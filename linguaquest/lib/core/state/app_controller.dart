import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/custom_word.dart';
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
      final lessons = await _learningRepository.listLessons();
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
      );
    } catch (error) {
      state = state.copyWith(
        isBootstrapped: true,
        isLoading: false,
        errorMessage: 'Could not start LinguaQuest: $error',
      );
    }
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
  }) async {
    final user = state.user;
    if (user == null) return false;
    return _run(() async {
      final updated = await _authRepository.updateProfile(
        user.copyWith(
          targetExam: targetExam,
          level: level,
          dailyGoal: dailyGoal,
          updatedAt: DateTime.now(),
        ),
      );
      state = state.copyWith(user: updated);
    });
  }

  Future<void> logout() async {
    await _authRepository.logout();
    state = AppState.initial().copyWith(
      isBootstrapped: true,
      lessons: state.lessons,
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
      state = state.copyWith(user: updatedUser, lastResult: result);
    });
  }

  Future<bool> reviewWord(String id, bool isCorrect) async {
    final user = state.user;
    if (user == null) return false;
    final word = _customWordById(id);
    if (word == null) return false;
    return _run(() async {
      final reviewed = word.reviewed(isCorrect: isCorrect);
      await _customWordRepository.update(reviewed);
      await _reviewRepository.recordReviewEvent(
        ReviewEvent(
          id: 'review-${DateTime.now().microsecondsSinceEpoch}',
          uid: user.uid,
          wordId: id,
          isCorrect: isCorrect,
          answerTimeMs: 2400,
          reviewedAt: DateTime.now(),
          masteryBefore: word.masteryLevel,
          masteryAfter: reviewed.masteryLevel,
          nextReviewAt: reviewed.nextReviewAt,
        ),
      );
      state = state.copyWith(
        customWords: [
          for (final item in state.customWords) item.id == id ? reviewed : item,
        ],
      );
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
      return false;
    }
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
}
