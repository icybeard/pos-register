import 'package:flutter/material.dart';

import '../../services/sync/sync_status_service.dart';
import '../../services/stock/stock_freshness_service.dart';
import '../theme/hifi.dart';

/// Modal bottom sheet with four rows explaining what the sync-status chip
/// in the top chrome is showing. Tapping the chip opens this sheet; the
/// user can trigger a manual refresh or dismiss.
///
/// Rows:
///   1. Связь — server reachability + host
///   2. Мастер-данные — pull freshness + age
///   3. Очередь — outbox pending + failed counts
///   4. Обновлено — snapshot timestamp
class SyncStatusSheet extends StatefulWidget {
  const SyncStatusSheet._({required this.service});

  final SyncStatusService service;

  /// Entry point — callers use this instead of constructing the widget
  /// directly so the modal routing stays encapsulated.
  static Future<void> show(BuildContext context, SyncStatusService service) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => SyncStatusSheet._(service: service),
    );
  }

  @override
  State<SyncStatusSheet> createState() => _SyncStatusSheetState();
}

class _SyncStatusSheetState extends State<SyncStatusSheet> {
  SyncStatusSnapshot? _snap;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _refreshing = true);
    final s = await widget.service.refresh();
    if (!mounted) return;
    setState(() {
      _snap = s;
      _refreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _handle(),
            const SizedBox(height: 12),
            Row(children: [
              Text(
                'Статус синхронизации',
                style: Hifi.ui(size: 18, weight: FontWeight.w700, color: Hifi.chrome),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refreshing ? null : _load,
                icon: _refreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                tooltip: 'Обновить',
              ),
            ]),
            const Divider(height: 24),
            if (_snap == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              _StatusRow(
                icon: _snap!.online ? Icons.cloud_done : Icons.cloud_off,
                iconColor: _snap!.online ? Hifi.success : Hifi.chromeOffline,
                title: 'Связь',
                body: _snap!.online
                    ? 'Сервер доступен'
                    : 'Нет связи с сервером',
              ),
              const SizedBox(height: 14),
              _StatusRow(
                icon: Icons.cloud_download,
                iconColor: _freshnessColor(_snap!.freshness.tier),
                title: 'Мастер-данные',
                body: _freshnessLabel(_snap!.freshness),
              ),
              const SizedBox(height: 14),
              _StatusRow(
                icon: Icons.upload_file,
                iconColor: _outboxColor(
                  _snap!.outboxPending,
                  _snap!.outboxFailed,
                ),
                title: 'Очередь на отправку',
                body: _outboxLabel(_snap!.outboxPending, _snap!.outboxFailed),
              ),
              const SizedBox(height: 14),
              _StatusRow(
                icon: Icons.access_time,
                iconColor: const Color(0xFF78909C),
                title: 'Обновлено',
                body: _updatedAgo(_snap!.checkedAt),
              ),
            ],
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Закрыть',
                  style: Hifi.ui(size: 14, weight: FontWeight.w600, color: Hifi.chrome),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _handle() => Center(
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFCCCCCC),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  // --- Row content builders ------------------------------------------------

  String _freshnessLabel(StockFreshnessSnapshot f) {
    switch (f.tier) {
      case StockFreshness.fresh:
        return 'Свежие · обновлено ${_fmtAge(f.age)} назад';
      case StockFreshness.stale:
        return 'Устаревают · ${_fmtAge(f.age)} без обновления';
      case StockFreshness.outdated:
        return 'Устарели · ${_fmtAge(f.age)} без обновления';
      case StockFreshness.unknown:
        return 'Ещё не синхронизированы';
    }
  }

  Color _freshnessColor(StockFreshness t) {
    switch (t) {
      case StockFreshness.fresh:
        return Hifi.success;
      case StockFreshness.stale:
        return const Color(0xFFE67E00);
      case StockFreshness.outdated:
        return Hifi.chromeOffline;
      case StockFreshness.unknown:
        return const Color(0xFF78909C);
    }
  }

  String _outboxLabel(int pending, int failed) {
    if (pending == 0 && failed == 0) return 'Очередь пуста';
    final parts = <String>[];
    if (pending > 0) parts.add('$pending ожидают');
    if (failed > 0) parts.add('$failed с ошибкой (повтор)');
    return parts.join(' · ');
  }

  Color _outboxColor(int pending, int failed) {
    if (failed > 0) return Hifi.chromeOffline;
    if (pending > 10) return Hifi.chromeOffline;
    if (pending > 0) return const Color(0xFFE67E00);
    return Hifi.success;
  }

  String _updatedAgo(DateTime ts) {
    final age = DateTime.now().toUtc().difference(ts.toUtc());
    return '${_fmtAge(age)} назад';
  }

  String _fmtAge(Duration d) {
    if (d.inSeconds < 1) return 'только что';
    if (d.inMinutes < 1) return '${d.inSeconds} с';
    if (d.inHours < 1) return '${d.inMinutes} мин';
    return '${d.inHours} ч';
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: iconColor, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            title,
            style: Hifi.ui(size: 12, weight: FontWeight.w600, color: const Color(0xFF666666)),
          ),
          const SizedBox(height: 2),
          Text(
            body,
            style: Hifi.ui(size: 14, weight: FontWeight.w500, color: Hifi.chrome),
          ),
        ]),
      ),
    ]);
  }
}
