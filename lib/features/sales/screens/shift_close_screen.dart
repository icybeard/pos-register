import 'package:flutter/material.dart';
import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';
import '../widgets/x_report_sheet.dart';

/// Section 03 — shift close / Z-report screen.
///
/// Left pane: header, 4×2 KPI grid, transaction log table, expected cash.
/// Right pane: 5×2 action tile grid + Cancel + "Закрыть смену + Z-отчёт".
class ShiftCloseScreen extends StatefulWidget {
  final ApiClient api;
  final String shiftId;
  final String cashierName;
  const ShiftCloseScreen({
    super.key,
    required this.api,
    required this.shiftId,
    required this.cashierName,
  });

  @override
  State<ShiftCloseScreen> createState() => _ShiftCloseScreenState();
}

class _ShiftCloseScreenState extends State<ShiftCloseScreen> {
  Map<String, dynamic>? _shift;
  bool _loading = true;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      // Current shift is looked up via cashier. Backend exposes listOpenShifts
      // if we need direct shift lookup, but getCurrentShift is sufficient here
      // because the caller has just opened a shift (single-cashier terminal).
      final s = await widget.api.getCurrentShift('');
      if (!mounted) return;
      setState(() {
        _shift = s;
        _loading = false;
      });
    } on Exception {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _closeShift() async {
    if (_closing) return;
    setState(() => _closing = true);
    try {
      await widget.api.closeShift(shiftId: widget.shiftId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Смена закрыта, Z-отчёт отправлен в Webkassa')),
      );
      Navigator.of(context).pop(true);
    } on Exception catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    } finally {
      if (mounted) setState(() => _closing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hifi.canvas,
      body: Column(children: [
        // Push-routed full-screen flow — outside _MainShell, so this screen
        // renders its own chrome with a back button. The shell's chrome
        // covers in-shell pages only (POS / shift / products / etc.).
        HifiChrome(
          leading: BackButton(color: Colors.white, onPressed: () => Navigator.of(context).maybePop()),
          shiftNumber: _shift == null ? 'Смена' : 'Смена №${_shift!['ShiftNumber'] ?? '—'}',
          cashierName: widget.cashierName,
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Row(children: [
                  Expanded(child: _leftPane()),
                  _rightPanel(),
                ]),
        ),
      ]),
    );
  }

  Widget _leftPane() {
    final s = _shift ?? {};
    final sales = (s['TotalSales'] as num?)?.toInt() ?? 0;
    final cash = (s['TotalCash'] as num?)?.toInt() ?? 0;
    final card = (s['TotalCard'] as num?)?.toInt() ?? 0;
    final qr = (s['TotalQR'] as num?)?.toInt() ?? 0;
    final returns = (s['TotalReturns'] as num?)?.toInt() ?? 0;
    final discount = (s['TotalDiscount'] as num?)?.toInt() ?? 0;
    final parked = (s['ParkedCount'] as num?)?.toInt() ?? 0;
    final openedDebts = (s['OpenDebts'] as num?)?.toInt() ?? 0;
    final receiptCount = (s['ReceiptCount'] as num?)?.toInt() ?? 0;
    final cashStart = (s['CashStart'] as num?)?.toInt() ?? 0;
    final expected = cashStart + cash - returns;

    final kpis = <List<dynamic>>[
      ['Продажи за смену', '$receiptCount', Hifi.chrome],
      ['Оборот', Money.formatTenge(sales), Hifi.chrome],
      ['Наличные', Money.formatTenge(cash), Hifi.success],
      ['Kaspi / Halyk', Money.formatTenge(card + qr), Hifi.success],
      ['Возвраты', '−${Money.formatTenge(returns)}', Hifi.danger],
      ['Скидки', '−${Money.formatTenge(discount)}', Hifi.warn],
      ['Отложенные', '$parked', const Color(0xFF666666)],
      ['Долги открыты', '$openedDebts', Hifi.warn],
    ];

    return Container(
      color: Hifi.paneBg,
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        HifiSectionHeader(
          icon: '🔒',
          title: 'Z-отчёт · Закрытие смены',
          subtitle: _shiftTiming(s),
        ),
        const SizedBox(height: 10),
        // KPI grid 4×2
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 2.4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [for (final k in kpis) _kpi(k[0] as String, k[1] as String, k[2] as Color)],
        ),
        const SizedBox(height: 10),
        Expanded(
          child: _transactionsTable((s['Receipts'] as List<dynamic>?) ?? const <dynamic>[]),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Ожидаемо в кассе', style: Hifi.ui(size: 11, color: const Color(0xFF666666))),
            Text(Money.formatTenge(expected), style: Hifi.mono(size: 28, weight: FontWeight.w700, color: Hifi.chrome)),
          ]),
        ),
      ]),
    );
  }

  String _shiftTiming(Map<String, dynamic> s) {
    String? fmt(String? iso) {
      if (iso == null) return null;
      try {
        final d = DateTime.parse(iso).toLocal();
        String p(int n) => n.toString().padLeft(2, '0');
        return '${p(d.hour)}:${p(d.minute)}';
      } on FormatException {
        return null;
      }
    }

    final opened = fmt(s['OpenedAt'] as String?);
    if (opened == null) return 'Смена открыта';
    final now = DateTime.now();
    final openedAt = DateTime.tryParse(s['OpenedAt'] as String? ?? '');
    String dur = '';
    if (openedAt != null) {
      final diff = now.difference(openedAt);
      dur = ' · ${diff.inHours}ч ${diff.inMinutes.remainder(60)}м';
    }
    return 'Открыта $opened · закрывается сейчас$dur';
  }

  Widget _kpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Hifi.tableHead,
        border: Border.all(color: Hifi.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label.toUpperCase(), style: Hifi.ui(size: 10, color: const Color(0xFF666666)).copyWith(letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: Hifi.mono(size: 16, weight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _transactionsTable(List<dynamic> receipts) {
    if (receipts.isEmpty) {
      return Container(
        decoration: BoxDecoration(border: Border.all(color: Hifi.border), borderRadius: BorderRadius.circular(4)),
        child: Center(
          child: Text('Нет операций за смену', style: Hifi.ui(size: 13, color: const Color(0xFF888888))),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Hifi.border), borderRadius: BorderRadius.circular(4)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(children: [
          Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Hifi.tableHead,
              border: Border(bottom: BorderSide(color: Hifi.border)),
            ),
            child: Row(children: [
              SizedBox(width: 80, child: _th('ВРЕМЯ')),
              Expanded(child: _th('ОПЕРАЦИЯ')),
              SizedBox(width: 90, child: _th('ЧЕК №')),
              SizedBox(width: 100, child: _th('СПОСОБ')),
              SizedBox(width: 110, child: _th('СУММА', align: TextAlign.right)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: receipts.length,
              itemBuilder: (context, i) {
                final r = receipts[i] as Map<String, dynamic>;
                final kind = (r['Type'] as String?) ?? 'Продажа';
                final amount = (r['Total'] as num?)?.toInt() ?? 0;
                final isRefund = kind.toLowerCase().contains('возврат');
                final isDebt = kind.toLowerCase().contains('долг');
                final color = isRefund ? Hifi.danger : (isDebt ? Hifi.warn : const Color(0xFF333333));
                final amtStr = isRefund ? '−${Money.formatTenge(amount.abs())}' : Money.formatTenge(amount);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Hifi.divider))),
                  child: Row(children: [
                    SizedBox(width: 80, child: Text((r['Time'] as String?) ?? '--:--', style: Hifi.mono(size: 12, color: color))),
                    Expanded(child: Text(kind, style: Hifi.ui(size: 12, color: color))),
                    SizedBox(width: 90, child: Text((r['ReceiptNumber'] ?? '').toString(), style: Hifi.mono(size: 12, color: color))),
                    SizedBox(width: 100, child: Text((r['PaymentType'] as String?) ?? '—', style: Hifi.ui(size: 12, color: color))),
                    SizedBox(width: 110, child: Text(amtStr, textAlign: TextAlign.right, style: Hifi.mono(size: 12, weight: FontWeight.w600, color: color))),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _th(String label, {TextAlign align = TextAlign.left}) => Text(label,
      textAlign: align, style: Hifi.ui(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555)).copyWith(letterSpacing: 0.3));

  Widget _rightPanel() {
    final tiles = <ActionTile>[
      ActionTile(
        label: 'Печать X',
        hotkey: 'F7',
        onTap: () => XReportSheet.show(
          context,
          api: widget.api,
          shiftId: widget.shiftId,
          cashierName: widget.cashierName,
        ),
      ),
      ActionTile(label: 'Пересчёт', hotkey: 'F3', onTap: () => _todo('Пересчёт кассы')),
      ActionTile(label: 'Инкассация', onTap: () => _todo('Инкассация')),
      ActionTile(label: 'Журнал', hotkey: 'F4', onTap: () => _todo('Журнал операций')),
      ActionTile(label: 'Возвраты', onTap: () => Navigator.of(context).pushNamed('/returns')),
      ActionTile(label: 'Отложенные', onTap: () => _todo('Отложенные чеки')),
      ActionTile(label: 'Экспорт .csv', onTap: () => _todo('Экспорт CSV')),
      ActionTile(label: 'Email отчёт', onTap: () => _todo('Email отчёт')),
      ActionTile(label: 'Фискал. отчёт', onTap: () => _todo('Фискальный отчёт (Webkassa)')),
      ActionTile(label: 'Тех. перерыв', onTap: () => _todo('Технический перерыв')),
    ];
    return ActionGridPanel(
      tiles: tiles,
      voidTile: ActionTile(
        label: 'Отмена',
        variant: HifiTileVariant.red,
        hotkey: 'Esc',
        onTap: () => Navigator.of(context).maybePop(),
      ),
      payTile: ActionTile(
        label: _closing ? 'Закрытие…' : 'Закрыть смену + Z-отчёт',
        hotkey: 'F2',
        variant: HifiTileVariant.pay,
        onTap: _closing ? null : _closeShift,
        fontSize: 16,
      ),
    );
  }

  void _todo(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — в разработке'), duration: const Duration(seconds: 2)),
    );
  }
}
