import '../models/achievement.dart';
import '../models/analytics.dart';
import '../models/recommendation.dart';

abstract class AnalyticsRepository {
  Future<LearningAnalytics> getAnalytics(String uid);
  Future<List<Achievement>> getAchievements(String uid);
  Future<LeaderboardResult> getLeaderboard({
    required String dimension,
    required String uid,
  });
  Future<List<Recommendation>> getRecommendations(String uid);
}
