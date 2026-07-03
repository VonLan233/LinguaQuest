import 'models/custom_word.dart';
import 'models/lesson.dart';
import '../core/utils/pinyin.dart';

final _whitespaceRegExp = RegExp(r'\s+');

enum DictionarySearchScope { currentWordBook, allWordBooks }

class DictionaryWordSearchResult {
  const DictionaryWordSearchResult({
    required this.word,
    required this.book,
    required this.matchedBy,
    required this.preview,
    required this.inCurrentWordBook,
  });

  final Word word;
  final WordBook book;
  final String matchedBy;
  final String preview;
  final bool inCurrentWordBook;
}

class CustomWordSearchResult {
  const CustomWordSearchResult({
    required this.word,
    required this.matchedBy,
    required this.preview,
  });

  final CustomWord word;
  final String matchedBy;
  final String preview;
}

List<DictionaryWordSearchResult> searchDictionaryWords({
  required List<WordBook> wordBooks,
  required String currentWordBookId,
  required DictionarySearchScope scope,
  required String query,
  List<Word>? currentWords,
  String Function(String tag) tagLabeler = _identity,
}) {
  final normalized = normalizeDictionaryQuery(query);
  if (normalized.isEmpty) return const [];

  final currentBook = wordBooks.firstWhereOrNull(
    (book) => book.id == currentWordBookId,
  );
  final currentScopeWords =
      currentWords ?? currentBook?.words ?? const <Word>[];
  final activeBook = currentBook ??
      (currentScopeWords.isNotEmpty
          ? _fallbackWordBook(
              currentWordBookId: currentWordBookId,
              words: currentScopeWords,
            )
          : null);

  final currentWordNames = {
    for (final word in currentScopeWords)
      normalizeDictionaryQuery(word.word)
  };
  final sources = scope == DictionarySearchScope.currentWordBook
      ? activeBook == null
          ? const <_DictionarySearchSource>[]
          : [
              _DictionarySearchSource(
                book: activeBook,
                words: currentScopeWords,
              ),
            ]
      : [
          for (final book in wordBooks)
            _DictionarySearchSource(book: book, words: book.words),
        ];
  final resultsByWord = <String, DictionaryWordSearchResult>{};

  for (final source in sources) {
    for (final word in source.words) {
      final match = _targetWordMatch(word, normalized, tagLabeler);
      if (match == null) continue;
      final normalizedWord = normalizeDictionaryQuery(word.word);
      final key = normalizedWord.isEmpty ? word.id : normalizedWord;
      final candidate = DictionaryWordSearchResult(
        word: word,
        book: source.book,
        matchedBy: match.label,
        preview: match.preview,
        inCurrentWordBook: currentWordNames.contains(normalizedWord),
      );
      final existing = resultsByWord[key];
      if (existing == null || _isBetterMatch(candidate, existing, normalized)) {
        resultsByWord[key] = candidate;
      }
    }
  }

  final results = resultsByWord.values.toList();
  results.sort((a, b) {
    final rank = _matchRank(a, normalized).compareTo(_matchRank(b, normalized));
    if (rank != 0) return rank;
    if (a.inCurrentWordBook != b.inCurrentWordBook) {
      return a.inCurrentWordBook ? -1 : 1;
    }
    return a.word.word.compareTo(b.word.word);
  });
  return List.unmodifiable(results);
}

List<CustomWordSearchResult> searchCustomWords({
  required List<CustomWord> customWords,
  required String query,
  String Function(String tag) tagLabeler = _identity,
}) {
  final normalized = normalizeDictionaryQuery(query);
  if (normalized.isEmpty) return const [];
  final results = <CustomWordSearchResult>[];
  for (final word in customWords) {
    final match = _customWordMatch(word, normalized, tagLabeler);
    if (match == null) continue;
    results.add(
      CustomWordSearchResult(
        word: word,
        matchedBy: match.label,
        preview: match.preview,
      ),
    );
  }
  results.sort((a, b) {
    final rank = _customMatchRank(a, normalized).compareTo(
      _customMatchRank(b, normalized),
    );
    if (rank != 0) return rank;
    final word = normalizeDictionaryQuery(a.word.word).compareTo(
      normalizeDictionaryQuery(b.word.word),
    );
    if (word != 0) return word;
    return a.word.id.compareTo(b.word.id);
  });
  return List.unmodifiable(results);
}

String normalizeDictionaryQuery(String query) {
  return query.trim().toLowerCase().replaceAll(_whitespaceRegExp, ' ');
}

String dictionaryScopeLabel(DictionarySearchScope scope) {
  switch (scope) {
    case DictionarySearchScope.currentWordBook:
      return '当前词书';
    case DictionarySearchScope.allWordBooks:
      return '全词库';
  }
}

_SearchMatch? _targetWordMatch(
  Word word,
  String query,
  String Function(String tag) tagLabeler,
) {
  return _matchText('英文单词/词组', word.word, query) ??
      _matchPinyin('汉字拼音', word.phonetic, query) ??
      // Japanese phonetic fields (kana + romaji) — no-op for zh words (empty).
      _matchText('かな', word.kana, query) ??
      _matchText('ローマ字', word.romaji, query) ??
      _matchText('中文释义', word.meaning, query) ??
      _matchList('中文释义', word.definitions, query) ??
      _matchText('英文释义', word.definition, query) ??
      _matchList('英文释义', word.englishDefinitions, query) ??
      _matchList('马来语释义', word.malayDefinitions, query) ??
      _matchText('例句片段', word.exampleSentence, query) ??
      _matchText('例句翻译', word.exampleTranslation, query) ??
      _matchExamples(word.examples, query) ??
      _matchPhrases(word.collocations, query) ??
      _matchList('近义词', word.synonyms, query) ??
      _matchList('反义词', word.antonyms, query) ??
      _matchList('派生词族', word.derivatives, query) ??
      _matchText('词根词缀', word.rootAffix, query) ??
      _matchLabeledList('考试标签', word.tags, query, tagLabeler);
}

_SearchMatch? _customWordMatch(
  CustomWord word,
  String query,
  String Function(String tag) tagLabeler,
) {
  return _matchText('英文单词/词组', word.word, query) ??
      _matchText('中文释义', word.meaning, query) ??
      _matchText('例句片段', word.exampleSentence, query) ??
      _matchText('笔记', word.note, query) ??
      _matchText('标签', word.tag, query) ??
      _matchText('标签', tagLabeler(word.tag), query);
}

_SearchMatch? _matchExamples(List<WordExample> examples, String query) {
  for (final example in examples) {
    final match =
        _matchText('例句片段', example.en, query) ??
        _matchText('例句翻译', example.cn, query);
    if (match != null) return match;
  }
  return null;
}

_SearchMatch? _matchPhrases(List<WordPhrase> phrases, String query) {
  for (final phrase in phrases) {
    final match =
        _matchText('词组搭配', phrase.phrase, query) ??
        _matchText('搭配释义', phrase.cn, query);
    if (match != null) return match;
  }
  return null;
}

_SearchMatch? _matchList(String label, List<String> values, String query) {
  for (final value in values) {
    final match = _matchText(label, value, query);
    if (match != null) return match;
  }
  return null;
}

_SearchMatch? _matchLabeledList(
  String label,
  List<String> values,
  String query,
  String Function(String tag) tagLabeler,
) {
  for (final value in values) {
    final match =
        _matchText(label, value, query) ??
        _matchText(label, tagLabeler(value), query);
    if (match != null) return match;
  }
  return null;
}

_SearchMatch? _matchText(String label, String value, String query) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.toLowerCase().contains(query)) return null;
  return _SearchMatch(label: label, preview: trimmed);
}

_SearchMatch? _matchPinyin(String label, String value, String query) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  // 去声调后匹配：'ài' -> 'ai'，'tài' -> 'tai'。精确=整串相等，否则子串。
  final normalized = normalizePinyin(trimmed);
  if (!normalized.contains(query)) return null;
  final matchLabel = normalized == query ? '汉字拼音精确' : label;
  return _SearchMatch(label: matchLabel, preview: trimmed);
}

int _matchRank(DictionaryWordSearchResult result, String query) {
  final word = result.word.word.toLowerCase();
  if (word == query) return 0;
  if (word.startsWith(query)) return 1;
  if (result.matchedBy == '汉字拼音精确') return 1;
  if (result.matchedBy == '汉字拼音') return 2;
  if (result.matchedBy == '英文单词/词组') return 2;
  // Japanese phonetic matches rank alongside word-text matches.
  if (result.matchedBy == 'かな' || result.matchedBy == 'ローマ字') return 2;
  if (result.matchedBy == '中文释义') return 3;
  if (result.matchedBy == '例句片段') return 4;
  return 5;
}

int _customMatchRank(CustomWordSearchResult result, String query) {
  final word = normalizeDictionaryQuery(result.word.word);
  if (word == query) return 0;
  if (word.startsWith(query)) return 1;
  if (result.matchedBy == '英文单词/词组') return 2;
  if (result.matchedBy == '中文释义') return 3;
  if (result.matchedBy == '例句片段') return 4;
  return 5;
}

bool _isBetterMatch(
  DictionaryWordSearchResult candidate,
  DictionaryWordSearchResult existing,
  String query,
) {
  final candidateRank = _matchRank(candidate, query);
  final existingRank = _matchRank(existing, query);
  if (candidateRank != existingRank) return candidateRank < existingRank;
  if (candidate.inCurrentWordBook != existing.inCurrentWordBook) {
    return candidate.inCurrentWordBook;
  }
  return candidate.preview.length < existing.preview.length;
}

class _SearchMatch {
  const _SearchMatch({required this.label, required this.preview});

  final String label;
  final String preview;
}

class _DictionarySearchSource {
  const _DictionarySearchSource({required this.book, required this.words});

  final WordBook book;
  final List<Word> words;
}

WordBook _fallbackWordBook({
  required String currentWordBookId,
  required List<Word> words,
}) {
  return WordBook(
    id: currentWordBookId,
    title: '当前词书',
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

String _identity(String value) => value;

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
