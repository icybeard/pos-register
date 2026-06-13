import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide Provider;
// `provider` package supplies the existing context.read<ApiClient>() / <SalesGuards>()
// non-bloc DI. `Consumer` is hidden because Riverpod ships one too and the cart
// UI uses Riverpod's reactive Consumer.
import 'package:provider/provider.dart' hide Consumer;
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';
import '../../../services/sales/sales_service.dart';
import '../controllers/sales_controller.dart';
import '../models/cart_item.dart';
import '../sales_guards.dart';
import '../widgets/manager_override_dialog.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../clients/screens/debts_screen.dart';
import '../../settings/screens/settings_screen.dart';
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
    // Side-effects (success/error snackbars) ride a Consumer + ref.listen so
    // we only rebuild on the saleSuccess / error fields, not every cart edit.
    return Consumer(
      builder: (context, ref, child) {
        ref.listen<SalesState>(salesControllerProvider, (prev, curr) {
          if (prev?.saleSuccess != curr.saleSuccess && curr.saleSuccess != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(curr.saleSuccess!), backgroundColor: PosColors.of(context).successFg),
            );
          } else if (prev?.error != curr.error && curr.error != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(curr.error!), backgroundColor: PosColors.of(context).errorFg),
            );
          }
        });
        return child!;
      },
      // No more local chrome — the shell (`_MainShell._buildShellChrome`)
      // renders the navy top bar above this body. PosScreen returns just
      // the cart + action-grid layout; LayoutBuilder picks monobloc vs
      // tablet based on remaining width.
      child: Scaffold(
        backgroundColor: Hifi.canvas,
        body: LayoutBuilder(builder: (context, c) {
          final isTablet = c.maxWidth < 1024;
          return isTablet
              ? _TabletLayout(shiftId: shiftId, cashierId: cashierId, role: role)
              : _MonoblocLayout(shiftId: shiftId, cashierId: cashierId, role: role);
        }),
      ),
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

class _CartPane extends ConsumerStatefulWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _CartPane({this.shiftId, this.cashierId, required this.role});

  @override
  ConsumerState<_CartPane> createState() => _CartPaneState();
}

class _CartPaneState extends ConsumerState<_CartPane> {
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
    ref.read(salesControllerProvider.notifier).searchProduct(q);
    _scanCtrl.clear();
    _scanFocus.requestFocus();
  }

  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      ref.read(salesControllerProvider.notifier).searchProduct(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(salesControllerProvider);
    final l = AppLocalizations.of(context)!;
    final lastItem = state.items.isEmpty ? null : state.items.last;
    return Container(
      color: Hifi.paneBg,
      padding: const EdgeInsets.all(10),
      child: Column(children: [
        HifiSearchField(
          controller: _scanCtrl,
          focusNode: _scanFocus,
          autofocus: true,
          hint: l.posSearchHint,
          onSubmitted: _onSubmitted,
          onChanged: _onChanged,
          trailing: Text('⏎ Enter', style: Hifi.mono(size: 10, color: const Color(0xFF888888))),
        ),
        const SizedBox(height: 8),
        LastAddedStrip(
          iconData: lastItem == null
              ? Icons.qr_code_scanner_outlined
              : (lastItem.isWeighted ? Icons.scale_outlined : Icons.inventory_2_outlined),
          title: lastItem?.name ?? l.posScanPrompt,
          subtitle: lastItem == null
              ? l.posScanPromptHint
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
  }
}

class _SearchResultsOverlay extends ConsumerWidget {
  final List<Map<String, dynamic>> results;
  const _SearchResultsOverlay({required this.results});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final top = results.take(4).toList();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Hifi.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(children: [
        for (int i = 0; i < top.length; i++) _row(context, ref, top[i], last: i == top.length - 1),
      ]),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, Map<String, dynamic> p, {required bool last}) {
    final name = p['Name'] as String? ?? '';
    final price = (p['SalePrice'] as num?)?.toInt() ?? 0;
    final unit = p['SaleUnit'] as String? ?? 'pcs';
    final isWeighted = p['IsWeighted'] as bool? ?? false;
    final ntin = p['NTIN'] as String?;
    return InkWell(
      onTap: () {
        ref.read(salesControllerProvider.notifier).addToCart(CartItem(
              productId: p['ID'] as String,
              name: name,
              ntin: ntin,
              unit: unit,
              basePrice: price,
              isWeighted: isWeighted,
              vatRate: (p['VATRate'] as num?)?.toInt() ?? 12,
            ));
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
    final l = AppLocalizations.of(context)!;
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
            Text(l.posCartEmpty, style: Hifi.ui(size: 13, color: const Color(0xFF888888))),
            const SizedBox(height: 2),
            Text(l.posCartEmptyHint, style: Hifi.ui(size: 11, color: const Color(0xFFAAAAAA))),
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

class _CartRow extends ConsumerWidget {
  final CartItem item;
  final int index;
  const _CartRow({required this.item, required this.index});

  void _editQty(BuildContext context, WidgetRef ref) {
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
              if (q > 0) ref.read(salesControllerProvider.notifier).updateQuantity(index, q);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sales = ref.read(salesControllerProvider.notifier);
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
                    onTap: () => _editQty(context, ref),
                    child: Text('${item.weightGrams}г', style: Hifi.mono(size: 14, weight: FontWeight.w600)),
                  ),
                )
              : Center(
                  child: HifiStepper(
                    value: item.quantity.toInt(),
                    onDec: item.quantity > 1
                        ? () => sales.updateQuantity(index, item.quantity - 1)
                        : null,
                    onInc: () => sales.updateQuantity(index, item.quantity + 1),
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
            onPressed: () => sales.removeFromCart(index),
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

class _CartActionPanel extends ConsumerWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _CartActionPanel({this.shiftId, this.cashierId, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesControllerProvider);
    final sales = ref.read(salesControllerProvider.notifier);
    final disabled = state.items.isEmpty;
    return ActionGridPanel(
      tiles: _buildTiles(context, ref, state),
      voidTile: ActionTile(
        label: 'Отмена',
        variant: HifiTileVariant.red,
        onTap: disabled ? null : sales.clearCart,
      ),
      discountTile: ActionTile(
        label: 'Скидка',
        hotkey: 'F7',
        variant: HifiTileVariant.yellow,
        onTap: disabled ? null : () => _openDiscountDialog(context, ref, state),
      ),
      payTile: ActionTile(
        label: disabled
            ? 'ОПЛАТА'
            : 'ОПЛАТА · ${Money.formatTenge(state.total)}',
        hotkey: 'F2',
        variant: HifiTileVariant.pay,
        onTap: disabled
            ? null
            : () => unawaited(_openPayment(context, ref, state)),
      ),
    );
  }

  List<ActionTile> _buildTiles(BuildContext context, WidgetRef ref, SalesState state) {
    final l = AppLocalizations.of(context)!;
    final sales = ref.read(salesControllerProvider.notifier);
    return [
      ActionTile(
        label: '＋ Новый',
        hotkey: 'F4',
        variant: HifiTileVariant.green,
        onTap: sales.clearCart,
      ),
      ActionTile(
        label: 'Отложить',
        hotkey: 'F5',
        onTap: state.items.isEmpty ? null : sales.parkCart,
      ),
      ActionTile(
        label: 'Открытые',
        hotkey: 'F6',
        onTap: state.parkedCarts.isEmpty ? null : () => _showParked(context, ref, state),
      ),
      ActionTile(
        label: 'Поиск',
        hotkey: 'F3',
        onTap: () => _openSearch(context, ref),
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
      ActionTile(label: l.posActionHistory, onTap: () => _todo(context, 'История чеков')),
      ActionTile(label: l.posActionPrintReceipt, hotkey: 'F11', onTap: () => _todo(context, 'Печать копии')),
      ActionTile(
        label: l.posActionReportX,
        onTap: shiftId == null
            ? null
            : () => XReportSheet.show(
                  context,
                  api: context.read<ApiClient>(),
                  shiftId: shiftId!,
                  cashierName: cashierId ?? 'Кассир',
                ),
      ),
      ActionTile(label: l.posActionReportZ, onTap: shiftId == null ? null : () => _openShiftClose(context)),
      ActionTile(label: l.posActionDeposit, onTap: shiftId == null ? null : () => _cashMove(context, deposit: true)),
      ActionTile(label: l.posActionWithdraw, onTap: shiftId == null ? null : () => _cashMove(context, deposit: false)),
      ActionTile(label: l.posActionOpenDrawer, onTap: () => _todo(context, 'Открыть денежный ящик')),
      ActionTile(label: l.navSettingsShort, onTap: () => _openSettings(context, ref)),
      ActionTile(label: l.posActionGoodsCodes, onTap: () => _todo(context, 'Коды ТРУ')),
      ActionTile(label: l.posActionLock, onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
    ];
  }

  /// Open the SettingsScreen via a proper imperative push. Replaces an
  /// earlier `Navigator.pushNamed('/settings')` that crashed at runtime —
  /// the app's MaterialApp is configured with `home:` only, no named-route
  /// table is registered. The cashier's only path to settings is this tile
  /// (the sidebar in cashier mode shows only POS + Shift), so the route
  /// must work for non-admin users too.
  ///
  /// `onLogout` dispatches [LogoutRequested]; the root BlocBuilder reacts
  /// to the resulting state change and routes to PinScreen / OwnerLoginScreen.
  /// `popUntil` clears any settings-tree pages so the navigator stack
  /// doesn't end up with stale routes covering the new home widget.
  void _openSettings(BuildContext context, WidgetRef ref) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          api: context.read<ApiClient>(),
          role: role,
          onLogout: () {
            ref.read(authControllerProvider.notifier).logout();
            Navigator.of(context).popUntil((r) => r.isFirst);
          },
        ),
      ),
    );
  }

  Future<void> _openPayment(BuildContext context, WidgetRef ref, SalesState state) async {
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
    await ref.read(salesControllerProvider.notifier).completeSale(
          shiftId: shiftId!,
          cashierId: cashierId ?? '',
          paymentType: result['method'] as String? ?? 'cash',
          cashAmount: result['cash'] as int? ?? 0,
          cardAmount: result['card'] as int? ?? 0,
          qrAmount: result['qr'] as int? ?? 0,
          changeAmount: result['change'] as int? ?? 0,
          overrideUserId: overrideUserId,
        );
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

  void _openDiscountDialog(BuildContext context, WidgetRef ref, SalesState state) {
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
              ref.read(salesControllerProvider.notifier).applyDiscount((tenge * 100).round());
              Navigator.pop(ctx);
            },
            child: const Text('Применить'),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
  }

  void _showParked(BuildContext context, WidgetRef ref, SalesState state) {
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
                  ref.read(salesControllerProvider.notifier).resumeParkedCart(idx);
                },
              ),
            );
          }),
        ]),
      ),
    );
  }

  void _openSearch(BuildContext context, WidgetRef ref) {
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
              ref.read(salesControllerProvider.notifier).searchProduct(v);
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
class _TabletActionStrip extends ConsumerWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const _TabletActionStrip({this.shiftId, this.cashierId, required this.role});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(salesControllerProvider);
    final sales = ref.read(salesControllerProvider.notifier);
    final disabled = state.items.isEmpty;
    final panel = _CartActionPanel(shiftId: shiftId, cashierId: cashierId, role: role);
    final tiles = panel._buildTiles(context, ref, state).take(8).toList();
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
              onTap: disabled ? null : sales.clearCart,
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
                onTap: disabled ? null : () => panel._openPayment(context, ref, state),
                fontSize: 22,
              ),
            ),
          ),
        ]),
      ]),
    );
  }
}

