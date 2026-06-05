import 'models/custom_word.dart';
import 'models/lesson.dart';

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
}) {
  final normalized = normalizeDictionaryQuery(query);
  if (normalized.isEmpty) return const [];

  final currentBook = wordBooks.firstWhereOrNull(
    (book) => book.id == currentWordBookId,
  );
  final sourceBooks = scope == DictionarySearchScope.currentWordBook
      ? currentBook == null
            ? const <WordBook>[]
            : [currentBook]
      : wordBooks;
  final seenWords = <String>{};
  final results = <DictionaryWordSearchResult>[];

  for (final book in sourceBooks) {
    for (final word in book.words) {
      final key = _wordKey(word);
      if (!seenWords.add(key)) continue;
      final match = _targetWordMatch(word, normalized);
      if (match == null) continue;
      results.add(
        DictionaryWordSearchResult(
          word: word,
          book: book,
          matchedBy: match.label,
          preview: match.preview,
          inCurrentWordBook:
              currentBook?.words.any((item) => item.id == word.id) ?? false,
        ),
      );
    }
  }

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
}) {
  final normalized = normalizeDictionaryQuery(query);
  if (normalized.isEmpty) return const [];
  final results = <CustomWordSearchResult>[];
  for (final word in customWords) {
    final match = _customWordMatch(word, normalized);
    if (match == null) continue;
    results.add(
      CustomWordSearchResult(
        word: word,
        matchedBy: match.label,
        preview: match.preview,
      ),
    );
  }
  return List.unmodifiable(results);
}

String normalizeDictionaryQuery(String query) {
  return query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}

String dictionaryScopeLabel(DictionarySearchScope scope) {
  switch (scope) {
    case DictionarySearchScope.currentWordBook:
      return '当前词书';
    case DictionarySearchScope.allWordBooks:
      return '全词库';
  }
}

_SearchMatch? _targetWordMatch(Word word, String query) {
  return _matchText('英文单词/词组', word.word, query) ??
      _matchText('中文释义', word.meaning, query) ??
      _matchList('中文释义', word.definitions, query) ??
      _matchText('英文释义', word.definition, query) ??
      _matchList('英文释义', word.englishDefinitions, query) ??
      _matchText('例句片段', word.exampleSentence, query) ??
      _matchText('例句翻译', word.exampleTranslation, query) ??
      _matchExamples(word.examples, query) ??
      _matchPhrases(word.collocations, query) ??
      _matchList('近义词', word.synonyms, query) ??
      _matchList('反义词', word.antonyms, query) ??
      _matchList('派生词族', word.derivatives, query) ??
      _matchText('词根词缀', word.rootAffix, query) ??
      _matchList('考试标签', word.tags, query);
}

_SearchMatch? _customWordMatch(CustomWord word, String query) {
  return _matchText('英文单词/词组', word.word, query) ??
      _matchText('中文释义', word.meaning, query) ??
      _matchText('例句片段', word.exampleSentence, query) ??
      _matchText('笔记', word.note, query) ??
      _matchText('标签', word.tag, query);
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

_SearchMatch? _matchText(String label, String value, String query) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (!trimmed.toLowerCase().contains(query)) return null;
  return _SearchMatch(label: label, preview: trimmed);
}

int _matchRank(DictionaryWordSearchResult result, String query) {
  final word = result.word.word.toLowerCase();
  if (word == query) return 0;
  if (word.startsWith(query)) return 1;
  if (result.matchedBy == '英文单词/词组') return 2;
  if (result.matchedBy == '中文释义') return 3;
  if (result.matchedBy == '例句片段') return 4;
  return 5;
}

String _wordKey(Word word) {
  final normalizedWord = normalizeDictionaryQuery(word.word);
  return normalizedWord.isEmpty ? word.id : normalizedWord;
}

class _SearchMatch {
  const _SearchMatch({required this.label, required this.preview});

  final String label;
  final String preview;
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
