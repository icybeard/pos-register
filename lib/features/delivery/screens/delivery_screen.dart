import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

class DeliveryScreen extends StatefulWidget {
  final ApiClient api;
  final String cashierId;
  final String cashierName;

  const DeliveryScreen({
    super.key,
    required this.api,
    required this.cashierId,
    required this.cashierName,
  });

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _searchCtrl = TextEditingController();
  final _docNumberCtrl = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _searching = false;
  final List<_DeliveryLine> _lines = [];
  bool _submitting = false;

  // Suppliers
  List<Map<String, dynamic>> _suppliers = [];
  String? _selectedSupplierId;

  // History
  bool _showHistory = false;
  List<dynamic> _history = [];
  bool _loadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _docNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    try {
      final resp = await widget.api.listSuppliers();
      if (mounted) {
        setState(() => _suppliers = (resp['suppliers'] as List?)?.cast<Map<String, dynamic>>() ?? []);
      }
    } on Exception catch (_) {}
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final resp = await widget.api.listDeliveries();
      if (mounted) {
        setState(() {
          _history = (resp['deliveries'] as List?) ?? [];
          _loadingHistory = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final resp = await widget.api.searchProducts(q.trim(), limit: 20);
      if (mounted) {
        setState(() {
          _searchResults = (resp['products'] as List?) ?? [];
          _searching = false;
        });
      }
    } on Exception catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _addProduct(Map<String, dynamic> product) {
    final id = product['ID'] as String? ?? product['id'] as String? ?? '';
    final idx = _lines.indexWhere((l) => l.productId == id);
    final name = product['Name'] as String? ?? product['name'] as String? ?? '';
    final costPrice = (product['PurchasePrice'] as num?)?.toInt() ??
        (product['purchase_price'] as num?)?.toInt() ??
        (product['cost_price'] as num?)?.toInt() ?? 0;
    setState(() {
      if (idx >= 0) {
        _lines[idx] = _lines[idx].copyWith(qty: _lines[idx].qty + 1);
      } else {
        _lines.add(_DeliveryLine(
          productId: id,
          name: name,
          costPrice: costPrice,
          qty: 1,
          expectedQty: 0, // user can enter expected qty for discrepancy
        ));
      }
      _searchCtrl.clear();
      _searchResults = [];
    });
  }

  void _removeLine(int idx) => setState(() => _lines.removeAt(idx));

  void _updateLine(int idx, _DeliveryLine updated) {
    setState(() => _lines[idx] = updated);
  }

  Future<void> _submit() async {
    if (_lines.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await widget.api.createDelivery(
        cashierId: widget.cashierId,
        cashierName: widget.cashierName,
        items: _lines.map((l) => {
          'product_id': l.productId,
          'qty': l.qty,
          'cost_price': l.costPrice,
        }).toList(),
      );
      if (mounted) {
        setState(() {
          _lines.clear();
          _submitting = false;
          _docNumberCtrl.clear();
          _selectedSupplierId = null;
        });
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l.deliverySuccess, style: GoogleFonts.inter()),
            backgroundColor: PosColors.of(context).successFg,
          ),
        );
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        final l = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l.errorPrefix(e.toString())), backgroundColor: PosColors.of(context).errorFg),
        );
      }
    }
  }

  void _showAddSupplierDialog() {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.deliveryAddSupplier, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameC, decoration: InputDecoration(labelText: l.productsFieldName), autofocus: true),
          const SizedBox(height: 12),
          TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Телефон'), keyboardType: TextInputType.phone),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
          ElevatedButton(onPressed: () async {
            if (nameC.text.trim().isEmpty) return;
            try {
              await widget.api.createSupplier(name: nameC.text.trim(), phone: phoneC.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
              await _loadSuppliers();
            } on Exception catch (e) {
              messenger.showSnackBar(SnackBar(content: Text('$e')));
            }
          }, child: Text(l.create)),
        ],
      ),
    );
  }

  void _showCreateProductDialog() {
    final l = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final nameC = TextEditingController();
    final priceC = TextEditingController();
    final barcodeC = TextEditingController();
    bool isWeighted = false;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(l.deliveryCreateProduct, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: nameC, decoration: InputDecoration(labelText: l.productsFieldName)),
            const SizedBox(height: 12),
            TextField(controller: barcodeC, decoration: InputDecoration(labelText: l.productsFieldBarcode), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            TextField(controller: priceC, decoration: InputDecoration(labelText: l.productsPurchasePrice, suffixText: '₸'), keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            SwitchListTile(
              title: Text(l.productsWeighted, style: GoogleFonts.inter(fontSize: 14)),
              value: isWeighted,
              onChanged: (v) => setDialogState(() => isWeighted = v),
              contentPadding: EdgeInsets.zero,
            ),
          ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.cancel)),
            ElevatedButton(onPressed: () async {
              if (nameC.text.trim().isEmpty) return;
              final price = ((double.tryParse(priceC.text) ?? 0) * 100).round();
              final id = 'p-${DateTime.now().millisecondsSinceEpoch}';
              try {
                await widget.api.createProduct({
                  'id': id,
                  'name': nameC.text.trim(),
                  'barcode_gtin': barcodeC.text.trim(),
                  'sale_unit': isWeighted ? 'kg' : 'pcs',
                  'purchase_price': price,
                  'sale_price': price,
                  'is_weighted': isWeighted,
                  'vat_rate': 12,
                  'is_active': true,
                  'device_id': 'local-001',
                });
                if (ctx.mounted) Navigator.pop(ctx);
                // Auto-add to delivery
                _addProduct({'ID': id, 'Name': nameC.text.trim(), 'PurchasePrice': price});
              } on Exception catch (e) {
                messenger.showSnackBar(SnackBar(content: Text('$e')));
              }
            }, child: Text(l.create)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width >= 700;

    return Scaffold(
      body: isWide ? _buildWide(context, cs) : _buildNarrow(context, cs),
    );
  }

  Widget _buildWide(BuildContext context, ColorScheme cs) {
    return Row(children: [
      Expanded(child: _showHistory ? _buildHistoryPanel(cs) : _buildSearchPanel(context, cs)),
      const VerticalDivider(width: 1),
      SizedBox(width: 400, child: _buildLinesPanel(context, cs)),
    ]);
  }

  Widget _buildNarrow(BuildContext context, ColorScheme cs) {
    return Column(children: [
      SizedBox(height: 280, child: _showHistory ? _buildHistoryPanel(cs) : _buildSearchPanel(context, cs)),
      const Divider(height: 1),
      Expanded(child: _buildLinesPanel(context, cs)),
    ]);
  }

  Widget _buildSearchPanel(BuildContext context, ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(children: [
          Text(l.deliveryTitle, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const Spacer(),
          // History toggle
          TextButton.icon(
            onPressed: () {
              setState(() => _showHistory = true);
              _loadHistory();
            },
            icon: const Icon(Icons.history_rounded, size: 18),
            label: Text(l.deliveryHistory, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),

      // Supplier + document number
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _selectedSupplierId,
              decoration: InputDecoration(
                labelText: l.deliverySupplier,
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              isExpanded: true,
              items: [
                ..._suppliers.map((s) => DropdownMenuItem(
                  value: s['ID'] as String,
                  child: Text(s['Name'] as String? ?? '', overflow: TextOverflow.ellipsis),
                )),
              ],
              onChanged: (v) => setState(() => _selectedSupplierId = v),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: IconButton(
              onPressed: _showAddSupplierDialog,
              icon: Icon(Icons.person_add_outlined, color: pos.accentFg),
              tooltip: l.deliveryAddSupplier,
              style: IconButton.styleFrom(
                backgroundColor: pos.accentBg,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TextField(
          controller: _docNumberCtrl,
          decoration: InputDecoration(
            labelText: l.deliveryDocNumber,
            prefixIcon: const Icon(Icons.description_outlined, size: 20),
            filled: true,
            fillColor: cs.surfaceContainerLowest,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          ),
        ),
      ),
      const SizedBox(height: 8),

      // Product search
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: l.deliverySearchHint,
                prefixIcon: _searching
                    ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                    : const Icon(Icons.search_rounded),
                filled: true,
                fillColor: cs.surfaceContainerLowest,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _showCreateProductDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(l.deliveryCreateProduct, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ]),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          itemCount: _searchResults.length,
          itemBuilder: (context, i) {
            final p = _searchResults[i] as Map<String, dynamic>;
            final name = p['Name'] as String? ?? p['name'] as String? ?? '';
            final costPrice = (p['PurchasePrice'] as num?)?.toInt() ?? (p['purchase_price'] as num?)?.toInt() ?? (p['cost_price'] as num?)?.toInt() ?? 0;
            return ListTile(
              title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              subtitle: Text(l.deliveryCostLabel(Money.format(costPrice)), style: GoogleFonts.inter(fontSize: 12)),
              trailing: IconButton(icon: const Icon(Icons.add_circle_outline_rounded), onPressed: () => _addProduct(p)),
              onTap: () => _addProduct(p),
            );
          },
        ),
      ),
    ]);
  }

  Widget _buildHistoryPanel(ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        child: Row(children: [
          Text(l.deliveryHistory, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => _showHistory = false),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: Text(l.deliveryTitle, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ]),
      ),
      Expanded(
        child: _loadingHistory
            ? const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            : _history.isEmpty
                ? Center(child: Text(l.deliveryNoHistory, style: GoogleFonts.inter(color: cs.outline)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _history.length,
                    itemBuilder: (context, i) {
                      final h = _history[i] as Map<String, dynamic>;
                      final name = h['product_name'] as String? ?? '';
                      final qty = (h['quantity'] as num?)?.toDouble() ?? 0;
                      final createdAt = h['created_at'] as String? ?? '';
                      String dateStr = '';
                      try {
                        final dt = DateTime.parse(createdAt).toLocal();
                        dateStr = '${dt.day}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
                      } on FormatException catch (_) {}
                      return ListTile(
                        leading: Icon(Icons.inventory_rounded, color: cs.primary),
                        title: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                        subtitle: Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: cs.outline)),
                        trailing: Text('+${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1)}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: PosColors.of(context).successFg)),
                      );
                    },
                  ),
      ),
    ]);
  }

  Widget _buildLinesPanel(BuildContext context, ColorScheme cs) {
    final l = AppLocalizations.of(context)!;
    final pos = PosColors.of(context);
    final totalCost = _lines.fold<int>(0, (sum, line) => sum + line.costPrice * line.qty);

    // Check discrepancies
    final hasDiscrepancy = _lines.any((line) => line.expectedQty > 0 && line.qty != line.expectedQty);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(children: [
          Text(l.deliveryLinesLabel(_lines.length), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700)),
          const Spacer(),
          if (_lines.isNotEmpty)
            Text(Money.format(totalCost), style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: cs.primary)),
        ]),
      ),

      // Discrepancy warning
      if (hasDiscrepancy)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: pos.warningBg, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.warning_amber_rounded, size: 16, color: pos.warningFg),
              const SizedBox(width: 8),
              Text(l.deliveryDiscrepancy, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: pos.warningFg)),
            ]),
          ),
        ),

      Expanded(
        child: _lines.isEmpty
            ? Center(child: Text(l.deliveryEmptyHint, style: GoogleFonts.inter(color: cs.outline)))
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: _lines.length,
                itemBuilder: (context, i) => _LineCard(
                  line: _lines[i],
                  onRemove: () => _removeLine(i),
                  onChanged: (updated) => _updateLine(i, updated),
                ),
              ),
      ),
      if (_lines.isNotEmpty) Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _submitting ? null : _submit,
            icon: _submitting
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_rounded),
            label: Text(l.deliverySubmit, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
      ),
    ]);
  }
}

class _DeliveryLine {
  final String productId;
  final String name;
  final int costPrice;
  final int qty;
  final int expectedQty; // 0 = no expected qty set

  const _DeliveryLine({
    required this.productId,
    required this.name,
    required this.costPrice,
    required this.qty,
    this.expectedQty = 0,
  });

  _DeliveryLine copyWith({String? productId, String? name, int? costPrice, int? qty, int? expectedQty}) {
    return _DeliveryLine(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      costPrice: costPrice ?? this.costPrice,
      qty: qty ?? this.qty,
      expectedQty: expectedQty ?? this.expectedQty,
    );
  }
}

class _LineCard extends StatefulWidget {
  final _DeliveryLine line;
  final VoidCallback onRemove;
  final ValueChanged<_DeliveryLine> onChanged;

  const _LineCard({
    required this.line,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<_LineCard> createState() => _LineCardState();
}

class _LineCardState extends State<_LineCard> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _costCtrl;
  late final TextEditingController _expectedCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '${widget.line.qty}');
    _costCtrl = TextEditingController(text: '${widget.line.costPrice}');
    _expectedCtrl = TextEditingController(text: widget.line.expectedQty > 0 ? '${widget.line.expectedQty}' : '');
  }

  @override
  void didUpdateWidget(_LineCard old) {
    super.didUpdateWidget(old);
    if (old.line.qty != widget.line.qty) _qtyCtrl.text = '${widget.line.qty}';
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _costCtrl.dispose();
    _expectedCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pos = PosColors.of(context);
    final l = AppLocalizations.of(context)!;
    final hasDiscrepancy = widget.line.expectedQty > 0 && widget.line.qty != widget.line.expectedQty;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: hasDiscrepancy ? pos.warningBg : null,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(widget.line.name,
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              maxLines: 1, overflow: TextOverflow.ellipsis)),
            // Line total
            Text(Money.format(widget.line.costPrice * widget.line.qty),
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: cs.primary)),
            const SizedBox(width: 4),
            IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: widget.onRemove,
              style: IconButton.styleFrom(foregroundColor: cs.error)),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            // Expected qty
            Expanded(child: TextField(
              controller: _expectedCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.deliveryExpectedQty,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) {
                final q = int.tryParse(v) ?? 0;
                widget.onChanged(widget.line.copyWith(expectedQty: q));
              },
            )),
            const SizedBox(width: 8),
            // Actual qty
            Expanded(child: TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.deliveryActualQty,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) {
                final q = int.tryParse(v);
                if (q != null && q > 0) widget.onChanged(widget.line.copyWith(qty: q));
              },
            )),
            const SizedBox(width: 8),
            // Cost price
            Expanded(child: TextField(
              controller: _costCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l.deliveryFieldCost,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              onChanged: (v) {
                final c = int.tryParse(v);
                if (c != null) widget.onChanged(widget.line.copyWith(costPrice: c));
              },
            )),
          ]),
          // Discrepancy indicator
          if (hasDiscrepancy) ...[
            const SizedBox(height: 6),
            Row(children: [
              Icon(Icons.warning_amber_rounded, size: 14, color: pos.warningFg),
              const SizedBox(width: 4),
              Text(
                '${l.deliveryDiscrepancy}: ${widget.line.qty - widget.line.expectedQty > 0 ? "+" : ""}${widget.line.qty - widget.line.expectedQty}',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: pos.warningFg),
              ),
            ]),
          ],
        ]),
      ),
    );
  }
}
