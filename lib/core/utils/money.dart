/// Утилиты для работы с деньгами (тиын)
class Money {
  Money._();

  /// Форматирует тиыны в строку с тенге
  /// 144000 -> "1 440 ₸", -144000 -> "-1 440 ₸"
  static String format(int tiyin) {
    final sign = tiyin < 0 ? '-' : '';
    final abs = tiyin.abs();
    final tenge = abs ~/ 100;
    final remainder = abs % 100;

    final tengeStr = _formatWithSpaces(tenge);

    if (remainder == 0) {
      return '$sign$tengeStr ₸';
    }
    return '$sign$tengeStr,${remainder.toString().padLeft(2, '0')} ₸';
  }

  /// Форматирует тенге без тиын
  /// 144000 -> "1 440 ₸"
  static String formatTenge(int tiyin) {
    final tenge = tiyin ~/ 100;
    return '${_formatWithSpaces(tenge)} ₸';
  }

  /// Конвертирует тенге в тиыны
  static int tengeToTiyin(double tenge) => (tenge * 100).round();

  /// Конвертирует тиыны в тенге
  static double tiyinToTenge(int tiyin) => tiyin / 100;

  /// Рассчитывает цену весового товара
  /// [pricePerKgTiyin] — цена за кг в тиынах
  /// [weightGrams] — вес в граммах
  static int calculateWeightedPrice(int pricePerKgTiyin, int weightGrams) {
    return ((weightGrams * pricePerKgTiyin) + 500) ~/ 1000;
  }

  /// Рассчитывает НДС «изнутри» (включён в цену)
  /// НДС = сумма × ставка / (100 + ставка)
  ///
  /// **Использует целочисленное деление (truncation)** — в точности как .NET `Calculator.VatFromInside`
  /// и Go-сервер. Не округление! См. parity-tests в `test/calculator_parity_test.dart`.
  static int calculateVat(int totalTiyin, int vatRate) {
    if (vatRate == 0) return 0;
    return (totalTiyin * vatRate) ~/ (100 + vatRate);
  }

  /// Рассчитывает итог по строке чека (штучный или весовой), минус скидка.
  /// Скидка не делает итог отрицательным — clamp к 0.
  /// Зеркало .NET `Calculator.ItemTotal` / Go `domain.CalculateItemTotal`.
  static int calculateItemTotal({
    required bool isWeighted,
    required int basePriceTiyin,
    required int quantity,
    required int weightGrams,
    required int discountTiyin,
  }) {
    if (basePriceTiyin < 0) {
      throw ArgumentError('basePriceTiyin must be non-negative');
    }
    if (discountTiyin < 0) {
      throw ArgumentError('discountTiyin must be non-negative');
    }
    final subtotal = isWeighted
        ? calculateWeightedPrice(basePriceTiyin, weightGrams)
        : basePriceTiyin * quantity;
    final net = subtotal - discountTiyin;
    return net < 0 ? 0 : net;
  }

  /// Сдача покупателю: оплачено − итог. Никогда не отрицательная (клиент сам валидирует недоплату).
  /// Зеркало .NET `Calculator.Change`.
  static int calculateChange({
    required int totalTiyin,
    required int cashTiyin,
    required int cardTiyin,
    required int qrTiyin,
  }) {
    final paid = cashTiyin + cardTiyin + qrTiyin;
    final diff = paid - totalTiyin;
    return diff > 0 ? diff : 0;
  }

  static String _formatWithSpaces(int number) {
    final str = number.abs().toString();
    final result = StringBuffer();
    final sign = number < 0 ? '-' : '';

    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        result.write(' ');
      }
      result.write(str[i]);
    }

    return '$sign$result';
  }
}
