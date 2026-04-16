import 'dart:async';

import 'sync_puller.dart';
import 'sync_worker.dart';

/// Ties [SyncWorker] (push) and [SyncPuller] (pull) into a single periodic cadence.
///
/// One timer, one shared tick:
///   1. push pending outbox rows
///   2. pull server changes
///
/// Both halves are independently mutexed (reentrancy safe) and short-circuit on no-op.
/// The scheduler itself ALSO guards against overlapping ticks — if a tick is still running
/// when the next one fires, the new tick is skipped.
///
/// **Lifecycle**:
///   - `start()` begins the timer; safe to call multiple times (no-op if already running)
///   - `stop()` cancels the timer; safe to call even if not started
///   - `runOnce()` fires one immediate tick, ignoring the timer cadence — useful for
///     "drain on app resume" or manual user refresh buttons
///
/// **Cadence**: default 30s. Production tuning is a per-deployment concern (high-traffic
/// stores may want 10s; low-traffic ones can go 60s+).
class SyncScheduler {
  SyncScheduler({
    required SyncWorker worker,
    required SyncPuller puller,
    this.interval = const Duration(seconds: 30),
    void Function(SyncTickResult result)? onTick,
  })  : _worker = worker,
        _puller = puller,
        _onTick = onTick;

  final SyncWorker _worker;
  final SyncPuller _puller;
  final Duration interval;
  final void Function(SyncTickResult)? _onTick;

  Timer? _timer;
  bool _tickInFlight = false;

  bool get isRunning => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(interval, (_) => runOnce());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Fire an immediate tick. Returns the result. If a tick is already running, returns
  /// [SyncTickResult.busy] without queueing — the next periodic tick will try again.
  Future<SyncTickResult> runOnce() async {
    if (_tickInFlight) {
      return const SyncTickResult.busy();
    }
    _tickInFlight = true;
    try {
      final push = await _worker.drainOnce();
      final pull = await _puller.pullOnce();
      final result = SyncTickResult(push: push, pull: pull);
      _onTick?.call(result);
      return result;
    } finally {
      _tickInFlight = false;
    }
  }
}

/// Combined outcome of one push+pull tick.
class SyncTickResult {
  const SyncTickResult({required this.push, required this.pull}) : isBusy = false;

  const SyncTickResult.busy()
      : push = null,
        pull = null,
        isBusy = true;

  final SyncDrainResult? push;
  final SyncPullResult? pull;
  final bool isBusy;

  @override
  String toString() => isBusy ? 'SyncTickResult(busy)' : 'SyncTickResult(push: $push, pull: $pull)';
}
