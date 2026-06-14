import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/dictionary_search.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  group('dictionary_search', () {
    test(
      'fallback current words are used when current wordbook is missing',
      () {
        final word = _word(id: 'w1', text: 'apple', meaning: '苹果');

        final results = searchDictionaryWords(
          wordBooks: const [],
          currentWordBookId: 'current',
          scope: DictionarySearchScope.currentWordBook,
          query: 'apple',
          currentWords: [word],
        );

        expect(results, hasLength(1));
        expect(results.single.word.id, 'w1');
        expect(results.single.book.id, 'current');
        expect(results.single.book.title, '当前词书');
        expect(results.single.inCurrentWordBook, isTrue);
      },
    );

    test(
      'current scope returns empty for no current wordbook and no current words',
      () {
        final results = searchDictionaryWords(
          wordBooks: const [],
          currentWordBookId: 'current',
          scope: DictionarySearchScope.currentWordBook,
          query: 'apple',
          currentWords: const [],
        );

        expect(results, isEmpty);
      },
    );

    test('all-wordbooks search scans every book', () {
      final target = _word(id: 'w1', text: 'apple', meaning: '苹果');
      final distractor = _word(id: 'w2', text: 'banana', meaning: '香蕉');
      final bookA = _wordBook(id: 'a', words: [target]);
      final bookB = _wordBook(id: 'b', words: [distractor]);

      final results = searchDictionaryWords(
        wordBooks: [bookA, bookB],
        currentWordBookId: 'missing',
        scope: DictionarySearchScope.allWordBooks,
        query: 'banana',
      );

      expect(results, hasLength(1));
      expect(results.single.word.id, 'w2');
      expect(results.single.book.id, 'b');
    });

    test('custom word search ranks exact and prefix matches first', () {
      final now = DateTime(2026, 1, 1);
      final results = searchCustomWords(
        query: 'app',
        customWords: [
          _customWord(id: 'note', text: 'banana', meaning: 'app note', now: now),
          _customWord(id: 'prefix', text: 'application', meaning: '应用', now: now),
          _customWord(id: 'exact', text: 'app', meaning: '应用程序', now: now),
          _customWord(id: 'middle', text: 'snapple', meaning: '饮料', now: now),
        ],
      );

      expect(
        results.map((result) => result.word.id),
        ['exact', 'prefix', 'middle', 'note'],
      );
    });
  });
}

CustomWord _customWord({
  required String id,
  required String text,
  required String meaning,
  required DateTime now,
}) {
  return CustomWord.create(
    id: id,
    uid: 'u1',
    word: text,
    meaning: meaning,
    exampleSentence: '',
    now: now,
  );
}

Word _word({
  required String id,
  required String text,
  required String meaning,
}) {
  return Word(
    id: id,
    word: text,
    phonetic: '',
    meaning: meaning,
    definition: '$text definition',
    partOfSpeech: 'noun',
    exampleSentence: '',
    exampleTranslation: '',
    imageCue: 'A',
    difficulty: 'Medium',
    tags: const [],
  );
}

WordBook _wordBook({required String id, required List<Word> words}) {
  return WordBook(
    id: id,
    title: 'book-$id',
    category: 'exam',
    examType: '',
    coverUrl: '',
    totalWords: words.length,
    includedWords: words.length,
    description: '',
    wordIds: [for (final word in words) word.id],
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    words: words,
  );
}
