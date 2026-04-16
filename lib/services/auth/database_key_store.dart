import 'dart:convert' show base64UrlEncode;
import 'dart:math' show Random;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Per-device key for the SQLCipher-backed drift database. Generated once
/// on first boot (256 random bits, base64-url-encoded) and held in the
/// platform secure store (Keychain / Keystore / DPAPI / libsecret).
///
/// The key never leaves the device. Losing it means the local DB becomes
/// unreadable and the register must resync master data from central — an
/// acceptable failure mode for a register that lost its secure storage
/// (reinstall, OS reset, etc.).
class DatabaseKeyStore {
  DatabaseKeyStore({FlutterSecureStorage? storage, Random? random})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions:
                  AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
        _random = random ?? Random.secure();

  static const _key = 'pos.db_key.v1';
  final FlutterSecureStorage _storage;
  final Random _random;

  String? _memoized;

  /// Return the persisted DB key, generating + saving one on first call.
  Future<String> getOrCreate() async {
    final memoized = _memoized;
    if (memoized != null) return memoized;
    try {
      final existing = await _storage.read(key: _key);
      if (existing != null && existing.isNotEmpty) {
        _memoized = existing;
        return existing;
      }
    } on Object {
      // Fall through and mint a fresh key below.
    }
    final fresh = _generate();
    _memoized = fresh;
    try {
      await _storage.write(key: _key, value: fresh);
    } on Object {
      // Best-effort persistence. If this fails the DB will be unreadable
      // on next boot; drift will surface the open failure and the boot
      // flow can wipe + recreate.
    }
    return fresh;
  }

  String _generate() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
