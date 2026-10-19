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
  static const double radiusChip = 12;
  static const double radiusButton = 18;
  static const double radiusTile = 18;
  static const double radiusCard = 22;
  static const double radiusSheet = 26;
  static const double radiusPill = 999;

  // Durations.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);

  // Brand palette (light) — Cozy Quest.
  static const Color brandNavy = Color(0xFF193956);
  static const Color azure = Color(0xFF2469DF);
  static const Color azurePressed = Color(0xFF1F5FAE);
  static const Color sky = Color(0xFF8FD0F2);
  static const Color success = Color(0xFF5FB23C);
  static const Color mango = Color(0xFFFFB22E);
  static const Color coral = Color(0xFFFF6B5A);
  static const Color amber = Color(0xFFF5A623);
  // True antonym/error red (cool-blue reference comps use a truer red than the
  // warm `coral`): used for antonyms, errors, and high-difficulty tags.
  static const Color danger = Color(0xFFE5484D);
  static const Color dangerSoft = Color(0xFFFCE9EA);

  // Neutrals.
  // Cool off-white page background (reference comps float white cards on it).
  static const Color bgLight = Color(0xFFF7F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFEDF1F7);
  static const Color hairline = Color(0xFFE5EBF3);
  static const Color chipLight = Color(0xFFEAF2FC); // = primarySoft
  static const Color textPrimaryLight = Color(0xFF193956);
  static const Color textSecondaryLight = Color(0xFF64788B);
  static const Color textHintLight = Color(0xFF73869A);
  static const Color outlineLight = Color(0xFFE5EBF3);

  // Semantic soft fills (badge / chip backgrounds).
  static const Color xpSoft = Color(0xFFFFF1D6);
  static const Color xpSoftText = Color(0xFFE08A00);
  static const Color successSoft = Color(0xFFF2FAEC);
  static const Color successSoftText = Color(0xFF3F7A22);
  static const Color streakSoft = Color(0xFFFFE2DC);
  static const Color streakSoftText = Color(0xFFE8503B);
  static const Color primarySoft = Color(0xFFEAF2FC);
  static const Color primarySoftText = Color(0xFF2469DF);

  // Brand palette (dark) — derived from the navy cat.
  static const Color bgDark = Color(0xFF0E1626);
  static const Color surfaceDark = Color(0xFF16223A);
  static const Color surfaceDarkHigh = Color(0xFF1E2D49);
  static const Color azureDark = Color(0xFF6FB0F5);
  static const Color textPrimaryDark = Color(0xFFE6EEF8);
  static const Color textSecondaryDark = Color(0xFF9DB0CC);
  static const Color outlineDark = Color(0xFF2D4263);

  /// Standard progress fill: "from start (mango) to done (success)".
  static const LinearGradient progressGradient = LinearGradient(
    colors: [mango, success],
  );

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Soft single-layer elevation shadow used by cards.
  static List<BoxShadow> cardShadow(BuildContext c) => _isDark(c)
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F28283C), // ~6% cool-ink
            blurRadius: 22,
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
  static Color dangerColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFF26F73) : danger;
  static Color amberColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFFC04D) : amber;
}
