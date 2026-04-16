import '../../data/repositories/stock_movement_repository.dart';
import '../sales/sales_service.dart';

/// Describes a single cart line that would drive stock below zero if sold.
/// The UI surfaces these in the `ManagerOverrideDialog.subtitle` so the
/// authorising manager sees exactly what they're approving.
class OversellShortage {
  const OversellShortage({
    required this.productId,
    required this.productName,
    required this.requested,
    required this.onHand,
    required this.isWeighted,
  });

  final String productId;
  final String productName;

  /// Units requested in the cart. Pieces for piece goods, grams for weighted.
  final int requested;

  /// Current on-hand as of the check. Can be negative already (previously
  /// authorised oversell that hasn't been replenished).
  final int onHand;

  /// Convenience: units the sale would push stock into the red by. Always > 0
  /// when this row exists — non-negative cases don't produce a shortage at all.
  int get shortageUnits => requested - onHand;

  final bool isWeighted;
}

/// Pre-sale stock check. Lives outside the BLoC so the UI layer can invoke it
/// BEFORE dispatching `CompleteSale` — BLoCs don't own a BuildContext and
/// can't pop modal dialogs. Flow:
///
///   1. Cashier taps "Pay"
///   2. UI calls `OversellGuard.check(lines)` → `List<OversellShortage>`
///   3. If empty, dispatch `CompleteSale` immediately
///   4. If non-empty, show `ManagerOverrideDialog` with the shortages as its
///      subtitle; on `ok`, dispatch `CompleteSale` with `overrideUserId` set
///   5. SalesService threads that id onto the stock_movements via
///      [StockMovementRepository.record]'s `overrideByUserId` param
///
/// **Scope**: reads current on-hand; does not lock. If two registers oversell
/// the same unit between the check and the receipt commit, both succeed. The
/// plan's stock model (Section 6.5) accepts that — distributed locks would
/// break offline operation. Central's reconciler flags the resulting
/// negative-stock row.
class OversellGuard {
  OversellGuard(this._stock, {this.storeId});

  final StockMovementRepository _stock;
  final String? storeId;

  /// Check each line's delta against current on-hand. Skips lines with
  /// stockDelta == 0 (non-decrementing, e.g. a zero-quantity line that
  /// shouldn't really be in the cart anyway).
  ///
  /// Returns one `OversellShortage` per line that would go negative.
  /// Empty list = no override needed.
  Future<List<OversellShortage>> check(List<SalesLineInput> lines) async {
    final shortages = <OversellShortage>[];
    for (final line in lines) {
      final decrement = line.isWeighted ? line.weightGrams : line.quantity;
      if (decrement <= 0) continue;
      final onHand = await _stock.quantityOnHand(line.productId, storeId: storeId);
      if (decrement > onHand) {
        shortages.add(OversellShortage(
          productId: line.productId,
          productName: line.productName,
          requested: decrement,
          onHand: onHand,
          isWeighted: line.isWeighted,
        ));
      }
    }
    return shortages;
  }
}
