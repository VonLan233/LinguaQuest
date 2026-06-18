import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/utils/quiz_localization.dart';
import 'package:linguaquest/core/utils/custom_word_localization.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_word.dart';
import 'package:linguaquest/features/study/session/session_queue_builder.dart';

Word _word({
  String word = 'allocate',
  String meaning = '分配',
  String definition = 'to distribute',
  List<String> definitions = const ['分配', '划拨'],
  List<String> englishDefinitions = const ['to distribute', 'to assign'],
  List<String> malayDefinitions = const ['memperuntukkan'],
}) {
  return Word(
    id: word,
    word: word,
    phonetic: '',
    meaning: meaning,
    definition: definition,
    partOfSpeech: 'verb',
    exampleSentence: '',
    exampleTranslation: '',
    imageCue: 'A',
    difficulty: 'Medium',
    tags: const [],
    definitions: definitions,
    englishDefinitions: englishDefinitions,
    malayDefinitions: malayDefinitions,
  );
}

void main() {
  group('custom review word localized meanings', () {
    final enriched = CustomWord.create(
      id: 'custom-ambiguous',
      uid: 'u1',
      word: 'ambiguous',
      meaning: '含糊的',
      exampleSentence: 'The sentence was ambiguous.',
      now: DateTime(2026, 6, 18),
      definitions: const ['含糊的'],
      englishDefinitions: const ['unclear or open to interpretation'],
      malayDefinitions: const ['kabur'],
    );

    final manual = CustomWord.create(
      id: 'custom-gizmo',
      uid: 'u1',
      word: 'gizmo',
      meaning: '小玩意',
      exampleSentence: '',
      now: DateTime(2026, 6, 18),
    );

    test('uses stored per-language definitions when present', () {
      expect(customWordMeaningFor(enriched, 'zh'), '含糊的');
      expect(
        customWordMeaningFor(enriched, 'en'),
        'unclear or open to interpretation',
      );
      expect(customWordMeaningFor(enriched, 'ms'), 'kabur');
    });

    test('manual word with only a meaning shows it verbatim everywhere', () {
      expect(customWordMeaningFor(manual, 'zh'), '小玩意');
      expect(customWordMeaningFor(manual, 'en'), '小玩意');
      expect(customWordMeaningFor(manual, 'ms'), '小玩意');
    });

    test('ms falls back to the English definition before the raw meaning', () {
      final noMs = enriched.copyWith(malayDefinitions: const []);
      expect(
        customWordMeaningFor(noMs, 'ms'),
        'unclear or open to interpretation',
      );
    });

    test('skips CJK-contaminated English filler and shows meaning instead', () {
      final filler = CustomWord.create(
        id: 'custom-filler',
        uid: 'u1',
        word: 'a',
        meaning: '字母A',
        exampleSentence: '',
        now: DateTime(2026, 6, 18),
        englishDefinitions: const [
          'A target vocabulary item commonly tested as “字母A”.',
        ],
      );
      expect(customWordMeaningFor(filler, 'en'), '字母A');
      expect(
        customWordMeaningFor(filler, 'en'),
        isNot(contains('target vocabulary')),
      );
    });

    test('study session queue uses the stored localized meaning', () {
      final item = StudySessionQueueItem(
        id: 'q1',
        wordId: enriched.id,
        source: StudySessionItemSource.dueReview,
        step: StudySessionStep.reviewRecall,
        customWord: enriched,
        attempt: 0,
        affectsSchedule: true,
      );

      expect(item.meaningFor('en'), 'unclear or open to interpretation');
    });

    test('training word conversion exposes the stored definitions', () {
      final converted = wordFromCustomWord(enriched);

      expect(
        converted.primaryDefinitionFor('en'),
        'unclear or open to interpretation',
      );
      expect(converted.primaryDefinitionFor('ms'), 'kabur');
      expect(converted.primaryDefinitionFor('zh'), '含糊的');
    });

    test('round-trips the multilingual definition lists through JSON', () {
      final restored = CustomWord.fromJson(enriched.toJson());
      expect(restored.definitions, ['含糊的']);
      expect(restored.englishDefinitions, ['unclear or open to interpretation']);
      expect(restored.malayDefinitions, ['kabur']);
    });

    test('legacy JSON without the lists decodes empty and shows meaning', () {
      final json = manual.toJson()
        ..remove('definitions')
        ..remove('englishDefinitions')
        ..remove('malayDefinitions');
      final legacy = CustomWord.fromJson(json);
      expect(legacy.englishDefinitions, isEmpty);
      expect(customWordMeaningFor(legacy, 'en'), '小玩意');
    });
  });

  group('UserWord.toReviewCard multilingual backfill', () {
    final source = _word(
      word: 'ambiguous',
      meaning: '含糊的',
      definitions: const ['含糊的'],
      englishDefinitions: const ['unclear or open to interpretation'],
      malayDefinitions: const ['kabur'],
    );
    final userWord = UserWord.create(
      uid: 'u1',
      word: source,
      wordBookId: 'beginner',
      now: DateTime(2026, 6, 18),
    );

    test('without a source the card keeps only the scalar meaning', () {
      final card = userWord.toReviewCard();
      expect(card.englishDefinitions, isEmpty);
      expect(customWordMeaningFor(card, 'en'), '含糊的');
    });

    test('with a source the card carries the localized definitions', () {
      final card = userWord.toReviewCard(source: source);
      expect(
        customWordMeaningFor(card, 'en'),
        'unclear or open to interpretation',
      );
      expect(customWordMeaningFor(card, 'ms'), 'kabur');
      expect(customWordMeaningFor(card, 'zh'), '含糊的');
    });
  });

  group('Word.definitionsFor / primaryDefinitionFor', () {
    final w = _word();

    test('zh returns Chinese definitions', () {
      expect(w.definitionsFor('zh'), ['分配', '划拨']);
      expect(w.primaryDefinitionFor('zh'), '分配');
    });

    test('en returns English definitions', () {
      expect(w.definitionsFor('en'), ['to distribute', 'to assign']);
      expect(w.primaryDefinitionFor('en'), 'to distribute');
    });

    test('ms returns Malay definitions', () {
      expect(w.definitionsFor('ms'), ['memperuntukkan']);
      expect(w.primaryDefinitionFor('ms'), 'memperuntukkan');
    });

    test(
      'en falls back to scalar English definition when localized list empty',
      () {
        final noEn = _word(englishDefinitions: const []);
        expect(noEn.definitionsFor('en'), ['to distribute']);
      },
    );

    test('en filters generated definitions that still contain Chinese', () {
      final generated = _word(
        word: 'ambiguous',
        meaning: '含糊的',
        definitions: const ['含糊的'],
        englishDefinitions: const [
          'A target vocabulary item commonly tested as “含糊的”.',
        ],
        definition: 'A target vocabulary item commonly tested as “含糊的”.',
      );

      expect(
        generated.primaryDefinitionFor('en'),
        'Vocabulary item for ambiguous.',
      );
      expect(generated.primaryDefinitionFor('en'), isNot(contains('含糊的')));
    });

    test('ms falls back to English then scalar English definition', () {
      final noMs = _word(malayDefinitions: const []);
      expect(noMs.definitionsFor('ms'), ['to distribute', 'to assign']);
      final noMsNoEn = _word(
        malayDefinitions: const [],
        englishDefinitions: const [],
      );
      expect(noMsNoEn.definitionsFor('ms'), ['to distribute']);
    });

    test('zh falls back to English when definitions empty', () {
      final noZh = _word(definitions: const []);
      expect(noZh.definitionsFor('zh'), ['to distribute', 'to assign']);
    });

    test('legacy/custom word with only scalar fields still resolves', () {
      final legacy = _word(
        definitions: const [],
        englishDefinitions: const [],
        malayDefinitions: const [],
        meaning: '分配',
        definition: 'to distribute',
      );
      expect(legacy.primaryDefinitionFor('zh'), '分配');
      expect(legacy.primaryDefinitionFor('ms'), 'to distribute');
      expect(legacy.primaryDefinitionFor('en'), 'to distribute');
    });

    test('unknown locale defaults to Chinese', () {
      expect(w.primaryDefinitionFor('fr'), '分配');
    });
  });

  group('WordBook.nameFor', () {
    final book = WordBook(
      id: 'ielts',
      title: '雅思核心词汇',
      titleEn: 'IELTS Core Words',
      titleMs: 'Perkataan Teras IELTS',
      category: 'exam',
      examType: 'IELTS',
      coverUrl: '',
      totalWords: 0,
      includedWords: 0,
      description: '',
      wordIds: const [],
      createdAt: DateTime(2024, 1, 1),
      words: const [],
    );

    test('zh returns Chinese title', () {
      expect(book.nameFor('zh'), '雅思核心词汇');
    });

    test('en returns titleEn', () {
      expect(book.nameFor('en'), 'IELTS Core Words');
    });

    test('ms returns titleMs', () {
      expect(book.nameFor('ms'), 'Perkataan Teras IELTS');
    });

    test('en falls back to title when titleEn empty', () {
      final noEn = WordBook(
        id: 'x',
        title: '词书',
        category: 'exam',
        examType: '',
        coverUrl: '',
        totalWords: 0,
        includedWords: 0,
        description: '',
        wordIds: const [],
        createdAt: DateTime(2024, 1, 1),
        words: const [],
      );
      expect(noEn.nameFor('en'), '词书');
      expect(noEn.nameFor('ms'), '词书');
    });

    test('ms falls back to titleEn then title', () {
      final onlyEn = WordBook(
        id: 'x',
        title: '词书',
        titleEn: 'Book',
        category: 'exam',
        examType: '',
        coverUrl: '',
        totalWords: 0,
        includedWords: 0,
        description: '',
        wordIds: const [],
        createdAt: DateTime(2024, 1, 1),
        words: const [],
      );
      expect(onlyEn.nameFor('ms'), 'Book');
    });

    test('round trips titleEn/titleMs through JSON', () {
      final restored = WordBook.fromJson(book.toJson());
      expect(restored.nameFor('en'), 'IELTS Core Words');
      expect(restored.nameFor('ms'), 'Perkataan Teras IELTS');
      expect(restored.nameFor('zh'), '雅思核心词汇');
    });
  });

  group('localizeQuizOptions', () {
    test('translates options + answer; correctness preserved', () {
      final pool = [
        _word(
          word: 'allocate',
          meaning: '分配',
          definitions: const ['分配'],
          englishDefinitions: const ['to distribute'],
          malayDefinitions: const ['memperuntukkan'],
        ),
        _word(
          word: 'compare',
          meaning: '比较',
          definitions: const ['比较'],
          englishDefinitions: const ['to compare'],
          malayDefinitions: const ['membandingkan'],
        ),
      ];
      final question = QuizQuestion(
        id: 'q1',
        type: QuizQuestionType.meaningChoice,
        prompt: '',
        answer: '分配',
        options: const ['分配', '比较'],
        explanation: '',
        word: pool.first,
      );

      final localized = localizeQuizQuestion(question, pool, 'en');
      expect(localized.options, containsAll(['to distribute', 'to compare']));
      expect(localized.answer, 'to distribute');
      // The displayed correct option still equals the localized answer.
      expect(localized.options.contains(localized.answer), isTrue);
    });

    test('word-answer questions (chineseChoice) are untouched', () {
      final pool = [_word(word: 'allocate')];
      final question = QuizQuestion(
        id: 'q1',
        type: QuizQuestionType.chineseChoice,
        prompt: '',
        answer: 'allocate',
        options: const ['allocate', 'compare'],
        explanation: '',
        word: pool.first,
      );
      final localized = localizeQuizQuestion(question, pool, 'en');
      expect(localized.answer, 'allocate');
      expect(localized.options, ['allocate', 'compare']);
    });

    test('zh locale leaves meaning options unchanged', () {
      final pool = [
        _word(word: 'allocate', meaning: '分配', definitions: const ['分配']),
        _word(word: 'compare', meaning: '比较', definitions: const ['比较']),
      ];
      final question = QuizQuestion(
        id: 'q1',
        type: QuizQuestionType.meaningChoice,
        prompt: '',
        answer: '分配',
        options: const ['分配', '比较'],
        explanation: '',
        word: pool.first,
      );
      final localized = localizeQuizQuestion(question, pool, 'zh');
      expect(localized.answer, '分配');
      expect(localized.options, ['分配', '比较']);
    });
  });
}
