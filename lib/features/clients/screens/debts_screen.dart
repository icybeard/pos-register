import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

/// Section 05 — Debts (running customer tab, "на долг").
///
/// Left pane: customer list (search by name/phone) + detail/history.
/// Right pane: action tiles (Новый долг / Погашение / SMS / Карточка / ...)
/// + Cancel + Pay tile.
class DebtsScreen extends StatefulWidget {
  final ApiClient api;
  final String cashierId;
  const DebtsScreen({super.key, required this.api, required this.cashierId});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  bool _loading = true;
  List<_Debtor> _debtors = const [];
  String? _selectedId;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final debtsResp = await widget.api.listDebts();
      final clientsResp = await widget.api.listClients();
      final clients = (clientsResp['clients'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];
      final debts = (debtsResp['debts'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          const <Map<String, dynamic>>[];

      final byClient = <String, _Debtor>{};
      for (final c in clients) {
        final id = c['ID'] as String? ?? '';
        if (id.isEmpty) continue;
        byClient[id] = _Debtor(
          id: id,
          name: (c['Name'] as String?) ?? '—',
          phone: (c['Phone'] as String?) ?? '',
          amount: 0,
          lastDate: null,
          itemsCount: 0,
          entries: const [],
        );
      }
      final tempEntries = <String, List<_Entry>>{};
      for (final d in debts) {
        final cid = d['ClientID'] as String? ?? '';
        if (cid.isEmpty || byClient[cid] == null) continue;
        final amt = (d['Amount'] as num?)?.toInt() ?? 0;
        final paid = (d['PaidAmount'] as num?)?.toInt() ?? 0;
        final open = amt - paid;
        final status = d['Status'] as String? ?? 'open';
        final created = DateTime.tryParse(d['CreatedAt'] as String? ?? '');
        final list = tempEntries.putIfAbsent(cid, () => <_Entry>[]);
        list.add(_Entry(
          when: created ?? DateTime.now(),
          kind: status == 'closed' ? 'оплат.' : 'долг',
          label: status == 'closed'
              ? 'Погашение чека'
              : 'Долг (${(d['ItemCount'] as num?)?.toInt() ?? 1} поз.)',
          amount: status == 'closed' ? -paid : amt,
        ));
        final d0 = byClient[cid]!;
        byClient[cid] = d0.copyWith(
          amount: d0.amount + open,
          lastDate: created ?? d0.lastDate,
          itemsCount: d0.itemsCount + ((d['ItemCount'] as num?)?.toInt() ?? 0),
        );
      }
      for (final e in byClient.entries) {
        byClient[e.key] = e.value.copyWith(entries: tempEntries[e.key] ?? const []);
      }

      final list = byClient.values.where((d) => d.amount > 0).toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
      if (!mounted) return;
      setState(() {
        _debtors = list;
        _selectedId = list.isEmpty ? null : list.first.id;
        _loading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
    }
  }

  _Debtor? get _selected => _debtors.where((d) => d.id == _selectedId).cast<_Debtor?>().firstWhere((_) => true, orElse: () => null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Hifi.canvas,
      body: Column(children: [
        // Push-routed flow from POS — outside _MainShell, so the chrome
        // is rendered locally with a back button.
        HifiChrome(
          leading: BackButton(color: Colors.white, onPressed: () => Navigator.of(context).maybePop()),
          shiftNumber: 'Долги',
          cashierName: widget.cashierId,
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
    return Container(
      color: Hifi.paneBg,
      padding: const EdgeInsets.all(10),
      child: Row(children: [
        SizedBox(width: 320, child: _list()),
        const SizedBox(width: 8),
        Expanded(child: _detail()),
      ]),
    );
  }

  Widget _list() {
    final filtered = _debtors
        .where((d) =>
            _search.isEmpty ||
            d.name.toLowerCase().contains(_search.toLowerCase()) ||
            d.phone.contains(_search))
        .toList();
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Hifi.border), borderRadius: BorderRadius.circular(4)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.all(6),
            child: HifiSearchField(
              hint: 'Имя / телефон',
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? Center(child: Text('Нет должников', style: Hifi.ui(size: 13, color: const Color(0xFF888888))))
                : ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => _debtorRow(filtered[i]),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _debtorRow(_Debtor d) {
    final selected = _selectedId == d.id;
    final daysAgo = d.lastDate == null ? 0 : DateTime.now().difference(d.lastDate!).inDays;
    final accent = daysAgo > 14 ? Hifi.danger : daysAgo > 7 ? Hifi.warn : Hifi.chrome;
    return Material(
      color: selected ? const Color(0xFFE3F2FF) : Colors.white,
      child: InkWell(
        onTap: () => setState(() => _selectedId = d.id),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: const BorderSide(color: Hifi.divider),
              left: BorderSide(color: selected ? Hifi.chrome : Colors.transparent, width: 3),
            ),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(d.name, style: Hifi.ui(size: 13, weight: FontWeight.w600))),
              Text(Money.formatTenge(d.amount), style: Hifi.mono(size: 13, weight: FontWeight.w700, color: accent)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              Expanded(child: Text(d.phone, style: Hifi.ui(size: 11, color: const Color(0xFF666666)))),
              Text(daysAgo == 0 ? 'сегодня' : '$daysAgo' 'д', style: Hifi.ui(size: 11, color: const Color(0xFF666666))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _detail() {
    final d = _selected;
    if (d == null) {
      return Center(child: Text('Выберите клиента', style: Hifi.ui(size: 13, color: const Color(0xFF888888))));
    }
    final daysAgo = d.lastDate == null ? 0 : DateTime.now().difference(d.lastDate!).inDays;
    final amountColor = daysAgo > 14 ? Hifi.danger : Hifi.chrome;
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Hifi.infoStrip,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Hifi.border),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(color: Hifi.chrome, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              d.name.isEmpty ? '?' : d.name.characters.first,
              style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(d.name, style: Hifi.ui(size: 15, weight: FontWeight.w700, color: Hifi.chrome)),
            Text(
              '${d.phone} · последняя операция ${d.lastDate == null ? '—' : _date(d.lastDate!)}',
              style: Hifi.ui(size: 11, color: const Color(0xFF666666)),
            ),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('ДОЛГ', style: Hifi.ui(size: 10, color: const Color(0xFF666666))),
            Text(Money.formatTenge(d.amount), style: Hifi.mono(size: 22, weight: FontWeight.w700, color: amountColor)),
          ]),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(child: _history(d)),
    ]);
  }

  String _date(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}.${p(d.month)}.${d.year}';
  }

  Widget _history(_Debtor d) {
    if (d.entries.isEmpty) {
      return Container(
        decoration: BoxDecoration(border: Border.all(color: Hifi.border), borderRadius: BorderRadius.circular(4)),
        child: Center(
          child: Text('Нет операций', style: Hifi.ui(size: 13, color: const Color(0xFF888888))),
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
            decoration: const BoxDecoration(color: Hifi.tableHead, border: Border(bottom: BorderSide(color: Hifi.border))),
            child: Row(children: [
              SizedBox(width: 90, child: _th('ДАТА')),
              Expanded(child: _th('ОПЕРАЦИЯ')),
              SizedBox(width: 80, child: _th('ТИП', align: TextAlign.center)),
              SizedBox(width: 110, child: _th('СУММА', align: TextAlign.right)),
            ]),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: d.entries.length,
              itemBuilder: (context, i) {
                final e = d.entries[i];
                final typeColor = e.kind == 'долг' ? Hifi.danger : Hifi.success;
                final amtColor = e.amount >= 0 ? Hifi.danger : Hifi.success;
                final amtStr = e.amount >= 0 ? '+${Money.formatTenge(e.amount)}' : '−${Money.formatTenge(e.amount.abs())}';
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Hifi.divider))),
                  child: Row(children: [
                    SizedBox(width: 90, child: Text(_date(e.when), style: Hifi.mono(size: 12, color: const Color(0xFF666666)))),
                    Expanded(child: Text(e.label, style: Hifi.ui(size: 12))),
                    SizedBox(width: 80, child: Text(e.kind, textAlign: TextAlign.center, style: Hifi.ui(size: 12, weight: FontWeight.w600, color: typeColor))),
                    SizedBox(width: 110, child: Text(amtStr, textAlign: TextAlign.right, style: Hifi.mono(size: 12, weight: FontWeight.w600, color: amtColor))),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _th(String label, {TextAlign align = TextAlign.left}) => Text(
        label,
        textAlign: align,
        style: Hifi.ui(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555)).copyWith(letterSpacing: 0.3),
      );

  Widget _rightPanel() {
    final d = _selected;
    final tiles = <ActionTile>[
      ActionTile(label: 'Новый долг', hotkey: 'F4', variant: HifiTileVariant.green, onTap: () => _todo('Новый долг')),
      ActionTile(label: 'Погашение', hotkey: 'F2', variant: HifiTileVariant.green, onTap: d == null ? null : () => _payDown(d)),
      ActionTile(label: 'Поиск', hotkey: 'F3', onTap: () {}),
      ActionTile(label: 'SMS напом.', onTap: () => _todo('SMS напоминание')),
      ActionTile(label: 'Карточка', onTap: () => _todo('Карточка клиента')),
      ActionTile(label: 'История', onTap: () => _todo('Полная история')),
      ActionTile(label: 'Экспорт', onTap: () => _todo('Экспорт .csv')),
      ActionTile(label: 'Печать', hotkey: 'F11', onTap: () => _todo('Печать выписки')),
      ActionTile(label: 'Фильтр > 14д', onTap: () => _todo('Фильтр > 14 дней')),
      ActionTile(label: 'Фильтр > 30д', onTap: () => _todo('Фильтр > 30 дней')),
    ];
    return ActionGridPanel(
      tiles: tiles,
      voidTile: ActionTile(
        label: 'Закрыть',
        variant: HifiTileVariant.red,
        hotkey: 'Esc',
        onTap: () => Navigator.of(context).maybePop(),
      ),
      payTile: ActionTile(
        label: d == null ? '💰 Погасить долг' : '💰 Погасить ${d.shortName} · ${Money.formatTenge(d.amount)}',
        variant: HifiTileVariant.pay,
        hotkey: 'F2',
        fontSize: 16,
        onTap: d == null ? null : () => _payDown(d),
      ),
    );
  }

  Future<void> _payDown(_Debtor d) async {
    final ctrl = TextEditingController(text: (d.amount / 100).toStringAsFixed(0));
    final amount = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Погашение долга · ${d.name}', style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '₸'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ((double.tryParse(ctrl.text) ?? 0) * 100).round()),
            child: const Text('Принять'),
          ),
        ],
      ),
    );
    if (amount == null || amount <= 0 || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Погашение ${Money.formatTenge(amount)} (в разработке)')),
    );
    unawaited(_load());
  }

  void _todo(String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — в разработке'), duration: const Duration(seconds: 2)),
    );
  }
}

class _Debtor {
  final String id;
  final String name;
  final String phone;
  final int amount;
  final DateTime? lastDate;
  final int itemsCount;
  final List<_Entry> entries;

  const _Debtor({
    required this.id,
    required this.name,
    required this.phone,
    required this.amount,
    required this.lastDate,
    required this.itemsCount,
    required this.entries,
  });

  _Debtor copyWith({int? amount, DateTime? lastDate, int? itemsCount, List<_Entry>? entries}) => _Debtor(
        id: id,
        name: name,
        phone: phone,
        amount: amount ?? this.amount,
        lastDate: lastDate ?? this.lastDate,
        itemsCount: itemsCount ?? this.itemsCount,
        entries: entries ?? this.entries,
      );

  String get shortName {
    final parts = name.split(' ');
    return parts.isEmpty ? name : parts.first;
  }
}

class _Entry {
  final DateTime when;
  final String kind; // 'долг' | 'оплат.'
  final String label;
  final int amount; // +долг, −оплат.
  const _Entry({required this.when, required this.kind, required this.label, required this.amount});
}
