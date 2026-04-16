import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';

import '../services/auth/database_key_store.dart';
import 'tables/categories_table.dart';
import 'tables/clients_table.dart';
import 'tables/products_table.dart';
import 'tables/receipts_table.dart';
import 'tables/settings_table.dart';
import 'tables/shifts_table.dart';
import 'tables/stock_movements_table.dart';
import 'tables/suppliers_table.dart';
import 'tables/sync_outbox_table.dart';
import 'tables/users_table.dart';

part 'database.g.dart';

/// Local-first SQLite store for the register. Built on `drift` (formerly moor).
///
/// **Tables ship in waves matching the per-screen feature-flag rollout** — see
/// [FeatureFlags](../core/feature_flags.dart). T1.2 ships only the tables needed
/// by Settings + Cashiers + sync infra. The remaining 16 storage modules join in
/// P1.T4–T1.10, P4, and P5 as their corresponding screens migrate.
///
/// **Concurrency**: drift opens one writer + many readers via background isolates
/// (NativeDatabase.createInBackground), so widget rebuilds don't block on writes.
@DriftDatabase(tables: [
  UsersTable,
  SettingsTable,
  ProductsTable,
  CategoriesTable,
  SuppliersTable,
  ClientsTable,
  StockMovementsTable,
  ReceiptsTable,
  ReceiptItemsTable,
  ShiftsTable,
  SyncOutboxTable,
  SyncCursorsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase({DatabaseKeyStore? keyStore})
      : super(_openConnection(keyStore ?? DatabaseKeyStore()));

  /// In-memory variant for unit tests. Each test gets a fresh DB.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 7;

  /// Migration handler. Schema version bumps go here as new tables come on-line.
  /// Until P9 cutover, every migration that adds a table must also be reflected in
  /// `app/lib/migration/go_to_drift.dart` if it backfills from pos.db.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: P4 wave-1 — add products table for the catalog-on-drift migration.
          if (from < 2) {
            await m.createTable(productsTable);
          }
          // v2 → v3: P4 wave-2a — add categories table. Products reference category_id,
          // so order matters on reinstall (createAll handles it; upgrades don't need FKs).
          if (from < 3) {
            await m.createTable(categoriesTable);
          }
          // v3 → v4: P4 wave-2b — add suppliers + clients tables.
          if (from < 4) {
            await m.createTable(suppliersTable);
            await m.createTable(clientsTable);
          }
          // v4 → v5: P5.T1 — add stock_movements (sales-path foundation).
          if (from < 5) {
            await m.createTable(stockMovementsTable);
          }
          // v5 → v6: P5.T2 — add receipts + receipt_items (header before items
          // for FK clarity, though we don't enforce FKs in drift).
          if (from < 6) {
            await m.createTable(receiptsTable);
            await m.createTable(receiptItemsTable);
          }
          // v6 → v7: P5.T3 — add shifts (opens cashier session; totals roll up
          // as receipts land; close stamps closed_at).
          if (from < 7) {
            await m.createTable(shiftsTable);
          }
        },
      );
}

LazyDatabase _openConnection(DatabaseKeyStore keyStore) {
  return LazyDatabase(() async {
    // sqlcipher_flutter_libs ships an SQLCipher-compatible SQLite build.
    // applyWorkaroundToOpenSqlite3OnOldAndroidVersions is required for
    // KitKat (4.4) — POS hardware in Kazakhstan often runs older Android.
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    }
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pos.drift.sqlite'));

    // Fetch the per-device encryption key BEFORE opening — PRAGMA key must
    // be the very first statement on a fresh connection or SQLCipher will
    // refuse to decrypt subsequent queries.
    final key = await keyStore.getOrCreate();

    // Tunes for the cashier register workload: many small reads, occasional bursts of
    // writes during a sale. WAL gives concurrent reads + one writer; mmap reduces
    // syscall overhead on hot reads.
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(
      file,
      logStatements: false,
      setup: (rawDb) {
        // Keying MUST come first, before any other PRAGMA or query.
        // Using the quoted form so arbitrary bytes in the key don't need
        // hex-encoding (SQLCipher treats the value as a passphrase,
        // derives the encryption key via PBKDF2).
        rawDb.execute("PRAGMA key = '${_escapeKey(key)}'");
        rawDb.execute('PRAGMA journal_mode = WAL');
        rawDb.execute('PRAGMA foreign_keys = ON');
        rawDb.execute('PRAGMA cache_size = -8000');     // 8 MB cache
        rawDb.execute('PRAGMA mmap_size = 268435456');  // 256 MB mmap
        rawDb.execute('PRAGMA busy_timeout = 5000');
      },
    );
  });
}

/// Escape single-quote characters inside the passphrase so the quoted
/// `PRAGMA key` statement stays well-formed. Base64-url alphabet doesn't
/// produce quotes, but we defend in depth in case the generator changes.
String _escapeKey(String key) => key.replaceAll("'", "''");
