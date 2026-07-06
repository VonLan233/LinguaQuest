import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/lesson_factory.dart';
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

  test('mixed sessions do not overfill when review target rounds to zero', () {
    final now = DateTime(2026, 6, 4, 9);
    final plan = builder.build(
      newWords: [_word('fresh')],
      dueWords: [_customWord('due-1', now), _customWord('due-2', now)],
      weakWords: const [],
      dailyGoal: 1,
    );

    expect(plan.dueReviewCount, 0);
    expect(plan.newWordCount, 1);
    expect(plan.items.every((item) => item.isNewWord), isTrue);
  });

  test('mixed sessions do not overfill when new target rounds to zero', () {
    final now = DateTime(2026, 6, 4, 9);
    final plan = builder.build(
      newWords: [
        for (var index = 0; index < 10; index++) _word('fresh-$index'),
      ],
      dueWords: [
        for (var index = 0; index < 8; index++)
          _customWord('due-$index', now, wrongCount: index),
      ],
      weakWords: const [],
      dailyGoal: 1,
    );

    expect(plan.dueReviewCount, 1);
    expect(plan.newWordCount, 0);
    expect(plan.items, hasLength(1));
    expect(plan.items.single.source, StudySessionItemSource.dueReview);
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

  // ── 新题型测试（TDD：先红后绿）────────────────────────────────────────────

  group('new exercise types', () {
    final distractors = [
      for (var i = 0; i < 6; i++) _word('dist-$i'),
    ];

    test('sentenceCloze question prompt contains ____ blank', () {
      // 给定有 exampleSentence 的词，生成 sentenceCloze 时 prompt 应含 ____
      final word = _word(
        'allocate',
        exampleSentence: 'The manager will allocate the budget next week.',
      );
      final question = buildQuestionsForWords(
        lessonId: 'test-lesson',
        words: [word],
        distractorWords: distractors,
        forceType: QuizQuestionType.sentenceCloze,
      ).single;

      expect(question.type, QuizQuestionType.sentenceCloze);
      expect(question.prompt, contains('____'));
      expect(question.answer, word.word);
      expect(question.options, contains(word.word));
      expect(question.options, hasLength(4));
    });

    test('confusableChoice question is generated without throwing', () {
      // confusableChoice 使用 synonyms 或干扰词构建选项，不应抛异常
      final word = _wordWithExampleAndCollocations('distribute');
      final question = buildQuestionsForWords(
        lessonId: 'test-lesson',
        words: [word],
        distractorWords: distractors,
        forceType: QuizQuestionType.confusableChoice,
      ).single;

      expect(question.type, QuizQuestionType.confusableChoice);
      expect(question.options, isNotEmpty);
      expect(question.answer, isNotEmpty);
    });

    test('collocationChoice uses word collocations when available', () {
      final word = _wordWithExampleAndCollocations('allocate');
      final question = buildQuestionsForWords(
        lessonId: 'test-lesson',
        words: [word],
        distractorWords: distractors,
        forceType: QuizQuestionType.collocationChoice,
      ).single;

      expect(question.type, QuizQuestionType.collocationChoice);
      expect(question.answer, isNotEmpty);
      expect(question.options, hasLength(greaterThanOrEqualTo(2)));
    });

    test('collocationChoice degrades to meaningChoice when no collocations', () {
      // 无搭配词时降级为 meaningChoice
      final word = _word('basic'); // 无 collocations
      final question = buildQuestionsForWords(
        lessonId: 'test-lesson',
        words: [word],
        distractorWords: distractors,
        forceType: QuizQuestionType.collocationChoice,
      ).single;

      expect(question.type, QuizQuestionType.meaningChoice);
    });

    test('derivativeChoice uses derivatives when available', () {
      final word = _wordWithExampleAndCollocations('allocate');
      final question = buildQuestionsForWords(
        lessonId: 'test-lesson',
        words: [word],
        distractorWords: distractors,
        forceType: QuizQuestionType.derivativeChoice,
      ).single;

      expect(question.type, QuizQuestionType.derivativeChoice);
      expect(question.answer, isNotEmpty);
    });

    test('derivativeChoice degrades to meaningChoice when no derivatives', () {
      final word = _word('simple'); // 无 derivatives
      final question = buildQuestionsForWords(
        lessonId: 'test-lesson',
        words: [word],
        distractorWords: distractors,
        forceType: QuizQuestionType.derivativeChoice,
      ).single;

      expect(question.type, QuizQuestionType.meaningChoice);
    });

    test('sentenceCloze degrades gracefully when no exampleSentence', () {
      // 无例句时降级为 meaningChoice
      final word = Word(
        id: 'bare',
        word: 'bare',
        phonetic: '/beə/',
        meaning: 'basic',
        definition: 'having no covering',
        partOfSpeech: 'adj',
        exampleSentence: '', // 无例句
        exampleTranslation: '',
        imageCue: 'B',
        difficulty: 'Easy',
        tags: const [],
      );
      final question = buildQuestionsForWords(
        lessonId: 'test-lesson',
        words: [word],
        distractorWords: distractors,
        forceType: QuizQuestionType.sentenceCloze,
      ).single;

      expect(question.type, QuizQuestionType.meaningChoice);
    });

    test('_typeForWord covers multiple question types in large enough word pool', () {
      // 扩展后 _typeForWord 应能返回新题型
      // 通过生成大量词并检查类型分布
      final words = [
        for (var i = 0; i < 50; i++)
          _wordWithExampleAndCollocations('word-$i'),
      ];
      final allWords = [...words];
      final questions = buildQuestionsForWords(
        lessonId: 'type-coverage',
        words: words,
        distractorWords: allWords,
      );

      final types = questions.map((q) => q.type).toSet();
      // 至少应出现4种题型（扩展后覆盖更多）
      expect(types.length, greaterThanOrEqualTo(4));
    });
  });
}

Word _word(String id, {String exampleSentence = ''}) {
  return Word(
    id: id,
    word: id,
    phonetic: '/$id/',
    meaning: '释义 $id',
    definition: 'definition $id',
    partOfSpeech: 'noun',
    exampleSentence: exampleSentence.isEmpty ? 'Use $id in a sentence.' : exampleSentence,
    exampleTranslation: '例句 $id',
    imageCue: '⭐',
    difficulty: 'Easy',
    tags: const ['test'],
  );
}

Word _wordWithExampleAndCollocations(String id) {
  return Word(
    id: id,
    word: id,
    phonetic: '/$id/',
    meaning: '释义 $id',
    definition: 'definition $id',
    partOfSpeech: 'verb',
    exampleSentence: 'She will $id the resources carefully.',
    exampleTranslation: '她将仔细地 $id 资源。',
    imageCue: '⭐',
    difficulty: 'Easy',
    tags: const ['test'],
    collocations: [WordPhrase(phrase: '$id resources'), WordPhrase(phrase: '$id time')],
    synonyms: ['distribute', 'assign'],
    derivatives: ['${id}d', '${id}ing', '${id}ion'],
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

