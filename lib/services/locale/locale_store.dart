import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-scoped persistence for the operator's preferred UI locale.
///
/// Locale lives outside [SettingsRepository] because that repo is
/// tenant-scoped and we need the locale BEFORE tenant id is known (the
/// activation screen renders pre-login). Stored in flutter_secure_storage
/// alongside the other device-level stores ([WorkstationStore],
/// [DeviceIdStore], etc.) for a single secure-storage round-trip on boot.
///
/// Values are restricted to the locales declared in
/// `AppLocalizations.supportedLocales` (currently `ru` + `kk`); anything
/// else is treated as "no preference saved".
class LocaleStore {
  LocaleStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _key = 'pos.locale.v1';
  static const _supported = {'ru', 'kk'};

  final FlutterSecureStorage _storage;

  /// Best-effort load. Returns null when nothing is saved, the saved value
  /// is unrecognised, or the secure-storage platform channel errors out
  /// (unsigned macOS sandbox, Linux without libsecret, etc.). Callers
  /// should fall back to a sensible default — typically `'ru'` for KZ.
  Future<String?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || !_supported.contains(raw)) return null;
      return raw;
    } on Object {
      return null;
    }
  }

  /// Persist [locale]. Throws on invalid values to catch typos at the
  /// callsite — silently dropping unknown locales would let a bug ship
  /// where the toggle "works" in dev but no choice is ever persisted.
  Future<void> save(String locale) async {
    if (!_supported.contains(locale)) {
      throw ArgumentError.value(locale, 'locale',
          'must be one of $_supported');
    }
    try {
      await _storage.write(key: _key, value: locale);
    } on Object {
      // Same rationale as WorkstationStore.save: a secure-storage failure
      // shouldn't cascade and crash the toggle. The in-memory choice still
      // applies for the current session; next boot will re-prompt.
    }
  }
}
