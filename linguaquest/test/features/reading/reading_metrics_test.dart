import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/analytics.dart';
import 'package:linguaquest/data/repositories/article_repository.dart';
import 'package:linguaquest/features/reading/reading_metrics.dart';

ReadingResult _result(
  String articleId, {
  required int total,
  required int correct,
  String theme = 'life',
}) {
  return ReadingResult(
    uid: 'u',
    scope: 'zh::hsk1',
    articleId: articleId,
    totalQuestions: total,
    correctAnswers: correct,
    theme: theme,
    createdAt: DateTime(2026, 6, 27),
  );
}

void main() {
  test('empty results → empty metrics', () {
    final m = ReadingMetrics.fromResults(const []);
    expect(m.isEmpty, isTrue);
    expect(m.articlesRead, 0);
    expect(m.accuracyPct, 0);
    expect(m.themeDistribution, isEmpty);
  });

  test('aggregates accuracy + distinct articles + theme distribution', () {
    final m = ReadingMetrics.fromResults([
      _result('a1', total: 4, correct: 3, theme: 'campus'),
      _result('a2', total: 5, correct: 5, theme: 'life'),
      _result('a3', total: 2, correct: 1, theme: 'campus'),
    ]);
    // (3 + 5 + 1) / (4 + 5 + 2) = 9/11 = 81.8 → 82
    expect(m.accuracyPct, 82);
    expect(m.articlesRead, 3);
    expect(m.themeDistribution, {'campus': 2, 'life': 1});
  });

  test('re-read of same article counts once', () {
    final m = ReadingMetrics.fromResults([
      _result('a1', total: 4, correct: 2, theme: 'travel'),
      _result('a1', total: 4, correct: 4, theme: 'travel'),
    ]);
    expect(m.articlesRead, 1);
    expect(m.themeDistribution, {'travel': 1});
    // accuracy still spans both rows: 6/8 = 75
    expect(m.accuracyPct, 75);
  });

  test('LearningAnalytics round-trips reading metrics', () {
    const a = LearningAnalytics(
      streakDays: 1,
      totalStudyDays: 1,
      learnedWords: 1,
      masteredWords: 1,
      newWordsToday: 1,
      reviewsToday: 1,
      wordbookProgressPct: 1,
      todayMinutes: 1,
      totalMinutes: 1,
      averageAccuracyPct: 1,
      sevenDayXp: [1],
      weakestExerciseType: 'spelling',
      mostMissedWordIds: [],
      achievementCount: 0,
      trainingXp: 0,
      trainingRank: -1,
      articlesRead: 4,
      readingAccuracyPct: 82,
      themeDistribution: {'campus': 2},
    );
    final back = LearningAnalytics.fromJson(a.toJson());
    expect(back.articlesRead, 4);
    expect(back.readingAccuracyPct, 82);
    expect(back.themeDistribution, {'campus': 2});
  });

  test('reading fields default to 0/{} for legacy payloads', () {
    final back = LearningAnalytics.fromJson(const {
      'streakDays': 1,
      'sevenDayXp': <int>[],
      'mostMissedWordIds': <String>[],
    });
    expect(back.articlesRead, 0);
    expect(back.readingAccuracyPct, 0);
    expect(back.themeDistribution, isEmpty);
  });
}
