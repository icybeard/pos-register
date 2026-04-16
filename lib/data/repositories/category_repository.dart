import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables/categories_table.dart';

/// Local-first category repository. Same pattern as [ProductRepository] —
/// every write is atomic with an outbox append. Categories are tenant-wide or
/// store-scoped; the cashier UI reads them grouped by `sort_order` then `name`.
class CategoryRepository {
  CategoryRepository(this._db, {required String tenantId}) : _tenantId = tenantId;

  final AppDatabase _db;
  final String _tenantId;
  static const _uuid = Uuid();

  Stream<List<CategoryRow>> watchAll({String? storeId, bool includeInactive = false}) {
    return _buildBaseQuery(storeId: storeId, includeInactive: includeInactive).watch();
  }

  Future<List<CategoryRow>> all({String? storeId, bool includeInactive = false}) {
    return _buildBaseQuery(storeId: storeId, includeInactive: includeInactive).get();
  }

  Future<CategoryRow?> getById(String id) {
    final q = _db.select(_db.categoriesTable)
      ..where((c) => c.tenantId.equals(_tenantId) & c.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<String> create({
    String? id,
    String? storeId,
    required String name,
    String? nameKz,
    String? parentId,
    String? oktruCode,
    int sortOrder = 0,
  }) async {
    final newId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.categoriesTable).insert(
            CategoriesTableCompanion.insert(
              id: newId,
              tenantId: _tenantId,
              storeId: Value(storeId),
              name: name,
              nameKz: Value(nameKz),
              parentId: Value(parentId),
              oktruCode: Value(oktruCode),
              sortOrder: Value(sortOrder),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'categories',
              op: 'insert',
              uuid: newId,
              payloadJson: jsonEncode({
                'id': newId,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'name': name,
                'name_kz': nameKz,
                'parent_id': parentId,
                'oktru_code': oktruCode,
                'sort_order': sortOrder,
              }),
              createdAt: now,
            ),
          );
    });
    return newId;
  }

  Future<void> update({
    required String id,
    String? name,
    String? nameKz,
    String? parentId,
    String? oktruCode,
    int? sortOrder,
    bool? isActive,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('category $id not found');
    }

    final updated = existing.copyWith(
      name: name ?? existing.name,
      nameKz: Value(nameKz ?? existing.nameKz),
      parentId: Value(parentId ?? existing.parentId),
      oktruCode: Value(oktruCode ?? existing.oktruCode),
      sortOrder: sortOrder ?? existing.sortOrder,
      isActive: isActive ?? existing.isActive,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.update(_db.categoriesTable).replace(updated);
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'categories',
              op: 'update',
              uuid: id,
              payloadJson: jsonEncode({
                'id': id,
                'name': updated.name,
                'name_kz': updated.nameKz,
                'parent_id': updated.parentId,
                'oktru_code': updated.oktruCode,
                'sort_order': updated.sortOrder,
                'is_active': updated.isActive,
              }),
              createdAt: now,
            ),
          );
    });
  }

  SimpleSelectStatement<CategoriesTable, CategoryRow> _buildBaseQuery({
    String? storeId,
    bool includeInactive = false,
  }) {
    final q = _db.select(_db.categoriesTable)
      ..where((c) => c.tenantId.equals(_tenantId));
    if (storeId != null) {
      q.where((c) => c.storeId.isNull() | c.storeId.equals(storeId));
    }
    if (!includeInactive) {
      q.where((c) => c.isActive.equals(true));
    }
    q.orderBy([
      (c) => OrderingTerm.asc(c.sortOrder),
      (c) => OrderingTerm.asc(c.name),
    ]);
    return q;
  }
}
