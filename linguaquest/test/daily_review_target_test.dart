import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/study_plan.dart';

void main() {
  final now = DateTime(2026, 6, 18, 12);

  CustomWord baseWord(String id) => CustomWord.create(
    id: id,
    uid: 'u',
    word: id,
    meaning: 'm',
    exampleSentence: 'e',
    now: now,
  );

  CustomWord due(String id) =>
      baseWord(id).copyWith(nextReviewAt: now.subtract(const Duration(days: 1)));

  CustomWord reviewed(String id) =>
      baseWord(id).copyWith(nextReviewAt: now.add(const Duration(days: 1)));

  StudyPlan plan({required int reviewLimit, String status = 'active'}) =>
      StudyPlan(
        id: 'p',
        uid: 'u',
        wordBookId: 'beginner',
        dailyNewTarget: 4,
        dailyReviewLimit: reviewLimit,
        startDate: now,
        targetFinishDate: now,
        reminderTime: '20:00',
        status: status,
        createdAt: now,
        updatedAt: now,
      );

  group('AppState.dailyReviewTarget', () {
    test('stays stable when a due word is reviewed (no shrinking total)', () {
      final before = AppState.initial().copyWith(
        customWords: [due('a'), due('b'), due('c')],
        studyPlan: plan(reviewLimit: 10),
        todayReviewWordIds: <String>{},
      );
      expect(before.dailyReviewTarget, 3);

      // Reviewing 'a' pushes it out of the due set and records its id — the
      // home denominator must not shrink (this was the "5/4" bug).
      final after = before.copyWith(
        customWords: [reviewed('a'), due('b'), due('c')],
        todayReviewWordIds: {'a'},
      );
      expect(after.reviewQueue.length, 2); // live queue did shrink...
      expect(after.dailyReviewTarget, 3); // ...but the target held.
    });

    test('is stable without a study plan too', () {
      final before = AppState.initial().copyWith(
        customWords: [due('a'), due('b'), due('c')],
        todayReviewWordIds: <String>{},
      );
      expect(before.dailyReviewTarget, 3);

      final after = before.copyWith(
        customWords: [reviewed('a'), due('b'), due('c')],
        todayReviewWordIds: {'a'},
      );
      expect(after.dailyReviewTarget, 3);
    });

    test('caps at the plan review limit when more words are due', () {
      final state = AppState.initial().copyWith(
        customWords: [due('a'), due('b'), due('c'), due('d'), due('e')],
        studyPlan: plan(reviewLimit: 3),
        todayReviewWordIds: <String>{},
      );
      expect(state.dailyReviewTarget, 3);
    });

    test('is zero while the plan is paused', () {
      final state = AppState.initial().copyWith(
        customWords: [due('a'), due('b')],
        studyPlan: plan(reviewLimit: 10, status: 'paused'),
        todayReviewWordIds: <String>{},
      );
      expect(state.dailyReviewTarget, 0);
    });
  });
}
