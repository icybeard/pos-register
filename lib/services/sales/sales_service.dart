import '../../core/feature_flags.dart';
import '../../data/database.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../data/repositories/shift_repository.dart';
import '../api_client.dart';

/// One cart line in canonical form. Mirrors what the cashier sees on screen,
/// money in tiyin, weighted vs piece distinguished by [isWeighted].
class SalesLineInput {
  const SalesLineInput({
    required this.productId,
    required this.productName,
    this.productBarcode,
    this.ntin,
    required this.isWeighted,
    this.quantity = 0,
    this.weightGrams = 0,
    required this.unitPriceTiyin,
    required this.itemTotalTiyin,
    this.discountTiyin = 0,
    this.vatRate = 12,
    required this.unit, // 'pcs' | 'kg' | ...
  });

  final String productId;
  final String productName;
  final String? productBarcode;
  final String? ntin;
  final bool isWeighted;
  final int quantity;
  final int weightGrams;
  final int unitPriceTiyin;
  final int itemTotalTiyin;
  final int discountTiyin;
  final int vatRate;
  final String unit;
}

/// Aggregated payment + receipt-header data the BLoC has on hand at the moment
/// the cashier taps "Pay". Money in tiyin throughout.
class SalesCompletionInput {
  const SalesCompletionInput({
    required this.shiftId,
    required this.cashierId,
    required this.paymentType,
    required this.lines,
    required this.subtotalTiyin,
    required this.discountTiyin,
    required this.totalTiyin,
    required this.vatAmountTiyin,
    this.cashAmountTiyin = 0,
    this.cardAmountTiyin = 0,
    this.qrAmountTiyin = 0,
    this.debtAmountTiyin = 0,
    this.changeAmountTiyin = 0,
    this.isReturn = false,
    this.refundForReceiptId,
    this.clientId,
    this.overrideByUserId,
  });

  final String shiftId;
  final String cashierId;
  /// Free-form descriptor: 'cash' | 'card' | 'kaspiQR' | 'mixed' | 'debt'.
  /// Stored on neither side of the wire — the per-method amounts are the truth.
  final String paymentType;
  final List<SalesLineInput> lines;
  final int subtotalTiyin;
  final int discountTiyin;
  final int totalTiyin;
  final int vatAmountTiyin;
  final int cashAmountTiyin;
  final int cardAmountTiyin;
  final int qrAmountTiyin;
  final int debtAmountTiyin;
  final int changeAmountTiyin;
  final bool isReturn;
  final String? refundForReceiptId;
  final String? clientId;

  /// UUID of the manager who authorised an oversell. Stamped onto every
  /// stock_movement emitted by this sale so EOD reports can surface the audit
  /// trail ("receipt 1234 sold last unit of X under override by manager Y").
  /// Null on normal sales. UI obtains this from `ManagerOverrideDialog.show`
  /// via `OversellGuard` BEFORE dispatching `CompleteSale`.
  final String? overrideByUserId;
}

/// Returned by [SalesService.completeSale] so the BLoC can stash the new
/// receipt id (used by reprint / fiscal-status polling later).
class SalesCompletionResult {
  const SalesCompletionResult({required this.receiptId});
  final String receiptId;
}

/// Cashier "Pay" button — the single critical-path operation the sales BLoC
/// hands off when a customer tap-finishes a transaction. Two implementations
/// behind [createSalesService]:
///
///   - [DriftSalesService] writes locally (receipt + items + stock_movements +
///     shift roll-up) in one drift transaction; sync_outbox carries the rows
///     to central asynchronously. Survives offline.
///   - [LegacySalesService] hits the Go server's `POST /api/receipts`. No
///     offline support — Go is the source of truth for older builds.
///
/// Per the FeatureFlags rule, the BLoC consumes this interface and the factory
/// picks the impl from `FeatureFlags.useDriftSales`. Flipping the flag swaps
/// the data path with zero UI change.
abstract interface class SalesService {
  Future<SalesCompletionResult> completeSale(SalesCompletionInput input);
}

/// Drift-backed: one atomic local write, then sync_outbox does the rest.
class DriftSalesService implements SalesService {
  DriftSalesService(
    AppDatabase db, {
    required String tenantId,
    required String deviceId,
    required this.workstationId,
    this.storeId,
  })  : _shifts = ShiftRepository(db, tenantId: tenantId),
        _receipts = ReceiptRepository(
          db,
          tenantId: tenantId,
          deviceId: deviceId,
        );

  /// Workstation context. The BLoC doesn't carry these — they're injected at
  /// construction time from the same place that constructs `AppDatabase`.
  final String workstationId;
  final String? storeId;

  final ShiftRepository _shifts;
  final ReceiptRepository _receipts;

  @override
  Future<SalesCompletionResult> completeSale(SalesCompletionInput input) async {
    // Receipt number = shift.receiptCount + 1. Computed BEFORE the receipt
    // commits because the receipt's own commit will bump receiptCount via
    // _shifts.recordReceipt right after. If currentOpen returns null the
    // shift was never opened or has been closed — both are caller bugs.
    final shift = await _shifts.currentOpenById(input.shiftId);
    final receiptNumber = shift.receiptCount + (input.isReturn ? 0 : 1);

    final create = await _receipts.createReceipt(
      storeId: storeId,
      workstationId: workstationId,
      shiftId: input.shiftId,
      userId: input.cashierId,
      receiptNumber: receiptNumber,
      lines: input.lines.map(_toReceiptLine).toList(),
      totalAmountTiyin: input.totalTiyin,
      vatAmountTiyin: input.vatAmountTiyin,
      discountAmountTiyin: input.discountTiyin,
      changeAmountTiyin: input.changeAmountTiyin,
      cashAmountTiyin: input.cashAmountTiyin,
      cardAmountTiyin: input.cardAmountTiyin,
      qrAmountTiyin: input.qrAmountTiyin,
      debtAmountTiyin: input.debtAmountTiyin,
      isReturn: input.isReturn,
      refundForReceiptId: input.refundForReceiptId,
      clientId: input.clientId,
      overrideByUserId: input.overrideByUserId,
    );

    // Roll up the shift totals AFTER the receipt commits. If the recordReceipt
    // throws (e.g. shift was closed mid-flight), the receipt is still recorded
    // — that's a deliberate trade: better to have a real receipt with stale
    // shift totals than to lose the customer's transaction. EOD reconciliation
    // catches the drift.
    await _shifts.recordReceipt(
      input.shiftId,
      ShiftReceiptTotals(
        totalAmountTiyin: input.totalTiyin,
        cashAmountTiyin: input.cashAmountTiyin,
        cardAmountTiyin: input.cardAmountTiyin,
        qrAmountTiyin: input.qrAmountTiyin,
        debtAmountTiyin: input.debtAmountTiyin,
        isReturn: input.isReturn,
      ),
    );

    return SalesCompletionResult(receiptId: create.receiptId);
  }

  static ReceiptLineInput _toReceiptLine(SalesLineInput s) => ReceiptLineInput(
        productId: s.productId,
        productName: s.productName,
        productBarcode: s.productBarcode,
        quantity: s.quantity,
        weightGrams: s.isWeighted ? s.weightGrams : null,
        unitPriceTiyin: s.unitPriceTiyin,
        itemTotalTiyin: s.itemTotalTiyin,
        discountAmountTiyin: s.discountTiyin,
        vatRate: s.vatRate,
      );
}

/// HTTP-backed against the Go server. Single network call. No offline support;
/// fires `ApiException` on transport errors which the BLoC already handles.
///
/// Removed at P9 cutover when Go is deleted.
class LegacySalesService implements SalesService {
  LegacySalesService(this._api);

  final ApiClient _api;

  @override
  Future<SalesCompletionResult> completeSale(SalesCompletionInput input) async {
    final items = <Map<String, dynamic>>[];
    for (var i = 0; i < input.lines.length; i++) {
      final l = input.lines[i];
      items.add({
        'ProductID': l.productId,
        'Name': l.productName,
        'NTIN': l.ntin ?? '',
        // Go server expects `Quantity` as a float on this endpoint regardless
        // of piece-vs-weighted — kept as double to preserve byte-for-byte wire
        // parity with the pre-T5.5 inline code path.
        'Quantity': l.isWeighted ? (l.weightGrams / 1000.0) : l.quantity.toDouble(),
        'Unit': l.unit,
        'Price': l.unitPriceTiyin,
        'BasePrice': l.unitPriceTiyin,
        'Discount': l.discountTiyin,
        'Total': l.itemTotalTiyin,
        'VATRate': l.vatRate,
        'IsWeighted': l.isWeighted,
        'WeightGrams': l.weightGrams,
        'SortOrder': i + 1,
      });
    }

    final resp = await _api.createReceipt({
      'ShiftID': input.shiftId,
      'CashierID': input.cashierId,
      'Subtotal': input.subtotalTiyin,
      'Discount': input.discountTiyin,
      'Total': input.totalTiyin,
      'VATAmount': input.vatAmountTiyin,
      'PaymentType': input.paymentType,
      'CashAmount': input.cashAmountTiyin,
      'CardAmount': input.cardAmountTiyin,
      'QRAmount': input.qrAmountTiyin,
      'ChangeAmount': input.changeAmountTiyin,
      'FiscalStatus': 'pending',
      'Items': items,
    });

    // Go server may return the new receipt id under any of these keys depending
    // on version — be tolerant. If none match, fall back to a synthetic id.
    final id = (resp['ID'] ?? resp['id'] ?? resp['ReceiptID']) as String?;
    return SalesCompletionResult(
      receiptId: id ?? 'legacy-no-id-${DateTime.now().microsecondsSinceEpoch}',
    );
  }
}

/// Pick an impl based on [FeatureFlags.useDriftSales]. Constructed once per
/// authenticated session (workstation/tenant don't change mid-session) and
/// injected into the sales BLoC.
SalesService createSalesService({
  required FeatureFlags flags,
  required AppDatabase db,
  required ApiClient api,
  required String tenantId,
  required String deviceId,
  required String workstationId,
  String? storeId,
}) {
  if (flags.useDriftSales) {
    return DriftSalesService(
      db,
      tenantId: tenantId,
      deviceId: deviceId,
      workstationId: workstationId,
      storeId: storeId,
    );
  }
  return LegacySalesService(api);
}
