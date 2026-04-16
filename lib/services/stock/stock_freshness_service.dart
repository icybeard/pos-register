import 'dart:async';

import '../../data/database.dart';

/// Tier of stock-count freshness shown in the cashier UI as a colored dot
/// (green/yellow/red) next to the quantity-on-hand badge.
///
/// Source: the time elapsed since the register's last successful pull from
/// central. If a delivery was received an hour ago at another workstation and
/// we haven't pulled since, our on-hand count is an hour stale — the cashier
/// deserves to know before ringing up "last unit".
enum StockFreshness {
  /// < 60s since last pull. Safe to rely on the count.
  fresh,

  /// 60s ≤ age < 5min. Count might miss the very latest deliveries; tolerable.
  stale,

  /// ≥ 5min since last pull, OR no pull has ever succeeded. Show a banner —
  /// the count is unreliable enough that overselling is a real risk.
  outdated,

  /// No tokens / unactivated / offline path. The indicator should still render
  /// (dimmed) so the cashier knows we're in a degraded mode, not a bug.
  unknown,
}

/// Snapshot of freshness at a moment in time, plus the age it was computed
/// from. Widgets bind to [StockFreshnessService.watch] and render from this.
class StockFreshnessSnapshot {
  const StockFreshnessSnapshot({required this.tier, required this.age});
  final StockFreshness tier;

  /// Time elapsed since the last successful pull, or `Duration.zero` when
  /// [tier] is [StockFreshness.unknown].
  final Duration age;

  @override
  String toString() => 'StockFreshnessSnapshot($tier, age=${age.inSeconds}s)';
}

/// Thresholds are compile-time constants so tests can reference them directly.
/// Tuned to the POS hot path: 60s = "within one sync tick", 5min = "we've
/// missed at least a couple of ticks, reconsider the count".
const Duration kStockFreshMaxAge = Duration(seconds: 60);
const Duration kStockStaleMaxAge = Duration(minutes: 5);

/// Reads the `sync_cursors.updated_at` for the shared pull cursor (`__all__`)
/// and classifies freshness. The puller writes this cursor after every
/// successful pull of watched tables (stock_movements included), so its
/// `updated_at` is the authoritative "last time we heard from central" signal.
///
/// **Why not per-table cursors**: the puller ships a single cursor across
/// watched tables (see `SyncPuller._sharedCursorKey`). If we later split cursors
/// per table for latency reasons, this service keeps working — it just reads
/// from a different row.
class StockFreshnessService {
  StockFreshnessService(
    this._db, {
    DateTime Function() clock = _defaultClock,
    Duration pollInterval = const Duration(seconds: 15),
  })  : _clock = clock,
        _pollInterval = pollInterval;

  static DateTime _defaultClock() => DateTime.now().toUtc();

  /// Matches `SyncPuller._sharedCursorKey`. Importing that private constant
  /// would couple the freshness service to the puller's internals; hard-coding
  /// the same literal is the lesser coupling.
  static const _cursorKey = '__all__';

  final AppDatabase _db;
  final DateTime Function() _clock;
  final Duration _pollInterval;

  /// One-shot read — current freshness snapshot.
  Future<StockFreshnessSnapshot> current() async {
    final row = await (_db.select(_db.syncCursorsTable)
          ..where((t) => t.targetTable.equals(_cursorKey)))
        .getSingleOrNull();
    if (row == null) {
      return const StockFreshnessSnapshot(
        tier: StockFreshness.unknown,
        age: Duration.zero,
      );
    }
    final age = _clock().difference(row.updatedAt);
    return StockFreshnessSnapshot(tier: _classify(age), age: age);
  }

  /// Reactive freshness stream. Emits on every poll tick — 15s by default.
  /// Polling (rather than watching the drift row) keeps a correct age readout
  /// even when NO new pull lands, which is precisely when freshness degrades.
  ///
  /// Caller should `await for` with `.distinct()` if they only want tier
  /// transitions (the age itself is monotonic until a new pull resets it).
  Stream<StockFreshnessSnapshot> watch() {
    late final StreamController<StockFreshnessSnapshot> controller;
    Timer? timer;

    Future<void> tick() async {
      if (controller.isClosed) return;
      controller.add(await current());
    }

    controller = StreamController<StockFreshnessSnapshot>(
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

  static StockFreshness _classify(Duration age) {
    if (age.isNegative) {
      // Clock skew / fake clock in tests — treat as fresh.
      return StockFreshness.fresh;
    }
    if (age < kStockFreshMaxAge) return StockFreshness.fresh;
    if (age < kStockStaleMaxAge) return StockFreshness.stale;
    return StockFreshness.outdated;
  }
}
