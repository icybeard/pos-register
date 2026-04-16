import 'package:drift/drift.dart';

/// Local mirror of central `suppliers` table. Поставщики for goods-receipt
/// workflow. `bin` is KZ Business Identification Number (12 digits for legal
/// entities). Notes field carries free-form memo from procurement.
@DataClassName('SupplierRow')
class SuppliersTable extends Table {
  TextColumn get id => text()();                                        // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get bin => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'suppliers';
}
