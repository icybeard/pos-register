import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';
import '../../../services/products/product_catalog_service.dart';

class ProductsScreen extends StatefulWidget {
  final ApiClient api;

  /// Read-path catalog source. Injected so the screen doesn't know whether
  /// rows come from the Go HTTP server or local drift. Defaults to the
  /// legacy HTTP path for back-compat at call sites that haven't been migrated.
  final ProductCatalogService? catalog;

  const ProductsScreen({super.key, required this.api, this.catalog});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;
  String _search = '';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      // If a catalog service was injected (flag-driven factory), use it. This is
      // the T4.4 data-source swap — the rest of the screen still works off the
      // PascalCase map shape, so we adapt the service's canonical entries back
      // into maps. Write ops (create/update/delete/generateLabels) stay on
      // `widget.api` for this wave; they migrate behind their own flag later.
      List<Map<String, dynamic>> rows;
      if (widget.catalog case final svc?) {
        final entries = await svc.list(includeInactive: true);
        rows = entries.map(_entryToLegacyMap).toList();
      } else {
        final resp = await widget.api.listProducts();
        rows = (resp['products'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      }
      setState(() {
        _products = rows;
        _loading = false;
      });
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки товаров: ${e is ApiException ? "Сервер недоступен" : "Нет связи"}')),
        );
      }
    }
  }

  /// Bridge the canonical [ProductCatalogEntry] to the PascalCase Go-server map
  /// shape the UI widgets in this file were written against. Removed when the
  /// screen is fully ported to the entry type (tracked as T4.4c).
  static Map<String, dynamic> _entryToLegacyMap(ProductCatalogEntry e) => {
        'ID': e.id,
        'Name': e.name,
        'NameKZ': e.nameKz,
        'BarcodeGTIN': e.barcodeGtin,
        'NTIN': e.ntin,
        'SalePrice': e.salePriceTiyin,
        'SaleUnit': e.saleUnit,
        'IsWeighted': e.isWeighted,
        'VATRate': e.vatRate,
        'IsActive': e.isActive,
      };

  List<Map<String, dynamic>> get _filtered {
    var list = _products;
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) {
        final name = (p['Name'] as String? ?? '').toLowerCase();
        final barcode = (p['BarcodeGTIN'] as String? ?? '').toLowerCase();
        return name.contains(q) || barcode.contains(q);
      }).toList();
    }
    final tab = _tabController.index;
    if (tab == 1) list = list.where((p) => p['IsWeighted'] == true).toList();
    if (tab == 2) list = list.where((p) => p['IsWeighted'] != true).toList();
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final weighted = _products.where((p) => p['IsWeighted'] == true).length;
    final piece = _products.length - weighted;
    final avgPrice = _products.isEmpty
        ? 0
        : _products.fold<int>(0, (s, p) => s + ((p['SalePrice'] as num?)?.toInt() ?? 0)) ~/ _products.length;

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
                          Text(l.productsTitle, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          const SizedBox(height: 4),
                          Text(l.productsCountLabel(_products.length),
                              style: TextStyle(fontFamily: 'Inter', fontSize: 14, color: cs.onSurfaceVariant)),
                        ]),
                      ),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddDialog(context),
                          icon: const Icon(Icons.add_rounded, size: 20),
                          label: Text(l.add, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600)),
                        ),
                      ),
                    ]),
                  ),
                ),

                // Stat cards
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 600;
                      if (isWide) {
                        return Row(children: [
                          Expanded(child: _BentoStatCard(
                            label: l.productsTotalStat, value: '${_products.length}',
                            icon: Icons.inventory_2_rounded, accentColor: pos.accentFg,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _BentoStatCard(
                            label: l.productsWeightedStat, value: '$weighted',
                            icon: Icons.scale_rounded, accentColor: pos.warningFg,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _BentoStatCard(
                            label: l.productsPieceStat, value: '$piece',
                            icon: Icons.category_rounded, accentColor: pos.successFg,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _BentoStatCard(
                            label: l.productsAvgPriceStat, value: Money.format(avgPrice),
                            icon: Icons.analytics_rounded, accentColor: cs.primary,
                          )),
                        ]);
                      }
                      return Column(children: [
                        Row(children: [
                          Expanded(child: _BentoStatCard(
                            label: l.productsTotalShort, value: '${_products.length}',
                            icon: Icons.inventory_2_rounded, accentColor: pos.accentFg,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _BentoStatCard(
                            label: l.productsWeightedStat, value: '$weighted',
                            icon: Icons.scale_rounded, accentColor: pos.warningFg,
                          )),
                        ]),
                        const SizedBox(height: 12),
                        Row(children: [
                          Expanded(child: _BentoStatCard(
                            label: l.productsPieceStat, value: '$piece',
                            icon: Icons.category_rounded, accentColor: pos.successFg,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _BentoStatCard(
                            label: l.productsAvgPriceShort, value: Money.format(avgPrice),
                            icon: Icons.analytics_rounded, accentColor: cs.primary,
                          )),
                        ]),
                      ]);
                    }),
                  ),
                ),

                // Search + Tabs
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                        boxShadow: [
                          const BoxShadow(color: Color(0x140D1C2F), blurRadius: 48, offset: Offset(0, 24), spreadRadius: -12),
                        ],
                      ),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                          child: Row(children: [
                            Expanded(
                              child: TextField(
                                onChanged: (v) => setState(() => _search = v),
                                decoration: InputDecoration(
                                  hintText: l.productsSearchHint,
                                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                                  filled: true,
                                  fillColor: cs.surfaceContainerLow,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
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
                          ]),
                        ),
                        TabBar(
                          controller: _tabController,
                          onTap: (_) => setState(() {}),
                          tabs: [
                            Tab(text: l.productsTabAll(_products.length)),
                            Tab(text: l.productsTabWeighted(weighted)),
                            Tab(text: l.productsTabPiece(piece)),
                          ],
                        ),
                      ]),
                    ),
                  ),
                ),

                // Table header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow.withValues(alpha: 0.5),
                      ),
                      child: Row(children: [
                        const SizedBox(width: 52),
                        Expanded(flex: 3, child: Text(l.productsColName, style: _headerStyle(cs))),
                        Expanded(flex: 2, child: Text(l.productsColBarcode, style: _headerStyle(cs))),
                        Expanded(flex: 1, child: Text(l.productsColVat, style: _headerStyle(cs))),
                        Expanded(flex: 2, child: Text(l.productsColPrice, style: _headerStyle(cs), textAlign: TextAlign.right)),
                        const SizedBox(width: 48),
                      ]),
                    ),
                  ),
                ),

                // Product rows
                _filtered.isEmpty
                    ? SliverToBoxAdapter(child: _buildEmpty(context))
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _ProductRow(
                              product: _filtered[i],
                              index: i,
                              isLast: i == _filtered.length - 1,
                              onDelete: () => _deleteProduct(_filtered[i]),
                              onPrintLabel: () => _printLabel(_filtered[i]),
                              onEdit: () => _showEditDialog(context, _filtered[i]),
                            ),
                            childCount: _filtered.length,
                          ),
                        ),
                      ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  TextStyle _headerStyle(ColorScheme cs) => TextStyle(fontFamily: 'Inter', 
        fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline,
        letterSpacing: 0.8,
      );

  Widget _buildEmpty(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Container(
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
            child: Icon(Icons.inventory_2_outlined, size: 32, color: cs.outline),
          ),
          const SizedBox(height: 16),
          Text(_search.isNotEmpty ? l.productsNotFound : l.productsEmpty,
              style: const TextStyle(fontFamily: 'Inter', fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            _search.isNotEmpty
                ? l.productsTryAnother
                : l.productsEmptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(fontFamily: 'Inter', color: cs.outline, fontSize: 13),
          ),
        ]),
      ),
    );
  }

  Future<void> _printLabel(Map<String, dynamic> p) async {
    final id = p['ID'] as String?;
    if (id == null) return;
    try {
      final pdfBytes = await widget.api.generateLabels(productIds: [id]);
      if (!mounted) return;
      await Printing.layoutPdf(
        onLayout: (_) => Future.value(pdfBytes),
        name: 'label-$id',
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
      }
    }
  }

  Future<void> _deleteProduct(Map<String, dynamic> p) async {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.productsDeleteConfirm),
        content: Text(p['Name'] as String? ?? ''),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: pos.errorFg),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      try {
        await widget.api.deleteProduct(p['ID'] as String);
        if (mounted) await _load();
      } on Exception catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
        }
      }
    }
  }

  void _showEditDialog(BuildContext context, Map<String, dynamic> product) {
    final l = AppLocalizations.of(context)!;
    final nameC = TextEditingController(text: product['Name'] as String? ?? '');
    final salePriceC = TextEditingController(
      text: Money.tiyinToTenge((product['SalePrice'] as num?)?.toInt() ?? 0).toStringAsFixed(0),
    );
    final purchasePriceC = TextEditingController(
      text: Money.tiyinToTenge((product['PurchasePrice'] as num?)?.toInt() ?? 0).toStringAsFixed(0),
    );
    final barcodeC = TextEditingController(text: product['BarcodeGTIN'] as String? ?? '');
    bool isWeighted = product['IsWeighted'] as bool? ?? false;
    bool submitting = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.productsEdit, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(controller: nameC, decoration: InputDecoration(labelText: l.productsFieldName)),
              const SizedBox(height: 14),
              TextField(controller: barcodeC, decoration: InputDecoration(labelText: l.productsFieldBarcode), keyboardType: TextInputType.number),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: TextField(
                  controller: purchasePriceC,
                  decoration: InputDecoration(labelText: l.productsPurchasePrice, suffixText: '₸'),
                  keyboardType: TextInputType.number,
                )),
                const SizedBox(width: 12),
                Expanded(child: TextField(
                  controller: salePriceC,
                  decoration: InputDecoration(labelText: l.productsSalePrice, suffixText: '₸'),
                  keyboardType: TextInputType.number,
                )),
              ]),
              const SizedBox(height: 14),
              // Margin display
              Builder(builder: (_) {
                final purchase = (double.tryParse(purchasePriceC.text) ?? 0) * 100;
                final sale = (double.tryParse(salePriceC.text) ?? 0) * 100;
                final margin = purchase > 0 ? ((sale - purchase) / purchase * 100).round() : 0;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: margin > 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(l.productsMargin, style: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600)),
                    Text('$margin%', style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700,
                      color: margin > 0 ? const Color(0xFF059669) : const Color(0xFFD97706))),
                  ]),
                );
              }),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(l.productsWeighted, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                  value: isWeighted,
                  onChanged: (v) => setDialogState(() => isWeighted = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: submitting
                  ? null
                  : () async {
                      setDialogState(() => submitting = true);
                      final salePrice = ((double.tryParse(salePriceC.text) ?? 0) * 100).round();
                      final purchasePrice = ((double.tryParse(purchasePriceC.text) ?? 0) * 100).round();
                      try {
                        await widget.api.updateProduct(product['ID'] as String, {
                          'name': nameC.text,
                          'barcode_gtin': barcodeC.text,
                          'sale_price': salePrice,
                          'purchase_price': purchasePrice,
                          'is_weighted': isWeighted,
                          'sale_unit': isWeighted ? 'kg' : 'pcs',
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (mounted) await _load();
                      } on Exception catch (e) {
                        if (ctx.mounted) setDialogState(() => submitting = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
              child: submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(l.save),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // Controllers must be disposed when the dialog closes (any path —
      // Cancel, Save success, Save error, barrier dismiss). Without this,
      // each open leaks a TextEditingController + the listenable it
      // registers with the framework.
      nameC.dispose();
      salePriceC.dispose();
      purchasePriceC.dispose();
      barcodeC.dispose();
    });
  }

  void _showAddDialog(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final barcodeC = TextEditingController();
    String ntin = '', nameKZ = '';
    bool isWeighted = false, nktLoading = false;
    String? nktStatus;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.productsNew, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: barcodeC,
                    decoration: InputDecoration(labelText: l.productsFieldBarcode),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: nktLoading
                        ? null
                        : () async {
                            final code = barcodeC.text.trim();
                            if (code.isEmpty) {
                              setDialogState(() => nktStatus = l.productsEnterBarcode);
                              return;
                            }
                            setDialogState(() {
                              nktLoading = true;
                              nktStatus = null;
                            });
                            try {
                              final resp = await widget.api.nktSearchByGTIN(code);
                              final products = resp['products'] as List?;
                              if (products != null && products.isNotEmpty) {
                                final p = products[0] as Map<String, dynamic>;
                                setDialogState(() {
                                  nameC.text = p['name_ru'] as String? ?? '';
                                  nameKZ = p['name_kk'] as String? ?? '';
                                  ntin = p['ntin_code'] as String? ?? '';
                                  nktStatus = 'NTIN: $ntin';
                                  nktLoading = false;
                                });
                              } else {
                                setDialogState(() {
                                  nktStatus = l.productsNktNotFound;
                                  nktLoading = false;
                                });
                              }
                            } on Exception catch (e) {
                              setDialogState(() {
                                nktStatus = l.productsNktError(e.toString());
                                nktLoading = false;
                              });
                            }
                          },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 16)),
                    child: nktLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(l.productsNkt),
                  ),
                ),
              ]),
              if (nktStatus != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: ntin.isNotEmpty ? pos.successBg : pos.warningBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    nktStatus!,
                    style: TextStyle(fontFamily: 'Inter', 
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: ntin.isNotEmpty ? pos.successFg : pos.warningFg,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              TextField(controller: nameC, decoration: InputDecoration(labelText: l.productsFieldName)),
              const SizedBox(height: 14),
              TextField(
                controller: priceC,
                decoration: InputDecoration(labelText: l.productsFieldPrice, suffixText: '₸'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SwitchListTile(
                  title: Text(l.productsWeighted, style: const TextStyle(fontFamily: 'Inter', fontSize: 14)),
                  subtitle: Text(
                    isWeighted ? l.productsWeightedSubPriceKg : l.productsWeightedSubPricePcs,
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
                  ),
                  value: isWeighted,
                  onChanged: (v) => setDialogState(() => isWeighted = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () async {
                final price = ((double.tryParse(priceC.text) ?? 0) * 100).round();
                await widget.api.createProduct({
                  'id': 'p-${DateTime.now().millisecondsSinceEpoch}',
                  'name': nameC.text,
                  'name_kz': nameKZ,
                  'barcode_gtin': barcodeC.text,
                  'ntin': ntin,
                  'sale_unit': isWeighted ? 'kg' : 'pcs',
                  'sale_price': price,
                  'is_weighted': isWeighted,
                  // Locked invariant: KZ retail uses 12% (standard) or 0%
                  // (zero-rated) — never 10% or 20%. Standard VAT is the
                  // default for new products; user can edit later for
                  // zero-rated items via the edit dialog (P2).
                  'vat_rate': AppConstants.vatRateStandard,
                  'is_active': true,
                  // device_id pulled from DeviceIdStore in pos-register's
                  // boot path; for products created via the admin-style
                  // dialog here we don't have a workstation context, so
                  // 'local-001' is a placeholder until the products screen
                  // gains real owner-flow wiring (P2). The server stamps
                  // the actual creator from the JWT regardless.
                  'device_id': 'local-001',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) await _load();
              },
              child: Text(l.create),
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      // See _showEditDialog: controllers must be disposed on every dialog
      // exit path; otherwise each open leaks one + its listeners.
      nameC.dispose();
      priceC.dispose();
      barcodeC.dispose();
    });
  }
}

class _BentoStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accentColor;

  const _BentoStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          const BoxShadow(color: Color(0x0A0D1C2F), blurRadius: 24, offset: Offset(0, 8)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: accentColor),
          ),
          const Spacer(),
        ]),
        const SizedBox(height: 14),
        Text(value, style: const TextStyle(fontFamily: 'Inter', fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontFamily: 'Inter', 
          fontSize: 11, fontWeight: FontWeight.w700, color: cs.outline, letterSpacing: 0.8,
        )),
        const SizedBox(height: 8),
        Container(height: 3, decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(2))),
      ]),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final Map<String, dynamic> product;
  final int index;
  final bool isLast;
  final VoidCallback onDelete;
  final VoidCallback onPrintLabel;
  final VoidCallback onEdit;

  const _ProductRow({required this.product, required this.index, required this.isLast, required this.onDelete, required this.onPrintLabel, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final isWeighted = product['IsWeighted'] as bool? ?? false;
    final price = (product['SalePrice'] as num?)?.toInt() ?? 0;
    final purchasePrice = (product['PurchasePrice'] as num?)?.toInt() ?? 0;
    final name = product['Name'] as String? ?? '';
    final barcode = product['BarcodeGTIN'] as String? ?? '';
    final ntin = product['NTIN'] as String? ?? '';
    final vatRate = product['VATRate'] as num? ?? 12;
    final stockQty = (product['StockQty'] as num?)?.toDouble() ?? -1;
    final isEven = index.isEven;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isEven ? cs.surfaceContainerLowest : cs.surfaceContainerLow.withValues(alpha: 0.4),
        borderRadius: isLast ? const BorderRadius.vertical(bottom: Radius.circular(20)) : null,
      ),
      child: Row(children: [
        // Product icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isWeighted ? pos.warningBg : pos.accentBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isWeighted ? Icons.scale_rounded : Icons.inventory_2_outlined,
            size: 18,
            color: isWeighted ? pos.warningFg : pos.accentFg,
          ),
        ),
        const SizedBox(width: 12),

        // Name + type
        Expanded(
          flex: 3,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isWeighted ? pos.warningBg : pos.successBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isWeighted ? l.productsTypeWeighted : l.productsTypePiece,
                  style: TextStyle(fontFamily: 'Inter', 
                    fontSize: 10, fontWeight: FontWeight.w600,
                    color: isWeighted ? pos.warningFg : pos.successFg,
                  ),
                ),
              ),
              if (ntin.isNotEmpty) ...[
                const SizedBox(width: 6),
                Icon(Icons.verified, size: 13, color: pos.successFg),
              ],
            ]),
          ]),
        ),

        // Barcode
        Expanded(
          flex: 2,
          child: Text(
            barcode.isNotEmpty ? barcode : '—',
            style: TextStyle(fontFamily: 'JetBrainsMono', fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // VAT
        Expanded(
          flex: 1,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: cs.surfaceContainer, borderRadius: BorderRadius.circular(8)),
            child: Text('$vatRate%', style: TextStyle(fontFamily: 'Inter', fontSize: 12, fontWeight: FontWeight.w500, color: cs.outline),
                textAlign: TextAlign.center),
          ),
        ),

        // Price + margin
        Expanded(
          flex: 2,
          child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              isWeighted ? '${Money.format(price)}/кг' : Money.format(price),
              style: TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w700, color: cs.primary),
              textAlign: TextAlign.right,
            ),
            if (purchasePrice > 0)
              Text(
                '+${((price - purchasePrice) / purchasePrice * 100).round()}%',
                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: FontWeight.w600,
                  color: price > purchasePrice ? pos.successFg : pos.errorFg),
              ),
          ]),
        ),

        // Stock qty
        SizedBox(
          width: 50,
          child: Column(children: [
            Text(
              stockQty >= 0 ? stockQty.toStringAsFixed(stockQty == stockQty.roundToDouble() ? 0 : 1) : '—',
              style: TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600,
                color: stockQty >= 0 && stockQty <= 5 ? pos.errorFg : cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            Text(l.productsStock, style: TextStyle(fontFamily: 'Inter', fontSize: 8, color: cs.outline), textAlign: TextAlign.center),
          ]),
        ),

        // Actions: edit, label, delete
        SizedBox(
          width: 40,
          child: PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, size: 18, color: cs.outline),
            onSelected: (action) {
              switch (action) {
                case 'edit': onEdit();
                case 'label': onPrintLabel();
                case 'delete': onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'edit', child: Row(children: [
                const Icon(Icons.edit_outlined, size: 18), const SizedBox(width: 8), Text(l.productsEdit),
              ])),
              PopupMenuItem(value: 'label', child: Row(children: [
                const Icon(Icons.label_outline_rounded, size: 18), const SizedBox(width: 8), Text(l.productsNkt),
              ])),
              PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: pos.errorFg), const SizedBox(width: 8),
                Text(l.delete, style: TextStyle(color: pos.errorFg)),
              ])),
            ],
          ),
        ),
      ]),
    );
  }
}
