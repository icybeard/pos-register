import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/api_client.dart';
import '../../../services/sales/sales_service.dart';
import '../models/cart_item.dart';

// ═══════════════════════════════════════════════════════════════
// Events
// ═══════════════════════════════════════════════════════════════

sealed class SalesEvent {}

class AddToCart extends SalesEvent {
  final CartItem item;
  AddToCart(this.item);
}

class RemoveFromCart extends SalesEvent {
  final int index;
  RemoveFromCart(this.index);
}

class UpdateQuantity extends SalesEvent {
  final int index;
  final double quantity;
  UpdateQuantity(this.index, this.quantity);
}

class UpdateWeight extends SalesEvent {
  final int index;
  final int weightGrams;
  UpdateWeight(this.index, this.weightGrams);
}

/// Global discount on the whole receipt
class ApplyDiscount extends SalesEvent {
  final int discountTiyin;
  ApplyDiscount(this.discountTiyin);
}

/// Per-item discount (in tiyin)
class ApplyItemDiscount extends SalesEvent {
  final int index;
  final int discountTiyin;
  ApplyItemDiscount(this.index, this.discountTiyin);
}

class ClearCart extends SalesEvent {}

/// Undo the last destructive action (remove item)
class UndoLastAction extends SalesEvent {}

/// Park current cart (save aside) to serve another customer
class ParkCart extends SalesEvent {}

/// Resume a previously parked cart
class ResumeParkedCart extends SalesEvent {
  final int index;
  ResumeParkedCart(this.index);
}

/// Delete a parked cart
class DeleteParkedCart extends SalesEvent {
  final int index;
  DeleteParkedCart(this.index);
}

class SearchProduct extends SalesEvent {
  final String query;
  SearchProduct(this.query);
}

class ScanBarcode extends SalesEvent {
  final String barcode;
  ScanBarcode(this.barcode);
}

/// Creates a receipt on the server after payment
class CompleteSale extends SalesEvent {
  final String shiftId;
  final String cashierId;
  final String paymentType; // cash, card, kaspiQR, mixed
  final int cashAmount;
  final int cardAmount;
  final int qrAmount;
  final int changeAmount;

  /// UUID of the manager who authorised an oversell, if any. The UI runs
  /// `OversellGuard` + `ManagerOverrideDialog` BEFORE dispatching this event
  /// — BLoCs can't pop modals — and stamps the returned user id here.
  /// Null on normal sales.
  final String? overrideUserId;

  CompleteSale({
    required this.shiftId,
    required this.cashierId,
    required this.paymentType,
    required this.cashAmount,
    required this.cardAmount,
    required this.qrAmount,
    required this.changeAmount,
    this.overrideUserId,
  });
}

/// Dismiss NKT results
class ClearNktResults extends SalesEvent {}

/// Scale weight update for the last weighted item in cart
class ScaleWeightUpdate extends SalesEvent {
  final int weightGrams;
  ScaleWeightUpdate(this.weightGrams);
}

/// Load categories from server
class LoadCategories extends SalesEvent {}

/// Filter products by category
class SelectCategory extends SalesEvent {
  final String? categoryId; // null = all
  SelectCategory(this.categoryId);
}

// ═══════════════════════════════════════════════════════════════
// Parked cart snapshot
// ═══════════════════════════════════════════════════════════════

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
}

// ═══════════════════════════════════════════════════════════════
// State
// ═══════════════════════════════════════════════════════════════

class SalesState {
  final List<CartItem> items;
  final int discountTiyin;
  final List<Map<String, dynamic>> searchResults;
  final bool isSearching;
  final bool isProcessingPayment;
  final String? error;
  final String? saleSuccess;
  final List<Map<String, dynamic>> nktResults;
  final bool isNktSearching;
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
    this.isSearching = false,
    this.isProcessingPayment = false,
    this.error,
    this.saleSuccess,
    this.nktResults = const [],
    this.isNktSearching = false,
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
    bool? isSearching,
    bool? isProcessingPayment,
    String? error,
    String? saleSuccess,
    bool clearSaleSuccess = false,
    bool clearError = false,
    List<Map<String, dynamic>>? nktResults,
    bool? isNktSearching,
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
      isSearching: isSearching ?? this.isSearching,
      isProcessingPayment: isProcessingPayment ?? this.isProcessingPayment,
      error: clearError ? null : (error ?? this.error),
      saleSuccess: clearSaleSuccess ? null : (saleSuccess ?? this.saleSuccess),
      nktResults: clearNkt ? const [] : (nktResults ?? this.nktResults),
      isNktSearching: isNktSearching ?? this.isNktSearching,
      nktQuery: clearNkt ? null : (nktQuery ?? this.nktQuery),
      lastQuery: lastQuery ?? this.lastQuery,
      parkedCarts: parkedCarts ?? this.parkedCarts,
      undoItem: clearUndo ? null : (undoItem ?? this.undoItem),
      undoIndex: clearUndo ? null : (undoIndex ?? this.undoIndex),
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategoryFilter ? null : (selectedCategoryId ?? this.selectedCategoryId),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// BLoC
// ═══════════════════════════════════════════════════════════════

class SalesBloc extends Bloc<SalesEvent, SalesState> {
  final ApiClient _api;

  /// Optional sales-service. When provided, `CompleteSale` routes through the
  /// abstraction (which picks drift vs. legacy HTTP via the factory in
  /// `main.dart`). When null, the BLoC falls back to the direct `_api` call —
  /// keeps the existing bloc_test suite (which doesn't inject a service) working.
  final SalesService? _salesService;

  SalesBloc(this._api, {SalesService? salesService})
      : _salesService = salesService,
        super(const SalesState()) {
    on<AddToCart>(_onAdd);
    on<RemoveFromCart>(_onRemove);
    on<UpdateQuantity>(_onUpdateQty);
    on<UpdateWeight>(_onUpdateWeight);
    on<ApplyDiscount>(_onDiscount);
    on<ApplyItemDiscount>(_onItemDiscount);
    on<ClearCart>(_onClear);
    on<UndoLastAction>(_onUndo);
    on<ParkCart>(_onPark);
    on<ResumeParkedCart>(_onResume);
    on<DeleteParkedCart>(_onDeleteParked);
    on<SearchProduct>(_onSearch);
    on<ScanBarcode>(_onScan);
    on<CompleteSale>(_onCompleteSale);
    on<ClearNktResults>(_onClearNkt);
    on<ScaleWeightUpdate>(_onScaleWeight);
    on<LoadCategories>(_onLoadCategories);
    on<SelectCategory>(_onSelectCategory);
  }

  void _onAdd(AddToCart event, Emitter<SalesState> emit) {
    final items = List<CartItem>.from(state.items)..add(event.item);
    emit(state.copyWith(items: items, searchResults: [], clearError: true, clearSaleSuccess: true, clearNkt: true, clearUndo: true));
  }

  void _onRemove(RemoveFromCart event, Emitter<SalesState> emit) {
    if (event.index < 0 || event.index >= state.items.length) return;
    final removedItem = state.items[event.index];
    final items = List<CartItem>.from(state.items)..removeAt(event.index);
    emit(state.copyWith(
      items: items,
      undoItem: removedItem,
      undoIndex: event.index,
    ));
  }

  void _onUndo(UndoLastAction event, Emitter<SalesState> emit) {
    if (state.undoItem == null) return;
    final items = List<CartItem>.from(state.items);
    final insertIndex = (state.undoIndex ?? items.length).clamp(0, items.length);
    items.insert(insertIndex, state.undoItem!);
    emit(state.copyWith(items: items, clearUndo: true));
  }

  void _onPark(ParkCart event, Emitter<SalesState> emit) {
    if (state.items.isEmpty) return;
    final parked = ParkedCart(
      items: List.unmodifiable(state.items),
      discountTiyin: state.discountTiyin,
      parkedAt: DateTime.now(),
    );
    final parkedCarts = List<ParkedCart>.from(state.parkedCarts)..add(parked);
    emit(SalesState(parkedCarts: parkedCarts, categories: state.categories));
  }

  void _onResume(ResumeParkedCart event, Emitter<SalesState> emit) {
    if (event.index < 0 || event.index >= state.parkedCarts.length) return;
    final cart = state.parkedCarts[event.index];

    // If current cart is not empty, park it first
    List<ParkedCart> parkedCarts;
    if (state.items.isNotEmpty) {
      final currentParked = ParkedCart(
        items: List.unmodifiable(state.items),
        discountTiyin: state.discountTiyin,
        parkedAt: DateTime.now(),
      );
      parkedCarts = List<ParkedCart>.from(state.parkedCarts)
        ..removeAt(event.index)
        ..add(currentParked);
    } else {
      parkedCarts = List<ParkedCart>.from(state.parkedCarts)..removeAt(event.index);
    }

    emit(state.copyWith(
      items: List<CartItem>.from(cart.items),
      discountTiyin: cart.discountTiyin,
      parkedCarts: parkedCarts,
      clearUndo: true,
    ));
  }

  void _onDeleteParked(DeleteParkedCart event, Emitter<SalesState> emit) {
    if (event.index < 0 || event.index >= state.parkedCarts.length) return;
    final parkedCarts = List<ParkedCart>.from(state.parkedCarts)..removeAt(event.index);
    emit(state.copyWith(parkedCarts: parkedCarts));
  }

  void _onUpdateQty(UpdateQuantity event, Emitter<SalesState> emit) {
    final items = List<CartItem>.from(state.items);
    items[event.index] = items[event.index].copyWith(quantity: event.quantity);
    emit(state.copyWith(items: items));
  }

  void _onUpdateWeight(UpdateWeight event, Emitter<SalesState> emit) {
    final items = List<CartItem>.from(state.items);
    items[event.index] = items[event.index].copyWith(weightGrams: event.weightGrams);
    emit(state.copyWith(items: items));
  }

  void _onDiscount(ApplyDiscount event, Emitter<SalesState> emit) {
    emit(state.copyWith(discountTiyin: event.discountTiyin));
  }

  void _onItemDiscount(ApplyItemDiscount event, Emitter<SalesState> emit) {
    if (event.index < 0 || event.index >= state.items.length) return;
    final items = List<CartItem>.from(state.items);
    items[event.index] = items[event.index].copyWith(discount: event.discountTiyin);
    emit(state.copyWith(items: items));
  }

  void _onClear(ClearCart event, Emitter<SalesState> emit) {
    emit(SalesState(parkedCarts: state.parkedCarts, categories: state.categories));
  }

  void _onClearNkt(ClearNktResults event, Emitter<SalesState> emit) {
    emit(state.copyWith(clearNkt: true));
  }

  void _onScaleWeight(ScaleWeightUpdate event, Emitter<SalesState> emit) {
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
    updated[lastWeightedIdx] = updated[lastWeightedIdx].copyWith(weightGrams: event.weightGrams);
    emit(state.copyWith(items: updated));
  }

  /// Returns true if all characters are digits
  static bool _isAllDigits(String q) => q.isNotEmpty && q.codeUnits.every((c) => c >= 48 && c <= 57);

  /// Returns true if the query looks like a full barcode (8-14 digits)
  static bool _isBarcode(String q) => q.length >= 8 && q.length <= 14 && _isAllDigits(q);

  Future<void> _onLoadCategories(LoadCategories event, Emitter<SalesState> emit) async {
    try {
      final resp = await _api.listCategories();
      final cats = (resp['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      emit(state.copyWith(categories: cats));
    } on Exception catch (e) {
      debugPrint('[SalesBloc] loadCategories error: $e');
    }
  }

  void _onSelectCategory(SelectCategory event, Emitter<SalesState> emit) {
    if (event.categoryId == null) {
      emit(state.copyWith(clearCategoryFilter: true));
    } else {
      emit(state.copyWith(selectedCategoryId: event.categoryId));
    }
  }

  Future<void> _onSearch(SearchProduct event, Emitter<SalesState> emit) async {
    debugPrint('[SalesBloc] search query: "${event.query}"');
    if (event.query.isEmpty) {
      emit(state.copyWith(searchResults: [], isSearching: false, clearNkt: true, lastQuery: ''));
      return;
    }

    emit(state.copyWith(isSearching: true, clearNkt: true, lastQuery: event.query));
    try {
      final response = await _api.searchProducts(event.query);
      final products = (response['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      emit(state.copyWith(searchResults: products, isSearching: false));

      // If no local results and query looks like a barcode → auto-search NKT
      if (products.isEmpty && _isBarcode(event.query)) {
        emit(state.copyWith(isNktSearching: true, nktQuery: event.query));
        try {
          final nktResp = await _api.nktSearchByGTIN(event.query);
          final nktProducts = (nktResp['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          emit(state.copyWith(nktResults: nktProducts, isNktSearching: false));
        } on Exception catch (e) {
          debugPrint('[SalesBloc] NKT search error: $e');
          emit(state.copyWith(isNktSearching: false));
        }
      }
    } on Exception catch (e) {
      debugPrint('[SalesBloc] search error: $e');
      emit(state.copyWith(isSearching: false, error: 'Ошибка поиска'));
    }
  }

  Future<void> _onScan(ScanBarcode event, Emitter<SalesState> emit) async {
    try {
      final response = await _api.getProductByBarcode(event.barcode);
      final item = CartItem(
        productId: response['ID'] as String,
        name: response['Name'] as String,
        ntin: response['NTIN'] as String?,
        unit: response['SaleUnit'] as String,
        basePrice: (response['SalePrice'] as num).toInt(),
        isWeighted: response['IsWeighted'] as bool? ?? false,
        vatRate: (response['VATRate'] as num?)?.toInt() ?? 12,
      );
      add(AddToCart(item));
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        // Not found locally — try NKT
        emit(state.copyWith(isNktSearching: true, nktQuery: event.barcode));
        try {
          final nktResp = await _api.nktSearchByGTIN(event.barcode);
          final nktProducts = (nktResp['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          if (nktProducts.isNotEmpty) {
            emit(state.copyWith(nktResults: nktProducts, isNktSearching: false));
          } else {
            emit(state.copyWith(isNktSearching: false, error: 'Товар не найден ни локально, ни в НКТ'));
          }
        } on Exception catch (nktErr) {
          debugPrint('[SalesBloc] NKT fallback error: $nktErr');
          emit(state.copyWith(isNktSearching: false, error: 'Товар не найден'));
        }
      }
    } on Exception catch (_) {
      emit(state.copyWith(error: 'Ошибка сканирования'));
    }
  }

  Future<void> _onCompleteSale(CompleteSale event, Emitter<SalesState> emit) async {
    if (state.items.isEmpty) return;

    emit(state.copyWith(isProcessingPayment: true, clearError: true));

    try {
      // T5.5b: when a SalesService is injected (production path), route through
      // the abstraction — the factory in main.dart picks drift-vs-HTTP via
      // FeatureFlags.useDriftSales. When null (legacy tests / builds without
      // an auth'd session), fall back to the direct Go-server call with the
      // same PascalCase wire shape the server has always accepted.
      if (_salesService case final svc?) {
        final lines = <SalesLineInput>[];
        for (final ci in state.items) {
          // CartItem.quantity is double because piece-input shares a field with
          // weighted-input-in-kg; for the receipt wire shape we split: pieces go
          // to `quantity` (int), weighted goes to `weightGrams`.
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
          shiftId: event.shiftId,
          cashierId: event.cashierId,
          paymentType: event.paymentType,
          lines: lines,
          subtotalTiyin: state.subtotal,
          discountTiyin: state.discountTiyin,
          totalTiyin: state.total,
          vatAmountTiyin: state.vatAmount,
          cashAmountTiyin: event.cashAmount,
          cardAmountTiyin: event.cardAmount,
          qrAmountTiyin: event.qrAmount,
          changeAmountTiyin: event.changeAmount,
          overrideByUserId: event.overrideUserId,
        ));
      } else {
        final items = <Map<String, dynamic>>[];
        for (int i = 0; i < state.items.length; i++) {
          final ci = state.items[i];
          items.add({
            'ProductID': ci.productId,
            'Name': ci.name,
            'NTIN': ci.ntin ?? '',
            'Quantity': ci.isWeighted ? (ci.weightGrams / 1000.0) : ci.quantity,
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
          'ShiftID': event.shiftId,
          'CashierID': event.cashierId,
          'Subtotal': state.subtotal,
          'Discount': state.discountTiyin,
          'Total': state.total,
          'VATAmount': state.vatAmount,
          'PaymentType': event.paymentType,
          'CashAmount': event.cashAmount,
          'CardAmount': event.cardAmount,
          'QRAmount': event.qrAmount,
          'ChangeAmount': event.changeAmount,
          'FiscalStatus': 'pending',
          'Items': items,
        });
      }

      emit(SalesState(
        saleSuccess: 'Оплата принята!',
        parkedCarts: state.parkedCarts,
        categories: state.categories,
      ));
    } on ApiException catch (e) {
      debugPrint('[SalesBloc] completeSale API error: $e');
      final msg = switch (e.statusCode) {
        400 => 'Некорректные данные чека',
        404 => 'Смена не найдена',
        409 => 'Конфликт данных — повторите попытку',
        _ => 'Ошибка сервера (${e.statusCode})',
      };
      emit(state.copyWith(isProcessingPayment: false, error: msg));
    } on Exception catch (e) {
      debugPrint('[SalesBloc] completeSale error: $e');
      emit(state.copyWith(
        isProcessingPayment: false,
        error: 'Нет связи с сервером. Попробуйте ещё раз.',
      ));
    }
  }
}
