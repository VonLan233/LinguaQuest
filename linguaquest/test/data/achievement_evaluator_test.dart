import 'package:flutter_test/flutter_test.dart';

import 'package:linguaquest/data/models/achievement.dart';

void main() {
  group('AchievementEvaluator', () {
    test('returns 10 achievements', () {
      final achievements = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      expect(achievements.length, 12);
    });

    test('all achievement ids are unique', () {
      final achievements = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      final ids = achievements.map((a) => a.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('learn_100_words unlocks at masteredWords >= 100, not at 99', () {
      final notYet = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 99,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      final unlocked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 100,
        totalStudyDays: 0,
        trainingXp: 0,
      );
      expect(
        notYet.firstWhere((a) => a.id == 'learn_100_words').unlocked,
        isFalse,
      );
      expect(
        unlocked.firstWhere((a) => a.id == 'learn_100_words').unlocked,
        isTrue,
      );
    });

    test('quiz_perfect unlocks iff hasPerfectQuiz is true', () {
      final locked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasPerfectQuiz: false,
      );
      final unlocked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasPerfectQuiz: true,
      );
      expect(
        locked.firstWhere((a) => a.id == 'quiz_perfect').unlocked,
        isFalse,
      );
      expect(
        unlocked.firstWhere((a) => a.id == 'quiz_perfect').unlocked,
        isTrue,
      );
    });

    test('first_listening unlocks iff hasListening is true', () {
      final locked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasListening: false,
      );
      final unlocked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasListening: true,
      );
      expect(
        locked.firstWhere((a) => a.id == 'first_listening').unlocked,
        isFalse,
      );
      expect(
        unlocked.firstWhere((a) => a.id == 'first_listening').unlocked,
        isTrue,
      );
    });

    test('first_map_language unlocks iff hasMapLanguage is true', () {
      final locked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasMapLanguage: false,
      );
      final unlocked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasMapLanguage: true,
      );
      expect(
        locked.firstWhere((a) => a.id == 'first_map_language').unlocked,
        isFalse,
      );
      expect(
        unlocked.firstWhere((a) => a.id == 'first_map_language').unlocked,
        isTrue,
      );
    });

    test('first_japanese_lesson unlocks iff hasJapaneseStudy is true', () {
      final locked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasJapaneseStudy: false,
      );
      final unlocked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasJapaneseStudy: true,
      );
      expect(
        locked.firstWhere((a) => a.id == 'first_japanese_lesson').unlocked,
        isFalse,
      );
      expect(
        unlocked.firstWhere((a) => a.id == 'first_japanese_lesson').unlocked,
        isTrue,
      );
    });

    test('first_reading unlocks iff hasReadingComprehension is true', () {
      final locked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasReadingComprehension: false,
      );
      final unlocked = AchievementEvaluator.evaluate(
        streakDays: 0,
        masteredWords: 0,
        totalStudyDays: 0,
        trainingXp: 0,
        hasReadingComprehension: true,
      );
      expect(
        locked.firstWhere((a) => a.id == 'first_reading').unlocked,
        isFalse,
      );
      expect(
        unlocked.firstWhere((a) => a.id == 'first_reading').unlocked,
        isTrue,
      );
    });

    test('streak_3 unlocks at streakDays >= 3, not at 1 or 2 (D-12)', () {
      bool streak3Unlocked(int streakDays) => AchievementEvaluator.evaluate(
            streakDays: streakDays,
            masteredWords: 0,
            totalStudyDays: 0,
            trainingXp: 0,
          ).firstWhere((a) => a.id == 'streak_3').unlocked;

      expect(streak3Unlocked(1), isFalse);
      expect(streak3Unlocked(2), isFalse);
      expect(streak3Unlocked(3), isTrue);
    });

    test('existing achievements still evaluate correctly', () {
      final achievements = AchievementEvaluator.evaluate(
        streakDays: 7,
        masteredWords: 50,
        totalStudyDays: 1,
        trainingXp: 1000,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'first_lesson').unlocked,
        isTrue,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'streak_3').unlocked,
        isTrue,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'streak_7').unlocked,
        isTrue,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mastered_10').unlocked,
        isTrue,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'mastered_50').unlocked,
        isTrue,
      );
      expect(
        achievements.firstWhere((a) => a.id == 'xp_1000').unlocked,
        isTrue,
      );
    });
  });
}
