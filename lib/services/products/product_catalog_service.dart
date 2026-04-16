import '../../core/feature_flags.dart';
import '../../data/database.dart';
import '../../data/repositories/product_repository.dart';
import '../api_client.dart';

/// Common shape consumed by widgets, regardless of where the catalog comes from.
///
/// Money in tiyin (long). Translates the legacy Go-server's PascalCase rows
/// (`ID`, `Name`, `SalePrice`, `BarcodeGTIN`, `IsWeighted`, `VATRate`) and the
/// new drift `ProductRow` into one canonical wire shape so screens are
/// data-source agnostic.
class ProductCatalogEntry {
  const ProductCatalogEntry({
    required this.id,
    required this.name,
    this.nameKz,
    this.barcodeGtin,
    this.ntin,
    required this.salePriceTiyin,
    required this.saleUnit,
    required this.isWeighted,
    required this.vatRate,
    required this.isActive,
  });

  final String id;
  final String name;
  final String? nameKz;
  final String? barcodeGtin;
  final String? ntin;
  final int salePriceTiyin;
  final String saleUnit; // pcs|kg|...
  final bool isWeighted;
  final int vatRate; // 0 or 12
  final bool isActive;
}

/// Read interface for the cashier register's catalog. The store-scoped read is
/// the hot path (every cart-add hits this); barcode lookup is the scanner path.
///
/// Per the FeatureFlags rule, screens must NOT branch on `useDriftProducts` —
/// they consume this interface and the factory below picks the implementation.
abstract interface class ProductCatalogService {
  /// Returns active products for the active store (plus tenant-wide items when
  /// applicable in the drift impl). Screens render this list directly; sort
  /// order is name-ascending (matches both the Go server and ProductRepository).
  Future<List<ProductCatalogEntry>> list({
    String? storeId,
    bool includeInactive = false,
  });

  /// Scanner hot path. Returns null when the barcode is unknown.
  /// Returns inactive products too, so the cashier UI can surface "this item is
  /// inactive" rather than "not found" — same contract as `ProductRepository`.
  Future<ProductCatalogEntry?> findByBarcode(String barcode);
}

/// Drift-backed implementation. Reads stay local and are reactive (the screen
/// can use `ProductRepository.watchAll` directly when it wants live updates;
/// this service is for one-shot fetches).
class DriftProductCatalogService implements ProductCatalogService {
  DriftProductCatalogService(this._repo);

  final ProductRepository _repo;

  @override
  Future<List<ProductCatalogEntry>> list({String? storeId, bool includeInactive = false}) async {
    final rows = await _repo.all(storeId: storeId, includeInactive: includeInactive);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<ProductCatalogEntry?> findByBarcode(String barcode) async {
    final row = await _repo.findByBarcode(barcode);
    return row == null ? null : _fromRow(row);
  }

  static ProductCatalogEntry _fromRow(ProductRow r) => ProductCatalogEntry(
        id: r.id,
        name: r.name,
        nameKz: r.nameKz,
        barcodeGtin: r.barcodeGtin,
        ntin: r.ntin,
        salePriceTiyin: r.salePriceTiyin,
        saleUnit: r.saleUnit,
        isWeighted: r.isWeighted,
        vatRate: r.vatRate,
        isActive: r.isActive,
      );
}

/// Legacy HTTP path — wraps the existing Go-server [ApiClient] so the screen
/// can stay on it while we bake the drift path. PascalCase Go keys (`ID`,
/// `Name`, `SalePrice`, `BarcodeGTIN`, `NameKZ`, `IsWeighted`, `VATRate`,
/// `SaleUnit`, `IsActive`, `NTIN`) are normalised to the canonical entry shape.
///
/// Removed at P9 cutover when Go is deleted.
class LegacyApiProductCatalogService implements ProductCatalogService {
  LegacyApiProductCatalogService(this._api);

  final ApiClient _api;

  @override
  Future<List<ProductCatalogEntry>> list({String? storeId, bool includeInactive = false}) async {
    // The Go server doesn't accept store_id or include_inactive on this endpoint —
    // returns the unfiltered tenant catalog. We filter is_active in Dart so the
    // contract matches the drift impl.
    final resp = await _api.listProducts();
    final raw = (resp['products'] as List?) ?? const [];
    final entries = raw
        .cast<Map<String, dynamic>>()
        .map(_fromLegacyRow)
        .toList();
    if (!includeInactive) {
      return entries.where((e) => e.isActive).toList();
    }
    return entries;
  }

  @override
  Future<ProductCatalogEntry?> findByBarcode(String barcode) async {
    try {
      final raw = await _api.getProductByBarcode(barcode);
      // Server returns {} or a 404-shaped body when not found — we normalise to null.
      if (raw.isEmpty || raw['ID'] == null) return null;
      return _fromLegacyRow(raw);
    } on Object {
      // Network or 404 — treat as miss. Caller decides what to render.
      return null;
    }
  }

  static ProductCatalogEntry _fromLegacyRow(Map<String, dynamic> r) => ProductCatalogEntry(
        id: (r['ID'] ?? r['id']) as String,
        name: (r['Name'] ?? r['name'] ?? '') as String,
        nameKz: r['NameKZ'] as String? ?? r['name_kz'] as String?,
        barcodeGtin: r['BarcodeGTIN'] as String? ?? r['barcode_gtin'] as String?,
        ntin: r['NTIN'] as String? ?? r['ntin'] as String?,
        salePriceTiyin: _asInt(r['SalePrice'] ?? r['sale_price'] ?? r['sale_price_tiyin']) ?? 0,
        saleUnit: (r['SaleUnit'] ?? r['sale_unit'] ?? 'pcs') as String,
        isWeighted: (r['IsWeighted'] ?? r['is_weighted'] ?? false) as bool,
        vatRate: _asInt(r['VATRate'] ?? r['vat_rate']) ?? 12,
        isActive: (r['IsActive'] ?? r['is_active'] ?? true) as bool,
      );

  static int? _asInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

/// Factory: pick the implementation based on the [FeatureFlags.useDriftProducts]
/// flag. Constructed once at app boot and injected into screens (via DI / IoC of
/// choice) so the swap is a one-line config change, not a UI refactor.
ProductCatalogService createProductCatalogService({
  required FeatureFlags flags,
  required AppDatabase db,
  required String tenantId,
  required ApiClient api,
}) {
  if (flags.useDriftProducts) {
    return DriftProductCatalogService(ProductRepository(db, tenantId: tenantId));
  }
  return LegacyApiProductCatalogService(api);
}
