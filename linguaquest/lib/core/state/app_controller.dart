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
import '../../data/repositories/analytics_repository.dart';
import '../../data/article_asset_loader.dart';
import '../../data/models/article.dart';
import '../../data/repositories/api_repositories.dart';
import '../../data/repositories/article_repository.dart';
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
import '../../data/models/study_spot.dart';
import '../../data/repositories/study_plan_repository.dart';
import '../../data/repositories/study_spot_repository.dart';
import '../../data/repositories/user_word_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../services/local_notification_service.dart';
import '../constants/app_constants.dart';
import '../services/location_service.dart';
import '../utils/progress_scope.dart';
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

final studySpotRepositoryProvider = Provider<StudySpotRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiStudySpotRepository(ref.read(apiClientProvider));
  }
  return MockStudySpotRepository();
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiAnalyticsRepository(ref.read(apiClientProvider));
  }
  return MockAnalyticsRepository();
});

final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiArticleRepository(
      ref.watch(apiClientProvider),
      ArticleAssetLoader(),
    );
  }
  return MockArticleRepository(ArticleAssetLoader());
});

final appControllerProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppController extends Notifier<AppState> {
  static const _themeModeKey = 'linguaquest.themeMode';
  static const _localeKey = 'linguaquest.locale';
  static const _targetLanguageKey = 'linguaquest.target_language';
  static const _firstMapLanguageKey = 'linguaquest.first_map_language_at';
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

  // P2b: per-language wordbook pointer and current language
  static const _currentLanguageKey = 'linguaquest.current_language';
  static const _migrationV2ScopeFlag = 'linguaquest.migrated.v2_scope';

  // P2b scope-qualified key builders
  static String _scopedCompletedKey(String scope) =>
      'linguaquest.completedLessons.$scope';
  static String _scopedTodayLessonsKey(String scope) =>
      'linguaquest.today.lessons.$scope';
  static String _scopedTodayLearnedKey(String scope) =>
      'linguaquest.today.learned.$scope';
  static String _scopedTodayReviewsKey(String scope) =>
      'linguaquest.today.reviews.$scope';
  static String _scopedTodayTrainingKey(String scope) =>
      'linguaquest.today.training.$scope';
  static String _scopedTodayTrainingGamesKey(String scope) =>
      'linguaquest.today.training.games.$scope';
  static String _scopedTodayTrainingXpKey(String scope) =>
      'linguaquest.today.training.xp.$scope';
  static String _scopedTodayRewardsKey(String scope) =>
      'linguaquest.today.rewards.$scope';
  // _scopedUserWordsKey and _scopedStudyPlanKey reserved for P2c.
  static String _currentWordBookIdForLangKey(String language) =>
      'linguaquest.currentWordBookId.$language';

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
  late final StudySpotRepository _studySpotRepository;
  late final AnalyticsRepository _analyticsRepository;
  late final ArticleRepository _articleRepository;
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
    _studySpotRepository = ref.watch(studySpotRepositoryProvider);
    _analyticsRepository = ref.watch(analyticsRepositoryProvider);
    _articleRepository = ref.watch(articleRepositoryProvider);
    _localNotificationService = ref.watch(localNotificationServiceProvider);
    return AppState.initial();
  }

  Future<void> bootstrap() async {
    if (state.isBootstrapped) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final prefs = await SharedPreferences.getInstance();
      // Run one-shot migration before reading any scoped keys.
      await _runMigrationV2Scope(prefs);

      final persistedLanguage = prefs.getString(_currentLanguageKey) ?? 'zh';
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
      final persistedLanguageDefaultBookId = _firstWordBookIdForLanguage(
        wordBooks,
        persistedLanguage,
      );
      final rememberedWordBookId =
          studyPlan?.wordBookId ??
          prefs.getString(_currentWordBookIdForLangKey(persistedLanguage)) ??
          (user?.targetExam == null
              ? persistedLanguageDefaultBookId ??
                    prefs.getString(_currentWordBookIdKey)
              : null);
      final currentWordBookId = _resolveCurrentWordBookId(
        books: wordBooks,
        savedId: rememberedWordBookId,
        target: user?.targetExam,
      );
      final currentLanguage =
          _wordBookById(wordBooks, currentWordBookId)?.language ??
          persistedLanguage;
      await prefs.setString(_currentLanguageKey, currentLanguage);
      await _saveCurrentWordBookIdForLanguage(
        currentLanguage,
        currentWordBookId,
      );
      final bootstrapScope = progressScope(currentLanguage, currentWordBookId);
      final localCompletedLessonIds = _stringSet(
        prefs,
        _scopedCompletedKey(bootstrapScope),
      );
      final todayKey = _dateKey(DateTime.now());
      final hasTodayState = prefs.getString(_todayDateKey) == todayKey;
      final localTodayCompletedLessonIds = hasTodayState
          ? _stringSet(prefs, _scopedTodayLessonsKey(bootstrapScope))
          : <String>{};
      final localTodayLearnedWordIds = hasTodayState
          ? _stringSet(prefs, _scopedTodayLearnedKey(bootstrapScope))
          : <String>{};
      final localTodayReviewWordIds = hasTodayState
          ? _stringSet(prefs, _scopedTodayReviewsKey(bootstrapScope))
          : <String>{};
      final todayTrainingSessionIds = hasTodayState
          ? _stringSet(prefs, _scopedTodayTrainingKey(bootstrapScope))
          : <String>{};
      final localTodayTrainingGameIds = hasTodayState
          ? _stringSet(prefs, _scopedTodayTrainingGamesKey(bootstrapScope))
          : <String>{};
      final localTodayTrainingXp = hasTodayState
          ? prefs.getInt(_scopedTodayTrainingXpKey(bootstrapScope)) ?? 0
          : 0;
      final localTodayClaimedRewardIds = hasTodayState
          ? _stringSet(prefs, _scopedTodayRewardsKey(bootstrapScope))
          : <String>{};
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
        targetLanguage: prefs.getString(_targetLanguageKey) ?? currentLanguage,
        currentLanguage: currentLanguage,
        reminderSettings: reminderSettings,
        sensorySettings: sensorySettings,
        privacySettings: privacySettings,
        studyPlan: studyPlan,
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayLearnedWordIds: localTodayLearnedWordIds,
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
    // Record first map language selection (one-shot flag for achievement)
    if (prefs.getString(_firstMapLanguageKey) == null) {
      await prefs.setString(
        _firstMapLanguageKey,
        DateTime.now().toIso8601String(),
      );
    }
    // Align the learning scope so language + wordbook + progress match the new
    // target immediately, not only after the picker later confirms a book. This
    // prevents the "target language shows new but lessons/wordbook stay old"
    // mismatch (Cycle 10 F). switchLanguage restores the language's remembered
    // (or first) wordbook and no-ops for languages that have no books yet.
    if (code != state.currentLanguage) {
      await switchLanguage(code);
    }
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
        await client.dio.put<void>('/privacy', data: settings.toJson());
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
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
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
      final user = await _authRepository.verifyEmail(email: email, code: code);
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
      final wordBookId = _hasWordBook(plan.wordBookId)
          ? plan.wordBookId
          : _wordBookIdForTarget(plan.wordBookId, state.wordBooks);
      final book = _wordBookById(state.wordBooks, wordBookId);
      final targetExam = book?.examType ?? targetForStudyBookId(wordBookId);
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
      await _saveTodayLearnedWords(<String>{}, resetAt);
      await _saveTodayReviewWords(<String>{}, resetAt);
      state = state.copyWith(
        studyPlan: resetPlan,
        reminderSettings: reminderSettings,
        customWords: resetWords,
        completedLessonIds: {},
        todayCompletedLessonIds: {},
        todayLearnedWordIds: {},
        todayReviewWordIds: {},
        lessons: _applyLessonProgression(state.lessons, <String>{}),
      );
      await refreshNotifications();
      unawaited(_scheduleLocalNotifications());
    });
  }

  Future<bool> switchWordBook(String wordBookId) async {
    final book = _wordBookById(state.wordBooks, wordBookId);
    if (book == null) return false;
    return _switchScopeInternal(book.language, wordBookId);
  }

  Future<bool> _switchScopeInternal(String language, String wordBookId) async {
    final book = _wordBookById(state.wordBooks, wordBookId);
    if (book == null || book.language != language) return false;
    return _run(() async {
      // Load this scope's progress (not the current scope's in-memory state).
      final targetScope = progressScope(language, wordBookId);
      final prefs = await SharedPreferences.getInstance();
      final scopedCompleted = _stringSet(
        prefs,
        _scopedCompletedKey(targetScope),
      );
      final todayKey = _dateKey(DateTime.now());
      final hasTodayState = prefs.getString(_todayDateKey) == todayKey;
      final scopedTodayLessons = hasTodayState
          ? _stringSet(prefs, _scopedTodayLessonsKey(targetScope))
          : <String>{};
      final scopedTodayLearned = hasTodayState
          ? _stringSet(prefs, _scopedTodayLearnedKey(targetScope))
          : <String>{};
      final scopedTodayReviews = hasTodayState
          ? _stringSet(prefs, _scopedTodayReviewsKey(targetScope))
          : <String>{};
      final scopedTodayTraining = hasTodayState
          ? _stringSet(prefs, _scopedTodayTrainingKey(targetScope))
          : <String>{};
      final scopedTodayTrainingGames = hasTodayState
          ? _stringSet(prefs, _scopedTodayTrainingGamesKey(targetScope))
          : <String>{};
      final scopedTodayRewards = hasTodayState
          ? _stringSet(prefs, _scopedTodayRewardsKey(targetScope))
          : <String>{};
      final scopedTodayXp = hasTodayState
          ? prefs.getInt(_scopedTodayTrainingXpKey(targetScope)) ?? 0
          : 0;

      final lessons = _applyLessonProgression(
        await _learningRepository.listLessonsForWordBook(wordBookId),
        scopedCompleted,
      );
      var updatedUser = state.user;
      var savedPlan = state.studyPlan;
      var reminderSettings = state.reminderSettings;
      if (updatedUser != null) {
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
      await prefs.setString(_currentLanguageKey, language);
      await _saveCurrentWordBookIdForLanguage(language, wordBookId);
      state = state.copyWith(
        user: updatedUser,
        currentLanguage: language,
        currentWordBookId: wordBookId,
        lessons: lessons,
        studyPlan: savedPlan,
        reminderSettings: reminderSettings,
        completedLessonIds: scopedCompleted,
        todayCompletedLessonIds: scopedTodayLessons,
        todayLearnedWordIds: scopedTodayLearned,
        todayReviewWordIds: scopedTodayReviews,
        todayTrainingSessionIds: scopedTodayTraining,
        todayTrainingGameIds: scopedTodayTrainingGames,
        todayClaimedRewardIds: scopedTodayRewards,
        todayTrainingXp: scopedTodayXp,
      );
      await refreshNotifications();
      await refreshRewardTasks();
      unawaited(_scheduleLocalNotifications());
    });
  }

  /// §7 (P4e): manually refreshes offline (bundled) content. Drops the memoized
  /// asset-loader caches for wordbooks and articles, then reloads the bundled
  /// wordbooks and the current wordbook's lessons back into state. Articles are
  /// loaded on-demand by the reading screens, so clearing their cache is enough
  /// for the next read to re-read from the bundle. No persistence, no network.
  Future<bool> refreshOfflineContent() async {
    return _run(() async {
      await _learningRepository.clearOfflineCache();
      await _articleRepository.clearOfflineCache();

      final wordBooks = await _learningRepository.listWordBooks();
      final lessons = _applyLessonProgression(
        await _learningRepository.listLessonsForWordBook(
          state.currentWordBookId,
        ),
        state.completedLessonIds,
      );
      state = state.copyWith(wordBooks: wordBooks, lessons: lessons);
    });
  }

  /// Switches to [language] and picks that language's remembered wordbook (or
  /// its first available book). Equivalent to [switchWordBook] but also updates
  /// [AppState.currentLanguage] and persists the new language pointer.
  ///
  /// Returns true on success, false if no books exist for [language].
  Future<bool> switchLanguage(String language) async {
    // Find books for this language.
    final books = state.wordBooks.where((b) => b.language == language).toList();
    if (books.isEmpty) return false;

    // Restore the previously remembered wordbook for this language, or use
    // the first book.
    final prefs = await SharedPreferences.getInstance();
    final rememberedBookId = prefs.getString(
      _currentWordBookIdForLangKey(language),
    );
    final targetBookId =
        (rememberedBookId != null && books.any((b) => b.id == rememberedBookId))
        ? rememberedBookId
        : books.first.id;

    return _switchScopeInternal(language, targetBookId);
  }

  /// Atomically switches to the given [language] **and** the exact [wordBookId]
  /// within that language. Use this when both dimensions are known (e.g. the map
  /// screen or the two-level picker confirming a (lang, book) pair).
  ///
  /// Returns true on success, false if [wordBookId] doesn't exist for [language].
  Future<bool> switchScope(String language, String wordBookId) async {
    final books = state.wordBooks.where((b) => b.language == language).toList();
    if (!books.any((b) => b.id == wordBookId)) return false;

    return _switchScopeInternal(language, wordBookId);
  }

  Future<void> logout() async {
    final themeMode = state.themeMode;
    final reminderSettings = state.reminderSettings;
    final sensorySettings = state.sensorySettings;
    final privacySettings = state.privacySettings;
    final locale = state.locale;
    final wordBooks = state.wordBooks;
    final currentWordBookId = state.currentWordBookId;
    final currentLanguage = state.currentLanguage;
    final targetLanguage = state.targetLanguage;
    final prefs = await SharedPreferences.getInstance();
    await _authRepository.logout();
    await _clearLocalProgressState(prefs);
    final lessons = _applyLessonProgression(
      await _learningRepository.listLessonsForWordBook(currentWordBookId),
      <String>{},
    );
    state = AppState.initial().copyWith(
      isBootstrapped: true,
      wordBooks: wordBooks,
      currentWordBookId: currentWordBookId,
      currentLanguage: currentLanguage,
      targetLanguage: targetLanguage,
      lessons: lessons,
      themeMode: themeMode,
      locale: locale,
      reminderSettings: reminderSettings,
      sensorySettings: sensorySettings,
      privacySettings: privacySettings,
      notifications: [],
      lotteryPrizes: [],
      userAssets: [],
      clearLastResult: true,
    );
    unawaited(_scheduleLocalNotifications());
  }

  Future<bool> clearAllDataAndRestart() {
    return _run(() async {
      await _authRepository.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _resetToFreshLocalState();
    });
  }

  Future<bool> deleteAccountAndRestart() {
    return _run(() async {
      await _authRepository.deleteAccount();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _resetToFreshLocalState();
    });
  }

  Future<void> _resetToFreshLocalState() async {
    final wordBooks = await _learningRepository.listWordBooks();
    final currentWordBookId = wordBooks.isEmpty ? 'hsk1' : wordBooks.first.id;
    final lessons = wordBooks.isEmpty
        ? <Lesson>[]
        : _applyLessonProgression(
            await _learningRepository.listLessonsForWordBook(currentWordBookId),
            <String>{},
          );
    state = AppState.initial().copyWith(
      isBootstrapped: true,
      wordBooks: wordBooks,
      currentWordBookId: currentWordBookId,
      currentLanguage: wordBooks.isEmpty ? 'zh' : wordBooks.first.language,
      targetLanguage: wordBooks.isEmpty ? 'zh' : wordBooks.first.language,
      lessons: lessons,
      clearLastResult: true,
    );
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
    final trimmed = word.trim();
    // #G: 同一个词已在生词本则不重复添加（幂等）。返回 false 表示"未新增"，
    // 并清空 errorMessage —— 重复不是错误，调用方据此展示"已在生词本"而非"已保存"，
    // 与真正失败（errorMessage 非空）区分。
    final dup = state.customWords.any(
      (w) => w.word.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (dup) {
      state = state.copyWith(clearError: true);
      return false;
    }
    return _run(() async {
      final created = await _customWordRepository.create(
        CustomWord.create(
          id: 'word-${DateTime.now().microsecondsSinceEpoch}',
          uid: user.uid,
          word: trimmed,
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
      // Formal-course words count toward "today's learning" the same way mixed
      // sessions do, keeping the home counter and hasStudyToday consistent
      // across both study paths. Training packs are not new learning, so skip.
      final todayLearnedWordIds = isTraining
          ? todayState.learnedWordIds
          : {
              ...todayState.learnedWordIds,
              for (final word in learnedUserWords) word.wordId,
            };
      if (!isTraining) {
        await _saveTodayLearnedWords(todayLearnedWordIds, now);
      }
      state = state.copyWith(
        user: updatedUser,
        lessons: shouldAdvanceLesson
            ? _applyLessonProgression(state.lessons, completedLessonIds)
            : state.lessons,
        completedLessonIds: shouldAdvanceLesson
            ? completedLessonIds
            : state.completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayLearnedWordIds: todayLearnedWordIds,
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
            streak: _nextStreak(
              user.lastStudyDate?.toLocal(),
              now,
              user.streak,
            ),
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
      await _applyRewardSnapshot(
        await _rewardTaskRepository.listTasks(user.uid),
      );
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
      // Record every new word the session actually studied, not just the
      // 3-word [currentLesson] chunk. New-word answers are logged with
      // source 'newWord' (StudySessionItemSource.newWord.name); their ids are
      // resolved against the current wordbook. Without this, words drawn beyond
      // the lesson chunk stay untracked and reappear in the next day's plan.
      final wordsById = {
        for (final word in state.currentWordBook?.words ?? const <Word>[])
          word.id: word,
      };
      final learnedWords = <Word>[
        if (currentLesson != null) ...currentLesson.words,
        for (final event in answerEvents)
          if (event['source'] == 'newWord' && event['wordId'] is String)
            if (wordsById[event['wordId'] as String] != null)
              wordsById[event['wordId'] as String]!,
      ];
      final learnedUserWords = await _recordLearnedWords(
        uid: user.uid,
        words: learnedWords,
        mistakeWordIds: mistakeWordIds.toSet(),
        now: now,
      );
      final todayLearnedWordIds = {
        ...state.todayLearnedWordIds,
        for (final word in learnedUserWords) word.wordId,
      };
      await _saveLessonProgress(
        completedLessonIds,
        todayCompletedLessonIds,
        now,
      );
      await _saveTodayLearnedWords(todayLearnedWordIds, now);
      state = state.copyWith(
        user: updatedUser,
        lessons: _applyLessonProgression(state.lessons, completedLessonIds),
        completedLessonIds: completedLessonIds,
        todayCompletedLessonIds: todayCompletedLessonIds,
        todayLearnedWordIds: todayLearnedWordIds,
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
      if (message == 'rate_limited') {
        return '请求过于频繁，请稍后再试。';
      }
      if (message == 'blocked') {
        return '内容不符合使用规范，请修改后重试。';
      }
      if (message == 'ai_unavailable') {
        return 'AI 服务暂时不可用，请稍后重试。';
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
    return _recordLearnedWords(
      uid: uid,
      words: lesson.words,
      mistakeWordIds: mistakeWordIds,
      now: now,
    );
  }

  /// Marks [words] as learned userWords, upserting them. Words already tracked
  /// keep their history (via [UserWord.learned]); untracked ones are created.
  /// Ignored words are skipped and duplicate ids collapse to a single update.
  Future<List<UserWord>> _recordLearnedWords({
    required String uid,
    required List<Word> words,
    required Set<String> mistakeWordIds,
    required DateTime now,
  }) async {
    if (words.isEmpty) return [];
    final existingByWordId = {
      for (final word in state.userWords) word.wordId: word,
    };
    final updates = <UserWord>[];
    final seen = <String>{};
    for (final targetWord in words) {
      if (!seen.add(targetWord.id)) continue;
      final existing =
          existingByWordId[targetWord.id] ??
          UserWord.create(
            uid: uid,
            word: targetWord,
            wordBookId: state.currentWordBookId,
            now: now,
          );
      if (existing.isIgnored || existing.status == 'Ignored') continue;
      updates.add(
        existing
            .copyWith(
              wordBookId: state.currentWordBookId,
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
    await _saveCurrentWordBookIdForLanguage(state.currentLanguage, wordBookId);
  }

  Future<void> _saveCurrentWordBookIdForLanguage(
    String lang,
    String wordBookId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    // Save both per-language (new) and global (legacy compat).
    await prefs.setString(_currentWordBookIdForLangKey(lang), wordBookId);
    await prefs.setString(_currentWordBookIdKey, wordBookId);
  }

  /// One-shot idempotent migration: copies legacy global keys → zh::hsk1 scope.
  /// COPY-don't-delete: original keys are preserved for safety. Runs once,
  /// guarded by [_migrationV2ScopeFlag].
  Future<void> _runMigrationV2Scope(SharedPreferences prefs) async {
    if (prefs.getBool(_migrationV2ScopeFlag) == true) return; // already done

    const lang = 'zh';
    const bookId = 'hsk1';
    final scope = progressScope(lang, bookId);

    // --- Copy completedLessons ---
    final globalCompleted = prefs.getStringList(_completedLessonIdsKey);
    if (globalCompleted != null &&
        prefs.getStringList(_scopedCompletedKey(scope)) == null) {
      await prefs.setStringList(_scopedCompletedKey(scope), globalCompleted);
    }

    // --- Copy today.* keys ---
    final globalTodayLessons = prefs.getStringList(_todayLessonIdsKey);
    if (globalTodayLessons != null &&
        prefs.getStringList(_scopedTodayLessonsKey(scope)) == null) {
      await prefs.setStringList(
        _scopedTodayLessonsKey(scope),
        globalTodayLessons,
      );
    }
    final globalTodayReviews = prefs.getStringList(_todayReviewIdsKey);
    if (globalTodayReviews != null &&
        prefs.getStringList(_scopedTodayReviewsKey(scope)) == null) {
      await prefs.setStringList(
        _scopedTodayReviewsKey(scope),
        globalTodayReviews,
      );
    }
    final globalTodayTraining = prefs.getStringList(_todayTrainingIdsKey);
    if (globalTodayTraining != null &&
        prefs.getStringList(_scopedTodayTrainingKey(scope)) == null) {
      await prefs.setStringList(
        _scopedTodayTrainingKey(scope),
        globalTodayTraining,
      );
    }
    final globalTodayGames = prefs.getStringList(_todayTrainingGameIdsKey);
    if (globalTodayGames != null &&
        prefs.getStringList(_scopedTodayTrainingGamesKey(scope)) == null) {
      await prefs.setStringList(
        _scopedTodayTrainingGamesKey(scope),
        globalTodayGames,
      );
    }
    final globalTodayXp = prefs.getInt(_todayTrainingXpKey);
    if (globalTodayXp != null &&
        prefs.getInt(_scopedTodayTrainingXpKey(scope)) == null) {
      await prefs.setInt(_scopedTodayTrainingXpKey(scope), globalTodayXp);
    }
    final globalTodayRewards = prefs.getStringList(_todayRewardIdsKey);
    if (globalTodayRewards != null &&
        prefs.getStringList(_scopedTodayRewardsKey(scope)) == null) {
      await prefs.setStringList(
        _scopedTodayRewardsKey(scope),
        globalTodayRewards,
      );
    }

    // --- currentWordBookId → per-language ---
    final globalBookId = prefs.getString(_currentWordBookIdKey);
    if (globalBookId != null &&
        prefs.getString(_currentWordBookIdForLangKey(lang)) == null) {
      await prefs.setString(_currentWordBookIdForLangKey(lang), globalBookId);
    }

    // --- Set default current_language ---
    if (prefs.getString(_currentLanguageKey) == null) {
      await prefs.setString(_currentLanguageKey, lang);
    }

    // NOTE: user_words and studyPlan migration is handled in their respective
    // load paths: legacy keys (no scope) are read as zh::hsk1 on first access.

    // Set the flag — migration is done. Original global keys are preserved.
    await prefs.setBool(_migrationV2ScopeFlag, true);
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

  String _mappedWordBookId(String normalizedTarget) =>
      studyBookIdForTarget(normalizedTarget);

  bool _hasWordBook(String wordBookId) {
    return _wordBookById(state.wordBooks, wordBookId) != null;
  }

  WordBook? _wordBookById(List<WordBook> books, String id) {
    for (final book in books) {
      if (book.id == id) return book;
    }
    return null;
  }

  String? _firstWordBookIdForLanguage(List<WordBook> books, String language) {
    for (final book in books) {
      if (book.language == language) return book.id;
    }
    return null;
  }

  Future<void> _clearLocalProgressState(SharedPreferences prefs) async {
    const progressKeyPrefixes = [
      'linguaquest.completedLessons',
      'linguaquest.today.lessons',
      'linguaquest.today.learned',
      'linguaquest.today.reviews',
      'linguaquest.today.training',
      'linguaquest.today.rewards',
    ];
    for (final key in prefs.getKeys()) {
      if (key == _todayDateKey ||
          key == _completedLessonIdsKey ||
          key == _todayLessonIdsKey ||
          key == _todayReviewIdsKey ||
          key == _todayTrainingIdsKey ||
          key == _todayTrainingGameIdsKey ||
          key == _todayTrainingXpKey ||
          key == _todayRewardIdsKey ||
          progressKeyPrefixes.any((prefix) => key.startsWith('$prefix.'))) {
        await prefs.remove(key);
      }
    }
  }

  Future<void> _saveLessonProgress(
    Set<String> completedLessonIds,
    Set<String> todayCompletedLessonIds,
    DateTime now,
  ) async {
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _scopedCompletedKey(scope),
      completedLessonIds.toList(),
    );
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _scopedTodayLessonsKey(scope),
      todayCompletedLessonIds.toList(),
    );
  }

  Future<void> _saveTodayLearnedWords(
    Set<String> todayLearnedWordIds,
    DateTime now,
  ) async {
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _scopedTodayLearnedKey(scope),
      todayLearnedWordIds.toList(),
    );
  }

  Future<void> _saveTodayReviewWords(
    Set<String> todayReviewWordIds,
    DateTime now,
  ) async {
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _scopedTodayReviewsKey(scope),
      todayReviewWordIds.toList(),
    );
  }

  Future<void> _saveTodayTrainingSessions(
    Set<String> todayTrainingSessionIds,
    DateTime now,
  ) async {
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _scopedTodayTrainingKey(scope),
      todayTrainingSessionIds.toList(),
    );
  }

  Future<void> _saveTodayTraining(Set<String> gameIds, int xp) async {
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(DateTime.now()));
    await prefs.setStringList(
      _scopedTodayTrainingGamesKey(scope),
      gameIds.toList(),
    );
    await prefs.setInt(_scopedTodayTrainingXpKey(scope), xp);
  }

  Future<void> _saveTodayClaimedRewards(
    Set<String> todayClaimedRewardIds,
    DateTime now,
  ) async {
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_todayDateKey, _dateKey(now));
    await prefs.setStringList(
      _scopedTodayRewardsKey(scope),
      todayClaimedRewardIds.toList(),
    );
  }

  Future<_TodayStateSnapshot> _normalizeTodayState(DateTime now) async {
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _dateKey(now);
    if (prefs.getString(_todayDateKey) == todayKey) {
      return _TodayStateSnapshot(
        completedLessonIds: {...state.todayCompletedLessonIds},
        learnedWordIds: {...state.todayLearnedWordIds},
        reviewWordIds: {...state.todayReviewWordIds},
        trainingSessionIds: {...state.todayTrainingSessionIds},
        claimedRewardIds: {...state.todayClaimedRewardIds},
      );
    }

    await prefs.remove(_scopedTodayLessonsKey(scope));
    await prefs.remove(_scopedTodayLearnedKey(scope));
    await prefs.remove(_scopedTodayReviewsKey(scope));
    await prefs.remove(_scopedTodayTrainingKey(scope));
    await prefs.remove(_scopedTodayRewardsKey(scope));
    await prefs.setString(_todayDateKey, todayKey);
    state = state.copyWith(
      todayCompletedLessonIds: {},
      todayLearnedWordIds: {},
      todayReviewWordIds: {},
      todayTrainingSessionIds: {},
      todayClaimedRewardIds: {},
    );
    return const _TodayStateSnapshot(
      completedLessonIds: {},
      learnedWordIds: {},
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

  Future<StudyPlan?> _loadOrCreateStudyPlan(UserProfile user) async {
    return _studyPlanRepository.load(user.uid);
  }

  Future<void> _ensureStudyPlan(UserProfile user) async {
    final plan = await _loadOrCreateStudyPlan(user);
    if (plan == null) return; // 新用户/未做 goal-setup：studyPlan 保持 null
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
    try {
      final repo = ref.read(aiRepositoryProvider);
      Map<String, dynamic> result;
      switch (featureType) {
        case 'chat':
          result = await repo.chat(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.currentLanguage,
          );
        case 'sentence_analysis':
          result = await repo.analyzeStatement(
            prompt: prompt,
            targetLanguage: state.currentLanguage,
          );
        case 'cloze':
          result = await repo.generateCloze(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.currentLanguage,
          );
        case 'confusion':
          result = await repo.generateConfusion(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.currentLanguage,
          );
        case 'sentence_gen':
          result = await repo.generateSentences(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.currentLanguage,
          );
        default:
          result = {};
      }
      final history = await repo.listHistory();
      state = state.copyWith(aiHistory: history, clearError: true);
      return result;
    } catch (e) {
      state = state.copyWith(errorMessage: _friendlyError(e));
      return {};
    }
  }

  /// Explains a reading paragraph via the AI pipeline (P3f). Runs in [language]
  /// (the article's language, not the global target-language setting). Returns
  /// the structured strict-JSON map, or `{}` on failure (with [AppState.errorMessage]
  /// set, mirroring the other AI screens' error flow). Reading-explain history is
  /// recorded but intentionally filtered out of the AI history list to avoid noise.
  Future<Map<String, dynamic>> explainParagraph({
    required String paragraph,
    required String language,
    String? level,
  }) async {
    try {
      final repo = ref.read(aiRepositoryProvider);
      final result = await repo.explainParagraph(
        paragraph: paragraph,
        language: language,
        level: level,
      );
      state = state.copyWith(clearError: true);
      return result;
    } catch (e) {
      state = state.copyWith(errorMessage: _friendlyError(e));
      return {};
    }
  }

  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    String? examType,
    double? targetScore,
  }) async {
    try {
      final result = await ref
          .read(aiRepositoryProvider)
          .reviewWriting(
            essay: essay,
            examType: examType,
            targetScore: targetScore,
            targetLanguage: state.currentLanguage,
          );
      final history = await ref.read(aiRepositoryProvider).listHistory();
      state = state.copyWith(aiHistory: history, clearError: true);
      return result;
    } catch (e) {
      state = state.copyWith(errorMessage: _friendlyError(e));
      return {};
    }
  }

  Future<void> deleteAiHistory(String id) async {
    final repo = ref.read(aiRepositoryProvider);
    await repo.deleteHistory(id);
    final history = await repo.listHistory();
    state = state.copyWith(aiHistory: history);
  }

  /// Deletes every AI history record in one pass: the deletes run in parallel
  /// and the list is refetched once, instead of refetching after each delete.
  Future<void> clearAiHistory() async {
    final repo = ref.read(aiRepositoryProvider);
    final ids = state.aiHistory.map((e) => e.id).toList();
    if (ids.isEmpty) return;
    await Future.wait(ids.map(repo.deleteHistory));
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

  Future<void> refreshFavoritedPosts() async {
    try {
      final posts = await _forumRepository.listFavoritedPosts();
      if (!ref.mounted) return;
      state = state.copyWith(favoritedPosts: posts);
    } catch (error) {
      debugPrint('Failed to refresh favorited posts: $error');
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

  Future<void> reportForumPost(
    String postId,
    String reason, {
    String? detail,
  }) async {
    try {
      await _forumRepository.reportPost(postId, reason, detail: detail);
    } catch (error) {
      debugPrint('Failed to report post: $error');
      rethrow;
    }
  }

  // ── Analytics / Achievement / Leaderboard ─────────────────────────────────

  Future<void> refreshAnalytics() async {
    final uid = state.user?.uid ?? '';
    try {
      final analytics = await _analyticsRepository.getAnalytics(uid);
      if (!ref.mounted) return;
      state = state.copyWith(analyticsSnapshot: analytics);
    } catch (error) {
      debugPrint('Failed to refresh analytics: $error');
    }
  }

  Future<void> refreshAchievements() async {
    final uid = state.user?.uid ?? '';
    try {
      final achievements = await _analyticsRepository.getAchievements(uid);
      if (!ref.mounted) return;
      state = state.copyWith(achievements: achievements);
    } catch (error) {
      debugPrint('Failed to refresh achievements: $error');
    }
  }

  Future<void> refreshLeaderboard({String dimension = 'global'}) async {
    final uid = state.user?.uid ?? '';
    try {
      final result = await _analyticsRepository.getLeaderboard(
        dimension: dimension,
        uid: uid,
      );
      if (!ref.mounted) return;
      state = state.copyWith(leaderboardSnapshot: result);
    } catch (error) {
      debugPrint('Failed to refresh leaderboard: $error');
    }
  }

  Future<void> refreshRecommendations() async {
    final user = state.user;
    if (user == null) return;
    try {
      final recs = await _analyticsRepository.getRecommendations(user.uid);
      if (!ref.mounted) return;
      state = state.copyWith(recommendations: recs);
    } catch (error) {
      // Recommendation failures are non-critical — do not surface to the user.
      debugPrint('Failed to refresh recommendations: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Study Map (P2d): study spot CRUD + visit recording.
  // ---------------------------------------------------------------------------

  Future<void> loadStudySpots() async {
    final spots = await _studySpotRepository.list();
    state = state.copyWith(studySpots: spots);
  }

  Future<void> saveStudySpot(StudySpot spot) async {
    await _studySpotRepository.add(spot);
    await loadStudySpots();
  }

  Future<void> deleteStudySpot(String id) async {
    await _studySpotRepository.remove(id);
    await loadStudySpots();
  }

  /// Records a study visit (nearby upsert via the repository). When [latitude]/
  /// [longitude] are omitted, the current device location is used. Any
  /// failure — denied permission, timeout, network — is swallowed so it never
  /// blocks lesson/training completion.
  Future<void> recordStudyVisit({
    required String name,
    double? latitude,
    double? longitude,
  }) async {
    try {
      double lat;
      double lng;
      if (latitude != null && longitude != null) {
        lat = latitude;
        lng = longitude;
      } else {
        final loc = await currentLatLng();
        if (loc == null) return; // silently skip
        lat = loc.latitude;
        lng = loc.longitude;
      }
      await _studySpotRepository.recordVisit(
        latitude: lat,
        longitude: lng,
        name: name,
      );
      await loadStudySpots();
    } catch (error) {
      debugPrint('recordStudyVisit skipped: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // Reading module (P3a): article listing/lookup. UI lands in P3b+.
  // ---------------------------------------------------------------------------

  /// All bundled reading articles, optionally filtered by language/level/theme.
  Future<List<Article>> loadArticles({
    String? language,
    String? level,
    String? theme,
  }) {
    return _articleRepository.listArticles(
      language: language,
      level: level,
      theme: theme,
    );
  }

  /// A single article by id, or null if not found.
  Future<Article?> getArticle(String id) => _articleRepository.getArticle(id);

  /// Articles recommended for the current scope (active language + wordbook).
  Future<List<Article>> recommendedArticles() {
    return _articleRepository.listArticles(
      language: state.currentLanguage,
      level: state.currentWordBookId,
    );
  }

  /// Persist reading progress for an article in the current scope.
  Future<void> saveReadingProgress(
    String articleId,
    int paragraphIndex, {
    bool done = false,
  }) async {
    final uid = state.user?.uid ?? '';
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    await _articleRepository.saveProgress(
      ReadingProgress(
        uid: uid,
        scope: scope,
        articleId: articleId,
        lastParagraphIndex: paragraphIndex,
        completed: done,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Reading progress entries for the current scope.
  Future<List<ReadingProgress>> readingProgressForScope() {
    final uid = state.user?.uid ?? '';
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    return _articleRepository.loadProgressForScope(uid, scope);
  }

  /// Saved reading-comprehension results for the current scope (analytics feed).
  Future<List<ReadingResult>> readingResultsForScope() {
    final uid = state.user?.uid ?? '';
    final scope = progressScope(state.currentLanguage, state.currentWordBookId);
    return _articleRepository.loadResults(uid, scope);
  }

  /// Records a completed reading comprehension (P3e).
  ///
  /// Reuses the training/analytics recording path: persists a [StudySession] +
  /// [ExerciseRecord]s (so accuracy/XP/streak aggregation counts it) AND a
  /// [ReadingResult] (per-kind correctness + theme) for the reading metrics.
  /// Also marks the article read and awards the earned XP.
  Future<bool> completeReading({
    required Article article,
    required List<QuizQuestion> questions,
    required List<bool> correctness,
    required Map<String, int> perKindCorrect,
    required DateTime startedAt,
  }) async {
    final user = state.user;
    if (user == null) return false;
    final total = questions.length;
    final correct = correctness.where((c) => c).length;
    final xpEarned = correct * 5; // small reward per correct comprehension item
    return _run(() async {
      final now = DateTime.now();
      final scope = progressScope(
        state.currentLanguage,
        state.currentWordBookId,
      );
      final gameId = 'reading-${article.id}';
      final sessionId = 'reading-${now.microsecondsSinceEpoch}';

      await _learningRepository.recordStudySession(
        StudySession(
          id: sessionId,
          uid: user.uid,
          lessonId: gameId,
          startedAt: startedAt,
          endedAt: now,
          totalQuestions: total,
          correctAnswers: correct,
          xpEarned: xpEarned,
          mistakeWordIds: const [],
        ),
      );

      final records = <ExerciseRecord>[];
      for (var i = 0; i < questions.length; i++) {
        final q = questions[i];
        records.add(
          ExerciseRecord(
            id: 'reading-${article.id}-$i-${now.microsecondsSinceEpoch}',
            uid: user.uid,
            sessionId: sessionId,
            gameId: gameId,
            wordId: q.word.id,
            promptType: q.type.name,
            isCorrect: correctness[i],
            answer: '',
            correctAnswer: q.answer,
            answerTimeMs: 0,
            dimension: ReviewDimension.context,
            createdAt: now,
            prompt: q.prompt,
            options: q.options,
          ),
        );
      }
      await _learningRepository.recordExerciseRecords(records);

      await _articleRepository.recordComprehensionResult(
        ReadingResult(
          uid: user.uid,
          scope: scope,
          articleId: article.id,
          totalQuestions: total,
          correctAnswers: correct,
          theme: article.theme,
          perKindCorrect: perKindCorrect,
          createdAt: now.toUtc(),
        ),
      );

      // Mark the article fully read.
      await _articleRepository.saveProgress(
        ReadingProgress(
          uid: user.uid,
          scope: scope,
          articleId: article.id,
          lastParagraphIndex: article.paragraphs.isEmpty
              ? 0
              : article.paragraphs.length - 1,
          completed: true,
          updatedAt: now.toUtc(),
        ),
      );

      final streak = _nextStreak(user.lastStudyDate, now, user.streak);
      final updatedUser = await _authRepository.updateProfile(
        user.copyWith(
          xp: user.xp + xpEarned,
          streak: streak,
          lastStudyDate: now,
          updatedAt: now,
        ),
      );
      state = state.copyWith(user: updatedUser);
      await refreshNotifications();
    });
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
    required this.learnedWordIds,
    required this.reviewWordIds,
    required this.trainingSessionIds,
    required this.claimedRewardIds,
  });

  final Set<String> completedLessonIds;
  final Set<String> learnedWordIds;
  final Set<String> reviewWordIds;
  final Set<String> trainingSessionIds;
  final Set<String> claimedRewardIds;
}
