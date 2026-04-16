import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables/products_table.dart';

/// Local-first catalog repository. Cashier-side reads are always local (drift) —
/// no HTTP in the hot path. Writes (admin editing from the register or offline
/// price changes) go through the outbox atomically.
///
/// **Money in tiyin** (long). Caller converts tenge↔tiyin at the UI boundary.
class ProductRepository {
  ProductRepository(this._db, {required String tenantId}) : _tenantId = tenantId;

  final AppDatabase _db;
  final String _tenantId;
  static const _uuid = Uuid();

  /// Reactive stream of products for the current tenant, optionally store-scoped.
  /// `storeId == null` = tenant-wide items only. `storeId = <id>` = items assigned
  /// to that store PLUS tenant-wide (store_id IS NULL) items, mirroring the
  /// .NET ListProductsQuery rule.
  Stream<List<ProductRow>> watchAll({String? storeId, bool includeInactive = false}) {
    final q = _buildBaseQuery(storeId: storeId, includeInactive: includeInactive);
    return q.watch();
  }

  Future<List<ProductRow>> all({String? storeId, bool includeInactive = false}) {
    return _buildBaseQuery(storeId: storeId, includeInactive: includeInactive).get();
  }

  Future<ProductRow?> getById(String id) {
    final q = _db.select(_db.productsTable)
      ..where((p) => p.tenantId.equals(_tenantId) & p.id.equals(id));
    return q.getSingleOrNull();
  }

  /// Barcode lookup for the scanner. Returns null if unknown. Does NOT apply
  /// `is_active` filter — cashier might scan a just-deactivated item and the
  /// UI should show "inactive" rather than "unknown barcode".
  Future<ProductRow?> findByBarcode(String barcode) {
    final q = _db.select(_db.productsTable)
      ..where((p) => p.tenantId.equals(_tenantId) & p.barcodeGtin.equals(barcode));
    return q.getSingleOrNull();
  }

  Future<String> create({
    String? id,
    String? storeId,
    required String name,
    String? nameKz,
    String? barcodeGtin,
    String? ntin,
    String? xtin,
    String? categoryId,
    String purchaseUnit = 'pcs',
    required int purchasePriceTiyin,
    String saleUnit = 'pcs',
    required int salePriceTiyin,
    bool isWeighted = false,
    int? minWeightGrams,
    int weightStepGrams = 1,
    int vatRate = 12,
  }) async {
    final newId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.productsTable).insert(
            ProductsTableCompanion.insert(
              id: newId,
              tenantId: _tenantId,
              storeId: Value(storeId),
              name: name,
              nameKz: Value(nameKz),
              barcodeGtin: Value(barcodeGtin),
              ntin: Value(ntin),
              xtin: Value(xtin),
              categoryId: Value(categoryId),
              purchaseUnit: purchaseUnit,
              purchasePriceTiyin: purchasePriceTiyin,
              saleUnit: saleUnit,
              salePriceTiyin: salePriceTiyin,
              isWeighted: Value(isWeighted),
              minWeightGrams: Value(minWeightGrams),
              weightStepGrams: Value(weightStepGrams),
              vatRate: Value(vatRate),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'products',
              op: 'insert',
              uuid: newId,
              payloadJson: jsonEncode({
                'id': newId,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'name': name,
                'name_kz': nameKz,
                'barcode_gtin': barcodeGtin,
                'ntin': ntin,
                'xtin': xtin,
                'category_id': categoryId,
                'purchase_unit': purchaseUnit,
                'purchase_price_tiyin': purchasePriceTiyin,
                'sale_unit': saleUnit,
                'sale_price_tiyin': salePriceTiyin,
                'is_weighted': isWeighted,
                'min_weight_grams': minWeightGrams,
                'weight_step_grams': weightStepGrams,
                'vat_rate': vatRate,
              }),
              createdAt: now,
            ),
          );
    });
    return newId;
  }

  /// Update mutable fields. Fields left null stay unchanged. Soft-delete via `isActive: false`.
  Future<void> update({
    required String id,
    String? name,
    String? nameKz,
    String? barcodeGtin,
    String? categoryId,
    int? purchasePriceTiyin,
    int? salePriceTiyin,
    int? vatRate,
    bool? isWeighted,
    int? minWeightGrams,
    int? weightStepGrams,
    bool? isActive,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('product $id not found');
    }

    final updated = existing.copyWith(
      name: name ?? existing.name,
      nameKz: Value(nameKz ?? existing.nameKz),
      barcodeGtin: Value(barcodeGtin ?? existing.barcodeGtin),
      categoryId: Value(categoryId ?? existing.categoryId),
      purchasePriceTiyin: purchasePriceTiyin ?? existing.purchasePriceTiyin,
      salePriceTiyin: salePriceTiyin ?? existing.salePriceTiyin,
      vatRate: vatRate ?? existing.vatRate,
      isWeighted: isWeighted ?? existing.isWeighted,
      minWeightGrams: Value(minWeightGrams ?? existing.minWeightGrams),
      weightStepGrams: weightStepGrams ?? existing.weightStepGrams,
      isActive: isActive ?? existing.isActive,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.update(_db.productsTable).replace(updated);
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'products',
              op: 'update',
              uuid: id,
              payloadJson: jsonEncode({
                'id': id,
                'name': updated.name,
                'name_kz': updated.nameKz,
                'barcode_gtin': updated.barcodeGtin,
                'category_id': updated.categoryId,
                'purchase_price_tiyin': updated.purchasePriceTiyin,
                'sale_price_tiyin': updated.salePriceTiyin,
                'vat_rate': updated.vatRate,
                'is_weighted': updated.isWeighted,
                'min_weight_grams': updated.minWeightGrams,
                'weight_step_grams': updated.weightStepGrams,
                'is_active': updated.isActive,
              }),
              createdAt: now,
            ),
          );
    });
  }

  SimpleSelectStatement<ProductsTable, ProductRow> _buildBaseQuery({
    String? storeId,
    bool includeInactive = false,
  }) {
    final q = _db.select(_db.productsTable)
      ..where((p) => p.tenantId.equals(_tenantId));
    if (storeId != null) {
      q.where((p) => p.storeId.isNull() | p.storeId.equals(storeId));
    }
    if (!includeInactive) {
      q.where((p) => p.isActive.equals(true));
    }
    q.orderBy([(p) => OrderingTerm.asc(p.name)]);
    return q;
  }
}
