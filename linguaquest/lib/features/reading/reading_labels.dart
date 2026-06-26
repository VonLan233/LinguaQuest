import '../../l10n/generated/app_localizations.dart';

/// Localized label for an article theme key (campus|life|travel|...).
String readingThemeLabel(AppLocalizations l10n, String theme) {
  switch (theme) {
    case 'campus':
      return l10n.readingThemeCampus;
    case 'life':
      return l10n.readingThemeLife;
    case 'travel':
      return l10n.readingThemeTravel;
    case 'tech':
      return l10n.readingThemeTech;
    case 'culture':
      return l10n.readingThemeCulture;
    case 'news':
      return l10n.readingThemeNews;
    case 'business':
      return l10n.readingThemeBusiness;
    case 'exam':
      return l10n.readingThemeExam;
    default:
      return theme;
  }
}

/// Short level chip, e.g. "HSK 1" / "JLPT N5", derived from language + level id.
///
/// Falls back to the raw level id when the convention is unknown.
String readingLevelLabel(String language, String level, {int? examLevel}) {
  final id = level.toLowerCase();
  if (id.startsWith('hsk')) {
    final n = examLevel ?? int.tryParse(id.replaceAll('hsk', ''));
    return n == null ? level : 'HSK $n';
  }
  if (id.startsWith('jlpt_n')) {
    final n = examLevel ?? int.tryParse(id.replaceAll('jlpt_n', ''));
    return n == null ? level : 'JLPT N$n';
  }
  return level;
}
