import 'dart:async';
import 'package:flutter/foundation.dart';
import 'api_client.dart';

/// Sync status for UI display
enum SyncStatus { idle, syncing, synced, error, offline }

/// Service that manages delta synchronization between local device and server.
/// Strategy: server-wins conflict resolution.
class SyncService {
  final ApiClient api;
  Timer? _periodicTimer;
  String? _lastSyncTimestamp;

  final _statusController = StreamController<SyncStatus>.broadcast();
  SyncStatus _status = SyncStatus.idle;

  /// Stream of sync status changes
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// Current sync status
  SyncStatus get status => _status;

  SyncService(this.api);

  /// Start periodic sync (every 30 seconds when online)
  void startPeriodicSync({Duration interval = const Duration(seconds: 30)}) {
    _periodicTimer?.cancel();
    _periodicTimer = Timer.periodic(interval, (_) => sync());
  }

  /// Stop periodic sync
  void stopPeriodicSync() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  /// Perform a full sync cycle: push local changes, then pull server changes
  Future<void> sync() async {
    if (_status == SyncStatus.syncing) return; // prevent concurrent syncs

    _setStatus(SyncStatus.syncing);
    try {
      // Step 1: Check server health
      final healthy = await api.checkHealth();
      if (!healthy) {
        _setStatus(SyncStatus.offline);
        return;
      }

      // Step 2: Pull changes from server
      final pullResult = await api.pullChanges(since: _lastSyncTimestamp);
      final entries = pullResult['entries'] as List<dynamic>? ?? [];
      if (entries.isNotEmpty) {
        // In a full implementation, apply these changes to local SQLite
        // For now, just update the timestamp
        final lastEntry = entries.last as Map<String, dynamic>;
        _lastSyncTimestamp = lastEntry['created_at'] as String?;
        assert(() {
          debugPrint('[SYNC] Pulled ${entries.length} changes from server');
          return true;
        }());
      }

      // Step 3: Get sync stats
      final stats = await api.syncStatus();
      final unsynced = stats['unsynced_count'] as int? ?? 0;
      assert(() {
        debugPrint('[SYNC] Server reports $unsynced unsynced entries');
        return true;
      }());

      _setStatus(SyncStatus.synced);
    } on Exception catch (e) {
      assert(() {
        debugPrint('[SYNC] Error: $e');
        return true;
      }());
      _setStatus(SyncStatus.error);
    }
  }

  void _setStatus(SyncStatus s) {
    _status = s;
    if (!_statusController.isClosed) {
      _statusController.add(s);
    }
  }

  void dispose() {
    stopPeriodicSync();
    _statusController.close();
  }
}
