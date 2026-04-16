import 'package:drift/drift.dart';

/// Local mirror of the central `categories` table. Hierarchy via `parent_id`,
/// though the MVP UI stays single-level. `oktru_code` is the KZ goods
/// classification (ОКРБ) — needed at receipt time for fiscal reports.
@DataClassName('CategoryRow')
class CategoriesTable extends Table {
  TextColumn get id => text()();                                        // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();
  TextColumn get name => text()();
  TextColumn get nameKz => text().named('name_kz').nullable()();
  TextColumn get parentId => text().named('parent_id').nullable()();
  TextColumn get oktruCode => text().named('oktru_code').nullable()();
  IntColumn get sortOrder =>
      integer().named('sort_order').withDefault(const Constant(0))();
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'categories';
}
