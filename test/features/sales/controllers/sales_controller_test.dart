// Action-by-action coverage for [SalesController] plus end-to-end cart flows.
//
// Every public method on the controller is a former bloc "event" — each gets
// its own test. The `group('full flows')` block stitches actions together the
// way a cashier hits them at the register: add → search → NKT fallback →
// remove → undo, park/resume, and a complete-sale handshake.
//
// Dependencies are injected through the provider seams the controller exposes
// (`salesApiClientProvider`, `salesServiceProvider`). We override the API with
// the shared [MockApiClient] and leave the SalesService null so completeSale
// exercises the `_api.createReceipt` legacy path (the path that does not need a
// drift database).

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_system/services/api_client.dart';
import 'package:pos_system/features/sales/controllers/sales_controller.dart';
import 'package:pos_system/features/sales/models/cart_item.dart';

import '../../../mocks/mock_api_client.dart';

void main() {
  late MockApiClient api;
  late ProviderContainer container;

  SalesController controller() => container.read(salesControllerProvider.notifier);
  SalesState read() => container.read(salesControllerProvider);

  setUp(() {
    api = MockApiClient();
    container = ProviderContainer(overrides: [
      salesApiClientProvider.overrideWithValue(api),
      // salesServiceProvider stays at its default (null) → legacy createReceipt path.
    ]);
  });

  tearDown(() => container.dispose());

  // Cola: 250₸ pcs, 12% VAT.
  CartItem cola({double qty = 1}) => CartItem(
        productId: 'prod-cola',
        name: 'Coca-Cola 0.5L',
        ntin: 'NTIN-COLA',
        unit: 'pcs',
        basePrice: 25000,
        quantity: qty,
      );

  // Bread: weighted, 800₸/kg.
  CartItem bread({int grams = 350}) => CartItem(
        productId: 'prod-bread',
        name: 'Хлеб',
        ntin: 'NTIN-BREAD',
        unit: 'kg',
        basePrice: 80000,
        isWeighted: true,
        weightGrams: grams,
      );

  // ═══════════════════════════════════════════════════════════════
  // addToCart
  // ═══════════════════════════════════════════════════════════════

  group('addToCart', () {
    test('appends item and exposes subtotal/total/vat', () {
      controller().addToCart(cola());
      final s = read();
      expect(s.items, hasLength(1));
      expect(s.itemCount, 1);
      expect(s.subtotal, 25000);
      expect(s.total, 25000);
      expect(s.vatAmount, greaterThan(0)); // 12% inside
    });

    test('two adds accumulate in order', () {
      controller()
        ..addToCart(cola())
        ..addToCart(bread());
      final s = read();
      expect(s.items.map((i) => i.productId), ['prod-cola', 'prod-bread']);
      expect(s.subtotal, 25000 + bread().total);
    });

    test('clears undo scratch state armed by a prior removal', () {
      final c = controller();
      c
        ..addToCart(cola())
        ..removeFromCart(0); // undo is armed
      expect(read().canUndo, isTrue);
      c.addToCart(cola());
      expect(read().canUndo, isFalse, reason: 'addToCart clears undo');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // removeFromCart + undo
  // ═══════════════════════════════════════════════════════════════

  group('removeFromCart', () {
    test('removes the item at index and arms undo', () {
      final c = controller()..addToCart(cola())..addToCart(bread());
      c.removeFromCart(0);
      final s = read();
      expect(s.items, hasLength(1));
      expect(s.items.single.productId, 'prod-bread');
      expect(s.canUndo, isTrue);
      expect(s.undoItem!.productId, 'prod-cola');
    });

    test('out-of-range index is a no-op', () {
      final c = controller()..addToCart(cola());
      c.removeFromCart(5);
      c.removeFromCart(-1);
      expect(read().items, hasLength(1));
      expect(read().canUndo, isFalse);
    });
  });

  group('undoLastAction', () {
    test('restores removed item at its original index', () {
      final c = controller()..addToCart(cola())..addToCart(bread());
      c.removeFromCart(0);
      c.undoLastAction();
      final s = read();
      expect(s.items.map((i) => i.productId), ['prod-cola', 'prod-bread']);
      expect(s.canUndo, isFalse, reason: 'undo consumed');
    });

    test('no-op when nothing to undo', () {
      final c = controller()..addToCart(cola());
      c.undoLastAction();
      expect(read().items, hasLength(1));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // updateQuantity / updateWeight / scaleWeightUpdate
  // ═══════════════════════════════════════════════════════════════

  group('quantity & weight', () {
    test('updateQuantity changes line total', () {
      final c = controller()..addToCart(cola());
      c.updateQuantity(0, 3);
      expect(read().items.single.quantity, 3);
      expect(read().subtotal, 75000);
    });

    test('updateWeight changes weighted line total', () {
      final c = controller()..addToCart(bread(grams: 0));
      c.updateWeight(0, 500); // 0.5kg × 800₸ = 400₸
      expect(read().items.single.weightGrams, 500);
      expect(read().items.single.total, 40000);
    });

    test('scaleWeightUpdate targets the last weighted line only', () {
      final c = controller()
        ..addToCart(bread(grams: 100))
        ..addToCart(cola())
        ..addToCart(bread(grams: 100));
      c.scaleWeightUpdate(750);
      final items = read().items;
      expect(items[0].weightGrams, 100, reason: 'earlier weighted line untouched');
      expect(items[2].weightGrams, 750, reason: 'last weighted line updated');
    });

    test('scaleWeightUpdate is a no-op with no weighted items', () {
      final c = controller()..addToCart(cola());
      c.scaleWeightUpdate(750);
      expect(read().items.single.weightGrams, 0);
    });

    test('scaleWeightUpdate is a no-op on empty cart', () {
      controller().scaleWeightUpdate(750);
      expect(read().items, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // discounts
  // ═══════════════════════════════════════════════════════════════

  group('discounts', () {
    test('applyDiscount subtracts from total but never below zero', () {
      final c = controller()..addToCart(cola());
      c.applyDiscount(10000);
      expect(read().total, 15000);
      c.applyDiscount(999999);
      expect(read().total, 0, reason: 'clamped at zero');
    });

    test('applyItemDiscount reduces a single line', () {
      final c = controller()..addToCart(cola())..addToCart(bread());
      c.applyItemDiscount(0, 5000);
      expect(read().items[0].discount, 5000);
      expect(read().items[0].total, 20000);
    });

    test('applyItemDiscount out-of-range is a no-op', () {
      final c = controller()..addToCart(cola());
      c.applyItemDiscount(9, 5000);
      expect(read().items.single.discount, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // clearCart / parking
  // ═══════════════════════════════════════════════════════════════

  group('clearCart', () {
    test('empties items but keeps parked carts', () {
      final c = controller()..addToCart(cola());
      c.parkCart(); // parks then clears
      c.addToCart(bread());
      c.clearCart();
      final s = read();
      expect(s.items, isEmpty);
      expect(s.parkedCarts, hasLength(1));
    });
  });

  group('parkCart / resumeParkedCart / deleteParkedCart', () {
    test('parkCart stashes current cart and clears the active one', () {
      final c = controller()..addToCart(cola())..addToCart(bread());
      c.applyDiscount(5000);
      c.parkCart();
      final s = read();
      expect(s.items, isEmpty);
      expect(s.parkedCarts, hasLength(1));
      expect(s.parkedCarts.single.items, hasLength(2));
      expect(s.parkedCarts.single.discountTiyin, 5000);
    });

    test('parkCart is a no-op on empty cart', () {
      controller().parkCart();
      expect(read().parkedCarts, isEmpty);
    });

    test('resumeParkedCart restores items and discount', () {
      final c = controller()..addToCart(cola());
      c.applyDiscount(2000);
      c.parkCart();
      c.resumeParkedCart(0);
      final s = read();
      expect(s.items.single.productId, 'prod-cola');
      expect(s.discountTiyin, 2000);
      expect(s.parkedCarts, isEmpty);
    });

    test('resumeParkedCart parks the current non-empty cart first', () {
      final c = controller()..addToCart(cola());
      c.parkCart(); // park #1 (cola)
      c.addToCart(bread()); // active cart now has bread
      c.resumeParkedCart(0); // resume cola, bread should get parked
      final s = read();
      expect(s.items.single.productId, 'prod-cola');
      expect(s.parkedCarts, hasLength(1));
      expect(s.parkedCarts.single.items.single.productId, 'prod-bread');
    });

    test('deleteParkedCart removes the snapshot', () {
      final c = controller()..addToCart(cola());
      c.parkCart();
      c.deleteParkedCart(0);
      expect(read().parkedCarts, isEmpty);
    });

    test('parked-cart index guards reject out-of-range', () {
      final c = controller()..addToCart(cola());
      c.parkCart();
      c.resumeParkedCart(9);
      c.deleteParkedCart(-1);
      expect(read().parkedCarts, hasLength(1), reason: 'no mutation on bad index');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // categories
  // ═══════════════════════════════════════════════════════════════

  group('categories', () {
    test('loadCategories populates from API', () async {
      api.onListCategories = (_) async => {
            'categories': [
              {'id': 'c1', 'name': 'Напитки'},
              {'id': 'c2', 'name': 'Хлеб'},
            ]
          };
      await controller().loadCategories();
      expect(read().categories, hasLength(2));
    });

    test('loadCategories surfaces an error message on failure', () async {
      api.onListCategories = (_) async => throw ApiException(500, 'boom');
      await controller().loadCategories();
      expect(read().error, 'Не удалось загрузить категории');
    });

    test('selectCategory sets and clears the filter', () {
      final c = controller();
      c.selectCategory('c1');
      expect(read().selectedCategoryId, 'c1');
      c.selectCategory(null);
      expect(read().selectedCategoryId, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // searchProduct (+ NKT fallback)
  // ═══════════════════════════════════════════════════════════════

  group('searchProduct', () {
    test('empty query resets results to idle', () async {
      await controller().searchProduct('');
      final s = read();
      expect(s.searchResults, isEmpty);
      expect(s.searchStatus, const SearchIdle());
      expect(s.lastQuery, '');
    });

    test('returns local matches without touching NKT', () async {
      var nktCalled = false;
      api.onSearchProducts = (q, _) async => {
            'products': [
              {'ID': 'prod-cola', 'Name': 'Coca-Cola'}
            ]
          };
      api.onNktSearchByGTIN = (_) async {
        nktCalled = true;
        return {'products': <Map<String, dynamic>>[]};
      };
      await controller().searchProduct('cola');
      expect(read().searchResults, hasLength(1));
      expect(read().searchStatus, const SearchIdle());
      expect(nktCalled, isFalse);
    });

    test('barcode with no local hit falls back to NKT', () async {
      api.onSearchProducts = (q, _) async => {'products': <Map<String, dynamic>>[]};
      api.onNktSearchByGTIN = (gtin) async => {
            'products': [
              {'gtin': gtin, 'name': 'Imported good'}
            ]
          };
      await controller().searchProduct('4870001234567'); // 13 digits
      final s = read();
      expect(s.searchResults, isEmpty);
      expect(s.nktResults, hasLength(1));
      expect(s.searchStatus, const SearchIdle());
    });

    test('short numeric query does not trigger NKT fallback', () async {
      var nktCalled = false;
      api.onSearchProducts = (q, _) async => {'products': <Map<String, dynamic>>[]};
      api.onNktSearchByGTIN = (_) async {
        nktCalled = true;
        return {'products': <Map<String, dynamic>>[]};
      };
      await controller().searchProduct('123'); // < 8 digits
      expect(nktCalled, isFalse);
    });

    test('NKT failure leaves search idle without crashing', () async {
      api.onSearchProducts = (q, _) async => {'products': <Map<String, dynamic>>[]};
      api.onNktSearchByGTIN = (_) async => throw ApiException(503, 'down');
      await controller().searchProduct('4870001234567');
      expect(read().searchStatus, const SearchIdle());
    });

    test('search API failure sets error', () async {
      api.onSearchProducts = (q, _) async => throw ApiException(500, 'boom');
      await controller().searchProduct('cola');
      expect(read().error, 'Ошибка поиска');
      expect(read().searchStatus, const SearchIdle());
    });
  });

  group('clearNktResults', () {
    test('drops nkt results and query', () async {
      api.onSearchProducts = (q, _) async => {'products': <Map<String, dynamic>>[]};
      api.onNktSearchByGTIN = (gtin) async => {
            'products': [
              {'gtin': gtin}
            ]
          };
      await controller().searchProduct('4870001234567');
      expect(read().nktResults, isNotEmpty);
      controller().clearNktResults();
      expect(read().nktResults, isEmpty);
      expect(read().nktQuery, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // scanBarcode (+ NKT fallback)
  // ═══════════════════════════════════════════════════════════════

  group('scanBarcode', () {
    test('found barcode is added straight to the cart', () async {
      api.onGetProductByBarcode = (bc) async => {
            'ID': 'prod-cola',
            'Name': 'Coca-Cola',
            'NTIN': 'NTIN-COLA',
            'SaleUnit': 'pcs',
            'SalePrice': 25000,
            'IsWeighted': false,
            'VATRate': 12,
          };
      await controller().scanBarcode('4870001234567');
      final s = read();
      expect(s.items.single.productId, 'prod-cola');
      expect(s.items.single.basePrice, 25000);
    });

    test('404 falls back to NKT and shows results when present', () async {
      api.onGetProductByBarcode = (bc) async => throw ApiException(404, 'nf');
      api.onNktSearchByGTIN = (gtin) async => {
            'products': [
              {'gtin': gtin, 'name': 'Imported'}
            ]
          };
      await controller().scanBarcode('4870001234567');
      expect(read().nktResults, hasLength(1));
      expect(read().items, isEmpty);
    });

    test('404 with empty NKT shows "not found anywhere" error', () async {
      api.onGetProductByBarcode = (bc) async => throw ApiException(404, 'nf');
      api.onNktSearchByGTIN = (_) async => {'products': <Map<String, dynamic>>[]};
      await controller().scanBarcode('4870001234567');
      expect(read().error, 'Товар не найден ни локально, ни в НКТ');
    });

    test('non-404 API error reports status code', () async {
      api.onGetProductByBarcode = (bc) async => throw ApiException(500, 'boom');
      await controller().scanBarcode('4870001234567');
      expect(read().error, 'Ошибка сканирования (500)');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // completeSale
  // ═══════════════════════════════════════════════════════════════

  group('completeSale', () {
    test('no-op on empty cart', () async {
      await controller().completeSale(
        shiftId: 's1',
        cashierId: 'c1',
        paymentType: 'cash',
        cashAmount: 0,
        cardAmount: 0,
        qrAmount: 0,
        changeAmount: 0,
      );
      expect(read().saleSuccess, isNull);
    });

    test('posts a receipt and resets cart on success', () async {
      Map<String, dynamic>? sent;
      api.onCreateReceipt = (data) async {
        sent = data;
        return {'ID': 'receipt-1'};
      };
      final c = controller()..addToCart(cola(qty: 2));
      await c.completeSale(
        shiftId: 's1',
        cashierId: 'c1',
        paymentType: 'cash',
        cashAmount: 50000,
        cardAmount: 0,
        qrAmount: 0,
        changeAmount: 0,
      );
      final s = read();
      expect(s.saleSuccess, 'Оплата принята!');
      expect(s.items, isEmpty, reason: 'cart cleared after sale');
      expect(sent!['ShiftID'], 's1');
      expect(sent!['Total'], 50000);
      expect((sent!['Items'] as List), hasLength(1));
    });

    test('maps 404 to "shift not found"', () async {
      api.onCreateReceipt = (_) async => throw ApiException(404, 'no shift');
      final c = controller()..addToCart(cola());
      await c.completeSale(
        shiftId: 's1',
        cashierId: 'c1',
        paymentType: 'cash',
        cashAmount: 25000,
        cardAmount: 0,
        qrAmount: 0,
        changeAmount: 0,
      );
      expect(read().error, 'Смена не найдена');
      expect(read().items, hasLength(1), reason: 'cart preserved on failure');
    });

    test('network error surfaces a retry message', () async {
      api.onCreateReceipt = (_) async => throw Exception('socket');
      final c = controller()..addToCart(cola());
      await c.completeSale(
        shiftId: 's1',
        cashierId: 'c1',
        paymentType: 'cash',
        cashAmount: 25000,
        cardAmount: 0,
        qrAmount: 0,
        changeAmount: 0,
      );
      expect(read().error, 'Нет связи с сервером. Попробуйте ещё раз.');
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // Full flows
  // ═══════════════════════════════════════════════════════════════

  group('full flows', () {
    test('add → remove → undo → checkout', () async {
      api.onCreateReceipt = (_) async => {'ID': 'r1'};
      final c = controller()
        ..addToCart(cola())
        ..addToCart(bread());
      c.removeFromCart(1); // oops, remove bread
      c.undoLastAction(); // bring it back
      expect(read().items, hasLength(2));

      await c.completeSale(
        shiftId: 's1',
        cashierId: 'c1',
        paymentType: 'cash',
        cashAmount: read().total,
        cardAmount: 0,
        qrAmount: 0,
        changeAmount: 0,
      );
      expect(read().saleSuccess, isNotNull);
      expect(read().items, isEmpty);
    });

    test('search miss → NKT fallback → clear → scan adds the item', () async {
      // 1. Search a barcode not held locally → NKT shows a candidate.
      api.onSearchProducts = (q, _) async => {'products': <Map<String, dynamic>>[]};
      api.onNktSearchByGTIN = (gtin) async => {
            'products': [
              {'gtin': gtin, 'name': 'New import'}
            ]
          };
      final c = controller();
      await c.searchProduct('4870001234567');
      expect(read().nktResults, hasLength(1));

      // 2. Dismiss the NKT panel.
      c.clearNktResults();
      expect(read().nktResults, isEmpty);

      // 3. Once catalogued, scanning the same barcode adds it to the cart.
      api.onGetProductByBarcode = (bc) async => {
            'ID': 'prod-new',
            'Name': 'New import',
            'NTIN': 'NTIN-NEW',
            'SaleUnit': 'pcs',
            'SalePrice': 30000,
            'IsWeighted': false,
            'VATRate': 12,
          };
      await c.scanBarcode('4870001234567');
      expect(read().items.single.productId, 'prod-new');
    });

    test('park one customer, serve another, resume the first', () {
      final c = controller()..addToCart(cola());
      c.parkCart(); // customer A parked
      expect(read().parkedCarts, hasLength(1));

      // Serve customer B
      c.addToCart(bread());
      expect(read().items.single.productId, 'prod-bread');

      // Resume A → B gets auto-parked
      c.resumeParkedCart(0);
      expect(read().items.single.productId, 'prod-cola');
      expect(read().parkedCarts.single.items.single.productId, 'prod-bread');
    });
  });
}
