import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/utils/quiz_localization.dart';
import 'package:linguaquest/core/utils/custom_word_localization.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
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
    final custom = CustomWord.create(
      id: 'custom-ambiguous',
      uid: 'u1',
      word: 'ambiguous',
      meaning: '含糊的',
      exampleSentence: 'The sentence was ambiguous.',
      note: 'A target vocabulary item commonly tested as “含糊的”.',
      now: DateTime(2026, 6, 18),
    );

    test('keeps Chinese meaning only for Chinese UI', () {
      expect(customWordMeaningFor(custom, 'zh'), '含糊的');
    });

    test('removes Chinese text from generated English and Malay notes', () {
      expect(
        customWordMeaningFor(custom, 'en'),
        'Review vocabulary item for ambiguous.',
      );
      expect(
        customWordMeaningFor(custom, 'ms'),
        'Item kosa kata ulang kaji untuk ambiguous.',
      );
      expect(customWordMeaningFor(custom, 'en'), isNot(contains('含糊的')));
      expect(customWordMeaningFor(custom, 'ms'), isNot(contains('含糊的')));
    });

    test('study session queue uses localized custom review meaning', () {
      final item = StudySessionQueueItem(
        id: 'q1',
        wordId: custom.id,
        source: StudySessionItemSource.dueReview,
        step: StudySessionStep.reviewRecall,
        customWord: custom,
        attempt: 0,
        affectsSchedule: true,
      );

      expect(item.meaningFor('en'), 'Review vocabulary item for ambiguous.');
      expect(item.meaningFor('en'), isNot(contains('含糊的')));
    });

    test('training word conversion exposes localized definitions', () {
      final converted = wordFromCustomWord(custom);

      expect(
        converted.primaryDefinitionFor('en'),
        'Review vocabulary item for ambiguous.',
      );
      expect(
        converted.primaryDefinitionFor('ms'),
        'Item kosa kata ulang kaji untuk ambiguous.',
      );
      expect(converted.primaryDefinitionFor('zh'), '含糊的');
      expect(converted.primaryDefinitionFor('en'), isNot(contains('含糊的')));
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
