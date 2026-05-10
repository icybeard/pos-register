import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'auth_token_store.dart';
import 'device_fingerprint.dart';

/// Which token to use on a given request. Encoded once at the call site
/// inside `ApiClient` so each public method declares its identity.
///
///   - [none]: anonymous endpoint (login, activate, health). No `Authorization`
///     header sent.
///   - [device]: pre-login / system actions — cashier-grid bootstrap, sync
///     push/pull, settings prefetch. Carries the device JWT issued at
///     register activation. Refreshes via `/api/register/refresh`.
///   - [user]: every other authenticated endpoint. Carries the JWT issued by
///     owner / cashier login. Refreshes via `/api/auth/refresh`.
enum AuthFlavor { none, device, user }

/// Refresh failed permanently — server rejected the refresh token, the device
/// fingerprint mismatched, or reuse-detection fired. Caller should clear the
/// matching slot and route the user back through activation (device) or login
/// (user). The session class has already cleared the persisted row by the
/// time this throws.
class SessionExpiredException implements Exception {
  const SessionExpiredException(this.flavor, this.message);
  final AuthFlavor flavor;
  final String message;

  @override
  String toString() => 'SessionExpiredException($flavor): $message';
}

/// Refresh attempt couldn't reach the server — network failure, 5xx, or
/// timeout. Slot is intact; caller should surface a connectivity error and
/// retry later (the access token still works on subsequent attempts after
/// the network recovers, and a future request will trigger refresh again).
class SessionUnavailableException implements Exception {
  const SessionUnavailableException(this.flavor, this.message);
  final AuthFlavor flavor;
  final String message;

  @override
  String toString() => 'SessionUnavailableException($flavor): $message';
}

/// Owns the in-memory + persisted state for both auth flavors and serialises
/// refreshes so concurrent 401s never produce parallel refresh round-trips.
///
/// Two parallel slots:
///   - device: from `/api/register/activate`; survives cashier login/logout.
///   - user:   from `/api/auth/login` or `/api/auth/cashier-login`; cleared
///             on logout, device slot stays alive so the cashier-grid keeps
///             working without re-activation.
///
/// Refresh is reactive only — `ApiClient._send` calls `refresh(flavor)` after
/// observing a 401, then retries the original request once. No proactive
/// expiry-checking. Per-slot mutex (Completer) guarantees that N concurrent
/// 401s on the same flavor produce ONE refresh round-trip and N retries.
class AuthSession {
  AuthSession({
    required this.baseUrl,
    required http.Client httpClient,
    required Future<AuthTokens?> Function() loadDevice,
    required Future<void> Function(AuthTokens) saveDevice,
    required Future<void> Function() clearDevicePersisted,
    required Future<AuthTokens?> Function() loadUser,
    required Future<void> Function(AuthTokens) saveUser,
    required Future<void> Function() clearUserPersisted,
    required DeviceFingerprint fingerprint,
  })  : _http = httpClient,
        _loadDevice = loadDevice,
        _saveDevice = saveDevice,
        _clearDevicePersisted = clearDevicePersisted,
        _loadUser = loadUser,
        _saveUser = saveUser,
        _clearUserPersisted = clearUserPersisted,
        _fingerprint = fingerprint;

  final String baseUrl;
  final http.Client _http;
  final Future<AuthTokens?> Function() _loadDevice;
  final Future<void> Function(AuthTokens) _saveDevice;
  final Future<void> Function() _clearDevicePersisted;
  final Future<AuthTokens?> Function() _loadUser;
  final Future<void> Function(AuthTokens) _saveUser;
  final Future<void> Function() _clearUserPersisted;
  final DeviceFingerprint _fingerprint;

  AuthTokens? _deviceTokens;
  AuthTokens? _userTokens;
  int _deviceEpoch = 0;
  int _userEpoch = 0;
  Completer<void>? _deviceRefresh;
  Completer<void>? _userRefresh;

  // --- read-only state --------------------------------------------------

  bool get hasDevice => _deviceTokens != null;
  bool get hasUser => _userTokens != null;

  /// Tokens currently in the device slot, or null. Test/diagnostic surface;
  /// production code should never read tokens directly — always go through
  /// [headers] which encapsulates the bearer plumbing.
  AuthTokens? get deviceTokens => _deviceTokens;
  AuthTokens? get userTokens => _userTokens;

  int epochOf(AuthFlavor flavor) =>
      flavor == AuthFlavor.device ? _deviceEpoch : _userEpoch;

  /// Returns `{Authorization: Bearer <access_token>}` for the requested
  /// flavor, or an empty map if no tokens are loaded / flavor is `none`.
  /// Pre-login flavor=user requests return empty headers and will 401 — the
  /// caller is expected to surface a "please log in" error.
  Map<String, String> headers(AuthFlavor flavor) {
    final tokens = _tokensOf(flavor);
    if (tokens == null) return const {};
    return {'Authorization': 'Bearer ${tokens.accessToken}'};
  }

  // --- bootstrap + slot writers ----------------------------------------

  /// Loads both slots from persistence. Call once at app startup before any
  /// authenticated traffic.
  Future<void> bootstrap() async {
    _deviceTokens = await _loadDevice();
    _userTokens = await _loadUser();
  }

  /// Replaces the device slot. Persists FIRST, then updates in-memory + epoch.
  /// Persist-first means a crash between persist and in-memory leaves the
  /// next-boot replay seeing the new tokens, never the old ones — avoids the
  /// server's reuse-detection trap that would revoke all sessions.
  Future<void> useDeviceSession(AuthTokens tokens) async {
    await _saveDevice(tokens);
    _deviceTokens = tokens;
    _deviceEpoch++;
  }

  Future<void> useUserSession(AuthTokens tokens) async {
    await _saveUser(tokens);
    _userTokens = tokens;
    _userEpoch++;
  }

  /// Logout: clears user slot only. Device slot survives so cashier-grid +
  /// background sync stay functional.
  Future<void> clearUserSession() async {
    await _clearUserPersisted();
    _userTokens = null;
    _userEpoch++;
  }

  /// Deactivation: clears device slot only. Cashier session (if any) stays
  /// — though it will fail on the next request because no device JWT exists
  /// to refresh against (and most flows route through activation first).
  Future<void> clearDeviceSession() async {
    await _clearDevicePersisted();
    _deviceTokens = null;
    _deviceEpoch++;
  }

  /// Full reset. Used when the user explicitly deactivates the register or
  /// when both flavors hit `SessionExpiredException` simultaneously.
  Future<void> clearAll() async {
    await Future.wait([_clearDevicePersisted(), _clearUserPersisted()]);
    _deviceTokens = null;
    _userTokens = null;
    _deviceEpoch++;
    _userEpoch++;
  }

  // --- refresh ---------------------------------------------------------

  /// Refreshes the slot's tokens via the appropriate server endpoint. All
  /// concurrent callers on the same flavor share a single round-trip via the
  /// per-slot Completer — N callers, one refresh, N retries.
  ///
  /// Throws [SessionExpiredException] when refresh is fatal (server rejects,
  /// fingerprint mismatch, reuse detected, refresh token expired). The slot
  /// is cleared before this throws.
  ///
  /// Throws [SessionUnavailableException] for transient failures (network,
  /// 5xx, timeout). The slot is left intact.
  Future<void> refresh(AuthFlavor flavor) {
    if (flavor == AuthFlavor.none) {
      throw ArgumentError('cannot refresh AuthFlavor.none');
    }
    final inFlight = _completerOf(flavor);
    if (inFlight != null) return inFlight.future;

    final c = Completer<void>();
    _setCompleter(flavor, c);
    unawaited(_runRefresh(flavor, c));
    return c.future;
  }

  Future<void> _runRefresh(AuthFlavor flavor, Completer<void> c) async {
    try {
      final current = _tokensOf(flavor);
      if (current == null) {
        throw SessionUnavailableException(flavor, 'no tokens loaded');
      }
      if (current.isRefreshExpired) {
        await _clearSlot(flavor);
        throw SessionExpiredException(flavor, 'refresh token expired');
      }

      final fp = await _fingerprint.value();
      final path = flavor == AuthFlavor.device
          ? '/api/register/refresh'
          : '/api/auth/refresh';
      final body = <String, dynamic>{
        'refresh_token': current.refreshToken,
        'device_fingerprint': fp,
        if (flavor == AuthFlavor.user && current.workstationId != null)
          'device_id': current.workstationId,
      };

      http.Response resp;
      try {
        resp = await _http.post(
          Uri.parse('$baseUrl$path'),
          headers: const {'Content-Type': 'application/json'},
          body: json.encode(body),
        );
      } on Exception catch (e) {
        throw SessionUnavailableException(
            flavor, 'refresh transport failure: $e');
      }

      if (resp.statusCode >= 500) {
        throw SessionUnavailableException(
            flavor, 'refresh server error ${resp.statusCode}');
      }
      if (resp.statusCode != 200) {
        // Any 4xx other than the explicit "available" cases is fatal for the
        // slot. The server distinguishes reasons in the body — we surface
        // the message but treat them all as slot-clear / re-login.
        await _clearSlot(flavor);
        throw SessionExpiredException(flavor, _bodyMessage(resp));
      }

      final fresh = AuthTokens.fromJson(
          json.decode(resp.body) as Map<String, dynamic>);

      // Persist FIRST, in-memory SECOND. Crash-recovery invariant.
      if (flavor == AuthFlavor.device) {
        await _saveDevice(fresh);
        _deviceTokens = fresh;
        _deviceEpoch++;
      } else {
        await _saveUser(fresh);
        _userTokens = fresh;
        _userEpoch++;
      }
      c.complete();
    } catch (e, st) {
      if (!c.isCompleted) c.completeError(e, st);
    } finally {
      _setCompleter(flavor, null);
    }
  }

  // --- internals -------------------------------------------------------

  AuthTokens? _tokensOf(AuthFlavor flavor) =>
      flavor == AuthFlavor.device ? _deviceTokens : _userTokens;

  Completer<void>? _completerOf(AuthFlavor flavor) =>
      flavor == AuthFlavor.device ? _deviceRefresh : _userRefresh;

  void _setCompleter(AuthFlavor flavor, Completer<void>? c) {
    if (flavor == AuthFlavor.device) {
      _deviceRefresh = c;
    } else {
      _userRefresh = c;
    }
  }

  Future<void> _clearSlot(AuthFlavor flavor) async {
    if (flavor == AuthFlavor.device) {
      await _clearDevicePersisted();
      _deviceTokens = null;
      _deviceEpoch++;
    } else {
      await _clearUserPersisted();
      _userTokens = null;
      _userEpoch++;
    }
  }

  /// Extracts a human-readable error message from a server error body.
  /// pos-server returns either `{"error": "...", ...}` (envelope middleware)
  /// or a plain string. We tolerate either.
  String _bodyMessage(http.Response resp) {
    if (resp.body.isEmpty) return 'http ${resp.statusCode}';
    try {
      final decoded = json.decode(resp.body);
      if (decoded is Map && decoded['error'] is String) {
        return decoded['error'] as String;
      }
    } on FormatException {
      // Not JSON — return raw body trimmed.
    }
    return resp.body.length > 200 ? resp.body.substring(0, 200) : resp.body;
  }
}
