import 'package:drift/drift.dart';

/// Local mirror of central `clients` table. Customers / debtors. `iin` is the KZ
/// Individual Identification Number (12 digits). `debt_limit_tiyin` is an
/// optional per-client cap on outstanding debt (null = no cap).
@DataClassName('ClientRow')
class ClientsTable extends Table {
  TextColumn get id => text()();                                        // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get iin => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get debtLimitTiyin => integer().named('debt_limit_tiyin').nullable()();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'clients';
}
