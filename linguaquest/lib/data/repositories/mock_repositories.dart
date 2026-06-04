import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/custom_word.dart';
import '../models/lesson.dart';
import '../models/review_event.dart';
import '../models/study_session.dart';
import '../models/user_word.dart';
import '../models/user_profile.dart';
import '../seed/seed_lessons.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'notification_repository.dart';
import 'review_repository.dart';
import 'user_word_repository.dart';

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
  Future<List<Lesson>> listLessons() async => seedLessons();

  @override
  Future<void> recordStudySession(StudySession session) async {
    _sessions.add(session);
  }
}

class MockUserWordRepository implements UserWordRepository {
  static const _keyPrefix = 'linguaquest.user_words';
  final Map<String, List<UserWord>> _cache = {};

  @override
  Future<List<UserWord>> list(String uid) async {
    if (_cache[uid] != null) return _sorted(_cache[uid]!);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix.$uid');
    if (raw == null) {
      _cache[uid] = [];
      return [];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        _cache[uid] = [];
        return [];
      }
      final words = decoded
          .whereType<Map>()
          .map((item) => UserWord.fromJson(Map<String, dynamic>.from(item)))
          .toList();
      _cache[uid] = words;
      return _sorted(words);
    } catch (_) {
      await prefs.remove('$_keyPrefix.$uid');
      _cache[uid] = [];
      return [];
    }
  }

  @override
  Future<UserWord> upsert(UserWord word) async {
    final updated = (await upsertAll([word])).first;
    return updated;
  }

  @override
  Future<List<UserWord>> upsertAll(List<UserWord> words) async {
    if (words.isEmpty) return [];
    final uid = words.first.uid;
    final existing = await list(uid);
    final byId = {for (final word in existing) word.id: word};
    for (final word in words) {
      byId[word.id] = word;
    }
    final merged = _sorted(byId.values.toList());
    _cache[uid] = merged;
    await _save(uid, merged);
    return words;
  }

  Future<void> _save(String uid, List<UserWord> words) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_keyPrefix.$uid',
      jsonEncode([for (final word in words) word.toJson()]),
    );
  }

  List<UserWord> _sorted(List<UserWord> words) {
    return [...words]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
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
