import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/api_client.dart';
import '../../../services/sales/sales_service.dart';
import '../models/cart_item.dart';

// ═══════════════════════════════════════════════════════════════
// Parked cart snapshot
// ═══════════════════════════════════════════════════════════════

@immutable
class ParkedCart {
  final List<CartItem> items;
  final int discountTiyin;
  final DateTime parkedAt;

  const ParkedCart({
    required this.items,
    required this.discountTiyin,
    required this.parkedAt,
  });

  int get total {
    final subtotal = items.fold(0, (sum, item) => sum + item.total);
    final result = subtotal - discountTiyin;
    return result < 0 ? 0 : result;
  }

  int get itemCount => items.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ParkedCart &&
        listEquals(items, other.items) &&
        discountTiyin == other.discountTiyin &&
        parkedAt == other.parkedAt;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(items), discountTiyin, parkedAt);
}

// ═══════════════════════════════════════════════════════════════
// State machines
// ═══════════════════════════════════════════════════════════════

/// Discriminated union for search/scan progress. Replaces the prior
/// `isSearching` + `isNktSearching` pair: those two booleans could in
/// principle co-exist (an impossible state) and forced consumers to
/// AND/OR them. Search and the NKT fallback are mutually exclusive in
/// the actual flow — the controller transitions [Searching] → [NktSearching]
/// → [SearchIdle], never holding both simultaneously.
sealed class SearchStatus {
  const SearchStatus();
}

class SearchIdle extends SearchStatus {
  const SearchIdle();
  @override
  bool operator ==(Object other) => other is SearchIdle;
  @override
  int get hashCode => 0;
}

class Searching extends SearchStatus {
  const Searching();
  @override
  bool operator ==(Object other) => other is Searching;
  @override
  int get hashCode => 1;
}

class NktSearching extends SearchStatus {
  const NktSearching();
  @override
  bool operator ==(Object other) => other is NktSearching;
  @override
  int get hashCode => 2;
}

/// Discriminated union for the payment-completion handshake. Replaces
/// `isProcessingPayment` so a future `PaymentRefunding` / `PaymentVoid`
/// state can be added without sprouting more booleans.
sealed class PaymentStatus {
  const PaymentStatus();
}

class PaymentIdle extends PaymentStatus {
  const PaymentIdle();
  @override
  bool operator ==(Object other) => other is PaymentIdle;
  @override
  int get hashCode => 0;
}

class PaymentProcessing extends PaymentStatus {
  const PaymentProcessing();
  @override
  bool operator ==(Object other) => other is PaymentProcessing;
  @override
  int get hashCode => 1;
}

// ═══════════════════════════════════════════════════════════════
// State
// ═══════════════════════════════════════════════════════════════

@immutable
class SalesState {
  final List<CartItem> items;
  final int discountTiyin;
  final List<Map<String, dynamic>> searchResults;
  final SearchStatus searchStatus;
  final PaymentStatus paymentStatus;
  final String? error;
  final String? saleSuccess;
  final List<Map<String, dynamic>> nktResults;
  final String? nktQuery; // the barcode that triggered NKT search
  final String lastQuery; // last search query for UI hints

  /// Parked carts (saved aside while serving another customer)
  final List<ParkedCart> parkedCarts;

  /// Whether undo is available (last removed item can be restored)
  final CartItem? undoItem;
  final int? undoIndex;

  /// Categories loaded from server
  final List<Map<String, dynamic>> categories;
  final String? selectedCategoryId; // null = all

  const SalesState({
    this.items = const [],
    this.discountTiyin = 0,
    this.searchResults = const [],
    this.searchStatus = const SearchIdle(),
    this.paymentStatus = const PaymentIdle(),
    this.error,
    this.saleSuccess,
    this.nktResults = const [],
    this.nktQuery,
    this.lastQuery = '',
    this.parkedCarts = const [],
    this.undoItem,
    this.undoIndex,
    this.categories = const [],
    this.selectedCategoryId,
  });

  /// Подитого до скидки (тиын)
  int get subtotal => items.fold(0, (sum, item) => sum + item.total);

  /// Итого (тиын)
  int get total {
    final result = subtotal - discountTiyin;
    return result < 0 ? 0 : result;
  }

  /// Общий НДС (тиын)
  int get vatAmount => items.fold(0, (sum, item) => sum + item.vatAmount);

  /// Количество позиций
  int get itemCount => items.length;

  bool get canUndo => undoItem != null;

  SalesState copyWith({
    List<CartItem>? items,
    int? discountTiyin,
    List<Map<String, dynamic>>? searchResults,
    SearchStatus? searchStatus,
    PaymentStatus? paymentStatus,
    String? error,
    String? saleSuccess,
    bool clearSaleSuccess = false,
    bool clearError = false,
    List<Map<String, dynamic>>? nktResults,
    String? nktQuery,
    bool clearNkt = false,
    String? lastQuery,
    List<ParkedCart>? parkedCarts,
    CartItem? undoItem,
    int? undoIndex,
    bool clearUndo = false,
    List<Map<String, dynamic>>? categories,
    String? selectedCategoryId,
    bool clearCategoryFilter = false,
  }) {
    return SalesState(
      items: items ?? this.items,
      discountTiyin: discountTiyin ?? this.discountTiyin,
      searchResults: searchResults ?? this.searchResults,
      searchStatus: searchStatus ?? this.searchStatus,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      error: clearError ? null : (error ?? this.error),
      saleSuccess: clearSaleSuccess ? null : (saleSuccess ?? this.saleSuccess),
      nktResults: clearNkt ? const [] : (nktResults ?? this.nktResults),
      nktQuery: clearNkt ? null : (nktQuery ?? this.nktQuery),
      lastQuery: lastQuery ?? this.lastQuery,
      parkedCarts: parkedCarts ?? this.parkedCarts,
      undoItem: clearUndo ? null : (undoItem ?? this.undoItem),
      undoIndex: clearUndo ? null : (undoIndex ?? this.undoIndex),
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategoryFilter ? null : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }

  // Value-equality so ConsumerWidget rebuilds short-circuit when copyWith()
  // yields a state whose fields are unchanged. Without this, every method
  // call (including searchProduct fired on each keystroke) rebuilds the full
  // _CartPane subtree even when nothing visible changed. List-typed fields
  // use Flutter's listEquals; CartItem has value semantics already (verified
  // by the parity test suite).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SalesState &&
        listEquals(items, other.items) &&
        discountTiyin == other.discountTiyin &&
        listEquals(searchResults, other.searchResults) &&
        searchStatus == other.searchStatus &&
        paymentStatus == other.paymentStatus &&
        error == other.error &&
        saleSuccess == other.saleSuccess &&
        listEquals(nktResults, other.nktResults) &&
        nktQuery == other.nktQuery &&
        lastQuery == other.lastQuery &&
        listEquals(parkedCarts, other.parkedCarts) &&
        undoItem == other.undoItem &&
        undoIndex == other.undoIndex &&
        listEquals(categories, other.categories) &&
        selectedCategoryId == other.selectedCategoryId;
  }

  @override
  int get hashCode => Object.hashAll([
        Object.hashAll(items),
        discountTiyin,
        Object.hashAll(searchResults),
        searchStatus,
        paymentStatus,
        error,
        saleSuccess,
        Object.hashAll(nktResults),
        nktQuery,
        lastQuery,
        Object.hashAll(parkedCarts),
        undoItem,
        undoIndex,
        Object.hashAll(categories),
        selectedCategoryId,
      ]);
}

// ═══════════════════════════════════════════════════════════════
// Controller (was: SalesBloc — flutter_bloc → Riverpod migration P0b)
// ═══════════════════════════════════════════════════════════════
//
// Method-per-former-event so the call-site rewrite is mechanical:
//   bloc.add(AddToCart(x))       →  controller.addToCart(x)
//   bloc.add(SearchProduct(q))   →  controller.searchProduct(q)
//
// State mutations go through `state = state.copyWith(...)` instead of
// `emit(...)`. Notifier suppresses identical-state rewrites automatically
// (it compares via `==`), so SalesState's hand-rolled equality is what makes
// the listEquals-driven rebuild-suppression work — same effect Equatable
// gave us before.

class SalesController extends Notifier<SalesState> {
  late final ApiClient _api;
  late final SalesService? _salesService;

  @override
  SalesState build() {
    // ProviderScope.overrides supplies these in main.dart; tests can override
    // with mocks via container.overrides. The provider definitions below are
    // the dependency seam.
    _api = ref.read(salesApiClientProvider);
    _salesService = ref.read(salesServiceProvider);
    return const SalesState();
  }

  void addToCart(CartItem item) {
    final items = List<CartItem>.from(state.items)..add(item);
    state = state.copyWith(
      items: items,
      searchResults: [],
      clearError: true,
      clearSaleSuccess: true,
      clearNkt: true,
      clearUndo: true,
    );
  }

  void removeFromCart(int index) {
    if (index < 0 || index >= state.items.length) return;
    final removedItem = state.items[index];
    final items = List<CartItem>.from(state.items)..removeAt(index);
    state = state.copyWith(
      items: items,
      undoItem: removedItem,
      undoIndex: index,
    );
  }

  void undoLastAction() {
    if (state.undoItem == null) return;
    final items = List<CartItem>.from(state.items);
    final insertIndex = (state.undoIndex ?? items.length).clamp(0, items.length);
    items.insert(insertIndex, state.undoItem!);
    state = state.copyWith(items: items, clearUndo: true);
  }

  void parkCart() {
    if (state.items.isEmpty) return;
    final parked = ParkedCart(
      items: List.unmodifiable(state.items),
      discountTiyin: state.discountTiyin,
      parkedAt: DateTime.now(),
    );
    final parkedCarts = List<ParkedCart>.from(state.parkedCarts)..add(parked);
    state = SalesState(parkedCarts: parkedCarts, categories: state.categories);
  }

  void resumeParkedCart(int index) {
    if (index < 0 || index >= state.parkedCarts.length) return;
    final cart = state.parkedCarts[index];

    // If current cart is not empty, park it first
    List<ParkedCart> parkedCarts;
    if (state.items.isNotEmpty) {
      final currentParked = ParkedCart(
        items: List.unmodifiable(state.items),
        discountTiyin: state.discountTiyin,
        parkedAt: DateTime.now(),
      );
      parkedCarts = List<ParkedCart>.from(state.parkedCarts)
        ..removeAt(index)
        ..add(currentParked);
    } else {
      parkedCarts = List<ParkedCart>.from(state.parkedCarts)..removeAt(index);
    }

    state = state.copyWith(
      items: List<CartItem>.from(cart.items),
      discountTiyin: cart.discountTiyin,
      parkedCarts: parkedCarts,
      clearUndo: true,
    );
  }

  void deleteParkedCart(int index) {
    if (index < 0 || index >= state.parkedCarts.length) return;
    final parkedCarts = List<ParkedCart>.from(state.parkedCarts)..removeAt(index);
    state = state.copyWith(parkedCarts: parkedCarts);
  }

  void updateQuantity(int index, double quantity) {
    final items = List<CartItem>.from(state.items);
    items[index] = items[index].copyWith(quantity: quantity);
    state = state.copyWith(items: items);
  }

  void updateWeight(int index, int weightGrams) {
    final items = List<CartItem>.from(state.items);
    items[index] = items[index].copyWith(weightGrams: weightGrams);
    state = state.copyWith(items: items);
  }

  void applyDiscount(int discountTiyin) {
    state = state.copyWith(discountTiyin: discountTiyin);
  }

  void applyItemDiscount(int index, int discountTiyin) {
    if (index < 0 || index >= state.items.length) return;
    final items = List<CartItem>.from(state.items);
    items[index] = items[index].copyWith(discount: discountTiyin);
    state = state.copyWith(items: items);
  }

  void clearCart() {
    state = SalesState(parkedCarts: state.parkedCarts, categories: state.categories);
  }

  void clearNktResults() {
    state = state.copyWith(clearNkt: true);
  }

  void scaleWeightUpdate(int weightGrams) {
    final items = state.items;
    if (items.isEmpty) return;

    int? lastWeightedIdx;
    for (int i = items.length - 1; i >= 0; i--) {
      if (items[i].isWeighted) {
        lastWeightedIdx = i;
        break;
      }
    }
    if (lastWeightedIdx == null) return;

    final updated = List<CartItem>.from(items);
    updated[lastWeightedIdx] = updated[lastWeightedIdx].copyWith(weightGrams: weightGrams);
    state = state.copyWith(items: updated);
  }

  /// Returns true if all characters are digits
  static bool _isAllDigits(String q) => q.isNotEmpty && q.codeUnits.every((c) => c >= 48 && c <= 57);

  /// Returns true if the query looks like a full barcode (8-14 digits)
  static bool _isBarcode(String q) => q.length >= 8 && q.length <= 14 && _isAllDigits(q);

  Future<void> loadCategories() async {
    try {
      final resp = await _api.listCategories();
      final cats = (resp['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      state = state.copyWith(categories: cats);
    } on Exception catch (e) {
      assert(() {
        debugPrint('[SalesController] loadCategories error: $e');
        return true;
      }());
      state = state.copyWith(error: 'Не удалось загрузить категории');
    }
  }

  void selectCategory(String? categoryId) {
    if (categoryId == null) {
      state = state.copyWith(clearCategoryFilter: true);
    } else {
      state = state.copyWith(selectedCategoryId: categoryId);
    }
  }

  Future<void> searchProduct(String query) async {
    assert(() {
      debugPrint('[SalesController] search query: "$query"');
      return true;
    }());
    if (query.isEmpty) {
      state = state.copyWith(
        searchResults: [],
        searchStatus: const SearchIdle(),
        clearNkt: true,
        lastQuery: '',
      );
      return;
    }

    state = state.copyWith(searchStatus: const Searching(), clearNkt: true, lastQuery: query);
    try {
      final response = await _api.searchProducts(query);
      final products = (response['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      state = state.copyWith(searchResults: products, searchStatus: const SearchIdle());

      // If no local results and query looks like a barcode → auto-search NKT
      if (products.isEmpty && _isBarcode(query)) {
        state = state.copyWith(searchStatus: const NktSearching(), nktQuery: query);
        try {
          final nktResp = await _api.nktSearchByGTIN(query);
          final nktProducts = (nktResp['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          state = state.copyWith(nktResults: nktProducts, searchStatus: const SearchIdle());
        } on Exception catch (e) {
          assert(() {
            debugPrint('[SalesController] NKT search error: $e');
            return true;
          }());
          state = state.copyWith(searchStatus: const SearchIdle());
        }
      }
    } on Exception catch (e) {
      assert(() {
        debugPrint('[SalesController] search error: $e');
        return true;
      }());
      state = state.copyWith(searchStatus: const SearchIdle(), error: 'Ошибка поиска');
    }
  }

  Future<void> scanBarcode(String barcode) async {
    try {
      final response = await _api.getProductByBarcode(barcode);
      final item = CartItem(
        productId: response['ID'] as String,
        name: response['Name'] as String,
        ntin: response['NTIN'] as String?,
        unit: response['SaleUnit'] as String,
        basePrice: (response['SalePrice'] as num).toInt(),
        isWeighted: response['IsWeighted'] as bool? ?? false,
        vatRate: (response['VATRate'] as num?)?.toInt() ?? 12,
      );
      addToCart(item);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Not found locally — try NKT
        state = state.copyWith(searchStatus: const NktSearching(), nktQuery: barcode);
        try {
          final nktResp = await _api.nktSearchByGTIN(barcode);
          final nktProducts = (nktResp['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (nktProducts.isNotEmpty) {
            state = state.copyWith(nktResults: nktProducts, searchStatus: const SearchIdle());
          } else {
            state = state.copyWith(
              searchStatus: const SearchIdle(),
              error: 'Товар не найден ни локально, ни в НКТ',
            );
          }
        } on Exception catch (nktErr) {
          assert(() {
            debugPrint('[SalesController] NKT fallback error: $nktErr');
            return true;
          }());
          state = state.copyWith(searchStatus: const SearchIdle(), error: 'Товар не найден');
        }
      } else {
        assert(() {
          debugPrint('[SalesController] scan error: $e');
          return true;
        }());
        state = state.copyWith(
          searchStatus: const SearchIdle(),
          error: 'Ошибка сканирования (${e.statusCode})',
        );
      }
    } on Exception catch (e) {
      assert(() {
        debugPrint('[SalesController] scan unexpected: $e');
        return true;
      }());
      state = state.copyWith(error: 'Ошибка сканирования');
    }
  }

  Future<void> completeSale({
    required String shiftId,
    required String cashierId,
    required String paymentType, // cash, card, kaspiQR, mixed
    required int cashAmount,
    required int cardAmount,
    required int qrAmount,
    required int changeAmount,
    String? overrideUserId,
  }) async {
    if (state.items.isEmpty) return;

    state = state.copyWith(paymentStatus: const PaymentProcessing(), clearError: true);

    try {
      if (_salesService case final svc?) {
        final lines = <SalesLineInput>[];
        for (final ci in state.items) {
          lines.add(SalesLineInput(
            productId: ci.productId,
            productName: ci.name,
            ntin: ci.ntin,
            isWeighted: ci.isWeighted,
            quantity: ci.isWeighted ? 0 : ci.quantity.toInt(),
            weightGrams: ci.isWeighted ? ci.weightGrams : 0,
            unitPriceTiyin: ci.basePrice,
            itemTotalTiyin: ci.total,
            discountTiyin: ci.discount,
            vatRate: ci.vatRate,
            unit: ci.unit,
          ));
        }
        await svc.completeSale(SalesCompletionInput(
          shiftId: shiftId,
          cashierId: cashierId,
          paymentType: paymentType,
          lines: lines,
          subtotalTiyin: state.subtotal,
          discountTiyin: state.discountTiyin,
          totalTiyin: state.total,
          vatAmountTiyin: state.vatAmount,
          cashAmountTiyin: cashAmount,
          cardAmountTiyin: cardAmount,
          qrAmountTiyin: qrAmount,
          changeAmountTiyin: changeAmount,
          overrideByUserId: overrideUserId,
        ));
      } else {
        final items = <Map<String, dynamic>>[];
        for (int i = 0; i < state.items.length; i++) {
          final ci = state.items[i];
          items.add({
            'ProductID': ci.productId,
            'Name': ci.name,
            'NTIN': ci.ntin ?? '',
            // Locked rule: integer wire format, no floats. For weighted
            // items the line is "one ticket position" so Quantity = 1;
            // the actual weight rides in WeightGrams below.
            'Quantity': ci.isWeighted ? 1 : ci.quantity,
            'Unit': ci.unit,
            'Price': ci.basePrice,
            'BasePrice': ci.basePrice,
            'Discount': ci.discount,
            'Total': ci.total,
            'VATRate': ci.vatRate,
            'VATAmount': ci.vatAmount,
            'IsWeighted': ci.isWeighted,
            'WeightGrams': ci.weightGrams,
            'SortOrder': i + 1,
          });
        }

        await _api.createReceipt({
          'ShiftID': shiftId,
          'CashierID': cashierId,
          'Subtotal': state.subtotal,
          'Discount': state.discountTiyin,
          'Total': state.total,
          'VATAmount': state.vatAmount,
          'PaymentType': paymentType,
          'CashAmount': cashAmount,
          'CardAmount': cardAmount,
          'QRAmount': qrAmount,
          'ChangeAmount': changeAmount,
          'FiscalStatus': 'pending',
          'Items': items,
        });
      }

      state = SalesState(
        saleSuccess: 'Оплата принята!',
        parkedCarts: state.parkedCarts,
        categories: state.categories,
      );
    } on ApiException catch (e) {
      assert(() {
        debugPrint('[SalesController] completeSale API error: $e');
        return true;
      }());
      final msg = switch (e.statusCode) {
        400 => 'Некорректные данные чека',
        404 => 'Смена не найдена',
        409 => 'Конфликт данных — повторите попытку',
        _ => 'Ошибка сервера (${e.statusCode})',
      };
      state = state.copyWith(paymentStatus: const PaymentIdle(), error: msg);
    } on Exception catch (e) {
      assert(() {
        debugPrint('[SalesController] completeSale error: $e');
        return true;
      }());
      state = state.copyWith(
        paymentStatus: const PaymentIdle(),
        error: 'Нет связи с сервером. Попробуйте ещё раз.',
      );
    }
  }
}

// ═══════════════════════════════════════════════════════════════
// Providers
// ═══════════════════════════════════════════════════════════════
//
// Seams for the controller's dependencies. main.dart overrides these on
// the root ProviderScope; tests override them on a per-test ProviderContainer
// (replacing the prior BlocProvider.value injection pattern).

final salesApiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError('salesApiClientProvider must be overridden at app root');
});

final salesServiceProvider = Provider<SalesService?>((ref) => null);

final salesControllerProvider =
    NotifierProvider<SalesController, SalesState>(SalesController.new);
