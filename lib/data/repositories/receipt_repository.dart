import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import 'stock_movement_repository.dart';

/// Input shape for one cart line — what the cashier sees on screen, before
/// the repository denormalises it onto a [ReceiptItemRow] and an attached
/// stock_movement.
class ReceiptLineInput {
  const ReceiptLineInput({
    required this.productId,
    required this.productName,
    this.productBarcode,
    this.quantity = 0,
    this.weightGrams,
    required this.unitPriceTiyin,
    required this.itemTotalTiyin,
    this.discountAmountTiyin = 0,
    this.vatRate = 12,
  });

  final String productId;
  final String productName;
  final String? productBarcode;
  final int quantity;
  final int? weightGrams;
  final int unitPriceTiyin;
  final int itemTotalTiyin;
  final int discountAmountTiyin;
  final int vatRate;

  /// Stock-movement delta this line produces. Negative for sales (outflow);
  /// `is_return` flips the sign at the call site.
  ///
  /// For weighted goods: -weight_grams. For piece goods: -quantity.
  int get stockDelta {
    if (weightGrams != null) return -weightGrams!;
    return -quantity;
  }
}

/// Outcome of a successful create — gives the BLoC the new receipt id, the
/// items it materialised, and the stock-movement uuids it queued. UI uses the
/// movement uuids to scope optimistic stock-on-hand updates.
class ReceiptCreateResult {
  const ReceiptCreateResult({
    required this.receiptId,
    required this.itemIds,
    required this.stockMovementUuids,
  });
  final String receiptId;
  final List<String> itemIds;
  final List<String> stockMovementUuids;
}

/// Local-first receipts. Register-authoritative, append-only after creation
/// (returns are modelled as a NEW receipt, not a mutation). The single hot
/// path is [createReceipt] — atomic across receipt header + N items + N
/// stock_movements + outbox rows. If any insert throws, the whole tx rolls
/// back and central never sees a partial transaction.
class ReceiptRepository {
  ReceiptRepository(
    this._db, {
    required String tenantId,
    required String deviceId,
  })  : _tenantId = tenantId,
        _stockRepo = StockMovementRepository(
          _db,
          tenantId: tenantId,
          deviceId: deviceId,
        );

  final AppDatabase _db;
  final String _tenantId;
  final StockMovementRepository _stockRepo;
  static const _uuid = Uuid();

  /// Create a receipt + items + stock_movements + outbox rows in ONE drift
  /// transaction. Drift's nested `transaction()` calls join the outer tx via
  /// SAVEPOINTs, so the call into [StockMovementRepository.record] is part of
  /// the same atomic unit — the whole thing commits, or nothing does.
  ///
  /// `receiptNumber` is per-shift monotonic; the caller computes it
  /// (`shifts.receipt_count + 1`) since shifts can be open offline and we
  /// don't have a server sequence to lean on.
  Future<ReceiptCreateResult> createReceipt({
    String? receiptId,
    String? storeId,
    required String workstationId,
    required String shiftId,
    required String userId,
    required int receiptNumber,
    required List<ReceiptLineInput> lines,
    required int totalAmountTiyin,
    required int vatAmountTiyin,
    int discountAmountTiyin = 0,
    int changeAmountTiyin = 0,
    int cashAmountTiyin = 0,
    int cardAmountTiyin = 0,
    int qrAmountTiyin = 0,
    int debtAmountTiyin = 0,
    bool isReturn = false,
    String? refundForReceiptId,
    String? clientId,
    String? debtId,
    /// UUID of the manager who authorised an oversell, if any. Stamped onto
    /// every stock_movement this receipt emits so EOD reports can surface the
    /// override chain. Null on non-oversell sales.
    String? overrideByUserId,
  }) async {
    if (lines.isEmpty) {
      throw ArgumentError('cannot create a receipt with zero lines');
    }
    final newReceiptId = receiptId ?? _uuid.v4();
    final now = DateTime.now().toUtc();

    final itemIds = <String>[];
    final movementUuids = <String>[];

    await _db.transaction(() async {
      // 1. Receipt header
      await _db.into(_db.receiptsTable).insert(
            ReceiptsTableCompanion.insert(
              id: newReceiptId,
              tenantId: _tenantId,
              storeId: Value(storeId),
              workstationId: workstationId,
              shiftId: shiftId,
              userId: userId,
              receiptNumber: receiptNumber,
              totalAmountTiyin: totalAmountTiyin,
              vatAmountTiyin: vatAmountTiyin,
              discountAmountTiyin: Value(discountAmountTiyin),
              changeAmountTiyin: Value(changeAmountTiyin),
              cashAmountTiyin: Value(cashAmountTiyin),
              cardAmountTiyin: Value(cardAmountTiyin),
              qrAmountTiyin: Value(qrAmountTiyin),
              debtAmountTiyin: Value(debtAmountTiyin),
              isReturn: Value(isReturn),
              refundForReceiptId: Value(refundForReceiptId),
              clientId: Value(clientId),
              debtId: Value(debtId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'receipts',
              op: 'insert',
              uuid: newReceiptId,
              payloadJson: jsonEncode({
                'id': newReceiptId,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'workstation_id': workstationId,
                'shift_id': shiftId,
                'user_id': userId,
                'receipt_number': receiptNumber,
                'total_amount_tiyin': totalAmountTiyin,
                'vat_amount_tiyin': vatAmountTiyin,
                'discount_amount_tiyin': discountAmountTiyin,
                'change_amount_tiyin': changeAmountTiyin,
                'cash_amount_tiyin': cashAmountTiyin,
                'card_amount_tiyin': cardAmountTiyin,
                'qr_amount_tiyin': qrAmountTiyin,
                'debt_amount_tiyin': debtAmountTiyin,
                'is_return': isReturn,
                'refund_for_receipt_id': refundForReceiptId,
                'client_id': clientId,
                'debt_id': debtId,
                'created_at': now.toIso8601String(),
              }),
              createdAt: now,
            ),
          );

      // 2. Items + matching stock_movements
      for (final line in lines) {
        final itemId = _uuid.v4();
        itemIds.add(itemId);

        await _db.into(_db.receiptItemsTable).insert(
              ReceiptItemsTableCompanion.insert(
                id: itemId,
                tenantId: _tenantId,
                receiptId: newReceiptId,
                productId: line.productId,
                productName: line.productName,
                productBarcode: Value(line.productBarcode),
                quantity: Value(line.quantity),
                weightGrams: Value(line.weightGrams),
                unitPriceTiyin: line.unitPriceTiyin,
                itemTotalTiyin: line.itemTotalTiyin,
                discountAmountTiyin: Value(line.discountAmountTiyin),
                vatRate: Value(line.vatRate),
              ),
            );
        await _db.into(_db.syncOutboxTable).insert(
              SyncOutboxTableCompanion.insert(
                targetTable: 'receipt_items',
                op: 'insert',
                uuid: itemId,
                payloadJson: jsonEncode({
                  'id': itemId,
                  'tenant_id': _tenantId,
                  'receipt_id': newReceiptId,
                  'product_id': line.productId,
                  'product_name': line.productName,
                  'product_barcode': line.productBarcode,
                  'quantity': line.quantity,
                  'weight_grams': line.weightGrams,
                  'unit_price_tiyin': line.unitPriceTiyin,
                  'item_total_tiyin': line.itemTotalTiyin,
                  'discount_amount_tiyin': line.discountAmountTiyin,
                  'vat_rate': line.vatRate,
                }),
                createdAt: now,
              ),
            );

        // Stock_movement. Returns flip the sign (positive = stock back in).
        final delta = isReturn ? -line.stockDelta : line.stockDelta;
        final movementUuid = await _stockRepo.record(
          storeId: storeId,
          productId: line.productId,
          delta: delta,
          reason: isReturn
              ? StockMovementReason.returnMovement
              : StockMovementReason.sale,
          cashierUserId: userId,
          // Stamped on EVERY movement of an override-authorised sale, not
          // only the lines that caused the shortage — EOD reports want to
          // scope the whole receipt as override-authorised, and it's the
          // cleanest way to join back to the authorising manager.
          overrideByUserId: overrideByUserId,
          receiptId: newReceiptId,
        );
        movementUuids.add(movementUuid);
      }
    });

    return ReceiptCreateResult(
      receiptId: newReceiptId,
      itemIds: itemIds,
      stockMovementUuids: movementUuids,
    );
  }

  /// One-shot read for receipt detail / reprint flows.
  Future<ReceiptRow?> getById(String id) {
    final q = _db.select(_db.receiptsTable)
      ..where((r) => r.tenantId.equals(_tenantId) & r.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<List<ReceiptItemRow>> itemsFor(String receiptId) {
    final q = _db.select(_db.receiptItemsTable)
      ..where((i) => i.tenantId.equals(_tenantId) & i.receiptId.equals(receiptId));
    return q.get();
  }

  /// Recent receipts for the given shift, most-recent-first.
  /// Used by the shift-close screen and the reprint dialog.
  Future<List<ReceiptRow>> recentInShift(String shiftId, {int limit = 50}) {
    final q = _db.select(_db.receiptsTable)
      ..where((r) => r.tenantId.equals(_tenantId) & r.shiftId.equals(shiftId))
      ..orderBy([
        (r) => OrderingTerm.desc(r.createdAt),
        (r) => OrderingTerm.desc(r.receiptNumber),
      ])
      ..limit(limit);
    return q.get();
  }
}
