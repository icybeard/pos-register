import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';

/// Per-receipt totals the shift needs to roll up. Passed to
/// [ShiftRepository.recordReceipt] by the receipt creation path so the shift's
/// running Z-report stays accurate offline.
class ShiftReceiptTotals {
  const ShiftReceiptTotals({
    required this.totalAmountTiyin,
    this.cashAmountTiyin = 0,
    this.cardAmountTiyin = 0,
    this.qrAmountTiyin = 0,
    this.debtAmountTiyin = 0,
    this.isReturn = false,
  });

  final int totalAmountTiyin;
  final int cashAmountTiyin;
  final int cardAmountTiyin;
  final int qrAmountTiyin;
  final int debtAmountTiyin;
  final bool isReturn;
}

/// Register-side shift lifecycle. Unlike receipts (append-only) shifts mutate
/// over their lifetime — every open/update/close writes a `sync_outbox` row,
/// central applies upserts via its SyncPushHandler.
///
/// The [recordReceipt] method is called by the receipt creation flow AFTER
/// the receipt commits, so the totals match what went out on the printer
/// even if the outbox-push to central is delayed for hours. Offline-safe by
/// design.
class ShiftRepository {
  ShiftRepository(this._db, {required String tenantId}) : _tenantId = tenantId;

  final AppDatabase _db;
  final String _tenantId;
  static const _uuid = Uuid();

  /// Find the currently-open shift for this (workstation, cashier) pair.
  /// Returns null if the cashier hasn't opened a shift yet.
  ///
  /// Central-enforced invariant: at most one open shift per workstation per
  /// cashier. The register trusts that and doesn't double-check.
  Future<ShiftRow?> currentOpen({
    required String workstationId,
    required String userId,
  }) async {
    final q = _db.select(_db.shiftsTable)
      ..where((s) =>
          s.tenantId.equals(_tenantId) &
          s.workstationId.equals(workstationId) &
          s.userId.equals(userId) &
          s.closedAt.isNull())
      ..orderBy([(s) => OrderingTerm.desc(s.openedAt)])
      ..limit(1);
    return q.getSingleOrNull();
  }

  /// Fetch an open shift by id. Throws if missing or closed — used by the
  /// sales flow when it needs the receipt counter from a shift it already
  /// knows the id of (e.g. the cashier's active shift carried in BLoC state).
  Future<ShiftRow> currentOpenById(String shiftId) => _requireOpen(shiftId);

  /// Open a new shift. Returns the new shift id. Caller supplies the
  /// workstation-scoped `shiftNumber` (typically prior shift count + 1 —
  /// computed outside the repository so the Z-report counter stays in sync
  /// with the cashier's expectations on a replaced device).
  Future<String> open({
    String? shiftId,
    String? storeId,
    required String workstationId,
    required String userId,
    required int shiftNumber,
    int cashStartTiyin = 0,
  }) async {
    final newId = shiftId ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.shiftsTable).insert(
            ShiftsTableCompanion.insert(
              id: newId,
              tenantId: _tenantId,
              storeId: Value(storeId),
              workstationId: workstationId,
              userId: userId,
              shiftNumber: shiftNumber,
              openedAt: now,
              cashStartTiyin: Value(cashStartTiyin),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'shifts',
              op: 'insert',
              uuid: newId,
              payloadJson: jsonEncode({
                'id': newId,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'workstation_id': workstationId,
                'user_id': userId,
                'shift_number': shiftNumber,
                'opened_at': now.toIso8601String(),
                'cash_start_tiyin': cashStartTiyin,
              }),
              createdAt: now,
            ),
          );
    });
    return newId;
  }

  /// Bump running totals after a receipt commits. Idempotent the caller is
  /// responsible for calling this EXACTLY once per receipt — the receipt flow
  /// guarantees that via its atomic transaction.
  ///
  /// Returns after the write lands. Throws if the shift is closed (caller bug).
  Future<void> recordReceipt(String shiftId, ShiftReceiptTotals totals) async {
    await _db.transaction(() async {
      final existing = await _requireOpen(shiftId);
      final now = DateTime.now().toUtc();

      final updated = totals.isReturn
          ? existing.copyWith(
              totalReturnsTiyin: existing.totalReturnsTiyin + totals.totalAmountTiyin.abs(),
              returnCount: existing.returnCount + 1,
              updatedAt: now,
            )
          : existing.copyWith(
              totalSalesTiyin: existing.totalSalesTiyin + totals.totalAmountTiyin,
              totalCashTiyin: existing.totalCashTiyin + totals.cashAmountTiyin,
              totalCardTiyin: existing.totalCardTiyin + totals.cardAmountTiyin,
              totalQrTiyin: existing.totalQrTiyin + totals.qrAmountTiyin,
              totalDebtTiyin: existing.totalDebtTiyin + totals.debtAmountTiyin,
              receiptCount: existing.receiptCount + 1,
              updatedAt: now,
            );

      await _db.update(_db.shiftsTable).replace(updated);
      await _enqueueUpdate(updated, now);
    });
  }

  /// Close the shift. Stamps `closed_at` and `cash_end_tiyin`. After close the
  /// register refuses further mutations (see [_requireOpen]); central-side
  /// admin reconciliation can still adjust the row.
  Future<void> close(String shiftId, {required int cashEndTiyin}) async {
    await _db.transaction(() async {
      final existing = await _requireOpen(shiftId);
      final now = DateTime.now().toUtc();

      final closed = existing.copyWith(
        closedAt: Value(now),
        cashEndTiyin: cashEndTiyin,
        updatedAt: now,
      );
      await _db.update(_db.shiftsTable).replace(closed);
      await _enqueueUpdate(closed, now);
    });
  }

  Future<ShiftRow> _requireOpen(String shiftId) async {
    final q = _db.select(_db.shiftsTable)
      ..where((s) => s.tenantId.equals(_tenantId) & s.id.equals(shiftId));
    final row = await q.getSingleOrNull();
    if (row == null) throw StateError('shift $shiftId not found');
    if (row.closedAt != null) {
      throw StateError('shift $shiftId is closed — register cannot mutate it');
    }
    return row;
  }

  Future<void> _enqueueUpdate(ShiftRow row, DateTime now) async {
    await _db.into(_db.syncOutboxTable).insert(
          SyncOutboxTableCompanion.insert(
            targetTable: 'shifts',
            op: 'update',
            uuid: row.id,
            payloadJson: jsonEncode({
              'id': row.id,
              'closed_at': row.closedAt?.toIso8601String(),
              'cash_start_tiyin': row.cashStartTiyin,
              'cash_end_tiyin': row.cashEndTiyin,
              'total_sales_tiyin': row.totalSalesTiyin,
              'total_cash_tiyin': row.totalCashTiyin,
              'total_card_tiyin': row.totalCardTiyin,
              'total_qr_tiyin': row.totalQrTiyin,
              'total_debt_tiyin': row.totalDebtTiyin,
              'total_returns_tiyin': row.totalReturnsTiyin,
              'total_deposits_tiyin': row.totalDepositsTiyin,
              'total_withdrawals_tiyin': row.totalWithdrawalsTiyin,
              'receipt_count': row.receiptCount,
              'return_count': row.returnCount,
            }),
            createdAt: now,
          ),
        );
  }
}
