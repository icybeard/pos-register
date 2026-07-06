import 'package:flutter/material.dart';

/// KeregeSystem Design System v1.0 — Flutter theme.
///
/// Canonical spec: `pos-docs/design-system/`.
/// Terracotta primary, warm-neutral cream/ink surfaces, semantic scales locked at
/// oklch(.60 .13 H). pos-register's identity accent is Blue `#3567ad` — used only
/// for the app's own header tint and the active nav state.
///
/// Class name `AppTheme` is preserved for backwards compatibility with the
/// existing 14 callers; only the colors change.
class AppTheme {
  AppTheme._();

  // === Brand · Primary (Terracotta) === see pos-docs/design-system/palette.md
  static const Color primary = Color(0xFFBF5F30);
  static const Color primaryContainer = Color(0xFFFAE0C9);
  static const Color onPrimaryContainer = Color(0xFF432011);
  static const Color inversePrimary = Color(0xFFF3C197);

  // === Secondary · pos-register's identity accent (Blue) ===
  static const Color secondary = Color(0xFF3567AD);
  static const Color secondaryContainer = Color(0xFFD3E0F1);

  // === Tertiary · Gold (carryover slot, currently unused but kept for API) ===
  static const Color tertiary = Color(0xFFA98C2A);
  static const Color tertiaryContainer = Color(0xFFF2E3A8);

  // === Semantic ===
  static const Color error = Color(0xFFB8332E);
  static const Color success = Color(0xFF2C8A5A);
  static const Color warning = Color(0xFFB6781A);
  static const Color info = Color(0xFF1E7A93);

  // === Sidebar (warm-neutral / ink) ===
  // Names preserved; recolored from the old slate-navy to KeregeSystem ink + cream.
  static const Color sidebarBg = Color(0xFF1D1A16);          // neutral-900 (ink)
  static const Color sidebarActiveBg = Color(0xFF322E28);    // neutral-800
  static const Color sidebarActiveText = Color(0xFFE89D65);  // primary-300 (warm highlight)
  static const Color sidebarText = Color(0xFFA59C8B);        // neutral-400

  // === Surfaces (light) ===
  static const Color bgLight = Color(0xFFFAF7F0);            // neutral-50 (cream)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceHoverLight = Color(0xFFF3EDE0);  // neutral-100
  static const Color borderLight = Color(0xFFE5DCCB);        // neutral-200

  // === Surfaces (dark) ===
  static const Color bgDark = Color(0xFF100E0C);             // neutral-950
  static const Color surfaceDark = Color(0xFF1D1A16);        // neutral-900 (ink)
  static const Color surfaceHoverDark = Color(0xFF322E28);   // neutral-800
  static const Color borderDark = Color(0xFF4A453C);         // neutral-700

  // === Shared component styling ===
  static final _buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  static const _buttonMinSize = Size(48, 52);
  static final _inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  /// Light theme — cream surfaces, ink text, terracotta primary.
  static ThemeData get light {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Color(0xFFFAF7F0),                          // cream
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: Color(0xFFFAF7F0),
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF14253D),               // secondary-900
      tertiary: tertiary,
      onTertiary: Color(0xFFFAF7F0),
      tertiaryContainer: tertiaryContainer,
      onTertiaryContainer: Color(0xFF34290D),                // accent-900
      error: error,
      onError: Color(0xFFFAF7F0),
      errorContainer: Color(0xFFFBE9E7),                     // error-50
      onErrorContainer: Color(0xFF531311),                   // error-800
      surface: bgLight,                                       // cream page bg
      onSurface: Color(0xFF1D1A16),                           // ink
      onSurfaceVariant: Color(0xFF4A453C),                    // neutral-700
      outline: Color(0xFF837B6D),                             // neutral-500
      outlineVariant: Color(0xFFC8BFAC),                      // neutral-300
      surfaceContainerLowest: surfaceLight,                   // pure white
      surfaceContainerLow: Color(0xFFFAF7F0),                 // cream
      surfaceContainer: Color(0xFFF3EDE0),                    // neutral-100
      surfaceContainerHigh: Color(0xFFE5DCCB),                // neutral-200
      surfaceContainerHighest: Color(0xFFC8BFAC),             // neutral-300
      inverseSurface: Color(0xFF322E28),                      // neutral-800
      onInverseSurface: Color(0xFFFAF7F0),
      inversePrimary: inversePrimary,
      surfaceTint: primary,
    );
    return _buildTheme(cs);
  }

  /// Dark theme — ink surfaces, cream text, warm terracotta primary.
  static ThemeData get dark {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFE89D65),                             // primary-300 (warm on dark)
      onPrimary: Color(0xFF432011),                           // primary-900
      primaryContainer: Color(0xFF843D1D),                    // primary-700
      onPrimaryContainer: Color(0xFFFAE0C9),                  // primary-100
      secondary: Color(0xFF739DD0),                           // secondary-300
      onSecondary: Color(0xFF14253D),                         // secondary-900
      secondaryContainer: Color(0xFF234670),                  // secondary-700
      onSecondaryContainer: Color(0xFFD3E0F1),                // secondary-100
      tertiary: Color(0xFFD0AD44),                            // accent-300
      onTertiary: Color(0xFF34290D),                          // accent-900
      tertiaryContainer: Color(0xFF715B1C),                   // accent-700
      onTertiaryContainer: Color(0xFFF2E3A8),                 // accent-100
      error: Color(0xFFDC6A64),                               // error-300
      onError: Color(0xFF340B0A),                             // error-900
      errorContainer: Color(0xFF721B18),                      // error-700
      onErrorContainer: Color(0xFFF5C4BF),                    // error-100
      surface: surfaceDark,                                    // ink
      onSurface: Color(0xFFFAF7F0),                            // cream
      onSurfaceVariant: Color(0xFFC8BFAC),                     // neutral-300
      outline: Color(0xFF837B6D),                              // neutral-500
      outlineVariant: Color(0xFF4A453C),                       // neutral-700
      surfaceContainerLowest: Color(0xFF100E0C),               // neutral-950
      surfaceContainerLow: Color(0xFF1D1A16),                  // neutral-900
      surfaceContainer: Color(0xFF322E28),                     // neutral-800
      surfaceContainerHigh: Color(0xFF4A453C),                 // neutral-700
      surfaceContainerHighest: Color(0xFF645E52),              // neutral-600
      inverseSurface: Color(0xFFFAF7F0),
      onInverseSurface: Color(0xFF1D1A16),
      inversePrimary: primary,
      surfaceTint: Color(0xFFE89D65),
    );
    return _buildTheme(cs);
  }

  static ThemeData _buildTheme(ColorScheme cs) {
    final isDark = cs.brightness == Brightness.dark;
    final baseTextTheme =
        (isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme)
            .apply(fontFamily: 'Inter');

    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge!.copyWith(
        fontSize: 44, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: cs.onSurface, height: 1.1,
      ),
      headlineLarge: baseTextTheme.headlineLarge!.copyWith(
        fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8, color: cs.onSurface, height: 1.2,
      ),
      headlineMedium: baseTextTheme.headlineMedium!.copyWith(
        fontSize: 24, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: cs.onSurface, height: 1.25,
      ),
      headlineSmall: baseTextTheme.headlineSmall!.copyWith(
        fontSize: 20, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: cs.onSurface, height: 1.3,
      ),
      titleLarge: baseTextTheme.titleLarge!.copyWith(
        fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: cs.onSurface,
      ),
      titleMedium: baseTextTheme.titleMedium!.copyWith(
        fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.1, color: cs.onSurface,
      ),
      titleSmall: baseTextTheme.titleSmall!.copyWith(
        fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface,
      ),
      bodyLarge: baseTextTheme.bodyLarge!.copyWith(
        fontSize: 15, fontWeight: FontWeight.w400, color: cs.onSurface, height: 1.5,
      ),
      bodyMedium: baseTextTheme.bodyMedium!.copyWith(
        fontSize: 14, fontWeight: FontWeight.w400, color: cs.onSurfaceVariant,
      ),
      bodySmall: baseTextTheme.bodySmall!.copyWith(
        fontSize: 12, fontWeight: FontWeight.w400, color: cs.outline,
      ),
      labelLarge: baseTextTheme.labelLarge!.copyWith(
        fontSize: 15, fontWeight: FontWeight.w600, color: cs.onSurface, letterSpacing: -0.1,
      ),
      labelMedium: baseTextTheme.labelMedium!.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant,
      ),
      labelSmall: baseTextTheme.labelSmall!.copyWith(
        fontSize: 11, fontWeight: FontWeight.w600, color: cs.outline, letterSpacing: 0.8,
      ),
    );

    const buttonTextStyle = TextStyle(fontFamily: 'Inter',
      fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: cs.brightness,
      colorScheme: cs,
      textTheme: textTheme,
      scaffoldBackgroundColor: isDark ? bgDark : bgLight,

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? cs.surface : bgLight,
        foregroundColor: cs.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: 'Inter',
          fontSize: 20, fontWeight: FontWeight.w700, color: cs.onSurface, letterSpacing: -0.4,
        ),
      ),

      cardTheme: CardThemeData(
        color: cs.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: _buttonMinSize,
          textStyle: buttonTextStyle,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: _buttonShape,
          elevation: 0,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: _buttonMinSize, textStyle: buttonTextStyle,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: _buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: _buttonMinSize, textStyle: buttonTextStyle,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: _buttonShape,
          side: BorderSide(color: cs.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 15, fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? cs.surfaceContainer : cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder.copyWith(borderSide: BorderSide.none),
        enabledBorder: _inputBorder.copyWith(borderSide: BorderSide.none),
        focusedBorder: _inputBorder.copyWith(borderSide: BorderSide(color: cs.primary, width: 2)),
        hintStyle: TextStyle(fontFamily: 'Inter', color: cs.outline, fontSize: 14),
        labelStyle: TextStyle(fontFamily: 'Inter', color: cs.onSurfaceVariant, fontSize: 14),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.primaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      dividerTheme: DividerThemeData(color: cs.outlineVariant.withValues(alpha: 0.4), thickness: 1, space: 1),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cs.surface,
        indicatorColor: cs.primaryContainer,
        surfaceTintColor: Colors.transparent,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary);
          }
          return TextStyle(fontFamily: 'Inter', fontSize: 11, color: cs.onSurfaceVariant);
        }),
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface),
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),

      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: cs.primary,
        unselectedLabelColor: cs.onSurfaceVariant,
        indicatorColor: cs.primary,
        labelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Inter', fontSize: 14, fontWeight: FontWeight.w500),
        dividerColor: cs.outlineVariant.withValues(alpha: 0.4),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}

/// Adaptive semantic colors for light/dark mode.
/// Usage: `final pos = PosColors.of(context);`
class PosColors {
  final ColorScheme _cs;
  PosColors._(this._cs);

  factory PosColors.of(BuildContext context) => PosColors._(Theme.of(context).colorScheme);

  bool get _isDark => _cs.brightness == Brightness.dark;

  // Tinted backgrounds — success/warning/error pills + brand accent surface.
  Color get successBg => _isDark ? AppTheme.success.withValues(alpha: 0.18) : const Color(0xFFE7F6ED); // success-50
  Color get errorBg   => _isDark ? AppTheme.error.withValues(alpha: 0.18)   : const Color(0xFFFBE9E7); // error-50
  Color get warningBg => _isDark ? AppTheme.warning.withValues(alpha: 0.18) : const Color(0xFFFEF6E0); // warning-50
  Color get accentBg  => _isDark ? AppTheme.primary.withValues(alpha: 0.22) : const Color(0xFFFDF3EC); // primary-50

  // Foreground colors — tuned darker on light, lighter on dark for contrast.
  Color get successFg => _isDark ? const Color(0xFF8FD2A8) : const Color(0xFF226E47); // success-700
  Color get errorFg   => _isDark ? const Color(0xFFEA9690) : const Color(0xFF952520); // error-700
  Color get warningFg => _isDark ? const Color(0xFFFBCF69) : const Color(0xFF905C13); // warning-700
  Color get accentFg  => _isDark ? const Color(0xFFE89D65) : const Color(0xFFA44D24); // primary-300 / primary-700
}
