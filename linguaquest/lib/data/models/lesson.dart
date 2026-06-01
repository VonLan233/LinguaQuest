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

  factory Word.fromJson(Map<String, dynamic> json) {
    final wordText = json['word'] as String? ?? '';
    final definitions = _stringList(json['definitions']);
    final englishDefinitions = _stringList(json['englishDefinitions']);
    final examples = _examples(json['exampleSentences']);
    final phoneticUK = json['phoneticUK'] as String? ?? '';
    final phoneticUS = json['phoneticUS'] as String? ?? '';
    final tags = _stringList(json['examTags']);
    final meaning = definitions.isEmpty ? '' : definitions.first;
    final definition = englishDefinitions.isNotEmpty
        ? englishDefinitions.first
        : definitions.skip(1).take(2).join('；');
    final example = examples.isEmpty
        ? const WordExample(en: '', cn: '')
        : examples.first;
    return Word(
      id: json['id'] as String? ?? wordText.toLowerCase(),
      word: wordText,
      phonetic: phoneticUK.isNotEmpty ? phoneticUK : phoneticUS,
      meaning: meaning,
      definition: definition.isEmpty ? meaning : definition,
      partOfSpeech: json['partOfSpeech'] as String? ?? 'word',
      exampleSentence: example.en,
      exampleTranslation: example.cn,
      imageCue: _initialCue(wordText),
      difficulty: _normalizeDifficulty(json['difficulty']),
      tags: tags.isEmpty ? const ['exam'] : tags,
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

  static String _initialCue(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.substring(0, 1).toUpperCase();
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
          .map((item) => WordExample.fromJson(Map<String, dynamic>.from(item)))
          .where((item) => item.en.trim().isNotEmpty),
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
  final List<Word> words;

  factory WordBook.fromJson(Map<String, dynamic> json) {
    final words = (json['words'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Word.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    return WordBook(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? 'exam',
      examType: json['examType'] as String? ?? '',
      coverUrl: json['coverUrl'] as String? ?? '',
      totalWords: json['totalWords'] as int? ?? words.length,
      includedWords: json['includedWords'] as int? ?? words.length,
      description: json['description'] as String? ?? '',
      words: List.unmodifiable(words),
    );
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
