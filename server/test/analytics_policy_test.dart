import 'package:test/test.dart';

import '../lib/src/achievement_policy.dart';
import '../lib/src/analytics_policy.dart';

void main() {
  group('LearningAnalytics', () {
    test('mock() returns all 16 fields populated', () {
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
    });

    test('toJson/fromJson round-trip', () {
      final original = LearningAnalytics.mock();
      final json = original.toJson();
      final restored = LearningAnalytics.fromJson(json);
      expect(restored.streakDays, equals(original.streakDays));
      expect(restored.masteredWords, equals(original.masteredWords));
      expect(restored.sevenDayXp, equals(original.sevenDayXp));
      expect(restored.trainingRank, equals(original.trainingRank));
    });
  });

  group('AchievementPolicy', () {
    test('evaluate returns 6 achievements', () {
      final achievements = AchievementPolicy.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      expect(achievements, hasLength(6));
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
