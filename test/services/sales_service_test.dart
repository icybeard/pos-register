import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/shift_repository.dart';
import 'package:pos_system/data/repositories/stock_movement_repository.dart';
import 'package:pos_system/services/sales/sales_service.dart';

void main() {
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const deviceId = 'register-test';
  const workstationId = 'ws-1';
  const cashierId = 'cashier-1';
  const storeId = '22222222-2222-2222-2222-222222222222';

  SalesLineInput coke({int qty = 1}) => SalesLineInput(
        productId: 'prod-coke',
        productName: 'Coca-Cola 0.5L',
        productBarcode: '4870001234567',
        ntin: 'NTIN-1',
        isWeighted: false,
        quantity: qty,
        unitPriceTiyin: 25000,
        itemTotalTiyin: 25000 * qty,
        unit: 'pcs',
      );

  SalesLineInput bread350g() => const SalesLineInput(
        productId: 'prod-bread',
        productName: 'Хлеб',
        isWeighted: true,
        weightGrams: 350,
        unitPriceTiyin: 80000, // 800₸/kg
        itemTotalTiyin: 28000,
        unit: 'kg',
      );

  group('DriftSalesService', () {
    late AppDatabase db;
    late ShiftRepository shifts;
    late StockMovementRepository stock;
    late DriftSalesService svc;
    late String shiftId;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      shifts = ShiftRepository(db, tenantId: tenantId);
      stock = StockMovementRepository(db, tenantId: tenantId, deviceId: deviceId);
      svc = DriftSalesService(
        db,
        tenantId: tenantId,
        deviceId: deviceId,
        workstationId: workstationId,
        storeId: storeId,
      );
      // Open a shift the sales path can roll into
      shiftId = await shifts.open(
        workstationId: workstationId,
        userId: cashierId,
        shiftNumber: 1,
        cashStartTiyin: 100000,
      );
    });

    tearDown(() async => db.close());

    test('completeSale writes receipt + items + stock_movements + shift roll-up', () async {
      final result = await svc.completeSale(SalesCompletionInput(
        shiftId: shiftId,
        cashierId: cashierId,
        paymentType: 'cash',
        lines: [coke(qty: 2)],
        subtotalTiyin: 50000,
        discountTiyin: 0,
        totalTiyin: 50000,
        vatAmountTiyin: 5357,
        cashAmountTiyin: 50000,
      ));

      expect(result.receiptId, isNotEmpty);

      // Receipt header landed
      final receipts = await db.select(db.receiptsTable).get();
      expect(receipts, hasLength(1));
      expect(receipts.first.totalAmountTiyin, 50000);
      expect(receipts.first.receiptNumber, 1, reason: 'shift had 0 receipts → number = 1');

      // Item landed (1 line × 2 qty = 1 receipt_item row, qty 2)
      final items = await db.select(db.receiptItemsTable).get();
      expect(items, hasLength(1));
      expect(items.first.quantity, 2);

      // Stock_movement landed (delta -2 piece)
      final movements = await db.select(db.stockMovementsTable).get();
      expect(movements, hasLength(1));
      expect(movements.first.delta, -2);
      expect(movements.first.reason, 'sale');
      expect(movements.first.cashierUserId, cashierId);

      // Shift rolled up
      final shift = await shifts.currentOpen(workstationId: workstationId, userId: cashierId);
      expect(shift!.receiptCount, 1);
      expect(shift.totalSalesTiyin, 50000);
      expect(shift.totalCashTiyin, 50000);
    });

    test('weighted line emits stock_movement delta in grams', () async {
      await svc.completeSale(SalesCompletionInput(
        shiftId: shiftId,
        cashierId: cashierId,
        paymentType: 'cash',
        lines: [bread350g()],
        subtotalTiyin: 28000,
        discountTiyin: 0,
        totalTiyin: 28000,
        vatAmountTiyin: 3000,
        cashAmountTiyin: 28000,
      ));

      final movements = await db.select(db.stockMovementsTable).get();
      expect(movements.single.delta, -350,
          reason: 'weighted goods debit grams, not pieces');
    });

    test('split payment (cash + card + qr) rolls up to all three shift counters', () async {
      await svc.completeSale(SalesCompletionInput(
        shiftId: shiftId,
        cashierId: cashierId,
        paymentType: 'mixed',
        lines: [coke(), coke(qty: 2)],
        subtotalTiyin: 75000,
        discountTiyin: 0,
        totalTiyin: 75000,
        vatAmountTiyin: 8036,
        cashAmountTiyin: 25000,
        cardAmountTiyin: 30000,
        qrAmountTiyin: 20000,
      ));

      final shift = await shifts.currentOpen(workstationId: workstationId, userId: cashierId);
      expect(shift!.totalCashTiyin, 25000);
      expect(shift.totalCardTiyin, 30000);
      expect(shift.totalQrTiyin, 20000);
      expect(shift.totalSalesTiyin, 75000);
    });

    test('return creates a return receipt with negative-direction stock_movement', () async {
      await svc.completeSale(SalesCompletionInput(
        shiftId: shiftId,
        cashierId: cashierId,
        paymentType: 'cash',
        lines: [coke()],
        subtotalTiyin: 25000,
        discountTiyin: 0,
        totalTiyin: 25000,
        vatAmountTiyin: 2679,
        cashAmountTiyin: 25000,
      ));

      await svc.completeSale(SalesCompletionInput(
        shiftId: shiftId,
        cashierId: cashierId,
        paymentType: 'cash',
        lines: [coke()],
        subtotalTiyin: -25000,
        discountTiyin: 0,
        totalTiyin: -25000,
        vatAmountTiyin: 0,
        isReturn: true,
        refundForReceiptId: 'orig-id',
      ));

      // 2 receipts, 1 sale + 1 return
      final receipts = await db.select(db.receiptsTable).get();
      expect(receipts, hasLength(2));
      expect(receipts.where((r) => r.isReturn), hasLength(1));

      // Sale movement -1, return movement +1 (stock back on shelf)
      final movements = await db.select(db.stockMovementsTable).get();
      expect(movements, hasLength(2));
      expect(movements.map((m) => m.delta).toSet(), {-1, 1});
      expect(movements.map((m) => m.reason).toSet(), {'sale', 'return'});

      // Shift counters: 1 sale, 1 return
      final shift = await shifts.currentOpen(workstationId: workstationId, userId: cashierId);
      expect(shift!.receiptCount, 1);
      expect(shift.returnCount, 1);
      expect(shift.totalReturnsTiyin, 25000); // .abs() of return total
    });

    test('completeSale on a closed shift surfaces the inner StateError', () async {
      await shifts.close(shiftId, cashEndTiyin: 100000);
      await expectLater(
        () => svc.completeSale(SalesCompletionInput(
          shiftId: shiftId,
          cashierId: cashierId,
          paymentType: 'cash',
          lines: [coke()],
          subtotalTiyin: 25000,
          discountTiyin: 0,
          totalTiyin: 25000,
          vatAmountTiyin: 0,
          cashAmountTiyin: 25000,
        )),
        throwsStateError,
      );
    });

    test('end-to-end stock arithmetic (delivery 10 - sale 3 = 7 on hand)', () async {
      await stock.record(
        productId: 'prod-coke',
        delta: 10,
        reason: StockMovementReason.delivery,
      );

      await svc.completeSale(SalesCompletionInput(
        shiftId: shiftId,
        cashierId: cashierId,
        paymentType: 'cash',
        lines: [coke(qty: 3)],
        subtotalTiyin: 75000,
        discountTiyin: 0,
        totalTiyin: 75000,
        vatAmountTiyin: 8036,
        cashAmountTiyin: 75000,
      ));

      expect(await stock.quantityOnHand('prod-coke'), 7);
    });
  });

  group('createSalesService factory', () {
    test('returns the drift impl (drift-local-first is the only path)', () {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      final svc = createSalesService(
        db: db,
        tenantId: tenantId,
        deviceId: deviceId,
        workstationId: workstationId,
      );
      expect(svc, isA<DriftSalesService>());
    });
  });

  group('DisabledSalesService', () {
    test('completeSale throws StateError pointing at register activation', () async {
      const svc = DisabledSalesService();
      await expectLater(
        svc.completeSale(SalesCompletionInput(
          shiftId: 's', cashierId: 'c', paymentType: 'cash',
          lines: [coke()],
          subtotalTiyin: 25000, discountTiyin: 0, totalTiyin: 25000,
          vatAmountTiyin: 0, cashAmountTiyin: 25000,
        )),
        throwsA(isA<StateError>()),
      );
    });
  });
}
