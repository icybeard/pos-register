// warehouse/11 — Register scanner flow modes.
//
// ⚠️ SCAFFOLD ONLY — not wired into SalesBloc yet. Production sale
// flow today still uses the single-shot _onScan handler in
// sales_bloc.dart; nothing in this file is observable to a cashier
// until the integration listed below lands.
//
// Decoupled from the SalesBloc on purpose so it can be unit-tested
// independently. Tests live at test/features/sales/scan_mode_test.dart.
//
// Integration steps for the follow-up Flutter session:
//   1. Add `scanMode` field to SalesState (default: ScanMode.single).
//   2. Add ScanModeChanged event + emitter.
//   3. In _onScan, branch on state.scanMode:
//        - single: existing flow.
//        - continuous: same flow, but DON'T close keyboard / refocus
//          search field — the next physical scan fires another event.
//        - multiQty: track via MultiQtyTracker; when same barcode
//          arrives within 1.5s, prompt for total quantity instead of
//          auto-adding.
//   4. Add a long-press handler on the scanner icon in pos_screen.dart
//      that opens a mode picker bottom-sheet.
//
// This file is intentionally pure — no Flutter imports — so the
// helpers can run in test mode without needing a
// TestWidgetsFlutterBinding.

/// Three behaviours for handling a physical scan.
enum ScanMode {
  /// Default. Each scan resolves a product and adds it to the cart;
  /// keyboard / search focus returns to the search field after.
  single,

  /// Each scan adds qty=1 without re-focusing the search field, so a
  /// quick succession of physical scans fills the cart hands-free.
  continuous,

  /// Same barcode within [MultiQtyTracker.window] seconds → prompt for
  /// total quantity once instead of N add-to-cart events. Useful when
  /// a customer brings 6 identical items to the till.
  multiQty,
}

/// Tracks repeated barcode scans for [ScanMode.multiQty]. Emits
/// `true` from [shouldPromptForQuantity] when the same barcode arrives
/// twice within the [window].
class MultiQtyTracker {
  MultiQtyTracker({Duration? window})
      : window = window ?? const Duration(milliseconds: 1500);

  final Duration window;
  String? _lastBarcode;
  DateTime? _lastAt;

  /// Call on every scan. Returns true if this scan matches the previous
  /// barcode within the window — caller should open a "quantity?" prompt
  /// and discard the second auto-add. Returns false on first scan or
  /// when the barcode is different / the window expired.
  bool shouldPromptForQuantity(String barcode, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final repeated = _lastBarcode == barcode &&
        _lastAt != null &&
        at.difference(_lastAt!).abs() <= window;
    _lastBarcode = barcode;
    _lastAt = at;
    return repeated;
  }

  /// Clear state — call after cart is cleared or after a prompt fires.
  void reset() {
    _lastBarcode = null;
    _lastAt = null;
  }
}

/// Display label for the scan-mode chip on the cashier topbar.
///
/// ⚠️ Returns a raw Russian literal — this is fine ONLY while this
/// helper isn't wired into the UI. Once the chip lands in the cashier
/// screen, swap to `AppLocalizations.of(context)!.scanMode<Single|Continuous|MultiQty>`
/// at the call site and delete this function (or keep it pure-Dart
/// and pass the localisation in from outside).
// ignore: untranslated_string
String scanModeLabel(ScanMode mode) => switch (mode) {
      ScanMode.single => 'один',
      ScanMode.continuous => 'непрерывный',
      ScanMode.multiQty => 'количество',
    };
