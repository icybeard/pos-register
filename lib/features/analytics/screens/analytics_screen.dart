import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

class AnalyticsScreen extends StatefulWidget {
  final ApiClient api;
  const AnalyticsScreen({super.key, required this.api});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _sales;
  List<dynamic>? _topProducts;
  Map<String, dynamic>? _payments;
  List<dynamic>? _alerts;
  Map<String, dynamic>? _debts;
  List<dynamic>? _cashiers;
  List<dynamic>? _revenueByProduct;
  int _avgReceiptTiyin = 0;
  int _avgReceiptCount = 0;
  bool _loading = true;
  bool _autoRefresh = false;
  Timer? _refreshTimer;

  // Date range for cashier performance & revenue by product
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _toggleAutoRefresh(bool value) {
    setState(() => _autoRefresh = value);
    _refreshTimer?.cancel();
    if (value) {
      _refreshTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    if (_loading && _sales != null) return; // avoid double-load on auto-refresh
    setState(() => _loading = _sales == null); // only show spinner on first load
    try {
      final dateFrom = _dateRange?.start.toIso8601String().substring(0, 10);
      final dateTo = _dateRange?.end.toIso8601String().substring(0, 10);
      final results = await Future.wait([
        widget.api.getSalesSummary(),
        widget.api.getTopProducts(),
        widget.api.getPaymentBreakdown(),
        widget.api.getInventoryAlerts(),
        widget.api.getDebtSummary(),
        widget.api.getCashierPerformance(dateFrom: dateFrom, dateTo: dateTo),
        widget.api.getAverageReceipt(),
        widget.api.getRevenueByProduct(dateFrom: dateFrom, dateTo: dateTo, limit: 20),
      ]);
      if (mounted) {
        final avgData = results[6];
        setState(() {
          _sales = results[0];
          _topProducts = (results[1]['products'] as List?) ?? [];
          _payments = results[2];
          _alerts = (results[3]['alerts'] as List?) ?? [];
          _debts = results[4];
          _cashiers = (results[5]['cashiers'] as List?) ?? [];
          _avgReceiptTiyin = (avgData['average'] as num?)?.toInt() ?? 0;
          _avgReceiptCount = (avgData['count'] as num?)?.toInt() ?? 0;
          _revenueByProduct = (results[7]['products'] as List?) ?? [];
          _loading = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showExportDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final reports = <String, String>{
      'sales': l.analyticsTitle,
      'products': l.analyticsTopProducts,
      'revenue-by-product': l.analyticsRevenueByProduct,
      'cashier-performance': l.analyticsCashiers,
      'debts': l.analyticsDebts,
      'audit-log': l.analyticsTitle,
    };
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(l.analyticsExport, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ),
          ...reports.entries.map((e) => ListTile(
            leading: const Icon(Icons.table_chart_rounded),
            title: Text(e.value),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              TextButton(
                onPressed: () { Navigator.pop(ctx); _doExport(e.key, 'xlsx'); },
                child: const Text('XLSX'),
              ),
              TextButton(
                onPressed: () { Navigator.pop(ctx); _doExport(e.key, 'csv'); },
                child: const Text('CSV'),
              ),
            ]),
          )),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _doExport(String reportType, String format) async {
    try {
      final dateFrom = _dateRange?.start.toIso8601String().substring(0, 10);
      final dateTo = _dateRange?.end.toIso8601String().substring(0, 10);
      final bytes = await widget.api.exportReport(reportType, format: format, dateFrom: dateFrom, dateTo: dateTo);
      final dir = Directory.systemTemp;
      final file = File('${dir.path}/${reportType}_${DateTime.now().millisecondsSinceEpoch}.$format');
      await file.writeAsBytes(bytes);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppLocalizations.of(context)!.analyticsExportSuccess}: ${file.path}'),
        ));
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(strokeWidth: 2.5)));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(slivers: [
          // Header
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.analyticsTitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(l.analyticsSubtitle, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant)),
              ])),
              // Auto-refresh toggle
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text(l.analyticsAutoRefresh, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.outline)),
                const SizedBox(width: 4),
                SizedBox(
                  height: 28,
                  child: Switch.adaptive(
                    value: _autoRefresh,
                    onChanged: _toggleAutoRefresh,
                    activeThumbColor: pos.successFg,
                    activeTrackColor: pos.successFg.withValues(alpha: 0.3),
                  ),
                ),
              ]),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _showExportDialog(context),
                icon: const Icon(Icons.download_rounded),
                tooltip: l.analyticsExport,
              ),
              const SizedBox(width: 4),
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded), tooltip: l.refresh),
            ]),
          )),

          // Sales summary cards
          if (_sales != null) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: LayoutBuilder(builder: (context, constraints) {
              final cards = [
                _StatCard(label: l.analyticsToday, value: Money.format((_sales!['today_total'] as num?)?.toInt() ?? 0),
                  sub: '${_sales!['today_count'] ?? 0} ${l.analyticsReceipts}', color: pos.successFg),
                _StatCard(label: l.analyticsYesterday, value: Money.format((_sales!['yesterday_total'] as num?)?.toInt() ?? 0),
                  sub: '${_sales!['yesterday_count'] ?? 0} ${l.analyticsReceipts}', color: pos.accentFg),
                _StatCard(label: l.analyticsWeek, value: Money.format((_sales!['week_total'] as num?)?.toInt() ?? 0),
                  sub: '${_sales!['week_count'] ?? 0} ${l.analyticsReceipts}', color: pos.warningFg),
                _StatCard(label: l.analyticsMonth, value: Money.format((_sales!['month_total'] as num?)?.toInt() ?? 0),
                  sub: '${_sales!['month_count'] ?? 0} ${l.analyticsReceipts}', color: AppTheme.primary),
              ];
              if (constraints.maxWidth >= 600) {
                return Row(children: [for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: cards[i])]]);
              }
              return Column(children: [
                Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
                const SizedBox(height: 12),
                Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
              ]);
            }),
          )),

          // Average receipt card
          if (_avgReceiptTiyin > 0) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [cs.primary, AppTheme.primaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(l.analyticsAvgReceipt, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(Money.format(_avgReceiptTiyin), style: const TextStyle(fontFamily: 'Inter', fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                ])),
                Column(children: [
                  Text('$_avgReceiptCount', style: const TextStyle(fontFamily: 'Inter', fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text(l.analyticsReceipts, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
                ]),
              ]),
            ),
          )),

          // Payment breakdown
          if (_payments != null) SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: _SectionCard(title: l.analyticsPaymentTypes, child: _PaymentBars(payments: _payments!)),
          )),

          // Top products + Cashier performance side by side
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: LayoutBuilder(builder: (context, constraints) {
              final topCard = _SectionCard(
                title: l.analyticsTopProducts,
                child: _topProducts != null && _topProducts!.isNotEmpty
                    ? Column(children: _topProducts!.take(5).map((p) => _TopProductRow(product: p)).toList())
                    : Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(l.noData, style: TextStyle(fontFamily: 'Inter', color: cs.outline)))),
              );
              final cashierCard = _SectionCard(
                title: l.analyticsCashiers,
                child: _cashiers != null && _cashiers!.isNotEmpty
                    ? Column(children: _cashiers!.take(5).map((c) => _CashierRow(cashier: c)).toList())
                    : Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(l.noData, style: TextStyle(fontFamily: 'Inter', color: cs.outline)))),
              );
              if (constraints.maxWidth >= 700) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: topCard),
                  const SizedBox(width: 16),
                  Expanded(child: cashierCard),
                ]);
              }
              return Column(children: [topCard, const SizedBox(height: 16), cashierCard]);
            }),
          )),

          // Date range picker + Revenue by product
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Date range filter
              Row(children: [
                Icon(Icons.date_range_rounded, size: 18, color: cs.outline),
                const SizedBox(width: 8),
                Text(l.analyticsDateRange, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                ActionChip(
                  label: Text(_dateRange != null
                    ? '${_dateRange!.start.day.toString().padLeft(2, '0')}.${_dateRange!.start.month.toString().padLeft(2, '0')} — ${_dateRange!.end.day.toString().padLeft(2, '0')}.${_dateRange!.end.month.toString().padLeft(2, '0')}'
                    : l.analyticsAllTime,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12)),
                  onPressed: () async {
                    final range = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      initialDateRange: _dateRange,
                    );
                    if (range != null) {
                      setState(() => _dateRange = range);
                      unawaited(_load());
                    }
                  },
                ),
                if (_dateRange != null) ...[
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
                    onPressed: () { setState(() => _dateRange = null); unawaited(_load()); },
                    tooltip: l.analyticsClearFilter,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ]),
              const SizedBox(height: 12),
              // Revenue by product table
              _SectionCard(
                title: l.analyticsRevenueByProduct,
                child: _revenueByProduct != null && _revenueByProduct!.isNotEmpty
                    ? Column(children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          child: Row(children: [
                            Expanded(flex: 3, child: Text(l.analyticsProductName, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: cs.outline))),
                            Expanded(flex: 1, child: Text(l.analyticsQty, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: cs.outline), textAlign: TextAlign.right)),
                            Expanded(flex: 2, child: Text(l.analyticsRevenue, style: TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: cs.outline), textAlign: TextAlign.right)),
                          ]),
                        ),
                        const Divider(height: 1),
                        ..._revenueByProduct!.take(15).map((p) => _RevenueProductRow(product: p)),
                      ])
                    : Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(l.noData, style: TextStyle(fontFamily: 'Inter', color: cs.outline)))),
              ),
            ]),
          )),

          // Inventory alerts + Debt summary
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: LayoutBuilder(builder: (context, constraints) {
              final alertCard = _SectionCard(
                title: l.analyticsLowStock,
                child: _alerts != null && _alerts!.isNotEmpty
                    ? Column(children: _alerts!.take(8).map((a) => _AlertRow(alert: a)).toList())
                    : Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(l.analyticsAllNormal, style: TextStyle(fontFamily: 'Inter', color: pos.successFg)))),
              );
              final debtCard = _SectionCard(
                title: l.analyticsDebts,
                child: _debts != null
                    ? Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                        _DebtLine(label: l.analyticsOpenDebts, value: '${_debts!['open_count'] ?? 0}'),
                        const SizedBox(height: 8),
                        _DebtLine(label: l.analyticsToPayDebts, value: Money.format((_debts!['total_outstanding'] as num?)?.toInt() ?? 0), color: pos.errorFg),
                        const SizedBox(height: 8),
                        _DebtLine(label: l.analyticsPaidDebts, value: Money.format((_debts!['total_paid'] as num?)?.toInt() ?? 0), color: pos.successFg),
                      ]))
                    : const SizedBox.shrink(),
              );
              if (constraints.maxWidth >= 700) {
                return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: alertCard),
                  const SizedBox(width: 16),
                  Expanded(child: debtCard),
                ]);
              }
              return Column(children: [alertCard, const SizedBox(height: 16), debtCard]);
            }),
          )),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ]),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value, sub;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.trending_up_rounded, size: 17, color: color),
        ),
        const SizedBox(height: 12),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w700, color: cs.outline, letterSpacing: 0.8)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Text(title, style: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700)),
        ),
        child,
        const SizedBox(height: 8),
      ]),
    );
  }
}

class _PaymentBars extends StatelessWidget {
  final Map<String, dynamic> payments;
  const _PaymentBars({required this.payments});

  @override
  Widget build(BuildContext context) {
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final cash = (payments['cash'] as num?)?.toInt() ?? 0;
    final card = (payments['card'] as num?)?.toInt() ?? 0;
    final qr = (payments['qr'] as num?)?.toInt() ?? 0;
    final total = cash + card + qr;
    if (total == 0) return Padding(padding: const EdgeInsets.all(16), child: Text(l.noData, style: TextStyle(fontFamily: 'Inter', color: Theme.of(context).colorScheme.outline)));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(children: [
        _PaymentBar(label: l.analyticsCash, value: cash, total: total, color: pos.successFg),
        const SizedBox(height: 8),
        _PaymentBar(label: l.analyticsCard, value: card, total: total, color: pos.accentFg),
        const SizedBox(height: 8),
        _PaymentBar(label: l.analyticsKaspiQR, value: qr, total: total, color: pos.warningFg),
      ]),
    );
  }
}

class _PaymentBar extends StatelessWidget {
  final String label;
  final int value, total;
  final Color color;
  const _PaymentBar({required this.label, required this.value, required this.total, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? value / total : 0.0;
    return Row(children: [
      SizedBox(width: 80, child: Text(label, style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500))),
      Expanded(child: Container(
        height: 20, decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft, widthFactor: pct,
          child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6))),
        ),
      )),
      const SizedBox(width: 8),
      SizedBox(width: 90, child: Text(Money.format(value), style: const TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
    ]);
  }
}

class _TopProductRow extends StatelessWidget {
  final dynamic product;
  const _TopProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final revenue = (product['total_revenue'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(children: [
        Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text(Money.format(revenue), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _CashierRow extends StatelessWidget {
  final dynamic cashier;
  const _CashierRow({required this.cashier});

  @override
  Widget build(BuildContext context) {
    final name = cashier['cashier_name'] as String? ?? '';
    final total = (cashier['total'] as num?)?.toInt() ?? 0;
    final count = (cashier['receipt_count'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(children: [
        Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500))),
        Text('$count ${AppLocalizations.of(context)!.analyticsReceipts}', style: TextStyle(fontFamily: 'Inter', fontSize: 11, color: Theme.of(context).colorScheme.outline)),
        const SizedBox(width: 12),
        Text(Money.format(total), style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _AlertRow extends StatelessWidget {
  final dynamic alert;
  const _AlertRow({required this.alert});

  @override
  Widget build(BuildContext context) {
    final pos = PosColors.of(context);
    final name = alert['name'] as String? ?? '';
    final qty = (alert['current_qty'] as num?)?.toDouble() ?? 0;
    final isZero = alert['is_zero'] == true;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Row(children: [
        Icon(isZero ? Icons.error_rounded : Icons.warning_rounded, size: 16, color: isZero ? pos.errorFg : pos.warningFg),
        const SizedBox(width: 8),
        Expanded(child: Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Text(qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1),
          style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700, color: isZero ? pos.errorFg : pos.warningFg)),
      ]),
    );
  }
}

class _RevenueProductRow extends StatelessWidget {
  final dynamic product;
  const _RevenueProductRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final name = product['name'] as String? ?? '';
    final qty = (product['quantity_sold'] as num?)?.toDouble() ?? 0;
    final revenue = (product['total_revenue'] as num?)?.toInt() ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      child: Row(children: [
        Expanded(flex: 3, child: Text(name, style: const TextStyle(fontFamily: 'Inter', fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
        Expanded(flex: 1, child: Text(qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w500), textAlign: TextAlign.right)),
        Expanded(flex: 2, child: Text(Money.format(revenue),
          style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w700), textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _DebtLine extends StatelessWidget {
  final String label, value;
  final Color? color;
  const _DebtLine({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]);
  }
}
