import 'package:flutter/material.dart';

import 'app_tokens.dart';

class AppTheme {
  const AppTheme._();

  // Brand palette — "Friendly Quest", anchored to the LinguaQuest cat mascot
  // (navy cat, sky-blue tile, leaf-green wordmark). Values live in AppTokens;
  // the names below are kept so existing screen references inherit the refresh.
  static const Color teal = AppTokens.azure;
  static const Color deepTeal = AppTokens.brandNavy;
  static const Color cyan = AppTokens.sky;
  static const Color coral = AppTokens.coral;
  static const Color mango = AppTokens.mango;
  static const Color mint = AppTokens.chipLight;
  static const Color leaf = AppTokens.success;
  static const Color ink = AppTokens.textPrimaryLight;
  static const Color paper = AppTokens.bgLight;
  static const Color lightSurface = AppTokens.surfaceLight;
  static const Color success = AppTokens.success;
  static const Color darkPaper = AppTokens.bgDark;
  static const Color darkSurface = AppTokens.surfaceDark;
  static const Color darkSurfaceHigh = AppTokens.surfaceDarkHigh;
  static const Color darkSurfaceHighest = AppTokens.surfaceDarkHigh;

  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: teal,
          brightness: Brightness.light,
          primary: teal,
          secondary: cyan,
          tertiary: mango,
          surface: lightSurface,
        ).copyWith(
          onPrimary: Colors.white,
          primaryContainer: mint,
          onPrimaryContainer: ink,
          secondaryContainer: mint,
          onSecondaryContainer: ink,
          tertiaryContainer: const Color(0xFFFFF0C2),
          onTertiaryContainer: const Color(0xFF4A3A00),
          surfaceContainerLowest: AppTokens.surfaceLight,
          surfaceContainerLow: AppTokens.bgLight,
          surfaceContainer: AppTokens.chipLight,
          surfaceContainerHigh: AppTokens.surfaceSunken,
          surfaceContainerHighest: const Color(0xFFE8E2D9),
          onSurface: AppTokens.textPrimaryLight,
          onSurfaceVariant: AppTokens.textSecondaryLight,
          outline: AppTokens.hairline,
          outlineVariant: AppTokens.outlineLight,
          error: AppTokens.coral,
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: paper);
  }

  static ThemeData dark() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: cyan,
          brightness: Brightness.dark,
          primary: AppTokens.azureDark,
          secondary: const Color(0xFFA3CFF5),
          tertiary: const Color(0xFFFFD767),
          surface: darkSurface,
          error: const Color(0xFFFFB4A8),
        ).copyWith(
          onPrimary: const Color(0xFF10254B),
          surfaceContainerLowest: AppTokens.bgDark,
          surfaceContainerLow: const Color(0xFF121E33),
          surfaceContainer: darkSurfaceHigh,
          surfaceContainerHigh: const Color(0xFF24365A),
          surfaceContainerHighest: darkSurfaceHighest,
          onSurface: AppTokens.textPrimaryDark,
          onSurfaceVariant: AppTokens.textSecondaryDark,
          outline: const Color(0xFF7E97B8),
          outlineVariant: AppTokens.outlineDark,
          primaryContainer: deepTeal,
          onPrimaryContainer: mint,
          secondaryContainer: ink,
          onSecondaryContainer: mint,
          tertiaryContainer: const Color(0xFF554500),
          onTertiaryContainer: const Color(0xFFFFF0C2),
        );

    return _base(scheme).copyWith(scaffoldBackgroundColor: darkPaper);
  }

  static bool isDark(BuildContext context) =>
      Theme.of(context).colorScheme.brightness == Brightness.dark;

  static Color warmSurface(BuildContext context) =>
      isDark(context) ? darkSurfaceHighest : const Color(0xFFFFF6DD);

  static Color accentSurface(BuildContext context) =>
      isDark(context) ? ink : mint;

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
      iconTheme: const IconThemeData(weight: 400, grade: 0, opticalSize: 24, fill: 0),
      textTheme: baseTextTheme.copyWith(
        displayMedium: baseTextTheme.displayMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineMedium: baseTextTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        headlineSmall: baseTextTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
        titleLarge: baseTextTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
        ),
        titleMedium: baseTextTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
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
        backgroundColor: isDark ? scheme.surfaceContainer : lightSurface,
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
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSheet),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTokens.radiusSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? scheme.surfaceContainerHigh : null,
        selectedColor: isDark ? scheme.primaryContainer : mint,
        disabledColor: isDark ? scheme.surfaceContainerLow : null,
        labelStyle: chipLabelStyle,
        secondaryLabelStyle: chipLabelStyle,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        side: BorderSide(color: scheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 54),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 54),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
        filled: true,
        fillColor: isDark ? scheme.surfaceContainerHigh : scheme.surface,
      ),
    );
  }
}
