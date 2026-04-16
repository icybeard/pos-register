import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/settings_repository.dart';
import 'package:pos_system/services/auth/auth_token_store.dart';
import 'package:pos_system/services/central_client.dart';
import 'package:pos_system/sync/sync_puller.dart';

void main() {
  late AppDatabase db;
  late _StubAdapter adapter;
  late CentralClient client;
  late SyncPuller puller;
  const tenantId = '11111111-1111-1111-1111-111111111111';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final store = _FakeTokenStore();
    await store.save(AuthTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      tenantId: tenantId,
    ));
    adapter = _StubAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://central.test'))..httpClientAdapter = adapter;
    client = CentralClient(baseUrl: 'http://central.test', tokenStore: store, dioOverride: dio);
    puller = SyncPuller(db: db, client: client, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('pulls entries, applies them to drift, and advances cursor', () async {
    adapter.on('GET', '/api/sync/pull', (_) => adapter.ok({
          'entries': [
            {
              'table': 'settings',
              'op': 'update',
              'server_seq': 1,
              'uuid': 'u1',
              'payload_json': jsonEncode({'key': 'receipt_footer', 'value': 'Привет'}),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
            {
              'table': 'users',
              'op': 'update',
              'server_seq': 2,
              'uuid': 'u2',
              'payload_json': jsonEncode({
                'id': 'user-123',
                'name': 'Anna',
                'role': 'cashier',
                'login': 'anna',
                'store_id': 'store-xyz',
                'is_active': true,
              }),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'cursor-after-2',
          'has_more': false,
        }));

    final r = await puller.pullOnce();
    expect(r.isOk, true);
    expect(r.applied, 2);

    // Settings landed
    final settings = SettingsRepository(db, tenantId: tenantId);
    expect(await settings.get('receipt_footer'), 'Привет');

    // User landed
    final users = await db.select(db.usersTable).get();
    expect(users, hasLength(1));
    expect(users.first.id, 'user-123');
    expect(users.first.name, 'Anna');
    expect(users.first.role, 'cashier');
    expect(users.first.login, 'anna');
    expect(users.first.isActive, true);

    // Cursor advanced
    final cursor = await db.select(db.syncCursorsTable).get();
    expect(cursor, hasLength(1));
    expect(cursor.first.cursor, 'cursor-after-2');
  });

  test('pagination: follows has_more until drained', () async {
    var callCount = 0;
    adapter.on('GET', '/api/sync/pull', (req) {
      callCount += 1;
      final since = req.queryParameters['since'] as String?;
      if (since == null) {
        // First call: return entries + has_more
        return adapter.ok({
          'entries': [
            {
              'table': 'settings',
              'op': 'update',
              'server_seq': 1,
              'uuid': 'u1',
              'payload_json': jsonEncode({'key': 'a', 'value': '1'}),
              'originating_device_id': 'dev-X',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'cursor-1',
          'has_more': true,
        });
      } else if (since == 'cursor-1') {
        return adapter.ok({
          'entries': [
            {
              'table': 'settings',
              'op': 'update',
              'server_seq': 2,
              'uuid': 'u2',
              'payload_json': jsonEncode({'key': 'b', 'value': '2'}),
              'originating_device_id': 'dev-X',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'cursor-2',
          'has_more': false,
        });
      }
      return adapter.ok({'entries': <Map<String, dynamic>>[], 'next_cursor': since, 'has_more': false});
    });

    final r = await puller.pullOnce();
    expect(r.applied, 2);
    expect(callCount, 2, reason: 'paginated — two pull calls');

    final repo = SettingsRepository(db, tenantId: tenantId);
    expect(await repo.all(), {'a': '1', 'b': '2'});

    final cursor = await db.select(db.syncCursorsTable).get();
    expect(cursor.first.cursor, 'cursor-2');
  });

  test('delete op removes setting from drift', () async {
    // Seed a value, then have central instruct deletion
    final repo = SettingsRepository(db, tenantId: tenantId);
    await repo.upsert('to_delete', 'stale');

    adapter.on('GET', '/api/sync/pull', (_) => adapter.ok({
          'entries': [
            {
              'table': 'settings',
              'op': 'delete',
              'server_seq': 5,
              'uuid': 'u-del',
              'payload_json': jsonEncode({'key': 'to_delete'}),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'c5',
          'has_more': false,
        }));

    await puller.pullOnce();
    expect(await repo.get('to_delete'), isNull);
  });

  test('unknown tables are silently skipped', () async {
    adapter.on('GET', '/api/sync/pull', (_) => adapter.ok({
          'entries': [
            {
              'table': 'receipts', // not tracked in P2.v1
              'op': 'insert',
              'server_seq': 10,
              'uuid': 'unknown',
              'payload_json': jsonEncode({'id': 'r1'}),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'c10',
          'has_more': false,
        }));

    final r = await puller.pullOnce();
    expect(r.isOk, true);
    expect(r.applied, 1, reason: 'applied-count counts visited entries, even if no-op');
    // Cursor still advanced — we don't want to loop forever on entries we ignore
    final cursor = await db.select(db.syncCursorsTable).get();
    expect(cursor.first.cursor, 'c10');
  });

  test('transient network error returns SyncPullResult.transient without crashing', () async {
    // No stub registered → 500 → DioException caught
    final r = await puller.pullOnce();
    expect(r.isOk, false);
    expect(r.transientError, isNotNull);
    expect(r.applied, 0);
  });

  test('P4 master-data tables: products + categories + suppliers + clients round-trip', () async {
    adapter.on('GET', '/api/sync/pull', (_) => adapter.ok({
          'entries': [
            {
              'table': 'products',
              'op': 'update',
              'server_seq': 1,
              'uuid': 'u-p1',
              'payload_json': jsonEncode({
                'id': 'prod-1',
                'store_id': null,
                'name': 'Coca-Cola',
                'barcode_gtin': '4870001234567',
                'purchase_unit': 'pcs',
                'purchase_price_tiyin': 15000,
                'sale_unit': 'pcs',
                'sale_price_tiyin': 25000,
                'is_weighted': false,
                'weight_step_grams': 1,
                'vat_rate': 12,
                'is_active': true,
              }),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
            {
              'table': 'categories',
              'op': 'update',
              'server_seq': 2,
              'uuid': 'u-c1',
              'payload_json': jsonEncode({
                'id': 'cat-1',
                'name': 'Напитки',
                'sort_order': 3,
                'is_active': true,
              }),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
            {
              'table': 'suppliers',
              'op': 'update',
              'server_seq': 3,
              'uuid': 'u-s1',
              'payload_json': jsonEncode({
                'id': 'sup-1',
                'name': 'ТОО Альфа',
                'bin': '123456789012',
                'is_active': true,
              }),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
            {
              'table': 'clients',
              'op': 'update',
              'server_seq': 4,
              'uuid': 'u-cl1',
              'payload_json': jsonEncode({
                'id': 'client-1',
                'name': 'Иван',
                'iin': '123456789012',
                'debt_limit_tiyin': 100000,
                'is_active': true,
              }),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'c4',
          'has_more': false,
        }));

    final r = await puller.pullOnce();
    expect(r.isOk, true);
    expect(r.applied, 4);

    final products = await db.select(db.productsTable).get();
    expect(products, hasLength(1));
    expect(products.first.name, 'Coca-Cola');
    expect(products.first.salePriceTiyin, 25000);

    final categories = await db.select(db.categoriesTable).get();
    expect(categories, hasLength(1));
    expect(categories.first.name, 'Напитки');
    expect(categories.first.sortOrder, 3);

    final suppliers = await db.select(db.suppliersTable).get();
    expect(suppliers, hasLength(1));
    expect(suppliers.first.bin, '123456789012');

    final clients = await db.select(db.clientsTable).get();
    expect(clients, hasLength(1));
    expect(clients.first.debtLimitTiyin, 100000);
  });

  test('delete op on products soft-deletes via is_active=false (receipts still resolve)', () async {
    // Seed the product first via a sync pull
    adapter.on('GET', '/api/sync/pull', (req) {
      final since = req.queryParameters['since'] as String?;
      if (since == null) {
        return adapter.ok({
          'entries': [
            {
              'table': 'products',
              'op': 'update',
              'server_seq': 1,
              'uuid': 'u1',
              'payload_json': jsonEncode({
                'id': 'prod-del',
                'name': 'To-delete',
                'purchase_unit': 'pcs',
                'purchase_price_tiyin': 1,
                'sale_unit': 'pcs',
                'sale_price_tiyin': 1,
                'weight_step_grams': 1,
                'vat_rate': 12,
                'is_active': true,
              }),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'c1',
          'has_more': false,
        });
      }
      if (since == 'c1') {
        // Second pull: delete op
        return adapter.ok({
          'entries': [
            {
              'table': 'products',
              'op': 'delete',
              'server_seq': 2,
              'uuid': 'u2',
              'payload_json': jsonEncode({'id': 'prod-del'}),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'c2',
          'has_more': false,
        });
      }
      return adapter.ok({'entries': <Map<String, dynamic>>[], 'next_cursor': since, 'has_more': false});
    });

    await puller.pullOnce();
    await puller.pullOnce();

    final rows = await db.select(db.productsTable).get();
    expect(rows, hasLength(1), reason: 'row retained for receipt-join integrity');
    expect(rows.first.isActive, false);
  });

  test('malformed payload_json is skipped without corrupting the rest', () async {
    adapter.on('GET', '/api/sync/pull', (_) => adapter.ok({
          'entries': [
            {
              'table': 'settings',
              'op': 'update',
              'server_seq': 1,
              'uuid': 'u1',
              'payload_json': 'this is not json {',
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
            {
              'table': 'settings',
              'op': 'update',
              'server_seq': 2,
              'uuid': 'u2',
              'payload_json': jsonEncode({'key': 'good_one', 'value': 'ok'}),
              'originating_device_id': 'dev-other',
              'created_at': DateTime.now().toUtc().toIso8601String(),
            },
          ],
          'next_cursor': 'c2',
          'has_more': false,
        }));

    final r = await puller.pullOnce();
    expect(r.isOk, true);

    final repo = SettingsRepository(db, tenantId: tenantId);
    expect(await repo.get('good_one'), 'ok');
  });
}

// ---- fixtures ----
class _FakeTokenStore implements AuthTokenStore {
  AuthTokens? _t;
  @override
  Future<AuthTokens?> load() async => _t;
  @override
  Future<void> save(AuthTokens tokens) async => _t = tokens;
  @override
  Future<void> clear() async => _t = null;
}

class _StubAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> _routes = {};

  void on(String method, String path, ResponseBody Function(RequestOptions) handler) {
    _routes['$method $path'] = handler;
  }

  ResponseBody ok(Object? body, {int status = 200}) {
    final bytes = utf8.encode(jsonEncode(body));
    return ResponseBody.fromBytes(bytes, status,
        headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final key = '${options.method} ${options.path}';
    final handler = _routes[key];
    if (handler == null) {
      throw DioException.badResponse(
        statusCode: 500,
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 500,
          data: {'error': 'no stub for $key'},
        ),
      );
    }
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}
