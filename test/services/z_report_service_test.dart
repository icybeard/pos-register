import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/data/database.dart';
import 'package:pos_system/data/repositories/receipt_repository.dart';
import 'package:pos_system/data/repositories/shift_repository.dart';
import 'package:pos_system/services/reports/z_report_service.dart';

void main() {
  late AppDatabase db;
  late ShiftRepository shifts;
  late ReceiptRepository receipts;
  late ZReportService zReport;
  const tenantId = '11111111-1111-1111-1111-111111111111';
  const deviceId = 'test-device';

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    shifts = ShiftRepository(db, tenantId: tenantId);
    receipts = ReceiptRepository(db, tenantId: tenantId, deviceId: deviceId);
    zReport = ZReportService(shifts, receipts);
  });

  tearDown(() async => db.close());

  Future<ShiftRow> seedShift({int cashStartTiyin = 10_000}) async {
    final id = await shifts.open(
      workstationId: 'ws-1',
      userId: 'cashier-1',
      shiftNumber: 7,
      cashStartTiyin: cashStartTiyin,
    );
    return shifts.currentOpenById(id);
  }

  Future<void> addCashSale(String shiftId,
      {required int receiptNumber, required int totalTiyin}) async {
    await receipts.createReceipt(
      workstationId: 'ws-1',
      shiftId: shiftId,
      userId: 'cashier-1',
      receiptNumber: receiptNumber,
      lines: [
        ReceiptLineInput(
          productId: 'p-$receiptNumber',
          productName: 'Товар $receiptNumber',
          quantity: 1,
          unitPriceTiyin: totalTiyin,
          itemTotalTiyin: totalTiyin,
        ),
      ],
      totalAmountTiyin: totalTiyin,
      vatAmountTiyin: 0,
      cashAmountTiyin: totalTiyin,
    );
    await shifts.recordReceipt(
      shiftId,
      ShiftReceiptTotals(
          totalAmountTiyin: totalTiyin, cashAmountTiyin: totalTiyin),
    );
  }

  test('renders non-empty PDF bytes for a shift with no receipts', () async {
    final s = await seedShift();
    final bytes = await ZReportService.renderPdf(ZReportData(
      shift: s,
      receipts: const [],
      countedCashTiyin: 10_000,
      storeName: 'Магазин №1',
      cashierName: 'Иванов И.',
    ));
    expect(bytes, isNotEmpty);
    // PDF magic header: %PDF-
    expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
  });

  test('generatePdf assembles shift + receipts end-to-end', () async {
    final s = await seedShift(cashStartTiyin: 10_000);
    await addCashSale(s.id, receiptNumber: 1, totalTiyin: 5_000);
    await addCashSale(s.id, receiptNumber: 2, totalTiyin: 12_500);

    final bytes = await zReport.generatePdf(
      shiftId: s.id,
      countedCashTiyin: 27_500, // 10_000 start + 17_500 cash sales
      storeName: 'Магазин №1',
      cashierName: 'Иванов И.',
    );
    expect(bytes, isNotEmpty);
    expect(bytes.sublist(0, 5), [0x25, 0x50, 0x44, 0x46, 0x2D]);
  });

  test('renders even when counted cash is null (X-report preview)', () async {
    final s = await seedShift();
    final bytes = await ZReportService.renderPdf(ZReportData(
      shift: s,
      receipts: const [],
      countedCashTiyin: null,
    ));
    expect(bytes, isNotEmpty);
  });

  test('renders with short-variance colouring without crashing', () async {
    final s = await seedShift(cashStartTiyin: 60_000);
    final bytes = await ZReportService.renderPdf(ZReportData(
      shift: s,
      receipts: const [],
      countedCashTiyin: 59_500, // −500 short
    ));
    expect(bytes, isNotEmpty);
  });

  test('renders with over-variance colouring without crashing', () async {
    final s = await seedShift(cashStartTiyin: 60_000);
    final bytes = await ZReportService.renderPdf(ZReportData(
      shift: s,
      receipts: const [],
      countedCashTiyin: 60_200, // +200 over
    ));
    expect(bytes, isNotEmpty);
  });
}
