import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/api_client.dart';

class AuditScreen extends StatefulWidget {
  final ApiClient api;
  const AuditScreen({super.key, required this.api});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> {
  List<dynamic> _entries = [];
  int _total = 0;
  bool _loading = true;
  int _offset = 0;
  static const _limit = 50;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool reset = true}) async {
    if (reset) _offset = 0;
    setState(() => _loading = true);
    try {
      final resp = await widget.api.listAuditLog(limit: _limit, offset: _offset);
      if (mounted) {
        setState(() {
          _entries = reset
              ? ((resp['entries'] as List?) ?? [])
              : [..._entries, ...((resp['entries'] as List?) ?? [])];
          _total = (resp['total'] as num?)?.toInt() ?? 0;
          _loading = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    _offset += _limit;
    await _load(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.auditTitle,
                  style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(l.auditTotalLabel(_total),
                  style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant)),
              ])),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
            ]),
          )),

          if (_loading && _entries.isEmpty)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)))
          else if (_entries.isEmpty)
            SliverFillRemaining(
              child: Center(child: Text(l.auditEmpty, style: TextStyle(fontFamily: 'Inter', color: cs.outline))),
            )
          else ...[
            SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => _AuditRow(entry: _entries[i] as Map<String, dynamic>),
              childCount: _entries.length,
            )),
            if (_entries.length < _total)
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(child: TextButton(
                  onPressed: _loadMore,
                  child: Text(l.loadMore, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                )),
              )),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }
}

class _AuditRow extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _AuditRow({required this.entry});

  void _showDetailDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final action = entry['action'] as String? ?? '';
    final cashierName = entry['cashier_name'] as String? ?? '—';
    final entityType = entry['entity_type'] as String? ?? '';
    final entityId = entry['entity_id'] as String? ?? '';
    final details = entry['details'] as String? ?? '';
    final createdAt = entry['created_at'] as String? ?? '';

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _actionColor(action, context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_actionIcon(action), size: 18, color: _actionColor(action, context)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(_actionLabel(action, context), style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700, fontSize: 16))),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          _DetailLine('Время', _formatDate(createdAt).replaceAll('\n', ' ')),
          const SizedBox(height: 8),
          _DetailLine('Кассир', cashierName),
          const SizedBox(height: 8),
          _DetailLine('Объект', '$entityType ($entityId)'),
          if (details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(details, style: const TextStyle(fontFamily: 'Inter', fontSize: 13)),
            ),
          ],
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.close)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final action = entry['action'] as String? ?? '';
    final cashierName = entry['cashier_name'] as String? ?? '—';
    final entityType = entry['entity_type'] as String? ?? '';
    final details = entry['details'] as String? ?? '';
    final createdAt = entry['created_at'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () => _showDetailDialog(context),
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _actionColor(action, context).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_actionIcon(action), size: 18, color: _actionColor(action, context)),
          ),
          title: Text(
            _actionLabel(action, context),
            style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
          ),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$cashierName · $entityType',
              style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: cs.onSurfaceVariant)),
            if (details.isNotEmpty)
              Text(details, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.outline),
                maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
          trailing: Text(
            _formatDate(createdAt),
            style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.outline),
          ),
        ),
      ),
    );
  }

  Color _actionColor(String action, BuildContext context) {
    final pos = PosColors.of(context);
    return switch (action) {
      'receipt_created'  => pos.successFg,
      'shift_opened'     => pos.accentFg,
      'shift_closed'     => pos.accentFg,
      'nkt_approved'     => pos.successFg,
      'nkt_rejected'     => pos.errorFg,
      'product_deleted'  => pos.errorFg,
      'debt_created'     => pos.warningFg,
      'debt_paid'        => pos.successFg,
      'delivery_received'=> pos.accentFg,
      _                  => pos.accentFg,
    };
  }

  IconData _actionIcon(String action) => switch (action) {
    'receipt_created'   => Icons.receipt_rounded,
    'shift_opened'      => Icons.lock_open_rounded,
    'shift_closed'      => Icons.lock_rounded,
    'nkt_approved'      => Icons.verified_rounded,
    'nkt_rejected'      => Icons.cancel_rounded,
    'product_created'   => Icons.add_box_rounded,
    'product_edited'    => Icons.edit_rounded,
    'product_deleted'   => Icons.delete_rounded,
    'debt_created'      => Icons.money_off_rounded,
    'debt_paid'         => Icons.payments_rounded,
    'cashier_created'   => Icons.person_add_rounded,
    'delivery_received' => Icons.local_shipping_rounded,
    _                   => Icons.info_outline_rounded,
  };

  String _actionLabel(String action, BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return switch (action) {
      'receipt_created'   => l.auditActionReceiptCreated,
      'shift_opened'      => l.auditActionShiftOpened,
      'shift_closed'      => l.auditActionShiftClosed,
      'nkt_approved'      => l.auditActionNktApproved,
      'nkt_rejected'      => l.auditActionNktRejected,
      'product_created'   => l.auditActionProductCreated,
      'product_edited'    => l.auditActionProductEdited,
      'product_deleted'   => l.auditActionProductDeleted,
      'debt_created'      => l.auditActionDebtCreated,
      'debt_paid'         => l.auditActionDebtPaid,
      'cashier_created'   => l.auditActionCashierCreated,
      'delivery_received' => l.auditActionDeliveryReceived,
      _                   => action,
    };
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final d = dt.day.toString().padLeft(2, '0');
      final mo = dt.month.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final mi = dt.minute.toString().padLeft(2, '0');
      return '$d.$mo ${dt.year}\n$h:$mi';
    } on Exception catch (_) {
      return iso;
    }
  }
}

class _DetailLine extends StatelessWidget {
  final String label;
  final String value;
  const _DetailLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: cs.outline))),
      Expanded(child: Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600))),
    ]);
  }
}
