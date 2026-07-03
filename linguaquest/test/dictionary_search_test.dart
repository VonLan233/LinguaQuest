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

    // -----------------------------------------------------------------------
    // P2f: Japanese kana/romaji search
    // -----------------------------------------------------------------------

    test('P2f: Japanese word is found by kanji (word field)', () {
      final jaWord = _jaWord(
        id: 'nihongo',
        kanji: '日本語',
        kana: 'にほんご',
        romaji: 'nihongo',
        meaning: '日语',
      );
      final book = _wordBook(id: 'jlpt_n4', words: [jaWord]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'jlpt_n4',
        scope: DictionarySearchScope.allWordBooks,
        query: '日本語',
      );

      expect(results, hasLength(1));
      expect(results.single.word.id, 'nihongo');
    });

    test('P2f: Japanese word is found by kana', () {
      final jaWord = _jaWord(
        id: 'nihongo',
        kanji: '日本語',
        kana: 'にほんご',
        romaji: 'nihongo',
        meaning: '日语',
      );
      final book = _wordBook(id: 'jlpt_n4', words: [jaWord]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'jlpt_n4',
        scope: DictionarySearchScope.allWordBooks,
        query: 'にほんご',
      );

      expect(results, hasLength(1));
      expect(results.single.word.id, 'nihongo');
      expect(results.single.matchedBy, 'かな');
    });

    test('P2f: Japanese word is found by romaji (full)', () {
      final jaWord = _jaWord(
        id: 'nihongo',
        kanji: '日本語',
        kana: 'にほんご',
        romaji: 'nihongo',
        meaning: '日语',
      );
      final book = _wordBook(id: 'jlpt_n4', words: [jaWord]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'jlpt_n4',
        scope: DictionarySearchScope.allWordBooks,
        query: 'nihongo',
      );

      expect(results, hasLength(1));
      expect(results.single.word.id, 'nihongo');
      expect(results.single.matchedBy, 'ローマ字');
    });

    test('P2f: Japanese word is found by partial romaji prefix', () {
      final jaWord = _jaWord(
        id: 'sakura',
        kanji: '桜',
        kana: 'さくら',
        romaji: 'sakura',
        meaning: 'cherry blossom',
      );
      final book = _wordBook(id: 'jlpt_n5', words: [jaWord]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'jlpt_n5',
        scope: DictionarySearchScope.allWordBooks,
        query: 'saku',
      );

      expect(results, hasLength(1));
      expect(results.single.word.id, 'sakura');
    });

    test('P2f: zh word without kana/romaji is NOT found by kana query', () {
      final zhWord = _word(id: 'apple', text: 'apple', meaning: '苹果');
      final book = _wordBook(id: 'hsk1', words: [zhWord]);

      // A kana query should not match Chinese words (kana is empty).
      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'hsk1',
        scope: DictionarySearchScope.allWordBooks,
        query: 'あ',
      );

      expect(results, isEmpty);
    });

    test('P-pinyin: 无声调拼音 ai 优先命中 爱（而非英文释义里 train/car）', () {
      final ai = _word(id: 'ai', text: '爱', meaning: '爱', phonetic: 'ài');
      final shangche = _word(
        id: 'shangche',
        text: '上车',
        meaning: '上车',
        englishDefinitions: const ['to get on or into (a bus, train, car etc)'],
      );
      final book = _wordBook(id: 'hsk1', words: [shangche, ai]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'hsk1',
        scope: DictionarySearchScope.allWordBooks,
        query: 'ai',
      );

      expect(results.first.word.id, 'ai');
      expect(results.first.matchedBy, '汉字拼音精确');
    });

    test('P-pinyin-exact: 精确拼音 ai 置顶于子串拼音（爱 在 太 之前）', () {
      final ai = _word(id: 'ai', text: '爱', meaning: '爱', phonetic: 'ài');
      final tai = _word(id: 'tai', text: '太', meaning: '太', phonetic: 'tài');
      // 列表故意把子串匹配的 太 放前面，验证排序而非顺序侥幸。
      final book = _wordBook(id: 'hsk1', words: [tai, ai]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'hsk1',
        scope: DictionarySearchScope.allWordBooks,
        query: 'ai',
      );

      expect(results.first.word.id, 'ai');
      expect(results.first.matchedBy, '汉字拼音精确');
      final taiResult = results.firstWhere((r) => r.word.id == 'tai');
      expect(taiResult.matchedBy, '汉字拼音'); // 子串
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
  String phonetic = '',
  List<String> englishDefinitions = const [],
}) {
  return Word(
    id: id,
    word: text,
    phonetic: phonetic,
    meaning: meaning,
    definition: '$text definition',
    partOfSpeech: 'noun',
    exampleSentence: '',
    exampleTranslation: '',
    imageCue: 'A',
    difficulty: 'Medium',
    tags: const [],
    englishDefinitions: englishDefinitions,
  );
}

/// Creates a Japanese word with kanji, kana, romaji, and meaning.
Word _jaWord({
  required String id,
  required String kanji,
  required String kana,
  required String romaji,
  required String meaning,
}) {
  return Word(
    id: id,
    word: kanji,
    phonetic: '',
    kana: kana,
    romaji: romaji,
    meaning: meaning,
    definition: meaning,
    englishDefinitions: [meaning],
    partOfSpeech: 'noun',
    exampleSentence: '',
    exampleTranslation: '',
    imageCue: 'J',
    difficulty: 'Easy',
    tags: const [],
    examLevel: 4,
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
