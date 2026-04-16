import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/receipt_repository.dart';
import 'package:pos_system/data/repositories/stock_movement_repository.dart';

void main() {
  late AppDatabase db;
  late ReceiptRepository repo;
  late StockMovementRepository stock;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const deviceId = 'test-register-01';
  const storeId = '22222222-2222-2222-2222-222222222222';
  const workstationId = 'ws-1';
  const shiftId = 'shift-1';
  const userId = 'user-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ReceiptRepository(db, tenantId: tenantId, deviceId: deviceId);
    stock = StockMovementRepository(db, tenantId: tenantId, deviceId: deviceId);
  });

  tearDown(() async {
    await db.close();
  });

  ReceiptLineInput piece({
    String productId = 'prod-cola',
    int quantity = 1,
    int unitPriceTiyin = 25000,
  }) =>
      ReceiptLineInput(
        productId: productId,
        productName: 'Coca-Cola 0.5L',
        productBarcode: '4870001234567',
        quantity: quantity,
        unitPriceTiyin: unitPriceTiyin,
        itemTotalTiyin: unitPriceTiyin * quantity,
        vatRate: 12,
      );

  ReceiptLineInput weighted({
    String productId = 'prod-bread',
    int weightGrams = 350,
    int unitPriceTiyin = 80000, // 800 ₸/kg
  }) =>
      ReceiptLineInput(
        productId: productId,
        productName: 'Хлеб',
        productBarcode: '4870000099999',
        quantity: 0,
        weightGrams: weightGrams,
        unitPriceTiyin: unitPriceTiyin,
        // 800₸/kg * 0.350 kg = 280₸ = 28000 tiyin
        itemTotalTiyin: (weightGrams * unitPriceTiyin) ~/ 1000,
        vatRate: 12,
      );

  test('createReceipt writes header + items + stock_movements + outbox atomically', () async {
    final result = await repo.createReceipt(
      storeId: storeId,
      workstationId: workstationId,
      shiftId: shiftId,
      userId: userId,
      receiptNumber: 1,
      lines: [piece(), piece(productId: 'prod-juice', unitPriceTiyin: 30000)],
      totalAmountTiyin: 55000,
      vatAmountTiyin: 5893,
      cashAmountTiyin: 60000,
      changeAmountTiyin: 5000,
    );

    expect(result.itemIds, hasLength(2));
    expect(result.stockMovementUuids, hasLength(2));

    // Receipt header landed
    final header = await repo.getById(result.receiptId);
    expect(header, isNotNull);
    expect(header!.totalAmountTiyin, 55000);
    expect(header.cashAmountTiyin, 60000);
    expect(header.changeAmountTiyin, 5000);
    expect(header.fiscalStatus, 'pending');

    // Items landed
    final items = await repo.itemsFor(result.receiptId);
    expect(items, hasLength(2));
    expect(items.map((i) => i.productId), containsAll(['prod-cola', 'prod-juice']));

    // Stock movements landed (one per line, sale reason)
    final movements = await db.select(db.stockMovementsTable).get();
    expect(movements, hasLength(2));
    expect(movements.every((m) => m.reason == 'sale'), true);
    expect(movements.every((m) => m.receiptId == result.receiptId), true);
    expect(movements.every((m) => m.delta == -1), true);

    // Outbox queued: 1 receipt + 2 items + 2 movements = 5 entries
    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(5));
    final tables = outbox.map((o) => o.targetTable).toSet();
    expect(tables, {'receipts', 'receipt_items', 'stock_movements'});
  });

  test('weighted line produces stock_movement delta in grams', () async {
    await repo.createReceipt(
      workstationId: workstationId,
      shiftId: shiftId,
      userId: userId,
      receiptNumber: 1,
      lines: [weighted(weightGrams: 350)],
      totalAmountTiyin: 28000,
      vatAmountTiyin: 3000,
      cashAmountTiyin: 28000,
    );

    final movements = await db.select(db.stockMovementsTable).get();
    expect(movements, hasLength(1));
    expect(movements.first.delta, -350,
        reason: 'weighted goods debit grams, not pieces');
  });

  test('return receipt flips stock_movement sign and reason', () async {
    final result = await repo.createReceipt(
      workstationId: workstationId,
      shiftId: shiftId,
      userId: userId,
      receiptNumber: 1,
      lines: [piece(quantity: 2)],
      totalAmountTiyin: -50000, // negative for return
      vatAmountTiyin: 0,
      isReturn: true,
      refundForReceiptId: 'original-receipt-id',
    );

    final header = await repo.getById(result.receiptId);
    expect(header!.isReturn, true);
    expect(header.refundForReceiptId, 'original-receipt-id');

    final movements = await db.select(db.stockMovementsTable).get();
    expect(movements, hasLength(1));
    expect(movements.first.reason, 'return');
    expect(movements.first.delta, 2, reason: 'return puts pieces BACK on the shelf');
  });

  test('rejects empty lines list (zero-line receipts are not a real thing)', () async {
    await expectLater(
      () => repo.createReceipt(
        workstationId: workstationId,
        shiftId: shiftId,
        userId: userId,
        receiptNumber: 1,
        lines: const [],
        totalAmountTiyin: 0,
        vatAmountTiyin: 0,
      ),
      throwsArgumentError,
    );

    // No partial state from the failed call
    expect(await db.select(db.receiptsTable).get(), isEmpty);
    expect(await db.select(db.syncOutboxTable).get(), isEmpty);
  });

  test('createReceipt updates quantityOnHand via the shared stock_movements table', () async {
    // Seed 10 units via a delivery
    await stock.record(
      productId: 'prod-cola',
      delta: 10,
      reason: StockMovementReason.delivery,
    );
    expect(await stock.quantityOnHand('prod-cola'), 10);

    // Sell 3
    await repo.createReceipt(
      workstationId: workstationId,
      shiftId: shiftId,
      userId: userId,
      receiptNumber: 1,
      lines: [piece(quantity: 3)],
      totalAmountTiyin: 75000,
      vatAmountTiyin: 8036,
    );

    expect(await stock.quantityOnHand('prod-cola'), 7,
        reason: '10 in stock - 3 sold = 7');
  });

  test('payload_json on the receipt outbox row matches the wire shape sync_puller expects', () async {
    final result = await repo.createReceipt(
      storeId: storeId,
      workstationId: workstationId,
      shiftId: shiftId,
      userId: userId,
      receiptNumber: 42,
      lines: [piece()],
      totalAmountTiyin: 25000,
      vatAmountTiyin: 2679,
      cashAmountTiyin: 25000,
    );

    final receiptRow = (await db.select(db.syncOutboxTable).get())
        .firstWhere((o) => o.targetTable == 'receipts' && o.uuid == result.receiptId);
    final payload = jsonDecode(receiptRow.payloadJson) as Map<String, dynamic>;

    expect(payload['id'], result.receiptId);
    expect(payload['receipt_number'], 42);
    expect(payload['total_amount_tiyin'], 25000);
    expect(payload['workstation_id'], workstationId);
    expect(payload['shift_id'], shiftId);
    expect(payload['is_return'], false);
  });

  test('recentInShift returns most-recent-first within the same shift', () async {
    for (var i = 1; i <= 5; i++) {
      await repo.createReceipt(
        workstationId: workstationId,
        shiftId: shiftId,
        userId: userId,
        receiptNumber: i,
        lines: [piece()],
        totalAmountTiyin: 25000,
        vatAmountTiyin: 0,
      );
    }

    // Different shift
    await repo.createReceipt(
      workstationId: workstationId,
      shiftId: 'other-shift',
      userId: userId,
      receiptNumber: 1,
      lines: [piece()],
      totalAmountTiyin: 25000,
      vatAmountTiyin: 0,
    );

    final recent = await repo.recentInShift(shiftId, limit: 3);
    expect(recent, hasLength(3));
    // Newest first → highest receipt_number first via the tiebreak
    expect(recent.first.receiptNumber, 5);
  });

  test('createReceipt with explicit receiptId preserves it', () async {
    const explicit = '99999999-9999-4999-9999-999999999999';
    final result = await repo.createReceipt(
      receiptId: explicit,
      workstationId: workstationId,
      shiftId: shiftId,
      userId: userId,
      receiptNumber: 1,
      lines: [piece()],
      totalAmountTiyin: 25000,
      vatAmountTiyin: 0,
    );
    expect(result.receiptId, explicit);
  });
}
