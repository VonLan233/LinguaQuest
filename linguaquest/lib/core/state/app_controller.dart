import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_notification.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/review_event.dart';
import '../../data/models/study_session.dart';
import '../../data/models/user_word.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/api_repositories.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/custom_word_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/user_word_repository.dart';
import '../../services/local_notification_service.dart';
import '../constants/app_constants.dart';
import '../utils/ui_labels.dart';
import 'app_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiAuthRepository(ref.watch(apiClientProvider));
  }
  return MockAuthRepository();
});

final customWordRepositoryProvider = Provider<CustomWordRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiCustomWordRepository(ref.watch(apiClientProvider));
  }
  return MockCustomWordRepository();
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiLearningRepository(ref.watch(apiClientProvider));
  }
  return MockLearningRepository();
});

final userWordRepositoryProvider = Provider<UserWordRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiUserWordRepository(ref.watch(apiClientProvider));
  }
  return MockUserWordRepository();
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiReviewRepository(ref.watch(apiClientProvider));
  }
  return MockReviewRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiNotificationRepository(ref.watch(apiClientProvider));
  }
  return MockNotificationRepository();
});

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  static const _themeModeKey = 'linguaquest.themeMode';
  static const _reminderKey = 'linguaquest.reminderSettings';
  static const _learningPlanKey = 'linguaquest.learningPlan';
  static const _completedLessonIdsKey = 'linguaquest.completedLessons';
  static const _todayDateKey = 'linguaquest.today.date';
  static const _todayLessonIdsKey = 'linguaquest.today.lessons';
  static const _todayReviewIdsKey = 'linguaquest.today.reviews';
  static const _todayRewardIdsKey = 'linguaquest.today.rewards';

  late final AuthRepository _authRepository;
  late final CustomWordRepository _customWordRepository;
  late final LearningRepository _learningRepository;
  late final UserWordRepository _userWordRepository;
  late final ReviewRepository _reviewRepository;
  late final NotificationRepository _notificationRepository;
  late final LocalNotificationService _localNotificationService;
  var _localNotificationsInitialized = false;

  @override
  AppState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _customWordRepository = ref.watch(customWordRepositoryProvider);
    _learningRepository = ref.watch(learningRepositoryProvider);
    _userWordRepository = ref.watch(userWordRepositoryProvider);
    _reviewRepository = ref.watch(reviewRepositoryProvider);
    _notificationRepository = ref.watch(notificationRepositoryProvider);
    _localNotificationService = ref.watch(localNotificationServiceProvider);
    return AppState.initial();
  }

  Future<void> bootstrap() async {
    if (state.isBootstrapped) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final completedLessonIds = _stringSet(prefs, _completedLessonIdsKey);
      final todayKey = _dateKey(DateTime.now());
      final hasTodayState = prefs.getString(_todayDateKey) == todayKey;
      final todayCompletedLessonIds = hasTodayState
          ? _stringSet(prefs, _todayLessonIdsKey)
          : <String>{};
      final todayReviewWordIds = hasTodayState
          ? _stringSet(prefs, _todayReviewIdsKey)
          : <String>{};
      final todayClaimedRewardIds = hasTodayState
          ? _stringSet(prefs, _todayRewardIdsKey)
          : <String>{};
      final lessons = _applyLessonProgression(
        await _learningRepository.listLessons(),
        completedLessonIds,
      );
      final user = await _authRepository.loadSession();
      final words = user == null
          ? <CustomWord>[]
          : await _customWordRepository.list(user.uid);
      final userWords = user == null
          ? <UserWord>[]
          : await _userWordRepository.list(user.uid);
      state = state.copyWith(
        isBootstrapped: true,
        isLoading: false,
        user: user,
        lessons: lessons,
        customWords: words,
        userWords: userWords,
        themeMode: _themeModeFromName(prefs.getString(_themeModeKey)),
        reminderSettings: _loadReminderSettings(prefs),
        learningPlan: _loadLearningPlan(prefs),
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayReviewWordIds: todayReviewWordIds,
        todayClaimedRewardIds: todayClaimedRewardIds,
      );
      await refreshNotifications();
      unawaited(_initializeThenScheduleLocalNotifications());
    } catch (error) {
      state = state.copyWith(
        isBootstrapped: false,
        isLoading: false,
        errorMessage: 'LinguaQuest 启动失败：${_friendlyError(error)}',
      );
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeName(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updateReminderSettings(DailyReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderKey, jsonEncode(settings.toJson()));
    state = state.copyWith(reminderSettings: settings);
    unawaited(_scheduleLocalNotifications());
  }

  Future<bool> register(String name, String email, String password) async {
    return _run(() async {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      state = state.copyWith(
        user: user,
        customWords: await _customWordRepository.list(user.uid),
        userWords: await _userWordRepository.list(user.uid),
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      state = state.copyWith(
        user: user,
        customWords: await _customWordRepository.list(user.uid),
        userWords: await _userWordRepository.list(user.uid),
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> completeGoalSetup({
    required String targetExam,
    required String level,
    required int dailyGoal,
    DateTime? deadline,
  }) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final plan = deadline == null
          ? null
          : _buildLearningPlan(target: targetExam, deadline: deadline);
      final updated = await _authRepository.updateProfile(
        user.copyWith(
          targetExam: targetExam,
          level: level,
          dailyGoal: plan?.dailyWords ?? dailyGoal,
          updatedAt: DateTime.now(),
        ),
      );
      if (plan == null) {
        await _clearLearningPlan();
      } else {
        await _saveLearningPlan(plan);
      }
      state = state.copyWith(
        user: updated,
        learningPlan: plan,
        clearLearningPlan: plan == null,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<void> logout() async {
    final themeMode = state.themeMode;
    final reminderSettings = state.reminderSettings;
    final lessons = state.lessons;
    final completedLessonIds = state.completedLessonIds;
    await _authRepository.logout();
    state = AppState.initial().copyWith(
      isBootstrapped: true,
      lessons: _applyLessonProgression(lessons, completedLessonIds),
      completedLessonIds: completedLessonIds,
      themeMode: themeMode,
      reminderSettings: reminderSettings,
      notifications: [],
    );
    unawaited(_scheduleLocalNotifications());
  }

  Future<bool> addCustomWord({
    required String word,
    required String meaning,
    required String exampleSentence,
    required String note,
    required String tag,
    required String difficulty,
  }) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final created = await _customWordRepository.create(
        CustomWord.create(
          id: 'word-${DateTime.now().microsecondsSinceEpoch}',
          uid: user.uid,
          word: word,
          meaning: meaning,
          exampleSentence: exampleSentence,
          note: note,
          tag: tag,
          difficulty: difficulty,
        ),
      );
      state = state.copyWith(customWords: [created, ...state.customWords]);
    });
  }

  Future<bool> updateCustomWord(CustomWord word) async {
    return _run(() async {
      final updated = await _customWordRepository.update(
        word.copyWith(updatedAt: DateTime.now()),
      );
      state = state.copyWith(
        customWords: [
          for (final item in state.customWords)
            item.id == updated.id ? updated : item,
        ],
      );
    });
  }

  Future<bool> deleteCustomWord(String id) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      await _customWordRepository.delete(user.uid, id);
      state = state.copyWith(
        customWords: state.customWords.where((word) => word.id != id).toList(),
      );
    });
  }

  Future<bool> updateTargetWordFlags(
    Word targetWord, {
    required String wordBookId,
    bool? isFavorite,
    bool? isInNewWordbook,
    bool? isIgnored,
  }) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final now = DateTime.now();
      final existing = state.userWords.firstWhere(
        (word) => word.wordId == targetWord.id,
        orElse: () => UserWord.create(
          uid: user.uid,
          word: targetWord,
          wordBookId: wordBookId,
          now: now,
        ),
      );
      final ignored = isIgnored ?? existing.isIgnored;
      final updated = existing.copyWith(
        wordBookId: wordBookId,
        word: targetWord.word,
        meaning: targetWord.meaning,
        exampleSentence: targetWord.exampleSentence,
        difficulty: targetWord.difficulty,
        isFavorite: isFavorite,
        isInNewWordbook: isInNewWordbook,
        isIgnored: ignored,
        status: ignored
            ? 'Ignored'
            : existing.status == 'Ignored'
            ? 'Previewed'
            : existing.status,
        updatedAt: now,
      );
      final saved = await _userWordRepository.upsert(updated);
      state = state.copyWith(
        userWords: _mergeUserWords(state.userWords, [saved]),
      );
      await refreshNotifications();
    });
  }

  Future<bool> completeLesson(LessonResult result) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final now = DateTime.now();
      final lastStudy = user.lastStudyDate;
      final streak = _nextStreak(lastStudy, now, user.streak);
      final completedLessonIds = {...state.completedLessonIds, result.lessonId};
      final todayCompletedLessonIds = {
        ...state.todayCompletedLessonIds,
        result.lessonId,
      };
      final updatedUser = await _authRepository.updateProfile(
        user.copyWith(
          xp: user.xp + result.xpEarned,
          streak: streak,
          lastStudyDate: now,
          updatedAt: now,
        ),
      );
      await _learningRepository.recordStudySession(
        StudySession(
          id: 'session-${now.microsecondsSinceEpoch}',
          uid: user.uid,
          lessonId: result.lessonId,
          startedAt: now.subtract(const Duration(minutes: 5)),
          endedAt: now,
          totalQuestions: result.totalQuestions,
          correctAnswers: result.correctAnswers,
          xpEarned: result.xpEarned,
          mistakeWordIds: result.mistakes
              .map((question) => question.word.id)
              .toList(),
        ),
      );
      final learnedUserWords = await _recordLessonUserWords(
        uid: user.uid,
        result: result,
        now: now,
      );
      await _saveLessonProgress(completedLessonIds, todayCompletedLessonIds);
      state = state.copyWith(
        user: updatedUser,
        lessons: _applyLessonProgression(state.lessons, completedLessonIds),
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        userWords: _mergeUserWords(state.userWords, learnedUserWords),
        lastResult: result,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> reviewWord(
    String id,
    bool isCorrect, {
    ReviewDimension dimension = ReviewDimension.confidence,
  }) async {
    final user = state.user;
    if (user == null) return false;
    final targetWord = _userWordByReviewId(id);
    if (targetWord != null) {
      return _reviewUserWord(
        user.uid,
        targetWord,
        isCorrect,
        dimension: dimension,
      );
    }
    final word = _customWordById(id);
    if (word == null) return false;
    final now = DateTime.now();
    if (isCorrect && !word.isDue(now)) {
      state = state.copyWith(errorMessage: '这张词卡今天已经完成复习。');
      return false;
    }
    return _run(() async {
      final reviewed = word.reviewed(
        isCorrect: isCorrect,
        now: now,
        dimension: dimension,
      );
      await _customWordRepository.update(reviewed);
      await _reviewRepository.recordReviewEvent(
        ReviewEvent(
          id: 'review-${now.microsecondsSinceEpoch}',
          uid: user.uid,
          wordId: id,
          isCorrect: isCorrect,
          answerTimeMs: 2400,
          reviewedAt: now,
          masteryBefore: word.masteryLevel,
          masteryAfter: reviewed.masteryLevel,
          nextReviewAt: reviewed.nextReviewAt,
        ),
      );
      final todayReviewWordIds = {...state.todayReviewWordIds, id};
      await _saveTodayReviewWords(todayReviewWordIds);
      state = state.copyWith(
        customWords: [
          for (final item in state.customWords) item.id == id ? reviewed : item,
        ],
        todayReviewWordIds: todayReviewWordIds,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> _reviewUserWord(
    String uid,
    UserWord word,
    bool isCorrect, {
    ReviewDimension dimension = ReviewDimension.confidence,
  }) async {
    final now = DateTime.now();
    if (isCorrect && !word.isDue(now)) {
      state = state.copyWith(errorMessage: '这个目标词今天已经完成复习。');
      return false;
    }
    return _run(() async {
      final reviewed = word.reviewed(
        isCorrect: isCorrect,
        now: now,
        dimension: dimension,
      );
      final saved = await _userWordRepository.upsert(reviewed);
      await _reviewRepository.recordReviewEvent(
        ReviewEvent(
          id: 'review-${now.microsecondsSinceEpoch}',
          uid: uid,
          wordId: word.wordId,
          isCorrect: isCorrect,
          answerTimeMs: 2400,
          reviewedAt: now,
          masteryBefore: word.masteryLevel,
          masteryAfter: saved.masteryLevel,
          nextReviewAt: saved.nextReviewAt,
        ),
      );
      final todayReviewWordIds = {
        ...state.todayReviewWordIds,
        word.reviewCardId,
      };
      await _saveTodayReviewWords(todayReviewWordIds);
      state = state.copyWith(
        userWords: _mergeUserWords(state.userWords, [saved]),
        todayReviewWordIds: todayReviewWordIds,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> claimReward({
    required String id,
    required int points,
    required bool isAvailable,
  }) async {
    final user = state.user;
    if (user == null || points <= 0 || !isAvailable) return false;
    if (state.todayClaimedRewardIds.contains(id)) return false;
    return _run(() async {
      final now = DateTime.now();
      final claimedRewardIds = {...state.todayClaimedRewardIds, id};
      final updatedUser = await _authRepository.updateProfile(
        user.copyWith(xp: user.xp + points, updatedAt: now),
      );
      await _saveTodayClaimedRewards(claimedRewardIds);
      state = state.copyWith(
        user: updatedUser,
        todayClaimedRewardIds: claimedRewardIds,
      );
      await refreshNotifications();
    });
  }

  Future<void> refreshNotifications() async {
    final user = state.user;
    if (user == null) {
      state = state.copyWith(notifications: []);
      return;
    }
    try {
      final generated = _buildGeneratedNotifications(user.uid, DateTime.now());
      await _notificationRepository.ensureGenerated(user.uid, generated);
      if (!ref.mounted || state.user?.uid != user.uid) return;
      final notifications = await _notificationRepository.list(user.uid);
      if (!ref.mounted || state.user?.uid != user.uid) return;
      state = state.copyWith(notifications: notifications);
    } catch (error) {
      debugPrint('Failed to refresh notifications: $error');
    }
  }

  Future<String> openNotification(AppNotification notification) async {
    unawaited(markNotificationRead(notification.id));
    return notification.targetRoute.trim().isEmpty
        ? '/home'
        : notification.targetRoute;
  }

  Future<void> markNotificationRead(String id) async {
    final user = state.user;
    if (user == null) return;
    final oldNotifications = state.notifications;
    final now = DateTime.now().toUtc();
    state = state.copyWith(
      notifications: [
        for (final notification in state.notifications)
          notification.id == id
              ? notification.markRead(now: now)
              : notification,
      ],
    );
    try {
      final updated = await _notificationRepository.markRead(user.uid, id);
      if (!ref.mounted || state.user?.uid != user.uid) return;
      if (updated == null) return;
      state = state.copyWith(
        notifications: [
          for (final notification in state.notifications)
            notification.id == id ? updated : notification,
        ],
      );
    } catch (_) {
      if (ref.mounted && state.user?.uid == user.uid) {
        state = state.copyWith(notifications: oldNotifications);
      }
    }
  }

  Future<int> markAllNotificationsRead() async {
    final user = state.user;
    if (user == null) return 0;
    final oldNotifications = state.notifications;
    final now = DateTime.now().toUtc();
    state = state.copyWith(
      notifications: [
        for (final notification in state.notifications)
          notification.isRead ? notification : notification.markRead(now: now),
      ],
    );
    try {
      return await _notificationRepository.markAllRead(user.uid);
    } catch (_) {
      if (ref.mounted && state.user?.uid == user.uid) {
        state = state.copyWith(notifications: oldNotifications);
      }
      return 0;
    }
  }

  Future<int> addMistakesToCustomWords(Set<String> wordIds) async {
    final user = state.user;
    final mistakes = state.lastResult?.mistakes ?? const [];
    if (user == null || wordIds.isEmpty || mistakes.isEmpty) return 0;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final existingWords = state.customWords
          .map((word) => word.word.trim().toLowerCase())
          .toSet();
      final createFutures = <Future<CustomWord>>[];
      final createdAt = DateTime.now().microsecondsSinceEpoch;
      for (var index = 0; index < mistakes.length; index++) {
        final mistake = mistakes[index];
        final word = mistake.word;
        final normalized = word.word.trim().toLowerCase();
        if (!wordIds.contains(word.id) || existingWords.contains(normalized)) {
          continue;
        }
        existingWords.add(normalized);
        createFutures.add(
          _customWordRepository.create(
            CustomWord.create(
              id: 'mistake-${word.id}-${createdAt + index}',
              uid: user.uid,
              word: word.word,
              meaning: word.meaning,
              exampleSentence: word.exampleSentence,
              note: '${word.definition}\n${mistake.explanation}',
              tag: word.tags.isEmpty ? '错题' : displayWordTag(word.tags.first),
              difficulty: word.difficulty,
            ),
          ),
        );
      }
      final created = await Future.wait(createFutures);
      state = state.copyWith(
        isLoading: false,
        customWords: [...created, ...state.customWords],
      );
      return created.length;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return 0;
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  String _friendlyError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      final message = data is Map ? data['error']?.toString() : null;
      if (message == 'email already registered') {
        return '该邮箱已经注册，请直接登录。';
      }
      if (message != null && message.isNotEmpty) return message;
      return '网络请求失败，请稍后重试。';
    }
    if (error is StateError) {
      final message = error.message;
      if (message == 'email already registered') {
        return '该邮箱已经注册，请直接登录。';
      }
      return message;
    }
    return error.toString();
  }

  int _nextStreak(DateTime? lastStudyDate, DateTime now, int currentStreak) {
    if (lastStudyDate == null) return 1;
    final last = DateTime.utc(
      lastStudyDate.year,
      lastStudyDate.month,
      lastStudyDate.day,
    );
    final today = DateTime.utc(now.year, now.month, now.day);
    final difference = today.difference(last).inDays;
    if (difference == 0) return currentStreak;
    if (difference == 1) return currentStreak + 1;
    return 1;
  }

  CustomWord? _customWordById(String id) {
    for (final word in state.customWords) {
      if (word.id == id) return word;
    }
    return null;
  }

  UserWord? _userWordByReviewId(String id) {
    for (final word in state.userWords) {
      if (word.reviewCardId == id || word.id == id || word.wordId == id) {
        return word;
      }
    }
    return null;
  }

  Future<List<UserWord>> _recordLessonUserWords({
    required String uid,
    required LessonResult result,
    required DateTime now,
  }) async {
    final lesson = _lessonById(result.lessonId);
    if (lesson == null || lesson.words.isEmpty) return [];
    final mistakeWordIds = result.mistakes
        .map((mistake) => mistake.word.id)
        .toSet();
    final existingByWordId = {
      for (final word in state.userWords) word.wordId: word,
    };
    final updates = <UserWord>[];
    for (final targetWord in lesson.words) {
      final existing =
          existingByWordId[targetWord.id] ??
          UserWord.create(
            uid: uid,
            word: targetWord,
            wordBookId: lesson.section,
            now: now,
          );
      if (existing.isIgnored || existing.status == 'Ignored') continue;
      updates.add(
        existing
            .copyWith(
              wordBookId: lesson.section,
              word: targetWord.word,
              meaning: targetWord.meaning,
              exampleSentence: targetWord.exampleSentence,
              difficulty: targetWord.difficulty,
            )
            .learned(
              hadMistake: mistakeWordIds.contains(targetWord.id),
              now: now,
            ),
      );
    }
    if (updates.isEmpty) return [];
    return _userWordRepository.upsertAll(updates);
  }

  Lesson? _lessonById(String lessonId) {
    for (final lesson in state.lessons) {
      if (lesson.id == lessonId) return lesson;
    }
    return null;
  }

  List<UserWord> _mergeUserWords(
    List<UserWord> existing,
    List<UserWord> updates,
  ) {
    if (updates.isEmpty) return existing;
    final byId = {for (final word in existing) word.id: word};
    for (final word in updates) {
      byId[word.id] = word;
    }
    return byId.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  LearningPlan _buildLearningPlan({
    required String target,
    required DateTime deadline,
  }) {
    final completed = state.completedLessonIds;
    final remainingWords = learningLessonsForTarget(state.lessons, target)
        .where((lesson) => !completed.contains(lesson.id))
        .fold(0, (total, lesson) => total + lesson.words.length);
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(deadline.year, deadline.month, deadline.day);
    final days = targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
    final dailyWords = remainingWords == 0
        ? 1
        : ((remainingWords + days - 1) ~/ days).clamp(1, 999).toInt();
    return LearningPlan(
      target: target,
      deadline: targetDay,
      dailyWords: dailyWords,
      remainingWords: remainingWords,
      createdAt: now,
    );
  }

  List<AppNotification> _buildGeneratedNotifications(String uid, DateTime now) {
    final dateKey = _dateKey(now);
    final notifications = <AppNotification>[];
    final dueCount = state.dueWords.length;
    final dailyGoal =
        state.learningPlan?.dailyWords ?? state.user?.dailyGoal ?? 10;
    final todayWork =
        state.todayLearningWords + state.todayReviewWordIds.length;
    final hasStudyToday =
        state.todayCompletedFormalLessonIds.isNotEmpty ||
        todayWork >= dailyGoal;
    final hasCheckedIn =
        _isSameDay(state.user?.lastStudyDate, now) || todayWork > 0;

    if (!hasStudyToday) {
      notifications.add(
        _generatedNotification(
          uid: uid,
          type: AppNotificationType.learningReminder,
          title: '今日学习计划待完成',
          body: '今天目标新学 $dailyGoal 词，先从当前词书开始。',
          targetRoute: '/study/new',
          sourceKey: 'learningReminder:$dateKey',
          now: now,
        ),
      );
    }
    if (dueCount > 0) {
      notifications.add(
        _generatedNotification(
          uid: uid,
          type: AppNotificationType.reviewDue,
          title: '$dueCount 个词到期复习',
          body: '先清理复习队列，答错词会自动进入强化阶段。',
          targetRoute: '/study/review',
          sourceKey: 'reviewDue:$dateKey',
          now: now,
        ),
      );
    }
    if (!hasCheckedIn) {
      notifications.add(
        _generatedNotification(
          uid: uid,
          type: AppNotificationType.checkInReminder,
          title: '今天还没有打卡',
          body: '完成一次学习或复习即可延续连续打卡。',
          targetRoute: '/discover',
          sourceKey: 'checkInReminder:$dateKey',
          now: now,
        ),
      );
    }
    notifications.add(
      _generatedNotification(
        uid: uid,
        type: AppNotificationType.activity,
        title: '发现页积分任务已刷新',
        body: '完成新学、复习和错词清理后可领取 XP。',
        targetRoute: '/discover',
        sourceKey: 'activity:$dateKey',
        now: now,
      ),
    );
    return notifications;
  }

  AppNotification _generatedNotification({
    required String uid,
    required AppNotificationType type,
    required String title,
    required String body,
    required String targetRoute,
    required String sourceKey,
    required DateTime now,
  }) {
    return AppNotification(
      id: 'notification-${sourceKey.replaceAll(':', '-')}-${now.year}',
      uid: uid,
      type: type,
      title: title,
      body: body,
      targetRoute: targetRoute,
      isRead: false,
      createdAt: now.toUtc(),
      sourceKey: sourceKey,
    );
  }

  Future<void> _scheduleLocalNotifications() async {
    if (!ref.mounted) return;
    final snapshot = state;
    final user = snapshot.user;
    final reminderSettings = snapshot.reminderSettings;
    final dueCount = user == null ? 0 : snapshot.dueWords.length;
    await _localNotificationService.scheduleDailyStudyReminder(
      enabled: user != null && reminderSettings.enabled,
      hour: reminderSettings.hour,
      minute: reminderSettings.minute,
    );
    await _localNotificationService.scheduleReviewDueReminder(
      dueCount: dueCount,
    );
  }

  Future<void> _initializeLocalNotifications() async {
    if (_localNotificationsInitialized || !ref.mounted) return;
    _localNotificationsInitialized = true;
    await _localNotificationService.initialize(
      onSelectRoute: (route) {
        if (!ref.mounted) return;
        ref.read(localNotificationTapRouteProvider.notifier).show(route);
      },
    );
  }

  Future<void> _initializeThenScheduleLocalNotifications() async {
    await _initializeLocalNotifications();
    await _scheduleLocalNotifications();
  }

  List<Lesson> _applyLessonProgression(
    List<Lesson> lessons,
    Set<String> completedLessonIds,
  ) {
    if (lessons.isEmpty) return lessons;
    final firstIncomplete = lessons.indexWhere(
      (lesson) =>
          !lesson.isTrainingPack && !completedLessonIds.contains(lesson.id),
    );
    if (firstIncomplete == -1) {
      return [
        for (final lesson in lessons)
          lesson.copyWith(
            status: lesson.isTrainingPack ? 'locked' : 'completed',
          ),
      ];
    }
    return [
      for (var index = 0; index < lessons.length; index++)
        lessons[index].copyWith(
          status: lessons[index].isTrainingPack
              ? 'locked'
              : completedLessonIds.contains(lessons[index].id)
              ? 'completed'
              : index == firstIncomplete
              ? 'current'
              : 'locked',
        ),
    ];
  }

  Future<void> _saveLearningPlan(LearningPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_learningPlanKey, jsonEncode(plan.toJson()));
  }

  Future<void> _clearLearningPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_learningPlanKey);
  }

  Future<void> _saveLessonProgress(
    Set<String> completedLessonIds,
    Set<String> todayCompletedLessonIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _completedLessonIdsKey,
      completedLessonIds.toList(),
    );
    await prefs.setString(_todayDateKey, _dateKey(DateTime.now()));
    await prefs.setStringList(
      _todayLessonIdsKey,
      todayCompletedLessonIds.toList(),
    );
  }

  Future<void> _saveTodayReviewWords(Set<String> todayReviewWordIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(DateTime.now()));
    await prefs.setStringList(_todayReviewIdsKey, todayReviewWordIds.toList());
  }

  Future<void> _saveTodayClaimedRewards(
    Set<String> todayClaimedRewardIds,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(DateTime.now()));
    await prefs.setStringList(
      _todayRewardIdsKey,
      todayClaimedRewardIds.toList(),
    );
  }

  ThemeMode _themeModeFromName(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  DailyReminderSettings _loadReminderSettings(SharedPreferences prefs) {
    final raw = prefs.getString(_reminderKey);
    if (raw == null) return DailyReminderSettings.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return DailyReminderSettings.defaults;
      return DailyReminderSettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return DailyReminderSettings.defaults;
    }
  }

  LearningPlan? _loadLearningPlan(SharedPreferences prefs) {
    final raw = prefs.getString(_learningPlanKey);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return LearningPlan.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }

  Set<String> _stringSet(SharedPreferences prefs, String key) {
    return (prefs.getStringList(key) ?? const <String>[]).toSet();
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  bool _isSameDay(DateTime? value, DateTime now) {
    if (value == null) return false;
    final local = value.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }
}
