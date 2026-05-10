import 'dart:convert';
import 'dart:io' show Platform;

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Derives a stable, tamper-evident hardware fingerprint hash and persists it
/// in secure storage so it survives across launches but cannot be tampered
/// with from outside the app sandbox.
///
/// The hash is `SHA-256(salt || raw_platform_id)` hex-encoded. The raw id is
/// the OS's stable per-device identifier:
///   - iOS: identifierForVendor (resets on app uninstall — first-launch
///          rebinding is acceptable; user re-activates).
///   - Android: ANDROID_ID (Settings.Secure.ANDROID_ID).
///   - macOS: hardware UUID via `device_info_plus`.
///   - Windows: deviceId from WindowsDeviceInfo.
///   - Linux: machineId from /etc/machine-id.
///
/// The hash is sent to the server on every issuance + refresh. The server
/// binds it on the refresh-token row and rejects mismatches with a 401.
class DeviceFingerprint {
  DeviceFingerprint({FlutterSecureStorage? storage, DeviceInfoPlugin? info})
      : _storage = storage ?? const FlutterSecureStorage(),
        _info = info ?? DeviceInfoPlugin();

  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _info;

  /// Persisted under this key. Bumping the key (v2, v3…) forces re-derivation
  /// on next launch — which would invalidate every existing device session,
  /// so don't unless you know what you're doing.
  static const String _storageKey = 'pos.device.fingerprint.v1';

  /// Per-app salt. Mixed into the hash so the same raw platform id used by
  /// another app on the same device produces a different fingerprint here.
  /// Not a secret — defence is binding, not confidentiality. Changing this
  /// constant forces re-derivation (effectively the same as bumping the
  /// storage-key version).
  static const String _salt = 'kz.pos.register.fingerprint.salt.v1';

  String? _cached;

  /// Returns the cached hash. Derives + persists on first call.
  Future<String> value() async {
    if (_cached != null) return _cached!;

    final stored = await _storage.read(key: _storageKey);
    if (stored != null && stored.isNotEmpty) {
      _cached = stored;
      return stored;
    }

    final raw = await _readPlatformId();
    final digest = sha256.convert(utf8.encode('$_salt|$raw'));
    final hex = digest.toString();

    // Best-effort persist. If secure storage write fails (rare; entitlement
    // issues on macOS), keep the in-memory hash so the current session still
    // sees a consistent value — next cold-boot will re-derive.
    try {
      await _storage.write(key: _storageKey, value: hex);
    } on Object {
      // Swallowed by design — see above.
    }

    _cached = hex;
    return hex;
  }

  /// Wipes the persisted hash. Test-only entry point; production code never
  /// clears the fingerprint (that would invalidate the device's bound
  /// sessions on the server).
  Future<void> resetForTesting() async {
    _cached = null;
    try {
      await _storage.delete(key: _storageKey);
    } on Object {
      // ignore
    }
  }

  Future<String> _readPlatformId() async {
    if (Platform.isIOS) {
      final ios = await _info.iosInfo;
      return ios.identifierForVendor ?? 'ios-unknown';
    }
    if (Platform.isAndroid) {
      final and = await _info.androidInfo;
      return and.id;
    }
    if (Platform.isMacOS) {
      final mac = await _info.macOsInfo;
      return mac.systemGUID ?? 'macos-unknown';
    }
    if (Platform.isWindows) {
      final win = await _info.windowsInfo;
      return win.deviceId;
    }
    if (Platform.isLinux) {
      final lin = await _info.linuxInfo;
      return lin.machineId ?? 'linux-unknown';
    }
    // Fallback (web / unknown): a non-stable id is better than crashing;
    // the server treats it as a fingerprint and binds whatever we send.
    // First-run binding is the correct behaviour.
    return 'unknown-platform';
  }
}
