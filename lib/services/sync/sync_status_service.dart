import 'dart:async';
import 'dart:developer' as developer;

import '../../data/database.dart';
import '../api_client.dart';
import '../stock/stock_freshness_service.dart';

/// Overall sync tier shown as a colored dot in the top chrome bar. Derived
/// from three inputs: master-data pull freshness, outbox depth, and server
/// reachability. The "worst" tier of the three wins — a green pull freshness
/// doesn't cover up a 50-receipt outbox backlog.
enum SyncStatusTier {
  /// All good — fresh pull, no outbox backlog, server reachable.
  green,

  /// Minor concern — stale pull (60 s – 5 min), or 1–10 pending outbox rows,
  /// or last health probe returned quickly after a transient failure.
  amber,

  /// Action needed — offline >60 s, or >10 pending rows, or no successful
  /// push in >5 min. Owner should investigate.
  red,

  /// Not yet activated or never synced. Dimmed indicator so the operator
  /// knows the system is in a degraded mode, not buggy.
  grey,
}

/// Point-in-time snapshot of all sync inputs. The chip widget renders the
/// overall tier plus a short label; the detail sheet reads the individual
/// fields for its four rows.
class SyncStatusSnapshot {
  const SyncStatusSnapshot({
    required this.tier,
    required this.freshness,
    required this.outboxPending,
    required this.outboxFailed,
    required this.online,
    required this.checkedAt,
  });

  /// Aggregate tier — what the single dot shows.
  final SyncStatusTier tier;

  /// Master-data pull freshness (from the shared `__all__` sync cursor).
  final StockFreshnessSnapshot freshness;

  /// Rows in `sync_outbox` with `synced_at IS NULL` and no terminal error.
  /// These will be retried on the next drain tick.
  final int outboxPending;

  /// Rows in `sync_outbox` with `last_error` set and `attempts >= 3` — the
  /// ones the drain worker has given up on until the next top-of-hour retry.
  /// Owner should see these surfaced separately.
  final int outboxFailed;

  /// True when the last `api.checkHealth()` returned OK within the timeout.
  /// Probed on every service tick (~15 s).
  final bool online;

  /// Clock timestamp this snapshot was computed at. Used by the detail
  /// sheet's "updated X s ago" label.
  final DateTime checkedAt;

  @override
  String toString() => 'SyncStatusSnapshot('
      'tier=$tier, '
      'freshness=${freshness.tier}, '
      'outbox=$outboxPending pending/$outboxFailed failed, '
      'online=$online)';
}

/// Aggregates pull freshness, outbox depth, and server reachability into a
/// single `SyncStatusSnapshot`. Exposes a reactive stream on a 15 s tick —
/// same cadence as `StockFreshnessService` so both signals age in lockstep.
class SyncStatusService {
  SyncStatusService(
    this._db,
    this._api, {
    StockFreshnessService? freshnessService,
    Duration pollInterval = const Duration(seconds: 15),
    Duration healthTimeout = const Duration(seconds: 3),
    DateTime Function() clock = _defaultClock,
  })  : _freshness = freshnessService ?? StockFreshnessService(_db, clock: clock),
        _pollInterval = pollInterval,
        _healthTimeout = healthTimeout,
        _clock = clock;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  final AppDatabase _db;
  final ApiClient _api;
  final StockFreshnessService _freshness;
  final Duration _pollInterval;
  final Duration _healthTimeout;
  final DateTime Function() _clock;

  /// Classification thresholds — exposed so tests can reference them
  /// and the detail sheet can explain "why amber" to the user.
  static const int kOutboxAmberThreshold = 1;
  static const int kOutboxRedThreshold = 10;

  /// One-shot read. Runs the three probes in parallel, aggregates, returns.
  Future<SyncStatusSnapshot> current() async {
    final probes = await Future.wait([
      _freshness.current(),
      _countOutboxPending(),
      _countOutboxFailed(),
      _probeHealth(),
    ]);
    final fresh = probes[0] as StockFreshnessSnapshot;
    final pending = probes[1] as int;
    final failed = probes[2] as int;
    final online = probes[3] as bool;
    return SyncStatusSnapshot(
      tier: _aggregate(fresh.tier, pending, failed, online),
      freshness: fresh,
      outboxPending: pending,
      outboxFailed: failed,
      online: online,
      checkedAt: _clock(),
    );
  }

  /// Reactive stream. Emits on subscribe + every `_pollInterval`. Consumers
  /// that only care about tier transitions can apply `.distinct((a, b) => a.tier == b.tier)`.
  Stream<SyncStatusSnapshot> watch() {
    late final StreamController<SyncStatusSnapshot> controller;
    Timer? timer;

    Future<void> tick() async {
      if (controller.isClosed) return;
      try {
        controller.add(await current());
      } on Object catch (e, st) {
        // A probe exception (drift error, API client in bad state) shouldn't
        // kill the stream — emit a safe "unknown" snapshot and keep polling.
        controller.add(SyncStatusSnapshot(
          tier: SyncStatusTier.grey,
          freshness: const StockFreshnessSnapshot(
            tier: StockFreshness.unknown,
            age: Duration.zero,
          ),
          outboxPending: 0,
          outboxFailed: 0,
          online: false,
          checkedAt: _clock(),
        ));
        // Structured log via dart:developer — visible in DevTools / IDE
        // log panes, filterable by name + level, and stripped from
        // release-build flags only when the embedder elects to. Replaces
        // the previous assert(()=>print(...)()) hack which suppressed the
        // avoid_print lint and would silently disappear if the wrapper
        // assert was ever removed.
        developer.log(
          'sync status tick failed',
          name: 'pos.sync.status',
          error: e,
          stackTrace: st,
        );
      }
    }

    controller = StreamController<SyncStatusSnapshot>(
      onListen: () {
        tick();
        timer = Timer.periodic(_pollInterval, (_) => tick());
      },
      onCancel: () async {
        timer?.cancel();
        timer = null;
      },
    );
    return controller.stream;
  }

  /// Force an immediate health probe + outbox scan. Used by the "refresh
  /// now" button in the detail sheet — users shouldn't have to wait up to
  /// 15 s for the next natural tick.
  Future<SyncStatusSnapshot> refresh() => current();

  // --- Internal probes -----------------------------------------------------

  Future<int> _countOutboxPending() async {
    // Pending = not yet synced AND below the give-up threshold. Rows with
    // attempts >= 3 are counted separately as "failed" so the UI can
    // distinguish transient backlog from stuck rows.
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM sync_outbox '
          'WHERE synced_at IS NULL AND attempts < 3',
        )
        .get();
    return rows.isEmpty ? 0 : rows.first.read<int>('c');
  }

  Future<int> _countOutboxFailed() async {
    final rows = await _db
        .customSelect(
          'SELECT COUNT(*) AS c FROM sync_outbox '
          'WHERE synced_at IS NULL AND attempts >= 3',
        )
        .get();
    return rows.isEmpty ? 0 : rows.first.read<int>('c');
  }

  Future<bool> _probeHealth() async {
    try {
      return await _api.checkHealth().timeout(_healthTimeout);
    } on Object {
      // Timeout, socket error, 5xx — all mean "not healthy right now".
      return false;
    }
  }

  // --- Aggregation ---------------------------------------------------------

  SyncStatusTier _aggregate(
    StockFreshness freshness,
    int pending,
    int failed,
    bool online,
  ) {
    // grey dominates — nothing else matters if we've never synced
    if (freshness == StockFreshness.unknown && pending == 0 && failed == 0) {
      return online ? SyncStatusTier.grey : SyncStatusTier.grey;
    }

    // red checks
    if (!online) return SyncStatusTier.red;
    if (failed > 0) return SyncStatusTier.red;
    if (pending > kOutboxRedThreshold) return SyncStatusTier.red;
    if (freshness == StockFreshness.outdated) return SyncStatusTier.red;

    // amber checks
    if (pending >= kOutboxAmberThreshold) return SyncStatusTier.amber;
    if (freshness == StockFreshness.stale) return SyncStatusTier.amber;

    return SyncStatusTier.green;
  }
}

