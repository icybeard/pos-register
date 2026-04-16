import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/settings_repository.dart';
import 'package:pos_system/services/auth/auth_token_store.dart';
import 'package:pos_system/services/central_client.dart';
import 'package:pos_system/sync/sync_worker.dart';

void main() {
  late AppDatabase db;
  late _FakeTokenStore store;
  late _StubAdapter adapter;
  late CentralClient client;
  late SyncWorker worker;
  late SettingsRepository settings;
  const tenantId = '11111111-1111-1111-1111-111111111111';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = _FakeTokenStore();
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
    worker = SyncWorker(db: db, client: client, deviceId: 'test-device');
    settings = SettingsRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('drainOnce is a no-op on an empty outbox', () async {
    final r = await worker.drainOnce();
    expect(r.isBusy, false);
    expect(r.pushed, 0);
    expect(r.pending, 0);
    expect(r.rejected, 0);
    expect(r.isIdle, true);
  });

  test('pushes pending outbox rows and marks them synced_at on success', () async {
    await settings.upsert('k1', 'v1');
    await settings.upsert('k2', 'v2');

    late List<Map<String, dynamic>> receivedEntries;
    adapter.on('POST', '/api/sync/push', (req) {
      final body = req.data as Map<String, dynamic>;
      receivedEntries = (body['entries'] as List).cast<Map<String, dynamic>>();
      // Accept everything
      return adapter.ok({
        'accepted': receivedEntries.map((e) => e['uuid']).toList(),
        'rejected': [],
      });
    });

    final result = await worker.drainOnce();
    expect(result.pushed, 2);
    expect(result.rejected, 0);
    expect(receivedEntries, hasLength(2));
    expect(receivedEntries.first['table'], 'settings');
    expect(receivedEntries.first['op'], 'update');

    final pending = await (db.select(db.syncOutboxTable)
          ..where((t) => t.syncedAt.isNull()))
        .get();
    expect(pending, isEmpty, reason: 'all rows should have synced_at set');

    final synced = await db.select(db.syncOutboxTable).get();
    expect(synced, hasLength(2));
    expect(synced.every((r) => r.syncedAt != null), true);
  });

  test('records rejected rows with reason, pushes the rest', () async {
    await settings.upsert('ok_key', 'ok');
    await settings.upsert('bad_key', 'bad');
    final outboxBefore = await db.select(db.syncOutboxTable).get();
    final okUuid = outboxBefore.firstWhere((r) => r.payloadJson.contains('ok_key')).uuid;
    final badUuid = outboxBefore.firstWhere((r) => r.payloadJson.contains('bad_key')).uuid;

    adapter.on('POST', '/api/sync/push', (_) => adapter.ok({
          'accepted': [okUuid],
          'rejected': [
            {'uuid': badUuid, 'reason': 'something something server-side'},
          ],
        }));

    final result = await worker.drainOnce();
    expect(result.pushed, 1);
    expect(result.rejected, 1);

    final rows = await db.select(db.syncOutboxTable).get();
    final okRow = rows.firstWhere((r) => r.uuid == okUuid);
    final badRow = rows.firstWhere((r) => r.uuid == badUuid);

    expect(okRow.syncedAt, isNotNull);
    expect(badRow.syncedAt, isNull, reason: 'rejected row stays pending for human review');
    expect(badRow.attempts, 1);
    expect(badRow.lastError, contains('something'));
  });

  test('network failure marks all attempted rows as pending with bumped attempts', () async {
    await settings.upsert('x', '1');

    // No stub → 500 → DioException
    final result = await worker.drainOnce();
    expect(result.pushed, 0);
    expect(result.pending, 1);

    final row = (await db.select(db.syncOutboxTable).get()).single;
    expect(row.syncedAt, isNull);
    expect(row.attempts, 1);
    expect(row.lastError, isNotNull);
  });

  test('skips rows with attempts >= 3 (poison-pill protection)', () async {
    await settings.upsert('poison', 'x');
    // Manually bump attempts to 3 — simulate 3 prior failed drains
    await db.update(db.syncOutboxTable).write(const SyncOutboxTableCompanion(
      attempts: Value(3),
      lastError: Value('stuck'),
    ));

    // Adapter would accept if called — but the worker should skip the poison row entirely.
    var called = false;
    adapter.on('POST', '/api/sync/push', (_) {
      called = true;
      return adapter.ok({'accepted': <String>[], 'rejected': <Map<String, dynamic>>[]});
    });

    final result = await worker.drainOnce();
    expect(called, false, reason: 'no push should happen — nothing eligible');
    expect(result.pushed, 0);

    // The row is still there, still unsynced, still at attempts=3
    final rows = await db.select(db.syncOutboxTable).get();
    expect(rows.single.attempts, 3);
    expect(rows.single.syncedAt, isNull);
  });

  test('drainOnce returns busy when already draining (mutex)', () async {
    await settings.upsert('k', 'v');

    // Slow stub to hold the first drain open
    var calls = 0;
    adapter.on('POST', '/api/sync/push', (_) async {
      calls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return adapter.ok({'accepted': <String>[], 'rejected': []});
    });

    final first = worker.drainOnce();
    // Immediately call again while first is in flight — should get busy
    final second = await worker.drainOnce();
    expect(second.isBusy, true);

    await first;
    expect(calls, 1);
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
  final Map<String, dynamic Function(RequestOptions)> _routes = {};

  void on(String method, String path, dynamic Function(RequestOptions) handler) {
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
    Stream<Uint8List>? requestStream,
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
    final res = await handler(options);
    if (res is ResponseBody) return res;
    throw StateError('stub returned non-ResponseBody: $res');
  }

  @override
  void close({bool force = false}) {}
}
