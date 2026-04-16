/// Константы приложения POS System Kazakhstan
class AppConstants {
  AppConstants._();

  // API. Default points at the .NET central on localhost:5000 (the value
  // `dotnet run` picks for ASPNETCORE_URLS). Override at build time with:
  //   flutter run --dart-define=POS_API_HOST=https://api.example.kz
  // The `String.fromEnvironment` lookup is compile-time, so each build
  // bakes in one host — no runtime reconfiguration.
  //
  // Production builds MUST use an https:// URL. Enforced at boot via
  // [assertApiHostIsSecure]; cleartext outside of localhost is also blocked
  // at the Android layer (network_security_config.xml).
  static const String defaultApiHost = String.fromEnvironment(
    'POS_API_HOST',
    defaultValue: 'http://localhost:5000',
  );
  static const String apiPrefix = '/api';

  /// True when the compiled-in API host is safe for release builds: an
  /// absolute `https://…` URL. Localhost over HTTP is permitted in debug /
  /// profile builds only.
  static bool get apiHostIsHttps {
    final uri = Uri.tryParse(defaultApiHost);
    if (uri == null) return false;
    return uri.isScheme('https');
  }

  static bool get apiHostIsLocalLoopback {
    final uri = Uri.tryParse(defaultApiHost);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '10.0.2.2';
  }

  /// Boot-time guard. Call from `main()` before `runApp`. Throws when a
  /// release build was compiled with a plain-HTTP host — that would silently
  /// send JWTs and PINs in cleartext on a production register.
  static void assertApiHostIsSecure({required bool isReleaseMode}) {
    final uri = Uri.tryParse(defaultApiHost);
    if (uri == null || !uri.hasAbsolutePath && uri.host.isEmpty) {
      throw StateError(
        'POS_API_HOST must be an absolute URL. '
        'Pass --dart-define=POS_API_HOST=https://your-api.example to the build.',
      );
    }
    if (isReleaseMode && !apiHostIsHttps) {
      throw StateError(
        'POS_API_HOST must use https:// in release builds '
        '(got "$defaultApiHost"). Cleartext HTTP in production ships JWTs '
        'and PINs unencrypted.',
      );
    }
  }

  // Валюта
  static const int tiyinPerTenge = 100;
  static const String currencySymbol = '₸';
  static const String currencyCode = 'KZT';

  // НДС
  static const int vatRateStandard = 12;
  static const int vatRateZero = 0;

  // PIN
  static const int pinLength = 4;

  // Пагинация
  static const int defaultPageSize = 50;
  static const int searchResultsLimit = 20;

  // Производительность
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const Duration apiTimeout = Duration(seconds: 10);
}
