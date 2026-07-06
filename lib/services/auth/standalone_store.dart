import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Standalone (автономный) mode marker — the register runs fully local with a
/// synthetic tenant/store id and no server. Mirrors [WorkstationStore]'s shape:
/// activation is a property of the machine, standalone mode is too. Both may
/// never be set at once — linking a standalone register adopts the real tenant
/// and clears this record (see AuthController.activateRegister).
///
/// Spec: pos-docs/specs/platform/03-device-linking.md (R1/R2).
class StandaloneInfo {
  const StandaloneInfo({
    required this.tenantId,
    required this.storeId,
    required this.storeName,
    required this.createdAt,
  });

  /// Synthetic UUID minted at setup. Re-stamped to the real tenant on link.
  final String tenantId;

  /// Synthetic UUID — local rows need SOME store id (users.store_id etc).
  final String storeId;

  final String storeName;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'tenant_id': tenantId,
        'store_id': storeId,
        'store_name': storeName,
        'created_at': createdAt.toIso8601String(),
      };

  factory StandaloneInfo.fromJson(Map<String, dynamic> j) => StandaloneInfo(
        tenantId: j['tenant_id'] as String,
        storeId: j['store_id'] as String,
        storeName: j['store_name'] as String? ?? '',
        createdAt: DateTime.parse(j['created_at'] as String).toUtc(),
      );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StandaloneInfo &&
        other.tenantId == tenantId &&
        other.storeId == storeId &&
        other.storeName == storeName &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(tenantId, storeId, storeName, createdAt);
}

/// Secure-storage-backed persistence for [StandaloneInfo]. Dedicated key so
/// neither logout ([AuthTokenStore.clear]) nor un-linking touches it by
/// accident.
class StandaloneStore {
  StandaloneStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'pos.standalone.v1';
  final FlutterSecureStorage _storage;

  Future<StandaloneInfo?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      return StandaloneInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Corrupt record — treat as "not standalone"; the connect screen shows
      // and the owner can skip again (local data keyed by the old tenant id
      // is recovered by re-reading this store, so don't delete it here).
      return null;
    }
  }

  Future<void> save(StandaloneInfo info) =>
      _storage.write(key: _key, value: jsonEncode(info.toJson()));

  Future<void> clear() => _storage.delete(key: _key);
}
