import 'package:flutter/material.dart';

/// POS System Kazakhstan — "Slate & Action" Design System
///
/// Based on ArchitectLedger V4 Stitch designs.
/// Deep Navy primary, professional retail-grade UI with high contrast,
/// large touch targets, and bold typography for prices.
class AppTheme {
  AppTheme._();

  // === Brand Colors (Stitch V4 "Slate & Action") ===
  static const Color primary = Color(0xFF002556);
  static const Color primaryContainer = Color(0xFF003A80);
  static const Color onPrimaryContainer = Color(0xFF78A6FF);
  static const Color inversePrimary = Color(0xFFADC6FF);

  static const Color secondary = Color(0xFF006C49);
  static const Color secondaryContainer = Color(0xFF6CF8BB);

  static const Color tertiary = Color(0xFF56000B);
  static const Color tertiaryContainer = Color(0xFF79121B);

  static const Color error = Color(0xFFBA1A1A);
  static const Color success = Color(0xFF006C49);
  static const Color warning = Color(0xFFD97706);

  // Sidebar
  static const Color sidebarBg = Color(0xFF0F172A);
  static const Color sidebarActiveBg = Color(0xFF1D3A6E);
  static const Color sidebarActiveText = Color(0xFF60A5FA);
  static const Color sidebarText = Color(0xFF94A3B8);

  // === Shared component styling ===
  static final _buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
  static const _buttonMinSize = Size(48, 52);
  static final _inputBorder = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  /// Light theme
  static ThemeData get light {
    const cs = ColorScheme(
      brightness: Brightness.light,
      primary: primary,
      onPrimary: Colors.white,
      primaryContainer: primaryContainer,
      onPrimaryContainer: onPrimaryContainer,
      secondary: secondary,
      onSecondary: Colors.white,
      secondaryContainer: secondaryContainer,
      onSecondaryContainer: Color(0xFF00714D),
      tertiary: Color(0xFF56000B),
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF79121B),
      onTertiaryContainer: Color(0xFFFF8180),
      error: error,
      onError: Colors.white,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFF8F9FF),
      onSurface: Color(0xFF0D1C2F),
      onSurfaceVariant: Color(0xFF43474C),
      outline: Color(0xFF74777D),
      outlineVariant: Color(0xFFC4C6CD),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFEFF4FF),
      surfaceContainer: Color(0xFFE6EEFF),
      surfaceContainerHigh: Color(0xFFDDE9FF),
      surfaceContainerHighest: Color(0xFFD5E3FD),
      inverseSurface: Color(0xFF233144),
      onInverseSurface: Color(0xFFEBF1FF),
      inversePrimary: inversePrimary,
      surfaceTint: Color(0xFF005BC1),
    );
    return _buildTheme(cs);
  }

  /// Dark theme
  static ThemeData get dark {
    const cs = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFFADC6FF),
      onPrimary: Color(0xFF002556),
      primaryContainer: Color(0xFF003A80),
      onPrimaryContainer: Color(0xFFD8E2FF),
      secondary: Color(0xFF4EDEA3),
      onSecondary: Color(0xFF002113),
      secondaryContainer: Color(0xFF005236),
      onSecondaryContainer: Color(0xFF6FFBBE),
      tertiary: Color(0xFFFFB3B0),
      onTertiary: Color(0xFF410006),
      tertiaryContainer: Color(0xFF79121B),
      onTertiaryContainer: Color(0xFFFFDAD8),
      error: Color(0xFFF87171),
      onError: Color(0xFF0F172A),
      errorContainer: Color(0xFF7F1D1D),
      onErrorContainer: Color(0xFFFEE2E2),
      surface: Color(0xFF0D1C2F),
      onSurface: Color(0xFFD5E3FD),
      onSurfaceVariant: Color(0xFFC4C6CD),
      outline: Color(0xFF74777D),
      outlineVariant: Color(0xFF43474C),
      surfaceContainerLowest: Color(0xFF030712),
      surfaceContainerLow: Color(0xFF0D1C2F),
      surfaceContainer: Color(0xFF1E293B),
      surfaceContainerHigh: Color(0xFF233144),
      surfaceContainerHighest: Color(0xFF334155),
      inverseSurface: Color(0xFFD5E3FD),
      onInverseSurface: Color(0xFF0D1C2F),
      inversePrimary: Color(0xFF002556),
      surfaceTint: Color(0xFFADC6FF),
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
      scaffoldBackgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8F9FF),

      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? cs.surface : const Color(0xFFF8F9FF),
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
          side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
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

      dividerTheme: DividerThemeData(color: cs.outlineVariant.withValues(alpha: 0.3), thickness: 1, space: 1),

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
        dividerColor: cs.outlineVariant.withValues(alpha: 0.3),
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

  // Tinted backgrounds
  Color get successBg => _isDark ? AppTheme.success.withValues(alpha: 0.12) : const Color(0xFFD1FAE5);
  Color get errorBg   => _isDark ? AppTheme.error.withValues(alpha: 0.12)   : const Color(0xFFFFDAD6);
  Color get warningBg => _isDark ? AppTheme.warning.withValues(alpha: 0.12) : const Color(0xFFFEF3C7);
  Color get accentBg  => _isDark ? const Color(0xFF002556).withValues(alpha: 0.2) : const Color(0xFFD8E2FF);

  // Foreground colors
  Color get successFg => _isDark ? const Color(0xFF4EDEA3) : AppTheme.success;
  Color get errorFg   => _isDark ? const Color(0xFFF87171) : AppTheme.error;
  Color get warningFg => _isDark ? const Color(0xFFFBBF24) : AppTheme.warning;
  Color get accentFg  => _isDark ? const Color(0xFFADC6FF) : AppTheme.primary;
}
