import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  // Brand palette derived from the LinguaQuest cat mascot icon:
  // deep navy cat, sky-blue tile, grass-green wordmark accent.
  static const Color teal = Color(0xFF2F55A4);
  static const Color deepTeal = Color(0xFF1E3A7A);
  static const Color cyan = Color(0xFF3D9BE9);
  static const Color coral = Color(0xFFFF7A59);
  static const Color mango = Color(0xFFFFC83D);
  static const Color mint = Color(0xFFD8EBFB);
  static const Color leaf = Color(0xFF6CBF3F);
  static const Color ink = Color(0xFF16315F);
  static const Color paper = Color(0xFFF2F8FE);
  static const Color success = Color(0xFF5CB531);
  static const Color darkPaper = Color(0xFF0A1426);
  static const Color darkSurface = Color(0xFF0F1B33);
  static const Color darkSurfaceHigh = Color(0xFF172A4A);
  static const Color darkSurfaceHighest = Color(0xFF1F3458);

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.light,
          primary: teal,
          secondary: cyan,
          tertiary: mango,
          surface: Colors.white,
        ).copyWith(
          onPrimary: Colors.white,
          primaryContainer: mint,
          onPrimaryContainer: ink,
          secondaryContainer: const Color(0xFFD8EBFB),
          onSecondaryContainer: ink,
          tertiaryContainer: const Color(0xFFFFF0C2),
          onTertiaryContainer: const Color(0xFF4A3A00),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFF8FBFE),
          surfaceContainer: const Color(0xFFEFF5FC),
          surfaceContainerHigh: const Color(0xFFE4EEF9),
          surfaceContainerHighest: const Color(0xFFD5E5F5),
          onSurface: ink,
          onSurfaceVariant: const Color(0xFF4F6480),
          outline: const Color(0xFF93AECC),
          outlineVariant: const Color(0xFFD7E4F2),
          error: const Color(0xFFE04F3A),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: paper);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          primary: const Color(0xFF7FBCF2),
          secondary: const Color(0xFFA3CFF5),
          tertiary: const Color(0xFFFFD767),
          surface: darkSurface,
          error: const Color(0xFFFFB4A8),
        ).copyWith(
          onPrimary: const Color(0xFF10254B),
          surfaceContainerLowest: const Color(0xFF0A1426),
          surfaceContainerLow: const Color(0xFF0D1A30),
          surfaceContainer: darkSurfaceHigh,
          surfaceContainerHigh: const Color(0xFF1C3050),
          surfaceContainerHighest: darkSurfaceHighest,
          onSurface: const Color(0xFFE3ECF6),
          onSurfaceVariant: const Color(0xFFBDD0E5),
          outline: const Color(0xFF7E97B8),
          outlineVariant: const Color(0xFF2D4263),
          primaryContainer: const Color(0xFF1E3A7A),
          onPrimaryContainer: const Color(0xFFD8EBFB),
          secondaryContainer: const Color(0xFF16315F),
          onSecondaryContainer: const Color(0xFFD8EBFB),
          tertiaryContainer: const Color(0xFF554500),
          onTertiaryContainer: const Color(0xFFFFF0C2),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: darkPaper);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark;

  static Color warmSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F3458) : const Color(0xFFFFF6DD);

  static Color accentSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF16315F) : const Color(0xFFD8EBFB);

  static Color selectedSurface(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.primaryContainer : mint;

  static Color progressTrack(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : const Color(0xFFD8EBFB);

  static Color iconBadgeSurface(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : const Color(0xFFD8EBFB);

  static ThemeData _base(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final baseTextTheme = scheme.brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;
    final chipLabelStyle = WidgetStateTextStyle.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return TextStyle(color: scheme.onSurface.withValues(alpha: 0.38));
      }
      if (isDark && states.contains(WidgetState.selected)) {
        return TextStyle(color: scheme.onPrimaryContainer);
      }
      return TextStyle(color: scheme.onSurface);
    });

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Avenir',
      textTheme: baseTextTheme.copyWith(
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: 0,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w900,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
        ),
      ),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? scheme.onSurface : ink,
        iconTheme: IconThemeData(color: isDark ? scheme.onSurface : ink),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainer : Colors.white,
        indicatorColor: isDark
            ? scheme.primaryContainer
            : const Color(0xFFD8EBFB),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? scheme.onSurface
                : scheme.onSurfaceVariant,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w900
                : FontWeight.w700,
            fontSize: 12,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : null,
        selectedColor: isDark ? scheme.primaryContainer : mint,
        disabledColor: isDark ? scheme.surfaceContainerLow : null,
        labelStyle: chipLabelStyle,
        secondaryLabelStyle: chipLabelStyle,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 56),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 56),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
      ),
    );
  }
}
