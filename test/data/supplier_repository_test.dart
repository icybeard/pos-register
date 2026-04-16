import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/supplier_repository.dart';

void main() {
  late AppDatabase db;
  late SupplierRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeA = '22222222-2222-2222-2222-222222222222';
  const storeB = '33333333-3333-3333-3333-333333333333';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = SupplierRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('create inserts supplier + appends insert to outbox atomically', () async {
    final id = await repo.create(
      name: 'ТОО Альфа',
      phone: '+77001112233',
      bin: '123456789012',
    );

    final s = await repo.getById(id);
    expect(s, isNotNull);
    expect(s!.name, 'ТОО Альфа');
    expect(s.phone, '+77001112233');
    expect(s.bin, '123456789012');
    expect(s.isActive, true);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'suppliers');
    expect(outbox.first.op, 'insert');
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['bin'], '123456789012');
  });

  test('update renames and soft-deletes via is_active=false', () async {
    final id = await repo.create(name: 'Старое');
    await repo.update(id: id, name: 'Новое', isActive: false);

    final s = await repo.getById(id);
    expect(s!.name, 'Новое');
    expect(s.isActive, false);

    expect(await repo.all(), isEmpty);
    expect(await repo.all(includeInactive: true), hasLength(1));
  });

  test('update on missing id throws', () async {
    await expectLater(
      repo.update(id: 'not-a-real-id', name: 'x'),
      throwsStateError,
    );
  });

  test('store-scoped query returns tenant-wide + matching store, not others', () async {
    await repo.create(storeId: null, name: 'Tenant-wide');
    await repo.create(storeId: storeA, name: 'Only-A');
    await repo.create(storeId: storeB, name: 'Only-B');

    final forA = await repo.all(storeId: storeA);
    expect(forA.map((s) => s.name), containsAll(['Tenant-wide', 'Only-A']));
    expect(forA.map((s) => s.name), isNot(contains('Only-B')));
  });

  test('cross-tenant rows are never returned', () async {
    await repo.create(name: 'Ours');
    final other = SupplierRepository(db, tenantId: 'other-tenant');
    await other.create(name: 'Theirs');

    expect((await repo.all()).map((s) => s.name), ['Ours']);
    expect((await other.all()).map((s) => s.name), ['Theirs']);
  });
}
