import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Device-level activation payload. Returned by
/// `POST /api/register/activate {code}` and persisted per-device in
/// flutter_secure_storage. Separate from the user access token
/// ([AuthTokenStore]) because activation is a property of the machine,
/// not the person — it survives user logout / cashier switching.
///
/// Note: the current .NET endpoint does NOT issue a JWT from activation;
/// it only binds the workstation to a tenant + store. The register must
/// still authenticate a user (owner or cashier) to make any authorised
/// call. Activation just tells the login UI which tenant + store the
/// cashier PIN should be resolved against.
class WorkstationInfo {
  const WorkstationInfo({
    required this.workstationId,
    required this.tenantId,
    required this.storeId,
    required this.storeName,
    required this.activatedAt,
  });

  final String workstationId;
  final String tenantId;
  final String storeId;
  final String storeName;
  final DateTime activatedAt;

  Map<String, dynamic> toJson() => {
        'workstation_id': workstationId,
        'tenant_id': tenantId,
        'store_id': storeId,
        'store_name': storeName,
        'activated_at': activatedAt.toIso8601String(),
      };

  factory WorkstationInfo.fromJson(Map<String, dynamic> j) => WorkstationInfo(
        workstationId: j['workstation_id'] as String,
        tenantId: j['tenant_id'] as String,
        storeId: j['store_id'] as String,
        storeName: j['store_name'] as String? ?? '',
        activatedAt: DateTime.parse(j['activated_at'] as String).toUtc(),
      );
}

/// Secure-storage-backed persistence for [WorkstationInfo].
/// Dedicated key (`pos.workstation.v1`) kept separate from auth tokens so
/// `logout` / `AuthTokenStore.clear()` doesn't accidentally de-activate
/// the device.
class WorkstationStore {
  WorkstationStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const _key = 'pos.workstation.v1';
  final FlutterSecureStorage _storage;

  Future<WorkstationInfo?> load() async {
    try {
      final raw = await _storage.read(key: _key);
      if (raw == null || raw.isEmpty) return null;
      try {
        return WorkstationInfo.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } on Object {
        // Corrupt payload — purge and force re-activation.
        await clear();
        return null;
      }
    } on Object {
      // Platform error (e.g. Keychain -34018 on unsigned macOS sandbox).
      // Treat as "not activated" — the operator re-types the code.
      return null;
    }
  }

  Future<void> save(WorkstationInfo info) async {
    try {
      await _storage.write(key: _key, value: jsonEncode(info.toJson()));
    } on Object {
      // Persistence is best-effort; in-memory state keeps the session.
    }
  }

  /// Hard-reset: device becomes un-activated again. Only the owner should
  /// trigger this from the settings screen; normal logout does NOT clear.
  Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } on Object {
      // Same rationale as save(): never let a Keychain failure cascade.
    }
  }
}
