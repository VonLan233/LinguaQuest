import 'package:shared_preferences/shared_preferences.dart';

import '../models/activity_summary.dart';
import '../models/achievement.dart';
import '../models/ai_conversation.dart';
import '../models/app_notification.dart';
import '../models/analytics_summary.dart';
import '../models/class_group.dart';
import '../models/custom_word.dart';
import '../models/forum_post.dart';
import '../models/leaderboard_entry.dart';
import '../models/lesson.dart';
import '../models/lottery_draw.dart';
import '../models/review_event.dart';
import '../models/reward_task.dart';
import '../models/study_session.dart';
import '../models/target_word_progress.dart';
import '../models/user_profile.dart';
import '../remote/api_client.dart';
import '../lesson_factory.dart';
import 'app_services_repository.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'review_repository.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository(this._client);

  static const _tokenKey = 'linguaquest.api.token';
  final ApiClient _client;
  UserProfile? _profile;

  @override
  Future<UserProfile?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    if (token == null) return null;
    _client.setToken(token);
    final response = await _client.dio.get<Map<String, dynamic>>('/me');
    _profile = UserProfile.fromJson(
      response.data!['user'] as Map<String, dynamic>,
    );
    return _profile;
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    return _saveAuthResponse(response.data!);
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'email': email, 'password': password},
    );
    return _saveAuthResponse(response.data!);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/me',
      data: {
        'name': profile.name,
        'targetExam': profile.targetExam,
        'level': profile.level,
        'dailyGoal': profile.dailyGoal,
        'xp': profile.xp,
        'streak': profile.streak,
        'lastStudyDate': profile.lastStudyDate?.toIso8601String(),
      },
    );
    _profile = UserProfile.fromJson(
      response.data!['user'] as Map<String, dynamic>,
    );
    return _profile!;
  }

  @override
  Future<void> logout() async {
    _profile = null;
    _client.setToken(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<UserProfile> _saveAuthResponse(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    _client.setToken(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    _profile = UserProfile.fromJson(data['user'] as Map<String, dynamic>);
    return _profile!;
  }
}

class ApiCustomWordRepository implements CustomWordRepository {
  ApiCustomWordRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<CustomWord>> list(String uid) async {
    final response = await _client.dio.get<List<dynamic>>('/custom-words');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(CustomWord.fromJson)
        .toList();
  }

  @override
  Future<CustomWord> create(CustomWord word) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/custom-words',
      data: word.toJson(),
    );
    return CustomWord.fromJson(response.data!['word'] as Map<String, dynamic>);
  }

  @override
  Future<void> delete(String uid, String id) async {
    await _client.dio.delete<void>('/custom-words/$id');
  }

  @override
  Future<CustomWord> update(CustomWord word) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/custom-words/${word.id}',
      data: word.toJson(),
    );
    return CustomWord.fromJson(response.data!['word'] as Map<String, dynamic>);
  }
}

class ApiLearningRepository implements LearningRepository {
  ApiLearningRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<WordBook>> listWordBooks() async {
    final response = await _client.dio.get<List<dynamic>>('/word-books');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(WordBook.fromJson)
        .toList(growable: false);
  }

  @override
  Future<List<Lesson>> listLessons() async {
    final books = await listWordBooks();
    if (books.isEmpty) return const [];
    return lessonsFromWordBook(books.first);
  }

  @override
  Future<Map<String, dynamic>?> loadStudyPlan(String uid) async {
    final response = await _client.dio.get<Map<String, dynamic>>('/study-plan');
    return response.data?['plan'] as Map<String, dynamic>?;
  }

  @override
  Future<Map<String, dynamic>?> saveStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/study-plan',
      data: data,
    );
    return response.data?['plan'] as Map<String, dynamic>?;
  }

  @override
  Future<void> clearStudyPlan(String uid) async {
    await _client.dio.delete<void>('/study-plan');
  }

  @override
  Future<List<TargetWordProgress>> listTargetWordProgress(String uid) async {
    final response = await _client.dio.get<List<dynamic>>('/user-words');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(TargetWordProgress.fromJson)
        .toList(growable: false);
  }

  @override
  Future<void> upsertTargetWordProgress(
    String uid,
    TargetWordProgress progress,
  ) async {
    await _client.dio.put<void>(
      '/user-words/${progress.wordId}',
      data: progress.toJson(),
    );
  }

  @override
  Future<ActivitySummary> loadActivitySummary(String uid) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/activity/summary',
    );
    return ActivitySummary.fromJson(response.data!);
  }

  @override
  Future<UserProfile> recordStudySession(StudySession session) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/study-sessions',
      data: session.toJson(),
    );
    return UserProfile.fromJson(response.data!['user'] as Map<String, dynamic>);
  }
}

class ApiReviewRepository implements ReviewRepository {
  ApiReviewRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> recordReviewEvent(ReviewEvent event) async {
    await _client.dio.post<void>('/review-events', data: event.toJson());
  }
}

class ApiAppServicesRepository implements AppServicesRepository {
  ApiAppServicesRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<RewardTask>> listRewardTasks() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/rewards/tasks',
    );
    return _rewardTasksFromResponse(response.data!);
  }

  @override
  Future<RewardClaimResult> claimReward(String taskId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/rewards/claim',
      data: {'taskId': taskId},
    );
    return RewardClaimResult(
      user: UserProfile.fromJson(
        response.data!['user'] as Map<String, dynamic>,
      ),
      tasks: _rewardTasksFromResponse(response.data!),
    );
  }

  @override
  Future<List<LeaderboardEntry>> listLeaderboard() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/leaderboard',
    );
    return (response.data!['leaderboard'] as List<dynamic>? ?? const [])
        .map((item) => LeaderboardEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AnalyticsSummary> loadAnalyticsSummary() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/analytics/summary',
    );
    return AnalyticsSummary.fromJson(
      response.data!['summary'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<Achievement>> listAchievements() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/achievements',
    );
    return (response.data!['achievements'] as List<dynamic>? ?? const [])
        .map((item) => Achievement.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<ClassGroup>> listClasses() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/classes');
    return (response.data!['classes'] as List<dynamic>? ?? const [])
        .map((item) => ClassGroup.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ClassGroup> joinClass(String code) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/classes/join',
      data: {'code': code},
    );
    return ClassGroup.fromJson(response.data!['class'] as Map<String, dynamic>);
  }

  @override
  Future<ClassProgressSummary> loadClassProgress({String? classId}) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/classes/progress',
      queryParameters: {'classId': ?classId},
    );
    return ClassProgressSummary.fromJson(
      response.data!['progress'] as Map<String, dynamic>,
    );
  }

  @override
  Future<LotteryDrawResult> drawLottery() async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/rewards/lottery',
    );
    return LotteryDrawResult(
      draw: LotteryDraw.fromJson(
        response.data!['draw'] as Map<String, dynamic>,
      ),
      user: UserProfile.fromJson(
        response.data!['user'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<List<ForumPost>> listForumPosts() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/forum/posts',
    );
    return (response.data!['posts'] as List<dynamic>? ?? const [])
        .map((item) => ForumPost.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ForumPostDetail> loadForumPost(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/forum/posts/$id',
    );
    return ForumPostDetail.fromJson(response.data!);
  }

  @override
  Future<ForumPost> createForumPost({
    required String title,
    required String content,
    required List<String> tags,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/forum/posts',
      data: {'title': title, 'content': content, 'tags': tags},
    );
    return ForumPost.fromJson(response.data!['post'] as Map<String, dynamic>);
  }

  @override
  Future<ForumComment> addForumComment({
    required String postId,
    required String content,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/forum/posts/$postId/comments',
      data: {'content': content},
    );
    return ForumComment.fromJson(
      response.data!['comment'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ForumPost> likeForumPost(String id) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/forum/posts/$id/like',
    );
    return ForumPost.fromJson(response.data!['post'] as Map<String, dynamic>);
  }

  @override
  Future<List<AppNotification>> listNotifications() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/notifications',
    );
    return (response.data!['notifications'] as List<dynamic>? ?? const [])
        .map((item) => AppNotification.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markNotificationRead(String id) async {
    await _client.dio.patch<void>('/notifications/$id/read');
  }

  @override
  Future<List<AiConversation>> listAiConversations() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/ai/conversations',
    );
    return (response.data!['conversations'] as List<dynamic>? ?? const [])
        .map((item) => AiConversation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<AiConversationDetail> loadAiConversation(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/ai/conversations/$id',
    );
    return AiConversationDetail.fromJson(response.data!);
  }

  @override
  Future<void> deleteAiConversation(String id) async {
    await _client.dio.delete<void>('/ai/conversations/$id');
  }

  @override
  Future<AiCompletionResult> completeAi({
    required String feature,
    required String prompt,
    String? conversationId,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/complete',
      data: {
        'feature': feature,
        'prompt': prompt,
        'conversationId': ?conversationId,
      },
    );
    return AiCompletionResult.fromJson(
      response.data!['result'] as Map<String, dynamic>,
    );
  }

  List<RewardTask> _rewardTasksFromResponse(Map<String, dynamic> data) {
    return (data['tasks'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(RewardTask.fromJson)
        .toList();
  }
}
