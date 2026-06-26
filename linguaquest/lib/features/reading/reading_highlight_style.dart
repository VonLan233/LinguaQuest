import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../l10n/generated/app_localizations.dart';
import 'word_segmenter.dart';

/// Visual styling for a highlighted reading token, derived from its [WordClass].
///
/// Distinct, subtle styling per class using [AppTokens] colors:
/// - key → azure accent (bold underline)
/// - unknown (needs review) → danger, faint red background
/// - new → mango/amber underline
/// - known → success underline (subtle)
/// Plain tokens get no decoration (returns a transparent style).
class ReadingHighlightStyle {
  const ReadingHighlightStyle({
    required this.color,
    required this.background,
    required this.bold,
    required this.underline,
  });

  final Color color;
  final Color background;
  final bool bold;
  final bool underline;

  static ReadingHighlightStyle forClass(WordClass cls) {
    switch (cls) {
      case WordClass.key:
        return ReadingHighlightStyle(
          color: AppTokens.azure,
          background: AppTokens.primarySoft.withValues(alpha: 0.0),
          bold: true,
          underline: true,
        );
      case WordClass.unknown:
        return ReadingHighlightStyle(
          color: AppTokens.danger,
          background: AppTokens.dangerSoft,
          bold: true,
          underline: true,
        );
      case WordClass.newWord:
        return ReadingHighlightStyle(
          color: AppTokens.xpSoftText,
          background: AppTokens.xpSoft.withValues(alpha: 0.6),
          bold: true,
          underline: true,
        );
      case WordClass.known:
        return ReadingHighlightStyle(
          color: AppTokens.successSoftText,
          background: const Color(0x00000000),
          bold: false,
          underline: true,
        );
      case WordClass.plain:
        return const ReadingHighlightStyle(
          color: Color(0x00000000),
          background: Color(0x00000000),
          bold: false,
          underline: false,
        );
    }
  }
}

/// Localized legend label for a [WordClass].
String readingClassLabel(AppLocalizations l10n, WordClass cls) {
  switch (cls) {
    case WordClass.key:
      return l10n.readingClassKey;
    case WordClass.unknown:
      return l10n.readingClassUnknown;
    case WordClass.newWord:
      return l10n.readingClassNew;
    case WordClass.known:
      return l10n.readingClassKnown;
    case WordClass.plain:
      return '';
  }
}
