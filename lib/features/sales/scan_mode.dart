// warehouse/11 — Register scanner flow modes.
//
// Defines the three scan behaviours called out in the spec plus a
// debouncer helper for multi-quantity detection. Decoupled from the
// SalesBloc so it can be unit-tested independently, then wired in
// through a future SalesEvent (ScanModeChanged) + state field.
//
// Integration steps for a follow-up session:
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

/// Localised display label for the scan-mode chip on the cashier
/// topbar. Keep in sync with the l10n ARB files when adding to UI.
String scanModeLabel(ScanMode mode) {
  switch (mode) {
    case ScanMode.single:
      return 'один';
    case ScanMode.continuous:
      return 'непрерывный';
    case ScanMode.multiQty:
      return 'количество';
  }
}
