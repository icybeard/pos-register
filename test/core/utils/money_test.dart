import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/utils/money.dart';

void main() {
  // -------------------------------------------------------------------------
  // Money.format
  // -------------------------------------------------------------------------
  group('Money.format', () {
    test('formats whole tenge', () {
      expect(Money.format(144000), '1 440 ₸');
      expect(Money.format(100), '1 ₸');
      expect(Money.format(0), '0 ₸');
      expect(Money.format(10000000), '100 000 ₸');
    });

    test('formats with tiyin remainder', () {
      expect(Money.format(150), '1,50 ₸');
      expect(Money.format(99), '0,99 ₸');
      expect(Money.format(1), '0,01 ₸');
      expect(Money.format(10), '0,10 ₸');
      expect(Money.format(50), '0,50 ₸');
    });

    test('formats negative values', () {
      expect(Money.format(-144000), '-1 440 ₸');
      expect(Money.format(-150), '-1,50 ₸');
      expect(Money.format(-1), '-0,01 ₸');
      expect(Money.format(-100), '-1 ₸');
    });

    test('formats large numbers with spaces', () {
      expect(Money.format(100000000), '1 000 000 ₸');
      expect(Money.format(999999900), '9 999 999 ₸');
      expect(Money.format(10000000000), '100 000 000 ₸');
    });

    test('small tenge values', () {
      expect(Money.format(200), '2 ₸');
      expect(Money.format(300), '3 ₸');
      expect(Money.format(1000), '10 ₸');
    });
  });

  // -------------------------------------------------------------------------
  // Money.formatTenge
  // -------------------------------------------------------------------------
  group('Money.formatTenge', () {
    test('drops tiyin', () {
      expect(Money.formatTenge(144000), '1 440 ₸');
      expect(Money.formatTenge(150), '1 ₸');
      expect(Money.formatTenge(99), '0 ₸');
    });

    test('zero', () {
      expect(Money.formatTenge(0), '0 ₸');
    });

    test('large values', () {
      expect(Money.formatTenge(10000000), '100 000 ₸');
    });
  });

  // -------------------------------------------------------------------------
  // Money.tengeToTiyin
  // -------------------------------------------------------------------------
  group('Money.tengeToTiyin', () {
    test('converts whole tenge', () {
      expect(Money.tengeToTiyin(100), 10000);
      expect(Money.tengeToTiyin(0), 0);
      expect(Money.tengeToTiyin(1), 100);
    });

    test('converts fractional tenge', () {
      expect(Money.tengeToTiyin(14.5), 1450);
      expect(Money.tengeToTiyin(0.01), 1);
      expect(Money.tengeToTiyin(0.99), 99);
    });

    test('rounds correctly', () {
      // Note: 1.005 * 100 = 100.49999... in IEEE 754, so rounds to 100
      expect(Money.tengeToTiyin(1.005), 100);
      expect(Money.tengeToTiyin(1.004), 100);
      // A value that clearly rounds up
      expect(Money.tengeToTiyin(1.006), 101);
    });
  });

  // -------------------------------------------------------------------------
  // Money.tiyinToTenge
  // -------------------------------------------------------------------------
  group('Money.tiyinToTenge', () {
    test('converts correctly', () {
      expect(Money.tiyinToTenge(10000), 100.0);
      expect(Money.tiyinToTenge(0), 0.0);
      expect(Money.tiyinToTenge(150), 1.5);
      expect(Money.tiyinToTenge(1), 0.01);
      expect(Money.tiyinToTenge(99), 0.99);
    });
  });

  // -------------------------------------------------------------------------
  // Money.calculateWeightedPrice
  // -------------------------------------------------------------------------
  group('Money.calculateWeightedPrice', () {
    test('basic calculations', () {
      // 500g at 2000 KZT/kg = 1000 KZT = 100000 tiyin
      expect(Money.calculateWeightedPrice(200000, 500), 100000);
      // 1000g at 1000 KZT/kg = 1000 KZT
      expect(Money.calculateWeightedPrice(100000, 1000), 100000);
      // 450g at 3200 KZT/kg = 1440 KZT
      expect(Money.calculateWeightedPrice(320000, 450), 144000);
    });

    test('edge cases', () {
      expect(Money.calculateWeightedPrice(100000, 0), 0);
      expect(Money.calculateWeightedPrice(0, 500), 0);
      expect(Money.calculateWeightedPrice(0, 0), 0);
      // 1g at 1000 KZT/kg
      expect(Money.calculateWeightedPrice(100000, 1), 100);
    });

    test('rounding with odd weights', () {
      // 333g at 1000 KZT/kg
      expect(Money.calculateWeightedPrice(100000, 333), 33300);
      // 999g at 1000 KZT/kg
      expect(Money.calculateWeightedPrice(100000, 999), 99900);
    });

    test('small prices', () {
      // 500g at 1 tiyin/kg
      expect(Money.calculateWeightedPrice(1, 500), 1);
      // 100g at 1 tiyin/kg -> (100 + 500) / 1000 = 0
      expect(Money.calculateWeightedPrice(1, 100), 0);
    });
  });

  // -------------------------------------------------------------------------
  // Money.calculateVat
  // -------------------------------------------------------------------------
  // calculateVat uses INTEGER TRUNCATION (parity with .NET Calculator.VatFromInside
  // and Go domain.CalculateVAT). NOT round. See test/calculator_parity_test.dart for
  // the canonical golden cases.
  group('Money.calculateVat', () {
    test('12% VAT from inside', () {
      // 11200 * 12 / 112 = 1200
      expect(Money.calculateVat(11200, 12), 1200);
      // 100000 * 12 / 112 = 10714.285... -> truncates to 10714
      expect(Money.calculateVat(100000, 12), 10714);
    });

    test('0% VAT returns 0', () {
      expect(Money.calculateVat(10000, 0), 0);
      expect(Money.calculateVat(0, 0), 0);
    });

    test('zero total returns 0', () {
      expect(Money.calculateVat(0, 12), 0);
    });

    test('large amounts truncate', () {
      // 1,000,000 * 12 / 112 = 107142.857... -> 107142 (truncated, not rounded)
      expect(Money.calculateVat(1000000, 12), 107142);
    });

    test('small amounts truncate', () {
      // 100 * 12 / 112 = 10.714... -> 10 (truncated, not rounded)
      expect(Money.calculateVat(100, 12), 10);
      // 1 * 12 / 112 = 0.107... -> 0
      expect(Money.calculateVat(1, 12), 0);
    });
  });
}
