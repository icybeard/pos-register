import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:pos_system/data/database.dart';
import 'package:pos_system/migration/go_to_drift.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late AppDatabase drift;
  late GoToDriftMigrator migrator;
  late Directory tmp;

  setUp(() async {
    drift = AppDatabase.forTesting(NativeDatabase.memory());
    migrator = GoToDriftMigrator(drift);
    tmp = await Directory.systemTemp.createTemp('pos-migration-test-');
  });

  tearDown(() async {
    await drift.close();
    if (tmp.existsSync()) {
      tmp.deleteSync(recursive: true);
    }
  });

  test('copies settings + cashiers and returns checksums', () async {
    final posDbPath = p.join(tmp.path, 'pos.db');
    await _seedLegacyDb(posDbPath, settings: const {
      'receipt_footer': 'Спасибо!',
      'vat_default': '12',
    }, cashiers: const [
      _Cashier('c1', 'Иван Петров', 'bcrypt-h1', 'cashier', 1),
      _Cashier('c2', 'Мария Иванова', 'bcrypt-h2', 'senior_cashier', 1),
      _Cashier('c3', 'Inactive One', 'bcrypt-h3', 'cashier', 0),
    ]);

    const tenantId = '11111111-1111-1111-1111-111111111111';
    const storeId = '22222222-2222-2222-2222-222222222222';
    final report = await migrator.migrate(
      tenantId: tenantId,
      posDbPath: posDbPath,
      defaultStoreId: storeId,
    );

    // Report shape
    expect(report.tenantId, tenantId);
    expect(report.totalRows, 5);
    expect(report.tables.keys, {'settings', 'cashiers_to_users'});
    expect(report.tables['settings']!.rowCount, 2);
    expect(report.tables['cashiers_to_users']!.rowCount, 3);
    expect(report.tables['settings']!.sha256Hex, hasLength(64));

    // Settings actually landed in drift with tenant scope
    final kv = await (drift.select(drift.settingsTable)
          ..where((t) => t.tenantId.equals(tenantId)))
        .get();
    expect(kv, hasLength(2));
    expect(kv.firstWhere((r) => r.key == 'receipt_footer').value, 'Спасибо!');

    // Cashiers → users with role mapping + derived login + preserved pin_hash
    final users = await drift.select(drift.usersTable).get();
    expect(users, hasLength(3));
    final ivan = users.firstWhere((u) => u.id == 'c1');
    expect(ivan.tenantId, tenantId);
    expect(ivan.storeId, storeId);
    expect(ivan.name, 'Иван Петров');
    expect(ivan.role, 'cashier');
    expect(ivan.pinHash, 'bcrypt-h1');
    expect(ivan.isActive, true);

    final inactive = users.firstWhere((u) => u.id == 'c3');
    expect(inactive.isActive, false);

    // Login derivation — ASCII-only fallback for Cyrillic names
    expect(users.firstWhere((u) => u.id == 'c1').login, isNull,
        reason: 'pure-Cyrillic name has no ASCII to derive a login from');
  });

  test('login derivation handles ASCII + mixed names', () async {
    final posDbPath = p.join(tmp.path, 'pos.db');
    await _seedLegacyDb(posDbPath, settings: const {}, cashiers: const [
      _Cashier('a1', 'John-Paul', 'h', 'cashier', 1),
      _Cashier('a2', 'Иван Petrov 42', 'h', 'cashier', 1),
      _Cashier('a3', '   ', 'h', 'cashier', 1),
    ]);

    await migrator.migrate(
        tenantId: '11111111-1111-1111-1111-111111111111', posDbPath: posDbPath);

    final users = await drift.select(drift.usersTable).get();
    expect(users.firstWhere((u) => u.id == 'a1').login, 'john_paul');
    expect(users.firstWhere((u) => u.id == 'a2').login, 'petrov_42');
    expect(users.firstWhere((u) => u.id == 'a3').login, isNull);
  });

  test('role normalisation: unknown role maps to cashier', () async {
    final posDbPath = p.join(tmp.path, 'pos.db');
    await _seedLegacyDb(posDbPath, settings: const {}, cashiers: const [
      _Cashier('r1', 'X', 'h', 'super_admin', 1), // not a valid role
      _Cashier('r2', 'Y', 'h', null, 1),           // null role
      _Cashier('r3', 'Z', 'h', 'Manager', 1),      // wrong case
    ]);
    await migrator
        .migrate(tenantId: '11111111-1111-1111-1111-111111111111', posDbPath: posDbPath);
    final users = await drift.select(drift.usersTable).get();
    expect(users.firstWhere((u) => u.id == 'r1').role, 'cashier');
    expect(users.firstWhere((u) => u.id == 'r2').role, 'cashier');
    expect(users.firstWhere((u) => u.id == 'r3').role, 'manager');
  });

  test('missing source table (e.g. very old pos.db) does not crash', () async {
    final posDbPath = p.join(tmp.path, 'pos.db');
    // Create a pos.db with ONLY settings, no cashiers table
    final db = await databaseFactory.openDatabase(posDbPath);
    await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT)');
    await db.insert('settings', {'key': 'k', 'value': 'v'});
    await db.close();

    final report = await migrator.migrate(
      tenantId: '11111111-1111-1111-1111-111111111111',
      posDbPath: posDbPath,
    );
    expect(report.tables['settings']!.rowCount, 1);
    expect(report.tables['cashiers_to_users']!.rowCount, 0,
        reason: 'missing cashiers table → empty result, no crash');
  });

  test('checksum is deterministic — same input → same sha256', () async {
    final posDbPath = p.join(tmp.path, 'pos.db');
    await _seedLegacyDb(posDbPath, settings: const {
      'b': '2', // inserted out of sort order to prove the migrator sorts
      'a': '1',
    }, cashiers: const []);

    final report = await migrator.migrate(
        tenantId: '11111111-1111-1111-1111-111111111111', posDbPath: posDbPath);
    final firstHash = report.tables['settings']!.sha256Hex;

    // Run against a FRESH drift but the same source.
    await drift.close();
    final drift2 = AppDatabase.forTesting(NativeDatabase.memory());
    final migrator2 = GoToDriftMigrator(drift2);
    final report2 = await migrator2.migrate(
        tenantId: '11111111-1111-1111-1111-111111111111', posDbPath: posDbPath);
    await drift2.close();

    expect(report2.tables['settings']!.sha256Hex, firstHash);
  });

  test('report.toJson round-trips', () async {
    final posDbPath = p.join(tmp.path, 'pos.db');
    await _seedLegacyDb(posDbPath,
        settings: const {'a': '1'}, cashiers: const []);
    final report = await migrator.migrate(
        tenantId: '11111111-1111-1111-1111-111111111111', posDbPath: posDbPath);

    final json = jsonEncode(report.toJson());
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    expect(decoded['total_rows'], 1);
    expect(decoded['tables']['settings']['row_count'], 1);
    expect(decoded['tables']['settings']['sha256'], hasLength(64));
  });
}

class _Cashier {
  const _Cashier(this.id, this.name, this.pinHash, this.role, this.isActive);
  final String id;
  final String name;
  final String pinHash;
  final String? role;
  final int isActive;
}

Future<void> _seedLegacyDb(
  String path, {
  required Map<String, String> settings,
  required List<_Cashier> cashiers,
}) async {
  final db = await databaseFactory.openDatabase(path);
  await db.execute('CREATE TABLE settings (key TEXT PRIMARY KEY, value TEXT NOT NULL)');
  await db.execute('''
    CREATE TABLE cashiers (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      pin_hash TEXT,
      role TEXT,
      is_active INTEGER DEFAULT 1,
      device_id TEXT,
      created_at TEXT,
      updated_at TEXT
    )
  ''');
  for (final e in settings.entries) {
    await db.insert('settings', {'key': e.key, 'value': e.value});
  }
  for (final c in cashiers) {
    await db.insert('cashiers', {
      'id': c.id,
      'name': c.name,
      'pin_hash': c.pinHash,
      'role': c.role,
      'is_active': c.isActive,
      'device_id': 'dev-test',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-01T00:00:00Z',
    });
  }
  await db.close();
}
