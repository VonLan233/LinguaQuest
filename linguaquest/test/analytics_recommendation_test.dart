import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/achievement.dart';
import 'package:linguaquest/data/models/analytics.dart';
import 'package:linguaquest/data/models/recommendation.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  group('MockAnalyticsRepository', () {
    final repo = MockAnalyticsRepository();

    test('getAnalytics returns mock with all fields populated', () async {
      final analytics = await repo.getAnalytics('test-uid');
      // D-12: demo streak stays below the streak_3 threshold (see mock()).
      expect(analytics.streakDays, equals(2));
      expect(analytics.masteredWords, equals(34));
      expect(analytics.sevenDayXp, hasLength(7));
      expect(analytics.weakestExerciseType, isNotEmpty);
    });

    test('getAchievements returns 12 achievements', () async {
      final achievements = await repo.getAchievements('test-uid');
      expect(achievements, hasLength(12));
    });

    test('getAchievements does NOT unlock streak_3 in the demo persona (D-12)',
        () async {
      // Regression: the offline/demo seed must not pre-unlock "3-Day Streak"
      // before the user has actually studied 3 days in a row.
      final achievements = await repo.getAchievements('test-uid');
      expect(
        achievements.firstWhere((a) => a.id == 'streak_3').unlocked,
        isFalse,
      );
    });

    test('getLeaderboard global returns entries with current user', () async {
      final result = await repo.getLeaderboard(
        dimension: 'global',
        uid: 'test-uid',
      );
      expect(result.dimension, equals('global'));
      expect(result.entries, isNotEmpty);
      expect(result.entries.any((e) => e.isCurrentUser), isTrue);
      expect(result.currentUserRank, greaterThan(0));
    });

    test('getLeaderboard friends returns different entries', () async {
      final global = await repo.getLeaderboard(
        dimension: 'global',
        uid: 'test-uid',
      );
      final friends = await repo.getLeaderboard(
        dimension: 'friends',
        uid: 'test-uid',
      );
      expect(friends.dimension, equals('friends'));
      expect(friends.entries.length, lessThan(global.entries.length));
    });
  });

  group('LearningAnalytics', () {
    test('fromJson/toJson round-trip', () {
      final original = LearningAnalytics.mock();
      final json = original.toJson();
      final restored = LearningAnalytics.fromJson(json);
      expect(restored.streakDays, equals(original.streakDays));
      expect(restored.masteredWords, equals(original.masteredWords));
      expect(restored.sevenDayXp, equals(original.sevenDayXp));
      expect(restored.trainingRank, equals(original.trainingRank));
    });
  });

  group('Recommendation', () {
    test('fromJson/toJson round-trip', () {
      const original = Recommendation(
        targetWordIds: ['w1', 'w2', 'w3'],
        exerciseType: 'listeningWordChoice',
        reason: 'Your listening recognition for these words is weak',
        priority: 1,
        estimatedMinutes: 3,
      );
      final json = original.toJson();
      final restored = Recommendation.fromJson(json);
      expect(restored.targetWordIds, equals(original.targetWordIds));
      expect(restored.exerciseType, equals(original.exerciseType));
      expect(restored.reason, equals(original.reason));
      expect(restored.priority, equals(original.priority));
      expect(restored.estimatedMinutes, equals(original.estimatedMinutes));
    });

    test('priority 1 is higher than priority 2', () {
      const high = Recommendation(
        targetWordIds: ['w1'],
        exerciseType: 'listeningWordChoice',
        reason: 'Listening weak',
        priority: 1,
        estimatedMinutes: 1,
      );
      const medium = Recommendation(
        targetWordIds: ['w2'],
        exerciseType: 'sentenceCloze',
        reason: 'Context weak',
        priority: 2,
        estimatedMinutes: 1,
      );
      expect(high.priority, lessThan(medium.priority));
    });
  });

  group('MockAnalyticsRepository.getRecommendations', () {
    final repo = MockAnalyticsRepository();

    test('returns non-empty list of recommendations', () async {
      final recs = await repo.getRecommendations('test-uid');
      expect(recs, isNotEmpty);
    });

    test('each recommendation has non-empty exerciseType and reason', () async {
      final recs = await repo.getRecommendations('test-uid');
      for (final rec in recs) {
        expect(rec.exerciseType, isNotEmpty);
        expect(rec.reason, isNotEmpty);
        expect(rec.targetWordIds, isNotEmpty);
        expect(rec.priority, greaterThan(0));
        expect(rec.estimatedMinutes, greaterThan(0));
      }
    });

    test('recommendations are ordered by ascending priority', () async {
      final recs = await repo.getRecommendations('test-uid');
      for (var i = 0; i < recs.length - 1; i++) {
        expect(recs[i].priority, lessThanOrEqualTo(recs[i + 1].priority));
      }
    });
  });

  group('Achievement', () {
    test('fromJson/toJson round-trip', () {
      const original = Achievement(
        id: 'test_id',
        title: 'Test Achievement',
        description: 'Test description',
        iconKey: 'star',
        unlocked: true,
        unlockedAt: null,
      );
      final json = original.toJson();
      final restored = Achievement.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.unlocked, equals(original.unlocked));
    });

    test('unlocked achievement has non-null unlockedAt', () {
      final achievements = AchievementEvaluator.evaluate(
        streakDays: 10,
        masteredWords: 100,
        totalStudyDays: 5,
        trainingXp: 2000,
        hasPerfectQuiz: true,
        hasListening: true,
        hasMapLanguage: true,
        hasJapaneseStudy: true,
        hasReadingComprehension: true,
      );
      for (final a in achievements) {
        expect(a.unlocked, isTrue);
        expect(a.unlockedAt, isNotNull);
      }
    });
  });
}
