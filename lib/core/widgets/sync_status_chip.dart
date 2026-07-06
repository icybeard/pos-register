import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../services/sync/sync_status_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/hifi.dart';
import 'sync_status_sheet.dart';

/// Compact status pill rendered in `HifiChrome` (top navy bar). One colored
/// dot + one-word label; tap opens `SyncStatusSheet` with the four-row
/// detail view. Subscribes to `SyncStatusService.watch()` for live updates
/// on the service's internal 15 s poll cadence.
///
/// In standalone (автономный) mode there is no server, so the chip shows a
/// neutral «Автономно» state instead of the health-derived tiers — otherwise
/// a register that deliberately skipped linking would read as OFFLINE
/// (spec 03 R4).
class SyncStatusChip extends ConsumerWidget {
  const SyncStatusChip({
    super.key,
    required this.service,
  });

  final SyncStatusService service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(authControllerProvider); // rebuild when standalone → linked
    if (ref.read(authControllerProvider.notifier).isStandalone) {
      return _standalonePill(context);
    }
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

  /// Neutral pill for standalone mode — no dot-tier, no tap-through to the
  /// sync sheet (there is nothing to sync). Grey styling matches the "not
  /// syncing" tier so it reads as calm, not error.
  Widget _standalonePill(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0x38B0BEC5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.cloud_off_rounded, size: 11, color: Color(0xFF837B6D)),
        const SizedBox(width: 4),
        Text(
          l.syncStandalone.toUpperCase(),
          style: Hifi.ui(
            size: 11,
            weight: FontWeight.w600,
            color: const Color(0xFF837B6D),
          ).copyWith(letterSpacing: 0.3),
        ),
      ]),
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
        return const Color(0xFFB6781A);
      case SyncStatusTier.red:
        return Hifi.chromeOffline;
      case SyncStatusTier.grey:
      case null:
        return const Color(0xFF837B6D);
    }
  }
}
