import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_word.dart';
import 'package:linguaquest/features/reading/word_segmenter.dart';

Word _word(
  String id,
  String surface, {
  String meaning = '',
  String kana = '',
  List<String> englishDefinitions = const [],
}) {
  return Word(
    id: id,
    word: surface,
    phonetic: '',
    meaning: meaning,
    definition: meaning,
    partOfSpeech: '',
    exampleSentence: '',
    exampleTranslation: '',
    imageCue: '',
    difficulty: 'medium',
    tags: const [],
    kana: kana,
    englishDefinitions: englishDefinitions,
  );
}

WordBook _book(List<Word> words) {
  return WordBook(
    id: 'hsk1',
    title: 'HSK1',
    category: '',
    examType: '',
    coverUrl: '',
    totalWords: words.length,
    includedWords: words.length,
    description: '',
    wordIds: const [],
    createdAt: DateTime(2026, 1, 1),
    words: words,
  );
}

Article _article(List<ArticleVocabRef> vocab) {
  return Article(
    id: 'a1',
    language: 'zh',
    level: 'hsk1',
    theme: 'life',
    title: 't',
    paragraphs: const [],
    vocab: vocab,
    comprehension: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('buildHighlightVocab', () {
    test('merges article vocab surfaces + wordbook word/kana surfaces', () {
      final book = _book([
        _word('w1', '北京', meaning: 'Beijing'),
        _word('w2', '行', kana: 'いく'),
      ]);
      final article = _article(const [
        ArticleVocabRef(surface: '起来', reading: 'qǐ lái', meaning: 'get up'),
      ]);
      final vocab = buildHighlightVocab(article: article, wordBook: book);

      expect(vocab.byVocab.keys, contains('起来'));
      expect(vocab.byWord.keys, containsAll(<String>['北京', '行', 'いく']));
      // Longest-first ordering: '北京'/'起来' (len 2) before '行' (len 1).
      expect(vocab.surfacesLongestFirst.first.length, 2);
      expect(vocab.surfacesLongestFirst.last, '行');
    });
  });

  group('segmentParagraph longest-match', () {
    test('prefers the longest overlapping surface left-to-right', () {
      // "北京大学" should match the longer "北京大学" over "北京" when both exist.
      final book = _book([
        _word('w1', '北京', meaning: 'Beijing'),
        _word('w2', '北京大学', meaning: 'Peking University'),
        _word('w3', '大学', meaning: 'university'),
      ]);
      final vocab =
          buildHighlightVocab(article: _article(const []), wordBook: book);
      final tokens = segmentParagraph(
        text: '北京大学很大',
        vocab: vocab,
        userWords: const [],
        reviewWords: const [],
      );

      final matched =
          tokens.where((t) => t.isMatched).map((t) => t.text).toList();
      expect(matched, ['北京大学']);
      // Remaining "很大" → two plain char tokens.
      final plain =
          tokens.where((t) => !t.isMatched).map((t) => t.text).toList();
      expect(plain, ['很', '大']);
    });

    test('falls back to per-character plain tokens for unmatched runs', () {
      final book = _book([_word('w1', '水', meaning: 'water')]);
      final vocab =
          buildHighlightVocab(article: _article(const []), wordBook: book);
      final tokens = segmentParagraph(
        text: '我喝水',
        vocab: vocab,
        userWords: const [],
        reviewWords: const [],
      );

      expect(tokens.map((t) => t.text).toList(), ['我', '喝', '水']);
      expect(tokens[0].isMatched, isFalse);
      expect(tokens[1].isMatched, isFalse);
      expect(tokens[2].isMatched, isTrue);
      expect(tokens[2].text, '水');
    });

    test('matches japanese kana surfaces', () {
      final book = _book([_word('w1', '行', kana: 'いきます', meaning: 'to go')]);
      final vocab =
          buildHighlightVocab(article: _article(const []), wordBook: book);
      final tokens = segmentParagraph(
        text: 'まいにち いきます',
        vocab: vocab,
        userWords: const [],
        reviewWords: const [],
      );
      final matched =
          tokens.where((t) => t.isMatched).map((t) => t.text).toList();
      expect(matched, ['いきます']);
    });
  });

  group('classifyToken precedence', () {
    final word = _word('w1', '学习',
        meaning: '', englishDefinitions: const ['to study']);

    test('author key role wins over everything', () {
      const ref = ArticleVocabRef(surface: '学习', role: 'key');
      final learned = UserWord.create(
        uid: 'u',
        word: word,
        wordBookId: 'hsk1',
      ).copyWith(status: 'Mastered', masteryLevel: 5);
      expect(
        classifyToken(
          surface: '学习',
          vocab: ref,
          word: word,
          userWord: learned,
        ),
        WordClass.key,
      );
    });

    test('mastered/learned user word → known', () {
      final learned = UserWord.create(
        uid: 'u',
        word: word,
        wordBookId: 'hsk1',
      ).copyWith(status: 'Mastered', masteryLevel: 4);
      expect(
        classifyToken(surface: '学习', word: word, userWord: learned),
        WordClass.known,
      );
    });

    test('new/relearning or low-mastery user word → unknown (struggling)', () {
      final struggling = UserWord.create(
        uid: 'u',
        word: word,
        wordBookId: 'hsk1',
      ); // status New, mastery 0
      expect(
        classifyToken(surface: '学习', word: word, userWord: struggling),
        WordClass.unknown,
      );
    });

    test('in wordbook but never studied → new', () {
      expect(
        classifyToken(surface: '学习', word: word),
        WordClass.newWord,
      );
    });

    test('review word with high mastery → known, else unknown', () {
      final mastered = CustomWord.create(
        id: 'c1',
        uid: 'u',
        word: '学习',
        meaning: 'study',
        exampleSentence: '',
      ).copyWith(masteryLevel: 4);
      final weak = CustomWord.create(
        id: 'c2',
        uid: 'u',
        word: '学习',
        meaning: 'study',
        exampleSentence: '',
      ); // mastery 0
      expect(
        classifyToken(surface: '学习', reviewWord: mastered),
        WordClass.known,
      );
      expect(
        classifyToken(surface: '学习', reviewWord: weak),
        WordClass.unknown,
      );
    });

    test('segment classifies tokens from seeded user/review words', () {
      final book = _book([
        _word('w1', '学习', englishDefinitions: const ['to study']),
        _word('w2', '中国', meaning: 'China'),
      ]);
      final article = _article(const [
        ArticleVocabRef(surface: '中国', role: 'key', meaning: 'China'),
      ]);
      final vocab = buildHighlightVocab(article: article, wordBook: book);
      final learned = UserWord.create(
        uid: 'u',
        word: book.words.first,
        wordBookId: 'hsk1',
      ).copyWith(status: 'Mastered', masteryLevel: 5);

      final tokens = segmentParagraph(
        text: '学习中国',
        vocab: vocab,
        userWords: [learned],
        reviewWords: const [],
      );
      final byText = {for (final t in tokens) t.text: t};
      expect(byText['学习']!.wordClass, WordClass.known);
      expect(byText['中国']!.wordClass, WordClass.key); // author key wins
    });

    test('readingToken resolves meaning from vocab then word', () {
      const ref = ArticleVocabRef(surface: '起来', meaning: 'get up');
      const t1 = ReadingToken(
        text: '起来',
        wordClass: WordClass.key,
        vocab: ref,
      );
      expect(t1.meaningFor('en'), 'get up');

      final w = _word('w', '学习', englishDefinitions: const ['to study']);
      final t2 = ReadingToken(
        text: '学习',
        wordClass: WordClass.newWord,
        word: w,
      );
      expect(t2.meaningFor('en'), contains('to study'));
    });
  });
}
