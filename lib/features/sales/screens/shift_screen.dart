import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

class ShiftScreen extends StatefulWidget {
  final ApiClient api;
  final String cashierId;
  final String cashierName;
  final VoidCallback? onShiftChanged;
  const ShiftScreen({super.key, required this.api, required this.cashierId, required this.cashierName, this.onShiftChanged});

  @override
  State<ShiftScreen> createState() => _ShiftScreenState();
}

class _ShiftScreenState extends State<ShiftScreen> {
  Map<String, dynamic>? _shift;
  bool _loading = true;
  bool _hasShift = false;

  @override
  void initState() {
    super.initState();
    _loadShift();
  }

  Future<void> _loadShift() async {
    setState(() => _loading = true);
    try {
      final resp = await widget.api.getCurrentShift(widget.cashierId);
      setState(() {
        _shift = resp;
        _hasShift = true;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        setState(() {
          _shift = null;
          _hasShift = false;
          _loading = false;
        });
      }
    } on Exception catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
          : _hasShift
              ? _buildShiftDashboard(context)
              : _buildOpenShift(context),
    );
  }

  Widget _buildOpenShift(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final cashStartC = TextEditingController(text: '0');

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: pos.accentBg, borderRadius: BorderRadius.circular(24)),
              child: Icon(Icons.schedule_outlined, size: 40, color: pos.accentFg),
            ),
            const SizedBox(height: 24),
            Text(l.shiftNotOpened, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 8),
            Text(
              l.shiftCashierLabel(widget.cashierName),
              style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 15),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: cashStartC,
              decoration: InputDecoration(
                labelText: l.shiftCashInDrawer,
                prefixIcon: const Icon(Icons.payments_outlined),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final cashStart = ((double.tryParse(cashStartC.text) ?? 0) * 100).round();
                  try {
                    await widget.api.openShift(cashierId: widget.cashierId, cashStart: cashStart);
                    if (context.mounted) {
                      await _loadShift();
                      widget.onShiftChanged?.call();
                    }
                  } on Exception catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.errorPrefix(e.toString()))));
                    }
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.shiftOpen, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildShiftDashboard(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isWide = MediaQuery.of(context).size.width >= 800;
    final s = _shift!;
    final isOpen = s['Status'] == 'open';
    final totalSales = (s['TotalSales'] as num?)?.toInt() ?? 0;
    final totalReturns = (s['TotalReturns'] as num?)?.toInt() ?? 0;
    final totalCash = (s['TotalCash'] as num?)?.toInt() ?? 0;
    final totalCard = (s['TotalCard'] as num?)?.toInt() ?? 0;
    final totalQR = (s['TotalQR'] as num?)?.toInt() ?? 0;
    final receiptCount = (s['ReceiptCount'] as num?)?.toInt() ?? 0;
    final cashStart = (s['CashStart'] as num?)?.toInt() ?? 0;
    final expectedInDrawer = cashStart + totalCash - totalReturns;
    final shiftId = s['ID'] as String;

    // Check if shift is overdue (> 24 hours)
    bool isOverdue = false;
    if (isOpen) {
      try {
        final openedAt = DateTime.parse(s['OpenedAt'] as String? ?? '');
        isOverdue = DateTime.now().difference(openedAt).inHours >= 24;
      } on FormatException catch (_) {}
    }

    if (isWide && isOpen) {
      // Stitch V4 cash management split layout
      return Row(children: [
        // Left: Stats & denomination counting
        Expanded(child: _DenominationPanel(
          cashierName: widget.cashierName,
          shiftNumber: s['ShiftNumber']?.toString() ?? '',
          isOpen: isOpen,
          totalSales: totalSales,
          totalCash: totalCash,
          totalCard: totalCard,
          totalQR: totalQR,
          totalReturns: totalReturns,
          receiptCount: receiptCount,
          cashStart: cashStart,
        )),
        // Right: Shift summary sidebar
        SizedBox(
          width: 380,
          child: _ShiftSummarySidebar(
            cashStart: cashStart,
            totalCash: totalCash,
            totalReturns: totalReturns,
            expectedInDrawer: expectedInDrawer,
            isOpen: isOpen,
            shiftId: shiftId,
            isOverdue: isOverdue,
            api: widget.api,
            onRefresh: _loadShift,
            onClose: () async {
              try {
                await widget.api.closeShift(shiftId: s['ID'] as String);
                if (context.mounted) {
                  await _loadShift();
                  widget.onShiftChanged?.call();
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.errorPrefix(e.toString()))));
                }
              }
            },
          ),
        ),
      ]);
    }

    // Narrow / closed shift: scrollable dashboard
    return _NarrowShiftDashboard(
      shift: s,
      cashierName: widget.cashierName,
      isOpen: isOpen,
      totalSales: totalSales,
      totalCash: totalCash,
      totalCard: totalCard,
      totalQR: totalQR,
      totalReturns: totalReturns,
      receiptCount: receiptCount,
      cashStart: cashStart,
      expectedInDrawer: expectedInDrawer,
      onClose: isOpen ? () async {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.shiftCloseConfirmTitle),
            content: Text(l.shiftCloseConfirmBody),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
                child: Text(l.shiftCloseButton),
              ),
            ],
          ),
        );
        if (confirm == true) {
          try {
            await widget.api.closeShift(shiftId: s['ID'] as String);
            if (context.mounted) {
              await _loadShift();
              widget.onShiftChanged?.call();
            }
          } on Exception catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.errorPrefix(e.toString()))));
            }
          }
        }
      } : null,
    );
  }
}

/// Stitch V4 denomination counting panel (left side of split layout)
class _DenominationPanel extends StatelessWidget {
  final String cashierName, shiftNumber;
  final bool isOpen;
  final int totalSales, totalCash, totalCard, totalQR, totalReturns, receiptCount, cashStart;

  const _DenominationPanel({
    required this.cashierName, required this.shiftNumber, required this.isOpen,
    required this.totalSales, required this.totalCash, required this.totalCard,
    required this.totalQR, required this.totalReturns, required this.receiptCount,
    required this.cashStart,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;

    // KZT denominations: bills + coins
    final bills = [
      ('20 000 ₸', 2000000),
      ('10 000 ₸', 1000000),
      ('5 000 ₸', 500000),
      ('2 000 ₸', 200000),
      ('1 000 ₸', 100000),
      ('500 ₸', 50000),
    ];
    final coins = [
      ('200 ₸', 20000),
      ('100 ₸', 10000),
      ('50 ₸', 5000),
      ('20 ₸', 2000),
      ('10 ₸', 1000),
      ('5 ₸', 500),
    ];

    return Container(
      color: cs.surfaceContainerLow,
      child: CustomScrollView(slivers: [
        // Header with status
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: pos.successBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shield_rounded, size: 14, color: pos.successFg),
                  const SizedBox(width: 6),
                  Text(l.shiftOpened, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: pos.successFg)),
                ]),
              ),
              const SizedBox(width: 12),
              Text(l.shiftReconciliation, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface)),
            ]),
            const SizedBox(height: 20),
            Text(l.shiftCountCash, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppTheme.primary)),
            const SizedBox(height: 4),
            Text(l.shiftCountInstruction, style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant)),
          ]),
        )),

        // Bills grid
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _DenominationCard(label: bills[i].$1, isBill: true),
              childCount: bills.length,
            ),
          ),
        ),

        // Coins grid
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
          child: Text(l.shiftCoin, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF74777D), letterSpacing: 1.2)),
        )),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 1.15,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _DenominationCard(label: coins[i].$1, isBill: false),
              childCount: coins.length,
            ),
          ),
        ),

        // Skip denomination — enter total manually
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit_rounded, size: 16),
            label: Text(l.shiftSkipDenomination, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(foregroundColor: AppTheme.primaryContainer),
          ),
        )),

        // Payment breakdown stats
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Row(children: [
            Expanded(child: _ShiftStatCard(label: l.shiftStatCash, value: Money.format(totalCash), icon: Icons.payments_rounded, accentColor: pos.successFg)),
            const SizedBox(width: 12),
            Expanded(child: _ShiftStatCard(label: l.shiftStatCard, value: Money.format(totalCard), icon: Icons.credit_card_rounded, accentColor: pos.accentFg)),
            const SizedBox(width: 12),
            Expanded(child: _ShiftStatCard(label: l.shiftStatKaspiQR, value: Money.format(totalQR), icon: Icons.qr_code_rounded, accentColor: pos.warningFg)),
            const SizedBox(width: 12),
            Expanded(child: _ShiftStatCard(label: l.shiftStatReturns, value: Money.format(totalReturns), icon: Icons.undo_rounded, accentColor: pos.errorFg)),
          ]),
        )),
      ]),
    );
  }
}

/// Stitch V4 denomination counting card
class _DenominationCard extends StatelessWidget {
  final String label;
  final bool isBill;

  const _DenominationCard({required this.label, this.isBill = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primary)),
          ),
          Text(isBill ? l.shiftBanknote : l.shiftCoin,
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFF74777D), letterSpacing: 1)),
        ]),
        const Spacer(),
        // Input
        Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
          child: TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: cs.outlineVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(l.shiftSubtotal, style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
          Text('0 ₸', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ]),
      ]),
    );
  }
}

/// Stitch V4 shift summary sidebar (right side)
class _ShiftSummarySidebar extends StatelessWidget {
  final int cashStart, totalCash, totalReturns, expectedInDrawer;
  final bool isOpen;
  final bool isOverdue;
  final String shiftId;
  final ApiClient api;
  final VoidCallback onClose;
  final VoidCallback onRefresh;

  const _ShiftSummarySidebar({
    required this.cashStart, required this.totalCash, required this.totalReturns,
    required this.expectedInDrawer, required this.isOpen, required this.shiftId,
    required this.onClose, required this.isOverdue, required this.api,
    required this.onRefresh,
  });

  void _showCashDialog(BuildContext context, {required bool isDeposit}) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isDeposit ? l.shiftDeposit : l.shiftWithdraw, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l.shiftEnterAmount, suffixText: '₸'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(onPressed: () async {
            final tenge = double.tryParse(controller.text) ?? 0;
            final tiyin = (tenge * 100).round();
            if (tiyin <= 0) return;
            try {
              if (isDeposit) {
                await api.shiftDeposit(shiftId, tiyin);
              } else {
                await api.shiftWithdraw(shiftId, tiyin);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              onRefresh();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(isDeposit ? l.shiftDepositSuccess : l.shiftWithdrawSuccess),
                  backgroundColor: const Color(0xFF059669),
                ));
              }
            } on Exception catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
              }
            }
          }, child: Text(l.ok)),
        ],
      ),
    );
  }

  void _showReceiptList(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    List<Map<String, dynamic>> receipts = [];
    try {
      final resp = await api.listReceiptsByShift(shiftId);
      receipts = (resp['receipts'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    } on Exception catch (_) {}

    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shiftReceiptList, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 400,
          height: 400,
          child: receipts.isEmpty
              ? Center(child: Text(l.shiftNoReceipts, style: GoogleFonts.inter(color: const Color(0xFF74777D))))
              : ListView.separated(
                  itemCount: receipts.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = receipts[i];
                    final total = (r['Total'] as num?)?.toInt() ?? 0;
                    final number = (r['ReceiptNumber'] as num?)?.toInt() ?? 0;
                    final payType = r['PaymentType'] as String? ?? 'cash';
                    final isReturn = r['IsReturn'] as bool? ?? false;
                    return ListTile(
                      leading: Icon(
                        isReturn ? Icons.undo_rounded : Icons.receipt_outlined,
                        color: isReturn ? pos.errorFg : null,
                      ),
                      title: Text('${l.shiftReceiptList} #$number', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      subtitle: Text(payType),
                      trailing: Text(
                        '${isReturn ? "-" : ""}${Money.format(total)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: isReturn ? pos.errorFg : null),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
        ],
      ),
    );
  }

  void _showCloseDialog(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final noteC = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.shiftCloseConfirmTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.shiftCloseConfirmBody),
          const SizedBox(height: 16),
          TextField(
            controller: noteC,
            decoration: InputDecoration(
              labelText: l.shiftDiscrepancyNote,
              hintText: l.shiftEnterNote,
              prefixIcon: const Icon(Icons.note_outlined),
            ),
            maxLines: 2,
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: Text(l.shiftCloseButton),
          ),
        ],
      ),
    );
    if (confirm == true) onClose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;

    return Container(
      color: Colors.white,
      child: Column(children: [
        // 24h overdue warning
        if (isOverdue)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: pos.errorBg,
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 20, color: pos.errorFg),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.shiftOverdue24h, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: pos.errorFg)),
                Text(l.shiftOverdueWarning, style: GoogleFonts.inter(fontSize: 11, color: pos.errorFg)),
              ])),
            ]),
          ),

        // Summary header
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.shiftSummary, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const SizedBox(height: 24),
            _SummaryLine(icon: Icons.flight_takeoff_rounded, label: l.shiftStartBalance, value: Money.format(cashStart)),
            const SizedBox(height: 18),
            _SummaryLine(icon: Icons.payments_rounded, label: l.shiftCashSales, value: '+${Money.format(totalCash)}', valueColor: pos.successFg),
            const SizedBox(height: 18),
            _SummaryLine(icon: Icons.assignment_return_rounded, label: l.shiftReturnsPayouts, value: '-${Money.format(totalReturns)}', valueColor: pos.errorFg),

            // Action buttons: deposit / withdraw / receipts / X-report
            const SizedBox(height: 20),
            Row(children: [
              _ActionChip(
                icon: Icons.add_circle_outline,
                label: l.shiftDeposit,
                onTap: () => _showCashDialog(context, isDeposit: true),
                color: pos.successFg,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.remove_circle_outline,
                label: l.shiftWithdraw,
                onTap: () => _showCashDialog(context, isDeposit: false),
                color: pos.errorFg,
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              _ActionChip(
                icon: Icons.receipt_long_outlined,
                label: l.shiftReceiptList,
                onTap: () => _showReceiptList(context),
                color: pos.accentFg,
              ),
              const SizedBox(width: 8),
              _ActionChip(
                icon: Icons.summarize_outlined,
                label: l.shiftXReport,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.shiftPrintReport)),
                  );
                },
                color: pos.warningFg,
              ),
            ]),
          ]),
        ),

        // Expected & counted section
        Expanded(child: Container(
          color: const Color(0xFFF8FAFC),
          padding: const EdgeInsets.all(28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.shiftExpectedBalance, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF74777D), letterSpacing: 1.2)),
            const SizedBox(height: 4),
            Text(Money.format(expectedInDrawer),
              style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: AppTheme.primary)),
            const SizedBox(height: 24),

            // Total counted (from denomination inputs)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.shiftCounted, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF74777D), letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text('0 ₸', style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: const Color(0xFF004493))),
              ]),
            ),
            const SizedBox(height: 16),

            // Variance
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4), style: BorderStyle.solid, width: 2),
              ),
              child: Column(children: [
                Text(l.shiftDiscrepancy, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic)),
                const SizedBox(height: 4),
                Text('-${Money.format(expectedInDrawer)}',
                  style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.tertiary)),
              ]),
            ),
          ]),
        )),

        // Close shift + print report
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(children: [
            SizedBox(
              width: double.infinity,
              height: 60,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryContainer],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _showCloseDialog(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(l.shiftCloseButton, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 10),
                      const Icon(Icons.lock_rounded, size: 20, color: Colors.white),
                    ]),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l.shiftCloseFooter,
              style: GoogleFonts.inter(fontSize: 10, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      ]),
    );
  }
}

/// Small action chip button used in shift sidebar
class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({required this.icon, required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
            ]),
          ),
        ),
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;
  const _SummaryLine({required this.icon, required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(children: [
      Icon(icon, size: 16, color: cs.onSurfaceVariant),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant))),
      Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: valueColor)),
    ]);
  }
}

/// Narrow shift dashboard (mobile or closed shift)
class _NarrowShiftDashboard extends StatelessWidget {
  final Map<String, dynamic> shift;
  final String cashierName;
  final bool isOpen;
  final int totalSales, totalCash, totalCard, totalQR, totalReturns, receiptCount, cashStart, expectedInDrawer;
  final VoidCallback? onClose;

  const _NarrowShiftDashboard({
    required this.shift, required this.cashierName, required this.isOpen,
    required this.totalSales, required this.totalCash, required this.totalCard,
    required this.totalQR, required this.totalReturns, required this.receiptCount,
    required this.cashStart, required this.expectedInDrawer, this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;

    return CustomScrollView(slivers: [
      // Header
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.shiftLabel, style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(l.shiftCashierLabel(cashierName), style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isOpen ? pos.successBg : cs.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isOpen ? pos.successFg : cs.outline)),
              const SizedBox(width: 8),
              Text(isOpen ? 'Открыта' : 'Закрыта',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: isOpen ? pos.successFg : cs.outline)),
            ]),
          ),
        ]),
      )),

      // Shift hero card
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [cs.primary, AppTheme.primaryContainer], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.shiftNumber((shift['ShiftNumber'] as num?)?.toInt() ?? 0),
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white.withValues(alpha: 0.7), letterSpacing: 1)),
              const SizedBox(height: 4),
              Text(Money.format(totalSales),
                style: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1)),
            ])),
            Column(children: [
              Text('$receiptCount', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
              Text(l.shiftReceipts, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.7), fontWeight: FontWeight.w500)),
            ]),
          ]),
        ),
      )),

      // Stat cards
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: LayoutBuilder(builder: (context, constraints) {
          final cards = [
            _ShiftStatCard(label: l.shiftStatCash, value: Money.format(totalCash), icon: Icons.payments_rounded, accentColor: pos.successFg),
            _ShiftStatCard(label: l.shiftStatCard, value: Money.format(totalCard), icon: Icons.credit_card_rounded, accentColor: pos.accentFg),
            _ShiftStatCard(label: l.shiftStatKaspiQR, value: Money.format(totalQR), icon: Icons.qr_code_rounded, accentColor: pos.warningFg),
            _ShiftStatCard(label: l.shiftStatReturns, value: Money.format(totalReturns), icon: Icons.undo_rounded, accentColor: pos.errorFg),
          ];
          if (constraints.maxWidth >= 500) {
            return Row(children: [for (var i = 0; i < cards.length; i++) ...[if (i > 0) const SizedBox(width: 12), Expanded(child: cards[i])]]);
          }
          return Column(children: [
            Row(children: [Expanded(child: cards[0]), const SizedBox(width: 12), Expanded(child: cards[1])]),
            const SizedBox(height: 12),
            Row(children: [Expanded(child: cards[2]), const SizedBox(width: 12), Expanded(child: cards[3])]),
          ]);
        }),
      )),

      // Cash info
      SliverToBoxAdapter(child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(10)),
              child: Icon(Icons.account_balance_wallet_rounded, size: 20, color: cs.onSurfaceVariant),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.shiftCashStart, style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(Money.format(cashStart), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
            ])),
            Text(l.shiftCurrentBalance, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: cs.outline, letterSpacing: 0.3)),
            const SizedBox(width: 8),
            Text(Money.format(expectedInDrawer), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: pos.successFg)),
          ]),
        ),
      )),

      // Close shift button
      if (onClose != null)
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: onClose,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(l.shiftCloseZReport, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: pos.errorFg,
                side: BorderSide(color: pos.errorFg),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        )),
    ]);
  }
}

class _ShiftStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _ShiftStatCard({required this.label, required this.value, required this.icon, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: accentColor),
        ),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: cs.outline, letterSpacing: 0.6)),
      ]),
    );
  }
}
