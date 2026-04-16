import 'package:drift/drift.dart';

/// Cashier shift. One row per (cashier, workstation) session: opened with a
/// cash float, closed with reconciliation. All money in tiyin.
///
/// **Lifecycle**: unlike receipts (append-only), shifts mutate in place over
/// their lifetime — totals roll up as receipts land, deposits/withdrawals
/// adjust cash-on-hand, and close stamps `closed_at` + `cash_end_tiyin`.
/// Every mutation enqueues a sync_outbox row, central applies upserts.
///
/// **Authority**: register-authoritative while open (only this cashier can
/// ring into it), central-authoritative once closed (admin EOD reconciliation
/// can correct misentered floats). The register never mutates a shift with a
/// non-null `closed_at`.
@DataClassName('ShiftRow')
class ShiftsTable extends Table {
  TextColumn get id => text()();                                       // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();
  TextColumn get workstationId => text().named('workstation_id')();
  TextColumn get userId => text().named('user_id')();

  /// Per-workstation monotonic — printed on Z-reports. Caller computes.
  IntColumn get shiftNumber => integer().named('shift_number')();

  DateTimeColumn get openedAt => dateTime().named('opened_at')();
  DateTimeColumn get closedAt => dateTime().named('closed_at').nullable()();

  IntColumn get cashStartTiyin =>
      integer().named('cash_start_tiyin').withDefault(const Constant(0))();
  IntColumn get cashEndTiyin =>
      integer().named('cash_end_tiyin').withDefault(const Constant(0))();

  // Running totals — bumped by [ShiftRepository.recordReceipt]. Kept on the
  // shift row (not derived) so the Z-report can be printed offline and the
  // close screen doesn't need to scan every receipt for the shift.
  IntColumn get totalSalesTiyin =>
      integer().named('total_sales_tiyin').withDefault(const Constant(0))();
  IntColumn get totalCashTiyin =>
      integer().named('total_cash_tiyin').withDefault(const Constant(0))();
  IntColumn get totalCardTiyin =>
      integer().named('total_card_tiyin').withDefault(const Constant(0))();
  IntColumn get totalQrTiyin =>
      integer().named('total_qr_tiyin').withDefault(const Constant(0))();
  IntColumn get totalDebtTiyin =>
      integer().named('total_debt_tiyin').withDefault(const Constant(0))();
  IntColumn get totalReturnsTiyin =>
      integer().named('total_returns_tiyin').withDefault(const Constant(0))();
  IntColumn get totalDepositsTiyin =>
      integer().named('total_deposits_tiyin').withDefault(const Constant(0))();
  IntColumn get totalWithdrawalsTiyin =>
      integer().named('total_withdrawals_tiyin').withDefault(const Constant(0))();

  IntColumn get receiptCount =>
      integer().named('receipt_count').withDefault(const Constant(0))();
  IntColumn get returnCount =>
      integer().named('return_count').withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'shifts';
}
