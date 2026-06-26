import 'package:test/test.dart';

import '../lib/src/achievement_policy.dart';
import '../lib/src/analytics_policy.dart';

void main() {
  group('LearningAnalytics', () {
    test('mock() returns all 19 fields populated', () {
      final a = LearningAnalytics.mock();
      expect(a.streakDays, equals(5));
      expect(a.totalStudyDays, equals(12));
      expect(a.learnedWords, equals(89));
      expect(a.masteredWords, equals(34));
      expect(a.newWordsToday, equals(8));
      expect(a.reviewsToday, equals(12));
      expect(a.wordbookProgressPct, equals(18));
      expect(a.todayMinutes, equals(15));
      expect(a.totalMinutes, equals(180));
      expect(a.averageAccuracyPct, equals(78));
      expect(a.sevenDayXp, hasLength(7));
      expect(a.weakestExerciseType, isNotEmpty);
      expect(a.mostMissedWordIds, isNotEmpty);
      expect(a.achievementCount, equals(3));
      expect(a.trainingXp, equals(300));
      expect(a.trainingRank, equals(-1));
      // New fields: modalityAccuracy, dailyXp, topErrorTypes
      expect(a.modalityAccuracy, isNotEmpty);
      expect(a.modalityAccuracy['meaning'], equals(84));
      expect(a.modalityAccuracy['listening'], equals(71));
      expect(a.modalityAccuracy['spelling'], equals(63));
      expect(a.modalityAccuracy['context'], equals(77));
      expect(a.dailyXp, hasLength(14));
      expect(a.topErrorTypes, equals(['spelling', 'listening']));
    });

    test('toJson/fromJson round-trip preserves all 19 fields', () {
      final original = LearningAnalytics.mock();
      final json = original.toJson();
      final restored = LearningAnalytics.fromJson(json);
      expect(restored.streakDays, equals(original.streakDays));
      expect(restored.masteredWords, equals(original.masteredWords));
      expect(restored.sevenDayXp, equals(original.sevenDayXp));
      expect(restored.trainingRank, equals(original.trainingRank));
      // New fields round-trip
      expect(restored.modalityAccuracy, equals(original.modalityAccuracy));
      expect(restored.dailyXp, equals(original.dailyXp));
      expect(restored.topErrorTypes, equals(original.topErrorTypes));
    });

    test('fromJson is backward-compatible: missing new fields default to empty', () {
      // Simulate an old JSON payload without the three new fields
      final oldJson = <String, dynamic>{
        'streakDays': 3,
        'totalStudyDays': 5,
        'learnedWords': 10,
        'masteredWords': 2,
        'newWordsToday': 1,
        'reviewsToday': 4,
        'wordbookProgressPct': 5,
        'todayMinutes': 8,
        'totalMinutes': 40,
        'averageAccuracyPct': 70,
        'sevenDayXp': [10, 20, 30, 40, 50, 60, 70],
        'weakestExerciseType': 'spelling',
        'mostMissedWordIds': [],
        'achievementCount': 0,
        'trainingXp': 0,
        'trainingRank': -1,
        // modalityAccuracy, dailyXp, topErrorTypes intentionally absent
      };
      final analytics = LearningAnalytics.fromJson(oldJson);
      expect(analytics.modalityAccuracy, isEmpty);
      expect(analytics.dailyXp, isEmpty);
      expect(analytics.topErrorTypes, isEmpty);
      expect(analytics.streakDays, equals(3));
    });

    test('zero-state LearningAnalytics has no crash on all-zero fields', () {
      const zero = LearningAnalytics(
        streakDays: 0,
        totalStudyDays: 0,
        learnedWords: 0,
        masteredWords: 0,
        newWordsToday: 0,
        reviewsToday: 0,
        wordbookProgressPct: 0,
        todayMinutes: 0,
        totalMinutes: 0,
        averageAccuracyPct: 0,
        sevenDayXp: [],
        weakestExerciseType: '',
        mostMissedWordIds: [],
        achievementCount: 0,
        trainingXp: 0,
        trainingRank: -1,
      );
      final json = zero.toJson();
      final restored = LearningAnalytics.fromJson(json);
      expect(restored.modalityAccuracy, isEmpty);
      expect(restored.dailyXp, isEmpty);
      expect(restored.topErrorTypes, isEmpty);
      expect(restored.averageAccuracyPct, equals(0));
    });
  });

  group('AchievementPolicy', () {
    test('evaluate returns 10 achievements', () {
      final achievements = AchievementPolicy.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      expect(achievements, hasLength(10));
    });

    test('first_lesson unlocks when totalStudyDays >= 1', () {
      final locked = AchievementPolicy.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      final unlocked = AchievementPolicy.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 1,
        trainingXp: 0,
      );
      expect(locked.firstWhere((a) => a.id == 'first_lesson').unlocked, isFalse);
      expect(unlocked.firstWhere((a) => a.id == 'first_lesson').unlocked, isTrue);
    });

    test('streak_7 unlocks when streakDays >= 7', () {
      final locked = AchievementPolicy.evaluate(
        streakDays: 6,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      final unlocked = AchievementPolicy.evaluate(
        streakDays: 7,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      expect(locked.firstWhere((a) => a.id == 'streak_7').unlocked, isFalse);
      expect(unlocked.firstWhere((a) => a.id == 'streak_7').unlocked, isTrue);
    });

    test('mastered_50 stays locked when masteredWords < 50', () {
      final achievements = AchievementPolicy.evaluate(
        streakDays: 0,
        masteredWords: 49,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mastered_50').unlocked,
        isFalse,
      );
    });
  });
}
