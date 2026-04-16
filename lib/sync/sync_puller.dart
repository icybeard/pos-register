import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';

import '../data/database.dart';
import '../services/central_client.dart';

/// Remote-change applier: mirror of [SyncWorker] for the pull direction.
///
/// For each watched table, reads the cursor from `sync_cursors`, calls
/// `GET /api/sync/pull?tables=...&since=<cursor>&limit=500`, upserts each entry
/// into its drift table (WITHOUT writing to `sync_outbox` — these are remote-origin),
/// advances the cursor, and loops until `has_more == false`.
///
/// Per-table dispatch lives in [_apply]. Add a case when a new drift table ships.
class SyncPuller {
  SyncPuller({
    required AppDatabase db,
    required CentralClient client,
    required String tenantId,
  })  : _db = db,
        _client = client,
        _tenantId = tenantId;

  final AppDatabase _db;
  final CentralClient _client;
  final String _tenantId;

  bool _pulling = false;

  /// Tables whose remote changes we care about on this register. Widen this list as
  /// new drift tables ship. P2.v1 added settings + users; P4 adds the master-catalog
  /// tables (products, categories, suppliers, clients).
  static const watchedTables = <String>[
    'settings',
    'users',
    'products',
    'categories',
    'suppliers',
    'clients',
  ];

  /// Run one pull cycle: for each watched table group fetch-until-drained, apply, advance cursor.
  /// Bounded concurrency — returns [SyncPullResult.busy] if another pull is in flight.
  Future<SyncPullResult> pullOnce({int limit = 500}) async {
    if (_pulling) {
      return const SyncPullResult.busy();
    }
    _pulling = true;
    try {
      var appliedTotal = 0;
      String? cursor = await _readCursor(_sharedCursorKey);

      for (;;) {
        final query = <String, dynamic>{
          'tables': watchedTables.join(','),
          'limit': limit,
        };
        if (cursor != null && cursor.isNotEmpty) {
          query['since'] = cursor;
        }

        final Response<Map<String, dynamic>> resp;
        try {
          resp = await _client.get<Map<String, dynamic>>('/api/sync/pull', query: query);
        } on DioException catch (e) {
          return SyncPullResult.transient(e.message ?? 'network error');
        } on Object catch (e) {
          return SyncPullResult.transient(e.toString());
        }

        final body = resp.data ?? const {};
        final entries = ((body['entries'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        final nextCursor = body['next_cursor'] as String?;
        final hasMore = (body['has_more'] as bool?) ?? false;

        await _db.transaction(() async {
          for (final e in entries) {
            await _apply(e);
          }
          if (nextCursor != null && nextCursor.isNotEmpty) {
            await _writeCursor(_sharedCursorKey, nextCursor);
          }
        });

        appliedTotal += entries.length;
        cursor = nextCursor;
        if (!hasMore || entries.isEmpty) {
          break;
        }
      }

      return SyncPullResult(applied: appliedTotal);
    } finally {
      _pulling = false;
    }
  }

  /// Dispatch one entry to the appropriate drift upsert path.
  /// Unknown tables are silently ignored (central may push tables we don't track yet).
  Future<void> _apply(Map<String, dynamic> entry) async {
    final table = entry['table'] as String?;
    final op = entry['op'] as String? ?? 'update';
    final payloadJson = entry['payload_json'] as String?;
    if (table == null || payloadJson == null) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(payloadJson) as Map<String, dynamic>;
    } on FormatException {
      return; // skip malformed payload — server's problem, not ours
    }

    switch (table) {
      case 'settings':
        await _applySetting(op, payload);
        break;
      case 'users':
        await _applyUser(op, payload);
        break;
      case 'products':
        await _applyProduct(op, payload);
        break;
      case 'categories':
        await _applyCategory(op, payload);
        break;
      case 'suppliers':
        await _applySupplier(op, payload);
        break;
      case 'clients':
        await _applyClient(op, payload);
        break;
      default:
        // Table not yet tracked locally — skip. This is normal during the gradual
        // screen-by-screen drift rollout.
        return;
    }
  }

  Future<void> _applySetting(String op, Map<String, dynamic> p) async {
    final key = p['key'] as String?;
    if (key == null) return;
    if (op == 'delete') {
      await (_db.delete(_db.settingsTable)
            ..where((t) => t.tenantId.equals(_tenantId) & t.key.equals(key)))
          .go();
      return;
    }
    final value = (p['value'] as String?) ?? '';
    await _db.into(_db.settingsTable).insertOnConflictUpdate(
          SettingsTableCompanion.insert(
            tenantId: _tenantId,
            key: key,
            value: value,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> _applyUser(String op, Map<String, dynamic> p) async {
    final id = p['id'] as String?;
    if (id == null) return;
    if (op == 'delete') {
      // Central sync sends is_active=false on delete; keep the local row so references stay valid.
      await (_db.update(_db.usersTable)..where((u) => u.id.equals(id)))
          .write(UsersTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
      return;
    }
    await _db.into(_db.usersTable).insertOnConflictUpdate(
          UsersTableCompanion.insert(
            id: id,
            tenantId: _tenantId,
            storeId: Value(p['store_id'] as String?),
            name: (p['name'] as String?) ?? '',
            login: Value(p['login'] as String?),
            pinHash: const Value.absent(),
            role: (p['role'] as String?) ?? 'cashier',
            isActive: Value((p['is_active'] as bool?) ?? true),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }

  Future<void> _applyProduct(String op, Map<String, dynamic> p) async {
    final id = p['id'] as String?;
    if (id == null) return;
    if (op == 'delete') {
      // Soft-delete locally so receipts still resolve the row.
      await (_db.update(_db.productsTable)..where((t) => t.id.equals(id)))
          .write(ProductsTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
      return;
    }
    final now = DateTime.now().toUtc();
    await _db.into(_db.productsTable).insertOnConflictUpdate(
          ProductsTableCompanion.insert(
            id: id,
            tenantId: _tenantId,
            storeId: Value(p['store_id'] as String?),
            name: (p['name'] as String?) ?? '',
            nameKz: Value(p['name_kz'] as String?),
            barcodeGtin: Value(p['barcode_gtin'] as String?),
            ntin: Value(p['ntin'] as String?),
            xtin: Value(p['xtin'] as String?),
            categoryId: Value(p['category_id'] as String?),
            purchaseUnit: (p['purchase_unit'] as String?) ?? 'pcs',
            purchasePriceTiyin: _asInt(p['purchase_price_tiyin']) ?? 0,
            saleUnit: (p['sale_unit'] as String?) ?? 'pcs',
            salePriceTiyin: _asInt(p['sale_price_tiyin']) ?? 0,
            isWeighted: Value((p['is_weighted'] as bool?) ?? false),
            minWeightGrams: Value(_asInt(p['min_weight_grams'])),
            weightStepGrams: Value(_asInt(p['weight_step_grams']) ?? 1),
            vatRate: Value(_asInt(p['vat_rate']) ?? 12),
            isActive: Value((p['is_active'] as bool?) ?? true),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _applyCategory(String op, Map<String, dynamic> p) async {
    final id = p['id'] as String?;
    if (id == null) return;
    if (op == 'delete') {
      await (_db.update(_db.categoriesTable)..where((t) => t.id.equals(id)))
          .write(CategoriesTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
      return;
    }
    final now = DateTime.now().toUtc();
    await _db.into(_db.categoriesTable).insertOnConflictUpdate(
          CategoriesTableCompanion.insert(
            id: id,
            tenantId: _tenantId,
            storeId: Value(p['store_id'] as String?),
            name: (p['name'] as String?) ?? '',
            nameKz: Value(p['name_kz'] as String?),
            parentId: Value(p['parent_id'] as String?),
            oktruCode: Value(p['oktru_code'] as String?),
            sortOrder: Value(_asInt(p['sort_order']) ?? 0),
            isActive: Value((p['is_active'] as bool?) ?? true),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _applySupplier(String op, Map<String, dynamic> p) async {
    final id = p['id'] as String?;
    if (id == null) return;
    if (op == 'delete') {
      await (_db.update(_db.suppliersTable)..where((t) => t.id.equals(id)))
          .write(SuppliersTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
      return;
    }
    final now = DateTime.now().toUtc();
    await _db.into(_db.suppliersTable).insertOnConflictUpdate(
          SuppliersTableCompanion.insert(
            id: id,
            tenantId: _tenantId,
            storeId: Value(p['store_id'] as String?),
            name: (p['name'] as String?) ?? '',
            phone: Value(p['phone'] as String?),
            bin: Value(p['bin'] as String?),
            notes: Value(p['notes'] as String?),
            isActive: Value((p['is_active'] as bool?) ?? true),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> _applyClient(String op, Map<String, dynamic> p) async {
    final id = p['id'] as String?;
    if (id == null) return;
    if (op == 'delete') {
      await (_db.update(_db.clientsTable)..where((t) => t.id.equals(id)))
          .write(ClientsTableCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ));
      return;
    }
    final now = DateTime.now().toUtc();
    await _db.into(_db.clientsTable).insertOnConflictUpdate(
          ClientsTableCompanion.insert(
            id: id,
            tenantId: _tenantId,
            storeId: Value(p['store_id'] as String?),
            name: (p['name'] as String?) ?? '',
            phone: Value(p['phone'] as String?),
            iin: Value(p['iin'] as String?),
            notes: Value(p['notes'] as String?),
            debtLimitTiyin: Value(_asInt(p['debt_limit_tiyin'])),
            isActive: Value((p['is_active'] as bool?) ?? true),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  /// Central may serialize numeric fields as either `int` or `num` (JSON parsing
  /// quirks when a number looks like a double). Normalise to int here.
  static int? _asInt(Object? raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  // ---- cursor persistence ----
  // We use ONE cursor per pull (across all watched tables) for simplicity. If
  // latency-sensitive per-table cursors become important later, split this.
  static const _sharedCursorKey = '__all__';

  Future<String?> _readCursor(String table) async {
    final row = await (_db.select(_db.syncCursorsTable)
          ..where((t) => t.targetTable.equals(table)))
        .getSingleOrNull();
    return row?.cursor;
  }

  Future<void> _writeCursor(String table, String cursor) async {
    await _db.into(_db.syncCursorsTable).insertOnConflictUpdate(
          SyncCursorsTableCompanion.insert(
            targetTable: table,
            cursor: cursor,
            updatedAt: DateTime.now().toUtc(),
          ),
        );
  }
}

/// Result of a single pull cycle.
class SyncPullResult {
  const SyncPullResult({required this.applied})
      : isBusy = false,
        transientError = null;

  const SyncPullResult.busy()
      : applied = 0,
        isBusy = true,
        transientError = null;

  const SyncPullResult.transient(String reason)
      : applied = 0,
        isBusy = false,
        transientError = reason;

  final int applied;
  final bool isBusy;
  final String? transientError;

  bool get isOk => !isBusy && transientError == null;

  @override
  String toString() {
    if (isBusy) return 'SyncPullResult(busy)';
    if (transientError != null) return 'SyncPullResult(transient: $transientError)';
    return 'SyncPullResult(applied: $applied)';
  }
}
