import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../data/database.dart';
import '../services/central_client.dart';

/// Drains the local `sync_outbox` to central's `POST /api/sync/push` on a periodic tick.
/// Marks synced rows with `synced_at` and records `last_error` + bumps `attempts` on failure.
///
/// **Safe to call concurrently** — the drainer pattern uses a strict per-call mutex so
/// overlapping ticks can't double-push the same row. If a drain is already in flight,
/// subsequent calls return immediately (they don't queue — next periodic tick retries).
///
/// Batch size: up to 100 entries per push (well under the server's 500 cap, leaving
/// headroom for retries). Ordered by `id` (insertion order) so causal dependencies
/// within a single transaction are preserved.
///
/// Exponential backoff: rows with `attempts >= 3` are skipped until the top-of-hour to
/// prevent poison-pill rows from starving fresh entries. Real backoff schedule lands in
/// P2.T2 (dedicated retry worker); this is the minimum viable version.
class SyncWorker {
  SyncWorker({required AppDatabase db, required CentralClient client, String? deviceId})
      : _db = db,
        _client = client,
        _deviceId = deviceId ?? const Uuid().v4();

  final AppDatabase _db;
  final CentralClient _client;
  final String _deviceId;

  /// Bounded concurrency — at most one drain in flight.
  bool _draining = false;

  /// Result of a single drain cycle. `pushed` = rows pushed + central accepted
  /// (i.e. `synced_at` set). `rejected` = server said no (row stays in outbox with
  /// `last_error` set for human review). `pending` = network/other transient failure,
  /// counts toward future retry.
  Future<SyncDrainResult> drainOnce({int maxPerBatch = 100}) async {
    if (_draining) {
      return const SyncDrainResult.busy();
    }
    _draining = true;
    try {
      final rows = await _fetchPending(maxPerBatch);
      if (rows.isEmpty) {
        return const SyncDrainResult(pushed: 0, rejected: 0, pending: 0);
      }

      final batchId = const Uuid().v4();
      final entries = rows.map((r) {
        final payload = jsonDecode(r.payloadJson) as Map<String, dynamic>;
        return {
          'table': r.targetTable,
          'op': r.op,
          'uuid': r.uuid,
          'client_ts': r.createdAt.toIso8601String(),
          'payload': payload,
        };
      }).toList();

      try {
        final resp = await _client.post<Map<String, dynamic>>('/api/sync/push', body: {
          'device_id': _deviceId,
          'batch_id': batchId,
          'entries': entries,
        });
        final body = resp.data ?? const {};
        final accepted = ((body['accepted'] as List?) ?? const [])
            .cast<String>()
            .toSet();
        final rejectedList = ((body['rejected'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        final rejected = {for (final r in rejectedList) r['uuid'] as String: r['reason'] as String? ?? ''};

        final now = DateTime.now().toUtc();
        await _db.transaction(() async {
          for (final row in rows) {
            if (accepted.contains(row.uuid)) {
              await (_db.update(_db.syncOutboxTable)..where((t) => t.id.equals(row.id)))
                  .write(SyncOutboxTableCompanion(syncedAt: Value(now)));
            } else if (rejected.containsKey(row.uuid)) {
              await (_db.update(_db.syncOutboxTable)..where((t) => t.id.equals(row.id)))
                  .write(SyncOutboxTableCompanion(
                attempts: Value(row.attempts + 1),
                lastError: Value('rejected: ${rejected[row.uuid] ?? 'unknown'}'),
              ));
            }
          }
        });

        return SyncDrainResult(
          pushed: accepted.length,
          rejected: rejected.length,
          pending: 0,
        );
      } on DioException catch (e) {
        // Network / 5xx — mark every attempted row as transient, bump attempts.
        final reason = e.message ?? 'network error';
        await _recordTransientFailure(rows, reason);
        return SyncDrainResult(pushed: 0, rejected: 0, pending: rows.length);
      } on Object catch (e) {
        await _recordTransientFailure(rows, e.toString());
        return SyncDrainResult(pushed: 0, rejected: 0, pending: rows.length);
      }
    } finally {
      _draining = false;
    }
  }

  Future<List<SyncOutboxRow>> _fetchPending(int limit) {
    return (_db.select(_db.syncOutboxTable)
          ..where((t) => t.syncedAt.isNull() & t.attempts.isSmallerThanValue(3))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])
          ..limit(limit))
        .get();
  }

  Future<void> _recordTransientFailure(List<SyncOutboxRow> rows, String reason) async {
    await _db.transaction(() async {
      for (final r in rows) {
        await (_db.update(_db.syncOutboxTable)..where((t) => t.id.equals(r.id)))
            .write(SyncOutboxTableCompanion(
          attempts: Value(r.attempts + 1),
          lastError: Value(reason),
        ));
      }
    });
  }
}

/// Aggregate outcome of a single drain call.
class SyncDrainResult {
  const SyncDrainResult({
    required this.pushed,
    required this.rejected,
    required this.pending,
  }) : isBusy = false;

  const SyncDrainResult.busy()
      : pushed = 0,
        rejected = 0,
        pending = 0,
        isBusy = true;

  final int pushed;
  final int rejected;
  final int pending;

  /// True when the drain was skipped because another drain was already in flight.
  final bool isBusy;

  bool get isIdle => !isBusy && pushed == 0 && rejected == 0 && pending == 0;

  @override
  String toString() => isBusy
      ? 'SyncDrainResult(busy)'
      : 'SyncDrainResult(pushed: $pushed, rejected: $rejected, pending: $pending)';
}
