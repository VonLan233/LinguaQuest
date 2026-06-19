import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'profile_repository.dart';

import '../models/app_notification.dart';
import '../models/custom_word.dart';
import '../models/daily_reward_task.dart';
import '../models/exercise_record.dart';
import '../models/lesson.dart';
import '../models/lottery.dart';
import '../models/point_grant_result.dart';
import '../models/review_event.dart';
import '../models/study_session.dart';
import '../models/study_plan.dart';
import '../models/user_word.dart';
import '../models/user_profile.dart';
import '../lesson_factory.dart';
import '../remote/api_client.dart';
import '../wordbook_asset_loader.dart';
import 'ai_repository.dart';
import 'analytics_repository.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'lottery_repository.dart';
import 'notification_repository.dart';
import 'reward_repository.dart';
import 'reward_task_repository.dart';
import 'review_repository.dart';
import 'study_plan_repository.dart';
import 'user_word_repository.dart';
import '../models/achievement.dart';
import '../models/ai_feature.dart';
import '../models/analytics.dart';
import '../models/forum.dart';
import '../models/recommendation.dart';
import 'forum_repository.dart';

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
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {'name': name, 'email': email, 'password': password},
    );
    final data = response.data!;
    if (data['status'] == 'verification_required') {
      return AuthVerificationRequired(data['email'] as String? ?? email);
    }
    return AuthSuccess(await _saveAuthResponse(data));
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'email': email, 'password': password},
      );
      return _saveAuthResponse(response.data!);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (error.response?.statusCode == 403 &&
          data is Map &&
          data['error'] == 'email_not_verified') {
        throw EmailNotVerifiedException(data['email'] as String? ?? email);
      }
      rethrow;
    }
  }

  @override
  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  }) async {
    try {
      final response = await _client.dio.post<Map<String, dynamic>>(
        '/auth/verify',
        data: {'email': email, 'code': code},
      );
      return _saveAuthResponse(response.data!);
    } on DioException catch (error) {
      final data = error.response?.data;
      if (data is Map && data['error'] is String) {
        throw EmailVerificationException(data['error'] as String);
      }
      rethrow;
    }
  }

  @override
  Future<void> resendCode(String email) async {
    await _client.dio.post<Map<String, dynamic>>(
      '/auth/resend',
      data: {'email': email},
    );
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
  ApiLearningRepository(this._client, {WordBookAssetLoader? fallbackLoader})
    : _fallbackLoader = fallbackLoader ?? WordBookAssetLoader();

  final ApiClient _client;
  final WordBookAssetLoader _fallbackLoader;
  List<WordBook>? _cache;

  @override
  Future<List<WordBook>> listWordBooks() async {
    final cached = _cache;
    if (cached != null) return cached;
    try {
      final response = await _client.dio.get<List<dynamic>>('/wordbooks');
      final books = (response.data ?? const <dynamic>[]).whereType<Map>().map((
        item,
      ) {
        return WordBook.fromJson(Map<String, dynamic>.from(item));
      }).toList();
      _cache = List.unmodifiable(books);
      return _cache!;
    } catch (_) {
      return _fallbackLoader.loadWordBooks();
    }
  }

  @override
  Future<List<Lesson>> listLessons() async {
    final books = await listWordBooks();
    if (books.isEmpty) return const [];
    return listLessonsForWordBook(books.first.id);
  }

  @override
  Future<List<Lesson>> listLessonsForWordBook(String wordBookId) async {
    final books = await listWordBooks();
    if (books.isEmpty) return const [];
    final book = _bookById(books, wordBookId) ?? books.first;
    return lessonsFromWordBook(book);
  }

  @override
  Future<LearningProgress?> loadLearningProgress(DateTime now) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/learning-progress',
      queryParameters: {
        'localDate': _localDateKey(now),
        'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      },
    );
    final data = response.data;
    if (data == null) return null;
    return LearningProgress.fromJson(data);
  }

  @override
  Future<void> recordStudySession(StudySession session) async {
    await _client.dio.post<void>('/study-sessions', data: session.toJson());
  }

  @override
  Future<void> recordExerciseRecords(List<ExerciseRecord> records) async {
    if (records.isEmpty) return;
    await _client.dio.post<void>(
      '/exercise-records',
      data: {'records': records.map((record) => record.toJson()).toList()},
    );
  }

  @override
  Future<RewardClaimResult?> claimReward({
    required String id,
    required int points,
    required DateTime now,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/reward-claims',
      data: {
        'id': id,
        'points': points,
        'localDate': _localDateKey(now),
        'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      },
    );
    final data = response.data;
    if (data == null) return null;
    return RewardClaimResult.fromJson(data);
  }

  WordBook? _bookById(List<WordBook> books, String id) {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }
}

class ApiUserWordRepository implements UserWordRepository {
  ApiUserWordRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<UserWord>> list(String uid) async {
    final response = await _client.dio.get<List<dynamic>>('/user-words');
    return response.data!
        .cast<Map<String, dynamic>>()
        .map(UserWord.fromJson)
        .toList();
  }

  @override
  Future<UserWord> upsert(UserWord word) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/user-words',
      data: word.toJson(),
    );
    return UserWord.fromJson(response.data!['word'] as Map<String, dynamic>);
  }

  @override
  Future<List<UserWord>> upsertAll(List<UserWord> words) async {
    if (words.isEmpty) return [];
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/user-words/batch',
      data: {
        'words': [for (final word in words) word.toJson()],
      },
    );
    return (response.data!['words'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(UserWord.fromJson)
        .toList();
  }
}

class ApiStudyPlanRepository implements StudyPlanRepository {
  ApiStudyPlanRepository(this._client);

  final ApiClient _client;

  @override
  Future<StudyPlan?> load(String uid) async {
    final response = await _client.dio.get<Map<String, dynamic>>('/study-plan');
    final plan = response.data?['studyPlan'];
    if (plan is! Map<String, dynamic>) return null;
    return StudyPlan.fromJson(plan);
  }

  @override
  Future<StudyPlan> save(StudyPlan plan) async {
    final response = await _client.dio.put<Map<String, dynamic>>(
      '/study-plan',
      data: plan.toJson(),
    );
    return StudyPlan.fromJson(
      response.data!['studyPlan'] as Map<String, dynamic>,
    );
  }

  @override
  Future<StudyPlan> reset(StudyPlan plan) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/study-plan/reset',
    );
    return StudyPlan.fromJson(
      response.data!['studyPlan'] as Map<String, dynamic>,
    );
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

class ApiNotificationRepository implements NotificationRepository {
  ApiNotificationRepository(this._client);

  final ApiClient _client;

  @override
  Future<void> ensureGenerated(
    String uid,
    List<AppNotification> notifications,
  ) async {}

  @override
  Future<List<AppNotification>> list(
    String uid, {
    bool unreadOnly = false,
    AppNotificationType? type,
  }) async {
    final now = DateTime.now();
    final response = await _client.dio.get<List<dynamic>>(
      '/notifications',
      queryParameters: {
        if (unreadOnly) 'unreadOnly': true,
        if (type != null) 'type': type.name,
        'localDate': _localDateKey(now),
        'timezoneOffsetMinutes': now.timeZoneOffset.inMinutes,
      },
    );
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map(
          (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  @override
  Future<int> markAllRead(String uid) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/notifications/read-all',
    );
    return response.data!['updated'] as int? ?? 0;
  }

  @override
  Future<AppNotification?> markRead(String uid, String id) async {
    final response = await _client.dio.patch<Map<String, dynamic>>(
      '/notifications/$id/read',
    );
    return AppNotification.fromJson(
      response.data!['notification'] as Map<String, dynamic>,
    );
  }
}

class ApiLotteryRepository implements LotteryRepository {
  ApiLotteryRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<LotteryPrize>> prizePool() async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/lottery/prizes',
    );
    final prizes = response.data!['prizes'] as List<dynamic>? ?? const [];
    return prizes
        .whereType<Map>()
        .map((item) => LotteryPrize.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<List<UserAsset>> assets(String uid) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/lottery/assets',
    );
    final assets = response.data!['assets'] as List<dynamic>? ?? const [];
    return assets
        .whereType<Map>()
        .map((item) => UserAsset.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<LotteryDrawResponse> draw({
    required String uid,
    required int currentXp,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/lottery/draw',
    );
    final data = response.data!;
    final rawNotifications =
        data['notifications'] as List<dynamic>? ?? const [];
    return LotteryDrawResponse(
      result: LotteryDrawResult.fromJson(
        Map<String, dynamic>.from(data['result'] as Map),
      ),
      user: data['user'] == null
          ? null
          : UserProfile.fromJson(
              Map<String, dynamic>.from(data['user'] as Map),
            ),
      notifications: rawNotifications
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
    );
  }
}

class ApiRewardTaskRepository implements RewardTaskRepository {
  ApiRewardTaskRepository(this._client);

  final ApiClient _client;

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async {
    final now = DateTime.now();
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/rewards/tasks',
      queryParameters: _dayParameters(now),
    );
    return _snapshotFromJson(response.data!);
  }

  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/rewards/check-in',
      data: _dayParameters(DateTime.now()),
    );
    return _snapshotFromJson(response.data!);
  }

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/rewards/tasks/$taskId/claim',
      data: _dayParameters(DateTime.now()),
    );
    return _snapshotFromJson(response.data!);
  }

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async {
    if (type == RewardEventType.newLearning ||
        type == RewardEventType.reviewDone) {
      return listTasks(uid);
    }
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/reward-events',
      data: {..._dayParameters(DateTime.now()), 'type': type.name},
    );
    return _snapshotFromJson(response.data!);
  }
}

RewardTaskSnapshot _snapshotFromJson(Map<String, dynamic> json) {
  final tasks = (json['tasks'] as List<dynamic>? ?? const <dynamic>[])
      .whereType<Map>()
      .map((item) => DailyRewardTask.fromJson(Map<String, dynamic>.from(item)))
      .toList();
  final userJson = json['user'];
  return RewardTaskSnapshot(
    dateKey: json['dateKey'] as String? ?? _localDateKey(DateTime.now()),
    tasks: tasks,
    claimed: json['claimed'] as bool?,
    alreadyClaimed: json['alreadyClaimed'] == true,
    user: userJson is Map
        ? UserProfile.fromJson(Map<String, dynamic>.from(userJson))
        : null,
  );
}

Map<String, dynamic> _dayParameters(DateTime date) {
  return {
    'localDate': _localDateKey(date),
    'timezoneOffsetMinutes': date.timeZoneOffset.inMinutes,
  };
}

class ApiRewardRepository implements RewardRepository {
  ApiRewardRepository(this._client);

  final ApiClient _client;

  @override
  Future<PointGrantResult> grantPoints({
    required String uid,
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/rewards/points',
      data: {
        'sourceType': sourceType,
        'sourceId': sourceId,
        'points': points,
        'description': description,
      },
    );
    final data = response.data!;
    return PointGrantResult(
      pointsAwarded: data['pointsAwarded'] as int? ?? 0,
      alreadyGranted: data['alreadyGranted'] as bool? ?? false,
      user: data['user'] != null
          ? UserProfile.fromJson(data['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class ApiAiRepository implements AiRepository {
  ApiAiRepository(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> chat({
    required String prompt,
    String? targetWord,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/chat',
      data: {
        'prompt': prompt,
        'targetWord': targetWord,
      },
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/sentence-analysis',
      data: {'prompt': prompt},
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    String? targetWord,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/cloze',
      data: {
        'prompt': prompt,
        'targetWord': targetWord,
      },
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  @override
  Future<List<AiHistoryEntry>> listHistory() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/ai/history');
    final items = response.data!['history'] as List<dynamic>? ?? const [];
    return items
        .whereType<Map>()
        .map((item) => AiHistoryEntry.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<void> deleteHistory(String id) async {
    await _client.dio.delete<void>('/ai/history/$id');
  }

  @override
  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    String? examType,
    double? targetScore,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/writing-review',
      data: {
        'prompt': essay,
        'examType': ?examType,
        'targetScore': ?targetScore,
      },
    );
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }
}

class ApiForumRepository implements ForumRepository {
  ApiForumRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<ForumPost>> listPosts() async {
    final response = await _client.dio.get<Map<String, dynamic>>('/forum/posts');
    final posts = response.data!['posts'] as List<dynamic>? ?? const [];
    return posts
        .whereType<Map>()
        .map((item) => ForumPost.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<ForumPost> getPost(String id) async {
    final response =
        await _client.dio.get<Map<String, dynamic>>('/forum/posts/$id');
    return ForumPost.fromJson(
      response.data!['post'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ForumPost> createPost({
    required String title,
    required String body,
    required String tag,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/forum/posts',
      data: {'title': title, 'body': body, 'tag': tag},
    );
    return ForumPost.fromJson(
      response.data!['post'] as Map<String, dynamic>,
    );
  }

  @override
  Future<ForumComment> createComment({
    required String postId,
    required String body,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/forum/posts/$postId/comments',
      data: {'body': body},
    );
    return ForumComment.fromJson(
      response.data!['comment'] as Map<String, dynamic>,
    );
  }

  @override
  Future<List<ForumComment>> listComments(String postId) async {
    final response =
        await _client.dio.get<Map<String, dynamic>>('/forum/posts/$postId');
    final comments =
        response.data!['comments'] as List<dynamic>? ?? const [];
    return comments
        .whereType<Map>()
        .map((item) => ForumComment.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  @override
  Future<bool> toggleLike(String postId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/forum/posts/$postId/like',
    );
    return response.data!['liked'] as bool? ?? false;
  }

  @override
  Future<bool> toggleFavorite(String postId) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/forum/posts/$postId/favorite',
    );
    return response.data!['favorited'] as bool? ?? false;
  }
}

class ApiAnalyticsRepository implements AnalyticsRepository {
  ApiAnalyticsRepository(this._client);

  final ApiClient _client;

  @override
  Future<LearningAnalytics> getAnalytics(String uid) async {
    final response = await _client.dio.get<Map<String, dynamic>>('/analytics');
    return LearningAnalytics.fromJson(response.data!);
  }

  @override
  Future<List<Achievement>> getAchievements(String uid) async {
    final response = await _client.dio.get<List<dynamic>>('/achievements');
    return (response.data ?? const <dynamic>[])
        .whereType<Map<String, dynamic>>()
        .map(Achievement.fromJson)
        .toList();
  }

  @override
  Future<LeaderboardResult> getLeaderboard({
    required String dimension,
    required String uid,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/leaderboard',
      queryParameters: {'dimension': dimension},
    );
    return LeaderboardResult.fromJson(response.data!);
  }

  @override
  Future<List<Recommendation>> getRecommendations(String uid) async {
    final response = await _client.dio.get<List<dynamic>>('/recommendations');
    return (response.data ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => Recommendation.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

String _localDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class ApiProfileRepository implements ProfileRepository {
  ApiProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<Map<String, dynamic>> getPublicProfile(String userId) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/users/$userId/profile',
    );
    return response.data ?? {};
  }
}
