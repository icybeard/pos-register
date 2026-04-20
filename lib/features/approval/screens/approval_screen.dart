import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

class ApprovalScreen extends StatefulWidget {
  final ApiClient api;
  final String reviewerId;
  final String reviewerName;
  final VoidCallback onCountChanged;

  const ApprovalScreen({
    super.key,
    required this.api,
    required this.reviewerId,
    required this.reviewerName,
    required this.onCountChanged,
  });

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  List<dynamic> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await widget.api.listPendingProducts(limit: 100);
      if (mounted) {
        setState(() {
          _products = (resp['products'] as List?) ?? [];
          _loading = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _approve(Map<String, dynamic> product) async {
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) => _ApproveDialog(product: product),
    );
    if (result == null || !mounted) return;

    try {
      await widget.api.approveProduct(
        product['id'] as String,
        reviewerId: widget.reviewerId,
        reviewerName: widget.reviewerName,
        name: result['name'] as String?,
        salePrice: result['sale_price'] as int?,
      );
      await _load();
      widget.onCountChanged();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.approvalApproved, style: GoogleFonts.inter()),
            backgroundColor: PosColors.of(context).successFg,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorPrefix(e.toString())), backgroundColor: PosColors.of(context).errorFg),
        );
      }
    }
  }

  Future<void> _reject(Map<String, dynamic> product) async {
    final note = await showDialog<String?>(
      context: context,
      builder: (ctx) => _RejectDialog(productName: product['name'] as String? ?? ''),
    );
    if (note == null || !mounted) return;

    try {
      await widget.api.rejectProduct(
        product['id'] as String,
        reviewerId: widget.reviewerId,
        reviewerName: widget.reviewerName,
        note: note,
      );
      await _load();
      widget.onCountChanged();
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.approvalRejected, style: GoogleFonts.inter()),
            backgroundColor: PosColors.of(context).warningFg,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorPrefix(e.toString())), backgroundColor: PosColors.of(context).errorFg),
        );
      }
    }
  }

  Future<void> _showBatchApproveDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final markupCtrl = TextEditingController(text: '30');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.approvalBatchApprove, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.approvalBatchCount(_products.length), style: GoogleFonts.inter(fontSize: 14)),
          const SizedBox(height: 16),
          TextField(
            controller: markupCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l.approvalDefaultMarkup,
              suffixText: '%',
              prefixIcon: const Icon(Icons.percent),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.approvalBatchApprove),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final markup = (double.tryParse(markupCtrl.text) ?? 30) / 100;
    int approved = 0;
    for (final p in List<dynamic>.from(_products)) {
      final product = p as Map<String, dynamic>;
      final purchasePrice = (product['purchase_price'] as num?)?.toInt() ?? (product['sale_price'] as num?)?.toInt() ?? 0;
      final salePrice = purchasePrice > 0 ? (purchasePrice * (1 + markup)).round() : purchasePrice;
      try {
        await widget.api.approveProduct(
          product['id'] as String,
          reviewerId: widget.reviewerId,
          reviewerName: widget.reviewerName,
          salePrice: salePrice > 0 ? salePrice : null,
        );
        approved++;
      } on Exception catch (_) {}
    }
    await _load();
    widget.onCountChanged();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.approvalBatchCount(approved)),
        backgroundColor: PosColors.of(context).successFg,
      ),
    );
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
                Text(l.approvalTitle,
                  style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(l.approvalSubtitle,
                  style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant)),
              ])),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
            ]),
          )),

          // Batch approve button
          if (!_loading && _products.isNotEmpty)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () => _showBatchApproveDialog(context),
                  icon: const Icon(Icons.done_all_rounded, size: 18),
                  label: Text(
                    l.approvalBatchCount(_products.length),
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PosColors.of(context).successFg,
                    side: BorderSide(color: PosColors.of(context).successFg.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            )),

          if (_loading)
            const SliverFillRemaining(child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)))
          else if (_products.isEmpty)
            SliverFillRemaining(
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline_rounded, size: 64, color: PosColors.of(context).successFg),
                const SizedBox(height: 16),
                Text(l.approvalEmpty,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
              ])),
            )
          else
            SliverList(delegate: SliverChildBuilderDelegate(
              (ctx, i) => _PendingCard(
                product: _products[i] as Map<String, dynamic>,
                onApprove: () => _approve(_products[i] as Map<String, dynamic>),
                onReject: () => _reject(_products[i] as Map<String, dynamic>),
              ),
              childCount: _products.length,
            )),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingCard({required this.product, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final name = product['name'] as String? ?? '—';
    final barcode = product['barcode'] as String? ?? '—';
    final ntin = product['ntin'] as String? ?? '—';
    final submittedBy = product['submitted_by'] as String? ?? '—';
    final salePrice = (product['sale_price'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 16, offset: Offset(0, 4))],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: pos.warningBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(l.approvalPending, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: pos.warningFg, letterSpacing: 0.8)),
              ),
              const Spacer(),
              Text(l.approvalFrom(submittedBy), style: GoogleFonts.inter(fontSize: 12, color: cs.outline)),
            ]),
            const SizedBox(height: 10),
            Text(name, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            _InfoRow(label: l.approvalBarcode, value: barcode),
            _InfoRow(label: l.approvalNtin, value: ntin),
            _InfoRow(label: l.approvalSalePrice, value: Money.format(salePrice)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: onReject,
                icon: Icon(Icons.close_rounded, size: 16, color: pos.errorFg),
                label: Text(l.approvalReject, style: GoogleFonts.inter(color: pos.errorFg, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: pos.errorFg.withValues(alpha: 0.4))),
              )),
              const SizedBox(width: 10),
              Expanded(child: FilledButton.icon(
                onPressed: onApprove,
                icon: const Icon(Icons.check_rounded, size: 16),
                label: Text(l.approvalApprove, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(width: 100, child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: cs.outline))),
        Expanded(child: Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialogs
// ---------------------------------------------------------------------------

class _ApproveDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  const _ApproveDialog({required this.product});

  @override
  State<_ApproveDialog> createState() => _ApproveDialogState();
}

class _ApproveDialogState extends State<_ApproveDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _priceCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product['name'] as String? ?? '');
    final price = (widget.product['sale_price'] as num?)?.toInt() ?? 0;
    _priceCtrl = TextEditingController(text: price > 0 ? '$price' : '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.approvalApproveTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(
          controller: _nameCtrl,
          decoration: InputDecoration(
            labelText: l.approvalFieldName,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _priceCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l.approvalFieldPrice,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            final price = int.tryParse(_priceCtrl.text.trim());
            Navigator.pop(context, {
              'name': name.isNotEmpty ? name : null,
              'sale_price': price,
            });
          },
          child: Text(l.approvalApprove),
        ),
      ],
    );
  }
}

class _RejectDialog extends StatefulWidget {
  final String productName;
  const _RejectDialog({required this.productName});

  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}

class _RejectDialogState extends State<_RejectDialog> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l.approvalRejectTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('«${widget.productName}»', style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        const SizedBox(height: 12),
        TextField(
          controller: _noteCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: l.approvalRejectReason,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        FilledButton(
          onPressed: () => Navigator.pop(context, _noteCtrl.text.trim()),
          style: FilledButton.styleFrom(backgroundColor: PosColors.of(context).errorFg),
          child: Text(l.approvalReject),
        ),
      ],
    );
  }
}
