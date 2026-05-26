import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/features/sales/models/cart_item.dart';

void main() {
  // -------------------------------------------------------------------------
  // Piece item total
  // -------------------------------------------------------------------------
  group('CartItem piece item total', () {
    test('single quantity', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Хлеб',
        unit: 'pcs',
        basePrice: 45000,
        quantity: 1,
      );
      expect(item.total, 45000);
    });

    test('multiple quantity', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Хлеб',
        unit: 'pcs',
        basePrice: 45000,
        quantity: 3,
      );
      expect(item.total, 135000);
    });

    test('fractional quantity truncates to int for pieces', () {
      // Per CartItem.total docstring: piece quantities are always integer;
      // the field is `double` only for storage uniformity with weighted's
      // stockQty comparison. Total uses `quantity.toInt()`, so 1.5 → 1.
      // No float math on money. (For weighted items, use weightGrams.)
      const item = CartItem(
        productId: 'p1',
        name: 'Item',
        unit: 'pcs',
        basePrice: 10000,
        quantity: 1.5,
      );
      expect(item.total, 10000);
    });
  });

  // -------------------------------------------------------------------------
  // Weighted item total (banker's rounding)
  // -------------------------------------------------------------------------
  group('CartItem weighted item total', () {
    test('standard weight calculation', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Сыр',
        unit: 'kg',
        basePrice: 320000,
        isWeighted: true,
        weightGrams: 450,
      );
      // (450 * 320000 + 500) / 1000 = 144000500 / 1000 = 144000
      expect(item.total, 144000);
    });

    test('1kg at known price', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Сыр',
        unit: 'kg',
        basePrice: 320000,
        isWeighted: true,
        weightGrams: 1000,
      );
      // (1000 * 320000 + 500) / 1000 = 320000
      expect(item.total, 320000);
    });

    test('small weight 1g', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Spice',
        unit: 'kg',
        basePrice: 100000,
        isWeighted: true,
        weightGrams: 1,
      );
      // (1 * 100000 + 500) / 1000 = 100
      expect(item.total, 100);
    });

    test('rounding behavior with odd amounts', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Item',
        unit: 'kg',
        basePrice: 100000,
        isWeighted: true,
        weightGrams: 333,
      );
      // (333 * 100000 + 500) / 1000 = 33300500 / 1000 = 33300
      expect(item.total, 33300);
    });

    test('zero weight returns zero plus rounding offset', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Сыр',
        unit: 'kg',
        basePrice: 320000,
        isWeighted: true,
        weightGrams: 0,
      );
      // (0 * 320000 + 500) / 1000 = 0 (integer division)
      expect(item.total, 0);
    });
  });

  // -------------------------------------------------------------------------
  // Item-level discount (clamped to 0)
  // -------------------------------------------------------------------------
  group('CartItem discount', () {
    test('discount reduces total', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Хлеб',
        unit: 'pcs',
        basePrice: 45000,
        quantity: 1,
        discount: 10000,
      );
      expect(item.total, 35000);
    });

    test('discount exceeding total clamped to 0', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Хлеб',
        unit: 'pcs',
        basePrice: 10000,
        quantity: 1,
        discount: 20000,
      );
      expect(item.total, 0);
    });

    test('discount on weighted item', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Сыр',
        unit: 'kg',
        basePrice: 320000,
        isWeighted: true,
        weightGrams: 450,
        discount: 44000,
      );
      // 144000 - 44000 = 100000
      expect(item.total, 100000);
    });

    test('zero discount has no effect', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Item',
        unit: 'pcs',
        basePrice: 10000,
        discount: 0,
      );
      expect(item.total, 10000);
    });
  });

  // -------------------------------------------------------------------------
  // VAT calculation (inside formula)
  // -------------------------------------------------------------------------
  group('CartItem vatAmount', () {
    test('12% VAT from inside', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 11200,
        quantity: 1,
        vatRate: 12,
      );
      // total = 11200, vat = 11200 * 12 / 112 = 1200
      expect(item.vatAmount, 1200);
    });

    test('0% VAT returns 0', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 11200,
        quantity: 1,
        vatRate: 0,
      );
      expect(item.vatAmount, 0);
    });

    test('VAT on larger amount', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 100000,
        quantity: 1,
        vatRate: 12,
      );
      // 100000 * 12 / 112 = 10714.285... -> 10714
      expect(item.vatAmount, 10714);
    });

    test('VAT on zero total is 0', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 10000,
        quantity: 1,
        discount: 20000,
        vatRate: 12,
      );
      // total = 0 (clamped), vat = 0 * 12 / 112 = 0
      expect(item.vatAmount, 0);
    });

    test('VAT on weighted item', () {
      const item = CartItem(
        productId: 'p2',
        name: 'Cheese',
        unit: 'kg',
        basePrice: 320000,
        isWeighted: true,
        weightGrams: 450,
        vatRate: 12,
      );
      // total = (450 * 320000 + 500) ~/ 1000 = 144000.
      // vat = 144000 * 12 ~/ 112 = 1_728_000 ~/ 112 = 15428 (truncating
      // integer division, NOT rounded). Mirrors .NET Calculator.VatFromInside
      // and the Go server — see calculator_parity_test.dart.
      expect(item.vatAmount, 15428);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith immutability
  // -------------------------------------------------------------------------
  group('CartItem copyWith', () {
    test('creates new instance with updated quantity', () {
      const original = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 10000,
        quantity: 1,
      );
      final updated = original.copyWith(quantity: 5);

      expect(updated.quantity, 5);
      expect(updated.total, 50000);
      // Original is unchanged
      expect(original.quantity, 1);
      expect(original.total, 10000);
    });

    test('creates new instance with updated weight', () {
      const original = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'kg',
        basePrice: 100000,
        isWeighted: true,
        weightGrams: 500,
      );
      final updated = original.copyWith(weightGrams: 1000);

      expect(updated.weightGrams, 1000);
      expect(updated.total, 100000);
      expect(original.weightGrams, 500);
      expect(original.total, 50000);
    });

    test('preserves all fields when no overrides', () {
      const original = CartItem(
        productId: 'p1',
        name: 'Test',
        ntin: 'ntin1',
        unit: 'pcs',
        basePrice: 10000,
        isWeighted: false,
        vatRate: 12,
        quantity: 2,
        weightGrams: 0,
        discount: 500,
      );
      final copy = original.copyWith();

      expect(copy.productId, original.productId);
      expect(copy.name, original.name);
      expect(copy.ntin, original.ntin);
      expect(copy.unit, original.unit);
      expect(copy.basePrice, original.basePrice);
      expect(copy.isWeighted, original.isWeighted);
      expect(copy.vatRate, original.vatRate);
      expect(copy.quantity, original.quantity);
      expect(copy.weightGrams, original.weightGrams);
      expect(copy.discount, original.discount);
    });

    test('can override multiple fields at once', () {
      const original = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 10000,
      );
      final updated = original.copyWith(
        name: 'New Name',
        basePrice: 20000,
        discount: 1000,
      );

      expect(updated.name, 'New Name');
      expect(updated.basePrice, 20000);
      expect(updated.discount, 1000);
    });
  });

  // -------------------------------------------------------------------------
  // Edge cases
  // -------------------------------------------------------------------------
  group('CartItem edge cases', () {
    test('zero quantity piece item', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 10000,
        quantity: 0,
      );
      expect(item.total, 0);
    });

    test('zero price', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Free Item',
        unit: 'pcs',
        basePrice: 0,
        quantity: 5,
      );
      expect(item.total, 0);
    });

    test('negative discount is rejected by Money.calculateItemTotal', () {
      // Money.calculateItemTotal asserts discountTiyin >= 0. The cart
      // building code already clamps user input to non-negative, so a
      // negative discount reaching this layer is a bug, not a user
      // condition — fail fast instead of silently producing inflated
      // totals.
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 10000,
        quantity: 1,
        discount: -5000,
      );
      expect(() => item.total, throwsArgumentError);
    });

    test('displayPrice returns basePrice', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 45000,
      );
      expect(item.displayPrice, 45000);
    });

    test('default values', () {
      const item = CartItem(
        productId: 'p1',
        name: 'Test',
        unit: 'pcs',
        basePrice: 10000,
      );
      expect(item.isWeighted, isFalse);
      expect(item.vatRate, 12);
      expect(item.quantity, 1);
      expect(item.weightGrams, 0);
      expect(item.discount, 0);
      expect(item.ntin, isNull);
    });
  });
}
