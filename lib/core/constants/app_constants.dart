/// Константы приложения POS System Kazakhstan
class AppConstants {
  AppConstants._();

  // API. Default points at the .NET central on localhost:5000 (the value
  // `dotnet run` picks for ASPNETCORE_URLS). Override at build time with:
  //   flutter run --dart-define=POS_API_HOST=https://api.example.kz
  // The `String.fromEnvironment` lookup is compile-time, so each build
  // bakes in one host — no runtime reconfiguration.
  static const String defaultApiHost = String.fromEnvironment(
    'POS_API_HOST',
    defaultValue: 'http://localhost:5000',
  );
  static const String apiPrefix = '/api';

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
