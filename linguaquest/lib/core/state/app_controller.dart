import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/activity_summary.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/lottery_draw.dart';
import '../../data/models/review_event.dart';
import '../../data/models/reward_task.dart';
import '../../data/models/study_session.dart';
import '../../data/models/target_word_progress.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/api_repositories.dart';
import '../../data/repositories/app_services_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/custom_word_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/lesson_factory.dart';
import '../utils/ui_labels.dart';
import 'app_state.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ApiAuthRepository(ref.watch(apiClientProvider));
});

final customWordRepositoryProvider = Provider<CustomWordRepository>((ref) {
  return ApiCustomWordRepository(ref.watch(apiClientProvider));
});

final learningRepositoryProvider = Provider<LearningRepository>((ref) {
  return ApiLearningRepository(ref.watch(apiClientProvider));
});

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ApiReviewRepository(ref.watch(apiClientProvider));
});

final appServicesRepositoryProvider = Provider<AppServicesRepository>((ref) {
  return ApiAppServicesRepository(ref.watch(apiClientProvider));
});

final leaderboardProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appServicesRepositoryProvider).listLeaderboard();
});

final analyticsSummaryProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appServicesRepositoryProvider).loadAnalyticsSummary();
});

final achievementsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appServicesRepositoryProvider).listAchievements();
});

final classesProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appServicesRepositoryProvider).listClasses();
});

final classProgressProvider = FutureProvider.autoDispose.family((
  ref,
  String classId,
) {
  return ref
      .watch(appServicesRepositoryProvider)
      .loadClassProgress(classId: classId.isEmpty ? null : classId);
});

final forumPostsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appServicesRepositoryProvider).listForumPosts();
});

final forumPostDetailProvider = FutureProvider.autoDispose.family((
  ref,
  String id,
) {
  return ref.watch(appServicesRepositoryProvider).loadForumPost(id);
});

final notificationsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appServicesRepositoryProvider).listNotifications();
});

final aiConversationsProvider = FutureProvider.autoDispose((ref) {
  return ref.watch(appServicesRepositoryProvider).listAiConversations();
});

final aiConversationDetailProvider = FutureProvider.autoDispose.family((
  ref,
  String id,
) {
  return ref.watch(appServicesRepositoryProvider).loadAiConversation(id);
});

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  static const _themeModeKey = 'linguaquest.themeMode';
  static const _reminderKey = 'linguaquest.reminderSettings';

  late final AuthRepository _authRepository;
  late final CustomWordRepository _customWordRepository;
  late final LearningRepository _learningRepository;
  late final ReviewRepository _reviewRepository;
  late final AppServicesRepository _appServicesRepository;

  @override
  AppState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _customWordRepository = ref.watch(customWordRepositoryProvider);
    _learningRepository = ref.watch(learningRepositoryProvider);
    _reviewRepository = ref.watch(reviewRepositoryProvider);
    _appServicesRepository = ref.watch(appServicesRepositoryProvider);
    return AppState.initial();
  }

  Future<void> bootstrap() async {
    if (state.isBootstrapped) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = await _authRepository.loadSession();
      final wordBooks = await _learningRepository.listWordBooks();
      final activity = user == null
          ? ActivitySummary.empty
          : await _learningRepository.loadActivitySummary(user.uid);
      final targetProgress = user == null
          ? <String, TargetWordProgress>{}
          : await _loadTargetWordProgressForUser(user.uid);
      final learningPlan = user == null
          ? null
          : await _loadLearningPlanForUser(
              user.uid,
              wordBooks,
              targetProgress,
              fallbackTarget: user.targetExam,
            );
      final activeBook = _activeWordBook(
        wordBooks,
        learningPlan?.wordBookId ?? wordBookIdForTarget(user?.targetExam),
      );
      final baseLessons = activeBook == null
          ? await _learningRepository.listLessons()
          : lessonsFromWordBook(activeBook);
      final completedLessonIds = {
        ...activity.completedLessonIds,
        ..._completedLessonIdsFromTargetProgress(baseLessons, targetProgress),
      };
      final lessons = _applyLessonProgression(baseLessons, completedLessonIds);
      final words = user == null
          ? <CustomWord>[]
          : await _customWordRepository.list(user.uid);
      final rewardTasks = user == null
          ? <RewardTask>[]
          : await _appServicesRepository.listRewardTasks();
      state = state.copyWith(
        isBootstrapped: true,
        isLoading: false,
        user: user,
        lessons: lessons,
        wordBooks: wordBooks,
        targetWordProgress: targetProgress,
        customWords: words,
        themeMode: _themeModeFromName(prefs.getString(_themeModeKey)),
        reminderSettings: _loadReminderSettings(prefs),
        learningPlan: learningPlan,
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: activity.todayCompletedLessonIds,
        todayReviewWordIds: activity.todayReviewWordIds,
        todayClaimedRewardIds: _claimedRewardIds(rewardTasks),
        rewardTasks: rewardTasks,
      );
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
  }

  Future<bool> register(String name, String email, String password) async {
    return _run(() async {
      final user = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      final plan = state.learningPlan;
      final rewardTasks = await _appServicesRepository.listRewardTasks();
      state = state.copyWith(
        user: user,
        lessons: _applyLessonProgression(
          _lessonsForTarget(plan?.target ?? user.targetExam, plan?.wordBookId),
          state.completedLessonIds,
        ),
        targetWordProgress: await _loadTargetWordProgressForUser(user.uid),
        customWords: await _customWordRepository.list(user.uid),
        rewardTasks: rewardTasks,
        todayClaimedRewardIds: _claimedRewardIds(rewardTasks),
      );
    });
  }

  Future<bool> login(String email, String password) async {
    return _run(() async {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      final plan = state.learningPlan;
      final rewardTasks = await _appServicesRepository.listRewardTasks();
      state = state.copyWith(
        user: user,
        lessons: _applyLessonProgression(
          _lessonsForTarget(plan?.target ?? user.targetExam, plan?.wordBookId),
          state.completedLessonIds,
        ),
        targetWordProgress: await _loadTargetWordProgressForUser(user.uid),
        customWords: await _customWordRepository.list(user.uid),
        rewardTasks: rewardTasks,
        todayClaimedRewardIds: _claimedRewardIds(rewardTasks),
      );
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
        await _clearLearningPlan(user.uid);
      } else {
        await _saveLearningPlan(user.uid, plan);
      }
      state = state.copyWith(
        user: updated,
        learningPlan: plan,
        clearLearningPlan: plan == null,
        lessons: _applyLessonProgression(
          _lessonsForTarget(targetExam, plan?.wordBookId),
          state.completedLessonIds,
        ),
      );
    });
  }

  Future<void> logout() async {
    final themeMode = state.themeMode;
    final reminderSettings = state.reminderSettings;
    final lessons = state.lessons;
    final wordBooks = state.wordBooks;
    final completedLessonIds = state.completedLessonIds;
    await _authRepository.logout();
    state = AppState.initial().copyWith(
      isBootstrapped: true,
      lessons: _applyLessonProgression(lessons, completedLessonIds),
      wordBooks: wordBooks,
      completedLessonIds: completedLessonIds,
      themeMode: themeMode,
      reminderSettings: reminderSettings,
    );
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
      final streakUser = await _authRepository.updateProfile(
        user.copyWith(streak: streak, lastStudyDate: now, updatedAt: now),
      );
      final updatedUser = await _learningRepository.recordStudySession(
        StudySession(
          id: 'session-${now.microsecondsSinceEpoch}',
          uid: user.uid,
          lessonId: result.lessonId,
          startedAt: now.subtract(const Duration(minutes: 5)),
          endedAt: now,
          totalQuestions: result.totalQuestions,
          correctAnswers: result.correctAnswers,
          xpEarned: result.xpEarned,
          mode: result.sessionMode,
          source: result.sessionSource,
          mistakeWordIds: result.mistakes
              .map((question) => question.word.id)
              .toList(),
          exerciseRecords: result.exerciseRecords,
        ),
      );
      final targetProgress = _targetProgressAfterLesson(result, now);
      await _saveTargetWordProgress(user.uid, targetProgress);
      final rewardTasks = await _appServicesRepository.listRewardTasks();
      state = state.copyWith(
        user: updatedUser.copyWith(streak: streakUser.streak),
        lessons: _applyLessonProgression(state.lessons, completedLessonIds),
        targetWordProgress: targetProgress,
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayClaimedRewardIds: _claimedRewardIds(rewardTasks),
        rewardTasks: rewardTasks,
        lastResult: result,
      );
    });
  }

  Future<bool> reviewWord(
    String id,
    bool isCorrect, {
    ReviewDimension dimension = ReviewDimension.confidence,
  }) async {
    final user = state.user;
    if (user == null) return false;
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
      final rewardTasks = await _appServicesRepository.listRewardTasks();
      state = state.copyWith(
        customWords: [
          for (final item in state.customWords) item.id == id ? reviewed : item,
        ],
        todayReviewWordIds: todayReviewWordIds,
        todayClaimedRewardIds: _claimedRewardIds(rewardTasks),
        rewardTasks: rewardTasks,
      );
    });
  }

  Future<bool> reviewTargetWord(
    String id,
    bool isCorrect, {
    ReviewDimension dimension = ReviewDimension.context,
  }) async {
    final user = state.user;
    final word = state.targetWordById(id);
    final book = state.currentWordBook;
    if (user == null || word == null || book == null) return false;
    final now = DateTime.now();
    final current =
        state.targetWordProgress[id] ??
        TargetWordProgress.newWord(wordId: id, wordBookId: book.id, now: now);
    return _run(() async {
      final reviewed = current.reviewed(
        isCorrect: isCorrect,
        dimension: dimension,
        now: now,
      );
      final targetProgress = {...state.targetWordProgress, id: reviewed};
      await _reviewRepository.recordReviewEvent(
        ReviewEvent(
          id: 'target-review-${now.microsecondsSinceEpoch}',
          uid: user.uid,
          wordId: id,
          isCorrect: isCorrect,
          answerTimeMs: 2600,
          reviewedAt: now,
          masteryBefore: current.masteryLevel,
          masteryAfter: reviewed.masteryLevel,
          nextReviewAt: reviewed.nextReviewAt,
        ),
      );
      final todayReviewWordIds = {...state.todayReviewWordIds, id};
      await _saveTargetWordProgress(user.uid, targetProgress);
      final rewardTasks = await _appServicesRepository.listRewardTasks();
      state = state.copyWith(
        targetWordProgress: targetProgress,
        todayReviewWordIds: todayReviewWordIds,
        todayClaimedRewardIds: _claimedRewardIds(rewardTasks),
        rewardTasks: rewardTasks,
      );
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
      final result = await _appServicesRepository.claimReward(id);
      final rewardTasks = result.tasks.isEmpty
          ? _markRewardClaimed(state.rewardTasks, id)
          : result.tasks;
      final claimedRewardIds = rewardTasks.isEmpty
          ? {...state.todayClaimedRewardIds, id}
          : _claimedRewardIds(rewardTasks);
      state = state.copyWith(
        user: result.user,
        todayClaimedRewardIds: claimedRewardIds,
        rewardTasks: rewardTasks,
      );
    });
  }

  Future<LotteryDraw?> drawLottery() async {
    if (state.user == null) return null;
    LotteryDraw? draw;
    final succeeded = await _run(() async {
      final result = await _appServicesRepository.drawLottery();
      draw = result.draw;
      state = state.copyWith(user: result.user);
    });
    return succeeded ? draw : null;
  }

  Future<bool> markNotificationRead(String id) {
    return _run(() async {
      await _appServicesRepository.markNotificationRead(id);
      ref.invalidate(notificationsProvider);
    });
  }

  Future<bool> refreshRewardTasks() {
    return _run(() async {
      final rewardTasks = await _appServicesRepository.listRewardTasks();
      state = state.copyWith(
        rewardTasks: rewardTasks,
        todayClaimedRewardIds: _claimedRewardIds(rewardTasks),
      );
    });
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

  LearningPlan _buildLearningPlan({
    required String target,
    required DateTime deadline,
  }) {
    final wordBookId = wordBookIdForTarget(target);
    final book = _activeWordBook(state.wordBooks, wordBookId);
    final remainingWords = book == null
        ? _lessonsForTarget(target, wordBookId)
              .where((lesson) => !state.completedLessonIds.contains(lesson.id))
              .fold(0, (total, lesson) => total + lesson.words.length)
        : book.words
              .where(
                (word) =>
                    !(state.targetWordProgress[word.id]?.isLearned ?? false),
              )
              .length;
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(deadline.year, deadline.month, deadline.day);
    final days = targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
    final dailyWords = remainingWords == 0
        ? 1
        : ((remainingWords + days - 1) ~/ days).clamp(1, 999).toInt();
    return LearningPlan(
      target: target,
      wordBookId: wordBookId,
      deadline: targetDay,
      dailyWords: dailyWords,
      dailyReviewLimit: (dailyWords * 2).clamp(10, 80).toInt(),
      remainingWords: remainingWords,
      createdAt: now,
    );
  }

  WordBook? _activeWordBook(List<WordBook> books, String id) {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return books.isEmpty ? null : books.first;
  }

  List<Lesson> _lessonsForTarget(String target, String? wordBookId) {
    final book = _activeWordBook(
      state.wordBooks,
      wordBookId ?? wordBookIdForTarget(target),
    );
    if (book == null) return learningLessonsForTarget(state.lessons, target);
    return lessonsFromWordBook(book);
  }

  int _remainingWordsForPlan(
    List<WordBook> wordBooks,
    Map<String, TargetWordProgress> progress,
    LearningPlan plan,
  ) {
    final book = _activeWordBook(wordBooks, plan.wordBookId);
    if (book == null) return plan.remainingWords;
    return book.words
        .where((word) => !(progress[word.id]?.isLearned ?? false))
        .length;
  }

  Set<String> _completedLessonIdsFromTargetProgress(
    List<Lesson> lessons,
    Map<String, TargetWordProgress> progress,
  ) {
    return {
      for (final lesson in lessons)
        if (!lesson.isTrainingPack &&
            lesson.words.isNotEmpty &&
            lesson.words.every((word) => progress[word.id]?.isLearned ?? false))
          lesson.id,
    };
  }

  Map<String, TargetWordProgress> _targetProgressAfterLesson(
    LessonResult result,
    DateTime now,
  ) {
    Lesson? lesson;
    for (final item in state.lessons) {
      if (item.id == result.lessonId) {
        lesson = item;
        break;
      }
    }
    if (lesson == null) return state.targetWordProgress;
    final mistakeWordIds = result.mistakes.map((item) => item.word.id).toSet();
    final updated = {...state.targetWordProgress};
    for (final word in lesson.words) {
      final current =
          updated[word.id] ??
          TargetWordProgress.newWord(
            wordId: word.id,
            wordBookId: state.activeWordBookId,
            now: now,
          );
      updated[word.id] = current.learnedToday(
        hadMistake: mistakeWordIds.contains(word.id),
        now: now,
      );
    }
    return updated;
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

  Future<void> _saveLearningPlan(String uid, LearningPlan plan) async {
    await _learningRepository.saveStudyPlan(uid, plan.toJson());
  }

  Future<void> _clearLearningPlan(String uid) async {
    await _learningRepository.clearStudyPlan(uid);
  }

  Set<String> _claimedRewardIds(List<RewardTask> tasks) {
    return {
      for (final task in tasks)
        if (task.isClaimed) task.id,
    };
  }

  List<RewardTask> _markRewardClaimed(List<RewardTask> tasks, String id) {
    return [
      for (final task in tasks)
        task.id == id
            ? task.copyWith(isAvailable: false, isClaimed: true)
            : task,
    ];
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

  Future<LearningPlan?> _loadLearningPlanForUser(
    String uid,
    List<WordBook> wordBooks,
    Map<String, TargetWordProgress> targetProgress, {
    required String fallbackTarget,
  }) async {
    final raw = await _learningRepository.loadStudyPlan(uid);
    if (raw == null) return null;
    final plan = LearningPlan.fromJson({'target': fallbackTarget, ...raw});
    return plan.copyWith(
      remainingWords: _remainingWordsForPlan(wordBooks, targetProgress, plan),
    );
  }

  Future<Map<String, TargetWordProgress>> _loadTargetWordProgressForUser(
    String uid,
  ) async {
    final remote = await _learningRepository.listTargetWordProgress(uid);
    return {for (final item in remote) item.wordId: item};
  }

  Future<void> _saveTargetWordProgress(
    String uid,
    Map<String, TargetWordProgress> progress,
  ) async {
    for (final item in progress.values) {
      await _learningRepository.upsertTargetWordProgress(uid, item);
    }
  }
}
