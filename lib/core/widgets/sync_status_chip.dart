import 'package:flutter/material.dart';

import '../../services/sync/sync_status_service.dart';
import '../theme/hifi.dart';
import 'sync_status_sheet.dart';

/// Compact status pill rendered in `HifiChrome` (top navy bar). One colored
/// dot + one-word label; tap opens `SyncStatusSheet` with the four-row
/// detail view. Subscribes to `SyncStatusService.watch()` for live updates
/// on the service's internal 15 s poll cadence.
class SyncStatusChip extends StatelessWidget {
  const SyncStatusChip({
    super.key,
    required this.service,
  });

  final SyncStatusService service;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SyncStatusSnapshot>(
      stream: service.watch(),
      builder: (context, snap) {
        final s = snap.data;
        return InkWell(
          onTap: () => SyncStatusSheet.show(context, service),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: _backgroundFor(s?.tier),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(
                '●',
                style: TextStyle(
                  color: _dotColorFor(s?.tier),
                  fontSize: 9,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                _labelFor(s),
                style: Hifi.ui(
                  size: 11,
                  weight: FontWeight.w600,
                  color: _textColorFor(s?.tier),
                ).copyWith(letterSpacing: 0.3),
              ),
            ]),
          ),
        );
      },
    );
  }

  // --- Styling + labels ---------------------------------------------------

  /// Short status label, ~15 chars max so the chip stays compact. Expands
  /// with outbox count when pending so the cashier sees the backlog at a
  /// glance without opening the sheet.
  String _labelFor(SyncStatusSnapshot? s) {
    if (s == null) return '…';
    final pending = s.outboxPending + s.outboxFailed;
    switch (s.tier) {
      case SyncStatusTier.green:
        return 'ONLINE';
      case SyncStatusTier.amber:
        if (pending > 0) return 'ОЧЕРЕДЬ · $pending';
        return 'СТАРЫЕ ДАННЫЕ';
      case SyncStatusTier.red:
        if (!s.online) return 'OFFLINE · $pending';
        if (pending > 0) return 'ЗАСТРЯЛО · $pending';
        return 'OFFLINE';
      case SyncStatusTier.grey:
        return 'НЕ СИНХР.';
    }
  }

  Color _backgroundFor(SyncStatusTier? t) {
    switch (t) {
      case SyncStatusTier.green:
        return const Color(0x3887F7C3);
      case SyncStatusTier.amber:
        return const Color(0x38FFD180);
      case SyncStatusTier.red:
        return const Color(0x38FFCDD2);
      case SyncStatusTier.grey:
      case null:
        return const Color(0x38B0BEC5);
    }
  }

  Color _dotColorFor(SyncStatusTier? t) => _textColorFor(t);

  Color _textColorFor(SyncStatusTier? t) {
    switch (t) {
      case SyncStatusTier.green:
        return Hifi.chromeOnline;
      case SyncStatusTier.amber:
        return const Color(0xFFE67E00);
      case SyncStatusTier.red:
        return Hifi.chromeOffline;
      case SyncStatusTier.grey:
      case null:
        return const Color(0xFF78909C);
    }
  }
}
