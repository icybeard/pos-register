import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database.dart';

/// Local-first cashier repository. Mirror of [SettingsRepository] — every write
/// goes to `users` table AND `sync_outbox` atomically in one drift transaction.
///
/// Writes accept a pre-hashed PIN (bcrypt) — hashing lives in the caller / service
/// layer, NOT in the repository. Keeps this class free of crypto deps and lets
/// tests use cheap hash stubs.
class CashierRepository {
  CashierRepository(this._db, {required String tenantId}) : _tenantId = tenantId;

  final AppDatabase _db;
  final String _tenantId;
  static const _uuid = Uuid();

  /// Reactive stream of all cashiers for the current tenant, optionally
  /// restricted to one store. Inactive rows are included — UI decides whether to filter.
  Stream<List<UserRow>> watchAll({String? storeId, bool includeInactive = false}) {
    final q = _db.select(_db.usersTable)
      ..where((u) => u.tenantId.equals(_tenantId));
    if (storeId != null) {
      q.where((u) => u.storeId.equals(storeId));
    }
    if (!includeInactive) {
      q.where((u) => u.isActive.equals(true));
    }
    q.orderBy([(u) => OrderingTerm.asc(u.name)]);
    return q.watch();
  }

  Future<List<UserRow>> all({String? storeId, bool includeInactive = false}) async {
    final q = _db.select(_db.usersTable)
      ..where((u) => u.tenantId.equals(_tenantId));
    if (storeId != null) {
      q.where((u) => u.storeId.equals(storeId));
    }
    if (!includeInactive) {
      q.where((u) => u.isActive.equals(true));
    }
    q.orderBy([(u) => OrderingTerm.asc(u.name)]);
    return q.get();
  }

  Future<UserRow?> getById(String id) async {
    final q = _db.select(_db.usersTable)
      ..where((u) => u.tenantId.equals(_tenantId) & u.id.equals(id));
    return q.getSingleOrNull();
  }

  /// Find a cashier by their login string (case-normalised by the caller).
  /// Used by the offline cashier-login path — verifies PIN against the local
  /// `pin_hash` when central is unreachable.
  Future<UserRow?> findByLogin(String login) async {
    final q = _db.select(_db.usersTable)
      ..where((u) => u.tenantId.equals(_tenantId) & u.login.equals(login));
    return q.getSingleOrNull();
  }

  /// Insert a new cashier (locally) and enqueue the sync op. Caller supplies the
  /// bcrypt `pinHash`. If `id` is null a UUID is generated.
  Future<String> create({
    String? id,
    required String storeId,
    required String name,
    required String login,
    required String pinHash,
    required String role,
    bool isActive = true,
  }) async {
    final newId = id ?? _uuid.v4();
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await _db.into(_db.usersTable).insert(
            UsersTableCompanion.insert(
              id: newId,
              tenantId: _tenantId,
              storeId: Value(storeId),
              name: name,
              login: Value(login),
              pinHash: Value(pinHash),
              role: role,
              isActive: Value(isActive),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'users',
              op: 'insert',
              uuid: newId,
              payloadJson: jsonEncode({
                'id': newId,
                'tenant_id': _tenantId,
                'store_id': storeId,
                'name': name,
                'login': login,
                'role': role,
                'is_active': isActive,
              }),
              createdAt: now,
            ),
          );
    });
    return newId;
  }

  /// Update mutable fields (name/login/role/store/is_active). PIN is rotated via
  /// [resetPinHash]. The repository only writes local state + outbox — it does NOT
  /// revoke refresh tokens (central does that on sync).
  Future<void> update({
    required String id,
    String? name,
    String? login,
    String? role,
    String? storeId,
    bool? isActive,
  }) async {
    final now = DateTime.now().toUtc();
    final existing = await getById(id);
    if (existing == null) {
      throw StateError('cashier $id not found');
    }

    final updated = existing.copyWith(
      name: name ?? existing.name,
      login: Value(login ?? existing.login),
      role: role ?? existing.role,
      storeId: Value(storeId ?? existing.storeId),
      isActive: isActive ?? existing.isActive,
      updatedAt: now,
    );

    await _db.transaction(() async {
      await _db.update(_db.usersTable).replace(updated);
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'users',
              op: 'update',
              uuid: id,
              payloadJson: jsonEncode({
                'id': id,
                'name': updated.name,
                'login': updated.login,
                'role': updated.role,
                'store_id': updated.storeId,
                'is_active': updated.isActive,
              }),
              createdAt: now,
            ),
          );
    });
  }

  /// Rotate the stored PIN hash. Caller supplies the bcrypt hash.
  Future<void> resetPinHash(String id, String newPinHash) async {
    final now = DateTime.now().toUtc();
    await _db.transaction(() async {
      await (_db.update(_db.usersTable)..where((u) => u.id.equals(id)))
          .write(UsersTableCompanion(
        pinHash: Value(newPinHash),
        updatedAt: Value(now),
      ));
      await _db.into(_db.syncOutboxTable).insert(
            SyncOutboxTableCompanion.insert(
              targetTable: 'users',
              op: 'update',
              uuid: id,
              payloadJson: jsonEncode({
                'id': id,
                'pin_hash_rotated': true,
              }),
              createdAt: now,
            ),
          );
    });
  }
}
