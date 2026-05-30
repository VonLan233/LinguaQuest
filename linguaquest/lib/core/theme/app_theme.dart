import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color teal = Color(0xFF58CC02);
  static const Color deepTeal = Color(0xFF1F5F8B);
  static const Color cyan = Color(0xFF1CB0F6);
  static const Color coral = Color(0xFFFF6B4A);
  static const Color mango = Color(0xFFFFC800);
  static const Color mint = Color(0xFFD7FFB8);
  static const Color ink = Color(0xFF17324D);
  static const Color paper = Color(0xFFF8FBF5);
  static const Color success = Color(0xFF58CC02);
  static const Color darkPaper = Color(0xFF0B1724);
  static const Color darkSurface = Color(0xFF102033);
  static const Color darkSurfaceHigh = Color(0xFF182A40);
  static const Color darkSurfaceHighest = Color(0xFF22374F);

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
          onPrimaryContainer: const Color(0xFF214100),
          secondaryContainer: const Color(0xFFDDF3FF),
          onSecondaryContainer: const Color(0xFF063653),
          tertiaryContainer: const Color(0xFFFFF1A6),
          onTertiaryContainer: const Color(0xFF463B00),
          surfaceContainerLowest: Colors.white,
          surfaceContainerLow: const Color(0xFFFBFDF8),
          surfaceContainer: const Color(0xFFF3F8EE),
          surfaceContainerHigh: const Color(0xFFEAF2E5),
          surfaceContainerHighest: const Color(0xFFDDEBD7),
          onSurface: ink,
          onSurfaceVariant: const Color(0xFF536471),
          outline: const Color(0xFFA9C49F),
          outlineVariant: const Color(0xFFE0ECD9),
          error: const Color(0xFFE04F3A),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: paper);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          primary: const Color(0xFF89E219),
          secondary: const Color(0xFF6ED6FF),
          tertiary: const Color(0xFFFFD85C),
          surface: darkSurface,
          error: const Color(0xFFFFB4A8),
        ).copyWith(
          onPrimary: const Color(0xFF173000),
          surfaceContainerLowest: const Color(0xFF101A1D),
          surfaceContainerLow: const Color(0xFF172429),
          surfaceContainer: darkSurfaceHigh,
          surfaceContainerHigh: const Color(0xFF22364F),
          surfaceContainerHighest: darkSurfaceHighest,
          onSurface: const Color(0xFFEAF4F2),
          onSurfaceVariant: const Color(0xFFC1D5E8),
          outline: const Color(0xFF84A0B9),
          outlineVariant: const Color(0xFF314963),
          primaryContainer: const Color(0xFF255400),
          onPrimaryContainer: const Color(0xFFE7FFD1),
          secondaryContainer: const Color(0xFF053B59),
          onSecondaryContainer: const Color(0xFFDDF3FF),
          tertiaryContainer: const Color(0xFF554800),
          onTertiaryContainer: const Color(0xFFFFF1A6),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: darkPaper);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark;

  static Color warmSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF1F3046) : const Color(0xFFFFF8D8);

  static Color accentSurface(BuildContext context) =>
      isDark(context) ? const Color(0xFF173A55) : const Color(0xFFE8F7FF);

  static Color selectedSurface(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.primaryContainer : mint;

  static Color progressTrack(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : const Color(0xFFDDF3FF);

  static Color iconBadgeSurface(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : const Color(0xFFE9FFD9);

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
            : const Color(0xFFE9FFD9),
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
