import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

class DebtsScreen extends StatefulWidget {
  final ApiClient api;
  final String cashierId;
  const DebtsScreen({super.key, required this.api, required this.cashierId});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _debts = [];
  List<Map<String, dynamic>> _clients = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final debtsResp = await widget.api.listDebts();
      final clientsResp = await widget.api.listClients();
      setState(() {
        _debts = (debtsResp['debts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _clients = (clientsResp['clients'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        _loading = false;
      });
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: ${e is ApiException ? "Сервер недоступен" : "Нет связи"}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);

    final openDebts = _debts.where((d) => d['Status'] != 'closed').toList();
    final totalDebt = openDebts.fold<int>(
        0, (sum, d) => sum + ((d['Amount'] as num?)?.toInt() ?? 0) - ((d['PaidAmount'] as num?)?.toInt() ?? 0));
    final clientCount = <String>{};
    for (final d in openDebts) {
      final cid = d['ClientID'] as String?;
      if (cid != null) clientCount.add(cid);
    }

    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(l.debtsTitle, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(l.debtsCountLabel(openDebts.length, clientCount.length),
                              style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant)),
                        ]),
                      ),
                      Row(children: [
                        IconButton(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 22),
                          tooltip: l.refresh,
                          style: IconButton.styleFrom(
                            backgroundColor: cs.surfaceContainerLow,
                            fixedSize: const Size(48, 48),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => _showCreateDebtDialog(context),
                            icon: const Icon(Icons.add_rounded, size: 20),
                            label: Text(l.debtsNewDebt, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ]),
                    ]),
                  ),
                ),

                // Total debt banner
                if (totalDebt > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              pos.errorFg,
                              pos.errorFg.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(
                                l.debtsTotalBanner,
                                style: GoogleFonts.inter(
                                  fontSize: 11, fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Money.format(totalDebt),
                                style: GoogleFonts.inter(
                                  fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5,
                                ),
                              ),
                            ]),
                          ),
                          Column(children: [
                            Text(
                              '${openDebts.length}',
                              style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            Text(
                              l.debtsRecordsLabel,
                              style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withValues(alpha: 0.7)),
                            ),
                          ]),
                        ]),
                      ),
                    ),
                  ),

                // Search
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: TextField(
                      onChanged: (v) => setState(() => _search = v),
                      decoration: InputDecoration(
                        hintText: l.debtsSearch,
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                ),

                // Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        onTap: (_) => setState(() {}),
                        tabs: [
                          Tab(text: l.debtsTabOpen(openDebts.length)),
                          Tab(text: l.debtsTabAll(_debts.length)),
                        ],
                      ),
                    ),
                  ),
                ),

                // Debt rows
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: _buildDebtSliver(
                    _filterDebts(_tabController.index == 0 ? openDebts : _debts),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  List<Map<String, dynamic>> _filterDebts(List<Map<String, dynamic>> debts) {
    if (_search.isEmpty) return debts;
    final q = _search.toLowerCase();
    return debts.where((d) {
      final name = (d['ClientName'] as String? ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  Widget _buildDebtSliver(List<Map<String, dynamic>> debts) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    if (debts.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 60),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          ),
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.account_balance_wallet_outlined, size: 32, color: cs.outline),
              ),
              const SizedBox(height: 16),
              Text(l.debtsEmpty, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, i) => _DebtRow(
          debt: debts[i],
          index: i,
          isLast: i == debts.length - 1,
          onPay: () {
            final d = debts[i];
            final amount = (d['Amount'] as num?)?.toInt() ?? 0;
            final paid = (d['PaidAmount'] as num?)?.toInt() ?? 0;
            _showPayDialog(context, d['ID'] as String, amount - paid);
          },
        ),
        childCount: debts.length,
      ),
    );
  }

  void _showPayDialog(BuildContext context, String debtId, int remainingTiyin) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final amountC = TextEditingController(text: Money.tiyinToTenge(remainingTiyin).toStringAsFixed(0));
    bool submitting = false;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.debtsPayTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(12)),
              child: Text(l.debtsPayRemaining(Money.format(remainingTiyin)), style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountC,
              decoration: InputDecoration(labelText: l.debtsFieldAmount),
              keyboardType: TextInputType.number,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      final amount = ((double.tryParse(amountC.text) ?? 0) * 100).round();
                      if (amount <= 0) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.debtsEnterAmount)));
                        }
                        return;
                      }
                      setDialogState(() => submitting = true);
                      try {
                        await widget.api.payDebt(debtId, {
                          'amount': amount,
                          'payment_type': 'cash',
                          'cashier_id': widget.cashierId,
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) await _load();
                      } on Exception catch (e) {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.success, foregroundColor: Colors.white),
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.debtsPay),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDebtDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final amountC = TextEditingController();
    final noteC = TextEditingController();
    String? selectedClientId;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.debtsCreateTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l.debtsFieldClient),
                items: _clients
                    .map((c) => DropdownMenuItem(value: c['ID'] as String, child: Text(c['Name'] as String? ?? '')))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedClientId = v),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: amountC,
                decoration: InputDecoration(labelText: l.debtsFieldAmount),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              TextField(controller: noteC, decoration: InputDecoration(labelText: l.debtsFieldNote)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () async {
                if (selectedClientId == null) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.debtsSelectClient)));
                  }
                  return;
                }
                final amount = ((double.tryParse(amountC.text) ?? 0) * 100).round();
                if (amount <= 0) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.debtsEnterAmount)));
                  }
                  return;
                }
                try {
                  await widget.api.createDebt({
                    'client_id': selectedClientId,
                    'amount': amount,
                    'note': noteC.text,
                    'cashier_id': widget.cashierId,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) await _load();
                } on Exception catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
                  }
                }
              },
              child: Text(l.debtsRecord),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  final Map<String, dynamic> debt;
  final int index;
  final bool isLast;
  final VoidCallback onPay;

  const _DebtRow({required this.debt, required this.index, required this.isLast, required this.onPay});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final amount = (debt['Amount'] as num?)?.toInt() ?? 0;
    final paid = (debt['PaidAmount'] as num?)?.toInt() ?? 0;
    final remaining = amount - paid;
    final status = debt['Status'] as String? ?? 'open';
    final isClosed = status == 'closed';
    final note = debt['Note'] as String? ?? '';
    final progress = amount > 0 ? paid / amount : 0.0;
    final createdAt = debt['CreatedAt'] as String? ?? '';

    // Calculate days since creation for "overdue" hint
    int daysSinceCreation = 0;
    try {
      final dt = DateTime.parse(createdAt);
      daysSinceCreation = DateTime.now().difference(dt).inDays;
    } on FormatException catch (_) {}
    final isOverdue = !isClosed && daysSinceCreation > 30;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: index.isEven ? cs.surfaceContainerLowest : cs.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(20)) : null,
      ),
      child: Column(children: [
        Row(children: [
          // Status icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isClosed ? pos.successBg : pos.errorBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isClosed ? Icons.check_rounded : Icons.warning_amber_rounded,
              size: 20,
              color: isClosed ? pos.successFg : pos.errorFg,
            ),
          ),
          const SizedBox(width: 14),

          // Client + note + overdue
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                debt['ClientName'] as String? ?? l.debtsClientDefault,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              if (isOverdue)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: pos.errorBg, borderRadius: BorderRadius.circular(6)),
                    child: Text(
                      '${l.debtsOverdue} ($daysSinceCreation ${l.debtsRemainingAmount})',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: pos.errorFg),
                    ),
                  ),
                ),
              if (note.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(note, style: GoogleFonts.inter(fontSize: 12, fontStyle: FontStyle.italic, color: cs.outline)),
                ),
            ]),
          ),

          // Amount + action
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              isClosed ? Money.format(amount) : Money.format(remaining),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isClosed ? pos.successFg : pos.errorFg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              isClosed ? l.debtsPaid : l.debtsOfTotal(Money.format(amount)),
              style: GoogleFonts.inter(fontSize: 11, color: cs.outline),
            ),
          ]),
          const SizedBox(width: 12),

          if (!isClosed)
            SizedBox(
              height: 36,
              child: ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(l.debtsPayment, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: pos.successBg, borderRadius: BorderRadius.circular(20)),
              child: Text(l.debtsClosed, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: pos.successFg)),
            ),
        ]),

        // Progress bar
        if (!isClosed && paid > 0) ...[
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: cs.surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(pos.successFg),
            ),
          ),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(l.debtsPaidLabel(Money.format(paid)), style: GoogleFonts.inter(fontSize: 11, color: cs.outline)),
            Text('${(progress * 100).toStringAsFixed(0)}%', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: pos.successFg)),
          ]),
        ],
      ]),
    );
  }
}
