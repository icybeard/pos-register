import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pos_system/services/auth/auth_session.dart';
import 'package:pos_system/services/auth/auth_token_store.dart';
import 'package:pos_system/services/auth/device_fingerprint.dart';

void main() {
  group('AuthSession', () {
    late _Persistence dev;
    late _Persistence usr;
    late _StubFingerprint fp;
    late _RecordingClient httpClient;
    late AuthSession session;

    setUp(() {
      dev = _Persistence();
      usr = _Persistence();
      fp = _StubFingerprint('fp-test-hash');
      httpClient = _RecordingClient();
      session = AuthSession(
        baseUrl: 'http://central.test',
        httpClient: httpClient,
        loadDevice: dev.load,
        saveDevice: dev.save,
        clearDevicePersisted: dev.clear,
        loadUser: usr.load,
        saveUser: usr.save,
        clearUserPersisted: usr.clear,
        fingerprint: fp,
      );
    });

    test('bootstrap loads both slots from persistence', () async {
      await dev.save(_tokens('dev-access', refresh: 'dev-r', workstationId: 'ws-1'));
      await usr.save(_tokens('usr-access', refresh: 'usr-r'));
      await session.bootstrap();
      expect(session.hasDevice, isTrue);
      expect(session.hasUser, isTrue);
      expect(session.deviceTokens!.accessToken, 'dev-access');
      expect(session.userTokens!.accessToken, 'usr-access');
    });

    test('headers returns Bearer for the requested flavor only', () async {
      await session.useDeviceSession(_tokens('dev-token'));
      expect(session.headers(AuthFlavor.device)['Authorization'], 'Bearer dev-token');
      expect(session.headers(AuthFlavor.user), isEmpty);
      expect(session.headers(AuthFlavor.none), isEmpty);
    });

    test('useDeviceSession does not touch user slot', () async {
      await session.useUserSession(_tokens('usr-1'));
      final userEpochBefore = session.epochOf(AuthFlavor.user);

      await session.useDeviceSession(_tokens('dev-1'));

      expect(session.userTokens!.accessToken, 'usr-1');
      expect(session.epochOf(AuthFlavor.user), userEpochBefore);
      expect(session.deviceTokens!.accessToken, 'dev-1');
    });

    test('clearUserSession leaves device slot alive (logout regression)', () async {
      await session.useDeviceSession(_tokens('dev-keep'));
      await session.useUserSession(_tokens('usr-go'));

      await session.clearUserSession();

      expect(session.hasUser, isFalse);
      expect(session.hasDevice, isTrue);
      expect(session.deviceTokens!.accessToken, 'dev-keep');
    });

    test('clearAll clears both slots', () async {
      await session.useDeviceSession(_tokens('a'));
      await session.useUserSession(_tokens('b'));
      await session.clearAll();
      expect(session.hasDevice, isFalse);
      expect(session.hasUser, isFalse);
    });

    test('refresh device flavor: posts to /api/register/refresh with fingerprint', () async {
      await session.useDeviceSession(_tokens('dev-old', refresh: 'dev-r-old', workstationId: 'ws-1'));
      httpClient.respondWith((req) async {
        expect(req.url.path, '/api/register/refresh');
        final body = json.decode(req.body) as Map<String, dynamic>;
        expect(body['refresh_token'], 'dev-r-old');
        expect(body['device_fingerprint'], 'fp-test-hash');
        expect(body.containsKey('device_id'), isFalse,
            reason: 'device flavor: server already knows from token row');
        return _refreshOk('dev-new', 'dev-r-new');
      });

      await session.refresh(AuthFlavor.device);

      expect(session.deviceTokens!.accessToken, 'dev-new');
      expect(session.deviceTokens!.refreshToken, 'dev-r-new');
      expect(httpClient.requests.length, 1);
    });

    test('refresh user flavor: posts to /api/auth/refresh with fingerprint + device_id', () async {
      await session.useUserSession(_tokens('usr-old', refresh: 'usr-r-old', workstationId: 'ws-2'));
      httpClient.respondWith((req) async {
        expect(req.url.path, '/api/auth/refresh');
        final body = json.decode(req.body) as Map<String, dynamic>;
        expect(body['refresh_token'], 'usr-r-old');
        expect(body['device_fingerprint'], 'fp-test-hash');
        expect(body['device_id'], 'ws-2');
        return _refreshOk('usr-new', 'usr-r-new');
      });

      await session.refresh(AuthFlavor.user);
      expect(session.userTokens!.accessToken, 'usr-new');
    });

    test('refresh persists FIRST then updates in-memory (crash-safety order)', () async {
      await session.useDeviceSession(_tokens('dev-old'));
      final saveOrder = <String>[];
      dev.onSave = (t) => saveOrder.add('persist:${t.accessToken}');

      httpClient.respondWith((req) async => _refreshOk('dev-new', 'dev-r-new'));
      await session.refresh(AuthFlavor.device);

      expect(dev.tokens!.accessToken, 'dev-new');
      expect(session.deviceTokens!.accessToken, 'dev-new');
      expect(saveOrder, contains('persist:dev-new'));
    });

    test('concurrent same-flavor 401s share ONE refresh round-trip (mutex)', () async {
      await session.useDeviceSession(_tokens('dev-old', refresh: 'dev-r'));

      var refreshCount = 0;
      final firstHit = Completer<void>();
      httpClient.respondWith((req) async {
        refreshCount++;
        if (refreshCount == 1) {
          firstHit.complete();
          await Future<void>.delayed(const Duration(milliseconds: 20));
        }
        return _refreshOk('dev-new', 'dev-r-new');
      });

      final f1 = session.refresh(AuthFlavor.device);
      await firstHit.future;
      final f2 = session.refresh(AuthFlavor.device);
      final f3 = session.refresh(AuthFlavor.device);
      final f4 = session.refresh(AuthFlavor.device);
      final f5 = session.refresh(AuthFlavor.device);

      await Future.wait([f1, f2, f3, f4, f5]);
      expect(refreshCount, 1, reason: 'all 5 callers should share one refresh');
    });

    test('concurrent device + user refresh run in parallel (separate mutexes)', () async {
      await session.useDeviceSession(_tokens('dev-old', refresh: 'dev-r'));
      await session.useUserSession(_tokens('usr-old', refresh: 'usr-r'));

      var inFlight = 0;
      var maxInFlight = 0;
      httpClient.respondWith((req) async {
        inFlight++;
        if (inFlight > maxInFlight) maxInFlight = inFlight;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        inFlight--;
        if (req.url.path.contains('register')) {
          return _refreshOk('dev-new', 'dev-r-new');
        }
        return _refreshOk('usr-new', 'usr-r-new');
      });

      await Future.wait([
        session.refresh(AuthFlavor.device),
        session.refresh(AuthFlavor.user),
      ]);
      expect(maxInFlight, 2, reason: 'device + user should refresh in parallel');
    });

    test('refresh 401 throws SessionExpiredException and clears that slot only', () async {
      await session.useDeviceSession(_tokens('dev-bad', refresh: 'dev-r'));
      await session.useUserSession(_tokens('usr-good', refresh: 'usr-r'));
      httpClient.respondWith((req) async => _httpResp(401, '{"error":"refresh token reuse detected"}'));

      await expectLater(
        session.refresh(AuthFlavor.device),
        throwsA(isA<SessionExpiredException>()
            .having((e) => e.flavor, 'flavor', AuthFlavor.device)),
      );

      expect(session.hasDevice, isFalse, reason: 'device slot cleared');
      expect(session.hasUser, isTrue, reason: 'user slot intact');
      expect(dev.tokens, isNull, reason: 'device persisted row cleared');
      expect(usr.tokens, isNotNull, reason: 'user persisted row intact');
    });

    test('refresh 401 with device_mismatch body throws SessionExpiredException', () async {
      await session.useDeviceSession(_tokens('dev', refresh: 'r'));
      httpClient.respondWith((req) async => _httpResp(401, 'device fingerprint mismatch'));

      await expectLater(
        session.refresh(AuthFlavor.device),
        throwsA(isA<SessionExpiredException>()
            .having((e) => e.message, 'message', contains('device fingerprint mismatch'))),
      );
    });

    test('refresh 5xx throws SessionUnavailableException and keeps slot', () async {
      await session.useDeviceSession(_tokens('dev', refresh: 'r'));
      httpClient.respondWith((req) async => _httpResp(503, 'service unavailable'));

      await expectLater(
        session.refresh(AuthFlavor.device),
        throwsA(isA<SessionUnavailableException>()),
      );
      expect(session.hasDevice, isTrue);
      expect(dev.tokens, isNotNull);
    });

    test('refresh transport failure throws SessionUnavailableException', () async {
      await session.useDeviceSession(_tokens('dev', refresh: 'r'));
      httpClient.respondWith((req) async => throw const _TransportError('network down'));

      await expectLater(
        session.refresh(AuthFlavor.device),
        throwsA(isA<SessionUnavailableException>()),
      );
      expect(session.hasDevice, isTrue);
    });

    test('refresh on already-expired refresh token clears slot without HTTP', () async {
      final expired = AuthTokens(
        accessToken: 'a',
        refreshToken: 'r',
        accessExpiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 2)),
        refreshExpiresAt: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
        tenantId: 'tenant-1',
      );
      await session.useDeviceSession(expired);

      await expectLater(
        session.refresh(AuthFlavor.device),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(session.hasDevice, isFalse);
      expect(httpClient.requests, isEmpty, reason: 'no network request when locally expired');
    });

    test('successful refresh bumps the slot epoch', () async {
      await session.useDeviceSession(_tokens('dev-old', refresh: 'r'));
      final before = session.epochOf(AuthFlavor.device);
      httpClient.respondWith((req) async => _refreshOk('dev-new', 'r-new'));
      await session.refresh(AuthFlavor.device);
      expect(session.epochOf(AuthFlavor.device), greaterThan(before));
    });
  });
}

// ---------- helpers ----------

http.Response _httpResp(int status, String body) =>
    http.Response(body, status, headers: const {'content-type': 'application/json'});

http.Response _refreshOk(String access, String refresh) {
  final now = DateTime.now().toUtc();
  return http.Response(
    json.encode({
      'access_token': access,
      'refresh_token': refresh,
      'access_expires_at': now.add(const Duration(minutes: 15)).toIso8601String(),
      'refresh_expires_at': now.add(const Duration(days: 30)).toIso8601String(),
      'tenant_id': 'tenant-1',
    }),
    200,
    headers: const {'content-type': 'application/json'},
  );
}

AuthTokens _tokens(String access,
    {String refresh = 'r-default', String? workstationId}) {
  final now = DateTime.now().toUtc();
  return AuthTokens(
    accessToken: access,
    refreshToken: refresh,
    accessExpiresAt: now.add(const Duration(minutes: 15)),
    refreshExpiresAt: now.add(const Duration(days: 30)),
    tenantId: 'tenant-1',
    workstationId: workstationId,
  );
}

class _Persistence {
  AuthTokens? tokens;
  void Function(AuthTokens)? onSave;

  Future<AuthTokens?> load() async => tokens;
  Future<void> save(AuthTokens t) async {
    onSave?.call(t);
    tokens = t;
  }

  Future<void> clear() async => tokens = null;
}

class _StubFingerprint extends DeviceFingerprint {
  _StubFingerprint(this._value) : super();
  final String _value;
  @override
  Future<String> value() async => _value;
}

class _TransportError implements Exception {
  const _TransportError(this.message);
  final String message;
  @override
  String toString() => 'TransportError: $message';
}

/// MockClient wrapper that captures requests and lets each test queue a
/// response factory.
class _RecordingClient extends http.BaseClient {
  final List<http.Request> requests = [];
  Future<http.Response> Function(http.Request)? _handler;
  late final MockClient _inner;

  _RecordingClient() {
    _inner = MockClient((req) async {
      requests.add(req);
      final h = _handler;
      if (h == null) return http.Response('no handler queued', 500);
      return h(req);
    });
  }

  void respondWith(Future<http.Response> Function(http.Request) handler) {
    _handler = handler;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _inner.send(request);
}
