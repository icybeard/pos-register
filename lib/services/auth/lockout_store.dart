import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persisted state for the PIN brute-force lockout counter.
///
/// Keeping this in-memory on the AuthBloc (prior design) let a physical
/// attacker reset the failure counter by force-stopping the app after each
/// batch of wrong PINs. We now persist in secure storage so the counter and
/// lockout deadline survive app restarts and cold boots.
class LockoutState {
  const LockoutState({required this.failedAttempts, this.lockedUntil});

  final int failedAttempts;
  final DateTime? lockedUntil;

  static const empty = LockoutState(failedAttempts: 0);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'failed_attempts': failedAttempts,
        'locked_until': lockedUntil?.toUtc().toIso8601String(),
      };

  factory LockoutState.fromJson(Map<String, dynamic> j) => LockoutState(
        failedAttempts: (j['failed_attempts'] as num?)?.toInt() ?? 0,
        lockedUntil: j['locked_until'] is String
            ? DateTime.tryParse(j['locked_until'] as String)?.toUtc()
            : null,
      );
}

class LockoutStore {
  LockoutStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions:
                  AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _key = 'pos.auth.lockout.v1';
  final FlutterSecureStorage _storage;

  Future<LockoutState> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return LockoutState.empty;
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return LockoutState.fromJson(decoded);
      }
      return LockoutState.empty;
    } on Object {
      return LockoutState.empty;
    }
  }

  Future<void> save(LockoutState state) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(state.toJson()));
    } on Object {
      // Best-effort persistence — see AuthTokenStore for rationale.
    }
  }

  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object {
      // ignore
    }
  }
}
