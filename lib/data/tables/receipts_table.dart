import 'package:drift/drift.dart';

/// Receipt header. One row per cashier transaction (sale OR return).
/// Items live in [ReceiptItemsTable]. All money in tiyin.
///
/// **Authority model**: register-authoritative — receipts are born here, never
/// updated locally after creation, and shipped to central via the outbox. The
/// only mutable column is `fiscal_id` / `fiscal_status` which central writes
/// back when Webkassa returns a fiscal reference (P8).
@DataClassName('ReceiptRow')
class ReceiptsTable extends Table {
  TextColumn get id => text()();                                       // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();
  TextColumn get workstationId => text().named('workstation_id')();
  TextColumn get shiftId => text().named('shift_id')();
  TextColumn get userId => text().named('user_id')();

  /// Per-shift monotonic — printed on the customer slip. Caller computes (eg.
  /// cashier-side counter); no DB-level sequence here because shifts can be
  /// open offline.
  IntColumn get receiptNumber => integer().named('receipt_number')();

  IntColumn get totalAmountTiyin => integer().named('total_amount_tiyin')();
  IntColumn get vatAmountTiyin => integer().named('vat_amount_tiyin')();
  IntColumn get discountAmountTiyin =>
      integer().named('discount_amount_tiyin').withDefault(const Constant(0))();
  IntColumn get changeAmountTiyin =>
      integer().named('change_amount_tiyin').withDefault(const Constant(0))();

  IntColumn get cashAmountTiyin =>
      integer().named('cash_amount_tiyin').withDefault(const Constant(0))();
  IntColumn get cardAmountTiyin =>
      integer().named('card_amount_tiyin').withDefault(const Constant(0))();
  IntColumn get qrAmountTiyin =>
      integer().named('qr_amount_tiyin').withDefault(const Constant(0))();
  IntColumn get debtAmountTiyin =>
      integer().named('debt_amount_tiyin').withDefault(const Constant(0))();

  BoolColumn get isReturn =>
      boolean().named('is_return').withDefault(const Constant(false))();

  /// FK to the original receipt for return/refund flows. Null on regular sales.
  TextColumn get refundForReceiptId =>
      text().named('refund_for_receipt_id').nullable()();

  TextColumn get clientId => text().named('client_id').nullable()();
  TextColumn get debtId => text().named('debt_id').nullable()();

  /// Set by central once Webkassa fiscalises the receipt. Pending until then.
  TextColumn get fiscalId => text().named('fiscal_id').nullable()();
  TextColumn get fiscalStatus =>
      text().named('fiscal_status').withDefault(const Constant('pending'))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'receipts';
}

/// Single line item on a receipt. Append-only — once a receipt is committed,
/// items are immutable. Returns are modelled as a NEW receipt with
/// `is_return = true` and `refund_for_receipt_id` pointing at the original.
@DataClassName('ReceiptItemRow')
class ReceiptItemsTable extends Table {
  TextColumn get id => text()();                                       // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get receiptId => text().named('receipt_id')();
  TextColumn get productId => text().named('product_id')();

  /// Snapshot taken at sale time so the line displays correctly even if the
  /// product is later renamed/deleted. Kazakh law also requires the printed
  /// name on the receipt to match what the cashier rang up.
  TextColumn get productName => text().named('product_name')();
  TextColumn get productBarcode => text().named('product_barcode').nullable()();

  /// For piece goods: count. For weighted: 0 (use [weightGrams]).
  IntColumn get quantity => integer().withDefault(const Constant(0))();
  IntColumn get weightGrams => integer().named('weight_grams').nullable()();

  /// Unit price in tiyin. For weighted, this is price-per-kg (so the line
  /// total = round(weight_grams / 1000 * unit_price_tiyin)).
  IntColumn get unitPriceTiyin => integer().named('unit_price_tiyin')();

  /// Computed line total after weighted math + discount. Stored (not derived)
  /// so reports replay deterministically even if the calculator is later
  /// adjusted — Kazakhstan tax inspector replays receipts year-on-year.
  IntColumn get itemTotalTiyin => integer().named('item_total_tiyin')();

  IntColumn get discountAmountTiyin =>
      integer().named('discount_amount_tiyin').withDefault(const Constant(0))();
  IntColumn get vatRate => integer().named('vat_rate').withDefault(const Constant(12))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'receipt_items';
}
