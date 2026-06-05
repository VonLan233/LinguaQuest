import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/custom_word.dart';
import '../models/lesson.dart';
import '../models/review_event.dart';
import '../models/study_session.dart';
import '../models/user_profile.dart';
import '../models/word_book.dart';
import '../models/word_entry.dart';
import '../seed/seed_lessons.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'notification_repository.dart';
import 'review_repository.dart';
import 'wordbook_repository.dart';

class MockAuthRepository implements AuthRepository {
  static const _profileKey = 'linguaquest.profile';
  static const _registeredEmailsKey = 'linguaquest.mock.registered_emails';
  UserProfile? _profile;

  @override
  Future<UserProfile?> loadSession() async {
    if (_profile != null) return _profile;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      _profile = UserProfile.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      await prefs.remove(_profileKey);
      return null;
    }
    return _profile;
  }

  @override
  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final registeredEmails =
        prefs.getStringList(_registeredEmailsKey) ?? const <String>[];
    final normalizedRegisteredEmails = registeredEmails
        .map((email) => email.trim().toLowerCase())
        .toSet();
    if (normalizedRegisteredEmails.contains(normalizedEmail)) {
      throw StateError('email already registered');
    }
    final now = DateTime.now();
    final profile = UserProfile(
      uid: 'user-${now.microsecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: now,
      updatedAt: now,
    );
    await prefs.setStringList(_registeredEmailsKey, [
      ...normalizedRegisteredEmails,
      normalizedEmail,
    ]);
    return updateProfile(profile);
  }

  @override
  Future<UserProfile> login({
    required String email,
    required String password,
  }) async {
    final existing = await loadSession();
    if (existing != null && existing.email == email.trim().toLowerCase()) {
      return existing;
    }
    final profile = UserProfile.demo().copyWith(
      email: email.trim().toLowerCase(),
      updatedAt: DateTime.now(),
    );
    return updateProfile(profile);
  }

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    _profile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    return profile;
  }

  @override
  Future<void> logout() async {
    _profile = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
  }
}

class MockCustomWordRepository implements CustomWordRepository {
  final List<CustomWord> _words = [];

  @override
  Future<List<CustomWord>> list(String uid) async {
    if (_words.where((word) => word.uid == uid).isEmpty) {
      _seed(uid);
    }
    final scoped = _words.where((word) => word.uid == uid).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return scoped;
  }

  @override
  Future<CustomWord> create(CustomWord word) async {
    _words.add(word);
    return word;
  }

  @override
  Future<void> delete(String uid, String id) async {
    _words.removeWhere((word) => word.uid == uid && word.id == id);
  }

  @override
  Future<CustomWord> update(CustomWord word) async {
    final index = _words.indexWhere(
      (item) => item.uid == word.uid && item.id == word.id,
    );
    if (index == -1) {
      _words.add(word);
    } else {
      _words[index] = word;
    }
    return word;
  }

  void _seed(String uid) {
    final now = DateTime.now();
    _words.addAll([
      CustomWord.create(
        id: 'seed-1',
        uid: uid,
        word: 'resilient',
        meaning: '有韧性的',
        exampleSentence: 'A resilient learner keeps practicing after mistakes.',
        note: 'Useful for essays and interviews.',
        tag: 'character',
        difficulty: 'Medium',
        now: now.subtract(const Duration(days: 1)),
      ).copyWith(masteryLevel: 2, correctCount: 3, wrongCount: 1),
      CustomWord.create(
        id: 'seed-2',
        uid: uid,
        word: 'ambiguous',
        meaning: '含糊的',
        exampleSentence:
            'The instruction was ambiguous, so I asked for an example.',
        note: 'Often appears in reading passages.',
        tag: 'academic',
        difficulty: 'Hard',
        now: now.subtract(const Duration(days: 2)),
      ).copyWith(
        masteryLevel: 1,
        correctCount: 1,
        wrongCount: 3,
        nextReviewAt: now,
      ),
    ]);
  }
}

class MockLearningRepository implements LearningRepository {
  final List<StudySession> _sessions = [];

  @override
  Future<List<Lesson>> listLessons({String? wordBookId}) async => seedLessons();

  @override
  Future<void> recordStudySession(StudySession session) async {
    _sessions.add(session);
  }
}

class MockReviewRepository implements ReviewRepository {
  final List<ReviewEvent> _events = [];

  @override
  Future<void> recordReviewEvent(ReviewEvent event) async {
    _events.add(event);
  }
}

class MockNotificationRepository implements NotificationRepository {
  static const _keyPrefix = 'linguaquest.notifications';

  @override
  Future<void> ensureGenerated(
    String uid,
    List<AppNotification> notifications,
  ) async {
    if (notifications.isEmpty) return;
    final existing = await _load(uid);
    final sourceKeys = existing
        .map((notification) => notification.sourceKey)
        .whereType<String>()
        .toSet();
    final ids = existing.map((notification) => notification.id).toSet();
    final merged = [...existing];
    for (final notification in notifications) {
      final sourceKey = notification.sourceKey;
      if (sourceKey != null && sourceKeys.contains(sourceKey)) continue;
      if (ids.contains(notification.id)) continue;
      merged.add(notification);
      if (sourceKey != null) sourceKeys.add(sourceKey);
      ids.add(notification.id);
    }
    await _save(uid, merged);
  }

  @override
  Future<List<AppNotification>> list(
    String uid, {
    bool unreadOnly = false,
    AppNotificationType? type,
  }) async {
    final notifications = await _load(uid);
    return notifications.where((notification) {
      if (unreadOnly && notification.isRead) return false;
      if (type != null && notification.type != type) return false;
      return true;
    }).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<int> markAllRead(String uid) async {
    final now = DateTime.now();
    final existing = await _load(uid);
    final updated = existing
        .where((notification) => !notification.isRead)
        .length;
    final notifications = [
      for (final notification in existing)
        if (notification.isRead)
          notification
        else
          notification.markRead(now: now),
    ];
    await _save(uid, notifications);
    return updated;
  }

  @override
  Future<AppNotification?> markRead(String uid, String id) async {
    final now = DateTime.now();
    AppNotification? updated;
    final notifications = [
      for (final notification in await _load(uid))
        if (notification.id == id)
          updated = notification.markRead(now: now)
        else
          notification,
    ];
    await _save(uid, notifications);
    return updated;
  }

  Future<List<AppNotification>> _load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix.$uid');
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (item) => AppNotification.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    } catch (_) {
      await prefs.remove('$_keyPrefix.$uid');
      return [];
    }
  }

  Future<void> _save(String uid, List<AppNotification> notifications) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = [...notifications]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await prefs.setString(
      '$_keyPrefix.$uid',
      jsonEncode([for (final notification in sorted) notification.toJson()]),
    );
  }
}

class MockWordBookRepository implements WordBookRepository {
  static const _wordBooks = [
    WordBook(
      id: 'beginner',
      title: '初级英语词汇',
      category: '基础英语',
      examType: 'Beginner',
      coverUrl: '',
      totalWords: 2971,
      description: '面向英语初学者的基础词汇，覆盖日常交流和简单阅读场景',
      wordIds: [],
    ),
    WordBook(
      id: 'ielts',
      title: '雅思核心词汇',
      category: '出国考试',
      examType: 'IELTS',
      coverUrl: '',
      totalWords: 3575,
      description: '雅思考试高频核心词汇，覆盖听说读写全场景',
      wordIds: [],
    ),
    WordBook(
      id: 'toefl',
      title: '托福核心词汇',
      category: '出国考试',
      examType: 'TOEFL',
      coverUrl: '',
      totalWords: 4264,
      description: '托福考试高频核心词汇，覆盖听说读写全场景',
      wordIds: [],
    ),
    WordBook(
      id: 'gre',
      title: 'GRE核心词汇',
      category: '出国考试',
      examType: 'GRE',
      coverUrl: '',
      totalWords: 3056,
      description: 'GRE考试高频核心词汇，覆盖填空、阅读、写作全场景',
      wordIds: [],
    ),
    WordBook(
      id: 'sat',
      title: 'SAT核心词汇',
      category: '出国考试',
      examType: 'SAT',
      coverUrl: '',
      totalWords: 5014,
      description: 'SAT考试高频核心词汇，覆盖阅读、文法、写作全场景',
      wordIds: [],
    ),
    WordBook(
      id: 'gmat',
      title: 'GMAT核心词汇',
      category: '出国考试',
      examType: 'GMAT',
      coverUrl: '',
      totalWords: 3254,
      description: 'GMAT考试高频核心词汇，覆盖逻辑、数学、阅读全场景',
      wordIds: [],
    ),
  ];

  @override
  Future<List<WordBook>> listWordBooks() async => _wordBooks;

  @override
  Future<WordBook?> getWordBook(String id) async {
    try {
      return _wordBooks.firstWhere((book) => book.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<WordEntry>> getWords(String bookId, {int? limit, int? offset}) async {
    return [];
  }

  @override
  Future<WordEntry?> getWord(String wordId) async => null;

  @override
  Future<List<WordEntry>> searchWords(String query, {int limit = 20}) async {
    return [];
  }
}
