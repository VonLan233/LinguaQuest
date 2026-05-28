import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/review_event.dart';
import '../../data/models/study_session.dart';
import '../../data/remote/api_client.dart';
import '../../data/repositories/api_repositories.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/custom_word_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/repositories/review_repository.dart';
import '../constants/app_constants.dart';
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

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiReviewRepository(ref.watch(apiClientProvider));
  }
  return MockReviewRepository();
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

  late final AuthRepository _authRepository;
  late final CustomWordRepository _customWordRepository;
  late final LearningRepository _learningRepository;
  late final ReviewRepository _reviewRepository;

  @override
  AppState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _customWordRepository = ref.watch(customWordRepositoryProvider);
    _learningRepository = ref.watch(learningRepositoryProvider);
    _reviewRepository = ref.watch(reviewRepositoryProvider);
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
      final lessons = _applyLessonProgression(
        await _learningRepository.listLessons(),
        completedLessonIds,
      );
      final user = await _authRepository.loadSession();
      final words = user == null
          ? <CustomWord>[]
          : await _customWordRepository.list(user.uid);
      state = state.copyWith(
        isBootstrapped: true,
        isLoading: false,
        user: user,
        lessons: lessons,
        customWords: words,
        themeMode: _themeModeFromName(prefs.getString(_themeModeKey)),
        reminderSettings: _loadReminderSettings(prefs),
        learningPlan: _loadLearningPlan(prefs),
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayReviewWordIds: todayReviewWordIds,
      );
    } catch (error) {
      state = state.copyWith(
        isBootstrapped: true,
        isLoading: false,
        errorMessage: 'Could not start LinguaQuest: ${_friendlyError(error)}',
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
      state = state.copyWith(
        user: user,
        customWords: await _customWordRepository.list(user.uid),
      );
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
        await _clearLearningPlan();
      } else {
        await _saveLearningPlan(plan);
      }
      state = state.copyWith(
        user: updated,
        learningPlan: plan,
        clearLearningPlan: plan == null,
      );
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
      await _saveLessonProgress(completedLessonIds, todayCompletedLessonIds);
      state = state.copyWith(
        user: updatedUser,
        lessons: _applyLessonProgression(state.lessons, completedLessonIds),
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        lastResult: result,
      );
    });
  }

  Future<bool> reviewWord(String id, bool isCorrect) async {
    final user = state.user;
    if (user == null) return false;
    final word = _customWordById(id);
    if (word == null) return false;
    final now = DateTime.now();
    if (isCorrect && !word.isDue(now)) {
      state = state.copyWith(
        errorMessage: 'This word is already marked for today.',
      );
      return false;
    }
    return _run(() async {
      final reviewed = word.reviewed(isCorrect: isCorrect, now: now);
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
      final created = <CustomWord>[];
      for (final mistake in mistakes) {
        final word = mistake.word;
        final normalized = word.word.trim().toLowerCase();
        if (!wordIds.contains(word.id) || existingWords.contains(normalized)) {
          continue;
        }
        final customWord = await _customWordRepository.create(
          CustomWord.create(
            id: 'mistake-${word.id}-${DateTime.now().microsecondsSinceEpoch}',
            uid: user.uid,
            word: word.word,
            meaning: word.meaning,
            exampleSentence: word.exampleSentence,
            note: '${word.definition}\n${mistake.explanation}',
            tag: word.tags.isEmpty ? 'mistake' : word.tags.first,
            difficulty: word.difficulty,
          ),
        );
        created.add(customWord);
        existingWords.add(normalized);
      }
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
        return 'This email is already registered. Try logging in instead.';
      }
      if (message != null && message.isNotEmpty) return message;
      return 'Network request failed. Please try again.';
    }
    if (error is StateError) {
      final message = error.message;
      if (message == 'email already registered') {
        return 'This email is already registered. Try logging in instead.';
      }
      return message;
    }
    return error.toString();
  }

  int _nextStreak(DateTime? lastStudyDate, DateTime now, int currentStreak) {
    if (lastStudyDate == null) return 1;
    final last = DateTime(
      lastStudyDate.year,
      lastStudyDate.month,
      lastStudyDate.day,
    );
    final today = DateTime(now.year, now.month, now.day);
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
    final completed = state.completedLessonIds;
    final remainingWords = state.lessons
        .where((lesson) => !completed.contains(lesson.id))
        .fold(0, (total, lesson) => total + lesson.words.length);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDay = DateTime(deadline.year, deadline.month, deadline.day);
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

  List<Lesson> _applyLessonProgression(
    List<Lesson> lessons,
    Set<String> completedLessonIds,
  ) {
    if (lessons.isEmpty) return lessons;
    final firstIncomplete = lessons.indexWhere(
      (lesson) => !completedLessonIds.contains(lesson.id),
    );
    if (firstIncomplete == -1) {
      return [
        for (final lesson in lessons) lesson.copyWith(status: 'completed'),
      ];
    }
    return [
      for (var index = 0; index < lessons.length; index++)
        lessons[index].copyWith(
          status: completedLessonIds.contains(lessons[index].id)
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
}
