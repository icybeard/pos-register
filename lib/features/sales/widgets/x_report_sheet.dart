import 'package:flutter/material.dart';

import '../../../core/theme/hifi.dart';
import '../../../core/utils/money.dart';
import '../../../services/api_client.dart';

/// X-report bottom sheet — non-destructive shift snapshot. Aggregates
/// receipts returned by [ApiClient.listReceiptsByShift] and shows totals by
/// tender, discount, returns, and receipt count. Printing the sheet is left
/// to the OS share flow (out of scope here); the numbers on screen match
/// what the fiscal X-report would emit.
class XReportSheet extends StatelessWidget {
  final ApiClient api;
  final String shiftId;
  final String cashierName;
  const XReportSheet({super.key, required this.api, required this.shiftId, required this.cashierName});

  static Future<void> show(BuildContext context, {required ApiClient api, required String shiftId, required String cashierName}) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.85,
        child: XReportSheet(api: api, shiftId: shiftId, cashierName: cashierName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: api.listReceiptsByShift(shiftId),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(child: Text('Ошибка: ${snap.error}', style: Hifi.ui(size: 13, color: Hifi.danger))),
          );
        }
        final receipts = (snap.data?['receipts'] as List<dynamic>? ?? const <dynamic>[])
            .cast<Map<String, dynamic>>();
        return _Body(receipts: receipts, shiftId: shiftId, cashierName: cashierName);
      },
    );
  }
}

class _Body extends StatelessWidget {
  final List<Map<String, dynamic>> receipts;
  final String shiftId;
  final String cashierName;
  const _Body({required this.receipts, required this.shiftId, required this.cashierName});

  @override
  Widget build(BuildContext context) {
    var cash = 0, card = 0, qr = 0, discount = 0, returnsTotal = 0, turnover = 0;
    var returnsCount = 0;
    for (final r in receipts) {
      final type = (r['Type'] as String?) ?? 'sale';
      final total = (r['Total'] as num?)?.toInt() ?? 0;
      final cashAmt = (r['CashAmount'] as num?)?.toInt() ?? 0;
      final cardAmt = (r['CardAmount'] as num?)?.toInt() ?? 0;
      final qrAmt = (r['QRAmount'] as num?)?.toInt() ?? 0;
      final disc = (r['Discount'] as num?)?.toInt() ?? 0;
      if (type == 'return') {
        returnsTotal += total;
        returnsCount++;
      } else {
        turnover += total;
        cash += cashAmt;
        card += cardAmt;
        qr += qrAmt;
        discount += disc;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          const Icon(Icons.receipt_long, color: Hifi.chrome),
          const SizedBox(width: 8),
          Text('X-отчёт · текущий срез смены',
              style: Hifi.ui(size: 16, weight: FontWeight.w700, color: Hifi.chrome)),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
        ]),
        const SizedBox(height: 4),
        Text('Кассир: $cashierName · смена не закрывается',
            style: Hifi.ui(size: 12, color: const Color(0xFF666666))),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _kpi('ЧЕКОВ', '${receipts.length - returnsCount}', Hifi.chrome),
            _kpi('ВОЗВРАТОВ', '$returnsCount', Hifi.danger),
            _kpi('ОБОРОТ', Money.formatTenge(turnover), Hifi.chrome),
            _kpi('НАЛИЧНЫЕ', Money.formatTenge(cash), Hifi.success),
            _kpi('КАРТА', Money.formatTenge(card), Hifi.success),
            _kpi('QR / KASPI', Money.formatTenge(qr), Hifi.success),
            _kpi('СКИДКИ', '−${Money.formatTenge(discount)}', Hifi.warn),
            _kpi('ВОЗВРАТЫ', '−${Money.formatTenge(returnsTotal)}', Hifi.danger),
            _kpi('НЕТТО', Money.formatTenge(turnover - returnsTotal), Hifi.chrome),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(child: _list(receipts)),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Закрыть')),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Печать X-отчёта — требуется драйвер чекового принтера')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Hifi.chrome),
            icon: const Icon(Icons.print),
            label: const Text('Печать'),
          ),
        ]),
      ]),
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Hifi.tableHead,
        border: Border.all(color: Hifi.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(label, style: Hifi.ui(size: 10, color: const Color(0xFF666666)).copyWith(letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: Hifi.mono(size: 14, weight: FontWeight.w700, color: color), maxLines: 1, overflow: TextOverflow.ellipsis),
      ]),
    );
  }

  Widget _list(List<Map<String, dynamic>> receipts) {
    if (receipts.isEmpty) {
      return Center(child: Text('Операций за смену ещё нет', style: Hifi.ui(size: 13, color: const Color(0xFF888888))));
    }
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Hifi.border), borderRadius: BorderRadius.circular(4)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: ListView.builder(
          itemCount: receipts.length,
          itemBuilder: (context, i) {
            final r = receipts[i];
            final type = (r['Type'] as String?) ?? 'sale';
            final total = (r['Total'] as num?)?.toInt() ?? 0;
            final no = (r['ReceiptNumber'] ?? r['ID'] ?? '—').toString();
            final tender = (r['PaymentType'] as String?) ?? '—';
            final isRefund = type == 'return';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Hifi.divider))),
              child: Row(children: [
                Expanded(child: Text('№$no · ${isRefund ? "Возврат" : "Продажа"}', style: Hifi.ui(size: 12))),
                SizedBox(width: 100, child: Text(tender, style: Hifi.ui(size: 12, color: const Color(0xFF666666)))),
                SizedBox(
                  width: 120,
                  child: Text(
                    isRefund ? '−${Money.formatTenge(total.abs())}' : Money.formatTenge(total),
                    textAlign: TextAlign.right,
                    style: Hifi.mono(size: 12, weight: FontWeight.w600, color: isRefund ? Hifi.danger : Hifi.chrome),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }
}
