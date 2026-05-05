import '../../../core/utils/money.dart';

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

  /// Итого по позиции в тиынах. Делегируется в [Money.calculateItemTotal] —
  /// тот же путь использует .NET `Calculator.ItemTotal` и Go-сервер,
  /// поэтому in-memory корзина и записанный чек дают тот же результат
  /// до тиыны (см. test/calculator_parity_test.dart).
  ///
  /// Для штучных товаров `quantity` всегда целое (кол-во штук), хранится
  /// как `double` только ради удобного сравнения со `stockQty`. Преобразуем
  /// через `.toInt()` — никаких float-операций над деньгами.
  int get total => Money.calculateItemTotal(
        isWeighted: isWeighted,
        basePriceTiyin: basePrice,
        quantity: isWeighted ? 0 : quantity.toInt(),
        weightGrams: weightGrams,
        discountTiyin: discount,
      );

  /// Сумма НДС «изнутри». Делегируется в [Money.calculateVat],
  /// которое выполняет truncating integer division — байт-в-байт
  /// совпадает с .NET `Calculator.VatFromInside`.
  int get vatAmount => Money.calculateVat(total, vatRate);

  /// Цена за единицу для отображения
  int get displayPrice => basePrice;

  /// Whether quantity exceeds available stock
  bool get isOverStock => stockQty >= 0 && quantity > stockQty;

  // Value equality so SalesState's `items` list comparison via Equatable
  // short-circuits when the cart contents are unchanged. Without this,
  // copyWith() with the same list creates new identity references and
  // every BlocBuilder rebuilds. All fields contribute — `stockQty` too,
  // because a stock-freshness pull that updates the warning level should
  // re-render the row.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItem &&
        other.productId == productId &&
        other.name == name &&
        other.ntin == ntin &&
        other.unit == unit &&
        other.basePrice == basePrice &&
        other.isWeighted == isWeighted &&
        other.vatRate == vatRate &&
        other.quantity == quantity &&
        other.weightGrams == weightGrams &&
        other.discount == discount &&
        other.stockQty == stockQty;
  }

  @override
  int get hashCode => Object.hash(
        productId, name, ntin, unit, basePrice, isWeighted, vatRate,
        quantity, weightGrams, discount, stockQty,
      );
}
