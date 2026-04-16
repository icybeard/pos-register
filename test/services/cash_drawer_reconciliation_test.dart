import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/shift_repository.dart';
import 'package:pos_system/services/reconciliation/cash_drawer_reconciliation.dart';

void main() {
  late AppDatabase db;
  late ShiftRepository shifts;
  const tenantId = '11111111-1111-1111-1111-111111111111';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    shifts = ShiftRepository(db, tenantId: tenantId);
  });

  tearDown(() async => db.close());

  Future<ShiftRow> seedShift({
    int cashStartTiyin = 0,
  }) async {
    final id = await shifts.open(
      workstationId: 'ws-1',
      userId: 'cashier-1',
      shiftNumber: 1,
      cashStartTiyin: cashStartTiyin,
    );
    return (await shifts.currentOpenById(id));
  }

  test('expected = cash_start on a freshly-opened shift with no activity', () async {
    final s = await seedShift(cashStartTiyin: 10_000);
    expect(CashDrawerReconciliation.expectedCashTiyin(s), 10_000);
  });

  test('expected rolls up cash receipts', () async {
    final s = await seedShift(cashStartTiyin: 10_000);
    // Post a pure-cash sale through the shift's recordReceipt to roll up
    // total_cash (the real write path that central + reports read from).
    await shifts.recordReceipt(
      s.id,
      const ShiftReceiptTotals(totalAmountTiyin: 25_000, cashAmountTiyin: 25_000),
    );
    final updated = await shifts.currentOpenById(s.id);
    expect(CashDrawerReconciliation.expectedCashTiyin(updated), 35_000);
  });

  test('card + qr + debt receipts do NOT touch expected cash', () async {
    final s = await seedShift(cashStartTiyin: 10_000);
    await shifts.recordReceipt(
      s.id,
      const ShiftReceiptTotals(
        totalAmountTiyin: 50_000,
        cardAmountTiyin: 30_000,
        qrAmountTiyin: 15_000,
        debtAmountTiyin: 5_000,
      ),
    );
    final updated = await shifts.currentOpenById(s.id);
    // Non-cash payments don't hit the drawer — expected unchanged.
    expect(CashDrawerReconciliation.expectedCashTiyin(updated), 10_000);
  });

  test('returns reduce expected cash (money handed back)', () async {
    final s = await seedShift(cashStartTiyin: 10_000);
    await shifts.recordReceipt(
      s.id,
      const ShiftReceiptTotals(totalAmountTiyin: 20_000, cashAmountTiyin: 20_000),
    );
    await shifts.recordReceipt(
      s.id,
      // Return: totalAmount is stored as |amount| on the shift's returns roll-up
      const ShiftReceiptTotals(totalAmountTiyin: 5_000, isReturn: true),
    );
    final updated = await shifts.currentOpenById(s.id);
    // 10_000 start + 20_000 cash sales − 5_000 returned = 25_000
    expect(CashDrawerReconciliation.expectedCashTiyin(updated), 25_000);
  });

  test('compute classifies tier correctly', () async {
    final s = await seedShift(cashStartTiyin: 60_000);

    final match = CashDrawerReconciliation.compute(s, 60_000);
    expect(match.varianceTiyin, 0);
    expect(match.tier, CashDrawerOutcomeTier.match);

    final short = CashDrawerReconciliation.compute(s, 59_500);
    expect(short.varianceTiyin, -500);
    expect(short.tier, CashDrawerOutcomeTier.short);

    final over = CashDrawerReconciliation.compute(s, 60_200);
    expect(over.varianceTiyin, 200);
    expect(over.tier, CashDrawerOutcomeTier.over);
  });

  test('matches server expected formula byte-for-byte on a realistic 3-sale + 1-return day', () async {
    // This test's numbers are the SAME as `ReconciliationTests.Expected_formula_respects_all_six_components`
    // on the server: cash_start 10_000, total_cash 50_000, returns 1_500.
    // Deposits + withdrawals are not exercised here (no drift-side write path
    // for them yet — plan §7 calls them out as a separate screen wave).
    final s = await seedShift(cashStartTiyin: 10_000);
    await shifts.recordReceipt(
      s.id,
      const ShiftReceiptTotals(totalAmountTiyin: 20_000, cashAmountTiyin: 20_000),
    );
    await shifts.recordReceipt(
      s.id,
      const ShiftReceiptTotals(totalAmountTiyin: 15_000, cashAmountTiyin: 15_000),
    );
    await shifts.recordReceipt(
      s.id,
      const ShiftReceiptTotals(totalAmountTiyin: 15_000, cashAmountTiyin: 15_000),
    );
    await shifts.recordReceipt(
      s.id,
      const ShiftReceiptTotals(totalAmountTiyin: 1_500, isReturn: true),
    );

    final updated = await shifts.currentOpenById(s.id);
    // cash_start 10_000 + total_cash 50_000 − returns 1_500 = 58_500
    expect(CashDrawerReconciliation.expectedCashTiyin(updated), 58_500);
  });
}
