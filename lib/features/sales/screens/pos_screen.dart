import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/sync_status_chip.dart';
import '../../../services/api_client.dart';
import '../../../services/sales/sales_service.dart';
import '../../../services/sync/sync_status_service.dart';
import '../bloc/sales_bloc.dart';
import '../models/cart_item.dart';
import '../sales_guards.dart';
import '../widgets/manager_override_dialog.dart';
import '../../clients/screens/debts_screen.dart';
import 'payment_screen.dart';
import '../widgets/x_report_sheet.dart';
import 'returns_screen.dart';
import 'shift_close_screen.dart';

/// POS register main screen — Variant C (action-grid) from the hi-fi handoff.
///
/// Layout (monobloc / 1024px wide):
///   [navy chrome bar]
///   ┌ left pane (flex) ─────── ┬ right panel (360) ┐
///   │ search/scan field        │ 4×4 action tiles  │
///   │ last-added info strip    │ − Void | Discount │
///   │ cart table               │   Pay · N ₸       │
///   │ subtotal / VAT / total   │                   │
///   └──────────────────────────┴───────────────────┘
///
/// Tablet (<1024): stacks vertically, action grid at the bottom (thumb zone).
class PosScreen extends StatelessWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const PosScreen({super.key, this.shiftId, this.cashierId, this.role = 'cashier'});

  @override
  Widget build(BuildContext context) {
    return BlocListener<SalesBloc, SalesState>(
      listenWhen: (prev, curr) => curr.saleSuccess != null || curr.error != null,
      listener: (context, state) {
        if (state.saleSuccess != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.saleSuccess!), backgroundColor: PosColors.of(context).successFg),
          );
        } else if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!), backgroundColor: PosColors.of(context).errorFg),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Hifi.canvas,
        body: LayoutBuilder(builder: (context, c) {
          final isTablet = c.maxWidth < 1024;
          return Column(children: [
            _PosChrome(cashierId: cashierId),
            Expanded(
              child: isTablet
                  ? _TabletLayout(shiftId: shiftId, cashierId: cashierId, role: role)
                  : _MonoblocLayout(shiftId: shiftId, cashierId: cashierId, role: role),
            ),
          ]);
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Chrome
// ════════════════════════════════════════════════════════════════════════════

class _PosChrome extends StatefulWidget {
  final String? cashierId;
  const _PosChrome({this.cashierId});

  @override
  State<_PosChrome> createState() => _PosChromeState();
}

class _PosChromeState extends State<_PosChrome> {
  // _online removed: the live SyncStatusChip below replaces the stub toggle.
  String _locale = 'ru';
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _ts {
    final d = _now;
    String p(int n) => n.toString().padLeft(2, '0');
    return '${p(d.day)}.${p(d.month)}.${d.year} ${p(d.hour)}:${p(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    // Pull the shared SyncStatusService from the app-root RepositoryProvider
    // (see main.dart). The chip replaces the old manual `online:` toggle —
    // the signal is now authoritative (live probe of server + outbox +
    // pull freshness) instead of a dev-only UI mock.
    final syncStatus = context.read<SyncStatusService>();
    return HifiChrome(
      shiftNumber: 'Смена №42',
      cashierName: widget.cashierId ?? 'Айжан К.',
      // Keep the existing `online: _online` default chip suppressed —
      // we're replacing it with a richer, live indicator in `extras`.
      // HifiChrome still renders the default chip when `online` is
      // explicitly set, so hiding it cleanly means passing an empty
      // trailing slot. Simpler: pass `online: true` so the default
      // chip is green (neutral) and put the real one in extras where
      // it paints on top in the Row order.
      online: true,
      locale: _locale,
      onToggleLocale: () => setState(() => _locale = _locale == 'ru' ? 'kk' : 'ru'),
      timestamp: _ts,
      extras: [SyncStatusChip(service: syncStatus)],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Monobloc layout (1024px+)
// ════════════════════════════════════════════════════════════════════════════

class _MonoblocLayout extends StatelessWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _MonoblocLayout({this.shiftId, this.cashierId, required this.role});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _CartPane(shiftId: shiftId, cashierId: cashierId, role: role)),
      _CartActionPanel(shiftId: shiftId, cashierId: cashierId, role: role),
    ]);
  }
}

class _TabletLayout extends StatelessWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _TabletLayout({this.shiftId, this.cashierId, required this.role});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Expanded(child: _CartPane(shiftId: shiftId, cashierId: cashierId, role: role)),
      _TabletActionStrip(shiftId: shiftId, cashierId: cashierId, role: role),
    ]);
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Left pane — search / last-added / cart / totals
// ════════════════════════════════════════════════════════════════════════════

class _CartPane extends StatefulWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _CartPane({this.shiftId, this.cashierId, required this.role});

  @override
  State<_CartPane> createState() => _CartPaneState();
}

class _CartPaneState extends State<_CartPane> {
  final _scanCtrl = TextEditingController();
  final _scanFocus = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _scanCtrl.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  void _onSubmitted(String v) {
    final q = v.trim();
    if (q.isEmpty) return;
    context.read<SalesBloc>().add(SearchProduct(q));
    _scanCtrl.clear();
    _scanFocus.requestFocus();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      context.read<SalesBloc>().add(SearchProduct(v));
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        final lastItem = state.items.isEmpty ? null : state.items.last;
        return Container(
          color: Hifi.paneBg,
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            HifiSearchField(
              controller: _scanCtrl,
              focusNode: _scanFocus,
              autofocus: true,
              hint: 'Поиск / штрих-код / SKU',
              onSubmitted: _onSubmitted,
              onChanged: _onChanged,
              trailing: Text('⏎ Enter', style: Hifi.mono(size: 10, color: const Color(0xFF888888))),
            ),
            const SizedBox(height: 8),
            LastAddedStrip(
              iconData: lastItem == null
                  ? Icons.qr_code_scanner_outlined
                  : (lastItem.isWeighted ? Icons.scale_outlined : Icons.inventory_2_outlined),
              title: lastItem?.name ?? 'Отсканируйте товар',
              subtitle: lastItem == null
                  ? 'последний добавленный товар появится здесь'
                  : '${lastItem.isWeighted ? "${lastItem.weightGrams}г" : "${lastItem.quantity.toStringAsFixed(0)} шт"} · ${Money.format(lastItem.basePrice)}${lastItem.isWeighted ? "/кг" : ""}',
              price: lastItem == null ? '—' : Money.format(lastItem.total),
              empty: lastItem == null,
            ),
            const SizedBox(height: 8),
            if (state.searchResults.isNotEmpty)
              _SearchResultsOverlay(results: state.searchResults),
            Expanded(child: _CartTable(items: state.items)),
            const SizedBox(height: 4),
            _PosTotals(state: state),
          ]),
        );
      },
    );
  }
}

class _SearchResultsOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  const _SearchResultsOverlay({required this.results});

  @override
  Widget build(BuildContext context) {
    final top = results.take(4).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Hifi.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: [
        for (int i = 0; i < top.length; i++) _row(context, top[i], last: i == top.length - 1),
      ]),
    );
  }

  Widget _row(BuildContext context, Map<String, dynamic> p, {required bool last}) {
    final name = p['Name'] as String? ?? '';
    final price = (p['SalePrice'] as num?)?.toInt() ?? 0;
    final unit = p['SaleUnit'] as String? ?? 'pcs';
    final isWeighted = p['IsWeighted'] as bool? ?? false;
    final ntin = p['NTIN'] as String?;
    return InkWell(
      onTap: () {
        context.read<SalesBloc>().add(AddToCart(CartItem(
              productId: p['ID'] as String,
              name: name,
              ntin: ntin,
              unit: unit,
              basePrice: price,
              isWeighted: isWeighted,
              vatRate: (p['VATRate'] as num?)?.toInt() ?? 12,
            )));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: last ? null : const Border(bottom: BorderSide(color: Hifi.divider)),
        ),
        child: Row(children: [
          Icon(
            isWeighted ? Icons.scale_outlined : Icons.inventory_2_outlined,
            size: 16,
            color: Hifi.chrome,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(name, style: Hifi.ui(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Text(
            isWeighted ? '${Money.format(price)}/кг' : Money.format(price),
            style: Hifi.mono(size: 13, weight: FontWeight.w600, color: Hifi.chrome),
          ),
        ]),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Cart table
// ════════════════════════════════════════════════════════════════════════════

class _CartTable extends StatelessWidget {
  final List<CartItem> items;
  const _CartTable({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Hifi.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.shopping_cart_outlined, size: 36, color: Hifi.border),
            const SizedBox(height: 8),
            Text('Корзина пуста', style: Hifi.ui(size: 13, color: const Color(0xFF888888))),
            const SizedBox(height: 2),
            Text('Отсканируйте первый товар', style: Hifi.ui(size: 11, color: const Color(0xFFAAAAAA))),
          ]),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Hifi.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(children: [
          _header(),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              itemBuilder: (context, i) => _CartRow(item: items[i], index: i),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _header() => Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: const BoxDecoration(
          color: Hifi.tableHead,
          border: Border(bottom: BorderSide(color: Hifi.border)),
        ),
        child: Row(children: [
          Expanded(child: _h('Наименование', TextAlign.left)),
          SizedBox(width: 120, child: _h('Кол-во', TextAlign.center)),
          SizedBox(width: 90, child: _h('Цена', TextAlign.right)),
          SizedBox(width: 100, child: _h('Итого', TextAlign.right)),
          const SizedBox(width: 32),
        ]),
      );

  Widget _h(String label, TextAlign align) => Text(
        label.toUpperCase(),
        textAlign: align,
        style: Hifi.ui(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555))
            .copyWith(letterSpacing: 0.3),
      );
}

class _CartRow extends StatelessWidget {
  final CartItem item;
  final int index;
  const _CartRow({required this.item, required this.index});

  void _editQty(BuildContext context) {
    final controller = TextEditingController(
      text: item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Количество', style: Hifi.ui(size: 16, weight: FontWeight.w700)),
        content: SizedBox(
          width: 260,
          child: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            style: Hifi.mono(size: 24, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final q = double.tryParse(controller.text) ?? 0;
              if (q > 0) context.read<SalesBloc>().add(UpdateQuantity(index, q));
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Hifi.divider))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(item.name, style: Hifi.ui(size: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              '${Money.format(item.basePrice)}${item.isWeighted ? "/кг" : "/шт"}',
              style: Hifi.mono(size: 10, color: const Color(0xFF888888)),
            ),
          ]),
        ),
        SizedBox(
          width: 120,
          child: item.isWeighted
              ? Center(
                  child: GestureDetector(
                    onTap: () => _editQty(context),
                    child: Text('${item.weightGrams}г', style: Hifi.mono(size: 14, weight: FontWeight.w600)),
                  ),
                )
              : Center(
                  child: HifiStepper(
                    value: item.quantity.toInt(),
                    onDec: item.quantity > 1
                        ? () => context.read<SalesBloc>().add(UpdateQuantity(index, item.quantity - 1))
                        : null,
                    onInc: () => context.read<SalesBloc>().add(UpdateQuantity(index, item.quantity + 1)),
                  ),
                ),
        ),
        SizedBox(
          width: 90,
          child: Text(
            Money.format(item.basePrice),
            textAlign: TextAlign.right,
            style: Hifi.mono(size: 13, color: const Color(0xFF666666)),
          ),
        ),
        SizedBox(
          width: 100,
          child: Text(
            Money.format(item.total),
            textAlign: TextAlign.right,
            style: Hifi.mono(size: 13, weight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () => context.read<SalesBloc>().add(RemoveFromCart(index)),
            icon: const Icon(Icons.close, size: 18, color: Color(0xFF888888)),
          ),
        ),
      ]),
    );
  }
}

class _PosTotals extends StatelessWidget {
  final SalesState state;
  const _PosTotals({required this.state});

  @override
  Widget build(BuildContext context) {
    final subtotal = state.subtotal;
    final vat = state.vatAmount;
    final net = subtotal - vat;
    return HifiTotals(
      subtotal: Money.format(net),
      vat: Money.format(vat),
      totalLabel: 'ИТОГО',
      total: Money.format(state.total),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Action panel (right side, navy)
// ════════════════════════════════════════════════════════════════════════════

class _CartActionPanel extends StatelessWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _CartActionPanel({this.shiftId, this.cashierId, required this.role});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        final disabled = state.items.isEmpty;
        return ActionGridPanel(
          tiles: _buildTiles(context, state),
          voidTile: ActionTile(
            label: 'Отмена',
            variant: HifiTileVariant.red,
            onTap: disabled ? null : () => context.read<SalesBloc>().add(ClearCart()),
          ),
          discountTile: ActionTile(
            label: 'Скидка',
            hotkey: 'F7',
            variant: HifiTileVariant.yellow,
            onTap: disabled ? null : () => _openDiscountDialog(context, state),
          ),
          payTile: ActionTile(
            label: disabled
                ? 'ОПЛАТА'
                : 'ОПЛАТА · ${Money.formatTenge(state.total)}',
            hotkey: 'F2',
            variant: HifiTileVariant.pay,
            onTap: disabled ? null : () => _openPayment(context, state),
          ),
        );
      },
    );
  }

  List<ActionTile> _buildTiles(BuildContext context, SalesState state) {
    return [
      ActionTile(
        label: '＋ Новый',
        hotkey: 'F4',
        variant: HifiTileVariant.green,
        onTap: () => context.read<SalesBloc>().add(ClearCart()),
      ),
      ActionTile(
        label: 'Отложить',
        hotkey: 'F5',
        onTap: state.items.isEmpty ? null : () => context.read<SalesBloc>().add(ParkCart()),
      ),
      ActionTile(
        label: 'Открытые',
        hotkey: 'F6',
        onTap: state.parkedCarts.isEmpty ? null : () => _showParked(context, state),
      ),
      ActionTile(
        label: 'Поиск',
        hotkey: 'F3',
        onTap: () => _openSearch(context),
      ),
      ActionTile(
        label: 'Возврат',
        hotkey: 'F9',
        onTap: () => _openReturns(context),
      ),
      ActionTile(
        label: 'Долги',
        hotkey: 'F8',
        onTap: () => _openDebts(context),
      ),
      ActionTile(label: 'История', onTap: () => _todo(context, 'История чеков')),
      ActionTile(label: 'Печать чека', hotkey: 'F11', onTap: () => _todo(context, 'Печать копии')),
      ActionTile(
        label: 'Отчёт X',
        onTap: shiftId == null
            ? null
            : () => XReportSheet.show(
                  context,
                  api: context.read<ApiClient>(),
                  shiftId: shiftId!,
                  cashierName: cashierId ?? 'Кассир',
                ),
      ),
      ActionTile(label: 'Отчёт Z', onTap: shiftId == null ? null : () => _openShiftClose(context)),
      ActionTile(label: 'Внесение', onTap: shiftId == null ? null : () => _cashMove(context, deposit: true)),
      ActionTile(label: 'Изъятие', onTap: shiftId == null ? null : () => _cashMove(context, deposit: false)),
      ActionTile(label: 'Откр. ящик', onTap: () => _todo(context, 'Открыть денежный ящик')),
      ActionTile(label: 'Настройки', onTap: () => Navigator.of(context).pushNamed('/settings')),
      ActionTile(label: 'Коды ТРУ', onTap: () => _todo(context, 'Коды ТРУ')),
      ActionTile(label: 'Блокировать', onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
    ];
  }

  void _openPayment(BuildContext context, SalesState state) async {
    if (shiftId == null || shiftId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.posOpenShiftFirst),
          backgroundColor: PosColors.of(context).warningFg,
        ),
      );
      return;
    }
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          totalTiyin: state.total,
          vatAmount: state.vatAmount,
          shiftId: shiftId,
          api: context.read<ApiClient>(),
          cashierId: cashierId,
        ),
      ),
    );
    if (result == null || !context.mounted) return;

    String? overrideUserId;
    final guards = context.read<SalesGuards>();
    if (guards.isWired) {
      final lines = _cartToSalesLines(state.items);
      final shortages = await guards.guard!.check(lines);
      if (shortages.isNotEmpty) {
        if (!context.mounted) return;
        final manager = await ManagerOverrideDialog.show(
          context,
          service: guards.overrideService!,
          subtitle: _subtitleFor(shortages),
        );
        if (manager == null) return;
        overrideUserId = manager.id;
      }
    }

    if (!context.mounted) return;
    context.read<SalesBloc>().add(CompleteSale(
          shiftId: shiftId!,
          cashierId: cashierId ?? '',
          paymentType: result['method'] as String? ?? 'cash',
          cashAmount: result['cash'] as int? ?? 0,
          cardAmount: result['card'] as int? ?? 0,
          qrAmount: result['qr'] as int? ?? 0,
          changeAmount: result['change'] as int? ?? 0,
          overrideUserId: overrideUserId,
        ));
  }

  static List<SalesLineInput> _cartToSalesLines(List<CartItem> items) {
    return items
        .map((ci) => SalesLineInput(
              productId: ci.productId,
              productName: ci.name,
              ntin: ci.ntin,
              isWeighted: ci.isWeighted,
              quantity: ci.isWeighted ? 0 : ci.quantity.toInt(),
              weightGrams: ci.isWeighted ? ci.weightGrams : 0,
              unitPriceTiyin: ci.basePrice,
              itemTotalTiyin: ci.total,
              discountTiyin: ci.discount,
              vatRate: ci.vatRate,
              unit: ci.unit,
            ))
        .toList();
  }

  static String _subtitleFor(List<dynamic> shortages) {
    final parts = shortages.map((s) {
      final unit = s.isWeighted as bool ? 'г' : 'шт';
      return '${s.productName} — ${s.requested}$unit при остатке ${s.onHand}$unit';
    }).join('; ');
    return 'Продажа ниже остатка: $parts';
  }

  void _openDiscountDialog(BuildContext context, SalesState state) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Скидка на чек', style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: '₸', hintText: '0'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          ElevatedButton(
            onPressed: () {
              final tenge = double.tryParse(controller.text) ?? 0;
              context.read<SalesBloc>().add(ApplyDiscount((tenge * 100).round()));
              Navigator.pop(ctx);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showParked(BuildContext context, SalesState state) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Отложенные чеки', style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
          const SizedBox(height: 12),
          ...state.parkedCarts.asMap().entries.map((e) {
            final idx = e.key;
            final cart = e.value;
            final time = '${cart.parkedAt.hour.toString().padLeft(2, '0')}:${cart.parkedAt.minute.toString().padLeft(2, '0')}';
            return ListTile(
              leading: const Icon(Icons.shopping_cart, color: Hifi.chrome),
              title: Text('${cart.itemCount} позиций — ${Money.format(cart.total)}'),
              subtitle: Text(time),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.read<SalesBloc>().add(ResumeParkedCart(idx));
                },
              ),
            );
          }),
        ]),
      ),
    );
  }

  void _openSearch(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text('Поиск товара', style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
        content: SizedBox(
          width: 320,
          child: HifiSearchField(
            controller: controller,
            hint: 'Название / SKU / штрих-код',
            autofocus: true,
            onSubmitted: (v) {
              context.read<SalesBloc>().add(SearchProduct(v));
              Navigator.pop(ctx);
            },
          ),
        ),
      ),
    ).whenComplete(controller.dispose);
  }

  void _openReturns(BuildContext context) {
    final api = context.read<ApiClient>();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ReturnsScreen(api: api, cashierName: cashierId ?? 'Кассир'),
    ));
  }

  void _openDebts(BuildContext context) {
    final api = context.read<ApiClient>();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => DebtsScreen(api: api, cashierId: cashierId ?? ''),
    ));
  }

  void _openShiftClose(BuildContext context) {
    if (shiftId == null) return;
    final api = context.read<ApiClient>();
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) => ShiftCloseScreen(api: api, shiftId: shiftId!, cashierName: cashierId ?? 'Кассир'),
    ));
  }

  Future<void> _cashMove(BuildContext context, {required bool deposit}) async {
    if (shiftId == null) return;
    final api = context.read<ApiClient>();
    final ctrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final tenge = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: Text(
          deposit ? 'Внесение в кассу' : 'Изъятие из кассы',
          style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome),
        ),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Сумма',
              suffixText: '₸',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: noteCtrl,
            decoration: const InputDecoration(labelText: 'Комментарий (необязательно)'),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text)),
            style: FilledButton.styleFrom(backgroundColor: Hifi.chrome),
            child: Text(deposit ? 'Внести' : 'Изъять'),
          ),
        ],
      ),
    );
    // Both controllers must be disposed regardless of dialog outcome.
    // Doing it after the API call (rather than via .whenComplete on the
    // dialog future) keeps `noteCtrl.text` readable for the api call
    // below — but in this method noteCtrl isn't currently sent, so
    // disposing immediately on close is fine. Using try/finally below.
    try {
      if (tenge == null || tenge <= 0 || !context.mounted) return;
      final tiyin = (tenge * 100).round();
      try {
        if (deposit) {
          await api.shiftDeposit(shiftId!, tiyin);
        } else {
          await api.shiftWithdraw(shiftId!, tiyin);
        }
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            '${deposit ? "Внесено" : "Изъято"}: ${Money.formatTenge(tiyin)}',
          ),
          backgroundColor: PosColors.of(context).successFg,
        ));
      } on Exception catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: PosColors.of(context).errorFg),
        );
      }
    } finally {
      ctrl.dispose();
      noteCtrl.dispose();
    }
  }

  void _todo(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label — в разработке'), duration: const Duration(seconds: 2)),
    );
  }
}

// Tablet thumb-zone action strip — 4 cols × 2 rows + Void/Pay. Per section 08
// in the handoff.
class _TabletActionStrip extends StatelessWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _TabletActionStrip({this.shiftId, this.cashierId, required this.role});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        final disabled = state.items.isEmpty;
        final panel = _CartActionPanel(shiftId: shiftId, cashierId: cashierId, role: role);
        final tiles = panel._buildTiles(context, state).take(8).toList();
        return Container(
          color: Hifi.chrome,
          padding: const EdgeInsets.all(10),
          child: Column(children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.6,
              children: [for (final t in tiles) SizedBox(height: 60, child: t)],
            ),
            const SizedBox(height: 8),
            Row(children: [
              SizedBox(
                width: 120,
                height: 72,
                child: ActionTile(
                  label: 'Отмена',
                  variant: HifiTileVariant.red,
                  onTap: disabled ? null : () => context.read<SalesBloc>().add(ClearCart()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 72,
                  child: ActionTile(
                    label: disabled
                        ? 'ОПЛАТА'
                        : 'ОПЛАТА · ${Money.formatTenge(state.total)}',
                    variant: HifiTileVariant.pay,
                    onTap: disabled ? null : () => panel._openPayment(context, state),
                    fontSize: 22,
                  ),
                ),
              ),
            ]),
          ]),
        );
      },
    );
  }
}

// silence unused import warning when running analyzer if none of the SystemChannels
// helpers are referenced; kept for FilteringTextInputFormatter usage above.
// ignore: unused_element
void _unused() => FilteringTextInputFormatter.digitsOnly;
