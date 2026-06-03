import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_notification.dart';
import '../models/custom_word.dart';
import '../models/daily_reward_task.dart';
import '../models/lesson.dart';
import '../models/review_event.dart';
import '../models/study_session.dart';
import '../models/user_profile.dart';
import '../seed/seed_lessons.dart';
import 'auth_repository.dart';
import 'custom_word_repository.dart';
import 'learning_repository.dart';
import 'notification_repository.dart';
import 'reward_repository.dart';
import 'review_repository.dart';

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

class MockRewardRepository implements RewardRepository {
  static const _keyPrefix = 'linguaquest.rewards';

  @override
  Future<RewardTaskSnapshot> listTasks(String uid) async {
    return _snapshot(uid);
  }

  @override
  Future<RewardTaskSnapshot> checkIn(String uid) async {
    final state = await _load(uid);
    state.checkedIn = true;
    await _save(uid, state);
    return _snapshot(uid);
  }

  @override
  Future<RewardTaskSnapshot> claimTask(String uid, String taskId) async {
    final state = await _load(uid);
    final tasks = _tasksFor(state);
    DailyRewardTask? task;
    for (final item in tasks) {
      if (item.id == taskId) {
        task = item;
        break;
      }
    }
    if (task == null || task.isClaimed) {
      final snapshot = await _snapshot(uid);
      return RewardTaskSnapshot(
        dateKey: snapshot.dateKey,
        tasks: snapshot.tasks,
        alreadyClaimed: task?.isClaimed == true,
        claimed: false,
      );
    }
    if (!task.isClaimable) return _snapshot(uid);
    state.claimedTaskIds.add(taskId);
    await _save(uid, state);
    final snapshot = await _snapshot(uid);
    return RewardTaskSnapshot(
      dateKey: snapshot.dateKey,
      tasks: snapshot.tasks,
      claimed: true,
    );
  }

  @override
  Future<RewardTaskSnapshot> recordEvent(
    String uid,
    RewardEventType type,
  ) async {
    final state = await _load(uid);
    switch (type) {
      case RewardEventType.newLearning:
        state.newLearningDone = true;
      case RewardEventType.reviewDone:
        state.reviewDone = true;
      case RewardEventType.trainingChallenge:
        state.trainingChallengeDone = true;
      case RewardEventType.wrongCleanup:
        state.wrongCleanupDone = true;
      case RewardEventType.forumInteraction:
        state.forumInteractionDone = true;
    }
    await _save(uid, state);
    return _snapshot(uid);
  }

  Future<RewardTaskSnapshot> _snapshot(String uid) async {
    final state = await _load(uid);
    return RewardTaskSnapshot(dateKey: state.dateKey, tasks: _tasksFor(state));
  }

  List<DailyRewardTask> _tasksFor(_MockRewardState state) {
    return [
      _task(
        id: 'dailyCheckIn',
        title: '每日签到',
        condition: '当天打开并点击签到',
        points: 5,
        targetRoute: '/discover',
        done: state.checkedIn,
        claimed: state.claimedTaskIds.contains('dailyCheckIn'),
      ),
      _task(
        id: 'newLearning',
        title: '完成新学',
        condition: '完成今日新学任务',
        points: 20,
        targetRoute: '/study/new',
        done: state.newLearningDone,
        claimed: state.claimedTaskIds.contains('newLearning'),
      ),
      _task(
        id: 'reviewDone',
        title: '完成复习',
        condition: '完成今日到期复习',
        points: 15,
        targetRoute: '/study/review',
        done: state.reviewDone,
        claimed: state.claimedTaskIds.contains('reviewDone'),
      ),
      _task(
        id: 'trainingChallenge',
        title: '训练场挑战',
        condition: '完成任意训练场游戏',
        points: 20,
        targetRoute: '/training',
        done: state.trainingChallengeDone,
        claimed: state.claimedTaskIds.contains('trainingChallenge'),
      ),
      _task(
        id: 'wrongCleanup',
        title: '错词清理',
        condition: '今日错词再次答对',
        points: 10,
        targetRoute: '/review',
        done: state.wrongCleanupDone,
        claimed: state.claimedTaskIds.contains('wrongCleanup'),
      ),
      _task(
        id: 'forumInteraction',
        title: '论坛互动',
        condition: '发帖或评论通过审核',
        points: 5,
        targetRoute: '/discover',
        done: state.forumInteractionDone,
        claimed: state.claimedTaskIds.contains('forumInteraction'),
      ),
    ];
  }

  DailyRewardTask _task({
    required String id,
    required String title,
    required String condition,
    required int points,
    required String targetRoute,
    required bool done,
    required bool claimed,
  }) {
    return DailyRewardTask(
      id: id,
      title: title,
      condition: condition,
      points: points,
      targetRoute: targetRoute,
      status: claimed
          ? DailyRewardTaskStatus.claimed
          : done
          ? DailyRewardTaskStatus.claimable
          : DailyRewardTaskStatus.incomplete,
    );
  }

  Future<_MockRewardState> _load(String uid) async {
    final todayKey = _dateKey(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix.$uid');
    if (raw == null) return _MockRewardState(dateKey: todayKey);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return _MockRewardState(dateKey: todayKey);
      final state = _MockRewardState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
      return state.dateKey == todayKey
          ? state
          : _MockRewardState(dateKey: todayKey);
    } catch (_) {
      await prefs.remove('$_keyPrefix.$uid');
      return _MockRewardState(dateKey: todayKey);
    }
  }

  Future<void> _save(String uid, _MockRewardState state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_keyPrefix.$uid', jsonEncode(state.toJson()));
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _MockRewardState {
  _MockRewardState({required this.dateKey});

  final String dateKey;
  bool checkedIn = false;
  bool newLearningDone = false;
  bool reviewDone = false;
  bool trainingChallengeDone = false;
  bool wrongCleanupDone = false;
  bool forumInteractionDone = false;
  final Set<String> claimedTaskIds = <String>{};

  factory _MockRewardState.fromJson(Map<String, dynamic> json) {
    return _MockRewardState(dateKey: json['dateKey'] as String? ?? '')
      ..checkedIn = json['checkedIn'] == true
      ..newLearningDone = json['newLearningDone'] == true
      ..reviewDone = json['reviewDone'] == true
      ..trainingChallengeDone = json['trainingChallengeDone'] == true
      ..wrongCleanupDone = json['wrongCleanupDone'] == true
      ..forumInteractionDone = json['forumInteractionDone'] == true
      ..claimedTaskIds.addAll(
        (json['claimedTaskIds'] as List<dynamic>? ?? const <dynamic>[])
            .whereType<String>(),
      );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'checkedIn': checkedIn,
      'newLearningDone': newLearningDone,
      'reviewDone': reviewDone,
      'trainingChallengeDone': trainingChallengeDone,
      'wrongCleanupDone': wrongCleanupDone,
      'forumInteractionDone': forumInteractionDone,
      'claimedTaskIds': claimedTaskIds.toList(),
    };
  }
}
