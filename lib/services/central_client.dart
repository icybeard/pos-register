import 'dart:async';

import 'package:dio/dio.dart';

import 'auth/auth_token_store.dart';

/// Single-source-of-truth HTTP client for talking to the .NET central server.
/// Every repository that needs to sync / write-through to central uses this.
///
/// Features:
///   - Base URL configurable (dev: http://localhost:8090, prod: https://api.pos.kz)
///   - Automatic `Authorization: Bearer <access_token>` injection on every request
///   - 401 → /api/auth/refresh → retry once, with a mutex to prevent N concurrent
///     requests from refreshing N times in parallel
///   - snake_case JSON matches the .NET central contract (binding is case-sensitive;
///     the client leaves request body keys as-is — callers build maps with snake_case keys)
///   - Correlation ID header propagated when the caller supplies one
///
/// This class does NOT know about drift / repositories — it just speaks HTTP.
class CentralClient {
  CentralClient({
    required String baseUrl,
    required AuthTokenStore tokenStore,
    Dio? dioOverride,
    Duration connectTimeout = const Duration(seconds: 10),
    Duration receiveTimeout = const Duration(seconds: 30),
  })  : _tokenStore = tokenStore,
        _dio = dioOverride ??
            Dio(BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: connectTimeout,
              receiveTimeout: receiveTimeout,
              contentType: 'application/json; charset=utf-8',
              responseType: ResponseType.json,
              // The .NET central requires exact snake_case — don't let dio case-fold.
              headers: {'Accept': 'application/json'},
            )) {
    _dio.interceptors.add(_AuthInterceptor(_tokenStore, this));
  }

  final Dio _dio;
  final AuthTokenStore _tokenStore;
  Completer<AuthTokens>? _refreshCompleter;

  /// Raw request forwarder so repositories can call arbitrary endpoints.
  Dio get raw => _dio;

  Future<Response<T>> get<T>(String path, {Map<String, dynamic>? query, Options? options}) =>
      _dio.get<T>(path, queryParameters: query, options: options);

  Future<Response<T>> post<T>(String path, {Object? body, Options? options}) =>
      _dio.post<T>(path, data: body, options: options);

  Future<Response<T>> put<T>(String path, {Object? body, Options? options}) =>
      _dio.put<T>(path, data: body, options: options);

  Future<Response<T>> delete<T>(String path, {Options? options}) =>
      _dio.delete<T>(path, options: options);

  /// Called by the interceptor on 401. Returns the refreshed AuthTokens, or throws
  /// [RefreshFailedException] if the refresh itself failed (caller should force re-login).
  ///
  /// **Mutex**: concurrent 401s share the same refresh round-trip. First caller kicks off
  /// the refresh, subsequent callers await the same Completer.
  Future<AuthTokens> refreshTokens() {
    // Concurrent callers share the same in-flight refresh.
    final inFlight = _refreshCompleter;
    if (inFlight != null) {
      return inFlight.future;
    }
    final c = Completer<AuthTokens>();
    _refreshCompleter = c;

    // Run the refresh work fully inside the Completer — single source of truth
    // for both happy path and error path. All awaiters of c.future observe
    // the result or the error, so no "unhandled error on Completer" warnings.
    unawaited(_runRefresh(c));
    return c.future;
  }

  Future<void> _runRefresh(Completer<AuthTokens> c) async {
    try {
      final current = await _tokenStore.load();
      if (current == null || current.isRefreshExpired) {
        throw RefreshFailedException('no valid refresh token');
      }

      // Use a bare Dio (no interceptor) so the refresh request doesn't recurse.
      // Share the outer Dio's HttpClientAdapter so mock/test adapters apply here too.
      final bare = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        connectTimeout: _dio.options.connectTimeout,
        receiveTimeout: _dio.options.receiveTimeout,
        contentType: 'application/json; charset=utf-8',
      ))
        ..httpClientAdapter = _dio.httpClientAdapter;
      final resp = await bare.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refresh_token': current.refreshToken},
      );

      final body = resp.data ?? const {};
      final fresh = AuthTokens(
        accessToken: body['access_token'] as String,
        refreshToken: body['refresh_token'] as String,
        accessExpiresAt: DateTime.parse(body['access_expires_at'] as String).toUtc(),
        refreshExpiresAt: DateTime.parse(body['refresh_expires_at'] as String).toUtc(),
        tenantId: (body['tenant_id'] as String?) ?? current.tenantId,
        userId: body['user_id'] as String? ?? current.userId,
        role: body['role'] as String? ?? current.role,
        storeId: current.storeId,
      );
      await _tokenStore.save(fresh);
      c.complete(fresh);
    } on Object catch (e, st) {
      // Wipe bad tokens — caller must re-login.
      await _tokenStore.clear();
      c.completeError(
        e is RefreshFailedException ? e : RefreshFailedException(e.toString()),
        st,
      );
    } finally {
      _refreshCompleter = null;
    }
  }
}

class RefreshFailedException implements Exception {
  RefreshFailedException(this.message);
  final String message;
  @override
  String toString() => 'RefreshFailedException: $message';
}

/// Injects Bearer token on every request; on 401, triggers refresh and retries once.
/// Refresh calls themselves and signup/login/activate bypass the header (they're anonymous).
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._store, this._client);

  final AuthTokenStore _store;
  final CentralClient _client;

  static const _anonymousPaths = <String>{
    '/api/signup',
    '/api/auth/login',
    '/api/auth/cashier-login',
    '/api/auth/refresh',
    '/api/register/activate',
    '/api/health',
  };

  bool _isAnonymous(String path) {
    // Strip query / trailing slash
    final p = Uri.parse(path).path;
    return _anonymousPaths.any((a) => p == a || p.startsWith('$a/'));
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (_isAnonymous(options.path)) {
      handler.next(options);
      return;
    }
    final tokens = await _store.load();
    if (tokens != null && !tokens.isAccessExpired) {
      options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final status = err.response?.statusCode;
    final path = err.requestOptions.path;

    if (status != 401 || _isAnonymous(path) || err.requestOptions.extra['retried'] == true) {
      handler.next(err);
      return;
    }

    try {
      final fresh = await _client.refreshTokens();
      // Retry the original request with the new access token.
      final retry = err.requestOptions
        ..headers['Authorization'] = 'Bearer ${fresh.accessToken}'
        ..extra['retried'] = true;
      final resp = await _client.raw.fetch<dynamic>(retry);
      handler.resolve(resp);
    } on Object catch (_) {
      handler.next(err);
    }
  }
}
