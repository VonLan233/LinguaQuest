import '../models/achievement.dart';
import '../models/analytics.dart';

abstract class AnalyticsRepository {
  Future<LearningAnalytics> getAnalytics(String uid);
  Future<List<Achievement>> getAchievements(String uid);
  Future<LeaderboardResult> getLeaderboard({
    required String dimension,
    required String uid,
  });
}
