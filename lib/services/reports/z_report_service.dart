import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../data/database.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../data/repositories/shift_repository.dart';
import '../reconciliation/cash_drawer_reconciliation.dart';

/// Z-report input bundle. The service pulls this together from
/// `ShiftRepository` + `ReceiptRepository` so the UI just says
/// `zReport.generatePdf(shiftId, countedCash: ...)`.
class ZReportData {
  const ZReportData({
    required this.shift,
    required this.receipts,
    required this.countedCashTiyin,
    this.storeName,
    this.cashierName,
  });

  final ShiftRow shift;
  final List<ReceiptRow> receipts;

  /// Cash the cashier counted at shift-close. Nullable for "X-report" previews
  /// (a mid-shift snapshot where expected is meaningful but actual isn't yet).
  final int? countedCashTiyin;

  /// Optional display fields. Service degrades gracefully when null —
  /// Kazakh law requires store BIN on receipts, but the Z-report is an
  /// internal document so missing names don't invalidate it.
  final String? storeName;
  final String? cashierName;
}

/// Generates the end-of-shift Z-report PDF. Plan §7 Tier-1 deliverable:
/// **per-register Z-report PDF + cash counts** shippable without any
/// cross-register networking.
///
/// **PDF shape** (vertical, A4):
///   - Header: store name, shift number, cashier, opened/closed timestamps
///   - Cash drawer block: cash_start / total_cash / deposits / withdrawals /
///     returns / expected / actual / variance (with tier colour)
///   - Payment totals: cash / card / qr / debt / grand sales / returns
///   - Receipt list: receipt number, time, total (first 50 rows; spec calls
///     for 100-receipt handling, page-break safe)
///
/// Returns raw PDF bytes — the UI either hands them to the `printing` package
/// or saves via `getApplicationDocumentsDirectory()` then `share_plus`.
/// Keeping this service pure (byte-returning) makes it `NativeDatabase.memory()`
/// + `flutter_test` testable end-to-end, which the golden-PDF test relies on.
class ZReportService {
  ZReportService(this._shifts, this._receipts);

  final ShiftRepository _shifts;
  final ReceiptRepository _receipts;

  /// Build the data bundle + render bytes. Caller passes the counted-cash
  /// figure (can be null for X-report preview).
  Future<Uint8List> generatePdf({
    required String shiftId,
    int? countedCashTiyin,
    String? storeName,
    String? cashierName,
  }) async {
    // Throws StateError if the shift was never opened / already closed —
    // both cases are caller bugs; the UI never invokes this without a known
    // open shift in hand.
    final shift = await _shifts.currentOpenById(shiftId);
    final receipts = await _receipts.recentInShift(shiftId, limit: 100);
    return renderPdf(ZReportData(
      shift: shift,
      receipts: receipts,
      countedCashTiyin: countedCashTiyin,
      storeName: storeName,
      cashierName: cashierName,
    ));
  }

  /// Pure rendering — exposed separately so golden tests can build a
  /// [ZReportData] without round-tripping through drift. Async because
  /// `pw.Document.save()` returns `Future<Uint8List>` in pdf ^3.x.
  ///
  /// `cyrillicFont` is an optional Cyrillic-capable [pw.Font]. The default
  /// Helvetica that ships with `pdf` lacks Cyrillic glyphs, so production
  /// wiring should pass a Noto/Roboto TTF (loaded via `printing`'s
  /// `PdfGoogleFonts.notoSansRegular()` or a bundled asset). Tests omit it —
  /// the byte-stream still validates as a PDF, Cyrillic chars render as
  /// placeholders but the structure is correct.
  static Future<Uint8List> renderPdf(
    ZReportData data, {
    pw.Font? cyrillicFont,
    pw.Font? cyrillicBoldFont,
  }) async {
    final doc = pw.Document(
      title: 'Z-отчёт №${data.shift.shiftNumber}',
      author: 'POS',
      theme: cyrillicFont == null
          ? null
          : pw.ThemeData.withFont(
              base: cyrillicFont,
              bold: cyrillicBoldFont ?? cyrillicFont,
            ),
    );

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (ctx) => [
        _header(data),
        pw.SizedBox(height: 16),
        _cashDrawerBlock(data),
        pw.SizedBox(height: 12),
        _paymentTotalsBlock(data.shift),
        pw.SizedBox(height: 12),
        _receiptsBlock(data.receipts),
      ],
    ));

    return doc.save();
  }

  // --- Building blocks ---------------------------------------------------

  static pw.Widget _header(ZReportData d) {
    final openedAt = d.shift.openedAt.toLocal();
    final closedAt = d.shift.closedAt?.toLocal();
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('Z-ОТЧЁТ',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      if (d.storeName != null)
        pw.Text(d.storeName!, style: const pw.TextStyle(fontSize: 14)),
      pw.Text('Смена №${d.shift.shiftNumber}',
          style: const pw.TextStyle(fontSize: 12)),
      if (d.cashierName != null)
        pw.Text('Кассир: ${d.cashierName!}', style: const pw.TextStyle(fontSize: 12)),
      pw.Text(
        'Открыта: ${_fmtDateTime(openedAt)}'
        '${closedAt != null ? ' · Закрыта: ${_fmtDateTime(closedAt)}' : ' · (не закрыта)'}',
        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
      ),
    ]);
  }

  static pw.Widget _cashDrawerBlock(ZReportData d) {
    final s = d.shift;
    final expected = CashDrawerReconciliation.expectedCashTiyin(s);
    final actual = d.countedCashTiyin;
    final variance = actual == null ? null : actual - expected;

    return _tableBlock('КАССА', [
      _TableRow('Начальная сумма',   s.cashStartTiyin),
      _TableRow('Наличные продажи',  s.totalCashTiyin),
      _TableRow('Внесения',          s.totalDepositsTiyin),
      _TableRow('Изъятия',           -s.totalWithdrawalsTiyin),
      _TableRow('Возвраты',          -s.totalReturnsTiyin),
      _TableRow('Ожидаемо',          expected, style: _RowStyle.emphasise),
      if (actual != null) _TableRow('Пересчитано', actual),
      if (variance != null)
        _TableRow('Расхождение', variance,
            style: variance == 0 ? _RowStyle.emphasise
                : variance < 0 ? _RowStyle.short : _RowStyle.over),
    ]);
  }

  static pw.Widget _paymentTotalsBlock(ShiftRow s) {
    return _tableBlock('ОПЛАТЫ', [
      _TableRow('Наличные',          s.totalCashTiyin),
      _TableRow('Карта',             s.totalCardTiyin),
      _TableRow('QR / Kaspi',        s.totalQrTiyin),
      _TableRow('В долг',            s.totalDebtTiyin),
      _TableRow('Продажи (итого)',   s.totalSalesTiyin, style: _RowStyle.emphasise),
      _TableRow('Возвраты (итого)',  s.totalReturnsTiyin),
      _TableRow('Чеков',             s.receiptCount, column: _Column.count),
      _TableRow('Возвратов',         s.returnCount, column: _Column.count),
    ]);
  }

  static pw.Widget _receiptsBlock(List<ReceiptRow> receipts) {
    if (receipts.isEmpty) {
      return pw.Text('Чеков за смену не было',
          style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700));
    }
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('ЧЕКИ',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.TableHelper.fromTextArray(
        border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        cellStyle: const pw.TextStyle(fontSize: 9),
        headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        headers: const ['№', 'Время', 'Тип', 'Итого'],
        data: receipts.map((r) => [
          r.receiptNumber.toString(),
          _fmtTime(r.createdAt.toLocal()),
          r.isReturn ? 'Возврат' : 'Продажа',
          _fmtTiyin(r.totalAmountTiyin),
        ]).toList(),
      ),
    ]);
  }

  // --- Small formatting helpers ------------------------------------------

  static String _fmtTiyin(int tiyin) {
    final sign = tiyin < 0 ? '−' : '';
    final abs = tiyin.abs();
    final tenge = abs ~/ 100;
    final remainder = abs % 100;
    return '$sign${_withSpaces(tenge)},${remainder.toString().padLeft(2, '0')} ₸';
  }

  static String _withSpaces(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }

  static String _fmtDateTime(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${_fmtTime(dt)}';

  static String _fmtTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // --- Rendering a "label: value" table with tier-colored rows -----------

  static pw.Widget _tableBlock(String title, List<_TableRow> rows) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 4),
      pw.Table(
        columnWidths: {
          0: const pw.FlexColumnWidth(2),
          1: const pw.FlexColumnWidth(1),
        },
        children: rows.map((r) {
          final label = r.label;
          final value = r.value;
          final style = r.style;
          final column = r.column;
          return pw.TableRow(
            decoration: style == _RowStyle.emphasise
                ? const pw.BoxDecoration(color: PdfColors.grey200)
                : null,
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: pw.Text(label,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: style == _RowStyle.emphasise
                          ? pw.FontWeight.bold
                          : pw.FontWeight.normal,
                    )),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: pw.Text(
                  column == _Column.currency ? _fmtTiyin(value) : value.toString(),
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: switch (style) {
                      _RowStyle.short => PdfColors.red700,
                      _RowStyle.over => PdfColors.green800,
                      _ => PdfColors.black,
                    },
                    fontWeight: style == _RowStyle.emphasise
                        ? pw.FontWeight.bold
                        : pw.FontWeight.normal,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ]);
  }
}

enum _RowStyle { plain, emphasise, short, over }
enum _Column { currency, count }

class _TableRow {
  const _TableRow(
    this.label,
    this.value, {
    this.style = _RowStyle.plain,
    this.column = _Column.currency,
  });

  final String label;
  final int value;
  final _RowStyle style;
  final _Column column;
}
