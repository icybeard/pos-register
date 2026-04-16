import '../../data/database.dart';

/// Register-side cash-drawer reconciliation — the cashier-facing version of
/// the central `ReconcileShiftsQuery`. Runs entirely on the register so the
/// cashier sees the expected/actual/variance immediately when they tap
/// "close shift"; central's reconcile endpoint is what the OWNER uses later
/// to cross-check all registers from admin.
///
/// **Same expected-cash formula** as central (plan §7, Z-report contract):
///
///   expected = cash_start + total_cash + total_deposits − total_withdrawals − total_returns
///
/// Keeping the math identical on both sides matters: if the cashier sees
/// "drawer short 500₸" at close-time and the owner later sees "drawer short
/// 700₸" for the same shift, that's a bug, not a timing issue. The shift
/// row is register-authoritative until close; once synced, central reads
/// the same columns.
class CashDrawerReconciliation {
  const CashDrawerReconciliation._();

  /// Expected cash in the drawer given the shift's running totals.
  ///
  /// The shift row the cashier passes in should be the live drift row —
  /// `ShiftRepository.currentOpen(...)` or the one picked by id. Mutating
  /// totals mid-reconcile (extremely unlikely but possible on a fast cart
  /// finalising during shift close) is not guarded here; caller should
  /// snapshot before computing if they care.
  static int expectedCashTiyin(ShiftRow shift) {
    return shift.cashStartTiyin
        + shift.totalCashTiyin
        + shift.totalDepositsTiyin
        - shift.totalWithdrawalsTiyin
        - shift.totalReturnsTiyin;
  }

  /// Variance = counted − expected. Negative = drawer short, positive = over.
  /// Matches the sign convention on central's `/api/reconciliation/compute`.
  static int varianceTiyin(ShiftRow shift, int countedCashTiyin) {
    return countedCashTiyin - expectedCashTiyin(shift);
  }

  /// Bundle the three numbers the close-shift UI renders. Returns a value
  /// rather than mutating anything — the act of persisting the variance is
  /// the caller's decision (e.g. `ShiftRepository.close(cashEndTiyin: ...)`
  /// writes `cash_end` but not an explicit variance column, since central
  /// can recompute).
  static CashDrawerOutcome compute(ShiftRow shift, int countedCashTiyin) {
    final expected = expectedCashTiyin(shift);
    return CashDrawerOutcome(
      expectedTiyin: expected,
      actualTiyin: countedCashTiyin,
      varianceTiyin: countedCashTiyin - expected,
    );
  }
}

class CashDrawerOutcome {
  const CashDrawerOutcome({
    required this.expectedTiyin,
    required this.actualTiyin,
    required this.varianceTiyin,
  });
  final int expectedTiyin;
  final int actualTiyin;
  final int varianceTiyin;

  /// Convenience classification for UI — red/amber/green badging typical.
  CashDrawerOutcomeTier get tier {
    if (varianceTiyin == 0) return CashDrawerOutcomeTier.match;
    if (varianceTiyin < 0) return CashDrawerOutcomeTier.short;
    return CashDrawerOutcomeTier.over;
  }
}

enum CashDrawerOutcomeTier {
  /// Counted matches expected to the tiyin. Normal close.
  match,
  /// Counted less than expected. Cashier may need to explain / refill.
  short,
  /// Counted more than expected. Unusual; log + review.
  over,
}
