import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Opaque token pair returned by /api/auth/* endpoints. Stored encrypted at rest
/// via flutter_secure_storage (Keychain on iOS/macOS, Keystore on Android,
/// DPAPI on Windows, libsecret on Linux).
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
    required this.tenantId,
    this.userId,
    this.role,
    this.storeId,
    this.workstationId,
  });

  final String accessToken;
  final String refreshToken;
  final DateTimeTokenTime accessExpiresAt;
  final DateTimeTokenTime refreshExpiresAt;
  final String tenantId;
  final String? userId;
  final String? role;
  final String? storeId;

  /// Workstation id returned by `/api/register/activate`. Stamped on every
  /// receipt / shift / stock_movement the register writes. Optional because
  /// the token may have been issued via owner-login (web admin) where no
  /// workstation concept applies.
  final String? workstationId;

  bool isAccessExpiringSoon({Duration leeway = const Duration(seconds: 30)}) {
    return DateTime.now().toUtc().add(leeway).isAfter(accessExpiresAt);
  }

  bool get isAccessExpired => DateTime.now().toUtc().isAfter(accessExpiresAt);
  bool get isRefreshExpired => DateTime.now().toUtc().isAfter(refreshExpiresAt);

  Map<String, dynamic> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'access_expires_at': accessExpiresAt.toIso8601String(),
        'refresh_expires_at': refreshExpiresAt.toIso8601String(),
        'tenant_id': tenantId,
        'user_id': userId,
        'role': role,
        'store_id': storeId,
        'workstation_id': workstationId,
      };

  factory AuthTokens.fromJson(Map<String, dynamic> j) => AuthTokens(
        accessToken: j['access_token'] as String,
        refreshToken: j['refresh_token'] as String,
        accessExpiresAt: DateTime.parse(j['access_expires_at'] as String).toUtc(),
        refreshExpiresAt: DateTime.parse(j['refresh_expires_at'] as String).toUtc(),
        tenantId: j['tenant_id'] as String,
        userId: j['user_id'] as String?,
        role: j['role'] as String?,
        storeId: j['store_id'] as String?,
        workstationId: j['workstation_id'] as String?,
      );
}

/// Alias to keep the type name suggestive at field sites.
typedef DateTimeTokenTime = DateTime;

/// Secure-storage-backed persistence for [AuthTokens]. Singleton in DI.
/// Thread-safe: flutter_secure_storage serialises internally per-instance.
class AuthTokenStore {
  AuthTokenStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _key = 'pos.auth.tokens.v1';
  final FlutterSecureStorage _storage;

  Future<AuthTokens?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      try {
        return AuthTokens.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on Object {
        // Corrupt payload — purge and force re-login.
        await clear();
        return null;
      }
    } on Object {
      // Platform error (e.g. Keychain -34018 on unsigned macOS sandbox).
      // Behave as if nothing was saved — the login flow re-prompts.
      return null;
    }
  }

  Future<void> save(AuthTokens tokens) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(tokens.toJson()));
    } on Object {
      // Persistence is best-effort. In-memory tokens keep the session
      // alive; losing them on next boot means the user re-logs in, which
      // is the worst-case recoverable outcome.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object {
      // Same rationale as save(): don't crash the logout flow just
      // because the platform refuses to touch the Keychain.
    }
  }
}
