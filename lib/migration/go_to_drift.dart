import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:sqflite/sqflite.dart';

import '../data/database.dart';

/// One-time migration of legacy Go `pos.db` (SQLite) into the new drift-backed
/// local-first store. Runs on first boot of the new Flutter app version; guarded by
/// `SharedPreferences` key `migration.go_to_drift.completed` (the caller sets that).
///
/// **The legacy Go server is single-tenant** — its rows have no `tenant_id`. The caller
/// supplies the register's `tenantId` (read from [AuthTokenStore] after activation).
/// For pre-activation / stand-alone dev installs, pass a synthetic tenant UUID and
/// re-assign later when the register is activated.
///
/// **This is a copy, not a move**: pos.db is left untouched for 14 days (per plan
/// Section 5 — rollback safety). A separate janitor job deletes it later.
///
/// Returns a [MigrationReport] with per-table row counts + sha256 of sorted rows.
/// The caller typically writes this to `migration_report.json` in the app docs dir.
class GoToDriftMigrator {
  GoToDriftMigrator(this._db);

  final AppDatabase _db;

  Future<MigrationReport> migrate({
    required String tenantId,
    required String posDbPath,
    String? defaultStoreId,
  }) async {
    final legacy = await openReadOnlyDatabase(posDbPath);
    try {
      final now = DateTime.now().toUtc();
      final perTable = <String, TableMigrationResult>{};

      perTable['settings'] =
          await _migrateSettings(legacy, tenantId: tenantId, now: now);

      perTable['cashiers_to_users'] =
          await _migrateCashiers(legacy, tenantId: tenantId, storeId: defaultStoreId, now: now);

      return MigrationReport(
        startedAt: now,
        finishedAt: DateTime.now().toUtc(),
        tenantId: tenantId,
        legacyDbPath: posDbPath,
        tables: perTable,
      );
    } finally {
      await legacy.close();
    }
  }

  Future<TableMigrationResult> _migrateSettings(
    Database legacy, {
    required String tenantId,
    required DateTime now,
  }) async {
    final rows = await _safeQuery(legacy, 'SELECT key, value FROM settings');
    final sorted = rows.toList()..sort((a, b) => (a['key'] as String).compareTo(b['key'] as String));

    await _db.transaction(() async {
      for (final r in sorted) {
        await _db.into(_db.settingsTable).insertOnConflictUpdate(
              SettingsTableCompanion.insert(
                tenantId: tenantId,
                key: r['key'] as String,
                value: (r['value'] as String?) ?? '',
                updatedAt: now,
              ),
            );
      }
    });

    return TableMigrationResult(
      source: 'settings',
      destination: 'settings',
      rowCount: sorted.length,
      sha256Hex: _hashRows(sorted),
    );
  }

  Future<TableMigrationResult> _migrateCashiers(
    Database legacy, {
    required String tenantId,
    String? storeId,
    required DateTime now,
  }) async {
    final rows = await _safeQuery(legacy,
        'SELECT id, name, pin_hash, role, is_active, device_id, created_at, updated_at FROM cashiers');
    final sorted = rows.toList()..sort((a, b) => (a['id'] as String).compareTo(b['id'] as String));

    await _db.transaction(() async {
      for (final r in sorted) {
        await _db.into(_db.usersTable).insertOnConflictUpdate(
              UsersTableCompanion.insert(
                id: r['id'] as String,
                tenantId: tenantId,
                storeId: Value(storeId),
                name: (r['name'] as String?) ?? '',
                login: Value(_deriveLogin(r['name'] as String?)),
                pinHash: Value(r['pin_hash'] as String?),
                role: _normaliseRole(r['role'] as String?),
                isActive: Value(((r['is_active'] as int?) ?? 1) != 0),
                createdAt: _parseTs(r['created_at']) ?? now,
                updatedAt: _parseTs(r['updated_at']) ?? now,
              ),
            );
      }
    });

    return TableMigrationResult(
      source: 'cashiers',
      destination: 'users',
      rowCount: sorted.length,
      sha256Hex: _hashRows(sorted),
    );
  }

  /// Reads a table defensively — if the source table doesn't exist (e.g. very old pos.db
  /// predating the column), returns an empty list rather than blowing up the migration.
  Future<List<Map<String, Object?>>> _safeQuery(Database legacy, String sql) async {
    try {
      return await legacy.rawQuery(sql);
    } on DatabaseException {
      return const [];
    }
  }

  /// Derive a login from the cashier name when the legacy schema didn't have one.
  /// Transliteration-free: just ASCII-lowercase alphanumerics + underscore separators.
  /// Leading and consecutive underscores are suppressed; trailing underscores are
  /// trimmed. Returns null for names with no ASCII alphanumerics at all (pure-Cyrillic
  /// names fall through — owner/admin assigns a login later via the cashiers API).
  static String? _deriveLogin(String? name) {
    if (name == null || name.trim().isEmpty) return null;
    final buf = StringBuffer();
    var hasAlnum = false;
    var lastWasUnderscore = false;
    for (final ch in name.trim().toLowerCase().split('')) {
      final c = ch.codeUnitAt(0);
      final isLetter = (c >= 0x61 && c <= 0x7A); // a-z
      final isDigit = (c >= 0x30 && c <= 0x39);  // 0-9
      if (isLetter || isDigit) {
        buf.write(ch);
        hasAlnum = true;
        lastWasUnderscore = false;
      } else if (hasAlnum && !lastWasUnderscore) {
        // Collapse any run of non-alnum chars into one underscore separator,
        // but only after we've seen at least one alnum (no leading underscore).
        buf.write('_');
        lastWasUnderscore = true;
      }
    }
    if (!hasAlnum) return null;
    var out = buf.toString();
    while (out.endsWith('_')) {
      out = out.substring(0, out.length - 1);
    }
    return out.isEmpty ? null : out;
  }

  static String _normaliseRole(String? role) {
    const allowed = {'owner', 'admin', 'manager', 'senior_cashier', 'cashier'};
    final r = (role ?? 'cashier').trim().toLowerCase();
    return allowed.contains(r) ? r : 'cashier';
  }

  static DateTime? _parseTs(Object? raw) {
    if (raw is String && raw.isNotEmpty) {
      return DateTime.tryParse(raw)?.toUtc();
    }
    if (raw is int) {
      // Unix seconds (legacy Go used both ISO strings and unix ints in different versions).
      return DateTime.fromMillisecondsSinceEpoch(raw * 1000, isUtc: true);
    }
    return null;
  }

  static String _hashRows(List<Map<String, Object?>> rows) {
    // Deterministic: jsonEncode with sorted keys per row, then line-join.
    final lines = rows.map((r) {
      final keys = r.keys.toList()..sort();
      return jsonEncode({for (final k in keys) k: r[k]});
    }).toList();
    return sha256.convert(utf8.encode(lines.join('\n'))).toString();
  }
}

/// Aggregate report suitable for persisting to `migration_report.json`.
class MigrationReport {
  const MigrationReport({
    required this.startedAt,
    required this.finishedAt,
    required this.tenantId,
    required this.legacyDbPath,
    required this.tables,
  });

  final DateTime startedAt;
  final DateTime finishedAt;
  final String tenantId;
  final String legacyDbPath;
  final Map<String, TableMigrationResult> tables;

  int get totalRows =>
      tables.values.fold(0, (sum, t) => sum + t.rowCount);

  Map<String, dynamic> toJson() => {
        'started_at': startedAt.toIso8601String(),
        'finished_at': finishedAt.toIso8601String(),
        'tenant_id': tenantId,
        'legacy_db_path': legacyDbPath,
        'total_rows': totalRows,
        'tables': tables.map((k, v) => MapEntry(k, v.toJson())),
      };
}

class TableMigrationResult {
  const TableMigrationResult({
    required this.source,
    required this.destination,
    required this.rowCount,
    required this.sha256Hex,
  });

  final String source;
  final String destination;
  final int rowCount;
  final String sha256Hex;

  Map<String, dynamic> toJson() => {
        'source': source,
        'destination': destination,
        'row_count': rowCount,
        'sha256': sha256Hex,
      };
}
