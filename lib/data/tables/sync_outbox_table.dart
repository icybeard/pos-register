import 'package:drift/drift.dart';

/// Outbox for changes that need to be pushed to central. Every Repository write
/// inserts into this table inside the SAME drift transaction as the domain write
/// — that's the core offline-first invariant (atomic local-state-and-pending-sync).
///
/// A background isolate (T2.x) drains the outbox in batches of 500 to /api/sync/push,
/// marks rows as synced (or records `last_error` + bumps `attempts` on failure),
/// then deletes synced rows older than 7 days.
@DataClassName('SyncOutboxRow')
class SyncOutboxTable extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Name of the domain table this entry belongs to (e.g. "settings", "users").
  /// Renamed from `tableName` to avoid colliding with drift's table-name override getter.
  TextColumn get targetTable => text().named('target_table')();

  TextColumn get op => text()();                       // insert | update | delete
  TextColumn get uuid => text()();                     // UUID of the affected row
  TextColumn get payloadJson => text().named('payload_json')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get syncedAt => dateTime().named('synced_at').nullable()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().named('last_error').nullable()();

  @override
  String get tableName => 'sync_outbox';
}

/// Per-table cursor for pulling updates from central. After each successful pull,
/// the worker stores the server's `next_cursor` here.
@DataClassName('SyncCursorRow')
class SyncCursorsTable extends Table {
  /// Name of the domain table this cursor tracks (e.g. "settings", "users").
  TextColumn get targetTable => text().named('target_table')();

  TextColumn get cursor => text()();                   // opaque base64 from central
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  Set<Column> get primaryKey => {targetTable};

  @override
  String get tableName => 'sync_cursors';
}
