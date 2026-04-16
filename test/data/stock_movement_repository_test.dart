import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/stock_movement_repository.dart';

void main() {
  late AppDatabase db;
  late StockMovementRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const deviceId = 'test-register-01';
  const productA = 'prod-a';
  const productB = 'prod-b';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = StockMovementRepository(db, tenantId: tenantId, deviceId: deviceId);
  });

  tearDown(() async {
    await db.close();
  });

  test('record inserts row + appends insert to outbox atomically', () async {
    final uuid = await repo.record(
      productId: productA,
      delta: -1,
      reason: StockMovementReason.sale,
      receiptId: 'receipt-1',
    );

    // Row present
    final rows = await db.select(db.stockMovementsTable).get();
    expect(rows, hasLength(1));
    expect(rows.first.clientUuid, uuid);
    expect(rows.first.delta, -1);
    expect(rows.first.deviceId, deviceId);
    expect(rows.first.reason, 'sale');
    expect(rows.first.receiptId, 'receipt-1');

    // Outbox queued
    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'stock_movements');
    expect(outbox.first.op, 'insert');
    expect(outbox.first.uuid, uuid);

    // Payload parses to the expected wire shape
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['product_id'], productA);
    expect(payload['delta'], -1);
    expect(payload['device_id'], deviceId);
    expect(payload['receipt_id'], 'receipt-1');
    expect(payload['tenant_id'], tenantId);
  });

  test('record with explicit client_uuid preserves it (server-side idempotency key)', () async {
    const explicit = 'abc-123-explicit';
    final returned = await repo.record(
      clientUuid: explicit,
      productId: productA,
      delta: 5,
      reason: StockMovementReason.delivery,
    );
    expect(returned, explicit);
  });

  test('record rejects unknown reason via assertion', () async {
    await expectLater(
      () => repo.record(productId: productA, delta: 1, reason: 'not-a-reason'),
      throwsA(isA<AssertionError>()),
    );
  });

  test('quantityOnHand sums deltas (start 0, +10 delivery, -3 sale = 7)', () async {
    expect(await repo.quantityOnHand(productA), 0, reason: 'no movements yet');

    await repo.record(productId: productA, delta: 10, reason: StockMovementReason.delivery);
    await repo.record(productId: productA, delta: -3, reason: StockMovementReason.sale);

    expect(await repo.quantityOnHand(productA), 7);
  });

  test('quantityOnHand can go negative (oversell) — does not clamp', () async {
    await repo.record(productId: productA, delta: 2, reason: StockMovementReason.delivery);
    await repo.record(
      productId: productA,
      delta: -5,
      reason: StockMovementReason.sale,
      overrideByUserId: 'manager-1',
    );
    expect(await repo.quantityOnHand(productA), -3);

    // Override is persisted for the EOD audit flag
    final rows = await repo.historyFor(productA);
    expect(rows.first.overrideByUserId, 'manager-1');
  });

  test('quantityOnHand is scoped to productId', () async {
    await repo.record(productId: productA, delta: 10, reason: StockMovementReason.delivery);
    await repo.record(productId: productB, delta: 100, reason: StockMovementReason.delivery);

    expect(await repo.quantityOnHand(productA), 10);
    expect(await repo.quantityOnHand(productB), 100);
  });

  test('store-scoped query includes tenant-wide + matching store, excludes other stores', () async {
    const storeA = 'store-a';
    const storeB = 'store-b';

    await repo.record(storeId: null, productId: productA, delta: 5, reason: StockMovementReason.delivery);
    await repo.record(storeId: storeA, productId: productA, delta: 3, reason: StockMovementReason.delivery);
    await repo.record(storeId: storeB, productId: productA, delta: 99, reason: StockMovementReason.delivery);

    expect(await repo.quantityOnHand(productA, storeId: storeA), 8, reason: 'tenant-wide + storeA');
    expect(await repo.quantityOnHand(productA, storeId: storeB), 104, reason: 'tenant-wide + storeB');
  });

  test('watchQuantityOnHand emits on each new movement', () async {
    final values = <int>[];
    final sub = repo.watchQuantityOnHand(productA).listen(values.add);

    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.record(productId: productA, delta: 10, reason: StockMovementReason.delivery);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.record(productId: productA, delta: -4, reason: StockMovementReason.sale);
    await Future<void>.delayed(const Duration(milliseconds: 10));

    await sub.cancel();
    expect(values.last, 6);
  });

  test('historyFor returns most-recent-first (tiebreak on id) and respects limit', () async {
    for (var i = 0; i < 5; i++) {
      await repo.record(productId: productA, delta: 1, reason: StockMovementReason.delivery);
    }

    final rows = await repo.historyFor(productA, limit: 3);
    expect(rows, hasLength(3));
    // Tiebreak on auto-increment id — newer rows have higher ids. Protects
    // against same-millisecond inserts on a fast cashier tap sequence.
    expect(rows.first.id > rows.last.id, true);
  });

  test('duplicate client_uuid is rejected by the UNIQUE index', () async {
    await repo.record(
      clientUuid: 'dup-uuid',
      productId: productA,
      delta: 1,
      reason: StockMovementReason.delivery,
    );
    await expectLater(
      () => repo.record(
        clientUuid: 'dup-uuid',
        productId: productA,
        delta: 1,
        reason: StockMovementReason.delivery,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
