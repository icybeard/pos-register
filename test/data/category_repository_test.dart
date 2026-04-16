import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/category_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeA = '22222222-2222-2222-2222-222222222222';
  const storeB = '33333333-3333-3333-3333-333333333333';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = CategoryRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('create inserts category + appends insert to outbox atomically', () async {
    final id = await repo.create(name: 'Напитки', sortOrder: 1);

    final c = await repo.getById(id);
    expect(c, isNotNull);
    expect(c!.name, 'Напитки');
    expect(c.sortOrder, 1);
    expect(c.isActive, true);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'categories');
    expect(outbox.first.op, 'insert');
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['name'], 'Напитки');
    expect(payload['sort_order'], 1);
  });

  test('all orders by sort_order then name', () async {
    await repo.create(name: 'Z-cat', sortOrder: 1);
    await repo.create(name: 'A-cat', sortOrder: 1);
    await repo.create(name: 'Топ', sortOrder: 0);

    final rows = await repo.all();
    expect(rows.map((r) => r.name), ['Топ', 'A-cat', 'Z-cat']);
  });

  test('update renames and soft-deletes via is_active=false', () async {
    final id = await repo.create(name: 'Старое');
    await repo.update(id: id, name: 'Новое', isActive: false);

    final c = await repo.getById(id);
    expect(c!.name, 'Новое');
    expect(c.isActive, false);

    expect(await repo.all(), isEmpty, reason: 'default all() hides inactive');
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
    expect(forA.map((c) => c.name), containsAll(['Tenant-wide', 'Only-A']));
    expect(forA.map((c) => c.name), isNot(contains('Only-B')));
  });

  test('cross-tenant rows are never returned', () async {
    await repo.create(name: 'Ours');
    final other = CategoryRepository(db, tenantId: 'other-tenant');
    await other.create(name: 'Theirs');

    expect((await repo.all()).map((c) => c.name), ['Ours']);
    expect((await other.all()).map((c) => c.name), ['Theirs']);
  });

  test('watchAll emits on create', () async {
    final stream = repo.watchAll();
    final values = <List<String>>[];
    final sub = stream.listen((rows) => values.add(rows.map((r) => r.name).toList()));

    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.create(name: 'Хлеб');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await sub.cancel();
    expect(values.last, ['Хлеб']);
  });
}
