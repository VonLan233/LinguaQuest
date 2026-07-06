// Controller-level regression test for C1: updateStudyPlan must preserve a
// real non-hsk1 wordBookId instead of collapsing it back to hsk1.
//
// Before the fix in app_controller.dart updateStudyPlan (lines 611-612),
// _wordBookIdForTarget unconditionally mapped every id through
// _mappedWordBookId => 'hsk1', so any save (including innocuous date/daily-word
// edits) would silently reset the user's chosen wordbook to hsk1.
//
// After the fix, _hasWordBook guards the mapping: if the plan already holds a
// valid book id that exists in state.wordBooks, it is preserved.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/exercise_record.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/study_plan.dart';
import 'package:linguaquest/data/models/study_session.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/learning_repository.dart';
import 'package:linguaquest/data/repositories/study_plan_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'updateStudyPlan preserves a real non-hsk1 wordBookId (C1 regression)',
    () async {
      final now = DateTime(2026, 6, 29);
      final profile = UserProfile(
        uid: 'c1-preserve-wordbook-user',
        name: 'Test',
        email: 'test@linguaquest.test',
        targetExam: 'Daily English',
        level: 'Beginner',
        dailyGoal: 10,
        xp: 0,
        streak: 0,
        createdAt: now,
        updatedAt: now,
      );

      // Build a plan already pointing at hsk2 (simulates a user who switched).
      final initialPlan = StudyPlan.defaultsFor(
        uid: profile.uid,
        targetExam: profile.targetExam,
        dailyGoal: profile.dailyGoal,
      ).copyWith(wordBookId: 'hsk2', updatedAt: now);

      final studyPlanRepository = _MemoryStudyPlanRepository(initialPlan);

      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
        'linguaquest.currentWordBookId': 'hsk2',
        'linguaquest.currentWordBookId.zh': 'hsk2',
      });

      final container = ProviderContainer(
        overrides: [
          studyPlanRepositoryProvider.overrideWithValue(studyPlanRepository),
          // Provide both hsk1 and hsk2 so _hasWordBook('hsk2') returns true.
          learningRepositoryProvider.overrideWithValue(
            _TwoBookLearningRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();

      final stateAfterBootstrap = container.read(appControllerProvider);
      // Sanity: both books loaded, plan has hsk2 after bootstrap.
      expect(
        stateAfterBootstrap.wordBooks.map((b) => b.id),
        containsAll(['hsk1', 'hsk2']),
      );
      expect(stateAfterBootstrap.studyPlan?.wordBookId, 'hsk2');

      // Trigger updateStudyPlan with an innocuous change (dailyNewTarget) —
      // the kind of edit study_plan_settings_screen._save() issues.
      final planToSave = stateAfterBootstrap.studyPlan!;
      final success = await container
          .read(appControllerProvider.notifier)
          .updateStudyPlan(planToSave.copyWith(dailyNewTarget: 8));

      expect(success, true);

      // The saved plan and current state must keep hsk2, NOT collapse to hsk1.
      expect(
        studyPlanRepository.savedPlan?.wordBookId,
        'hsk2',
        reason: 'updateStudyPlan must not reset wordBookId from hsk2 to hsk1',
      );
      expect(
        container.read(appControllerProvider).currentWordBookId,
        'hsk2',
        reason: 'state.currentWordBookId must remain hsk2 after save',
      );
    },
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _MemoryStudyPlanRepository implements StudyPlanRepository {
  _MemoryStudyPlanRepository(this.savedPlan);

  StudyPlan? savedPlan;

  @override
  Future<StudyPlan?> load(String uid) async => savedPlan;

  @override
  Future<StudyPlan> reset(StudyPlan plan) async {
    final now = DateTime.now();
    final resetPlan = plan.copyWith(
      startDate: DateTime(now.year, now.month, now.day),
      status: 'active',
      updatedAt: now,
    );
    savedPlan = resetPlan;
    return resetPlan;
  }

  @override
  Future<StudyPlan> save(StudyPlan plan) async {
    savedPlan = plan;
    return plan;
  }
}

WordBook _makeBook(String id, String title) => WordBook(
  id: id,
  title: title,
  category: 'exam',
  examType: title,
  coverUrl: '',
  totalWords: 1,
  includedWords: 1,
  description: '$title description',
  wordIds: const [],
  createdAt: DateTime(2026, 6, 29),
  words: const [],
);

class _TwoBookLearningRepository implements LearningRepository {
  @override
  Future<List<WordBook>> listWordBooks() async => [
    _makeBook('hsk1', 'HSK 1'),
    _makeBook('hsk2', 'HSK 2'),
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
