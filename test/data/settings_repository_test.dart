import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SettingsRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('upsert inserts new row + appends to outbox in same tx', () async {
    await repo.upsert('receipt_footer', 'Спасибо!');

    expect(await repo.get('receipt_footer'), 'Спасибо!');

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'settings');
    expect(outbox.first.op, 'update');
    expect(jsonDecode(outbox.first.payloadJson),
        {'key': 'receipt_footer', 'value': 'Спасибо!'});
    expect(outbox.first.syncedAt, isNull);
  });

  test('upsert overwrites existing value (insertOnConflictUpdate)', () async {
    await repo.upsert('vat_default', '12');
    await repo.upsert('vat_default', '0');

    expect(await repo.get('vat_default'), '0');

    final settings = await db.select(db.settingsTable).get();
    expect(settings, hasLength(1)); // only one row, updated
  });

  test('all() returns full tenant map', () async {
    await repo.upsert('a', '1');
    await repo.upsert('b', '2');
    await repo.upsert('c', '3');

    expect(await repo.all(), {'a': '1', 'b': '2', 'c': '3'});
  });

  test('watchAll emits on each upsert', () async {
    final emitted = <Map<String, String>>[];
    final sub = repo.watchAll().listen(emitted.add);
    // Allow drift's stream subscription to attach + emit initial empty state.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await repo.upsert('k', 'v1');
    await Future<void>.delayed(const Duration(milliseconds: 20));
    await repo.upsert('k', 'v2');
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await sub.cancel();

    expect(emitted, isNotEmpty);
    expect(emitted.last, {'k': 'v2'});
  });

  test('delete removes setting + appends delete to outbox', () async {
    await repo.upsert('k', 'v');
    await repo.delete('k');

    expect(await repo.get('k'), isNull);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(2));
    expect(outbox.last.op, 'delete');
  });

  test('repository scoped to tenant — sees nothing from another tenant', () async {
    // Manually insert a setting for a DIFFERENT tenant via the underlying DAO.
    await db.into(db.settingsTable).insert(
          SettingsTableCompanion.insert(
            tenantId: '22222222-2222-2222-2222-222222222222',
            key: 'leaked',
            value: 'should_not_be_visible',
            updatedAt: DateTime.now().toUtc(),
          ),
        );

    expect(await repo.get('leaked'), isNull);
    expect(await repo.all(), isEmpty);
  });

  test('outbox row payload is JSON-parseable', () async {
    await repo.upsert('json_test', 'value-with-"quotes"');
    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox.first.payloadJson, isA<String>());
    final parsed = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(parsed['value'], 'value-with-"quotes"');
  });

  // Suppress analyzer noise for the unused `Value` import in case future cases need it
  test('drift Value sentinel imports correctly', () {
    expect(const Value('x'), isNotNull);
  });
}
