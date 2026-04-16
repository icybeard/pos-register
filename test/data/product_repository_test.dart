import 'dart:convert';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/product_repository.dart';

void main() {
  late AppDatabase db;
  late ProductRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const storeA = '22222222-2222-2222-2222-222222222222';
  const storeB = '33333333-3333-3333-3333-333333333333';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ProductRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('create inserts product + appends insert to outbox atomically', () async {
    final id = await repo.create(
      storeId: storeA,
      name: 'Coca-Cola 0.5L',
      barcodeGtin: '4870001234567',
      purchasePriceTiyin: 15000,
      salePriceTiyin: 25000,
      vatRate: 12,
    );

    final p = await repo.getById(id);
    expect(p, isNotNull);
    expect(p!.name, 'Coca-Cola 0.5L');
    expect(p.barcodeGtin, '4870001234567');
    expect(p.salePriceTiyin, 25000);
    expect(p.vatRate, 12);
    expect(p.isActive, true);
    expect(p.approvalStatus, 'approved');

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'products');
    expect(outbox.first.op, 'insert');
    expect(outbox.first.uuid, id);
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['sale_price_tiyin'], 25000);
    expect(payload['barcode_gtin'], '4870001234567');
  });

  test('create with explicit id preserves it', () async {
    const explicitId = '44444444-4444-4444-4444-444444444444';
    final id = await repo.create(
      id: explicitId,
      name: 'Хлеб',
      purchasePriceTiyin: 8000,
      salePriceTiyin: 15000,
    );
    expect(id, explicitId);
  });

  test('findByBarcode returns the product regardless of is_active', () async {
    final id = await repo.create(
      name: 'Молоко',
      barcodeGtin: '4870000099999',
      purchasePriceTiyin: 30000,
      salePriceTiyin: 49900,
    );
    await repo.update(id: id, isActive: false);

    final found = await repo.findByBarcode('4870000099999');
    expect(found, isNotNull);
    expect(found!.isActive, false);
  });

  test('findByBarcode returns null for unknown barcode', () async {
    final found = await repo.findByBarcode('0000000000000');
    expect(found, isNull);
  });

  test('update writes new fields + appends update to outbox', () async {
    final id = await repo.create(
      name: 'Чай',
      purchasePriceTiyin: 10000,
      salePriceTiyin: 20000,
    );

    await repo.update(id: id, salePriceTiyin: 25000, name: 'Чай черный');

    final p = await repo.getById(id);
    expect(p!.name, 'Чай черный');
    expect(p.salePriceTiyin, 25000);
    expect(p.purchasePriceTiyin, 10000, reason: 'unmentioned fields stay unchanged');

    final outboxOps = await (db.select(db.syncOutboxTable)
          ..orderBy([(o) => OrderingTerm.asc(o.id)]))
        .get();
    expect(outboxOps, hasLength(2));
    expect(outboxOps.last.op, 'update');
    final payload = jsonDecode(outboxOps.last.payloadJson) as Map<String, dynamic>;
    expect(payload['sale_price_tiyin'], 25000);
    expect(payload['name'], 'Чай черный');
  });

  test('update soft-deletes via is_active=false', () async {
    final id = await repo.create(
      name: 'Печенье',
      purchasePriceTiyin: 20000,
      salePriceTiyin: 30000,
    );

    await repo.update(id: id, isActive: false);

    final all = await repo.all();
    expect(all, isEmpty, reason: 'default all() hides inactive');

    final allWithInactive = await repo.all(includeInactive: true);
    expect(allWithInactive, hasLength(1));
    expect(allWithInactive.single.isActive, false);
  });

  test('update on missing id throws', () async {
    await expectLater(
      repo.update(id: 'not-a-real-id', salePriceTiyin: 1),
      throwsStateError,
    );
  });

  test('store-scoped query returns tenant-wide + matching store, not other stores',
      () async {
    await repo.create(
      storeId: null,
      name: 'Tenant-wide',
      purchasePriceTiyin: 1,
      salePriceTiyin: 2,
    );
    await repo.create(
      storeId: storeA,
      name: 'Only-A',
      purchasePriceTiyin: 1,
      salePriceTiyin: 2,
    );
    await repo.create(
      storeId: storeB,
      name: 'Only-B',
      purchasePriceTiyin: 1,
      salePriceTiyin: 2,
    );

    final forA = await repo.all(storeId: storeA);
    expect(forA.map((p) => p.name), containsAll(['Tenant-wide', 'Only-A']));
    expect(forA.map((p) => p.name), isNot(contains('Only-B')));
  });

  test('cross-tenant rows are never returned', () async {
    await repo.create(
      name: 'Ours',
      purchasePriceTiyin: 1,
      salePriceTiyin: 2,
    );
    final otherRepo = ProductRepository(db, tenantId: 'other-tenant');
    await otherRepo.create(
      name: 'Theirs',
      purchasePriceTiyin: 1,
      salePriceTiyin: 2,
    );

    final ours = await repo.all();
    expect(ours.map((p) => p.name), ['Ours']);

    final theirs = await otherRepo.all();
    expect(theirs.map((p) => p.name), ['Theirs']);
  });

  test('watchAll emits changes reactively', () async {
    final stream = repo.watchAll();
    final values = <List<String>>[];
    final sub = stream.listen((rows) => values.add(rows.map((r) => r.name).toList()));

    // Initial empty emit
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.create(
      name: 'A',
      purchasePriceTiyin: 1,
      salePriceTiyin: 2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.create(
      name: 'B',
      purchasePriceTiyin: 1,
      salePriceTiyin: 2,
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await sub.cancel();
    expect(values.last, ['A', 'B']);
  });
}
