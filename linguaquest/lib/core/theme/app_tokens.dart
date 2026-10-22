import 'package:flutter/material.dart';

/// Single source of truth for the Swiss-inspired LinguaQuest design tokens.
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
  static const double radiusSmall = 4;
  static const double radiusChip = 4;
  static const double radiusButton = 4;
  static const double radiusTile = 4;
  static const double radiusCard = 4;
  static const double radiusSheet = 8;
  static const double radiusPill = 999;

  // Durations.
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);

  // Brand palette (light) — Cozy Quest.
  static const Color brandNavy = Color(0xFF171B22);
  static const Color azure = Color(0xFF1555E8);
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
  static const Color bgLight = Color(0xFFFAFBFC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFEEF0F3);
  static const Color hairline = Color(0xFFDDE1E6);
  static const Color chipLight = Color(0xFFEAF2FC); // = primarySoft
  static const Color textPrimaryLight = Color(0xFF171B22);
  static const Color textSecondaryLight = Color(0xFF535E6B);
  static const Color textHintLight = Color(0xFF626E7D);
  static const Color outlineLight = Color(0xFFDDE1E6);

  // Semantic soft fills (badge / chip backgrounds).
  static const Color xpSoft = Color(0xFFFFF1D6);
  static const Color xpSoftText = Color(0xFFE08A00);
  static const Color successSoft = Color(0xFFF2FAEC);
  static const Color successSoftText = Color(0xFF3F7A22);
  static const Color streakSoft = Color(0xFFFFE2DC);
  static const Color streakSoftText = Color(0xFFE8503B);
  static const Color primarySoft = Color(0xFFEAF2FC);
  static const Color primarySoftText = Color(0xFF1555E8);

  // Brand palette (dark) — derived from the navy cat.
  static const Color bgDark = Color(0xFF101317);
  static const Color surfaceDark = Color(0xFF171B21);
  static const Color surfaceDarkHigh = Color(0xFF222830);
  static const Color azureDark = Color(0xFF93B4FF);
  static const Color textPrimaryDark = Color(0xFFF1F3F6);
  static const Color textSecondaryDark = Color(0xFFAEB8C7);
  static const Color outlineDark = Color(0xFF343D49);

  /// Standard progress fill: "from start (mango) to done (success)".
  static const LinearGradient progressGradient = LinearGradient(
    colors: [mango, success],
  );

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Flat surfaces use hairline borders instead of elevation.
  static List<BoxShadow> cardShadow(BuildContext c) => const [];

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
