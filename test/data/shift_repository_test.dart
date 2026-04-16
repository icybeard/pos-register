import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/shift_repository.dart';

void main() {
  late AppDatabase db;
  late ShiftRepository repo;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const workstationId = 'ws-1';
  const userId = 'cashier-1';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = ShiftRepository(db, tenantId: tenantId);
  });

  tearDown(() async {
    await db.close();
  });

  test('open inserts shift + outbox entry and returns id', () async {
    final id = await repo.open(
      workstationId: workstationId,
      userId: userId,
      shiftNumber: 1,
      cashStartTiyin: 100000,
    );

    final rows = await db.select(db.shiftsTable).get();
    expect(rows, hasLength(1));
    expect(rows.first.id, id);
    expect(rows.first.cashStartTiyin, 100000);
    expect(rows.first.closedAt, isNull);
    expect(rows.first.receiptCount, 0);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(1));
    expect(outbox.first.targetTable, 'shifts');
    expect(outbox.first.op, 'insert');
    final payload = jsonDecode(outbox.first.payloadJson) as Map<String, dynamic>;
    expect(payload['cash_start_tiyin'], 100000);
    expect(payload['shift_number'], 1);
  });

  test('currentOpen returns the open shift, null when none', () async {
    expect(
      await repo.currentOpen(workstationId: workstationId, userId: userId),
      isNull,
    );

    final id = await repo.open(
      workstationId: workstationId,
      userId: userId,
      shiftNumber: 1,
    );
    final current = await repo.currentOpen(workstationId: workstationId, userId: userId);
    expect(current, isNotNull);
    expect(current!.id, id);

    await repo.close(id, cashEndTiyin: 150000);
    expect(
      await repo.currentOpen(workstationId: workstationId, userId: userId),
      isNull,
      reason: 'closed shift should not be returned',
    );
  });

  test('recordReceipt rolls up sale totals + increments receipt count', () async {
    final id = await repo.open(
      workstationId: workstationId,
      userId: userId,
      shiftNumber: 1,
    );

    await repo.recordReceipt(
      id,
      const ShiftReceiptTotals(
        totalAmountTiyin: 25000,
        cashAmountTiyin: 30000,
      ),
    );
    await repo.recordReceipt(
      id,
      const ShiftReceiptTotals(
        totalAmountTiyin: 18000,
        cardAmountTiyin: 18000,
      ),
    );

    final row = (await db.select(db.shiftsTable).get()).single;
    expect(row.totalSalesTiyin, 43000);
    expect(row.totalCashTiyin, 30000);
    expect(row.totalCardTiyin, 18000);
    expect(row.receiptCount, 2);
    expect(row.returnCount, 0);

    // Each call enqueues an update row (on top of the open-insert)
    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox, hasLength(3));
    expect(outbox.last.op, 'update');
  });

  test('recordReceipt with isReturn=true updates return totals, not sales', () async {
    final id = await repo.open(
      workstationId: workstationId,
      userId: userId,
      shiftNumber: 1,
    );
    await repo.recordReceipt(
      id,
      const ShiftReceiptTotals(totalAmountTiyin: 25000, cashAmountTiyin: 25000),
    );
    await repo.recordReceipt(
      id,
      // Returns sometimes carry negative totalAmountTiyin — we use .abs() for
      // the return roll-up because the printed Z-report wants a positive number.
      const ShiftReceiptTotals(totalAmountTiyin: -10000, isReturn: true),
    );

    final row = (await db.select(db.shiftsTable).get()).single;
    expect(row.totalSalesTiyin, 25000, reason: 'sales untouched by return');
    expect(row.totalReturnsTiyin, 10000);
    expect(row.returnCount, 1);
    expect(row.receiptCount, 1);
  });

  test('close stamps closed_at + cash_end_tiyin', () async {
    final id = await repo.open(
      workstationId: workstationId,
      userId: userId,
      shiftNumber: 1,
      cashStartTiyin: 100000,
    );
    await repo.close(id, cashEndTiyin: 175000);

    final row = (await db.select(db.shiftsTable).get()).single;
    expect(row.closedAt, isNotNull);
    expect(row.cashEndTiyin, 175000);

    final outbox = await db.select(db.syncOutboxTable).get();
    expect(outbox.last.op, 'update');
    final payload = jsonDecode(outbox.last.payloadJson) as Map<String, dynamic>;
    expect(payload['closed_at'], isNotNull);
    expect(payload['cash_end_tiyin'], 175000);
  });

  test('recordReceipt on a closed shift throws', () async {
    final id = await repo.open(
      workstationId: workstationId,
      userId: userId,
      shiftNumber: 1,
    );
    await repo.close(id, cashEndTiyin: 0);

    await expectLater(
      () => repo.recordReceipt(
        id,
        const ShiftReceiptTotals(totalAmountTiyin: 1000),
      ),
      throwsStateError,
    );
  });

  test('close on unknown shift throws', () async {
    await expectLater(
      () => repo.close('not-a-real-id', cashEndTiyin: 0),
      throwsStateError,
    );
  });

  test('close on already-closed shift throws', () async {
    final id = await repo.open(
      workstationId: workstationId,
      userId: userId,
      shiftNumber: 1,
    );
    await repo.close(id, cashEndTiyin: 100);
    await expectLater(
      () => repo.close(id, cashEndTiyin: 200),
      throwsStateError,
    );
  });

  test('currentOpen is scoped to (workstation, user) and tenant', () async {
    await repo.open(
      workstationId: 'ws-A',
      userId: 'cashier-A',
      shiftNumber: 1,
    );
    await repo.open(
      workstationId: 'ws-B',
      userId: 'cashier-B',
      shiftNumber: 1,
    );

    expect(
      (await repo.currentOpen(workstationId: 'ws-A', userId: 'cashier-A'))?.workstationId,
      'ws-A',
    );
    expect(
      (await repo.currentOpen(workstationId: 'ws-B', userId: 'cashier-A'))?.userId,
      isNull,
      reason: 'different workstation → no open shift for this cashier',
    );
    expect(
      (await repo.currentOpen(workstationId: 'ws-A', userId: 'cashier-B'))?.userId,
      isNull,
      reason: 'different cashier → no open shift on this workstation',
    );

    // Cross-tenant
    final otherRepo = ShiftRepository(db, tenantId: 'other-tenant');
    expect(
      await otherRepo.currentOpen(workstationId: 'ws-A', userId: 'cashier-A'),
      isNull,
      reason: 'other tenant sees no shifts',
    );
  });
}
