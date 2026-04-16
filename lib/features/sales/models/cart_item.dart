/// Позиция в текущем чеке (корзине) — immutable
class CartItem {
  final String productId;
  final String name;
  final String? ntin;
  final String unit;
  final int basePrice; // тиын (за шт или за кг)
  final bool isWeighted;
  final int vatRate;
  final double quantity; // штуки или кг
  final int weightGrams; // для весового товара
  final int discount; // скидка в тиын на позицию

  /// Available stock quantity (for UI warnings). -1 means unknown.
  final double stockQty;

  const CartItem({
    required this.productId,
    required this.name,
    this.ntin,
    required this.unit,
    required this.basePrice,
    this.isWeighted = false,
    this.vatRate = 12,
    this.quantity = 1,
    this.weightGrams = 0,
    this.discount = 0,
    this.stockQty = -1,
  });

  CartItem copyWith({
    String? productId,
    String? name,
    String? ntin,
    String? unit,
    int? basePrice,
    bool? isWeighted,
    int? vatRate,
    double? quantity,
    int? weightGrams,
    int? discount,
    double? stockQty,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      ntin: ntin ?? this.ntin,
      unit: unit ?? this.unit,
      basePrice: basePrice ?? this.basePrice,
      isWeighted: isWeighted ?? this.isWeighted,
      vatRate: vatRate ?? this.vatRate,
      quantity: quantity ?? this.quantity,
      weightGrams: weightGrams ?? this.weightGrams,
      discount: discount ?? this.discount,
      stockQty: stockQty ?? this.stockQty,
    );
  }

  /// Итого по позиции в тиынах
  int get total {
    int result;
    if (isWeighted) {
      // Весовой: (вес_г * цена_кг + 500) / 1000
      result = ((weightGrams * basePrice) + 500) ~/ 1000;
    } else {
      // Штучный: кол-во * цена
      result = (quantity * basePrice).round();
    }
    result -= discount;
    return result < 0 ? 0 : result;
  }

  /// Сумма НДС «изнутри»
  int get vatAmount {
    if (vatRate == 0) return 0;
    return ((total * vatRate) / (100 + vatRate)).round();
  }

  /// Цена за единицу для отображения
  int get displayPrice => basePrice;

  /// Whether quantity exceeds available stock
  bool get isOverStock => stockQty >= 0 && quantity > stockQty;
}
