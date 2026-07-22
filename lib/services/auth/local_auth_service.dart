import 'package:bcrypt/bcrypt.dart';

import '../../data/database.dart';
import '../../data/repositories/cashier_repository.dart';
import 'bcrypt_pin_verifier.dart';

/// Fully-local auth for standalone (автономный) mode: owner creation, cashier
/// listing and PIN verification against the drift `users` table — no server.
/// Linked registers keep using central auth; this service is only consulted
/// while no workstation binding exists.
///
/// Spec: pos-docs/specs/platform/03-device-linking.md (R1/R5).
class LocalAuthService {
  LocalAuthService(this._db);

  final AppDatabase _db;

  /// bcrypt cost 10 — matches central's PinHasher so a standalone-minted hash
  /// stays verifiable after the register links and the row syncs up.
  static const bcryptCost = 10;

  CashierRepository _repo(String tenantId) =>
      CashierRepository(_db, tenantId: tenantId);

  Future<bool> hasAnyUser(String tenantId) async {
    final rows = await _repo(tenantId).all(includeInactive: true);
    return rows.isNotEmpty;
  }

  /// Creates the standalone owner. PIN is hashed here (cost 10), the
  /// repository stores it opaquely.
  Future<String> createOwner({
    required String tenantId,
    required String storeId,
    required String name,
    required String pin,
  }) {
    final hash = BCrypt.hashpw(pin, BCrypt.gensalt(logRounds: bcryptCost));
    return _repo(tenantId).create(
      storeId: storeId,
      name: name,
      login: name.trim().toLowerCase(),
      pinHash: hash,
      role: 'owner',
    );
  }

  /// Active cashiers shaped like the central `listCashiers` response entries
  /// (`ID` / `Name` / `Role` PascalCase keys) so PinScreen renders them
  /// unchanged.
  Future<List<Map<String, dynamic>>> listCashiers(String tenantId) async {
    final rows = await _repo(tenantId).all();
    return [
      for (final r in rows)
        {'ID': r.id, 'Name': r.name, 'Role': r.role, 'Login': r.login},
    ];
  }

  /// Verifies a PIN for the cashier selected by display name (PinScreen's
  /// selection key). Returns the row on success, null on any mismatch.
  Future<UserRow?> verifyPinByName({
    required String tenantId,
    required String name,
    required String pin,
  }) async {
    final rows = await _repo(tenantId).all();
    for (final r in rows) {
      if (r.name != name) continue;
      final hash = r.pinHash;
      if (hash == null || hash.isEmpty) return null;
      return bcryptVerify(pin, hash) ? r : null;
    }
    return null;
  }

  /// Link-time adoption (spec 03 R2/R5 MVP): re-stamp every local row from the
  /// synthetic standalone tenant to the real one, and drop the accumulated
  /// outbox — sync is from-link-forward only; pre-link deltas reference the
  /// synthetic tenant and must never reach central.
  Future<void> adoptTenant({
    required String fromTenantId,
    required String toTenantId,
  }) async {
    // Keep in sync with lib/data/tables/ — every table carrying tenant_id.
    const tenantTables = [
      'users',
      'products',
      'categories',
      'clients',
      'receipts',
      'shifts',
      'settings',
      'stock_movements',
      'suppliers',
    ];
    await _db.transaction(() async {
      for (final table in tenantTables) {
        await _db.customStatement(
          'UPDATE $table SET tenant_id = ? WHERE tenant_id = ?',
          [toTenantId, fromTenantId],
        );
      }
      await _db.customStatement('DELETE FROM sync_outbox');
    });
  }

  /// Drops queued deltas that can never be delivered — used when the register
  /// is unlinked from the platform (spec 03 R5). Business data is untouched:
  /// receipts, stock and settings all stay on the device. Re-linking later
  /// syncs from that point forward, exactly like a first link.
  Future<void> clearOutbox() async {
    await _db.customStatement('DELETE FROM sync_outbox');
  }
}
