import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables/stock_movements_table.dart';

/// Valid values for `stock_movements.reason`. Kept as constants (not an enum)
/// so the sync wire shape stays a plain string — central deserialises the same
/// set on the server side.
abstract final class StockMovementReason {
  static const sale = 'sale';
  static const returnMovement = 'return';
  static const delivery = 'delivery';
  static const adjustment = 'adjustment';
  static const writeoff = 'writeoff';
  static const recount = 'recount';

  static const all = {sale, returnMovement, delivery, adjustment, writeoff, recount};
}

/// Local-first stock-movement repository. Register-authoritative: every row
/// born here ships to central on the next outbox drain.
///
/// **Append-only**: no update, no delete. Mistakes get corrected with a
/// compensating movement (an `adjustment` with the opposite delta). This keeps
/// the audit trail intact and makes sync conflict-free — central accepts
/// insertions by `client_uuid` and never reconciles edits.
///
/// **`quantityOnHand(productId)`** is the fast read for the cart UI: a SUM over
/// the register's local movements. When the sync_puller applies other-register
/// movements for the same product, the sum updates automatically — no cache to
/// invalidate.
class StockMovementRepository {
  StockMovementRepository(
    this._db, {
    required String tenantId,
    required String deviceId,
  })  : _tenantId = tenantId,
        _deviceId = deviceId;

  final AppDatabase _db;
  final String _tenantId;
  final String _deviceId;
  static const _uuid = Uuid();

  /// Record a movement AND enqueue the push in one drift transaction.
  /// Returns the generated client_uuid so the caller (e.g. receipt builder)
  /// can link the receipt row to this movement via `receipt_id`.
  Future<String> record({
    String? clientUuid,
    String? storeId,
    required String productId,
    required int delta,
    required String reason,
    String? cashierUserId,
    String? overrideByUserId,
    String? receiptId,
  }) async {
    assert(
      StockMovementReason.all.contains(reason),
      'unknown stock_movements.reason: $reason',
    );
    final uuid = clientUuid ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.stockMovementsTable).insert(
            StockMovementsTableCompanion.insert(
              clientUuid: uuid,
              tenantId: _tenantId,
              storeId: Value(storeId),
              productId: productId,
              delta: delta,
              reason: reason,
              deviceId: _deviceId,
              cashierUserId: Value(cashierUserId),
              overrideByUserId: Value(overrideByUserId),
              receiptId: Value(receiptId),
              createdAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'stock_movements',
              op: 'insert',
              uuid: uuid,
              payloadJson: jsonEncode({
                'client_uuid': uuid,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'product_id': productId,
                'delta': delta,
                'reason': reason,
                'device_id': _deviceId,
                'cashier_user_id': cashierUserId,
                'override_by_user_id': overrideByUserId,
                'receipt_id': receiptId,
                'created_at': now.toIso8601String(),
              }),
              createdAt: now,
            ),
          );
    });
    return uuid;
  }

  /// Current stock on hand for one product, aggregated from this register's
  /// own movements plus any pulled from other registers (sync_puller feeds
  /// the same table). Returns 0 when the product has no movements yet.
  ///
  /// For piece goods: pieces. For weighted: grams.
  Future<int> quantityOnHand(String productId, {String? storeId}) async {
    final rows = await _buildQuery(productId, storeId: storeId).get();
    return rows.fold<int>(0, (sum, r) => sum + r.delta);
  }

  /// Reactive variant. Bind to `StreamBuilder` / BLoC so the cart refreshes as
  /// movements land (either from the cashier's own ops or from sync_puller).
  Stream<int> watchQuantityOnHand(String productId, {String? storeId}) {
    return _buildQuery(productId, storeId: storeId)
        .watch()
        .map((rows) => rows.fold<int>(0, (sum, r) => sum + r.delta));
  }

  /// History for one product (most recent first). Used by the admin's stock
  /// audit view; cashier UI doesn't call this on the hot path.
  ///
  /// Ordered by `createdAt DESC` with a tiebreak on the surrogate `id`. The
  /// tiebreak matters: two inserts inside the same millisecond (common on a
  /// fast cash-register tap sequence) would otherwise sort arbitrarily.
  Future<List<StockMovementRow>> historyFor(String productId, {int limit = 100}) {
    final q = _db.select(_db.stockMovementsTable)
      ..where((s) => s.tenantId.equals(_tenantId) & s.productId.equals(productId))
      ..orderBy([
        (s) => OrderingTerm.desc(s.createdAt),
        (s) => OrderingTerm.desc(s.id),
      ])
      ..limit(limit);
    return q.get();
  }

  SimpleSelectStatement<StockMovementsTable, StockMovementRow> _buildQuery(
    String productId, {
    String? storeId,
  }) {
    final q = _db.select(_db.stockMovementsTable)
      ..where((s) => s.tenantId.equals(_tenantId) & s.productId.equals(productId));
    if (storeId != null) {
      // Include tenant-wide movements (store_id NULL) too — matches how products
      // scope queries in ProductRepository.
      q.where((s) => s.storeId.isNull() | s.storeId.equals(storeId));
    }
    return q;
  }
}
