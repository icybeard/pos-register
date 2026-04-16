import 'dart:convert';

import 'package:drift/drift.dart';

import '../database.dart';

/// Local-first key/value settings repository. Reads stream from drift; writes happen
/// inside a transaction that ALSO appends to `sync_outbox` — that's the offline-first
/// invariant: a successful local write is by definition queued for sync.
class SettingsRepository {
  SettingsRepository(this._db, {required String tenantId}) : _tenantId = tenantId;

  final AppDatabase _db;
  final String _tenantId;

  /// Reactive stream of the full settings map for the current tenant.
  /// Bind to BLoC / `StreamBuilder` for live UI updates.
  Stream<Map<String, String>> watchAll() {
    return (_db.select(_db.settingsTable)
          ..where((t) => t.tenantId.equals(_tenantId)))
        .watch()
        .map(_toMap);
  }

  /// One-shot read for code paths that don't want a stream.
  Future<Map<String, String>> all() async {
    final rows = await (_db.select(_db.settingsTable)
          ..where((t) => t.tenantId.equals(_tenantId)))
        .get();
    return _toMap(rows);
  }

  Future<String?> get(String key) async {
    final row = await (_db.select(_db.settingsTable)
          ..where((t) => t.tenantId.equals(_tenantId) & t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  /// Insert or update a setting. Atomic with the outbox write — if the outbox
  /// insert throws, the setting write rolls back. Sync worker drains the outbox
  /// asynchronously.
  Future<void> upsert(String key, String value) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.settingsTable).insertOnConflictUpdate(
            SettingsTableCompanion.insert(
              tenantId: _tenantId,
              key: key,
              value: value,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'settings',
              op: 'update',
              uuid: '$_tenantId/$key', // settings has composite PK; encode it
              payloadJson: jsonEncode({'key': key, 'value': value}),
              createdAt: now,
            ),
          );
    });
  }

  Future<void> delete(String key) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.delete(_db.settingsTable)
            ..where((t) => t.tenantId.equals(_tenantId) & t.key.equals(key)))
          .go();
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'settings',
              op: 'delete',
              uuid: '$_tenantId/$key',
              payloadJson: jsonEncode({'key': key}),
              createdAt: now,
            ),
          );
    });
  }

  static Map<String, String> _toMap(List<SettingRow> rows) {
    final m = <String, String>{};
    for (final r in rows) {
      m[r.key] = r.value;
    }
    return m;
  }
}
