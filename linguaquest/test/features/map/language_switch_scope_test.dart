// Regression test for the map language-switch bug (Cycle 10 F):
// selecting a new target language on the map used to update only
// `targetLanguage` while `currentLanguage` and the active wordbook stayed on
// the old language, so lessons/wordbook/progress no longer matched the language
// shown to the user (a "language ↔ wordbook mismatch" needing a refresh/restart).
//
// After the fix, `updateTargetLanguage` also aligns the learning scope: it
// switches `currentLanguage` and the language's remembered/first wordbook so all
// three (target language, current language, wordbook) are consistent immediately.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/exercise_record.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/study_session.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/learning_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'updateTargetLanguage aligns currentLanguage + wordbook with the target',
    () async {
      final now = DateTime(2026, 7, 5);
      final profile = UserProfile(
        uid: 'lang-switch-user',
        name: 'Test',
        email: 'test@linguaquest.test',
        targetExam: 'HSK 1',
        level: 'Beginner',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );

      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });

      final container = ProviderContainer(
        overrides: [
          learningRepositoryProvider.overrideWithValue(
            _BilingualLearningRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();

      final before = container.read(appControllerProvider);
      // Sanity: starts on Chinese with a Chinese wordbook.
      expect(before.currentLanguage, 'zh');
      final beforeBook = before.wordBooks
          .firstWhere((b) => b.id == before.currentWordBookId);
      expect(beforeBook.language, 'zh');

      // Choosing Japanese as the target (map "start learning" flow).
      await container
          .read(appControllerProvider.notifier)
          .updateTargetLanguage('ja');

      final after = container.read(appControllerProvider);
      expect(after.targetLanguage, 'ja');
      expect(
        after.currentLanguage,
        'ja',
        reason: 'currentLanguage must follow the new target language',
      );
      final afterBook = after.wordBooks
          .firstWhere((b) => b.id == after.currentWordBookId);
      expect(
        afterBook.language,
        'ja',
        reason: 'active wordbook must belong to the new target language',
      );
    },
  );
}

WordBook _makeBook(String id, String title, String language) => WordBook(
  id: id,
  title: title,
  category: 'exam',
  examType: title,
  coverUrl: '',
  totalWords: 1,
  includedWords: 1,
  description: '$title description',
  wordIds: const [],
  createdAt: DateTime(2026, 7, 5),
  words: const [],
  language: language,
);

class _BilingualLearningRepository implements LearningRepository {
  @override
  Future<List<WordBook>> listWordBooks() async => [
    _makeBook('hsk1', 'HSK 1', 'zh'),
    _makeBook('jlpt_n5', 'JLPT N5', 'ja'),
  ];

  @override
  Future<void> clearOfflineCache() async {}

  @override
  Future<List<Lesson>> listLessons() async => const [];

  @override
  Future<LearningProgress?> loadLearningProgress(DateTime now) async => null;

  @override
  Future<List<Lesson>> listLessonsForWordBook(String wordBookId) async =>
      const [];

  @override
  Future<void> recordStudySession(StudySession session) async {}

  @override
  Future<void> recordExerciseRecords(List<ExerciseRecord> records) async {}

  @override
  Future<RewardClaimResult?> claimReward({
    required String id,
    required int points,
    required DateTime now,
  }) async => null;
}
