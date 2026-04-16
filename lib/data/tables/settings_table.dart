import 'package:drift/drift.dart';

/// Per-tenant key/value config. Mirrors central's `settings` table.
/// Composite primary key (tenant_id, key) — the `tenantId` will normally be a single
/// constant on the register (the device's bound tenant) but the column stays for
/// future multi-tenant testing and for sync alignment.
@DataClassName('SettingRow')
class SettingsTable extends Table {
  TextColumn get tenantId => text().named('tenant_id')();
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {tenantId, key};

  @override
  String get tableName => 'settings';
}
