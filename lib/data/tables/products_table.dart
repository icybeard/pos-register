import 'package:drift/drift.dart';

/// Local mirror of the central `products` table. Source of truth for the catalog
/// at the register — cashier reads hit drift, never HTTP. Writes from the web admin
/// propagate via sync pull; offline edits from the register (price changes, renames,
/// P9 cashier-proposals) go through the outbox.
///
/// **Money in tiyin** (INTEGER). 1 KZT = 100 tiyin. Never store fractional tenge.
///
/// **NTIN / XTIN**: KZ national trade-item numbers. NTIN is permanent; XTIN is a
/// 30-day temporary identifier used while a NTIN is being assigned — see
/// `XtinExpiresAt`. After `2026-01-01` every sold item must have an NTIN.
@DataClassName('ProductRow')
class ProductsTable extends Table {
  TextColumn get id => text()();                                        // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();      // null = tenant-wide
  TextColumn get name => text()();
  TextColumn get nameKz => text().named('name_kz').nullable()();
  TextColumn get barcodeGtin => text().named('barcode_gtin').nullable()();
  TextColumn get ntin => text().nullable()();
  TextColumn get xtin => text().nullable()();
  DateTimeColumn get xtinExpiresAt => dateTime().named('xtin_expires_at').nullable()();
  TextColumn get categoryId => text().named('category_id').nullable()();
  TextColumn get categoryOktru => text().named('category_oktru').nullable()();

  TextColumn get purchaseUnit => text().named('purchase_unit')();       // pcs|kg|g|l|ml|m
  IntColumn get purchasePriceTiyin => integer().named('purchase_price_tiyin')();
  TextColumn get saleUnit => text().named('sale_unit')();
  IntColumn get salePriceTiyin => integer().named('sale_price_tiyin')();

  BoolColumn get isWeighted =>
      boolean().named('is_weighted').withDefault(const Constant(false))();
  IntColumn get minWeightGrams => integer().named('min_weight_grams').nullable()();
  IntColumn get weightStepGrams => integer().named('weight_step_grams').withDefault(const Constant(1))();

  IntColumn get vatRate => integer().named('vat_rate').withDefault(const Constant(12))();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();

  TextColumn get approvalStatus =>
      text().named('approval_status').withDefault(const Constant('approved'))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'products';
}
