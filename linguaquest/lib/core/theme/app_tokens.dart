import 'package:flutter/material.dart';

/// Single source of truth for the "Friendly Quest" design tokens.
///
/// Spacing, radii, durations and the brand palette live here so visual changes
/// propagate from one place. Semantic accent accessors brighten on dark.
class AppTokens {
  const AppTokens._();

  // Spacing scale.
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // Radii.
  static const double radiusSmall = 12;
  static const double radiusButton = 16;
  static const double radiusCard = 20;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;

  // Durations.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);

  // Brand palette (light).
  static const Color brandNavy = Color(0xFF233A66);
  static const Color azure = Color(0xFF2C7BE0);
  static const Color sky = Color(0xFF8FD0F2);
  static const Color success = Color(0xFF5FB23C);
  static const Color mango = Color(0xFFFFB22E);
  static const Color coral = Color(0xFFFF6B5A);
  static const Color amber = Color(0xFFF5A623);

  static const Color bgLight = Color(0xFFF4F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color chipLight = Color(0xFFEAF1F9);
  static const Color textPrimaryLight = Color(0xFF1E2A44);
  static const Color textSecondaryLight = Color(0xFF6B7B95);
  static const Color textHintLight = Color(0xFF9AA8BE);
  static const Color outlineLight = Color(0xFFE4ECF5);

  // Brand palette (dark) — derived from the navy cat.
  static const Color bgDark = Color(0xFF0E1626);
  static const Color surfaceDark = Color(0xFF16223A);
  static const Color surfaceDarkHigh = Color(0xFF1E2D49);
  static const Color azureDark = Color(0xFF6FB0F5);
  static const Color textPrimaryDark = Color(0xFFE6EEF8);
  static const Color textSecondaryDark = Color(0xFF9DB0CC);
  static const Color outlineDark = Color(0xFF2D4263);

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Soft elevation shadow used by cards (flat-with-depth in light mode).
  static List<BoxShadow> cardShadow(BuildContext c) => _isDark(c)
      ? const []
      : const [
          BoxShadow(
            color: Color(0x14233A66), // navy @ ~8%
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ];

  // Semantic accent accessors (brightened on dark surfaces).
  static Color successColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFF7FD05A) : success;
  static Color mangoColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFFC85C) : mango;
  static Color coralColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFF8A7B) : coral;
  static Color amberColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFFC04D) : amber;
}
