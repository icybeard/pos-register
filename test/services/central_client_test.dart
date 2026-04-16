import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/services/auth/auth_token_store.dart';
import 'package:pos_system/services/central_client.dart';

void main() {
  late _FakeTokenStore store;
  late _StubAdapter adapter;
  late Dio dio;
  late CentralClient client;

  setUp(() {
    store = _FakeTokenStore();
    adapter = _StubAdapter();
    dio = Dio(BaseOptions(baseUrl: 'http://central.test'))
      ..httpClientAdapter = adapter;
    client = CentralClient(baseUrl: 'http://central.test', tokenStore: store, dioOverride: dio);
  });

  test('anonymous endpoint does not get Authorization header', () async {
    await store.save(_tokens('access-1', DateTime.now().toUtc().add(const Duration(hours: 1))));
    adapter.on('POST', '/api/signup', (_) => adapter.ok({'tenant_id': 'x'}));

    final r = await client.post<Map<String, dynamic>>('/api/signup', body: {'email': 'a@b.c'});
    expect(r.statusCode, 200);
    expect(adapter.lastHeaders?['Authorization'], isNull,
        reason: 'signup is anonymous — the interceptor must NOT attach the token');
  });

  test('authenticated endpoint injects Bearer token from store', () async {
    await store.save(_tokens('access-42', DateTime.now().toUtc().add(const Duration(hours: 1))));
    adapter.on('GET', '/api/settings', (_) => adapter.ok({'settings': <String, String>{}}));

    final r = await client.get<Map<String, dynamic>>('/api/settings');
    expect(r.statusCode, 200);
    expect(adapter.lastHeaders?['Authorization'], 'Bearer access-42');
  });

  test('401 triggers refresh and retry, request eventually succeeds', () async {
    // First access token: access-old — already stored.
    await store.save(_tokens('access-old', DateTime.now().toUtc().add(const Duration(hours: 1))));

    // First GET returns 401; after refresh we return 200 with new token.
    var settingsCallCount = 0;
    adapter.on('GET', '/api/settings', (req) {
      settingsCallCount += 1;
      final authHeader = req.headers['Authorization'] as String?;
      if (authHeader == 'Bearer access-old') {
        return adapter.error(401, {'error': 'expired'});
      }
      return adapter.ok({'settings': <String, String>{'retry': 'succeeded'}});
    });

    adapter.on('POST', '/api/auth/refresh', (_) => adapter.ok({
          'access_token': 'access-new',
          'refresh_token': 'refresh-new',
          'access_expires_at': DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String(),
          'refresh_expires_at': DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String(),
          'tenant_id': 't-123',
          'user_id': 'u-1',
          'role': 'owner',
        }));

    final r = await client.get<Map<String, dynamic>>('/api/settings');
    expect(r.statusCode, 200);
    expect(r.data!['settings']['retry'], 'succeeded');
    expect(settingsCallCount, 2, reason: 'original + one retry = 2 hits');

    final updated = await store.load();
    expect(updated!.accessToken, 'access-new');
    expect(updated.refreshToken, 'refresh-new');
  });

  test('refresh fails → token store wiped, caller receives the original 401', () async {
    await store.save(_tokens('access-old', DateTime.now().toUtc().add(const Duration(hours: 1))));
    adapter.on('GET', '/api/settings', (_) => adapter.error(401, {'error': 'expired'}));
    adapter.on('POST', '/api/auth/refresh',
        (_) => adapter.error(401, {'error': 'refresh expired'}));

    Object? thrown;
    try {
      await client.get<Map<String, dynamic>>('/api/settings');
    } on Object catch (e) {
      thrown = e;
    }
    expect(thrown, isA<DioException>(), reason: 'should surface the original 401 error');
    expect(await store.load(), isNull, reason: 'bad tokens must be wiped');
  });

  test('concurrent 401s share a single refresh round-trip (mutex)', () async {
    await store.save(_tokens('access-old', DateTime.now().toUtc().add(const Duration(hours: 1))));

    var refreshCount = 0;
    final refreshGate = Completer<void>();

    adapter.on('GET', '/api/settings', (req) {
      if (req.headers['Authorization'] == 'Bearer access-old') {
        return adapter.error(401, {'error': 'expired'});
      }
      return adapter.ok({'settings': <String, String>{}});
    });

    adapter.on('POST', '/api/auth/refresh', (_) async {
      refreshCount += 1;
      // Block until all concurrent 401s have piled up, then release.
      if (!refreshGate.isCompleted) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      return adapter.ok({
        'access_token': 'access-new',
        'refresh_token': 'refresh-new',
        'access_expires_at':
            DateTime.now().toUtc().add(const Duration(hours: 1)).toIso8601String(),
        'refresh_expires_at':
            DateTime.now().toUtc().add(const Duration(days: 30)).toIso8601String(),
        'tenant_id': 't-123',
      });
    });

    // Fire off 3 concurrent requests that will all hit 401 → trigger refresh
    final futures = List.generate(3, (_) => client.get<Map<String, dynamic>>('/api/settings'));
    refreshGate.complete();
    final responses = await Future.wait(futures);

    expect(responses, everyElement(isA<Response<Map<String, dynamic>>>()));
    for (final r in responses) {
      expect(r.statusCode, 200);
    }
    expect(refreshCount, 1, reason: 'mutex ensures one refresh despite 3 concurrent 401s');
  });
}

AuthTokens _tokens(String access, DateTime expires) => AuthTokens(
      accessToken: access,
      refreshToken: 'refresh-stub',
      accessExpiresAt: expires,
      refreshExpiresAt: DateTime.now().toUtc().add(const Duration(days: 30)),
      tenantId: 't-123',
      userId: 'u-1',
      role: 'owner',
    );

/// In-memory AuthTokenStore for tests — avoids hitting platform channels.
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

/// Minimal HTTP adapter that dispatches by `(method, path)` to user-supplied handlers.
class _StubAdapter implements HttpClientAdapter {
  final Map<String, FutureOr<ResponseBody> Function(RequestOptions)> _routes = {};
  Map<String, dynamic>? lastHeaders;

  void on(String method, String path, FutureOr<ResponseBody> Function(RequestOptions) handler) {
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
    lastHeaders = Map<String, dynamic>.from(options.headers);
    final key = '${options.method} ${options.path}';
    final handler = _routes[key];
    if (handler == null) {
      return ResponseBody.fromString('{"error":"no stub for $key"}', 500,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
    }
    final body = await handler(options);
    // Manually raise DioException for non-2xx so the client sees an error, matching
    // default dio behaviour. (ResponseBody.statusCode alone won't trigger onError.)
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
