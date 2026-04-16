import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/num_pad.dart';
import '../../../services/api_client.dart';
import '../../../services/sales/sales_service.dart';
import '../bloc/sales_bloc.dart';
import '../models/cart_item.dart';
import '../sales_guards.dart';
import '../widgets/manager_override_dialog.dart';
import 'payment_screen.dart';

class PosScreen extends StatelessWidget {
  final String? shiftId;
  final String? cashierId;
  final String role;
  const PosScreen({super.key, this.shiftId, this.cashierId, this.role = 'cashier'});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
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
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 800) {
              return Row(children: [
                Expanded(flex: 5, child: _ProductPanel(role: role, cashierId: cashierId ?? '')),
                SizedBox(width: 380, child: _CartPanel(shiftId: shiftId, cashierId: cashierId)),
              ]);
            }
            return DefaultTabController(
              length: 2,
              child: Column(children: [
                Container(
                  color: cs.surface,
                  child: TabBar(tabs: [Tab(text: l.posTabProducts), Tab(text: l.posTabReceipt)]),
                ),
                Expanded(child: TabBarView(children: [
                  _ProductPanel(role: role, cashierId: cashierId ?? ''),
                  _CartPanel(shiftId: shiftId, cashierId: cashierId),
                ])),
              ]),
            );
          },
        ),
      ),
    );
  }
}

class _ProductPanel extends StatefulWidget {
  final String role;
  final String cashierId;
  const _ProductPanel({required this.role, required this.cashierId});

  @override
  State<_ProductPanel> createState() => _ProductPanelState();
}

class _ProductPanelState extends State<_ProductPanel> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<SalesBloc>().add(LoadCategories());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.isEmpty) {
      context.read<SalesBloc>().add(SearchProduct(''));
      return;
    }
    if (query.length < 3) return;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      context.read<SalesBloc>().add(SearchProduct(query));
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Column(children: [
      // Top bar with search
      Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        decoration: BoxDecoration(
          color: cs.surface.withValues(alpha: 0.8),
        ),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: l.posSearchHint,
                hintStyle: GoogleFonts.inter(color: cs.outline, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: cs.outline),
                suffixIcon: IconButton(
                  icon: Icon(Icons.clear_rounded, size: 18, color: cs.outline),
                  onPressed: () {
                    _searchController.clear();
                    context.read<SalesBloc>().add(SearchProduct(''));
                  },
                ),
                filled: true,
                fillColor: cs.surfaceContainerLow,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.3), width: 2)),
              ),
              onChanged: _onSearchChanged,
              onSubmitted: (query) {
                _debounce?.cancel();
                if (query.isNotEmpty) context.read<SalesBloc>().add(SearchProduct(query));
              },
            ),
          ),
          const SizedBox(width: 12),
          // Online status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_done_rounded, size: 16, color: Color(0xFF006C49)),
              const SizedBox(width: 6),
              Text(l.posOnline, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF006C49))),
            ]),
          ),
        ]),
      ),

      // Category chips (dynamic from server)
      BlocBuilder<SalesBloc, SalesState>(
        buildWhen: (prev, curr) =>
            prev.categories != curr.categories ||
            prev.selectedCategoryId != curr.selectedCategoryId,
        builder: (context, state) {
          return Container(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _CategoryChip(
                    label: l.posCatAll,
                    icon: Icons.apps_rounded,
                    selected: state.selectedCategoryId == null,
                    onTap: () => context.read<SalesBloc>().add(SelectCategory(null)),
                  ),
                  ...state.categories.map((cat) {
                    final id = cat['ID'] as String? ?? '';
                    final name = cat['Name'] as String? ?? '';
                    return _CategoryChip(
                      label: name,
                      icon: Icons.label_outline_rounded,
                      selected: state.selectedCategoryId == id,
                      onTap: () => context.read<SalesBloc>().add(SelectCategory(id)),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),

      // Product grid
      Expanded(
        child: BlocBuilder<SalesBloc, SalesState>(
          buildWhen: (prev, curr) =>
              prev.searchResults != curr.searchResults ||
              prev.isSearching != curr.isSearching ||
              prev.nktResults != curr.nktResults ||
              prev.isNktSearching != curr.isNktSearching ||
              prev.lastQuery != curr.lastQuery,
          builder: (context, state) {
            if (state.isSearching) return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));

            // No local results — show NKT panel, partial barcode hint, or empty state
            if (state.searchResults.isEmpty) {
              if (state.isNktSearching) {
                return _NktSearchingIndicator();
              }
              if (state.nktResults.isNotEmpty) {
                return _NktResultsPanel(
                  results: state.nktResults,
                  barcode: state.nktQuery ?? '',
                  role: widget.role,
                  cashierId: widget.cashierId,
                );
              }
              if (state.lastQuery.isNotEmpty) {
                return _NotFoundHint(query: state.lastQuery);
              }
              return _EmptySearch();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900 ? 4 : constraints.maxWidth > 600 ? 3 : 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) => _ProductCard(product: state.searchResults[index]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _CategoryChip({required this.label, required this.icon, this.selected = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppTheme.primary : const Color(0xFFEFF4FF),
        borderRadius: BorderRadius.circular(16),
        elevation: selected ? 4 : 0,
        shadowColor: selected ? AppTheme.primary.withValues(alpha: 0.3) : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 18, color: selected ? Colors.white : const Color(0xFF43474C)),
              const SizedBox(width: 8),
              Text(label, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF43474C),
              )),
            ]),
          ),
        ),
      ),
    );
  }
}

class _EmptySearch extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(22)),
          child: Icon(Icons.search_rounded, size: 36, color: cs.outline),
        ),
        const SizedBox(height: 20),
        Text(l.posEnterNameOr, style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 15)),
        const SizedBox(height: 4),
        Text(l.posScanBarcode, style: GoogleFonts.inter(color: cs.outline, fontSize: 14)),
      ]),
    );
  }
}

class _NotFoundHint extends StatelessWidget {
  final String query;
  const _NotFoundHint({required this.query});

  bool get _isAllDigits => query.isNotEmpty && query.codeUnits.every((c) => c >= 48 && c <= 57);
  bool get _isPartialBarcode => _isAllDigits && query.length < 8;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _isPartialBarcode ? pos.warningBg : cs.surfaceContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _isPartialBarcode ? Icons.qr_code_rounded : Icons.search_off_rounded,
              size: 32,
              color: _isPartialBarcode ? pos.warningFg : cs.outline,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l.posNotFoundLocally,
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_isPartialBarcode) ...[
            Text(
              l.posEnterFullBarcode,
              style: GoogleFonts.inter(fontSize: 14, color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l.posForAutoNkt,
              style: GoogleFonts.inter(fontSize: 13, color: cs.outline),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(10)),
              child: Text(
                l.posBarcodeProgress(query.length),
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: pos.warningFg),
              ),
            ),
          ] else
            Text(
              l.posNotFoundQuery(query),
              style: GoogleFonts.inter(fontSize: 13, color: cs.outline),
              textAlign: TextAlign.center,
            ),
        ]),
      ),
    );
  }
}

class _NktSearchingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context)!;
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 2.5)),
        const SizedBox(height: 16),
        Text(l.posSearchingNkt, style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text(l.posNotFoundLocallyHeader, style: GoogleFonts.inter(color: cs.outline, fontSize: 13)),
      ]),
    );
  }
}

class _NktResultsPanel extends StatelessWidget {
  final List<Map<String, dynamic>> results;
  final String barcode;
  final String role;
  final String cashierId;
  const _NktResultsPanel({
    required this.results,
    required this.barcode,
    required this.role,
    required this.cashierId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: pos.warningBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Icon(Icons.cloud_download_rounded, size: 22, color: pos.warningFg),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(l.posNotFoundLocallyHeader, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(l.posNktFoundCount(results.length, barcode),
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
            ])),
            IconButton(
              onPressed: () => context.read<SalesBloc>().add(ClearNktResults()),
              icon: Icon(Icons.close_rounded, size: 18, color: cs.outline),
              style: IconButton.styleFrom(fixedSize: const Size(32, 32)),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        Text(l.posNktSelectInstruction,
            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
        const SizedBox(height: 10),

        // NKT result cards
        Expanded(
          child: ListView.separated(
            itemCount: results.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _NktProductCard(
              product: results[i],
              barcode: barcode,
              role: role,
              cashierId: cashierId,
            ),
          ),
        ),
      ]),
    );
  }
}

class _NktProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final String barcode;
  final String role;
  final String cashierId;
  const _NktProductCard({
    required this.product,
    required this.barcode,
    required this.role,
    required this.cashierId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final nameRu = product['name_ru'] as String? ?? '';
    final nameKk = product['name_kk'] as String? ?? '';
    final ntinCode = product['ntin_code'] as String? ?? '';
    final isSocial = product['is_social'] as bool? ?? false;
    final measure = product['measure'];
    final measureName = measure is Map ? (measure['name'] as String? ?? '') : '';

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showQuickAddDialog(context, role, cashierId),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Row(children: [
            // NKT icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: pos.accentBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.verified_rounded, size: 22, color: pos.accentFg),
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nameRu, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: pos.successBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('NTIN: $ntinCode', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: pos.successFg)),
                ),
                if (measureName.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(measureName, style: GoogleFonts.inter(fontSize: 11, color: cs.outline)),
                ],
                if (isSocial) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(8)),
                    child: Text('СЗТ', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: pos.warningFg)),
                  ),
                ],
              ]),
              if (nameKk.isNotEmpty && nameKk != nameRu) ...[
                const SizedBox(height: 2),
                Text(nameKk, style: GoogleFonts.inter(fontSize: 11, color: cs.outline, fontStyle: FontStyle.italic),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ])),
            const SizedBox(width: 12),
            // Add button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [AppTheme.primary, AppTheme.primaryContainer]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                const SizedBox(width: 4),
                Text('Добавить', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  void _showQuickAddDialog(BuildContext context, String role, String cashierId) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final nameRu = product['name_ru'] as String? ?? '';
    final nameKk = product['name_kk'] as String? ?? '';
    final ntinCode = product['ntin_code'] as String? ?? '';
    final priceC = TextEditingController();
    final measure = product['measure'];
    final measureCode = measure is Map ? (measure['code'] as String? ?? '796') : '796';
    final isWeighted = measureCode == '166'; // kg

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.posNktAddTitle, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Product info card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(nameRu, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              if (nameKk.isNotEmpty && nameKk != nameRu) ...[
                const SizedBox(height: 2),
                Text(nameKk, style: GoogleFonts.inter(fontSize: 12, color: cs.outline, fontStyle: FontStyle.italic)),
              ],
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: pos.accentBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('GTIN: $barcode', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: pos.accentFg)),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: pos.successBg, borderRadius: BorderRadius.circular(8)),
                  child: Text('NTIN: $ntinCode', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: pos.successFg)),
                ),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          // Price input
          TextField(
            controller: priceC,
            autofocus: true,
            decoration: InputDecoration(
              labelText: isWeighted ? l.posNktPriceKg : l.posNktPricePcs,
              suffixText: '₸',
              prefixIcon: const Icon(Icons.sell_rounded),
            ),
            keyboardType: TextInputType.number,
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(
            onPressed: () async {
              final price = ((double.tryParse(priceC.text) ?? 0) * 100).round();
              if (price <= 0) return;

              final api = context.read<ApiClient>();
              final productId = 'nkt-${DateTime.now().millisecondsSinceEpoch}';
              final isOwner = role == 'owner' || role == 'admin';
              try {
                await api.createProduct({
                  'id': productId,
                  'name': nameRu,
                  'name_kz': nameKk,
                  'barcode_gtin': barcode,
                  'ntin': ntinCode,
                  'sale_unit': isWeighted ? 'kg' : 'pcs',
                  'sale_price': price,
                  'is_weighted': isWeighted,
                  'vat_rate': 12,
                  'is_active': isOwner,
                  'approval_status': isOwner ? 'approved' : 'pending_approval',
                  'submitted_by': cashierId,
                  'device_id': 'local-001',
                });

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  if (isOwner) {
                    // Owner: add to cart immediately
                    context.read<SalesBloc>().add(AddToCart(CartItem(
                      productId: productId,
                      name: nameRu,
                      ntin: ntinCode,
                      unit: isWeighted ? 'kg' : 'pcs',
                      basePrice: price,
                      isWeighted: isWeighted,
                      vatRate: 12,
                    )));
                  } else {
                    // Cashier: notify that product is pending approval
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l.posNktSentForApproval,
                          style: GoogleFonts.inter()),
                        backgroundColor: PosColors.of(context).warningFg,
                      ),
                    );
                  }
                }
              } on Exception catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.posNktCreateError(e.toString())), backgroundColor: pos.errorFg),
                  );
                }
              }
            },
            child: Text(l.posNktAddAndSell),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  const _ProductCard({required this.product});

  void _showQtyBeforeAddDialog(BuildContext context, Map<String, dynamic> p) {
    final l = AppLocalizations.of(context)!;
    final name = p['Name'] as String? ?? '';
    final controller = TextEditingController(text: '1');
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.posMultiAdd, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(name, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, _) => Text(
                value.text.isEmpty ? '0' : value.text,
                style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800),
              ),
            )),
          ),
          const SizedBox(height: 14),
          NumPad(controller: controller),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(onPressed: () {
            final qty = double.tryParse(controller.text) ?? 0;
            if (qty > 0) {
              final item = CartItem(
                productId: p['ID'] as String,
                name: name,
                ntin: p['NTIN'] as String?,
                unit: p['SaleUnit'] as String? ?? 'pcs',
                basePrice: (p['SalePrice'] as num?)?.toInt() ?? 0,
                isWeighted: p['IsWeighted'] as bool? ?? false,
                vatRate: (p['VATRate'] as num?)?.toInt() ?? 12,
                quantity: qty,
              );
              context.read<SalesBloc>().add(AddToCart(item));
            }
            Navigator.pop(ctx);
          }, child: Text(l.ok)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final name = product['Name'] as String? ?? '';
    final price = (product['SalePrice'] as num?)?.toInt() ?? 0;
    final isWeighted = product['IsWeighted'] as bool? ?? false;
    final unit = product['SaleUnit'] as String? ?? 'pcs';
    final ntin = product['NTIN'] as String?;

    return Material(
      color: cs.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          final item = CartItem(
            productId: product['ID'] as String, name: name, ntin: ntin,
            unit: unit, basePrice: price, isWeighted: isWeighted,
            vatRate: (product['VATRate'] as num?)?.toInt() ?? 12,
          );
          context.read<SalesBloc>().add(AddToCart(item));
        },
        onLongPress: () => _showQtyBeforeAddDialog(context, product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder area (matches Stitch rounded container)
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isWeighted ? pos.warningBg : pos.accentBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Stack(children: [
                    Center(
                      child: Icon(
                        isWeighted ? Icons.scale_rounded : Icons.inventory_2_outlined,
                        size: 36,
                        color: isWeighted ? pos.warningFg : pos.accentFg,
                      ),
                    ),
                    // NKT badge
                    if (ntin != null && ntin.isNotEmpty)
                      Positioned(
                        top: 8, left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: pos.successBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('НКТ', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: pos.successFg)),
                        ),
                      ),
                    // Add button overlay
                    Positioned(
                      bottom: 8, right: 8,
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.add_rounded, size: 18, color: cs.onSurface),
                      ),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 10),
              // Name
              Text(name,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(isWeighted ? l.productsTypeWeighted : l.productsTypePiece,
                style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 11, fontStyle: FontStyle.italic)),
              const SizedBox(height: 6),
              // Price (heroized per Stitch design)
              Text(isWeighted ? '${Money.format(price)}/кг' : Money.format(price),
                style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: AppTheme.primaryContainer,
                )),
            ],
          ),
        ),
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  final String? shiftId;
  final String? cashierId;
  const _CartPanel({this.shiftId, this.cashierId});

  void _openPayment(BuildContext context, SalesState state) async {
    if (shiftId == null || shiftId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.posOpenShiftFirst), backgroundColor: PosColors.of(context).warningFg),
      );
      return;
    }
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => PaymentScreen(
        totalTiyin: state.total,
        vatAmount: state.vatAmount,
        shiftId: shiftId,
        api: context.read<ApiClient>(),
        cashierId: cashierId,
      )),
    );
    if (result == null || !context.mounted) return;

    // T5.7d oversell-guard + manager-override pre-check. When the drift sales
    // path is not wired (`SalesGuards.disabled` — current production default),
    // skip straight to dispatching CompleteSale, preserving pre-T5.7d behaviour.
    String? overrideUserId;
    final guards = context.read<SalesGuards>();
    if (guards.isWired) {
      final lines = _cartToSalesLines(state.items);
      final shortages = await guards.guard!.check(lines);
      if (shortages.isNotEmpty) {
        if (!context.mounted) return;
        final subtitle = _subtitleFor(shortages);
        final manager = await ManagerOverrideDialog.show(
          context,
          service: guards.overrideService!,
          subtitle: subtitle,
        );
        if (manager == null) {
          // Cashier or manager cancelled — abort the sale. No error toast;
          // the cart stays intact so the cashier can recover.
          return;
        }
        overrideUserId = manager.id;
      }
    }

    if (!context.mounted) return;
    context.read<SalesBloc>().add(CompleteSale(
      shiftId: shiftId!, cashierId: cashierId ?? '',
      paymentType: result['method'] as String? ?? 'cash',
      cashAmount: result['cash'] as int? ?? 0,
      cardAmount: result['card'] as int? ?? 0,
      qrAmount: result['qr'] as int? ?? 0,
      changeAmount: result['change'] as int? ?? 0,
      overrideUserId: overrideUserId,
    ));
  }

  /// Mirror of the mapping in `SalesBloc._onCompleteSale` so the guard runs
  /// against the same inputs the BLoC will send. Keeping this local (not on
  /// CartItem itself) keeps the domain model free of the sales-service type.
  static List<SalesLineInput> _cartToSalesLines(List<CartItem> items) {
    return items.map((ci) => SalesLineInput(
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
    )).toList();
  }

  /// "Продажа ниже остатка: Coca-Cola — 3 шт при остатке 1; Хлеб — 500г при 200г"
  /// Shown in the override dialog so the authorising manager sees what they're
  /// approving without asking the cashier.
  static String _subtitleFor(List<dynamic> shortages) {
    final parts = shortages.map((s) {
      final unit = s.isWeighted as bool ? 'г' : 'шт';
      return '${s.productName} — ${s.requested}$unit при остатке ${s.onHand}$unit';
    }).join('; ');
    return 'Продажа ниже остатка: $parts';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    return BlocBuilder<SalesBloc, SalesState>(
      builder: (context, state) {
        final l = AppLocalizations.of(context)!;
        return Container(
          color: cs.surfaceContainerLow,
          child: Column(children: [
            // Parked carts indicator
            if (state.parkedCarts.isNotEmpty)
              _ParkedCartsBar(parkedCarts: state.parkedCarts),

            // Header (Stitch: "Current Order" with badge)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(l.posCartTitle,
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.primary)),
                  const Spacer(),
                  if (state.items.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('${state.itemCount} ${l.posCartItems}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF78A6FF))),
                    ),
                ]),
                const SizedBox(height: 6),
                Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.15)),
              ]),
            ),

            // Items
            Expanded(
              child: state.items.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(20)),
                        child: Icon(Icons.shopping_cart_outlined, size: 32, color: cs.outline),
                      ),
                      const SizedBox(height: 14),
                      Text(l.posCartEmpty, style: GoogleFonts.inter(color: cs.onSurfaceVariant, fontSize: 15, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(l.posCartEmptyHint, style: GoogleFonts.inter(color: cs.outline, fontSize: 13)),
                    ]))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: state.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 6),
                      itemBuilder: (context, index) => _CartItemTile(
                        item: state.items[index],
                        index: index,
                        onRemove: () => context.read<SalesBloc>().add(RemoveFromCart(index)),
                        onQuantityChanged: (qty) => context.read<SalesBloc>().add(UpdateQuantity(index, qty)),
                      ),
                    ),
            ),

            // Scale weight indicator (visible when weighted item in cart)
            if (state.items.any((i) => i.isWeighted))
              _ScaleIndicator(
                lastWeightedItem: state.items.lastWhere((i) => i.isWeighted),
              ),

            // Footer: totals + payment
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHigh,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 20, offset: const Offset(0, -8)),
                ],
              ),
              child: Column(children: [
                // Totals
                if (state.discountTiyin > 0) ...[
                  _SummaryRow('Подитого', Money.format(state.subtotal)),
                  _SummaryRow('Скидка', '-${Money.format(state.discountTiyin)}', color: pos.errorFg),
                ],
                _SummaryRow(l.posVat12, Money.format(state.vatAmount)),
                const SizedBox(height: 10),
                // Total (Stitch: heroized display scale)
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(l.posTotal, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                  Text(Money.format(state.total),
                    style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: -1.2, color: AppTheme.primary)),
                ]),
                const SizedBox(height: 16),

                // Payment button (gradient CTA)
                _GradientCta(
                  onPressed: state.items.isEmpty ? null : () => _openPayment(context, state),
                  icon: Icons.payments_rounded,
                  label: state.items.isEmpty ? l.posPayment : l.posPaymentWithAmount(Money.formatTenge(state.total)),
                ),

                const SizedBox(height: 10),
                // Quick actions row 1: Park + Undo
                Row(children: [
                  Expanded(child: SizedBox(height: 44, child: OutlinedButton.icon(
                    onPressed: state.items.isEmpty ? null : () {
                      context.read<SalesBloc>().add(ParkCart());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l.posParkCart), duration: const Duration(seconds: 2)),
                      );
                    },
                    icon: const Icon(Icons.pause_circle_outline_rounded, size: 18),
                    label: Text(l.posParkCart, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.secondary,
                      side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ))),
                  const SizedBox(width: 10),
                  Expanded(child: SizedBox(height: 44, child: OutlinedButton.icon(
                    onPressed: state.items.isEmpty ? null : () {
                      context.read<SalesBloc>().add(ClearCart());
                    },
                    icon: const Icon(Icons.cancel_outlined, size: 18),
                    label: Text(l.cancel, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: BorderSide(color: AppTheme.error.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ))),
                ]),
                // Undo button (shown after item removal)
                if (state.canUndo)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: TextButton.icon(
                        onPressed: () => context.read<SalesBloc>().add(UndoLastAction()),
                        icon: const Icon(Icons.undo_rounded, size: 16),
                        label: Text(l.posUndoRemove, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryContainer,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
          ]),
        );
      },
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<double> onQuantityChanged;
  const _CartItemTile({required this.item, required this.index, required this.onRemove, required this.onQuantityChanged});

  void _showQtyDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1),
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.posQuantity),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: controller,
              builder: (_, value, _) => Text(
                value.text.isEmpty ? '0' : value.text,
                style: GoogleFonts.inter(fontSize: 36, fontWeight: FontWeight.w800),
              ),
            )),
          ),
          const SizedBox(height: 14),
          NumPad(controller: controller),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(onPressed: () {
            final qty = double.tryParse(controller.text) ?? 0;
            if (qty > 0) onQuantityChanged(qty);
            Navigator.pop(ctx);
          }, child: Text(l.ok)),
        ],
      ),
    );
  }

  void _showItemDiscountDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final controller = TextEditingController(
      text: item.discount > 0 ? (item.discount / 100).toStringAsFixed(0) : '',
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.posItemDiscount, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l.posEnterDiscount, suffixText: '₸'),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(onPressed: () {
            final tenge = double.tryParse(controller.text) ?? 0;
            final tiyin = (tenge * 100).round();
            context.read<SalesBloc>().add(ApplyItemDiscount(index, tiyin));
            Navigator.pop(ctx);
          }, child: Text(l.ok)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final overStock = item.isOverStock;

    return Dismissible(
      key: ValueKey('cart-${item.productId}-$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: overStock ? pos.errorBg : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: overStock ? Border.all(color: pos.errorFg.withValues(alpha: 0.3)) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  item.isWeighted
                      ? '${item.weightGrams}г x ${Money.format(item.basePrice)}/кг'
                      : '${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)} x ${Money.format(item.basePrice)}',
                  style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
                ),
                if (item.discount > 0)
                  Text(
                    '-${Money.format(item.discount)}',
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: pos.errorFg),
                  ),
                const SizedBox(height: 4),
                Text(Money.format(item.total),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              ])),
              // Per-item discount button
              IconButton(
                onPressed: () => _showItemDiscountDialog(context),
                icon: Icon(
                  Icons.discount_outlined,
                  size: 18,
                  color: item.discount > 0 ? pos.errorFg : cs.outline,
                ),
                style: IconButton.styleFrom(fixedSize: const Size(34, 34)),
                tooltip: l.posItemDiscount,
              ),
              if (!item.isWeighted)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    _QtyButton(icon: Icons.remove, onTap: item.quantity > 1 ? () => onQuantityChanged(item.quantity - 1) : null),
                    GestureDetector(
                      onTap: () => _showQtyDialog(context),
                      child: SizedBox(width: 32, child: Text(
                        item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1),
                        textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
                      )),
                    ),
                    _QtyButton(icon: Icons.add, onTap: () => onQuantityChanged(item.quantity + 1)),
                  ]),
                ),
            ]),
            // Stock warning
            if (overStock)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, size: 14, color: pos.errorFg),
                  const SizedBox(width: 4),
                  Text(
                    l.posStockExceeded(item.stockQty.toStringAsFixed(item.stockQty == item.stockQty.roundToDouble() ? 0 : 1)),
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: pos.errorFg),
                  ),
                ]),
              ),
          ],
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: 34, height: 34, child: InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(8),
      child: Icon(icon, size: 16, color: onTap != null ? AppTheme.primaryContainer : const Color(0xFFC4C6CD)),
    ));
  }
}

class _ScaleIndicator extends StatelessWidget {
  final CartItem lastWeightedItem;
  const _ScaleIndicator({required this.lastWeightedItem});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final w = lastWeightedItem.weightGrams;
    final kg = (w / 1000).toStringAsFixed(3);
    final stable = w > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: stable ? pos.successBg : cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stable ? pos.successFg.withValues(alpha: 0.3) : cs.outlineVariant, width: 1),
      ),
      child: Row(children: [
        Icon(Icons.scale_rounded, size: 20, color: stable ? pos.successFg : cs.outline),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(lastWeightedItem.name,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
            maxLines: 1, overflow: TextOverflow.ellipsis),
          Text('$kg kg',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800,
              color: stable ? pos.successFg : cs.onSurface)),
        ])),
        if (w == 0)
          Text('--',
            style: GoogleFonts.inter(fontSize: 14, color: cs.outline, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _SummaryRow(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? const Color(0xFF43474C);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: GoogleFonts.inter(color: c, fontSize: 13)),
        Text(value, style: GoogleFonts.inter(color: c, fontSize: 13, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

// ─── Parked carts bar ────────────────────────────────────────

class _ParkedCartsBar extends StatelessWidget {
  final List<ParkedCart> parkedCarts;
  const _ParkedCartsBar({required this.parkedCarts});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: pos.warningBg,
      child: Row(children: [
        Icon(Icons.pause_circle_filled_rounded, size: 18, color: pos.warningFg),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${l.posParkedCarts}: ${parkedCarts.length}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: pos.warningFg),
          ),
        ),
        SizedBox(
          height: 28,
          child: TextButton(
            onPressed: () => _showParkedDialog(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              foregroundColor: pos.warningFg,
            ),
            child: Text(l.posResume, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  void _showParkedDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.posParkedCarts, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: 340,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: parkedCarts.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final cart = parkedCarts[i];
              final time = '${cart.parkedAt.hour.toString().padLeft(2, '0')}:${cart.parkedAt.minute.toString().padLeft(2, '0')}';
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(
                      l.posParkedCartLabel(cart.itemCount, Money.format(cart.total)),
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    Text(time, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF74777D))),
                  ])),
                  IconButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      context.read<SalesBloc>().add(ResumeParkedCart(i));
                    },
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    tooltip: l.posResume,
                  ),
                  IconButton(
                    onPressed: () {
                      context.read<SalesBloc>().add(DeleteParkedCart(i));
                      Navigator.pop(ctx);
                      if (parkedCarts.length > 1) {
                        _showParkedDialog(context);
                      }
                    },
                    icon: Icon(Icons.delete_outline, size: 20, color: PosColors.of(context).errorFg),
                    tooltip: l.posDelete,
                  ),
                ]),
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
}

/// Gradient CTA button matching Stitch design (primary → primaryContainer at 135°)
class _GradientCta extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;

  const _GradientCta({required this.onPressed, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primary, AppTheme.primaryContainer],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: enabled
              ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            splashColor: Colors.white.withValues(alpha: 0.1),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(icon, size: 22, color: Colors.white),
              const SizedBox(width: 10),
              Text(label, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.3)),
            ]),
          ),
        ),
      ),
    );
  }
}
