import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/custom_word.dart';
import '../models/lesson.dart';
import '../models/lottery.dart';
import '../models/review_event.dart';
import '../models/study_session.dart';
import '../models/user_profile.dart';
import '../remote/api_client.dart';
import '../seed/seed_lessons.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'lottery_repository.dart';
import 'notification_repository.dart';
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
  Future<List<Lesson>> listLessons() async => seedLessons();

  @override
  Future<void> recordStudySession(StudySession session) async {
    await _client.dio.post<void>('/study-sessions', data: session.toJson());
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

String _localDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
