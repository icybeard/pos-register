// Parity tests against the .NET Calculator (server-dotnet/src/Pos.Domain/Calculator.cs).
// Same inputs MUST produce the same outputs — receipt totals depend on this.
// If you change a formula here, change it in .NET too AND in the Go reference (until P9 deletes Go).
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/utils/money.dart';

void main() {
  group('Money.calculateWeightedPrice — golden parity with .NET / Go', () {
    final cases = <_WeightCase>[
      _WeightCase(1000, 250, 250),
      _WeightCase(100000, 1000, 100000),
      _WeightCase(100000, 500, 50000),
      _WeightCase(123456, 789, 97407),
      _WeightCase(0, 250, 0),
      _WeightCase(100000, 0, 0),
      // Banker's-rounding-via-+500-trick edges
      _WeightCase(1, 1, 0),
      _WeightCase(1, 999, 1),
      _WeightCase(1, 500, 1),
    ];
    for (final c in cases) {
      test('${c.pricePerKg} ₸/kg × ${c.weightGrams}g → ${c.expected} tiyin', () {
        expect(Money.calculateWeightedPrice(c.pricePerKg, c.weightGrams), c.expected);
      });
    }
  });

  group('Money.calculateVat — golden parity (integer truncation, NOT round)', () {
    final cases = <_VatCase>[
      _VatCase(11200, 12, 1200),
      _VatCase(10000, 12, 1071),
      _VatCase(0, 12, 0),
      _VatCase(10000, 0, 0),
      _VatCase(123456789, 12, 13227513), // big-number sanity
    ];
    for (final c in cases) {
      test('${c.total} tiyin @ ${c.vatRate}% → ${c.expected} tiyin VAT', () {
        expect(Money.calculateVat(c.total, c.vatRate), c.expected);
      });
    }
  });

  group('Money.calculateItemTotal — golden parity', () {
    test('3 × 250₸ piece → 750₸', () {
      expect(
        Money.calculateItemTotal(
          isWeighted: false, basePriceTiyin: 25000,
          quantity: 3, weightGrams: 0, discountTiyin: 0,
        ),
        75000,
      );
    });
    test('3 × 250₸ piece − 50₸ discount → 700₸', () {
      expect(
        Money.calculateItemTotal(
          isWeighted: false, basePriceTiyin: 25000,
          quantity: 3, weightGrams: 0, discountTiyin: 5000,
        ),
        70000,
      );
    });
    test('discount exceeds subtotal → clamp 0', () {
      expect(
        Money.calculateItemTotal(
          isWeighted: false, basePriceTiyin: 10000,
          quantity: 2, weightGrams: 0, discountTiyin: 100000,
        ),
        0,
      );
    });
    test('weighted 250g @ 1000₸/kg = 250₸', () {
      expect(
        Money.calculateItemTotal(
          isWeighted: true, basePriceTiyin: 100000,
          quantity: 0, weightGrams: 250, discountTiyin: 0,
        ),
        25000,
      );
    });
    test('weighted minus discount', () {
      expect(
        Money.calculateItemTotal(
          isWeighted: true, basePriceTiyin: 100000,
          quantity: 0, weightGrams: 250, discountTiyin: 5000,
        ),
        20000,
      );
    });
  });

  group('Money.calculateChange — golden parity', () {
    test('exact cash → 0', () {
      expect(Money.calculateChange(totalTiyin: 10000, cashTiyin: 10000, cardTiyin: 0, qrTiyin: 0), 0);
    });
    test('200₸ for 100₸ → 100₸ change', () {
      expect(Money.calculateChange(totalTiyin: 10000, cashTiyin: 20000, cardTiyin: 0, qrTiyin: 0), 10000);
    });
    test('split cash + card slight overpay → 10₸', () {
      expect(
        Money.calculateChange(totalTiyin: 10000, cashTiyin: 5000, cardTiyin: 6000, qrTiyin: 0),
        1000,
      );
    });
    test('underpaid → 0 (caller validates)', () {
      expect(Money.calculateChange(totalTiyin: 10000, cashTiyin: 5000, cardTiyin: 0, qrTiyin: 0), 0);
    });
  });

  group('Money.calculateItemTotal — argument validation', () {
    test('negative basePrice throws', () {
      expect(
        () => Money.calculateItemTotal(
          isWeighted: false, basePriceTiyin: -1,
          quantity: 1, weightGrams: 0, discountTiyin: 0,
        ),
        throwsArgumentError,
      );
    });
    test('negative discount throws', () {
      expect(
        () => Money.calculateItemTotal(
          isWeighted: false, basePriceTiyin: 100,
          quantity: 1, weightGrams: 0, discountTiyin: -1,
        ),
        throwsArgumentError,
      );
    });
  });

  // P5.T4: tighter parity coverage for the sales-path risks the plan calls out.
  // Split out into four sub-groups so a regression in one area doesn't mask others.
  //
  // Ported from the .NET `CalculatorTests` fixture. Any change here must land
  // in `server-dotnet/tests/Pos.Domain.Tests/CalculatorTests.cs` too, or receipt
  // totals will diverge between the register and central's reconciler.

  group('Money.calculateWeightedPrice — rounding boundary (half-up via +500)', () {
    // The +500 trick is half-up rounding: values with .5 fractional tiyin go UP.
    // Verified against the Go reference and .NET Calculator.WeightedPrice.
    final cases = <_WeightCase>[
      // Exact halves → round up (at price=10 tiyin/kg, 50g → 0.5 tiyin → rounds to 1)
      _WeightCase(10, 50, 1),
      _WeightCase(10, 150, 2), // 1.5 → 2
      _WeightCase(10, 250, 3), // 2.5 → 3
      // Below half → round down
      _WeightCase(10, 49, 0),  // 0.49 → 0
      _WeightCase(10, 149, 1), // 1.49 → 1
      // Just above half → round up
      _WeightCase(10, 51, 1),  // 0.51 → 1
      _WeightCase(10, 151, 2), // 1.51 → 2
      // High-precision: 1234 tiyin/kg × 789g = 973.626 tiyin → rounds to 974
      _WeightCase(1234, 789, 974),
      // Supermarket realistic: 350g of ≈800₸/kg cheese = 80000 × 350 / 1000 = 28000 tiyin (exact)
      _WeightCase(80000, 350, 28000),
      // A 2kg cut at 1499₸/kg = 149900 × 2000 / 1000 = 299800 (exact)
      _WeightCase(149900, 2000, 299800),
    ];
    for (final c in cases) {
      test('${c.pricePerKg} tiyin/kg × ${c.weightGrams}g = ${c.expected} tiyin', () {
        expect(Money.calculateWeightedPrice(c.pricePerKg, c.weightGrams), c.expected);
      });
    }
  });

  group('Money.calculateWeightedPrice — does not overflow at supermarket scale', () {
    test('50kg of a 12000₸/kg item — well under int64', () {
      // 1_200_000 × 50_000 = 60_000_000_000 (still < 2^63)
      expect(Money.calculateWeightedPrice(1200000, 50000), 60000000);
    });
  });

  group('Money.calculateVat — Kazakhstan rates (0 and 12)', () {
    // Only these two rates exist in KZ. Other values are accepted for future-proofing
    // but regressions are only caught against 0 and 12.
    final cases = <_VatCase>[
      // Boundary: 112 tiyin = 1.12₸ → 12 tiyin VAT (clean)
      _VatCase(112, 12, 12),
      // Boundary: 1 tiyin total → 0 VAT (truncates)
      _VatCase(1, 12, 0),
      // 11 tiyin → 11*12/112 = 1.178 → 1 (truncates)
      _VatCase(11, 12, 1),
      // 10_000_000 tiyin (100k₸) → 1_071_428 VAT
      _VatCase(10000000, 12, 1071428),
      // 0-rated item: any total → 0 VAT
      _VatCase(500000, 0, 0),
    ];
    for (final c in cases) {
      test('${c.total} tiyin @ ${c.vatRate}% → ${c.expected} tiyin VAT', () {
        expect(Money.calculateVat(c.total, c.vatRate), c.expected);
      });
    }
  });

  group('Money.calculateItemTotal — weighted × discount interaction', () {
    test('weighted 350g @ 800₸/kg = 280₸ (28000 tiyin)', () {
      expect(
        Money.calculateItemTotal(
          isWeighted: true, basePriceTiyin: 80000,
          quantity: 0, weightGrams: 350, discountTiyin: 0,
        ),
        28000,
      );
    });
    test('weighted with discount exactly equal to subtotal → 0', () {
      // 250g @ 1000₸/kg = 250₸, discount 250₸ → 0
      expect(
        Money.calculateItemTotal(
          isWeighted: true, basePriceTiyin: 100000,
          quantity: 0, weightGrams: 250, discountTiyin: 25000,
        ),
        0,
      );
    });
    test('weighted with discount 1 tiyin over subtotal → 0 (clamp)', () {
      expect(
        Money.calculateItemTotal(
          isWeighted: true, basePriceTiyin: 100000,
          quantity: 0, weightGrams: 250, discountTiyin: 25001,
        ),
        0,
      );
    });
    test('zero-price free sample → 0 regardless of discount', () {
      // Supermarket "free sample" product at 0₸. Discount is a no-op.
      expect(
        Money.calculateItemTotal(
          isWeighted: false, basePriceTiyin: 0,
          quantity: 5, weightGrams: 0, discountTiyin: 0,
        ),
        0,
      );
      expect(
        Money.calculateItemTotal(
          isWeighted: false, basePriceTiyin: 0,
          quantity: 5, weightGrams: 0, discountTiyin: 1000,
        ),
        0,
      );
    });
  });

  group('Money.calculateChange — payment-method semantics', () {
    test('debt does NOT reduce change (moves to A/R, not cash drawer)', () {
      // Debt paid 5000, cash paid 5000, total 10000 → NOT 0 change.
      // Change is computed from cash+card+qr ONLY. Debt is tracked separately.
      // This test encodes the contract; changing it would break shift totals.
      expect(
        Money.calculateChange(totalTiyin: 10000, cashTiyin: 5000, cardTiyin: 0, qrTiyin: 0),
        0,
        reason: 'cash alone underpaid → 0 change (caller validates underpayment)',
      );
    });
    test('all-card split — no cash, exact card match → 0 change', () {
      expect(
        Money.calculateChange(totalTiyin: 10000, cashTiyin: 0, cardTiyin: 10000, qrTiyin: 0),
        0,
      );
    });
    test('all-QR split — Kaspi QR pays the whole tab, no change', () {
      expect(
        Money.calculateChange(totalTiyin: 10000, cashTiyin: 0, cardTiyin: 0, qrTiyin: 10000),
        0,
      );
    });
    test('triple split slightly over → change from the overage', () {
      // 3000 + 4000 + 5000 = 12000 paid, 10000 total → 2000 change
      expect(
        Money.calculateChange(totalTiyin: 10000, cashTiyin: 3000, cardTiyin: 4000, qrTiyin: 5000),
        2000,
      );
    });
  });
}

class _WeightCase {
  _WeightCase(this.pricePerKg, this.weightGrams, this.expected);
  final int pricePerKg;
  final int weightGrams;
  final int expected;
}

class _VatCase {
  _VatCase(this.total, this.vatRate, this.expected);
  final int total;
  final int vatRate;
  final int expected;
}
