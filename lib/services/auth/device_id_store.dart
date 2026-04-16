import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Persisted, stable per-device identifier used when activating the register
/// against `/api/register/activate`.
///
/// The prior `dev-${millisecondsSinceEpoch}` pattern was predictable to the
/// millisecond — an attacker who obtained a valid activation code could mint
/// a matching `device_id` and replay the activation before the code expired.
/// This store replaces that with a one-time-generated UUID v4 held in the
/// platform's secure store (Keychain / Keystore / DPAPI / libsecret) and
/// reused for every subsequent call.
///
/// If the platform secure store is unavailable (unsigned macOS sandbox,
/// Linux without libsecret, etc.) the generator falls back to an in-memory
/// UUID that stays stable for the process lifetime. That's intentionally
/// weaker than the persisted path but still unpredictable.
class DeviceIdStore {
  DeviceIdStore({FlutterSecureStorage? storage, Uuid? uuid})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions:
                  AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            ),
        _uuid = uuid ?? const Uuid();

  static const _key = 'pos.device_id.v1';
  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  String? _memoized;

  /// Return the persisted device id, generating + saving a fresh one on
  /// first call. Safe to call repeatedly — the read is O(1) once memoized.
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
      // Platform secure-store unavailable — fall through to fresh UUID.
    }
    final fresh = _uuid.v4();
    _memoized = fresh;
    try {
      await _storage.write(key: _key, value: fresh);
    } on Object {
      // Best-effort persistence. Session-stable id still provides
      // unpredictability for this process; next boot will mint a new one
      // and re-register if persistence stays broken.
    }
    return fresh;
  }
}
