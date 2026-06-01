import '../models/app_notification.dart';
import '../models/analytics_summary.dart';
import '../models/achievement.dart';
import '../models/ai_conversation.dart';
import '../models/class_group.dart';
import '../models/forum_post.dart';
import '../models/leaderboard_entry.dart';
import '../models/lottery_draw.dart';
import '../models/reward_task.dart';
import '../models/user_profile.dart';

class RewardClaimResult {
  const RewardClaimResult({required this.user, required this.tasks});

  final UserProfile user;
  final List<RewardTask> tasks;
}

class LotteryDrawResult {
  const LotteryDrawResult({required this.draw, required this.user});

  final LotteryDraw draw;
  final UserProfile user;
}

class AiCompletionResult {
  const AiCompletionResult({
    required this.conversationId,
    required this.feature,
    required this.title,
    required this.response,
    required this.payload,
  });

  final String conversationId;
  final String feature;
  final String title;
  final String response;
  final Map<String, dynamic> payload;

  factory AiCompletionResult.fromJson(Map<String, dynamic> json) {
    return AiCompletionResult(
      conversationId: json['conversationId'] as String? ?? '',
      feature: json['feature'] as String? ?? 'qa',
      title: json['title'] as String? ?? 'AI 学习',
      response: json['response'] as String? ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
    );
  }
}

abstract class AppServicesRepository {
  Future<List<RewardTask>> listRewardTasks();

  Future<RewardClaimResult> claimReward(String taskId);

  Future<List<LeaderboardEntry>> listLeaderboard();

  Future<AnalyticsSummary> loadAnalyticsSummary();

  Future<List<Achievement>> listAchievements();

  Future<List<ClassGroup>> listClasses();

  Future<ClassGroup> joinClass(String code);

  Future<ClassProgressSummary> loadClassProgress({String? classId});

  Future<LotteryDrawResult> drawLottery();

  Future<List<ForumPost>> listForumPosts();

  Future<ForumPostDetail> loadForumPost(String id);

  Future<ForumPost> createForumPost({
    required String title,
    required String content,
    required List<String> tags,
  });

  Future<ForumComment> addForumComment({
    required String postId,
    required String content,
  });

  Future<ForumPost> likeForumPost(String id);

  Future<List<AppNotification>> listNotifications();

  Future<void> markNotificationRead(String id);

  Future<List<AiConversation>> listAiConversations();

  Future<AiConversationDetail> loadAiConversation(String id);

  Future<void> deleteAiConversation(String id);

  Future<AiCompletionResult> completeAi({
    required String feature,
    required String prompt,
    String? conversationId,
  });
}
