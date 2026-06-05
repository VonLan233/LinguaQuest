import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/study/session/session_queue_builder.dart';

void main() {
  const builder = StudySessionQueueBuilder();

  test('builds due-heavy mixed sessions with review priority', () {
    final now = DateTime(2026, 6, 4, 9);
    final plan = builder.build(
      newWords: [_word('new-1'), _word('new-2'), _word('new-3')],
      dueWords: [
        for (var index = 0; index < 8; index++)
          _customWord('due-$index', now, wrongCount: index),
      ],
      weakWords: const [],
      dailyGoal: 10,
    );

    expect(plan.reviewTargetRatio, 0.7);
    expect(plan.newTargetRatio, 0.3);
    expect(plan.dueReviewCount, 7);
    expect(plan.newWordCount, 3);
    expect(
      plan.items
          .take(4)
          .every((item) => item.source == StudySessionItemSource.dueReview),
      isTrue,
    );
  });

  test('new words include understanding, recognition, and short recall', () {
    final plan = builder.build(
      newWords: [_word('fresh')],
      dueWords: const [],
      weakWords: const [],
      dailyGoal: 1,
      mode: StudySessionEntryMode.newOnly,
    );

    expect(
      plan.items.map((item) => item.step),
      containsAllInOrder([
        StudySessionStep.understanding,
        StudySessionStep.recognition,
        StudySessionStep.shortRecall,
      ]),
    );
  });

  test(
    'mixed sessions use the full new-word target when no reviews are due',
    () {
      final plan = builder.build(
        newWords: [
          for (var index = 0; index < 10; index++) _word('new-$index'),
        ],
        dueWords: const [],
        weakWords: const [],
        dailyGoal: 10,
      );

      expect(plan.reviewTargetRatio, 0.0);
      expect(plan.newTargetRatio, 1.0);
      expect(plan.dueReviewCount, 0);
      expect(plan.newWordCount, 10);
    },
  );

  test('sanitizes negative daily goals before target allocation', () {
    final plan = builder.build(
      newWords: [_word('fresh-1'), _word('fresh-2')],
      dueWords: const [],
      weakWords: const [],
      dailyGoal: -5,
    );

    expect(plan.reviewTargetRatio, 0.0);
    expect(plan.newTargetRatio, 1.0);
    expect(plan.newWordCount, 1);
    expect(plan.items.map((item) => item.wordId).toSet(), {'fresh-1'});
  });

  test('deduplicates weak words without duplicating due reviews', () {
    final now = DateTime(2026, 6, 4, 9);
    final duplicateWeak = _customWord('weak-1', now, wrongCount: 4);
    final dueWeak = _customWord('due-1', now, wrongCount: 6);
    final plan = builder.build(
      newWords: const [],
      dueWords: [dueWeak],
      weakWords: [duplicateWeak, duplicateWeak, dueWeak],
      dailyGoal: 4,
    );

    expect(plan.weakWordCount, 1);
    expect(
      plan.items.where(
        (item) => item.source == StudySessionItemSource.weakReview,
      ),
      hasLength(1),
    );
  });

  test('wrong answers reappear after a short gap and at session end', () {
    final now = DateTime(2026, 6, 4, 9);
    final first = StudySessionQueueItem(
      id: 'due-1:review',
      wordId: 'due-1',
      source: StudySessionItemSource.dueReview,
      step: StudySessionStep.reviewRecall,
      customWord: _customWord('due-1', now),
      attempt: 1,
      affectsSchedule: true,
    );
    final queue = [
      for (var index = 0; index < 7; index++)
        StudySessionQueueItem(
          id: 'due-$index:review',
          wordId: 'due-$index',
          source: StudySessionItemSource.dueReview,
          step: StudySessionStep.reviewRecall,
          customWord: _customWord('due-$index', now),
          attempt: 1,
          affectsSchedule: true,
        ),
    ];

    final requeued = builder.requeueWrongAnswer(queue, first, answeredCount: 2);

    expect(requeued.first.step, StudySessionStep.knowledgeCard);
    final recallIndexes = <int>[
      for (var i = 0; i < requeued.length; i++)
        if (requeued[i].wordId == first.wordId &&
            requeued[i].step == StudySessionStep.reviewRecall)
          i,
    ];
    expect(recallIndexes.first, inInclusiveRange(3, 6));
    expect(recallIndexes.last, requeued.length - 1);
  });
}

Word _word(String id) {
  return Word(
    id: id,
    word: id,
    phonetic: '/$id/',
    meaning: '释义 $id',
    definition: 'definition $id',
    partOfSpeech: 'noun',
    exampleSentence: 'Use $id in a sentence.',
    exampleTranslation: '例句 $id',
    imageCue: '⭐',
    difficulty: 'Easy',
    tags: const ['test'],
  );
}

CustomWord _customWord(String id, DateTime now, {int wrongCount = 0}) {
  return CustomWord.create(
    id: id,
    uid: 'u1',
    word: id,
    meaning: '释义 $id',
    exampleSentence: 'Use $id in a sentence.',
    now: now,
  ).copyWith(wrongCount: wrongCount, nextReviewAt: now);
}
