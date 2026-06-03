import 'dart:convert';
import 'dart:io';

class WordBook {
  const WordBook({
    required this.id,
    required this.title,
    required this.category,
    required this.examType,
    required this.coverUrl,
    required this.totalWords,
    required this.description,
    required this.wordIds,
  });

  final String id;
  final String title;
  final String category;
  final String examType;
  final String coverUrl;
  final int totalWords;
  final String description;
  final List<String> wordIds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'category': category,
        'examType': examType,
        'coverUrl': coverUrl,
        'totalWords': totalWords,
        'description': description,
        'wordIds': wordIds,
      };
}

class WordEntry {
  const WordEntry({
    required this.id,
    required this.word,
    required this.phoneticUK,
    required this.phoneticUS,
    required this.audioUKUrl,
    required this.audioUSUrl,
    required this.partOfSpeech,
    required this.definitions,
    required this.englishDefinitions,
    required this.exampleSentences,
    required this.collocations,
    required this.synonyms,
    required this.antonyms,
    required this.derivatives,
    required this.rootAffix,
    required this.examTags,
    required this.difficulty,
    required this.imageUrl,
  });

  final String id;
  final String word;
  final String phoneticUK;
  final String phoneticUS;
  final String audioUKUrl;
  final String audioUSUrl;
  final String partOfSpeech;
  final List<String> definitions;
  final List<String> englishDefinitions;
  final List<ExampleSentence> exampleSentences;
  final List<Collocation> collocations;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> derivatives;
  final String rootAffix;
  final List<String> examTags;
  final String difficulty;
  final String imageUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'phoneticUK': phoneticUK,
        'phoneticUS': phoneticUS,
        'audioUKUrl': audioUKUrl,
        'audioUSUrl': audioUSUrl,
        'partOfSpeech': partOfSpeech,
        'definitions': definitions,
        'englishDefinitions': englishDefinitions,
        'exampleSentences': exampleSentences.map((e) => e.toJson()).toList(),
        'collocations': collocations.map((e) => e.toJson()).toList(),
        'synonyms': synonyms,
        'antonyms': antonyms,
        'derivatives': derivatives,
        'rootAffix': rootAffix,
        'examTags': examTags,
        'difficulty': difficulty,
        'imageUrl': imageUrl,
      };
}

class ExampleSentence {
  const ExampleSentence({required this.en, required this.cn});
  final String en;
  final String cn;

  Map<String, dynamic> toJson() => {'en': en, 'cn': cn};
}

class Collocation {
  const Collocation({required this.phrase, required this.cn});
  final String phrase;
  final String cn;

  Map<String, dynamic> toJson() => {'phrase': phrase, 'cn': cn};
}

class WordBookService {
  final Map<String, WordBook> _wordbooks = {};
  final Map<String, WordEntry> _words = {};
  final Map<String, List<String>> _wordIdsByBook = {};

  List<WordBook> get wordbooks => _wordbooks.values.toList();

  WordBook? getWordBook(String id) => _wordbooks[id];

  List<WordEntry> getWords(String bookId, {int? limit, int? offset}) {
    final ids = _wordIdsByBook[bookId] ?? [];
    final start = offset ?? 0;
    final end = limit == null ? ids.length : (start + limit).clamp(0, ids.length);
    return [
      for (var i = start; i < end; i++)
        if (_words.containsKey(ids[i])) _words[ids[i]]!,
    ];
  }

  int getWordCount(String bookId) => _wordIdsByBook[bookId]?.length ?? 0;

  WordEntry? getWord(String wordId) => _words[wordId];

  WordEntry? findWordByText(String text) {
    final lower = text.toLowerCase().trim();
    for (final entry in _words.values) {
      if (entry.word.toLowerCase().trim() == lower) return entry;
    }
    return null;
  }

  List<WordEntry> search(String query, {int limit = 20}) {
    final lower = query.toLowerCase().trim();
    if (lower.isEmpty) return [];
    final results = <WordEntry>[];
    for (final entry in _words.values) {
      if (results.length >= limit) break;
      if (_entryMatches(entry, lower)) {
        results.add(entry);
      }
    }
    return results;
  }

  bool _entryMatches(WordEntry entry, String query) {
    if (entry.word.toLowerCase().contains(query)) return true;
    if (entry.definitions.any((d) => d.toLowerCase().contains(query))) return true;
    if (entry.englishDefinitions.any((d) => d.toLowerCase().contains(query))) return true;
    if (entry.exampleSentences.any((e) => e.en.toLowerCase().contains(query) || e.cn.contains(query))) return true;
    return false;
  }

  Future<void> loadFromDirectory(String directoryPath) async {
    final dir = Directory(directoryPath);
    if (!dir.existsSync()) {
      throw StateError('Wordbooks directory not found: $directoryPath');
    }

    final manifestFile = File('${dir.path}/wordbooks_manifest.json');
    if (!manifestFile.existsSync()) {
      throw StateError('wordbooks_manifest.json not found in $directoryPath');
    }

    final manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    final books = (manifest['wordbooks'] as List<dynamic>).cast<Map<String, dynamic>>();

    for (final bookMeta in books) {
      final fileName = bookMeta['fileName'] as String;
      final filePath = '${dir.path}/$fileName';
      final file = File(filePath);
      if (!file.existsSync()) {
        stderr.writeln('Warning: wordbook file not found: $filePath');
        continue;
      }

      final rawList = jsonDecode(await file.readAsString()) as List<dynamic>;
      final wordIds = <String>[];

      for (final raw in rawList.cast<Map<String, dynamic>>()) {
        final entry = _parseWordEntry(raw);
        _words[entry.id] = entry;
        wordIds.add(entry.id);
      }

      final bookId = bookMeta['id'] as String;
      _wordIdsByBook[bookId] = wordIds;
      _wordbooks[bookId] = WordBook(
        id: bookId,
        title: bookMeta['title'] as String,
        category: bookMeta['category'] as String,
        examType: bookMeta['examType'] as String,
        coverUrl: bookMeta['coverUrl'] as String,
        totalWords: bookMeta['totalWords'] as int,
        description: bookMeta['description'] as String,
        wordIds: wordIds,
      );

      stdout.writeln('Loaded wordbook: ${bookMeta['title']} (${wordIds.length} words)');
    }

    stdout.writeln('Total unique words loaded: ${_words.length}');
  }

  WordEntry _parseWordEntry(Map<String, dynamic> raw) {
    List<String> _stringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.cast<String>();
      if (value is String) return value.isEmpty ? [] : [value];
      return [];
    }

    List<ExampleSentence> _examples(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => ExampleSentence(
                en: (e['en'] ?? e['EN'] ?? '').toString(),
                cn: (e['cn'] ?? e['CN'] ?? '').toString(),
              ))
          .toList();
    }

    List<Collocation> _collocations(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      return value
          .whereType<Map<String, dynamic>>()
          .map((e) => Collocation(
                phrase: (e['phrase'] ?? e['Phrase'] ?? '').toString(),
                cn: (e['cn'] ?? e['CN'] ?? '').toString(),
              ))
          .toList();
    }

    return WordEntry(
      id: raw['id']?.toString() ?? '',
      word: raw['word']?.toString() ?? '',
      phoneticUK: raw['phoneticUK']?.toString() ?? '',
      phoneticUS: raw['phoneticUS']?.toString() ?? '',
      audioUKUrl: raw['audioUKUrl']?.toString() ?? '',
      audioUSUrl: raw['audioUSUrl']?.toString() ?? '',
      partOfSpeech: raw['partOfSpeech']?.toString() ?? '',
      definitions: _stringList(raw['definitions']),
      englishDefinitions: _stringList(raw['englishDefinitions']),
      exampleSentences: _examples(raw['exampleSentences']),
      collocations: _collocations(raw['collocations']),
      synonyms: _stringList(raw['synonyms']),
      antonyms: _stringList(raw['antonyms']),
      derivatives: _stringList(raw['derivatives']),
      rootAffix: raw['rootAffix']?.toString() ?? '',
      examTags: _stringList(raw['examTags']),
      difficulty: raw['difficulty']?.toString() ?? 'medium',
      imageUrl: raw['imageUrl']?.toString() ?? '',
    );
  }
}
