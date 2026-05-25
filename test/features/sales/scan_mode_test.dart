// Pure unit tests for the warehouse/11 scan-mode helpers.
// No Flutter binding required.

import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/features/sales/scan_mode.dart';

void main() {
  group('MultiQtyTracker', () {
    test('first scan never prompts', () {
      final t = MultiQtyTracker();
      expect(t.shouldPromptForQuantity('4607012340090'), isFalse);
    });

    test('same barcode within window prompts', () {
      final t = MultiQtyTracker(window: const Duration(seconds: 2));
      final t0 = DateTime(2026, 5, 25, 12, 0, 0);
      expect(t.shouldPromptForQuantity('AAA', now: t0), isFalse);
      expect(
        t.shouldPromptForQuantity('AAA',
            now: t0.add(const Duration(milliseconds: 800))),
        isTrue,
      );
    });

    test('same barcode after window resets', () {
      final t = MultiQtyTracker(window: const Duration(seconds: 1));
      final t0 = DateTime(2026, 5, 25, 12, 0, 0);
      t.shouldPromptForQuantity('AAA', now: t0);
      expect(
        t.shouldPromptForQuantity('AAA',
            now: t0.add(const Duration(seconds: 5))),
        isFalse,
      );
    });

    test('different barcode does not prompt', () {
      final t = MultiQtyTracker();
      t.shouldPromptForQuantity('AAA');
      expect(t.shouldPromptForQuantity('BBB'), isFalse);
    });

    test('clock skew (backward `now`) treated as in-window via .abs()', () {
      // Guards against a future refactor that drops the .abs() — if it does,
      // an NTP sync that briefly walks the wall clock backward would
      // mis-classify two distinct scans as a single repeated one.
      final t = MultiQtyTracker(window: const Duration(seconds: 2));
      final t0 = DateTime(2026, 5, 25, 12, 0, 0);
      t.shouldPromptForQuantity('AAA', now: t0);
      expect(
        t.shouldPromptForQuantity('AAA',
            now: t0.subtract(const Duration(milliseconds: 500))),
        isTrue,
      );
    });

    test('reset clears state', () {
      final t = MultiQtyTracker();
      t.shouldPromptForQuantity('AAA');
      t.reset();
      expect(t.shouldPromptForQuantity('AAA'), isFalse);
    });
  });

  group('scanModeLabel', () {
    test('returns localised label per mode', () {
      expect(scanModeLabel(ScanMode.single), 'один');
      expect(scanModeLabel(ScanMode.continuous), 'непрерывный');
      expect(scanModeLabel(ScanMode.multiQty), 'количество');
    });
  });
}
