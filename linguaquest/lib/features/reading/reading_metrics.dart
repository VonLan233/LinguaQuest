import '../../data/repositories/article_repository.dart';

/// Reading metrics aggregated client-side from saved [ReadingResult]s (P3e).
///
/// Server stores results only when the Api routes exist; the analytics screen
/// computes these from the locally-saved results so the section works offline.
class ReadingMetrics {
  const ReadingMetrics({
    required this.articlesRead,
    required this.accuracyPct,
    required this.themeDistribution,
  });

  /// Distinct completed articles (one per articleId).
  final int articlesRead;

  /// Comprehension accuracy 0–100 over all results' correct/total.
  final int accuracyPct;

  /// Articles read per theme (theme key → distinct-article count).
  final Map<String, int> themeDistribution;

  bool get isEmpty => articlesRead == 0;

  static const empty = ReadingMetrics(
    articlesRead: 0,
    accuracyPct: 0,
    themeDistribution: {},
  );

  /// Aggregates [results]. Accuracy sums correct/total across every result row;
  /// articlesRead + themeDistribution count distinct articleIds (a re-read of the
  /// same article counts once, by its latest theme).
  factory ReadingMetrics.fromResults(List<ReadingResult> results) {
    if (results.isEmpty) return empty;
    var totalQ = 0;
    var totalCorrect = 0;
    final themeByArticle = <String, String>{};
    for (final r in results) {
      totalQ += r.totalQuestions;
      totalCorrect += r.correctAnswers;
      themeByArticle[r.articleId] = r.theme;
    }
    final themeCounts = <String, int>{};
    for (final theme in themeByArticle.values) {
      if (theme.isEmpty) continue;
      themeCounts[theme] = (themeCounts[theme] ?? 0) + 1;
    }
    final accuracy =
        totalQ == 0 ? 0 : (totalCorrect / totalQ * 100).round();
    return ReadingMetrics(
      articlesRead: themeByArticle.length,
      accuracyPct: accuracy,
      themeDistribution: themeCounts,
    );
  }
}
