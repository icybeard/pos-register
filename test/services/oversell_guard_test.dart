import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/stock_movement_repository.dart';
import 'package:pos_system/services/override/oversell_guard.dart';
import 'package:pos_system/services/sales/sales_service.dart';

void main() {
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const deviceId = 'test-reg';

  late AppDatabase db;
  late StockMovementRepository stock;
  late OversellGuard guard;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    stock = StockMovementRepository(db, tenantId: tenantId, deviceId: deviceId);
    guard = OversellGuard(stock);
  });

  tearDown(() async => db.close());

  SalesLineInput piece({
    String productId = 'prod-coke',
    int qty = 1,
    int priceTiyin = 25000,
  }) =>
      SalesLineInput(
        productId: productId,
        productName: 'Coca-Cola',
        isWeighted: false,
        quantity: qty,
        weightGrams: 0,
        unitPriceTiyin: priceTiyin,
        itemTotalTiyin: priceTiyin * qty,
        unit: 'pcs',
      );

  SalesLineInput weighted({
    String productId = 'prod-bread',
    int grams = 350,
    int pricePerKg = 80000,
  }) =>
      SalesLineInput(
        productId: productId,
        productName: 'Хлеб',
        isWeighted: true,
        quantity: 0,
        weightGrams: grams,
        unitPriceTiyin: pricePerKg,
        itemTotalTiyin: (grams * pricePerKg) ~/ 1000,
        unit: 'kg',
      );

  test('empty cart → no shortages', () async {
    expect(await guard.check(const []), isEmpty);
  });

  test('single line within stock → no shortages', () async {
    await stock.record(productId: 'prod-coke', delta: 10, reason: StockMovementReason.delivery);
    expect(await guard.check([piece(qty: 3)]), isEmpty);
  });

  test('single line exactly on stock → no shortage (=0 on hand after sale)', () async {
    await stock.record(productId: 'prod-coke', delta: 3, reason: StockMovementReason.delivery);
    expect(await guard.check([piece(qty: 3)]), isEmpty);
  });

  test('piece line exceeds stock by 1 → single shortage entry', () async {
    await stock.record(productId: 'prod-coke', delta: 2, reason: StockMovementReason.delivery);
    final shortages = await guard.check([piece(qty: 3)]);
    expect(shortages, hasLength(1));
    expect(shortages.first.productId, 'prod-coke');
    expect(shortages.first.requested, 3);
    expect(shortages.first.onHand, 2);
    expect(shortages.first.shortageUnits, 1);
    expect(shortages.first.isWeighted, false);
  });

  test('product never stocked → onHand 0 → shortage = full request', () async {
    final shortages = await guard.check([piece(qty: 2)]);
    expect(shortages, hasLength(1));
    expect(shortages.first.onHand, 0);
    expect(shortages.first.shortageUnits, 2);
  });

  test('already negative stock (previously authorised oversell) still flags next sale', () async {
    await stock.record(productId: 'prod-coke', delta: 1, reason: StockMovementReason.delivery);
    // Burn down to -2 via a prior override
    await stock.record(
      productId: 'prod-coke',
      delta: -3,
      reason: StockMovementReason.sale,
      overrideByUserId: 'prior-manager',
    );
    // Now any further sale is an oversell
    final shortages = await guard.check([piece(qty: 1)]);
    expect(shortages, hasLength(1));
    expect(shortages.first.onHand, -2, reason: 'already-negative on-hand surfaced to UI');
    expect(shortages.first.shortageUnits, 3); // 1 requested - (-2) = 3
  });

  test('weighted line exceeds stock in grams → shortage flagged', () async {
    await stock.record(productId: 'prod-bread', delta: 200, reason: StockMovementReason.delivery);
    final shortages = await guard.check([weighted(grams: 350)]);
    expect(shortages, hasLength(1));
    expect(shortages.first.isWeighted, true);
    expect(shortages.first.requested, 350);
    expect(shortages.first.onHand, 200);
  });

  test('mixed cart: one line ok, two lines short → two shortages returned', () async {
    await stock.record(productId: 'prod-coke', delta: 10, reason: StockMovementReason.delivery);
    await stock.record(productId: 'prod-bread', delta: 100, reason: StockMovementReason.delivery);
    // prod-juice never stocked → 0
    final shortages = await guard.check([
      piece(productId: 'prod-coke', qty: 2),       // ok (10 ≥ 2)
      weighted(productId: 'prod-bread', grams: 500),  // short (100 < 500)
      piece(productId: 'prod-juice', qty: 1),      // short (0 < 1)
    ]);
    expect(shortages, hasLength(2));
    expect(shortages.map((s) => s.productId).toSet(),
        {'prod-bread', 'prod-juice'});
  });

  test('zero-quantity line is skipped (not in cart, really — but tolerated)', () async {
    // qty=0 piece line should be filtered out, not produce a no-op shortage
    final shortages = await guard.check([piece(productId: 'prod-coke', qty: 0)]);
    expect(shortages, isEmpty);
  });

  test('store-scoped guard reads from the right store bucket', () async {
    const storeA = 'store-a';
    const storeB = 'store-b';

    await stock.record(
      storeId: storeA,
      productId: 'prod-coke',
      delta: 5,
      reason: StockMovementReason.delivery,
    );
    // storeB has no stock

    // Guard pointed at storeA sees 5, no shortage for qty 3
    final guardA = OversellGuard(stock, storeId: storeA);
    expect(await guardA.check([piece(qty: 3)]), isEmpty);

    // Guard pointed at storeB sees tenant-wide + storeB-specific. Here
    // there's no tenant-wide row, so storeB sees 0 and shorts out.
    final guardB = OversellGuard(stock, storeId: storeB);
    final shortages = await guardB.check([piece(qty: 1)]);
    expect(shortages, hasLength(1));
    expect(shortages.first.onHand, 0);
  });
}
