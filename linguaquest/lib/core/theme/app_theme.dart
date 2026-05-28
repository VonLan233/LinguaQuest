import 'package:flutter/material.dart';

class AppTheme {
  const AppTheme._();

  static const Color teal = Color(0xFF00A99D);
  static const Color deepTeal = Color(0xFF006E72);
  static const Color cyan = Color(0xFF34C7D8);
  static const Color coral = Color(0xFFFF7A59);
  static const Color mango = Color(0xFFFFB84D);
  static const Color mint = Color(0xFFE5FFF8);
  static const Color ink = Color(0xFF10202A);
  static const Color paper = Color(0xFFF4F8F6);
  static const Color cardShadow = Color(0x1A006E72);
  static const Color darkPaper = Color(0xFF0D1518);
  static const Color darkSurface = Color(0xFF142125);
  static const Color darkSurfaceHigh = Color(0xFF1D2B30);
  static const Color darkSurfaceHighest = Color(0xFF26363B);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: teal,
      brightness: Brightness.light,
      primary: teal,
      secondary: coral,
      surface: Colors.white,
    );

    return _base(scheme).copyWith(scaffoldBackgroundColor: paper);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          primary: cyan,
          secondary: coral,
        ).copyWith(
          surface: darkSurface,
          surfaceContainerLowest: const Color(0xFF101A1D),
          surfaceContainerLow: const Color(0xFF172429),
          surfaceContainer: darkSurfaceHigh,
          surfaceContainerHigh: const Color(0xFF223238),
          surfaceContainerHighest: darkSurfaceHighest,
          onSurface: const Color(0xFFEAF4F2),
          onSurfaceVariant: const Color(0xFFC4D2D0),
          outline: const Color(0xFF76908E),
          outlineVariant: const Color(0xFF334A4D),
          primaryContainer: const Color(0xFF005B63),
          onPrimaryContainer: const Color(0xFFD9FEFF),
          secondaryContainer: const Color(0xFF6A2818),
          onSecondaryContainer: const Color(0xFFFFDAD1),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: darkPaper);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark;

  static Color warmSurface(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHigh
      : const Color(0xFFFFFBF2);

  static Color accentSurface(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHigh
      : const Color(0xFFFFF7E8);

  static Color selectedSurface(BuildContext context) =>
      isDark(context) ? Theme.of(context).colorScheme.primaryContainer : mint;

  static Color progressTrack(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : mint;

  static Color iconBadgeSurface(BuildContext context) => isDark(context)
      ? Theme.of(context).colorScheme.surfaceContainerHighest
      : mint;

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
        height: 72,
        elevation: 0,
        backgroundColor: isDark ? scheme.surfaceContainer : Colors.white,
        indicatorColor: isDark ? scheme.primaryContainer : mint,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
          minimumSize: const Size(48, 54),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
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
