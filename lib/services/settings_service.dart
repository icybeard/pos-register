import 'package:dio/dio.dart';

import '../data/repositories/settings_repository.dart';
import 'central_client.dart';

/// Ties [SettingsRepository] (drift, offline-first) to [CentralClient] (.NET central).
///
/// **Write pattern — local-first + best-effort push**:
///   1. `upsert` writes to drift + sync_outbox atomically (never throws on network issues)
///   2. Then attempts PUT `/api/settings/{key}` best-effort
///   3. If central is reachable, the sync_outbox row can be marked synced (P2 drainer job)
///   4. If central is unreachable, the row stays in the outbox and the P2 drainer retries later
///
/// **Read pattern — always drift, reactive**:
///   - `watchAll` streams from drift (fast, offline-capable)
///   - `hydrateFromCentral` pulls GET `/api/settings` and upserts into drift (called on app
///     boot + on sync tick)
///
/// This service intentionally swallows central-side errors on writes — the outbox captures
/// intent, the drainer handles eventual consistency. Caller decides whether to surface errors
/// via the optional [SettingsWriteResult] return value.
class SettingsService {
  SettingsService({
    required SettingsRepository repo,
    required CentralClient client,
  })  : _repo = repo,
        _client = client;

  final SettingsRepository _repo;
  final CentralClient _client;

  Stream<Map<String, String>> watchAll() => _repo.watchAll();

  Future<Map<String, String>> all() => _repo.all();

  Future<String?> get(String key) => _repo.get(key);

  /// Local-first write. Always writes drift. Attempts central push; records success
  /// or failure in the returned [SettingsWriteResult]. Never throws on network issues.
  Future<SettingsWriteResult> upsert(String key, String value) async {
    await _repo.upsert(key, value);
    try {
      await _client.put<void>(
        '/api/settings/$key',
        body: {'value': value},
      );
      return const SettingsWriteResult.synced();
    } on DioException catch (e) {
      return SettingsWriteResult.pending(e.message ?? 'network error');
    } on Object catch (e) {
      return SettingsWriteResult.pending(e.toString());
    }
  }

  /// Fetch every setting from central and upsert into drift. Called on app boot and
  /// whenever the sync worker ticks. Returns the number of rows pulled, 0 on offline.
  Future<int> hydrateFromCentral() async {
    try {
      final resp = await _client.get<Map<String, dynamic>>('/api/settings');
      final settings = (resp.data?['settings'] as Map?)?.cast<String, dynamic>() ?? const {};
      for (final e in settings.entries) {
        // Bypass the outbox for remote-origin upserts — the data already is in central.
        // For now we go through the regular upsert path (extra outbox rows are harmless;
        // drainer will no-op on duplicates). P2 adds a dedicated bulkUpsertFromRemote.
        await _repo.upsert(e.key, e.value.toString());
      }
      return settings.length;
    } on DioException catch (_) {
      return 0;
    } on Object catch (_) {
      return 0;
    }
  }
}

/// Outcome of a write-through upsert. `synced` = central acknowledged. `pending` = local
/// only; the sync_outbox row will be drained by the P2 worker once central is reachable.
class SettingsWriteResult {
  const SettingsWriteResult.synced()
      : isSynced = true,
        reason = null;
  const SettingsWriteResult.pending(this.reason) : isSynced = false;

  final bool isSynced;
  final String? reason;

  @override
  String toString() => isSynced ? 'synced' : 'pending: $reason';
}
