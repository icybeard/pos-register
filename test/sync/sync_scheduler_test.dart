import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/settings_repository.dart';
import 'package:pos_system/services/auth/auth_token_store.dart';
import 'package:pos_system/services/central_client.dart';
import 'package:pos_system/sync/sync_puller.dart';
import 'package:pos_system/sync/sync_scheduler.dart';
import 'package:pos_system/sync/sync_worker.dart';

void main() {
  late AppDatabase db;
  late _StubAdapter adapter;
  late CentralClient client;
  late SyncWorker worker;
  late SyncPuller puller;
  late SyncScheduler scheduler;
  late SettingsRepository settings;
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
    worker = SyncWorker(db: db, client: client, deviceId: 'test-device');
    puller = SyncPuller(db: db, client: client, tenantId: tenantId);
    settings = SettingsRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    scheduler.stop();
    await db.close();
  });

  test('runOnce does push then pull', () async {
    await settings.upsert('local', 'v');

    var pushHit = 0;
    var pullHit = 0;
    adapter.on('POST', '/api/sync/push', (req) {
      pushHit += 1;
      final body = req.data as Map<String, dynamic>;
      final uuids = ((body['entries'] as List).cast<Map<String, dynamic>>())
          .map((e) => e['uuid'] as String)
          .toList();
      return adapter.ok({'accepted': uuids, 'rejected': <Map<String, dynamic>>[]});
    });
    adapter.on('GET', '/api/sync/pull', (_) {
      pullHit += 1;
      return adapter.ok({
        'entries': [
          {
            'table': 'settings',
            'op': 'update',
            'server_seq': 1,
            'uuid': 'remote-1',
            'payload_json': jsonEncode({'key': 'from_central', 'value': '42'}),
            'originating_device_id': 'dev-other',
            'created_at': DateTime.now().toUtc().toIso8601String(),
          },
        ],
        'next_cursor': 'c1',
        'has_more': false,
      });
    });

    scheduler = SyncScheduler(worker: worker, puller: puller);
    final tick = await scheduler.runOnce();
    expect(tick.isBusy, false);
    expect(tick.push!.pushed, 1);
    expect(tick.pull!.applied, 1);
    expect(pushHit, 1);
    expect(pullHit, 1);

    expect(await settings.get('from_central'), '42');
  });

  test('tick is mutexed — concurrent runOnce returns busy', () async {
    await settings.upsert('k', 'v');

    // Slow push so we can observe the second call colliding
    adapter.on('POST', '/api/sync/push', (_) async {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      return adapter.ok({'accepted': <String>[], 'rejected': <Map<String, dynamic>>[]});
    });
    adapter.on('GET', '/api/sync/pull',
        (_) => adapter.ok({'entries': <Map<String, dynamic>>[], 'next_cursor': null, 'has_more': false}));

    scheduler = SyncScheduler(worker: worker, puller: puller);
    final first = scheduler.runOnce();
    final second = await scheduler.runOnce();
    expect(second.isBusy, true);
    await first;
  });

  test('start schedules periodic ticks, stop cancels', () async {
    var pullCount = 0;
    adapter.on('POST', '/api/sync/push',
        (_) => adapter.ok({'accepted': <String>[], 'rejected': <Map<String, dynamic>>[]}));
    adapter.on('GET', '/api/sync/pull', (_) {
      pullCount += 1;
      return adapter.ok({'entries': <Map<String, dynamic>>[], 'next_cursor': null, 'has_more': false});
    });

    scheduler = SyncScheduler(
      worker: worker,
      puller: puller,
      interval: const Duration(milliseconds: 40),
    );

    expect(scheduler.isRunning, false);
    scheduler.start();
    expect(scheduler.isRunning, true);

    // Let a few ticks fire
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final countBeforeStop = pullCount;
    expect(countBeforeStop, greaterThanOrEqualTo(2),
        reason: 'at least 2 ticks should have fired in 150ms with 40ms interval');

    scheduler.stop();
    expect(scheduler.isRunning, false);
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(pullCount, countBeforeStop, reason: 'no more ticks after stop');
  });

  test('start is idempotent — calling twice does not double-schedule', () async {
    adapter.on('POST', '/api/sync/push',
        (_) => adapter.ok({'accepted': <String>[], 'rejected': <Map<String, dynamic>>[]}));
    adapter.on('GET', '/api/sync/pull',
        (_) => adapter.ok({'entries': <Map<String, dynamic>>[], 'next_cursor': null, 'has_more': false}));

    scheduler = SyncScheduler(
      worker: worker,
      puller: puller,
      interval: const Duration(seconds: 10), // long — no ticks during test
    );
    scheduler.start();
    scheduler.start(); // should be no-op
    expect(scheduler.isRunning, true);
    scheduler.stop();
  });

  test('onTick callback is invoked with the tick result', () async {
    await settings.upsert('k', 'v');
    adapter.on('POST', '/api/sync/push', (req) {
      final body = req.data as Map<String, dynamic>;
      final uuids = ((body['entries'] as List).cast<Map<String, dynamic>>())
          .map((e) => e['uuid'] as String)
          .toList();
      return adapter.ok({'accepted': uuids, 'rejected': <Map<String, dynamic>>[]});
    });
    adapter.on('GET', '/api/sync/pull',
        (_) => adapter.ok({'entries': <Map<String, dynamic>>[], 'next_cursor': null, 'has_more': false}));

    SyncTickResult? observed;
    scheduler = SyncScheduler(
      worker: worker,
      puller: puller,
      onTick: (r) => observed = r,
    );
    await scheduler.runOnce();

    expect(observed, isNotNull);
    expect(observed!.push!.pushed, 1);
    expect(observed!.pull!.applied, 0);
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
    final res = await handler(options);
    if (res is ResponseBody) return res;
    throw StateError('stub returned non-ResponseBody: $res');
  }

  @override
  void close({bool force = false}) {}
}
