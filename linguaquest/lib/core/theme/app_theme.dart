import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color teal = Color(0xFF4F46E5);
  static const Color deepTeal = Color(0xFF3730A3);
  static const Color cyan = Color(0xFF6366F1);
  static const Color coral = Color(0xFFFF6B4A);
  static const Color mango = Color(0xFFFFC800);
  static const Color mint = Color(0xFFE0E7FF);
  static const Color ink = Color(0xFF1E1B4B);
  static const Color paper = Color(0xFFF8FBF5);
  static const Color success = Color(0xFF22C55E);
  static const Color darkPaper = Color(0xFF0B0F1F);
  static const Color darkSurface = Color(0xFF0F1428);
  static const Color darkSurfaceHigh = Color(0xFF181F3A);
  static const Color darkSurfaceHighest = Color(0xFF1F2850);

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
          onPrimaryContainer: const Color(0xFF1E1B4B),
          secondaryContainer: const Color(0xFFE0E7FF),
          onSecondaryContainer: const Color(0xFF1E1B4B),
          tertiaryContainer: const Color(0xFFFFF1A6),
          onTertiaryContainer: const Color(0xFF463B00),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFFBFDF8),
          surfaceContainer: const Color(0xFFF3F4F8),
          surfaceContainerHigh: const Color(0xFFEAEBF5),
          surfaceContainerHighest: const Color(0xFFDDDFF0),
          onSurface: ink,
          onSurfaceVariant: const Color(0xFF536471),
          outline: const Color(0xFFA9AACC),
          outlineVariant: const Color(0xFFE0E1F0),
          error: const Color(0xFFE04F3A),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: paper);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          primary: const Color(0xFF818CF8),
          secondary: const Color(0xFFA5B4FC),
          tertiary: const Color(0xFFFFD85C),
          surface: darkSurface,
          error: const Color(0xFFFFB4A8),
        ).copyWith(
          onPrimary: const Color(0xFF1E1B4B),
          surfaceContainerLowest: const Color(0xFF0B0F1F),
          surfaceContainerLow: const Color(0xFF111528),
          surfaceContainer: darkSurfaceHigh,
          surfaceContainerHigh: const Color(0xFF1E2650),
          surfaceContainerHighest: darkSurfaceHighest,
          onSurface: const Color(0xFFE4E8F4),
          onSurfaceVariant: const Color(0xFFC1C8E8),
          outline: const Color(0xFF848CB9),
          outlineVariant: const Color(0xFF313D63),
          primaryContainer: const Color(0xFF3730A3),
          onPrimaryContainer: const Color(0xFFE0E7FF),
          secondaryContainer: const Color(0xFF1E1B4B),
          onSecondaryContainer: const Color(0xFFE0E7FF),
          tertiaryContainer: const Color(0xFF554800),
          onTertiaryContainer: const Color(0xFFFFF1A6),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: darkPaper);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark;

  static Color warmSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F2850) : const Color(0xFFFFF8D8);

  static Color accentSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1E1B4B) : const Color(0xFFE0E7FF);

  static Color selectedSurface(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.primaryContainer : mint;

  static Color progressTrack(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : const Color(0xFFE0E7FF);

  static Color iconBadgeSurface(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : const Color(0xFFE0E7FF);

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
            : const Color(0xFFE0E7FF),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 56),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
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
