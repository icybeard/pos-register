import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Hi-fi design tokens + shared widgets for the "Variant C — Action-grid"
/// direction locked in the design handoff (hifi/POS Register Hi-fi.html).
///
/// All on-screen chrome uses the navy #1a3a6b. Action tiles, steppers, pin
/// pads, chips etc. are shared here so shift, returns, debts, override and
/// POS screens stay visually consistent.
class Hifi {
  Hifi._();

  // Chrome + surfaces
  static const Color chrome = Color(0xFF1A3A6B);
  static const Color chromeOnline = Color(0xFF87F7C3);
  static const Color chromeOffline = Color(0xFFFFCDD2);
  static const Color canvas = Color(0xFFEEF1F4);
  static const Color paneBg = Colors.white;
  static const Color infoStrip = Color(0xFFF4F6F9);
  static const Color tableHead = Color(0xFFF6F8FA);

  // Borders + dividers
  static const Color border = Color(0xFFD0D7DE);
  static const Color divider = Color(0xFFE6E8EB);

  // Action tile palette
  static const Color tileDefault = Color(0xFFE3F2FF);
  static const Color tileGreen = Color(0xFFC8F7D7);
  static const Color tileYellow = Color(0xFFFFE9A8);
  static const Color tileRed = Color(0xFFFFCDD2);
  static const Color tileRedFg = Color(0xFFB71C1C);
  static const Color tilePay = Color(0xFF2E7D32);

  // Status colors
  static const Color success = Color(0xFF006C49);
  static const Color warn = Color(0xFF9C5700);
  static const Color danger = Color(0xFFB91C1C);

  // Typography
  static TextStyle mono({double size = 13, FontWeight weight = FontWeight.w500, Color? color}) =>
      TextStyle(fontFamily: 'JetBrainsMono', fontSize: size, fontWeight: weight, color: color);

  static TextStyle ui({double size = 13, FontWeight weight = FontWeight.w500, Color? color, double? height}) =>
      TextStyle(fontFamily: 'Inter', fontSize: size, fontWeight: weight, color: color, height: height);
}

/// Navy chrome bar — single source of truth for the app's top bar.
///
/// Lives at 44 px, rendered by `_MainShell` in main.dart for in-shell pages
/// and by individual screens that exist outside the shell (pre-login,
/// push-routed full-screen flows like payment/cashier-login). Page screens
/// inside the shell DO NOT render this themselves any more — the shell
/// owns one instance and populates it from current state.
///
/// Slot layout, left → right:
///   `[leading?] [appName] [title?] [shiftNumber chip?] [cashierName chip?]`
///   `[extras...]  <Spacer>  [online chip?]`
///   `[timestamp?] [storeLabel?] [locale chip?]`
///
/// `online` is opt-in (nullable) — passing null hides the legacy chip; the
/// shell populates `extras` with a live `SyncStatusChip` instead. Keeping
/// the parameter (instead of removing) preserves test fixtures.
class HifiChrome extends StatelessWidget implements PreferredSizeWidget {
  final String appName;
  /// Page-level breadcrumb. Rendered between `appName` and the cashier/shift
  /// chips in slightly larger weight. Replaces `_buildTopBar`'s breadcrumb.
  final String? title;
  final String? shiftNumber;
  final String? cashierName;
  /// Opt-in legacy online chip. Default null → no chip rendered (shell ships
  /// `SyncStatusChip` via [extras] instead, which carries richer signal).
  final bool? online;
  final VoidCallback? onToggleOnline;
  final String locale;
  final VoidCallback? onToggleLocale;
  final String? timestamp;
  final String? storeLabel;
  final Widget? leading;
  final List<Widget> extras;

  const HifiChrome({
    super.key,
    this.appName = 'pos-register',
    this.title,
    this.shiftNumber,
    this.cashierName,
    this.online,
    this.onToggleOnline,
    this.locale = 'ru',
    this.onToggleLocale,
    this.timestamp,
    this.storeLabel,
    this.leading,
    this.extras = const [],
  });

  /// Visual height of the chrome bar itself (excludes the device's top
  /// safe-area inset, which is added at build time inside [build]).
  static const double _barHeight = 44;

  /// Returned size ignores the safe-area inset because the MediaQuery
  /// isn't reachable here. This is fine: HifiChrome is used as a regular
  /// Column child on every screen we ship, never as an AppBar, so no
  /// consumer reads this. Kept implementing the interface so existing
  /// test fixtures that pass a HifiChrome to `Scaffold(appBar: ...)` keep
  /// compiling.
  @override
  Size get preferredSize => const Size.fromHeight(_barHeight);

  @override
  Widget build(BuildContext context) {
    // SafeArea(top: true) so the chrome doesn't sit under the iPad / iPhone
    // status bar (or Android system bar). bottom: false because we're at
    // the top edge of the screen and the body below handles its own
    // bottom inset.
    return SafeArea(
      top: true,
      bottom: false,
      child: Container(
        height: _barHeight,
        color: Hifi.chrome,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(children: [
        if (leading != null) ...[leading!, const SizedBox(width: 12)],
        Text(
          appName,
          style: Hifi.ui(size: 13, weight: FontWeight.w700, color: Colors.white)
              .copyWith(letterSpacing: 0.3),
        ),
        if (title != null) ...[
          const SizedBox(width: 12),
          Text(
            '· $title',
            style: Hifi.ui(
              size: 13,
              weight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ).copyWith(letterSpacing: 0.2),
          ),
        ],
        const SizedBox(width: 12),
        if (shiftNumber != null) ...[_chip(shiftNumber!), const SizedBox(width: 8)],
        if (cashierName != null) _chip('Кассир: $cashierName'),
        for (final w in extras) ...[const SizedBox(width: 8), w],
        const Spacer(),
        if (online != null) ...[
          _OnlineChip(online: online!, onTap: onToggleOnline),
          const SizedBox(width: 10),
        ],
        if (timestamp != null)
          Text(
            timestamp!,
            style: Hifi.mono(size: 11, color: Colors.white.withValues(alpha: 0.6)),
          ),
        if (storeLabel != null) ...[
          const SizedBox(width: 10),
          Text(
            storeLabel!,
            style: Hifi.mono(size: 11, color: Colors.white.withValues(alpha: 0.6)),
          ),
        ],
        if (onToggleLocale != null) ...[
          const SizedBox(width: 10),
          _LocaleChip(locale: locale, onTap: onToggleLocale!),
        ],
        ]),
      ),
    );
  }

  Widget _chip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: Hifi.ui(size: 11, weight: FontWeight.w500, color: Colors.white),
        ),
      );
}

class _OnlineChip extends StatelessWidget {
  final bool online;
  final VoidCallback? onTap;
  const _OnlineChip({required this.online, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bg = online
        ? const Color(0x3887F7C3)
        : const Color(0x38FFCDD2);
    final fg = online ? Hifi.chromeOnline : Hifi.chromeOffline;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('●', style: TextStyle(color: fg, fontSize: 9)),
          const SizedBox(width: 4),
          Text(
            online ? 'ONLINE' : 'OFFLINE · очередь 3',
            style: Hifi.ui(size: 11, weight: FontWeight.w600, color: fg).copyWith(letterSpacing: 0.3),
          ),
        ]),
      ),
    );
  }
}

class _LocaleChip extends StatelessWidget {
  final String locale;
  final VoidCallback onTap;
  const _LocaleChip({required this.locale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final label = locale == 'ru' ? 'ҚЗ' : 'РУ';
    return SizedBox(
      height: 24,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 24),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
        child: Text(label, style: Hifi.ui(size: 12, weight: FontWeight.w500, color: Colors.white)),
      ),
    );
  }
}

/// Variant sets for action tiles — matches `.action-tile` CSS classes.
enum HifiTileVariant { defaultTile, green, yellow, red, pay }

class ActionTile extends StatelessWidget {
  final String label;
  final String? hotkey;
  final HifiTileVariant variant;
  final VoidCallback? onTap;
  final double? height;
  final double? fontSize;
  final IconData? icon;

  const ActionTile({
    super.key,
    required this.label,
    this.hotkey,
    this.variant = HifiTileVariant.defaultTile,
    this.onTap,
    this.height,
    this.fontSize,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = switch (variant) {
      HifiTileVariant.defaultTile => Hifi.tileDefault,
      HifiTileVariant.green => Hifi.tileGreen,
      HifiTileVariant.yellow => Hifi.tileYellow,
      HifiTileVariant.red => Hifi.tileRed,
      HifiTileVariant.pay => Hifi.tilePay,
    };
    final fg = switch (variant) {
      HifiTileVariant.red => Hifi.tileRedFg,
      HifiTileVariant.pay => Colors.white,
      _ => const Color(0xFF1B1B21),
    };
    final disabled = onTap == null;
    final effective = disabled ? bg.withValues(alpha: 0.55) : bg;
    final fs = fontSize ?? (variant == HifiTileVariant.pay ? 20.0 : 13.0);
    return SizedBox(
      height: height,
      child: Material(
        color: effective,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(height: 4),
              ],
              Text(
                label,
                textAlign: TextAlign.center,
                style: Hifi.ui(
                  size: fs,
                  weight: variant == HifiTileVariant.pay ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (hotkey != null) ...[
                const SizedBox(height: 2),
                Text(
                  hotkey!,
                  style: Hifi.mono(size: 10, color: fg.withValues(alpha: 0.7)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

/// Right-hand action panel matching Variant C. 4x4 tile grid + Void/Discount +
/// 80px Pay footer. Width 360 in full-screen monobloc, content flows to any
/// height via Expanded.
class ActionGridPanel extends StatelessWidget {
  final List<ActionTile> tiles;
  final ActionTile? voidTile;
  final ActionTile? discountTile;
  final ActionTile? payTile;
  final double width;

  const ActionGridPanel({
    super.key,
    required this.tiles,
    this.voidTile,
    this.discountTile,
    this.payTile,
    this.width = 360,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      color: Hifi.chrome,
      padding: const EdgeInsets.all(8),
      child: Column(children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.55,
            physics: const NeverScrollableScrollPhysics(),
            children: tiles,
          ),
        ),
        if (voidTile != null || discountTile != null) ...[
          const SizedBox(height: 8),
          Row(children: [
            if (voidTile != null)
              Expanded(child: SizedBox(height: 56, child: voidTile)),
            if (voidTile != null && discountTile != null) const SizedBox(width: 8),
            if (discountTile != null)
              Expanded(child: SizedBox(height: 56, child: discountTile)),
          ]),
        ],
        if (payTile != null) ...[
          const SizedBox(height: 8),
          SizedBox(height: 80, width: double.infinity, child: payTile),
        ],
      ]),
    );
  }
}

/// Feedback strip above the cart showing the most-recently-added product.
/// Replaces the "⊕ POS Клиент" chip Adil flagged — the search result / info
/// belongs here, not in the chrome.
class LastAddedStrip extends StatelessWidget {
  final String? iconEmoji;
  final IconData? iconData;
  final String title;
  final String subtitle;
  final String price;
  final bool empty;

  const LastAddedStrip({
    super.key,
    this.iconEmoji,
    this.iconData,
    required this.title,
    required this.subtitle,
    required this.price,
    this.empty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Hifi.infoStrip,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Hifi.border),
      ),
      child: Row(children: [
        SizedBox(
          width: 32,
          child: Center(
            child: iconData != null
                ? Icon(iconData, size: 22, color: empty ? Colors.grey : Hifi.chrome)
                : Text(iconEmoji ?? '📦', style: const TextStyle(fontSize: 22)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(title, style: Hifi.ui(size: 13, weight: FontWeight.w600, color: Hifi.chrome), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subtitle, style: Hifi.mono(size: 10, color: const Color(0xFF666666)), maxLines: 1, overflow: TextOverflow.ellipsis),
          ]),
        ),
        if (!empty)
          Text(price, style: Hifi.mono(size: 18, weight: FontWeight.w700, color: Hifi.chrome)),
      ]),
    );
  }
}

/// Small navy-outlined "−" and filled-navy "＋" stepper used on cart rows,
/// denomination counts, return qty.
class HifiStepper extends StatelessWidget {
  final int value;
  final VoidCallback? onDec;
  final VoidCallback? onInc;
  final ValueChanged<int>? onChanged;
  final double buttonSize;
  final bool showInput;

  const HifiStepper({
    super.key,
    required this.value,
    this.onDec,
    this.onInc,
    this.onChanged,
    this.buttonSize = 30,
    this.showInput = false,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(text: '$value');
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _StepBtn(
        size: buttonSize,
        filled: false,
        onTap: onDec,
        child: const Icon(Icons.remove, size: 16, color: Hifi.chrome),
      ),
      const SizedBox(width: 4),
      if (showInput && onChanged != null)
        SizedBox(
          width: 60,
          height: buttonSize,
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onSubmitted: (v) => onChanged!(int.tryParse(v) ?? 0),
            style: Hifi.mono(size: 14, weight: FontWeight.w600),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.zero,
              isDense: true,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Hifi.border),
                borderRadius: BorderRadius.circular(4),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Hifi.chrome, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        )
      else
        SizedBox(
          width: 32,
          child: Center(
            child: Text('$value', style: Hifi.mono(size: 14, weight: FontWeight.w600)),
          ),
        ),
      const SizedBox(width: 4),
      _StepBtn(
        size: buttonSize,
        filled: true,
        onTap: onInc,
        child: const Icon(Icons.add, size: 16, color: Colors.white),
      ),
    ]);
  }
}

class _StepBtn extends StatelessWidget {
  final double size;
  final bool filled;
  final VoidCallback? onTap;
  final Widget child;
  const _StepBtn({required this.size, required this.filled, required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Material(
        color: filled ? Hifi.chrome : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: Hifi.chrome),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// 3×4 PIN pad used by login and manager override. Renders as buttons with
/// mono digits; ⌫ deletes, ⏎ submits (optional).
class HifiPinPad extends StatelessWidget {
  final ValueChanged<String>? onKey;
  final VoidCallback? onBackspace;
  final VoidCallback? onSubmit;
  final double keyHeight;
  final double gap;
  final bool showSubmit;

  const HifiPinPad({
    super.key,
    this.onKey,
    this.onBackspace,
    this.onSubmit,
    this.keyHeight = 56,
    this.gap = 8,
    this.showSubmit = true,
  });

  @override
  Widget build(BuildContext context) {
    final keys = ['1','2','3','4','5','6','7','8','9','⌫','0', showSubmit ? '⏎' : ''];
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: gap,
      crossAxisSpacing: gap,
      childAspectRatio: 1.3,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: keys.map((k) => _padKey(k)).toList(),
    );
  }

  Widget _padKey(String k) {
    if (k.isEmpty) return const SizedBox.shrink();
    final isEnter = k == '⏎';
    final isBack = k == '⌫';
    return Material(
      color: isEnter ? Hifi.chrome : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Hifi.border),
      ),
      child: InkWell(
        onTap: () {
          if (isBack) {
            onBackspace?.call();
          } else if (isEnter) {
            onSubmit?.call();
          } else {
            onKey?.call(k);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Center(
          child: Text(
            k,
            style: Hifi.mono(
              size: 20,
              weight: FontWeight.w600,
              color: isEnter ? Colors.white : Hifi.chrome,
            ),
          ),
        ),
      ),
    );
  }
}

/// Row of 4 dot cells showing how many PIN digits have been entered.
class HifiPinDots extends StatelessWidget {
  final int length;
  final int filled;
  final double cellHeight;

  const HifiPinDots({super.key, this.length = 4, required this.filled, this.cellHeight = 52});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(length, (i) {
        final active = i < filled;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == length - 1 ? 0 : 8),
            child: Container(
              height: cellHeight,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: active ? Hifi.chrome : Hifi.border,
                  width: 2,
                ),
              ),
              alignment: Alignment.center,
              child: active
                  ? const Text('●', style: TextStyle(color: Hifi.chrome, fontSize: 24))
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

/// Section header / "info strip" used at the top of shift open, shift close,
/// returns, debts. Icon + title + subtitle, right-aligned meta.
class HifiSectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  final String? subtitle;
  final String? trailing;

  const HifiSectionHeader({super.key, required this.icon, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Hifi.infoStrip,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Hifi.border),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Text(title, style: Hifi.ui(size: 14, weight: FontWeight.w600, color: Hifi.chrome)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle!, style: Hifi.ui(size: 11, color: const Color(0xFF666666))),
          ],
        ])),
        if (trailing != null)
          Text(trailing!, style: Hifi.ui(size: 11, color: const Color(0xFF666666))),
      ]),
    );
  }
}

/// Standard hi-fi data-table shell: grey header row + rows with 1px bottom
/// border. Grid columns are defined by [columns] and each row returns a list
/// of widgets of matching length.
class HifiTable extends StatelessWidget {
  final List<HifiColumn> columns;
  final List<List<Widget>> rows;
  final double headerHeight;
  final double? rowHeight;

  const HifiTable({
    super.key,
    required this.columns,
    required this.rows,
    this.headerHeight = 32,
    this.rowHeight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Hifi.border),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Column(children: [
          // header
          Container(
            height: headerHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Hifi.tableHead,
              border: Border(bottom: BorderSide(color: Hifi.border)),
            ),
            child: Row(children: [
              for (final c in columns)
                _cell(
                  flex: c.flex,
                  width: c.width,
                  align: c.align,
                  child: Text(
                    c.label.toUpperCase(),
                    style: Hifi.ui(size: 11, weight: FontWeight.w600, color: const Color(0xFF555555))
                        .copyWith(letterSpacing: 0.3),
                  ),
                ),
            ]),
          ),
          // rows
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final r = rows[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Hifi.divider)),
                  ),
                  child: Row(children: [
                    for (int j = 0; j < columns.length; j++)
                      _cell(
                        flex: columns[j].flex,
                        width: columns[j].width,
                        align: columns[j].align,
                        child: j < r.length ? r[j] : const SizedBox.shrink(),
                      ),
                  ]),
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  Widget _cell({required int? flex, required double? width, required TextAlign align, required Widget child}) {
    final aligned = Align(
      alignment: switch (align) {
        TextAlign.left || TextAlign.start => Alignment.centerLeft,
        TextAlign.right || TextAlign.end => Alignment.centerRight,
        _ => Alignment.center,
      },
      child: child,
    );
    if (width != null) return SizedBox(width: width, child: aligned);
    return Expanded(flex: flex ?? 1, child: aligned);
  }
}

class HifiColumn {
  final String label;
  final double? width;
  final int? flex;
  final TextAlign align;
  const HifiColumn({required this.label, this.width, this.flex, this.align = TextAlign.left});
}

/// Compact totals strip: optional subtotal / VAT rows + big ИТОГО in navy.
class HifiTotals extends StatelessWidget {
  final String? subtotal;
  final String? vat;
  final String totalLabel;
  final String total;
  final Color? totalColor;
  final double totalFontSize;

  const HifiTotals({
    super.key,
    this.subtotal,
    this.vat,
    required this.totalLabel,
    required this.total,
    this.totalColor,
    this.totalFontSize = 26,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (subtotal != null) _row('Подытог', subtotal!),
        if (vat != null) _row('НДС 12%', vat!),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Text(
            '$totalLabel: ',
            style: Hifi.ui(size: totalFontSize * 0.6, weight: FontWeight.w700, color: totalColor ?? Hifi.chrome),
          ),
          Text(
            total,
            style: Hifi.mono(size: totalFontSize, weight: FontWeight.w700, color: totalColor ?? Hifi.chrome),
          ),
        ]),
      ]),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('$label: ', style: Hifi.ui(size: 13, color: const Color(0xFF666666))),
          Text(value, style: Hifi.mono(size: 13, color: const Color(0xFF666666))),
        ]),
      );
}

/// Hi-fi text input — 36px tall, search-style with leading icon, border flips
/// to navy on focus.
class HifiSearchField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final Widget? leading;
  final Widget? trailing;
  final FocusNode? focusNode;

  const HifiSearchField({
    super.key,
    this.controller,
    this.hint,
    this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.leading,
    this.trailing,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Hifi.border),
      ),
      child: Row(children: [
        leading ?? const Icon(Icons.search, size: 18, color: Color(0xFF666666)),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: autofocus,
            onSubmitted: onSubmitted,
            onChanged: onChanged,
            style: Hifi.ui(size: 13),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: Hifi.ui(size: 13, color: const Color(0xFF888888)),
            ),
          ),
        ),
        ?trailing,
      ]),
    );
  }
}
