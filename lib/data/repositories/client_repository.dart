import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';
import '../tables/clients_table.dart';

/// Local-first client (customer / debtor) repository. Mirror of
/// [SupplierRepository] — same atomic-outbox pattern. `debtLimitTiyin` is
/// optional; null means no per-client debt cap.
class ClientRepository {
  ClientRepository(this._db, {required String tenantId}) : _tenantId = tenantId;

  final AppDatabase _db;
  final String _tenantId;
  static const _uuid = Uuid();

  Stream<List<ClientRow>> watchAll({String? storeId, bool includeInactive = false}) {
    return _buildBaseQuery(storeId: storeId, includeInactive: includeInactive).watch();
  }

  Future<List<ClientRow>> all({String? storeId, bool includeInactive = false}) {
    return _buildBaseQuery(storeId: storeId, includeInactive: includeInactive).get();
  }

  Future<ClientRow?> getById(String id) {
    final q = _db.select(_db.clientsTable)
      ..where((c) => c.tenantId.equals(_tenantId) & c.id.equals(id));
    return q.getSingleOrNull();
  }

  Future<String> create({
    String? id,
    String? storeId,
    required String name,
    String? phone,
    String? iin,
    String? notes,
    int? debtLimitTiyin,
  }) async {
    final newId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.clientsTable).insert(
            ClientsTableCompanion.insert(
              id: newId,
              tenantId: _tenantId,
              storeId: Value(storeId),
              name: name,
              phone: Value(phone),
              iin: Value(iin),
              notes: Value(notes),
              debtLimitTiyin: Value(debtLimitTiyin),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'clients',
              op: 'insert',
              uuid: newId,
              payloadJson: jsonEncode({
                'id': newId,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'name': name,
                'phone': phone,
                'iin': iin,
                'notes': notes,
                'debt_limit_tiyin': debtLimitTiyin,
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
    String? iin,
    String? notes,
    int? debtLimitTiyin,
    bool? isActive,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('client $id not found');
    }

    final updated = existing.copyWith(
      name: name ?? existing.name,
      phone: Value(phone ?? existing.phone),
      iin: Value(iin ?? existing.iin),
      notes: Value(notes ?? existing.notes),
      debtLimitTiyin: Value(debtLimitTiyin ?? existing.debtLimitTiyin),
      isActive: isActive ?? existing.isActive,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.update(_db.clientsTable).replace(updated);
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'clients',
              op: 'update',
              uuid: id,
              payloadJson: jsonEncode({
                'id': id,
                'name': updated.name,
                'phone': updated.phone,
                'iin': updated.iin,
                'notes': updated.notes,
                'debt_limit_tiyin': updated.debtLimitTiyin,
                'is_active': updated.isActive,
              }),
              createdAt: now,
            ),
          );
    });
  }

  SimpleSelectStatement<ClientsTable, ClientRow> _buildBaseQuery({
    String? storeId,
    bool includeInactive = false,
  }) {
    final q = _db.select(_db.clientsTable)
      ..where((c) => c.tenantId.equals(_tenantId));
    if (storeId != null) {
      q.where((c) => c.storeId.isNull() | c.storeId.equals(storeId));
    }
    if (!includeInactive) {
      q.where((c) => c.isActive.equals(true));
    }
    q.orderBy([(c) => OrderingTerm.asc(c.name)]);
    return q;
  }
}
