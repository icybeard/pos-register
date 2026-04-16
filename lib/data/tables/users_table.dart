import 'package:drift/drift.dart';

/// Local mirror of the central `users` table. PIN-using accounts (cashier/manager/admin)
/// are pulled down via sync; the owner login record is also synced for offline web-admin
/// access from the register UI (read-only in that case).
///
/// PIN hashes are bcrypt — verified locally for offline cashier login when
/// the register can't reach central. Online auth always prefers central.
@DataClassName('UserRow')
class UsersTable extends Table {
  TextColumn get id => text()();                       // UUID
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get storeId => text().named('store_id').nullable()();
  TextColumn get name => text()();
  TextColumn get login => text().nullable()();         // null for owner
  TextColumn get email => text().nullable()();         // null for cashier
  TextColumn get pinHash => text().named('pin_hash').nullable()();
  TextColumn get role => text()();                     // owner|admin|manager|senior_cashier|cashier
  BoolColumn get isActive =>
      boolean().named('is_active').withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'users';
}
