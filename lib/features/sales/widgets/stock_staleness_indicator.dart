import 'package:flutter/material.dart';

import '../../../services/stock/stock_freshness_service.dart';

/// Colored dot the cashier cart UI shows next to the quantity-on-hand badge.
///
/// - green: the count is within one sync tick, safe to trust
/// - yellow: the count is stale but probably still usable
/// - red: the count is outdated — a manager-PIN override is likely imminent
/// - grey: no sync has ever landed (pre-activation, or an extended offline)
///
/// The widget consumes a pre-built stream (usually
/// `StockFreshnessService.watch()`) so tests can drive it deterministically
/// without a DB. A separate [StockStalenessBanner] below shows the coarse
/// "Stock may be outdated" warning when the tier is red.
class StockStalenessIndicator extends StatelessWidget {
  const StockStalenessIndicator({
    super.key,
    required this.stream,
    this.size = 10,
  });

  /// Convenience constructor that pulls the stream from a service. Keep the
  /// raw-stream constructor for tests so they can feed a
  /// [StreamController]-backed stream.
  factory StockStalenessIndicator.fromService(
    StockFreshnessService service, {
    Key? key,
    double size = 10,
  }) =>
      StockStalenessIndicator(key: key, stream: service.watch(), size: size);

  final Stream<StockFreshnessSnapshot> stream;
  final double size;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StockFreshnessSnapshot>(
      stream: stream,
      builder: (context, snap) {
        final tier = snap.data?.tier ?? StockFreshness.unknown;
        final age = snap.data?.age ?? Duration.zero;
        return Tooltip(
          message: _tooltip(tier, age),
          child: Semantics(
            label: _semanticLabel(tier),
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: _colorFor(tier),
                shape: BoxShape.circle,
              ),
            ),
          ),
        );
      },
    );
  }

  static Color _colorFor(StockFreshness t) => switch (t) {
        StockFreshness.fresh => Colors.green,
        StockFreshness.stale => Colors.amber,
        StockFreshness.outdated => Colors.red,
        StockFreshness.unknown => Colors.grey,
      };

  static String _semanticLabel(StockFreshness t) => switch (t) {
        StockFreshness.fresh => 'Остаток актуален',
        StockFreshness.stale => 'Остаток устаревает',
        StockFreshness.outdated => 'Остаток устарел',
        StockFreshness.unknown => 'Остаток неизвестен',
      };

  static String _tooltip(StockFreshness t, Duration age) {
    final s = age.inSeconds;
    final ageStr = s < 60
        ? '$s с назад'
        : s < 3600
            ? '${age.inMinutes}м назад'
            : '${age.inHours}ч назад';
    return switch (t) {
      StockFreshness.fresh => 'Синхронизация: $ageStr',
      StockFreshness.stale => 'Синхронизация: $ageStr (устаревает)',
      StockFreshness.outdated => 'Синхронизация: $ageStr — остаток может быть неточным',
      StockFreshness.unknown => 'Синхронизация не выполнялась',
    };
  }
}

/// Top-of-cart banner that only renders when the freshness tier is
/// [StockFreshness.outdated]. Kept separate from the per-row dot so the cart
/// UI can place them independently — the banner is stack-level, the dots are
/// row-level.
class StockStalenessBanner extends StatelessWidget {
  const StockStalenessBanner({super.key, required this.stream});

  factory StockStalenessBanner.fromService(
    StockFreshnessService service, {
    Key? key,
  }) =>
      StockStalenessBanner(key: key, stream: service.watch());

  final Stream<StockFreshnessSnapshot> stream;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<StockFreshnessSnapshot>(
      stream: stream,
      builder: (context, snap) {
        if (snap.data?.tier != StockFreshness.outdated) {
          return const SizedBox.shrink();
        }
        return Material(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Остаток товаров может быть неточным — синхронизация отстаёт',
                    style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
