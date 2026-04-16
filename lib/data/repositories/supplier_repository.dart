import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables/suppliers_table.dart';

/// Local-first supplier repository. Pattern matches [ProductRepository] /
/// [CategoryRepository] — every write atomic with an outbox append.
class SupplierRepository {
  SupplierRepository(this._db, {required String tenantId}) : _tenantId = tenantId;

  final AppDatabase _db;
  final String _tenantId;
  static const _uuid = Uuid();

  Stream<List<SupplierRow>> watchAll({String? storeId, bool includeInactive = false}) {
    return _buildBaseQuery(storeId: storeId, includeInactive: includeInactive).watch();
  }

  Future<List<SupplierRow>> all({String? storeId, bool includeInactive = false}) {
    return _buildBaseQuery(storeId: storeId, includeInactive: includeInactive).get();
  }

  Future<SupplierRow?> getById(String id) {
    final q = _db.select(_db.suppliersTable)
      ..where((s) => s.tenantId.equals(_tenantId) & s.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<String> create({
    String? id,
    String? storeId,
    required String name,
    String? phone,
    String? bin,
    String? notes,
  }) async {
    final newId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.suppliersTable).insert(
            SuppliersTableCompanion.insert(
              id: newId,
              tenantId: _tenantId,
              storeId: Value(storeId),
              name: name,
              phone: Value(phone),
              bin: Value(bin),
              notes: Value(notes),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'suppliers',
              op: 'insert',
              uuid: newId,
              payloadJson: jsonEncode({
                'id': newId,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'name': name,
                'phone': phone,
                'bin': bin,
                'notes': notes,
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
    String? phone,
    String? bin,
    String? notes,
    bool? isActive,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('supplier $id not found');
    }

    final updated = existing.copyWith(
      name: name ?? existing.name,
      phone: Value(phone ?? existing.phone),
      bin: Value(bin ?? existing.bin),
      notes: Value(notes ?? existing.notes),
      isActive: isActive ?? existing.isActive,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.update(_db.suppliersTable).replace(updated);
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'suppliers',
              op: 'update',
              uuid: id,
              payloadJson: jsonEncode({
                'id': id,
                'name': updated.name,
                'phone': updated.phone,
                'bin': updated.bin,
                'notes': updated.notes,
                'is_active': updated.isActive,
              }),
              createdAt: now,
            ),
          );
    });
  }

  SimpleSelectStatement<SuppliersTable, SupplierRow> _buildBaseQuery({
    String? storeId,
    bool includeInactive = false,
  }) {
    final q = _db.select(_db.suppliersTable)
      ..where((s) => s.tenantId.equals(_tenantId));
    if (storeId != null) {
      q.where((s) => s.storeId.isNull() | s.storeId.equals(storeId));
    }
    if (!includeInactive) {
      q.where((s) => s.isActive.equals(true));
    }
    q.orderBy([(s) => OrderingTerm.asc(s.name)]);
    return q;
  }
}
