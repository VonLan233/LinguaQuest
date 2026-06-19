import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/achievement.dart';
import 'package:linguaquest/data/models/analytics.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  group('MockAnalyticsRepository', () {
    final repo = MockAnalyticsRepository();

    test('getAnalytics returns mock with all fields populated', () async {
      final analytics = await repo.getAnalytics('test-uid');
      expect(analytics.streakDays, equals(5));
      expect(analytics.masteredWords, equals(34));
      expect(analytics.sevenDayXp, hasLength(7));
      expect(analytics.weakestExerciseType, isNotEmpty);
    });

    test('getAchievements returns 6 achievements', () async {
      final achievements = await repo.getAchievements('test-uid');
      expect(achievements, hasLength(6));
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
        masteredWords: 60,
        totalStudyDays: 5,
        trainingXp: 2000,
      );
      for (final a in achievements) {
        expect(a.unlocked, isTrue);
        expect(a.unlockedAt, isNotNull);
      }
    });
  });
}
