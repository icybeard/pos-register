import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/settings_repository.dart';
import 'package:pos_system/services/auth/auth_token_store.dart';
import 'package:pos_system/services/central_client.dart';
import 'package:pos_system/services/settings_service.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;
  late _FakeTokenStore store;
  late _StubAdapter adapter;
  late CentralClient client;
  late SettingsService service;
  const tenantId = '11111111-1111-1111-1111-111111111111';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepository(db, tenantId: tenantId);
    store = _FakeTokenStore();
    await store.save(AuthTokens(
      accessToken: 'access-1',
      refreshToken: 'refresh-1',
      accessExpiresAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
      refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      tenantId: tenantId,
    ));
    adapter = _StubAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'http://central.test'))
      ..httpClientAdapter = adapter;
    client = CentralClient(baseUrl: 'http://central.test', tokenStore: store, dioOverride: dio);
    service = SettingsService(repo: repo, client: client);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert writes locally and reports synced when central accepts', () async {
    var putBody = <String, dynamic>{};
    adapter.on('PUT', '/api/settings/receipt_footer', (req) {
      putBody = req.data as Map<String, dynamic>;
      return adapter.ok({'key': 'receipt_footer', 'value': 'Спасибо!'});
    });

    final result = await service.upsert('receipt_footer', 'Спасибо!');
    expect(result.isSynced, true);
    expect(putBody['value'], 'Спасибо!');
    expect(await service.get('receipt_footer'), 'Спасибо!');
  });

  test('upsert reports pending but still writes locally when central is offline', () async {
    // No stub for PUT → adapter throws with status 500. Service should catch and return pending.
    adapter.on('PUT', '/api/settings/offline_key', (_) => adapter.error(500, {'error': 'down'}));

    final result = await service.upsert('offline_key', 'v');
    expect(result.isSynced, false);
    expect(result.reason, isNotNull);
    // Local state still correct
    expect(await service.get('offline_key'), 'v');
    // Outbox still has the pending row (P2 drainer will retry)
    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.op, 'update');
  });

  test('hydrateFromCentral pulls all settings into drift', () async {
    adapter.on('GET', '/api/settings', (_) => adapter.ok({
          'settings': {
            'receipt_footer': 'Спасибо!',
            'vat_default': '12',
            'kaspi_merchant_id': 'KASPI-42',
          },
        }));

    final n = await service.hydrateFromCentral();
    expect(n, 3);
    expect(await service.get('receipt_footer'), 'Спасибо!');
    expect(await service.get('vat_default'), '12');
    expect(await service.get('kaspi_merchant_id'), 'KASPI-42');
  });

  test('hydrateFromCentral returns 0 and swallows network error when offline', () async {
    // No stub registered → adapter returns 500. Service must swallow and return 0.
    final n = await service.hydrateFromCentral();
    expect(n, 0);
    expect(await service.all(), isEmpty);
  });

  test('watchAll streams after upsert — same drift stream as repo', () async {
    adapter.on('PUT', '/api/settings/k', (_) => adapter.ok({'key': 'k', 'value': 'v'}));

    final emitted = <Map<String, String>>[];
    final sub = service.watchAll().listen(emitted.add);
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await service.upsert('k', 'v');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await sub.cancel();
    expect(emitted.last, {'k': 'v'});
  });
}

class _FakeTokenStore implements AuthTokenStore {
  AuthTokens? _tokens;
  @override
  Future<AuthTokens?> load() async => _tokens;
  @override
  Future<void> save(AuthTokens tokens) async {
    _tokens = tokens;
  }
  @override
  Future<void> clear() async {
    _tokens = null;
  }
}

class _StubAdapter implements HttpClientAdapter {
  final Map<String, ResponseBody Function(RequestOptions)> _routes = {};

  void on(String method, String path, ResponseBody Function(RequestOptions) handler) {
    _routes['$method $path'] = handler;
  }

  ResponseBody ok(Object? body, {int status = 200}) {
    final bytes = utf8.encode(jsonEncode(body));
    return ResponseBody.fromBytes(
      bytes,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  ResponseBody error(int status, Object? body) => ok(body, status: status);

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
    final body = handler(options);
    if (body.statusCode >= 400) {
      throw DioException.badResponse(
        statusCode: body.statusCode,
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: body.statusCode,
          data: jsonDecode(utf8.decode(await _collect(body.stream))),
        ),
      );
    }
    return body;
  }

  Future<List<int>> _collect(Stream<Uint8List> stream) async {
    final out = <int>[];
    await for (final chunk in stream) {
      out.addAll(chunk);
    }
    return out;
  }

  @override
  void close({bool force = false}) {}
}
