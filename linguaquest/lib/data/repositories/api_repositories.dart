import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/custom_word.dart';
import '../models/lesson.dart';
import '../models/review_event.dart';
import '../models/study_session.dart';
import '../models/user_profile.dart';
import '../models/word_book.dart';
import '../models/word_entry.dart';
import '../remote/api_client.dart';
import '../lesson_factory.dart';
import '../seed/seed_lessons.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'notification_repository.dart';
import 'review_repository.dart';
import 'wordbook_repository.dart';

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
  ApiLearningRepository(this._client, {WordBookRepository? wordBookRepository})
      : _wordBookRepository = wordBookRepository;

  final ApiClient _client;
  final WordBookRepository? _wordBookRepository;

  @override
  Future<List<Lesson>> listLessons({String? wordBookId}) async {
    if (wordBookId == null || _wordBookRepository == null) {
      return seedLessons();
    }
    try {
      final book = await _wordBookRepository.getWordBook(wordBookId);
      if (book == null) return seedLessons();
      final entries = await _wordBookRepository.getWords(
        wordBookId,
        limit: 60,
        offset: 0,
      );
      if (entries.isEmpty) return seedLessons();
      return LessonFactory().buildLessons(
        wordBookId: wordBookId,
        wordBookTitle: book.title,
        entries: entries,
      );
    } catch (_) {
      return seedLessons();
    }
  }

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

class ApiWordBookRepository implements WordBookRepository {
  ApiWordBookRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<WordBook>> listWordBooks() async {
    final response = await _client.dio.get<List<dynamic>>('/word-books');
    return (response.data ?? const <dynamic>[])
        .cast<Map<String, dynamic>>()
        .map(WordBook.fromJson)
        .toList();
  }

  @override
  Future<WordBook?> getWordBook(String id) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/word-books/$id',
      );
      return WordBook.fromJson(response.data!['wordbook'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WordEntry>> getWords(String bookId, {int? limit, int? offset}) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      '/word-books/$bookId',
      queryParameters: {
        'limit': limit,
        'offset': offset,
      },
    );
    return (response.data!['words'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(WordEntry.fromJson)
        .toList();
  }

  @override
  Future<WordEntry?> getWord(String wordId) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/words/$wordId',
      );
      return WordEntry.fromJson(response.data!['word'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WordEntry>> searchWords(String query, {int limit = 20}) async {
    try {
      final response = await _client.dio.get<Map<String, dynamic>>(
        '/words/search',
        queryParameters: {'q': query, 'limit': limit},
      );
      return (response.data!['results'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WordEntry.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }
}

String _localDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
