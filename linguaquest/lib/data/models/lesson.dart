enum QuizQuestionType {
  meaningChoice,
  chineseChoice,
  contextChoice,
  imageChoice,
  listeningWordChoice,
  listeningMeaningChoice,
  spelling,
}

class WordExample {
  const WordExample({required this.en, required this.cn});

  final String en;
  final String cn;

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(
      en: json['en'] as String? ?? '',
      cn: json['cn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'en': en, 'cn': cn};
}

class WordPhrase {
  const WordPhrase({required this.phrase, this.cn = ''});

  final String phrase;
  final String cn;

  factory WordPhrase.fromJson(Object? value) {
    if (value is Map) {
      final json = Map<String, dynamic>.from(value);
      return WordPhrase(
        phrase: json['phrase'] as String? ?? json['en'] as String? ?? '',
        cn: json['cn'] as String? ?? '',
      );
    }
    return WordPhrase(phrase: value?.toString() ?? '');
  }

  Map<String, dynamic> toJson() => {'phrase': phrase, 'cn': cn};
}

class Word {
  const Word({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meaning,
    required this.definition,
    required this.partOfSpeech,
    required this.exampleSentence,
    required this.exampleTranslation,
    required this.imageCue,
    required this.difficulty,
    required this.tags,
    this.phoneticUK = '',
    this.phoneticUS = '',
    this.audioUKUrl = '',
    this.audioUSUrl = '',
    this.definitions = const [],
    this.englishDefinitions = const [],
    this.examples = const [],
    this.collocations = const [],
    this.synonyms = const [],
    this.antonyms = const [],
    this.derivatives = const [],
    this.rootAffix = '',
    this.imageUrl = '',
  });

  final String id;
  final String word;
  final String phonetic;
  final String meaning;
  final String definition;
  final String partOfSpeech;
  final String exampleSentence;
  final String exampleTranslation;
  final String imageCue;
  final String difficulty;
  final List<String> tags;

  final String phoneticUK;
  final String phoneticUS;
  final String audioUKUrl;
  final String audioUSUrl;
  final List<String> definitions;
  final List<String> englishDefinitions;
  final List<WordExample> examples;
  final List<WordPhrase> collocations;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> derivatives;
  final String rootAffix;
  final String imageUrl;

  String get audioUrl => audioUSUrl.isNotEmpty ? audioUSUrl : audioUKUrl;

  factory Word.fromJson(Map<String, dynamic> json) {
    final wordText = json['word'] as String? ?? '';
    final definitions = _stringList(json['definitions']);
    final englishDefinitions = _stringList(json['englishDefinitions']);
    final examples = _examples(json['exampleSentences']);
    final phoneticUK = json['phoneticUK'] as String? ?? '';
    final phoneticUS = json['phoneticUS'] as String? ?? '';
    final meaning = definitions.isEmpty ? '' : definitions.first;
    final definition = englishDefinitions.isNotEmpty
        ? englishDefinitions.first
        : definitions.skip(1).join('；');
    final firstExample = examples.isEmpty
        ? const WordExample(en: '', cn: '')
        : examples.first;
    return Word(
      id: json['id'] as String? ?? wordText.toLowerCase(),
      word: wordText,
      phonetic: phoneticUK.isNotEmpty ? phoneticUK : phoneticUS,
      meaning: meaning,
      definition: definition.isEmpty ? meaning : definition,
      partOfSpeech: json['partOfSpeech'] as String? ?? 'word',
      exampleSentence: firstExample.en,
      exampleTranslation: firstExample.cn,
      imageCue: _imageCue(wordText),
      difficulty: _normalizeDifficulty(json['difficulty']),
      tags: _stringList(json['examTags']),
      phoneticUK: phoneticUK,
      phoneticUS: phoneticUS,
      audioUKUrl: json['audioUKUrl'] as String? ?? '',
      audioUSUrl: json['audioUSUrl'] as String? ?? '',
      definitions: definitions,
      englishDefinitions: englishDefinitions,
      examples: examples,
      collocations: _phrases(json['collocations']),
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      derivatives: _stringList(json['derivatives']),
      rootAffix: json['rootAffix'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phoneticUK': phoneticUK.isEmpty ? phonetic : phoneticUK,
      'phoneticUS': phoneticUS.isEmpty ? phonetic : phoneticUS,
      'audioUKUrl': audioUKUrl,
      'audioUSUrl': audioUSUrl,
      'partOfSpeech': partOfSpeech,
      'definitions': definitions.isEmpty ? [meaning] : definitions,
      'englishDefinitions': englishDefinitions.isEmpty
          ? [definition]
          : englishDefinitions,
      'exampleSentences': examples.isEmpty
          ? [WordExample(en: exampleSentence, cn: exampleTranslation).toJson()]
          : [for (final example in examples) example.toJson()],
      'collocations': [for (final phrase in collocations) phrase.toJson()],
      'synonyms': synonyms,
      'antonyms': antonyms,
      'derivatives': derivatives,
      'rootAffix': rootAffix,
      'examTags': tags,
      'difficulty': difficulty,
      'imageUrl': imageUrl,
    };
  }

  static String _imageCue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
  }

  static String _normalizeDifficulty(Object? value) {
    switch (value?.toString().trim().toLowerCase()) {
      case 'easy':
        return 'Easy';
      case 'hard':
        return 'Hard';
      default:
        return 'Medium';
    }
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty),
    );
  }

  static List<WordExample> _examples(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value
          .whereType<Map>()
          .map((item) {
            return WordExample.fromJson(Map<String, dynamic>.from(item));
          })
          .where(
            (item) => item.en.trim().isNotEmpty && item.cn.trim().isNotEmpty,
          ),
    );
  }

  static List<WordPhrase> _phrases(Object? value) {
    if (value is! List) return const [];
    return List.unmodifiable(
      value
          .map(WordPhrase.fromJson)
          .where((item) => item.phrase.trim().isNotEmpty),
    );
  }
}

class WordBook {
  const WordBook({
    required this.id,
    required this.title,
    required this.category,
    required this.examType,
    required this.coverUrl,
    required this.totalWords,
    required this.includedWords,
    required this.description,
    required this.wordIds,
    required this.createdAt,
    required this.words,
  });

  final String id;
  final String title;
  final String category;
  final String examType;
  final String coverUrl;
  final int totalWords;
  final int includedWords;
  final String description;
  final List<String> wordIds;
  final DateTime createdAt;
  final List<Word> words;

  factory WordBook.fromJson(Map<String, dynamic> json) {
    final words = (json['words'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Word.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final wordIds = Word._stringList(json['wordIds']);
    return WordBook(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'exam',
      examType: json['examType'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      totalWords: _intValue(json['totalWords'], words.length),
      includedWords: _intValue(json['includedWords'], words.length),
      description: json['description'] as String? ?? '',
      wordIds: wordIds.isEmpty
          ? List.unmodifiable(words.map((word) => word.id))
          : wordIds,
      createdAt:
          DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      words: List.unmodifiable(words),
    );
  }

  Map<String, dynamic> toJson({bool includeWords = true}) {
    return {
      'id': id,
      'title': title,
      'category': category,
      'examType': examType,
      'coverUrl': coverUrl,
      'totalWords': totalWords,
      'includedWords': includedWords,
      'description': description,
      'wordIds': wordIds,
      'createdAt': createdAt.toIso8601String(),
      if (includeWords) 'words': [for (final word in words) word.toJson()],
    };
  }

  static int _intValue(Object? value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.type,
    required this.prompt,
    required this.answer,
    required this.options,
    required this.explanation,
    required this.word,
  });

  final String id;
  final QuizQuestionType type;
  final String prompt;
  final String answer;
  final List<String> options;
  final String explanation;
  final Word word;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.section,
    required this.description,
    required this.status,
    required this.xpReward,
    required this.estimatedMinutes,
    required this.words,
    required this.questions,
  });

  final String id;
  final String title;
  final String section;
  final String description;
  final String status;
  final int xpReward;
  final int estimatedMinutes;
  final List<Word> words;
  final List<QuizQuestion> questions;

  bool get isTrainingPack => section == '训练场';

  Lesson copyWith({
    String? id,
    String? title,
    String? section,
    String? description,
    String? status,
    int? xpReward,
    int? estimatedMinutes,
    List<Word>? words,
    List<QuizQuestion>? questions,
  }) {
    return Lesson(
      id: id ?? this.id,
      title: title ?? this.title,
      section: section ?? this.section,
      description: description ?? this.description,
      status: status ?? this.status,
      xpReward: xpReward ?? this.xpReward,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      words: words ?? this.words,
      questions: questions ?? this.questions,
    );
  }
}
