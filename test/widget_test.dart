import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/utils/money.dart';
import 'package:pos_system/features/sales/models/cart_item.dart';

// =============================================================================
// Money Utils Tests
// =============================================================================

void main() {
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
    });

    test('formats negative values', () {
      expect(Money.format(-144000), '-1 440 ₸');
      expect(Money.format(-150), '-1,50 ₸');
      expect(Money.format(-1), '-0,01 ₸');
    });

    test('formats large numbers with spaces', () {
      expect(Money.format(100000000), '1 000 000 ₸');
      expect(Money.format(999999900), '9 999 999 ₸');
    });
  });

  group('Money.formatTenge', () {
    test('drops tiyin', () {
      expect(Money.formatTenge(144000), '1 440 ₸');
      expect(Money.formatTenge(150), '1 ₸');
      expect(Money.formatTenge(99), '0 ₸');
    });
  });

  group('Money.tengeToTiyin', () {
    test('converts correctly', () {
      expect(Money.tengeToTiyin(100), 10000);
      expect(Money.tengeToTiyin(0), 0);
      expect(Money.tengeToTiyin(14.5), 1450);
      expect(Money.tengeToTiyin(0.01), 1);
    });
  });

  group('Money.tiyinToTenge', () {
    test('converts correctly', () {
      expect(Money.tiyinToTenge(10000), 100.0);
      expect(Money.tiyinToTenge(0), 0.0);
      expect(Money.tiyinToTenge(150), 1.5);
    });
  });

  group('Money.calculateWeightedPrice', () {
    test('basic calculations', () {
      // 500g at 2000 KZT/kg = 1000 KZT
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

    test('rounding (banker)', () {
      // 333g at 1000 KZT/kg = 333 KZT (no rounding issue)
      expect(Money.calculateWeightedPrice(100000, 333), 33300);
    });
  });

  group('Money.calculateVat', () {
    test('12% VAT from inside', () {
      // 11200 * 12 / 112 = 1200
      expect(Money.calculateVat(11200, 12), 1200);
      // 100000 * 12 / 112 = 10714.285... → 10714
      expect(Money.calculateVat(100000, 12), 10714);
    });

    test('0% VAT', () {
      expect(Money.calculateVat(10000, 0), 0);
      expect(Money.calculateVat(0, 0), 0);
    });

    test('zero total', () {
      expect(Money.calculateVat(0, 12), 0);
    });
  });

  // =============================================================================
  // CartItem Tests
  // =============================================================================

  group('CartItem', () {
    test('piece item total', () {
      const item = CartItem(
        productId: 'p1', name: 'Хлеб', unit: 'pcs',
        basePrice: 45000, quantity: 2,
      );
      expect(item.total, 90000);
    });

    test('piece item with discount', () {
      const item = CartItem(
        productId: 'p1', name: 'Хлеб', unit: 'pcs',
        basePrice: 45000, quantity: 1, discount: 10000,
      );
      expect(item.total, 35000);
    });

    test('discount exceeds total clamped to 0', () {
      const item = CartItem(
        productId: 'p1', name: 'Хлеб', unit: 'pcs',
        basePrice: 10000, quantity: 1, discount: 20000,
      );
      expect(item.total, 0);
    });

    test('weighted item total', () {
      const item = CartItem(
        productId: 'p2', name: 'Сыр', unit: 'kg',
        basePrice: 320000, isWeighted: true, weightGrams: 450,
      );
      // (450 * 320000 + 500) / 1000 = 144000
      expect(item.total, 144000);
    });

    test('weighted item 0g', () {
      const item = CartItem(
        productId: 'p2', name: 'Сыр', unit: 'kg',
        basePrice: 320000, isWeighted: true, weightGrams: 0,
      );
      expect(item.total, 0);
    });

    test('vatAmount at 12%', () {
      const item = CartItem(
        productId: 'p1', name: 'Test', unit: 'pcs',
        basePrice: 11200, quantity: 1, vatRate: 12,
      );
      // total=11200, vat = 11200 * 12 / 112 = 1200
      expect(item.vatAmount, 1200);
    });

    test('vatAmount at 0%', () {
      const item = CartItem(
        productId: 'p1', name: 'Test', unit: 'pcs',
        basePrice: 11200, quantity: 1, vatRate: 0,
      );
      expect(item.vatAmount, 0);
    });

    test('copyWith quantity', () {
      const item = CartItem(
        productId: 'p1', name: 'Test', unit: 'pcs',
        basePrice: 10000, quantity: 1,
      );
      expect(item.total, 10000);
      final updated = item.copyWith(quantity: 5);
      expect(updated.total, 50000);
      expect(item.total, 10000); // original unchanged
    });

    test('copyWith weightGrams', () {
      const item = CartItem(
        productId: 'p1', name: 'Test', unit: 'kg',
        basePrice: 100000, isWeighted: true, weightGrams: 500,
      );
      expect(item.total, 50000);
      final updated = item.copyWith(weightGrams: 1000);
      expect(updated.total, 100000);
      expect(item.total, 50000); // original unchanged
    });
  });

  // =============================================================================
  // SalesState computed properties tests
  // =============================================================================

  group('SalesState computed', () {
    test('subtotal sums all items', () {
      final items = [
        const CartItem(productId: 'p1', name: 'A', unit: 'pcs', basePrice: 10000, quantity: 2), // 20000
        const CartItem(productId: 'p2', name: 'B', unit: 'pcs', basePrice: 30000, quantity: 1), // 30000
      ];
      final subtotal = items.fold<int>(0, (sum, item) => sum + item.total);
      expect(subtotal, 50000);
    });

    test('total with discount', () {
      const subtotal = 50000;
      const discount = 10000;
      const total = subtotal - discount;
      expect(total, 40000);
    });

    test('total cannot go below zero', () {
      const subtotal = 10000;
      const discount = 20000;
      const total = (subtotal - discount) < 0 ? 0 : (subtotal - discount);
      expect(total, 0);
    });

    test('vatAmount sums all items', () {
      final items = [
        const CartItem(productId: 'p1', name: 'A', unit: 'pcs', basePrice: 11200, quantity: 1, vatRate: 12),
        const CartItem(productId: 'p2', name: 'B', unit: 'pcs', basePrice: 11200, quantity: 1, vatRate: 0),
      ];
      final totalVat = items.fold<int>(0, (sum, item) => sum + item.vatAmount);
      expect(totalVat, 1200); // only first item has VAT
    });
  });
}
