import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/lesson_factory.dart';
import 'package:linguaquest/data/models/lesson.dart';

WordBook _book() {
  Word w(String id, String hanzi, String pinyin, String meaning) => Word(
    id: id,
    word: hanzi,
    phonetic: pinyin,
    meaning: meaning,
    definition: meaning,
    partOfSpeech: 'n',
    exampleSentence: '',
    exampleTranslation: '',
    imageCue: '',
    difficulty: 'Easy',
    tags: const [],
    phoneticUK: pinyin,
    phoneticUS: pinyin,
    definitions: [meaning],
    englishDefinitions: [meaning],
    hskLevel: 1,
  );
  return WordBook(
    id: 'hsk1',
    title: 'HSK 1',
    titleEn: 'HSK 1',
    category: 'hsk',
    examType: 'HSK 1',
    coverUrl: '',
    totalWords: 4,
    includedWords: 4,
    description: '',
    wordIds: const ['a', 'b', 'c', 'd'],
    createdAt: DateTime.utc(2026),
    words: [
      w('a', '爱', 'ài', 'to love'),
      w('b', '好', 'hǎo', 'good'),
      w('c', '人', 'rén', 'person'),
      w('d', '大', 'dà', 'big'),
    ],
  );
}

void main() {
  test('all generated prompts are English (no leftover Chinese prompt text)', () {
    final lessons = lessonsFromWordBook(_book());
    final prompts = [
      for (final lesson in lessons)
        for (final q in lesson.questions) q.prompt,
    ];
    expect(prompts, isNotEmpty);
    for (final prompt in prompts) {
      expect(
        prompt.contains('中文释义') || prompt.contains('拼写单词') ||
            prompt.contains('播放发音'),
        isFalse,
        reason: 'prompt still has old Chinese text: $prompt',
      );
    }
  });

  test('spelling answers are pinyin, choice answers map to the word', () {
    final lessons = lessonsFromWordBook(_book());
    for (final lesson in lessons) {
      for (final q in lesson.questions) {
        if (q.type == QuizQuestionType.spelling) {
          expect(q.answer, q.word.phonetic);
        }
        if (q.type == QuizQuestionType.meaningChoice) {
          expect(q.answer, q.word.meaning);
        }
        if (q.type == QuizQuestionType.chineseChoice) {
          expect(q.answer, q.word.word);
        }
      }
    }
  });

  test('context questions are not generated when there is no example', () {
    final lessons = lessonsFromWordBook(_book());
    final contextQs = [
      for (final lesson in lessons)
        for (final q in lesson.questions)
          if (q.type == QuizQuestionType.contextChoice) q,
    ];
    expect(contextQs, isEmpty);
  });
}
