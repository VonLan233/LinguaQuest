class ExampleSentence {
  const ExampleSentence({required this.en, required this.cn});

  final String en;
  final String cn;

  factory ExampleSentence.fromJson(Map<String, dynamic> json) {
    return ExampleSentence(
      en: json['en'] as String? ?? '',
      cn: json['cn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'en': en, 'cn': cn};
}

class Collocation {
  const Collocation({required this.phrase, required this.cn});

  final String phrase;
  final String cn;

  factory Collocation.fromJson(Map<String, dynamic> json) {
    return Collocation(
      phrase: json['phrase'] as String? ?? '',
      cn: json['cn'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'phrase': phrase, 'cn': cn};
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

  factory WordEntry.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.cast<String>();
      if (value is String) return value.isEmpty ? [] : [value];
      return [];
    }

    List<ExampleSentence> parseExamples(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(ExampleSentence.fromJson)
          .toList();
    }

    List<Collocation> parseCollocations(dynamic value) {
      if (value == null) return [];
      if (value is! List) return [];
      return value
          .whereType<Map<String, dynamic>>()
          .map(Collocation.fromJson)
          .toList();
    }

    return WordEntry(
      id: json['id'] as String? ?? '',
      word: json['word'] as String? ?? '',
      phoneticUK: json['phoneticUK'] as String? ?? '',
      phoneticUS: json['phoneticUS'] as String? ?? '',
      audioUKUrl: json['audioUKUrl'] as String? ?? '',
      audioUSUrl: json['audioUSUrl'] as String? ?? '',
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definitions: stringList(json['definitions']),
      englishDefinitions: stringList(json['englishDefinitions']),
      exampleSentences: parseExamples(json['exampleSentences']),
      collocations: parseCollocations(json['collocations']),
      synonyms: stringList(json['synonyms']),
      antonyms: stringList(json['antonyms']),
      derivatives: stringList(json['derivatives']),
      rootAffix: json['rootAffix']?.toString() ?? '',
      examTags: stringList(json['examTags']),
      difficulty: json['difficulty'] as String? ?? 'medium',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }

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
