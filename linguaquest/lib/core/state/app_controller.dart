import 'dart:async';
import 'dart:convert';
import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/app_notification.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/daily_reward_task.dart';
import '../../data/models/exercise_record.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/lottery.dart';
import '../../data/models/point_grant_result.dart';
import '../../data/models/review_event.dart';
import '../../data/models/study_session.dart';
import '../../data/models/study_plan.dart';
import '../../data/models/user_privacy.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/user_word.dart';
import '../../data/remote/api_client.dart';
import '../../data/models/forum.dart';
import '../../data/repositories/ai_repository.dart';
import '../../data/repositories/api_repositories.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/custom_word_repository.dart';
import '../../data/repositories/forum_repository.dart';
import '../../data/repositories/learning_repository.dart';
import '../../data/repositories/lottery_repository.dart';
import '../../data/repositories/mock_repositories.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/reward_repository.dart';
import '../../data/repositories/reward_task_repository.dart';
import '../../data/repositories/review_repository.dart';
import '../../data/repositories/study_plan_repository.dart';
import '../../data/repositories/user_word_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/local_notification_service.dart';
import '../constants/app_constants.dart';
import '../utils/ui_labels.dart';
import 'app_state.dart';

/// Outcome of a register/login attempt, used by the auth screens to decide
/// navigation (home vs the verify-email screen vs showing an error).
enum AuthStep { authenticated, needsVerification, failed }

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

final studyPlanRepositoryProvider = Provider<StudyPlanRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiStudyPlanRepository(ref.watch(apiClientProvider));
  }
  return MockStudyPlanRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiNotificationRepository(ref.watch(apiClientProvider));
  }
  return MockNotificationRepository();
});

final lotteryRepositoryProvider = Provider<LotteryRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiLotteryRepository(ref.watch(apiClientProvider));
  }
  return MockLotteryRepository();
});

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiRewardRepository(ref.watch(apiClientProvider));
  }
  return MockRewardRepository();
});

final rewardTaskRepositoryProvider = Provider<RewardTaskRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiRewardTaskRepository(ref.watch(apiClientProvider));
  }
  return MockRewardTaskRepository();
});

final aiRepositoryProvider = Provider<AiRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiAiRepository(ref.read(apiClientProvider));
  }
  return MockAiRepository();
});

final forumRepositoryProvider = Provider<ForumRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiForumRepository(ref.read(apiClientProvider));
  }
  return MockForumRepository();
});

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  static const _themeModeKey = 'linguaquest.themeMode';
  static const _localeKey = 'linguaquest.locale';
  static const _targetLanguageKey = 'linguaquest.target_language';
  static const _reminderKey = 'linguaquest.reminderSettings';
  static const _sensoryKey = 'linguaquest.sensory_settings';
  static const _privacyKey = 'linguaquest.privacy_settings';
  static const _currentWordBookIdKey = 'linguaquest.currentWordBookId';
  static const _completedLessonIdsKey = 'linguaquest.completedLessons';
  static const _todayDateKey = 'linguaquest.today.date';
  static const _todayLessonIdsKey = 'linguaquest.today.lessons';
  static const _todayReviewIdsKey = 'linguaquest.today.reviews';
  static const _todayTrainingIdsKey = 'linguaquest.today.training';
  static const _todayTrainingGameIdsKey = 'linguaquest.today.training.games';
  static const _todayTrainingXpKey = 'linguaquest.today.training.xp';
  static const _todayRewardIdsKey = 'linguaquest.today.rewards';

  late final AuthRepository _authRepository;
  late final CustomWordRepository _customWordRepository;
  late final LearningRepository _learningRepository;
  late final UserWordRepository _userWordRepository;
  late final ReviewRepository _reviewRepository;
  late final StudyPlanRepository _studyPlanRepository;
  late final NotificationRepository _notificationRepository;
  late final LotteryRepository _lotteryRepository;
  late final RewardRepository _rewardRepository;
  late final RewardTaskRepository _rewardTaskRepository;
  late final ForumRepository _forumRepository;
  late final LocalNotificationService _localNotificationService;
  var _localNotificationsInitialized = false;

  @override
  AppState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    _customWordRepository = ref.watch(customWordRepositoryProvider);
    _learningRepository = ref.watch(learningRepositoryProvider);
    _userWordRepository = ref.watch(userWordRepositoryProvider);
    _reviewRepository = ref.watch(reviewRepositoryProvider);
    _studyPlanRepository = ref.watch(studyPlanRepositoryProvider);
    _notificationRepository = ref.watch(notificationRepositoryProvider);
    _lotteryRepository = ref.watch(lotteryRepositoryProvider);
    _rewardRepository = ref.watch(rewardRepositoryProvider);
    _rewardTaskRepository = ref.watch(rewardTaskRepositoryProvider);
    _forumRepository = ref.watch(forumRepositoryProvider);
    _localNotificationService = ref.watch(localNotificationServiceProvider);
    return AppState.initial();
  }

  Future<void> bootstrap() async {
    if (state.isBootstrapped) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final localCompletedLessonIds = _stringSet(prefs, _completedLessonIdsKey);
      final todayKey = _dateKey(DateTime.now());
      final hasTodayState = prefs.getString(_todayDateKey) == todayKey;
      final localTodayCompletedLessonIds = hasTodayState
          ? _stringSet(prefs, _todayLessonIdsKey)
          : <String>{};
      final localTodayReviewWordIds = hasTodayState
          ? _stringSet(prefs, _todayReviewIdsKey)
          : <String>{};
      final todayTrainingSessionIds = hasTodayState
          ? _stringSet(prefs, _todayTrainingIdsKey)
          : <String>{};
      final localTodayTrainingGameIds = hasTodayState
          ? _stringSet(prefs, _todayTrainingGameIdsKey)
          : <String>{};
      final localTodayTrainingXp = hasTodayState
          ? prefs.getInt(_todayTrainingXpKey) ?? 0
          : 0;
      final localTodayClaimedRewardIds = hasTodayState
          ? _stringSet(prefs, _todayRewardIdsKey)
          : <String>{};
      UserProfile? user;
      try {
        user = await _authRepository.loadSession();
      } catch (error) {
        debugPrint('Failed to load session: $error');
      }
      final wordBooks = await _learningRepository.listWordBooks();
      final studyPlan = user == null
          ? null
          : await _loadOrCreateStudyPlan(user);
      final currentWordBookId = _resolveCurrentWordBookId(
        books: wordBooks,
        savedId:
            studyPlan?.wordBookId ?? prefs.getString(_currentWordBookIdKey),
        target: user?.targetExam,
      );
      LearningProgress? progress;
      if (user != null) {
        try {
          progress = await _learningRepository.loadLearningProgress(
            DateTime.now(),
          );
        } catch (error) {
          debugPrint('Failed to load remote learning progress: $error');
        }
      }
      final completedLessonIds =
          progress?.completedLessonIds ?? localCompletedLessonIds;
      final todayCompletedLessonIds =
          progress?.todayCompletedLessonIds ?? localTodayCompletedLessonIds;
      final todayReviewWordIds =
          progress?.todayReviewWordIds ?? localTodayReviewWordIds;
      final todayClaimedRewardIds =
          progress?.todayClaimedRewardIds ?? localTodayClaimedRewardIds;
      final lessons = _applyLessonProgression(
        await _learningRepository.listLessonsForWordBook(currentWordBookId),
        completedLessonIds,
      );
      final words = user == null
          ? <CustomWord>[]
          : await _customWordRepository.list(user.uid);
      final lotteryData = await _loadLotteryData(user);
      final reminderSettings = studyPlan == null
          ? _loadReminderSettings(prefs)
          : _reminderSettingsForPlan(studyPlan);
      final sensorySettings = _loadSensorySettings(prefs);
      final privacySettings = _loadPrivacySettings(prefs);
      final userWords = user == null
          ? <UserWord>[]
          : await _userWordRepository.list(user.uid);
      state = state.copyWith(
        isBootstrapped: true,
        isLoading: false,
        user: user,
        wordBooks: wordBooks,
        currentWordBookId: currentWordBookId,
        lessons: lessons,
        customWords: words,
        lotteryPrizes: lotteryData.prizes,
        userAssets: lotteryData.assets,
        userWords: userWords,
        themeMode: _themeModeFromName(prefs.getString(_themeModeKey)),
        locale: _localeFromName(prefs.getString(_localeKey)),
        targetLanguage: prefs.getString(_targetLanguageKey) ?? 'zh',
        reminderSettings: reminderSettings,
        sensorySettings: sensorySettings,
        privacySettings: privacySettings,
        studyPlan: studyPlan,
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayReviewWordIds: todayReviewWordIds,
        todayTrainingSessionIds: todayTrainingSessionIds,
        todayTrainingGameIds: localTodayTrainingGameIds,
        todayTrainingXp: localTodayTrainingXp,
        todayClaimedRewardIds: todayClaimedRewardIds,
      );
      await refreshRewardTasks();
      await refreshNotifications();
      unawaited(_initializeThenScheduleLocalNotifications());
    } catch (error) {
      state = state.copyWith(
        isBootstrapped: false,
        isLoading: false,
        errorMessage: _resolveLocalizations(
          state.locale,
        ).errorStartupFailed(_friendlyError(error)),
      );
    }
  }

  Future<void> updateThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, _themeModeName(mode));
    state = state.copyWith(themeMode: mode);
  }

  Future<void> updateLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> updateTargetLanguage(String code) async {
    state = state.copyWith(targetLanguage: code);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_targetLanguageKey, code);
  }

  Future<void> updateReminderSettings(DailyReminderSettings settings) async {
    final plan = state.studyPlan;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      StudyPlan? savedPlan;
      if (plan != null) {
        savedPlan = await _studyPlanRepository.save(
          plan.copyWith(
            reminderTime: settings.formattedTime,
            status: settings.enabled ? 'active' : 'paused',
            updatedAt: DateTime.now(),
          ),
        );
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reminderKey, jsonEncode(settings.toJson()));
      state = state.copyWith(
        isLoading: false,
        reminderSettings: settings,
        studyPlan: savedPlan ?? plan,
      );
      unawaited(_scheduleLocalNotifications());
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> updateSensorySettings(SensorySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sensoryKey, jsonEncode(settings.toJson()));
    state = state.copyWith(sensorySettings: settings);
  }

  Future<void> updatePrivacySettings(UserPrivacySettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_privacyKey, jsonEncode(settings.toJson()));
    if (AppConstants.apiBaseUrl.isNotEmpty) {
      try {
        final client = ref.read(apiClientProvider);
        await client.dio.put<void>(
          '/privacy',
          data: settings.toJson(),
        );
      } catch (e) {
        debugPrint('Failed to sync privacy settings to backend: $e');
      }
    }
    state = state.copyWith(privacySettings: settings);
  }

  Future<void> _applyAuthenticatedUser(UserProfile user) async {
    final lotteryData = await _loadLotteryData(user);
    state = state.copyWith(
      user: user,
      customWords: await _customWordRepository.list(user.uid),
      lotteryPrizes: lotteryData.prizes,
      userAssets: lotteryData.assets,
      userWords: await _userWordRepository.list(user.uid),
    );
    await _ensureStudyPlan(user);
    await refreshNotifications();
    await refreshRewardTasks();
    unawaited(_scheduleLocalNotifications());
  }

  Future<AuthStep> register(String name, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );
      if (result is AuthVerificationRequired) {
        state = state.copyWith(isLoading: false);
        return AuthStep.needsVerification;
      }
      await _applyAuthenticatedUser((result as AuthSuccess).profile);
      state = state.copyWith(isLoading: false);
      return AuthStep.authenticated;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return AuthStep.failed;
    }
  }

  Future<AuthStep> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user =
          await _authRepository.login(email: email, password: password);
      await _applyAuthenticatedUser(user);
      state = state.copyWith(isLoading: false);
      return AuthStep.authenticated;
    } on EmailNotVerifiedException {
      state = state.copyWith(isLoading: false);
      return AuthStep.needsVerification;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return AuthStep.failed;
    }
  }

  Future<bool> verifyEmail({
    required String email,
    required String code,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user =
          await _authRepository.verifyEmail(email: email, code: code);
      await _applyAuthenticatedUser(user);
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

  Future<void> resendCode(String email) async {
    try {
      await _authRepository.resendCode(email);
    } catch (_) {
      // Best-effort; the screen shows its own cooldown feedback.
    }
  }

  Future<bool> enterDemo() async {
    return _run(() async {
      final user = UserProfile.demo();
      final lotteryData = await _loadLotteryData(user);
      state = state.copyWith(
        user: user,
        customWords: await _customWordRepository.list(user.uid),
        lotteryPrizes: lotteryData.prizes,
        userAssets: lotteryData.assets,
        userWords: await _userWordRepository.list(user.uid),
      );
      await _ensureStudyPlan(user);
      await refreshNotifications();
      await refreshRewardTasks();
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
      final wordBookId = _wordBookIdForTarget(targetExam, state.wordBooks);
      final targetLessons = await _learningRepository.listLessonsForWordBook(
        wordBookId,
      );
      final plannedDailyGoal = deadline == null
          ? dailyGoal
          : _dailyWordsForDeadline(deadline: deadline, lessons: targetLessons);
      final plan = _buildStudyPlan(
        uid: user.uid,
        target: targetExam,
        dailyGoal: plannedDailyGoal,
        targetFinishDate: deadline,
        wordBookId: wordBookId,
      );
      final updated = await _authRepository.updateProfile(
        user.copyWith(
          targetExam: targetExam,
          level: level,
          dailyGoal: plan.dailyNewTarget,
          updatedAt: DateTime.now(),
        ),
      );
      final savedPlan = await _studyPlanRepository.save(plan);
      final reminderSettings = _reminderSettingsForPlan(savedPlan);
      await _persistReminderSettings(reminderSettings);
      await _saveCurrentWordBookId(savedPlan.wordBookId);
      final lessons = _applyLessonProgression(
        targetLessons,
        state.completedLessonIds,
      );
      state = state.copyWith(
        user: updated,
        studyPlan: savedPlan,
        reminderSettings: reminderSettings,
        currentWordBookId: savedPlan.wordBookId,
        lessons: lessons,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> updateStudyPlan(StudyPlan plan) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final wordBookId = _wordBookIdForTarget(plan.wordBookId, state.wordBooks);
      final targetExam = targetForStudyBookId(wordBookId);
      final saved = await _studyPlanRepository.save(
        plan.copyWith(
          uid: user.uid,
          wordBookId: wordBookId,
          updatedAt: DateTime.now(),
        ),
      );
      final reminderSettings = _reminderSettingsForPlan(saved);
      await _persistReminderSettings(reminderSettings);
      await _saveCurrentWordBookId(saved.wordBookId);
      final lessons = _applyLessonProgression(
        await _learningRepository.listLessonsForWordBook(saved.wordBookId),
        state.completedLessonIds,
      );
      final updatedUser = await _authRepository.updateProfile(
        user.copyWith(
          targetExam: targetExam,
          dailyGoal: saved.dailyNewTarget,
          updatedAt: DateTime.now(),
        ),
      );
      state = state.copyWith(
        user: updatedUser,
        studyPlan: saved,
        reminderSettings: reminderSettings,
        currentWordBookId: saved.wordBookId,
        lessons: lessons,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> toggleStudyPlanPaused() async {
    final plan = state.studyPlan;
    if (plan == null) return false;
    return updateStudyPlan(
      plan.copyWith(status: plan.isPaused ? 'active' : 'paused'),
    );
  }

  Future<bool> resetStudyPlan() async {
    final user = state.user;
    final plan = state.studyPlan;
    if (user == null || plan == null) return false;
    return _run(() async {
      final resetPlan = await _studyPlanRepository.reset(plan);
      final reminderSettings = _reminderSettingsForPlan(resetPlan);
      await _persistReminderSettings(reminderSettings);
      final resetAt = resetPlan.updatedAt;
      final resetWords = state.customWords
          .map(
            (word) => word.copyWith(
              masteryLevel: 0,
              correctCount: 0,
              wrongCount: 0,
              nextReviewAt: resetAt,
              updatedAt: resetAt,
            ),
          )
          .toList();
      await _saveLessonProgress(<String>{}, <String>{}, resetAt);
      await _saveTodayReviewWords(<String>{}, resetAt);
      state = state.copyWith(
        studyPlan: resetPlan,
        reminderSettings: reminderSettings,
        customWords: resetWords,
        completedLessonIds: {},
        todayCompletedLessonIds: {},
        todayReviewWordIds: {},
        lessons: _applyLessonProgression(state.lessons, <String>{}),
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> switchWordBook(String wordBookId) async {
    if (!_hasWordBook(wordBookId)) return false;
    return _run(() async {
      final lessons = _applyLessonProgression(
        await _learningRepository.listLessonsForWordBook(wordBookId),
        state.completedLessonIds,
      );
      final book = _wordBookById(state.wordBooks, wordBookId);
      var updatedUser = state.user;
      var savedPlan = state.studyPlan;
      var reminderSettings = state.reminderSettings;
      if (updatedUser != null && book != null) {
        updatedUser = await _authRepository.updateProfile(
          updatedUser.copyWith(
            targetExam: book.examType,
            updatedAt: DateTime.now(),
          ),
        );
        final plan =
            savedPlan ??
            _buildStudyPlan(
              uid: updatedUser.uid,
              target: book.examType,
              dailyGoal: updatedUser.dailyGoal,
              wordBookId: wordBookId,
            );
        savedPlan = await _studyPlanRepository.save(
          plan.copyWith(wordBookId: wordBookId, updatedAt: DateTime.now()),
        );
        reminderSettings = _reminderSettingsForPlan(savedPlan);
        await _persistReminderSettings(reminderSettings);
      }
      await _saveCurrentWordBookId(wordBookId);
      state = state.copyWith(
        user: updatedUser,
        currentWordBookId: wordBookId,
        lessons: lessons,
        studyPlan: savedPlan,
        reminderSettings: reminderSettings,
      );
      await refreshNotifications();
      await refreshRewardTasks();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<void> logout() async {
    final themeMode = state.themeMode;
    final reminderSettings = state.reminderSettings;
    final wordBooks = state.wordBooks;
    final currentWordBookId = state.currentWordBookId;
    final lessons = state.lessons;
    final completedLessonIds = state.completedLessonIds;
    await _authRepository.logout();
    state = AppState.initial().copyWith(
      isBootstrapped: true,
      wordBooks: wordBooks,
      currentWordBookId: currentWordBookId,
      lessons: _applyLessonProgression(lessons, completedLessonIds),
      completedLessonIds: completedLessonIds,
      themeMode: themeMode,
      reminderSettings: reminderSettings,
      notifications: [],
      lotteryPrizes: [],
      userAssets: [],
      clearLastResult: true,
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
    List<String> definitions = const [],
    List<String> englishDefinitions = const [],
    List<String> malayDefinitions = const [],
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
          definitions: definitions,
          englishDefinitions: englishDefinitions,
          malayDefinitions: malayDefinitions,
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

  Future<bool> completeLesson(
    LessonResult result, {
    bool isTrainingChallenge = false,
  }) async {
    final user = state.user;
    if (user == null) return false;
    if (state.isStudyPlanPaused) {
      state = state.copyWith(
        errorMessage: _resolveLocalizations(
          state.locale,
        ).errorPlanPausedNewLearning,
      );
      return false;
    }
    return _run(() async {
      final now = DateTime.now();
      final lastStudy = user.lastStudyDate?.toLocal();
      final streak = _nextStreak(lastStudy, now, user.streak);
      final completedLessonIds = {...state.completedLessonIds, result.lessonId};
      final lesson = _lessonById(result.lessonId);
      final isTraining = lesson?.isTrainingPack ?? false;
      final shouldAdvanceLesson = !isTraining;
      final todayState = await _normalizeTodayState(now);
      final todayCompletedLessonIds = {
        ...todayState.completedLessonIds,
        if (shouldAdvanceLesson) result.lessonId,
      };
      final todayTrainingSessionIds = {
        ...todayState.trainingSessionIds,
        if (isTraining) result.lessonId,
      };
      final pointGrant = await _grantPointsBestEffort(
        user: user,
        sourceType: isTraining ? 'training_session' : 'study_lesson',
        sourceId: isTraining
            ? '${result.lessonId}:${_dateKey(result.completedAt)}'
            : result.lessonId,
        points: result.xpEarned,
        description: isTraining ? '完成训练场挑战' : '完成新学课程',
      );
      final resolvedResult = result.copyWith(
        xpEarned: pointGrant.awarded ? pointGrant.pointsAwarded : 0,
      );
      final updatedUser = await _authRepository.updateProfile(
        pointGrant.user.copyWith(
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
          xpEarned: resolvedResult.xpEarned,
          mistakeWordIds: result.mistakes
              .map((question) => question.word.id)
              .toList(),
        ),
      );
      if (shouldAdvanceLesson) {
        await _saveLessonProgress(
          completedLessonIds,
          todayCompletedLessonIds,
          now,
        );
      }
      if (isTraining) {
        await _saveTodayTrainingSessions(todayTrainingSessionIds, now);
      }
      final learnedUserWords = await _recordLessonUserWords(
        uid: user.uid,
        result: result,
        now: now,
      );
      state = state.copyWith(
        user: updatedUser,
        lessons: shouldAdvanceLesson
            ? _applyLessonProgression(state.lessons, completedLessonIds)
            : state.lessons,
        completedLessonIds: shouldAdvanceLesson
            ? completedLessonIds
            : state.completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayTrainingSessionIds: todayTrainingSessionIds,
        userWords: _mergeUserWords(state.userWords, learnedUserWords),
        lastResult: resolvedResult,
      );
      try {
        final isTrainingReward =
            isTrainingChallenge || _isTrainingLessonId(result.lessonId);
        await _applyRewardSnapshot(
          await _rewardTaskRepository.recordEvent(
            user.uid,
            isTrainingReward
                ? RewardEventType.trainingChallenge
                : RewardEventType.newLearning,
          ),
        );
      } catch (error) {
        debugPrint('Failed to record lesson reward event: $error');
      }
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> reviewWord(
    String id,
    bool isCorrect, {
    ReviewDimension dimension = ReviewDimension.confidence,
    int answerTimeMs = 0,
    int confidence = 3,
    String? wrongOption,
  }) async {
    final user = state.user;
    if (user == null) return false;
    if (state.isStudyPlanPaused) {
      state = state.copyWith(
        errorMessage: _resolveLocalizations(state.locale).errorPlanPausedReview,
      );
      return false;
    }
    final targetWord = _userWordByReviewId(id);
    if (targetWord != null) {
      return _reviewUserWord(
        user.uid,
        targetWord,
        isCorrect,
        dimension: dimension,
        answerTimeMs: answerTimeMs,
        confidence: confidence,
        wrongOption: wrongOption,
      );
    }
    final word = _customWordById(id);
    if (word == null) return false;
    final now = DateTime.now();
    if (isCorrect && !word.isDue(now)) {
      state = state.copyWith(
        errorMessage: _resolveLocalizations(
          state.locale,
        ).errorCardReviewedToday,
      );
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
          answerTimeMs: answerTimeMs,
          confidence: confidence,
          wrongOption: isCorrect ? null : wrongOption,
          reviewedAt: now,
          masteryBefore: word.masteryLevel,
          masteryAfter: reviewed.masteryLevel,
          nextReviewAt: reviewed.nextReviewAt,
        ),
      );
      final todayState = await _normalizeTodayState(now);
      final todayReviewWordIds = {...todayState.reviewWordIds, id};
      final rewardedUser = isCorrect
          ? await _grantPointsBestEffort(
              user: user,
              sourceType: 'review_word',
              sourceId: '$id:${_dateKey(now)}',
              points: 3,
              description: '完成到期复习',
            )
          : _PointGrantOutcome(
              user: user,
              awarded: false,
              alreadyGranted: false,
              pointsAwarded: 0,
            );
      await _saveTodayReviewWords(todayReviewWordIds, now);
      state = state.copyWith(
        user: rewardedUser.user,
        customWords: [
          for (final item in state.customWords) item.id == id ? reviewed : item,
        ],
        todayReviewWordIds: todayReviewWordIds,
      );
      try {
        if (isCorrect && word.wrongCount > 0) {
          await _applyRewardSnapshot(
            await _rewardTaskRepository.recordEvent(
              user.uid,
              RewardEventType.wrongCleanup,
            ),
          );
        } else {
          await _applyRewardSnapshot(
            await _rewardTaskRepository.recordEvent(
              user.uid,
              RewardEventType.reviewDone,
            ),
          );
        }
      } catch (error) {
        debugPrint('Failed to record review reward events: $error');
      }
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> checkInToday() async {
    final user = state.user;
    if (user == null || state.pendingRewardTaskIds.contains('dailyCheckIn')) {
      return false;
    }
    state = state.copyWith(
      pendingRewardTaskIds: {...state.pendingRewardTaskIds, 'dailyCheckIn'},
      clearError: true,
    );
    try {
      final snapshot = await _rewardTaskRepository.checkIn(user.uid);
      await _applyRewardSnapshot(snapshot);
      if (snapshot.user == null) {
        final now = DateTime.now();
        final updated = await _authRepository.updateProfile(
          user.copyWith(
            streak: _nextStreak(user.lastStudyDate?.toLocal(), now, user.streak),
            lastStudyDate: now,
            updatedAt: now,
          ),
        );
        state = state.copyWith(user: updated);
      }
      state = state.copyWith(
        pendingRewardTaskIds: state.pendingRewardTaskIds
            .where((id) => id != 'dailyCheckIn')
            .toSet(),
      );
      await refreshNotifications();
      return true;
    } catch (error) {
      state = state.copyWith(
        pendingRewardTaskIds: state.pendingRewardTaskIds
            .where((id) => id != 'dailyCheckIn')
            .toSet(),
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> claimReward(String id) async {
    final user = state.user;
    if (user == null || state.pendingRewardTaskIds.contains(id)) return false;
    final task = _rewardTaskById(id);
    if (task == null || !task.isClaimable) return false;
    state = state.copyWith(
      pendingRewardTaskIds: {...state.pendingRewardTaskIds, id},
      clearError: true,
    );
    try {
      final snapshot = await _rewardTaskRepository.claimTask(user.uid, id);
      await _applyRewardSnapshot(snapshot);
      final credited = snapshot.claimed == true && !snapshot.alreadyClaimed;
      if (snapshot.user == null) {
        if (credited) {
          final updated = await _authRepository.updateProfile(
            user.copyWith(xp: user.xp + task.points, updatedAt: DateTime.now()),
          );
          state = state.copyWith(user: updated);
        }
      }
      state = state.copyWith(
        pendingRewardTaskIds: state.pendingRewardTaskIds
            .where((taskId) => taskId != id)
            .toSet(),
        errorMessage: snapshot.alreadyClaimed
            ? _resolveLocalizations(state.locale).errorTaskClaimedToday
            : null,
        clearError: !snapshot.alreadyClaimed,
      );
      await refreshNotifications();
      return credited;
    } catch (error) {
      state = state.copyWith(
        pendingRewardTaskIds: state.pendingRewardTaskIds
            .where((taskId) => taskId != id)
            .toSet(),
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> recordForumInteraction() async {
    final user = state.user;
    if (user == null ||
        state.pendingRewardTaskIds.contains('forumInteraction')) {
      return false;
    }
    state = state.copyWith(
      pendingRewardTaskIds: {...state.pendingRewardTaskIds, 'forumInteraction'},
      clearError: true,
    );
    try {
      final snapshot = await _rewardTaskRepository.recordEvent(
        user.uid,
        RewardEventType.forumInteraction,
      );
      await _applyRewardSnapshot(snapshot);
      state = state.copyWith(
        pendingRewardTaskIds: state.pendingRewardTaskIds
            .where((id) => id != 'forumInteraction')
            .toSet(),
      );
      return true;
    } catch (error) {
      state = state.copyWith(
        pendingRewardTaskIds: state.pendingRewardTaskIds
            .where((id) => id != 'forumInteraction')
            .toSet(),
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  Future<void> refreshRewardTasks() async {
    final user = state.user;
    if (user == null) {
      state = state.copyWith(
        rewardTasks: [],
        pendingRewardTaskIds: {},
        isRewardLoading: false,
      );
      return;
    }
    if (state.isRewardLoading) return;
    state = state.copyWith(isRewardLoading: true, clearError: true);
    try {
      await _applyRewardSnapshot(await _rewardTaskRepository.listTasks(user.uid));
      state = state.copyWith(isRewardLoading: false);
    } catch (error) {
      state = state.copyWith(
        isRewardLoading: false,
        errorMessage: _friendlyError(error),
      );
    }
  }

  Future<void> _applyRewardSnapshot(RewardTaskSnapshot snapshot) async {
    final user = snapshot.user;
    state = state.copyWith(
      user: user,
      rewardTasks: snapshot.tasks,
      todayClaimedRewardIds: {
        for (final task in snapshot.tasks)
          if (task.isClaimed) task.id,
      },
    );
    if (user != null) {
      if (_authRepository is MockAuthRepository) {
        await _authRepository.updateProfile(user);
      }
    }
  }

  DailyRewardTask? _rewardTaskById(String id) {
    for (final task in state.rewardTasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  Future<bool> completeMixedStudySession({
    required String lessonId,
    required int totalQuestions,
    required int correctAnswers,
    required List<String> mistakeWordIds,
    required List<Map<String, dynamic>> answerEvents,
    required DateTime startedAt,
    required DateTime endedAt,
    bool completeCurrentLesson = false,
    int xpEarned = 0,
  }) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final now = endedAt;
      final lastStudy = user.lastStudyDate;
      final streak = _nextStreak(lastStudy, now, user.streak);
      final currentLesson = completeCurrentLesson ? state.currentLesson : null;
      final completedLessonIds = currentLesson == null
          ? state.completedLessonIds
          : {...state.completedLessonIds, currentLesson.id};
      final todayCompletedLessonIds = currentLesson == null
          ? state.todayCompletedLessonIds
          : {...state.todayCompletedLessonIds, currentLesson.id};
      final updatedUser = await _authRepository.updateProfile(
        user.copyWith(
          xp: user.xp + xpEarned,
          streak: streak,
          lastStudyDate: now,
          updatedAt: now,
        ),
      );
      await _learningRepository.recordStudySession(
        StudySession(
          id: 'session-${now.microsecondsSinceEpoch}',
          uid: user.uid,
          lessonId: lessonId,
          startedAt: startedAt,
          endedAt: endedAt,
          totalQuestions: totalQuestions,
          correctAnswers: correctAnswers,
          xpEarned: xpEarned,
          mistakeWordIds: mistakeWordIds,
          answerEvents: answerEvents,
        ),
      );
      final learnedUserWords = currentLesson == null
          ? <UserWord>[]
          : await _recordLessonUserWords(
              uid: user.uid,
              result: LessonResult(
                lessonId: currentLesson.id,
                lessonTitle: currentLesson.title,
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                xpEarned: xpEarned,
                mistakes: [
                  for (final question in currentLesson.questions)
                    if (mistakeWordIds.contains(question.word.id)) question,
                ],
                completedAt: now,
              ),
              now: now,
            );
      await _saveLessonProgress(completedLessonIds, todayCompletedLessonIds, now);
      state = state.copyWith(
        user: updatedUser,
        lessons: _applyLessonProgression(state.lessons, completedLessonIds),
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        userWords: _mergeUserWords(state.userWords, learnedUserWords),
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
    int answerTimeMs = 0,
    int confidence = 3,
    String? wrongOption,
  }) async {
    final now = DateTime.now();
    if (isCorrect && !word.isDue(now)) {
      state = state.copyWith(
        errorMessage: _resolveLocalizations(
          state.locale,
        ).errorTargetReviewedToday,
      );
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
          answerTimeMs: answerTimeMs,
          confidence: confidence,
          wrongOption: isCorrect ? null : wrongOption,
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
      await _saveTodayReviewWords(todayReviewWordIds, now);
      state = state.copyWith(
        userWords: _mergeUserWords(state.userWords, [saved]),
        todayReviewWordIds: todayReviewWordIds,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> claimLocalReward({
    required String id,
    required int points,
    required bool isAvailable,
  }) async {
    final user = state.user;
    if (user == null || points <= 0 || !isAvailable) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final now = DateTime.now();
      final todayState = await _normalizeTodayState(now);
      if (todayState.claimedRewardIds.contains(id)) {
        state = state.copyWith(isLoading: false);
        return false;
      }
      final claimedRewardIds = {...todayState.claimedRewardIds, id};
      final pointGrant = await _grantPoints(
        user: user,
        sourceType: 'reward_task',
        sourceId: '$id:${_dateKey(now)}',
        points: points,
        description: '领取积分任务奖励',
      );
      if (pointGrant.alreadyGranted) {
        await _saveTodayClaimedRewards(claimedRewardIds, now);
        state = state.copyWith(
          isLoading: false,
          user: pointGrant.user.copyWith(updatedAt: now),
          todayClaimedRewardIds: claimedRewardIds,
        );
        await refreshNotifications();
        return true;
      }
      await _saveTodayClaimedRewards(claimedRewardIds, now);
      state = state.copyWith(
        isLoading: false,
        user: pointGrant.user.copyWith(updatedAt: now),
        todayClaimedRewardIds: claimedRewardIds,
      );
      await refreshNotifications();
      return true;
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: _friendlyError(error),
      );
      return false;
    }
  }

  Future<bool> drawLottery() async {
    final user = state.user;
    if (user == null) return false;
    if (user.xp < lotteryDrawCost) {
      state = state.copyWith(
        errorMessage: _resolveLocalizations(
          state.locale,
        ).errorInsufficientXp(user.xp, lotteryDrawCost),
      );
      return false;
    }
    return _run(() async {
      final response = await _lotteryRepository.draw(
        uid: user.uid,
        currentXp: user.xp,
      );
      if (response.notifications.isNotEmpty) {
        await _notificationRepository.ensureGenerated(
          user.uid,
          response.notifications,
        );
      }
      final updatedUser =
          response.user ??
          user.copyWith(
            xp: response.result.balanceAfter,
            updatedAt: DateTime.now(),
          );
      final assets = await _lotteryRepository.assets(user.uid);
      final notifications = await _notificationRepository.list(user.uid);
      state = state.copyWith(
        user: updatedUser,
        userAssets: assets,
        lastLotteryResult: response.result,
        notifications: notifications,
      );
    });
  }

  Future<({List<LotteryPrize> prizes, List<UserAsset> assets})>
  _loadLotteryData(UserProfile? user) async {
    if (user == null) {
      return (prizes: <LotteryPrize>[], assets: <UserAsset>[]);
    }
    try {
      final (prizes, assets) = await (
        _lotteryRepository.prizePool(),
        _lotteryRepository.assets(user.uid),
      ).wait;
      return (prizes: prizes, assets: assets);
    } catch (error) {
      debugPrint('Failed to load lottery data: $error');
      return (prizes: <LotteryPrize>[], assets: <UserAsset>[]);
    }
  }

  Future<bool> completeTraining({
    required LessonResult result,
    required String gameId,
    required DateTime startedAt,
    required List<ExerciseRecord> exerciseRecords,
  }) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final now = DateTime.now();
      final lastStudy = user.lastStudyDate;
      final streak = _nextStreak(lastStudy, now, user.streak);
      final sessionId = 'training-${now.microsecondsSinceEpoch}';
      await _learningRepository.recordStudySession(
        StudySession(
          id: sessionId,
          uid: user.uid,
          lessonId: gameId,
          startedAt: startedAt,
          endedAt: now,
          totalQuestions: result.totalQuestions,
          correctAnswers: result.correctAnswers,
          xpEarned: result.xpEarned,
          mistakeWordIds: result.mistakes
              .map((question) => question.word.id)
              .toList(),
        ),
      );
      await _learningRepository.recordExerciseRecords(
        exerciseRecords
            .map(
              (record) => ExerciseRecord(
                id: record.id,
                uid: user.uid,
                sessionId: sessionId,
                gameId: record.gameId,
                wordId: record.wordId,
                promptType: record.promptType,
                isCorrect: record.isCorrect,
                answer: record.answer,
                correctAnswer: record.correctAnswer,
                answerTimeMs: record.answerTimeMs,
                dimension: record.dimension,
                createdAt: record.createdAt,
              ),
            )
            .toList(),
      );
      final customWords = await _applyTrainingWordUpdates(
        uid: user.uid,
        mistakes: result.mistakes,
        records: exerciseRecords,
        now: now,
      );
      final todayTrainingGameIds = {...state.todayTrainingGameIds, gameId};
      final todayTrainingXp = state.todayTrainingXp + result.xpEarned;
      final updatedUser = await _authRepository.updateProfile(
        user.copyWith(
          xp: user.xp + result.xpEarned,
          streak: streak,
          lastStudyDate: now,
          updatedAt: now,
        ),
      );
      await _saveTodayTraining(todayTrainingGameIds, todayTrainingXp);
      state = state.copyWith(
        user: updatedUser,
        customWords: customWords,
        todayTrainingGameIds: todayTrainingGameIds,
        todayTrainingXp: todayTrainingXp,
        lastResult: result,
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<List<CustomWord>> _applyTrainingWordUpdates({
    required String uid,
    required List<QuizQuestion> mistakes,
    required List<ExerciseRecord> records,
    required DateTime now,
  }) async {
    final updatedById = {for (final word in state.customWords) word.id: word};
    final byText = {
      for (final word in state.customWords)
        word.word.trim().toLowerCase(): word,
    };
    final wordIdToText = {
      for (final word in state.trainingWords) word.id: word.word,
    };
    final mistakesByWordId = {
      for (final question in mistakes) question.word.id: question,
    };

    for (final record in records) {
      final englishWord = wordIdToText[record.wordId];
      final existing =
          updatedById[record.wordId] ??
          (englishWord == null
              ? null
              : byText[englishWord.trim().toLowerCase()]);
      if (existing == null) continue;
      final updated = _trainingAdjustedWord(existing, record, now);
      await _customWordRepository.update(updated);
      updatedById[updated.id] = updated;
      byText[updated.word.trim().toLowerCase()] = updated;
    }

    for (final question in mistakesByWordId.values) {
      final normalized = question.word.word.trim().toLowerCase();
      if (byText.containsKey(normalized)) continue;
      final created = await _customWordRepository.create(
        CustomWord.create(
          id: 'training-mistake-${question.word.id}-${now.microsecondsSinceEpoch}',
          uid: uid,
          word: question.word.word,
          meaning: question.word.meaning,
          exampleSentence: question.word.exampleSentence,
          note: '${question.word.definition}\n${question.explanation}',
          tag: question.word.tags.isEmpty
              ? '错题'
              : displayWordTag(question.word.tags.first),
          difficulty: question.word.difficulty,
          now: now,
        ).copyWith(
          status: 'Relearning',
          masteryLevel: 0,
          wrongCount: 1,
          nextReviewAt: now.add(const Duration(hours: 2)),
          updatedAt: now,
        ),
      );
      updatedById[created.id] = created;
      byText[normalized] = created;
    }

    return updatedById.values.toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  CustomWord _trainingAdjustedWord(
    CustomWord word,
    ExerciseRecord record,
    DateTime now,
  ) {
    final scoreDelta = record.isCorrect ? 4 : -8;
    int adjust(ReviewDimension target, int current) {
      if (target != record.dimension) return current;
      return (current + scoreDelta).clamp(0, 100).toInt();
    }

    return word.copyWith(
      status: record.isCorrect ? word.status : 'Relearning',
      correctCount: word.correctCount + (record.isCorrect ? 1 : 0),
      wrongCount: word.wrongCount + (record.isCorrect ? 0 : 1),
      masteryLevel: record.isCorrect
          ? word.masteryLevel
          : (word.masteryLevel - 1).clamp(0, 5).toInt(),
      meaningRecognitionScore: adjust(
        ReviewDimension.meaningRecognition,
        word.meaningRecognitionScore,
      ),
      meaningRecallScore: adjust(
        ReviewDimension.meaningRecall,
        word.meaningRecallScore,
      ),
      spellingScore: adjust(ReviewDimension.spelling, word.spellingScore),
      listeningScore: adjust(ReviewDimension.listening, word.listeningScore),
      contextScore: adjust(ReviewDimension.context, word.contextScore),
      confidenceScore: adjust(ReviewDimension.confidence, word.confidenceScore),
      nextReviewAt: record.isCorrect
          ? word.nextReviewAt
          : now.add(const Duration(hours: 2)),
      updatedAt: now,
    );
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
      if (message == 'task_not_complete') {
        return '该任务尚未完成，无法领取奖励。';
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

  bool _isTrainingLessonId(String lessonId) {
    for (final lesson in state.lessons) {
      if (lesson.id == lessonId) return lesson.isTrainingPack;
    }
    return lessonId.startsWith('lesson-campus-');
  }

  Future<_PointGrantOutcome> _grantPoints({
    required UserProfile user,
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  }) async {
    if (points <= 0) {
      return _PointGrantOutcome(
        user: user,
        awarded: false,
        alreadyGranted: false,
        pointsAwarded: 0,
      );
    }
    final result = await _rewardRepository.grantPoints(
      uid: user.uid,
      sourceType: sourceType,
      sourceId: sourceId,
      points: points,
      description: description,
    );
    return _PointGrantOutcome(
      user: await _rewardedUser(user, result),
      awarded: result.awarded,
      alreadyGranted: result.alreadyGranted,
      pointsAwarded: result.pointsAwarded,
    );
  }

  Future<_PointGrantOutcome> _grantPointsBestEffort({
    required UserProfile user,
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  }) async {
    try {
      return await _grantPoints(
        user: user,
        sourceType: sourceType,
        sourceId: sourceId,
        points: points,
        description: description,
      );
    } catch (error) {
      debugPrint('Point grant skipped: $error');
      return _PointGrantOutcome(
        user: user,
        awarded: false,
        alreadyGranted: false,
        pointsAwarded: 0,
      );
    }
  }

  Future<UserProfile> _rewardedUser(
    UserProfile user,
    PointGrantResult result,
  ) async {
    if (result.user != null) return result.user!;
    if (!result.awarded) return user;
    return await _authRepository.updateProfile(
      user.copyWith(
        xp: user.xp + result.pointsAwarded,
        updatedAt: DateTime.now(),
      ),
    );
  }

  StudyPlan _buildStudyPlan({
    required String uid,
    required String target,
    required int dailyGoal,
    DateTime? targetFinishDate,
    String? wordBookId,
  }) {
    final normalizedWordBookId = _wordBookIdForTarget(
      wordBookId ?? target,
      state.wordBooks,
    );
    return StudyPlan.defaultsFor(
      uid: uid,
      targetExam: target,
      dailyGoal: dailyGoal,
      targetFinishDate: targetFinishDate,
    ).copyWith(wordBookId: normalizedWordBookId);
  }

  int _dailyWordsForDeadline({
    required DateTime deadline,
    required List<Lesson> lessons,
  }) {
    final completed = state.completedLessonIds;
    final remainingWords = lessons
        .where(
          (lesson) => !lesson.isTrainingPack && !completed.contains(lesson.id),
        )
        .fold(0, (total, lesson) => total + lesson.words.length);
    final now = DateTime.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(deadline.year, deadline.month, deadline.day);
    final days = targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
    if (remainingWords == 0) return 1;
    return ((remainingWords + days - 1) ~/ days).clamp(1, 999).toInt();
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

  List<AppNotification> _buildGeneratedNotifications(String uid, DateTime now) {
    final dateKey = _dateKey(now);
    final notifications = <AppNotification>[];
    final dueCount = state.reviewQueue.length;
    final dailyGoal = state.dailyNewTarget;
    final todayWork =
        state.todayLearningWords + state.todayReviewWordIds.length;
    final hasStudyToday =
        state.todayCompletedFormalLessonIds.isNotEmpty ||
        todayWork >= dailyGoal;
    final hasCheckedIn = state.rewardTasks.any(
      (task) =>
          task.id == 'dailyCheckIn' && (task.isClaimable || task.isClaimed),
    );

    if (!state.isStudyPlanPaused && !hasStudyToday) {
      notifications.add(
        _generatedNotification(
          uid: uid,
          type: AppNotificationType.learningReminder,
          title: '今日学习计划待完成',
          body: '今天目标新学 $dailyGoal 词，先从当前词书开始。',
          targetRoute: '/study/new',
          sourceKey: 'learningReminder:$dateKey',
          now: now,
          params: {'dailyGoal': dailyGoal},
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
          params: {'dueCount': dueCount},
        ),
      );
    }
    if (!hasCheckedIn) {
      notifications.add(
        _generatedNotification(
          uid: uid,
          type: AppNotificationType.checkInReminder,
          title: '今天还没有打卡',
          body: '去发现页点击签到，签到任务会进入可领取状态。',
          targetRoute: '/discover',
          sourceKey: 'checkInReminder:$dateKey',
          now: now,
          params: const {'kind': 'checkin'},
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
        params: const {'kind': 'activity'},
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
    Map<String, dynamic>? params,
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
      params: params,
    );
  }

  Future<void> _scheduleLocalNotifications() async {
    if (!ref.mounted) return;
    final snapshot = state;
    final user = snapshot.user;
    final reminderSettings = snapshot.reminderSettings;
    final dueCount = user == null || snapshot.isStudyPlanPaused
        ? 0
        : snapshot.reviewQueue.length;
    final l10n = _resolveLocalizations(snapshot.locale);
    final strings = LocalNotificationStrings.fromL10n(l10n);
    await _localNotificationService.scheduleDailyStudyReminder(
      enabled:
          user != null &&
          reminderSettings.enabled &&
          !snapshot.isStudyPlanPaused,
      hour: reminderSettings.hour,
      minute: reminderSettings.minute,
      strings: strings,
    );
    await _localNotificationService.scheduleReviewDueReminder(
      dueCount: dueCount,
      title: l10n.notificationReviewDueTitle(dueCount),
      strings: strings,
    );
  }

  /// Resolves [AppLocalizations] for the OS push, which fires outside any
  /// widget context. Prefers the in-app [locale] setting; otherwise clamps the
  /// platform locale to the supported set, defaulting to the app default (zh).
  AppLocalizations _resolveLocalizations(Locale? locale) {
    final supported = AppLocalizations.supportedLocales;
    bool isSupported(Locale candidate) =>
        supported.any((l) => l.languageCode == candidate.languageCode);

    Locale resolved;
    if (locale != null && isSupported(locale)) {
      resolved = locale;
    } else {
      final platform = PlatformDispatcher.instance.locale;
      resolved = isSupported(platform) ? platform : const Locale('zh');
    }
    return lookupAppLocalizations(resolved);
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

  Future<void> _saveCurrentWordBookId(String wordBookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentWordBookIdKey, wordBookId);
  }

  String _resolveCurrentWordBookId({
    required List<WordBook> books,
    required String? savedId,
    required String? target,
  }) {
    if (books.isEmpty) return savedId ?? 'hsk1';
    if (savedId != null && _wordBookById(books, savedId) != null) {
      return savedId;
    }
    final targetId = _wordBookIdForTarget(target, books);
    if (_wordBookById(books, targetId) != null) return targetId;
    return books.first.id;
  }

  String _wordBookIdForTarget(String? target, List<WordBook> books) {
    final normalized = target?.trim().toLowerCase() ?? '';
    final mapped = _mappedWordBookId(normalized);
    if (_wordBookById(books, mapped) != null) return mapped;
    for (final book in books) {
      final title = book.title.toLowerCase();
      final examType = book.examType.toLowerCase();
      if (normalized.isNotEmpty &&
          (title.contains(normalized) || examType.contains(normalized))) {
        return book.id;
      }
    }
    return books.isEmpty ? mapped : books.first.id;
  }

  // Only the HSK 1 book ships today; every target maps to it. (The
  // _wordBookIdForTarget title/examType fallback above still adapts if more
  // books are added later.)
  String _mappedWordBookId(String normalizedTarget) => 'hsk1';

  bool _hasWordBook(String wordBookId) {
    return _wordBookById(state.wordBooks, wordBookId) != null;
  }

  WordBook? _wordBookById(List<WordBook> books, String id) {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  Future<void> _saveLessonProgress(
    Set<String> completedLessonIds,
    Set<String> todayCompletedLessonIds,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _completedLessonIdsKey,
      completedLessonIds.toList(),
    );
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _todayLessonIdsKey,
      todayCompletedLessonIds.toList(),
    );
  }

  Future<void> _saveTodayReviewWords(
    Set<String> todayReviewWordIds,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(_todayReviewIdsKey, todayReviewWordIds.toList());
  }

  Future<void> _saveTodayTrainingSessions(
    Set<String> todayTrainingSessionIds,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _todayTrainingIdsKey,
      todayTrainingSessionIds.toList(),
    );
  }

  Future<void> _saveTodayTraining(Set<String> gameIds, int xp) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(DateTime.now()));
    await prefs.setStringList(_todayTrainingGameIdsKey, gameIds.toList());
    await prefs.setInt(_todayTrainingXpKey, xp);
  }

  Future<void> _saveTodayClaimedRewards(
    Set<String> todayClaimedRewardIds,
    DateTime now,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _todayRewardIdsKey,
      todayClaimedRewardIds.toList(),
    );
  }

  Future<_TodayStateSnapshot> _normalizeTodayState(DateTime now) async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(now);
    if (prefs.getString(_todayDateKey) == todayKey) {
      return _TodayStateSnapshot(
        completedLessonIds: {...state.todayCompletedLessonIds},
        reviewWordIds: {...state.todayReviewWordIds},
        trainingSessionIds: {...state.todayTrainingSessionIds},
        claimedRewardIds: {...state.todayClaimedRewardIds},
      );
    }

    await prefs.remove(_todayLessonIdsKey);
    await prefs.remove(_todayReviewIdsKey);
    await prefs.remove(_todayTrainingIdsKey);
    await prefs.remove(_todayRewardIdsKey);
    await prefs.setString(_todayDateKey, todayKey);
    state = state.copyWith(
      todayCompletedLessonIds: {},
      todayReviewWordIds: {},
      todayTrainingSessionIds: {},
      todayClaimedRewardIds: {},
    );
    return const _TodayStateSnapshot(
      completedLessonIds: {},
      reviewWordIds: {},
      trainingSessionIds: {},
      claimedRewardIds: {},
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

  Locale? _localeFromName(String? value) {
    if (value == null || value.isEmpty) return null;
    return Locale(value);
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

  SensorySettings _loadSensorySettings(SharedPreferences prefs) {
    final raw = prefs.getString(_sensoryKey);
    if (raw == null) return SensorySettings.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return SensorySettings.defaults;
      return SensorySettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return SensorySettings.defaults;
    }
  }

  UserPrivacySettings _loadPrivacySettings(SharedPreferences prefs) {
    final raw = prefs.getString(_privacyKey);
    if (raw == null) return UserPrivacySettings.defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return UserPrivacySettings.defaults;
      return UserPrivacySettings.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return UserPrivacySettings.defaults;
    }
  }

  Future<void> _persistReminderSettings(DailyReminderSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderKey, jsonEncode(settings.toJson()));
  }

  DailyReminderSettings _reminderSettingsForPlan(StudyPlan plan) {
    final parts = plan.reminderTime.split(':');
    final hour =
        int.tryParse(parts.first) ?? DailyReminderSettings.defaults.hour;
    final minute = parts.length > 1
        ? int.tryParse(parts[1]) ?? DailyReminderSettings.defaults.minute
        : DailyReminderSettings.defaults.minute;
    return DailyReminderSettings(
      enabled: plan.status == 'active',
      hour: hour.clamp(0, 23).toInt(),
      minute: minute.clamp(0, 59).toInt(),
    );
  }

  Future<StudyPlan> _loadOrCreateStudyPlan(UserProfile user) async {
    final existing = await _studyPlanRepository.load(user.uid);
    if (existing != null) return existing;
    return _studyPlanRepository.save(
      _buildStudyPlan(
        uid: user.uid,
        target: user.targetExam,
        dailyGoal: user.dailyGoal,
      ),
    );
  }

  Future<void> _ensureStudyPlan(UserProfile user) async {
    final plan = await _loadOrCreateStudyPlan(user);
    if (ref.mounted && state.user?.uid == user.uid) {
      final reminderSettings = _reminderSettingsForPlan(plan);
      await _persistReminderSettings(reminderSettings);
      state = state.copyWith(
        studyPlan: plan,
        reminderSettings: reminderSettings,
      );
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

  Future<Map<String, dynamic>> askAi({
    required String featureType,
    required String prompt,
    String? targetWord,
  }) async {
    final repo = ref.read(aiRepositoryProvider);
    Map<String, dynamic> result;
    switch (featureType) {
      case 'chat':
        result = await repo.chat(prompt: prompt, targetWord: targetWord);
      case 'sentence_analysis':
        result = await repo.analyzeStatement(prompt: prompt);
      case 'cloze':
        result = await repo.generateCloze(
          prompt: prompt,
          targetWord: targetWord,
        );
      default:
        result = {};
    }
    final history = await repo.listHistory();
    state = state.copyWith(aiHistory: history);
    return result;
  }

  Future<void> deleteAiHistory(String id) async {
    final repo = ref.read(aiRepositoryProvider);
    await repo.deleteHistory(id);
    final history = await repo.listHistory();
    state = state.copyWith(aiHistory: history);
  }

  // ---------------------------------------------------------------------------
  // Forum
  // ---------------------------------------------------------------------------

  Future<void> refreshForumPosts() async {
    try {
      final posts = await _forumRepository.listPosts();
      if (!ref.mounted) return;
      state = state.copyWith(forumPosts: posts);
    } catch (error) {
      debugPrint('Failed to refresh forum posts: $error');
    }
  }

  Future<ForumPost?> createForumPost({
    required String title,
    required String body,
    required String tag,
  }) async {
    try {
      final post = await _forumRepository.createPost(
        title: title,
        body: body,
        tag: tag,
      );
      if (!ref.mounted) return null;
      state = state.copyWith(forumPosts: [post, ...state.forumPosts]);
      return post;
    } catch (error) {
      debugPrint('Failed to create forum post: $error');
      return null;
    }
  }

  Future<ForumComment?> createForumComment({
    required String postId,
    required String body,
  }) async {
    try {
      final comment = await _forumRepository.createComment(
        postId: postId,
        body: body,
      );
      if (!ref.mounted) return null;
      // Increment comment count locally for immediate feedback
      state = state.copyWith(
        forumPosts: [
          for (final post in state.forumPosts)
            if (post.id == postId)
              post.copyWith(commentCount: post.commentCount + 1)
            else
              post,
        ],
      );
      return comment;
    } catch (error) {
      debugPrint('Failed to create forum comment: $error');
      return null;
    }
  }

  Future<void> toggleForumLike(String postId) async {
    // Optimistic update
    final oldPosts = state.forumPosts;
    state = state.copyWith(
      forumPosts: [
        for (final post in state.forumPosts)
          if (post.id == postId)
            post.copyWith(
              isLiked: !post.isLiked,
              likeCount: post.isLiked
                  ? (post.likeCount - 1).clamp(0, 999999)
                  : post.likeCount + 1,
            )
          else
            post,
      ],
    );
    try {
      await _forumRepository.toggleLike(postId);
    } catch (error) {
      debugPrint('Failed to toggle like: $error');
      if (ref.mounted) {
        state = state.copyWith(forumPosts: oldPosts);
      }
    }
  }

  Future<void> toggleForumFavorite(String postId) async {
    // Optimistic update
    final oldPosts = state.forumPosts;
    state = state.copyWith(
      forumPosts: [
        for (final post in state.forumPosts)
          if (post.id == postId)
            post.copyWith(isFavorited: !post.isFavorited)
          else
            post,
      ],
    );
    try {
      await _forumRepository.toggleFavorite(postId);
    } catch (error) {
      debugPrint('Failed to toggle favorite: $error');
      if (ref.mounted) {
        state = state.copyWith(forumPosts: oldPosts);
      }
    }
  }
}

class _PointGrantOutcome {
  const _PointGrantOutcome({
    required this.user,
    required this.awarded,
    required this.alreadyGranted,
    required this.pointsAwarded,
  });

  final UserProfile user;
  final bool awarded;
  final bool alreadyGranted;
  final int pointsAwarded;
}

class _TodayStateSnapshot {
  const _TodayStateSnapshot({
    required this.completedLessonIds,
    required this.reviewWordIds,
    required this.trainingSessionIds,
    required this.claimedRewardIds,
  });

  final Set<String> completedLessonIds;
  final Set<String> reviewWordIds;
  final Set<String> trainingSessionIds;
  final Set<String> claimedRewardIds;
}
