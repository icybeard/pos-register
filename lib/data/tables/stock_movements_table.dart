import 'package:drift/drift.dart';

/// Append-only stock change log. Register is authoritative: every sale, return,
/// delivery, adjustment, writeoff writes one row here + a matching `sync_outbox`
/// entry in the same drift transaction. Never updated, never deleted.
///
/// The register does NOT maintain a separate `stock` cache row — aggregate via
/// `SUM(delta)` grouped by `product_id` when the cart UI needs a live
/// stock-on-hand value. This keeps the write path a single insert and sidesteps
/// the classic "forgot to update the cache" bug class. Central runs the same
/// aggregation for cross-register consistency.
///
/// **Delta sign convention**: negative for outflow (sale, writeoff), positive
/// for inflow (delivery, return-to-stock). For weighted products, delta is in
/// grams; for piece goods, it's in pieces.
///
/// **Offline-first invariant**: `client_uuid` is generated on the register when
/// the row is born. Central's `(tenant_id, client_uuid)` unique index dedupes
/// replayed pushes — the outbox worker can retry safely on transient failure.
///
/// **Oversell audit**: when a cashier overrides a negative-stock sale,
/// `override_by_user_id` holds the manager's user id. EOD reports flag these.
@DataClassName('StockMovementRow')
class StockMovementsTable extends Table {
  /// Local auto-increment surrogate. Central re-keys on push via `client_uuid`;
  /// the register never serialises this id, so drift's default int PK is fine.
  IntColumn get id => integer().autoIncrement()();

  /// Stable UUID generated on this register. Sent to central for dedup.
  /// Unique locally too so a replayed client ops can't double-insert.
  TextColumn get clientUuid => text().named('client_uuid').unique()();

  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();
  TextColumn get productId => text().named('product_id')();

  /// Signed, in the product's native unit (grams for weighted, pieces for piece).
  IntColumn get delta => integer()();

  /// One of sale | return | delivery | adjustment | writeoff | recount.
  TextColumn get reason => text()();

  TextColumn get deviceId => text().named('device_id')();
  TextColumn get cashierUserId => text().named('cashier_user_id').nullable()();
  TextColumn get overrideByUserId => text().named('override_by_user_id').nullable()();

  /// FK to `receipts.id` when reason = sale or return. Nullable for
  /// delivery / adjustment / writeoff.
  TextColumn get receiptId => text().named('receipt_id').nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();

  @override
  String get tableName => 'stock_movements';
}
