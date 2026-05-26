import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/features/sales/bloc/sales_bloc.dart';
import 'package:pos_system/features/sales/models/cart_item.dart';
import 'package:pos_system/services/api_client.dart';
import '../../../mocks/mock_api_client.dart';

void main() {
  late MockApiClient mockApi;
  late SalesBloc bloc;

  setUp(() {
    mockApi = MockApiClient();
    bloc = SalesBloc(mockApi);
  });

  tearDown(() async {
    await bloc.close();
  });

  // -------------------------------------------------------------------------
  // Helper
  // -------------------------------------------------------------------------
  Future<List<SalesState>> collectStates(
    SalesBloc bloc,
    SalesEvent event, {
    int count = 1,
    Duration timeout = const Duration(seconds: 2),
  }) async {
    final states = <SalesState>[];
    final completer = Completer<void>();
    final sub = bloc.stream.listen((SalesState s) {
      states.add(s);
      if (states.length >= count && !completer.isCompleted) {
        completer.complete();
      }
    });

    bloc.add(event);
    await completer.future.timeout(timeout);
    await sub.cancel();
    return states;
  }

  const pieceItem = CartItem(
    productId: 'p1',
    name: 'Хлеб',
    unit: 'pcs',
    basePrice: 45000,
    quantity: 1,
    vatRate: 12,
  );

  const weightedItem = CartItem(
    productId: 'p2',
    name: 'Сыр',
    unit: 'kg',
    basePrice: 320000,
    isWeighted: true,
    weightGrams: 450,
    vatRate: 12,
  );

  // -------------------------------------------------------------------------
  // AddToCart
  // -------------------------------------------------------------------------
  group('AddToCart', () {
    test('adds item to empty cart', () async {
      final states = await collectStates(bloc, AddToCart(pieceItem));

      expect(states.last.items.length, 1);
      expect(states.last.items.first.productId, 'p1');
      expect(states.last.subtotal, 45000);
      expect(states.last.total, 45000);
    });

    test('adds multiple items', () async {
      await collectStates(bloc, AddToCart(pieceItem));
      final states = await collectStates(bloc, AddToCart(weightedItem));

      expect(states.last.items.length, 2);
      // 45000 + 144000 = 189000
      expect(states.last.subtotal, 45000 + 144000);
    });

    test('clears search results and errors after add', () async {
      // Set up search results first
      mockApi.onSearchProducts = (q, l) async => {
            'products': [
              {'ID': 'p1', 'Name': 'Test'}
            ]
          };
      await collectStates(bloc, SearchProduct('test'), count: 2);

      // Add to cart should clear search results
      final states = await collectStates(bloc, AddToCart(pieceItem));
      expect(states.last.searchResults, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // RemoveFromCart
  // -------------------------------------------------------------------------
  group('RemoveFromCart', () {
    test('removes item by index', () async {
      await collectStates(bloc, AddToCart(pieceItem));
      await collectStates(bloc, AddToCart(weightedItem));
      expect(bloc.state.items.length, 2);

      final states = await collectStates(bloc, RemoveFromCart(0));
      expect(states.last.items.length, 1);
      expect(states.last.items.first.productId, 'p2');
    });
  });

  // -------------------------------------------------------------------------
  // UpdateQuantity
  // -------------------------------------------------------------------------
  group('UpdateQuantity', () {
    test('updates quantity and recalculates totals', () async {
      await collectStates(bloc, AddToCart(pieceItem));
      expect(bloc.state.subtotal, 45000);

      final states =
          await collectStates(bloc, UpdateQuantity(0, 3));
      expect(states.last.items.first.quantity, 3);
      expect(states.last.subtotal, 135000);
    });
  });

  // -------------------------------------------------------------------------
  // UpdateWeight
  // -------------------------------------------------------------------------
  group('UpdateWeight', () {
    test('updates weight for weighted item', () async {
      await collectStates(bloc, AddToCart(weightedItem));
      // Initial: 450g * 320000 => 144000
      expect(bloc.state.subtotal, 144000);

      final states =
          await collectStates(bloc, UpdateWeight(0, 1000));
      // 1000g * 320000 => 320000
      expect(states.last.items.first.weightGrams, 1000);
      expect(states.last.subtotal, 320000);
    });
  });

  // -------------------------------------------------------------------------
  // ApplyDiscount
  // -------------------------------------------------------------------------
  group('ApplyDiscount', () {
    test('applies discount and recalculates total', () async {
      await collectStates(bloc, AddToCart(pieceItem));
      expect(bloc.state.total, 45000);

      final states =
          await collectStates(bloc, ApplyDiscount(5000));
      expect(states.last.discountTiyin, 5000);
      expect(states.last.total, 40000);
    });

    test('total clamped to 0 if discount exceeds subtotal', () async {
      await collectStates(bloc, AddToCart(pieceItem));

      final states =
          await collectStates(bloc, ApplyDiscount(100000));
      expect(states.last.total, 0);
    });
  });

  // -------------------------------------------------------------------------
  // ClearCart
  // -------------------------------------------------------------------------
  group('ClearCart', () {
    test('resets entire state', () async {
      await collectStates(bloc, AddToCart(pieceItem));
      await collectStates(bloc, ApplyDiscount(5000));

      final states = await collectStates(bloc, ClearCart());
      expect(states.last.items, isEmpty);
      expect(states.last.discountTiyin, 0);
      expect(states.last.subtotal, 0);
      expect(states.last.total, 0);
    });
  });

  // -------------------------------------------------------------------------
  // SearchProduct
  // -------------------------------------------------------------------------
  group('SearchProduct', () {
    test('populates searchResults from API', () async {
      mockApi.onSearchProducts = (q, l) async => {
            'products': [
              {
                'ID': 'p1',
                'Name': 'Хлеб',
                'SalePrice': 45000,
              },
              {
                'ID': 'p2',
                'Name': 'Хлебцы',
                'SalePrice': 55000,
              },
            ]
          };

      final states =
          await collectStates(bloc, SearchProduct('хлеб'), count: 2);

      // First state: search status flips to Searching
      expect(states.first.searchStatus, isA<Searching>());
      // Last state: results populated
      expect(states.last.searchResults.length, 2);
      expect(states.last.searchStatus, isA<SearchIdle>());
    });

    test('empty query clears results', () async {
      mockApi.onSearchProducts = (q, l) async => {
            'products': [
              {'ID': 'p1', 'Name': 'Test'}
            ]
          };
      await collectStates(bloc, SearchProduct('test'), count: 2);
      expect(bloc.state.searchResults.length, 1);

      final states = await collectStates(bloc, SearchProduct(''));
      expect(states.last.searchResults, isEmpty);
      expect(states.last.searchStatus, isA<SearchIdle>());
    });

    test('error sets error message', () async {
      mockApi.onSearchProducts =
          (q, l) async => throw Exception('network');

      final states =
          await collectStates(bloc, SearchProduct('test'), count: 2);

      expect(states.last.searchStatus, isA<SearchIdle>());
      expect(states.last.error, isNotNull);
    });

    test('barcode-like query with no local results triggers NKT search',
        () async {
      mockApi.onSearchProducts = (q, l) async => {'products': <Map<String, dynamic>>[]};
      mockApi.onNktSearchByGTIN = (gtin) async => {
            'products': [
              {'NTIN': 'nkt1', 'Name': 'NKT Product'}
            ]
          };

      // 13-digit barcode
      final states = await collectStates(
          bloc, SearchProduct('4607027760014'),
          count: 4);

      // Should have NKT results
      final last = states.last;
      expect(last.nktResults.length, 1);
      expect(last.searchStatus, isA<SearchIdle>());
    });
  });

  // -------------------------------------------------------------------------
  // ScanBarcode
  // -------------------------------------------------------------------------
  group('ScanBarcode', () {
    test('found locally — adds to cart', () async {
      mockApi.onGetProductByBarcode = (barcode) async => {
            'ID': 'p1',
            'Name': 'Хлеб',
            'NTIN': 'ntin1',
            'SaleUnit': 'pcs',
            'SalePrice': 45000,
            'IsWeighted': false,
            'VATRate': 12,
          };

      // ScanBarcode internally calls add(AddToCart(...)), so we wait for 2 states:
      // one from ScanBarcode processing, one from AddToCart.
      // The AddToCart emission is what we care about.
      bloc.add(ScanBarcode('4607027760014'));
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(bloc.state.items.length, 1);
      expect(bloc.state.items.first.productId, 'p1');
    });

    test('not found locally (404) — triggers NKT search', () async {
      mockApi.onGetProductByBarcode =
          (barcode) async => throw ApiException(404, 'not found');
      mockApi.onNktSearchByGTIN = (gtin) async => {
            'products': [
              {'NTIN': 'nkt1', 'Name': 'NKT Product'}
            ]
          };

      final states = <SalesState>[];
      final completer = Completer<void>();
      final sub = bloc.stream.listen((s) {
        states.add(s);
        // We need NktSearching to flip back to SearchIdle then nktResults populated
        if (states.length >= 2 &&
            states.last.searchStatus is SearchIdle &&
            states.last.nktResults.isNotEmpty &&
            !completer.isCompleted) {
          completer.complete();
        }
      });

      bloc.add(ScanBarcode('4607027760014'));
      await completer.future.timeout(const Duration(seconds: 2));
      await sub.cancel();

      expect(states.last.nktResults.length, 1);
    });

    test('not found locally, NKT also empty — error', () async {
      mockApi.onGetProductByBarcode =
          (barcode) async => throw ApiException(404, 'not found');
      mockApi.onNktSearchByGTIN = (gtin) async => {'products': <Map<String, dynamic>>[]};

      final states = <SalesState>[];
      final completer = Completer<void>();
      final sub = bloc.stream.listen((s) {
        states.add(s);
        if (states.length >= 2 &&
            states.last.searchStatus is SearchIdle &&
            !completer.isCompleted) {
          completer.complete();
        }
      });

      bloc.add(ScanBarcode('4607027760014'));
      await completer.future.timeout(const Duration(seconds: 2));
      await sub.cancel();

      expect(states.last.error, isNotNull);
      expect(states.last.error!, contains('не найден'));
    });

    test('generic exception — error', () async {
      mockApi.onGetProductByBarcode =
          (barcode) async => throw Exception('timeout');

      final states = <SalesState>[];
      final completer = Completer<void>();
      final sub = bloc.stream.listen((s) {
        states.add(s);
        if (!completer.isCompleted) completer.complete();
      });

      bloc.add(ScanBarcode('123'));
      await completer.future.timeout(const Duration(seconds: 2));
      await sub.cancel();

      expect(states.last.error, contains('сканирования'));
    });
  });

  // -------------------------------------------------------------------------
  // CompleteSale
  // -------------------------------------------------------------------------
  group('CompleteSale', () {
    test('successful sale — resets cart, shows success', () async {
      await collectStates(bloc, AddToCart(pieceItem));

      Map<String, dynamic>? capturedReceipt;
      mockApi.onCreateReceipt = (data) async {
        capturedReceipt = data;
        return {'ID': 'r1', 'Number': 1};
      };

      final event = CompleteSale(
        shiftId: 's1',
        cashierId: 'c1',
        paymentType: 'cash',
        cashAmount: 45000,
        cardAmount: 0,
        qrAmount: 0,
        changeAmount: 0,
      );

      final states = await collectStates(bloc, event, count: 2);

      // First state: payment status flips to PaymentProcessing
      expect(states.first.paymentStatus, isA<PaymentProcessing>());
      // Last state: success
      expect(states.last.saleSuccess, isNotNull);
      expect(states.last.items, isEmpty);

      // Verify receipt payload
      expect(capturedReceipt, isNotNull);
      expect(capturedReceipt!['ShiftID'], 's1');
      expect(capturedReceipt!['Total'], 45000);
      expect((capturedReceipt!['Items'] as List).length, 1);
    });

    test('does nothing with empty cart', () async {
      final states = <SalesState>[];
      final sub = bloc.stream.listen(states.add);

      bloc.add(CompleteSale(
        shiftId: 's1',
        cashierId: 'c1',
        paymentType: 'cash',
        cashAmount: 0,
        cardAmount: 0,
        qrAmount: 0,
        changeAmount: 0,
      ));
      await Future<void>.delayed(const Duration(milliseconds: 100));
      await sub.cancel();

      expect(states, isEmpty);
    });

    test('API error 400 — shows appropriate message', () async {
      await collectStates(bloc, AddToCart(pieceItem));

      mockApi.onCreateReceipt =
          (data) async => throw ApiException(400, 'bad request');

      final states = await collectStates(
        bloc,
        CompleteSale(
          shiftId: 's1',
          cashierId: 'c1',
          paymentType: 'cash',
          cashAmount: 45000,
          cardAmount: 0,
          qrAmount: 0,
          changeAmount: 0,
        ),
        count: 2,
      );

      expect(states.last.paymentStatus, isA<PaymentIdle>());
      expect(states.last.error, contains('Некорректные'));
    });

    test('network error — shows connection message', () async {
      await collectStates(bloc, AddToCart(pieceItem));

      mockApi.onCreateReceipt = (data) async => throw Exception('timeout');

      final states = await collectStates(
        bloc,
        CompleteSale(
          shiftId: 's1',
          cashierId: 'c1',
          paymentType: 'cash',
          cashAmount: 45000,
          cardAmount: 0,
          qrAmount: 0,
          changeAmount: 0,
        ),
        count: 2,
      );

      expect(states.last.error, contains('связи'));
    });
  });

  // -------------------------------------------------------------------------
  // SalesState computed properties
  // -------------------------------------------------------------------------
  group('SalesState computed properties', () {
    test('subtotal sums items', () {
      const state = SalesState(items: [
        CartItem(
            productId: 'p1', name: 'A', unit: 'pcs', basePrice: 10000, quantity: 2),
        CartItem(
            productId: 'p2', name: 'B', unit: 'pcs', basePrice: 30000, quantity: 1),
      ]);
      expect(state.subtotal, 50000);
    });

    test('total = subtotal - discount, clamped to 0', () {
      const state = SalesState(
        items: [
          CartItem(
              productId: 'p1', name: 'A', unit: 'pcs', basePrice: 10000),
        ],
        discountTiyin: 20000,
      );
      expect(state.total, 0);
    });

    test('vatAmount sums all item VAT', () {
      const state = SalesState(items: [
        CartItem(
            productId: 'p1',
            name: 'A',
            unit: 'pcs',
            basePrice: 11200,
            vatRate: 12),
        CartItem(
            productId: 'p2',
            name: 'B',
            unit: 'pcs',
            basePrice: 11200,
            vatRate: 0),
      ]);
      // 1200 + 0 = 1200
      expect(state.vatAmount, 1200);
    });

    test('itemCount returns number of items', () {
      const state = SalesState(items: [
        CartItem(productId: 'p1', name: 'A', unit: 'pcs', basePrice: 100),
        CartItem(productId: 'p2', name: 'B', unit: 'pcs', basePrice: 200),
      ]);
      expect(state.itemCount, 2);
    });

    test('copyWith preserves values and allows overrides', () {
      const original = SalesState(
        items: [
          CartItem(productId: 'p1', name: 'A', unit: 'pcs', basePrice: 100),
        ],
        discountTiyin: 50,
      );

      final updated = original.copyWith(discountTiyin: 100);
      expect(updated.discountTiyin, 100);
      expect(updated.items.length, 1);
      // Original unchanged
      expect(original.discountTiyin, 50);
    });
  });

  // -------------------------------------------------------------------------
  // ClearNktResults
  // -------------------------------------------------------------------------
  group('ClearNktResults', () {
    test('clears NKT results and query', () async {
      // First trigger NKT results
      mockApi.onSearchProducts = (q, l) async => {'products': <Map<String, dynamic>>[]};
      mockApi.onNktSearchByGTIN = (gtin) async => {
            'products': [
              {'NTIN': 'n1', 'Name': 'P'}
            ]
          };
      await collectStates(bloc, SearchProduct('4607027760014'), count: 4);
      expect(bloc.state.nktResults.isNotEmpty, isTrue);

      // Clear
      final states = await collectStates(bloc, ClearNktResults());
      expect(states.last.nktResults, isEmpty);
      expect(states.last.nktQuery, isNull);
    });
  });
}
