import '../../core/utils/text_language.dart';

enum QuizQuestionType {
  meaningChoice,
  chineseChoice,
  contextChoice,
  imageChoice,
  listeningWordChoice,
  listeningMeaningChoice,
  spelling,
  sentenceCloze, // 例句填空：把目标词替换为 ____ 让学习者选择
  confusableChoice, // 易混词辨析：从语义相近词中选出正确答案
  collocationChoice, // 搭配选择：从常用搭配中选出正确的动词/名词搭配
  derivativeChoice, // 词形变化：选择正确的词形（名词/动词/形容词等）
}

class WordExample {
  const WordExample({required this.en, required this.cn});

  final String en;
  final String cn;

  factory WordExample.fromJson(Map<String, dynamic> json) {
    return WordExample(en: _string(json['en']), cn: _string(json['cn']));
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
        phrase: _string(json['phrase'], fallback: _string(json['en'])),
        cn: _string(json['cn']),
      );
    }
    return WordPhrase(phrase: _string(value));
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
    this.malayDefinitions = const [],
    this.localizedDefinitions = const {},
    this.examples = const [],
    this.collocations = const [],
    this.synonyms = const [],
    this.antonyms = const [],
    this.derivatives = const [],
    this.rootAffix = '',
    this.imageUrl = '',
    this.hskLevel,
    // P2a: Japanese language fields (all default empty/null — zh data unaffected)
    this.kana = '',
    this.romaji = '',
    this.examLevel,
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
  final List<String> malayDefinitions;
  final Map<String, List<String>> localizedDefinitions;
  final List<WordExample> examples;
  final List<WordPhrase> collocations;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> derivatives;
  final String rootAffix;
  final String imageUrl;
  final int? hskLevel;
  // P2a: Japanese fields — empty/''/null for all existing zh data.
  /// Hiragana/katakana reading (Japanese words). Empty for zh/en words.
  final String kana;

  /// Romanized reading (Japanese words). Empty for zh/en words.
  final String romaji;

  /// Generic exam level (JLPT level number for ja; null for zh where hskLevel is used).
  final int? examLevel;

  String get audioUrl => audioUSUrl.isNotEmpty ? audioUSUrl : audioUKUrl;

  /// Returns the phonetic reading appropriate for [language]:
  /// - `'zh'` → pinyin (`phonetic`/`phoneticUK`).
  /// - `'ja'` → kana (primary), falling back to romaji.
  /// - anything else → empty string (screens adapt in P2f).
  ///
  /// This is a model-level accessor only; screen wiring happens in P2f.
  /// Backward-compat: for `'zh'` this returns exactly what `phonetic` returns today.
  String phoneticFor(String language) {
    switch (language) {
      case 'zh':
        return phonetic;
      case 'ja':
        if (kana.isNotEmpty) return kana;
        return romaji;
      default:
        return '';
    }
  }

  /// Returns the list of meanings localized for [languageCode]:
  /// - 'en' → [englishDefinitions], falling back to [definitions].
  /// - 'ms' → [malayDefinitions], falling back to [englishDefinitions], then
  ///   [definitions].
  /// - anything else (incl. 'zh') → [definitions], falling back to
  ///   [englishDefinitions].
  ///
  /// As a final fallback (e.g. legacy/custom words that only carry the scalar
  /// [meaning]/[definition] fields), returns a single-element list derived from
  /// those so callers always have something to show.
  List<String> definitionsFor(String languageCode) {
    final normalizedLanguage = languageCode.toLowerCase();
    final translated = localizedDefinitions[normalizedLanguage];
    if (translated != null && translated.isNotEmpty) return translated;
    List<String> nonChinese(Iterable<String> values) {
      return [
        for (final value in values)
          if (value.trim().isNotEmpty && !containsCjkText(value)) value.trim(),
      ];
    }

    List<String> nonChineseScalar(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || containsCjkText(trimmed)) return const [];
      return [trimmed];
    }

    List<String> pick() {
      switch (normalizedLanguage) {
        case 'en':
          if (nonChinese(englishDefinitions).isNotEmpty) {
            return nonChinese(englishDefinitions);
          }
          if (nonChineseScalar(definition).isNotEmpty) {
            return nonChineseScalar(definition);
          }
          if (nonChinese(definitions).isNotEmpty) {
            return nonChinese(definitions);
          }
          return [_fallbackDefinitionFor(word, normalizedLanguage)];
        case 'ja':
          // Legacy exam books without Japanese translations retain English glosses.
          return englishDefinitions.isNotEmpty
              ? englishDefinitions
              : definitions;
        case 'ms':
          if (nonChinese(malayDefinitions).isNotEmpty) {
            return nonChinese(malayDefinitions);
          }
          if (nonChinese(englishDefinitions).isNotEmpty) {
            return nonChinese(englishDefinitions);
          }
          if (nonChineseScalar(definition).isNotEmpty) {
            return nonChineseScalar(definition);
          }
          if (nonChinese(definitions).isNotEmpty) {
            return nonChinese(definitions);
          }
          return [_fallbackDefinitionFor(word, normalizedLanguage)];
        default:
          if (definitions.isNotEmpty) return definitions;
          return englishDefinitions;
      }
    }

    final result = pick();
    if (result.isNotEmpty) return result;
    // Legacy/custom words: synthesize from the scalar fields.
    if (languageCode == 'en' && definition.trim().isNotEmpty) {
      return [definition];
    }
    if (meaning.trim().isNotEmpty) return [meaning];
    if (definition.trim().isNotEmpty) return [definition];
    return const [];
  }

  /// The primary (first) meaning localized for [languageCode], or '' if none.
  /// Intended for single-line displays and as the answer key for quiz options.
  String primaryDefinitionFor(String languageCode) {
    final list = definitionsFor(languageCode);
    return list.isEmpty ? '' : list.first;
  }

  factory Word.fromJson(Map<String, dynamic> json) {
    final wordText = _string(json['word']);
    final definitions = _stringList(json['definitions']);
    final englishDefinitions = _stringList(json['englishDefinitions']);
    final malayDefinitions = _stringList(json['malayDefinitions']);
    final examples = _examples(json['exampleSentences']);
    final phoneticUK = _string(json['phoneticUK']);
    final phoneticUS = _string(json['phoneticUS']);
    final legacyMeaning = _string(json['meaning']);
    final meaning = definitions.isEmpty ? legacyMeaning : definitions.first;
    final derivedDefinition = englishDefinitions.isNotEmpty
        ? englishDefinitions.first
        : definitions.skip(1).join('；');
    final legacyDefinition = _string(json['definition']);
    final definition = derivedDefinition.isNotEmpty
        ? derivedDefinition
        : legacyDefinition.isNotEmpty
        ? legacyDefinition
        : meaning;
    final firstExample = examples.isEmpty
        ? const WordExample(en: '', cn: '')
        : examples.first;
    final legacyExampleSentence = _string(json['exampleSentence']);
    final legacyExampleTranslation = _string(json['exampleTranslation']);
    final examTags = _stringList(json['examTags']);
    final legacyTags = _stringList(json['tags']);
    final imageCue = _string(json['imageCue']);
    return Word(
      id: _string(json['id'], fallback: wordText.toLowerCase()),
      word: wordText,
      phonetic: phoneticUK.isNotEmpty
          ? phoneticUK
          : phoneticUS.isNotEmpty
          ? phoneticUS
          : _string(json['phonetic']),
      meaning: meaning,
      definition: definition,
      partOfSpeech: _string(json['partOfSpeech'], fallback: 'word'),
      exampleSentence: legacyExampleSentence.isNotEmpty
          ? legacyExampleSentence
          : firstExample.en,
      exampleTranslation: firstExample.cn.isNotEmpty
          ? firstExample.cn
          : legacyExampleTranslation,
      imageCue: imageCue.isNotEmpty ? imageCue : _imageCue(wordText),
      difficulty: _normalizeDifficulty(json['difficulty']),
      tags: examTags.isNotEmpty ? examTags : legacyTags,
      phoneticUK: phoneticUK,
      phoneticUS: phoneticUS,
      audioUKUrl: _string(json['audioUKUrl']),
      audioUSUrl: _string(json['audioUSUrl']),
      definitions: definitions,
      englishDefinitions: englishDefinitions,
      malayDefinitions: malayDefinitions,
      localizedDefinitions: {
        for (final entry
            in (json['localizedDefinitions'] as Map? ?? {}).entries)
          entry.key.toString(): _stringList(entry.value),
      },
      examples: examples,
      collocations: _phrases(json['collocations']),
      synonyms: _stringList(json['synonyms']),
      antonyms: _stringList(json['antonyms']),
      derivatives: _stringList(json['derivatives']),
      rootAffix: _string(json['rootAffix']),
      imageUrl: _string(json['imageUrl']),
      hskLevel: _int(json['hskLevel']),
      // P2a: Japanese fields — default '' / null when absent (all existing JSON unaffected)
      kana: _string(json['kana']),
      romaji: _string(json['romaji']),
      examLevel: _int(json['examLevel']),
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
      'malayDefinitions': malayDefinitions,
      'localizedDefinitions': localizedDefinitions,
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
      'hskLevel': hskLevel,
      // P2a: Japanese fields — always serialized so round-trips are lossless
      'kana': kana,
      'romaji': romaji,
      'examLevel': examLevel,
    };
  }
}

String _fallbackDefinitionFor(String word, String languageCode) {
  final fallbackWord = word.trim();
  if (fallbackWord.isNotEmpty && !containsCjkText(fallbackWord)) {
    if (languageCode == 'ms') return 'Item kosa kata untuk $fallbackWord.';
    return 'Vocabulary item for $fallbackWord.';
  }
  if (languageCode == 'ms') return 'Item kosa kata.';
  return 'Vocabulary item.';
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
    this.titleEn = '',
    this.titleMs = '',
    this.titleJa = '',
    // P2a: language code for this wordbook. Default 'zh' for all existing HSK data.
    this.language = 'zh',
  });

  final String id;
  final String title;
  final String titleEn;
  final String titleMs;
  final String titleJa;
  final String category;
  final String examType;
  final String coverUrl;
  final int totalWords;
  final int includedWords;
  final String description;
  final List<String> wordIds;
  final DateTime createdAt;
  final List<Word> words;

  /// ISO language code for this wordbook ('zh', 'ja', …). Default 'zh'.
  /// All existing HSK JSON (which lacks this field) will parse to 'zh'.
  final String language;

  /// The wordbook title localized for [languageCode]:
  /// - 'en' → [titleEn], falling back to [title].
  /// - 'ms' → [titleMs], falling back to [titleEn], then [title].
  /// - anything else (incl. 'zh') → [title].
  ///
  /// Display-only; never use as a map key or id.
  String nameFor(String languageCode) {
    switch (languageCode) {
      case 'ja':
        return titleJa.isNotEmpty
            ? titleJa
            : (titleEn.isNotEmpty ? titleEn : title);
      case 'en':
        return titleEn.isNotEmpty ? titleEn : title;
      case 'ms':
        if (titleMs.isNotEmpty) return titleMs;
        return titleEn.isNotEmpty ? titleEn : title;
      default:
        return title;
    }
  }

  factory WordBook.fromJson(Map<String, dynamic> json) {
    final words = (json['words'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Word.fromJson(Map<String, dynamic>.from(item)))
        .toList();
    final wordIds = _stringList(json['wordIds']);
    return WordBook(
      id: _string(json['id']),
      title: _string(json['title']),
      titleEn: _string(json['titleEn']),
      titleMs: _string(json['titleMs']),
      titleJa: _string(json['titleJa']),
      category: _string(json['category'], fallback: 'exam'),
      examType: _string(json['examType']),
      coverUrl: _string(json['coverUrl']),
      totalWords: _intValue(json['totalWords'], words.length),
      includedWords: _intValue(json['includedWords'], words.length),
      description: _string(json['description']),
      wordIds: wordIds.isEmpty
          ? List.unmodifiable(words.map((word) => word.id))
          : wordIds,
      createdAt:
          DateTime.tryParse(_string(json['createdAt'])) ??
          DateTime.now().toUtc(),
      words: List.unmodifiable(words),
      // P2a: default 'zh' so all existing HSK JSON (which lacks this field) loads unchanged
      language: _string(json['language'], fallback: 'zh'),
    );
  }

  Map<String, dynamic> toJson({bool includeWords = true}) {
    return {
      'id': id,
      'title': title,
      'titleEn': titleEn,
      'titleMs': titleMs,
      'titleJa': titleJa,
      'category': category,
      'examType': examType,
      'coverUrl': coverUrl,
      'totalWords': totalWords,
      'includedWords': includedWords,
      'description': description,
      'wordIds': wordIds,
      'createdAt': createdAt.toIso8601String(),
      // P2a: always serialized so round-trips are lossless
      'language': language,
      if (includeWords) 'words': [for (final word in words) word.toJson()],
    };
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
    this.promptEn,
    this.optionsEn,
    this.explanationEn,
  });

  final String id;
  final QuizQuestionType type;
  final String prompt;
  final String answer;
  final List<String> options;
  final String explanation;
  final Word word;
  final String? promptEn;
  final List<String>? optionsEn;
  final String? explanationEn;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final wordData = json['word'];
    return QuizQuestion(
      id: _string(json['id']),
      type: _questionType(json['type']),
      prompt: _string(json['prompt']),
      answer: _string(json['answer']),
      options: _stringList(json['options']),
      explanation: _string(json['explanation']),
      word: Word.fromJson(_questionWordJson(json, wordData)),
      promptEn: json['promptEn'] == null ? null : _string(json['promptEn']),
      optionsEn: json['optionsEn'] == null
          ? null
          : _stringList(json['optionsEn']),
      explanationEn: json['explanationEn'] == null
          ? null
          : _string(json['explanationEn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'prompt': prompt,
      'answer': answer,
      'options': options,
      'explanation': explanation,
      'word': word.toJson(),
      if (promptEn != null) 'promptEn': promptEn,
      if (optionsEn != null) 'optionsEn': optionsEn,
      if (explanationEn != null) 'explanationEn': explanationEn,
    };
  }
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

  bool get isTrainingPack => section == 'Training Ground' || section == '训练场';

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: _string(json['id']),
      title: _string(json['title']),
      section: _string(json['section']),
      description: _string(json['description']),
      status: _string(json['status'], fallback: 'locked'),
      xpReward: _int(json['xpReward']) ?? 0,
      estimatedMinutes: _int(json['estimatedMinutes']) ?? 5,
      words: _mapList(json['words']).map(Word.fromJson).toList(),
      questions: _mapList(
        json['questions'],
      ).map(QuizQuestion.fromJson).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'section': section,
      'description': description,
      'status': status,
      'xpReward': xpReward,
      'estimatedMinutes': estimatedMinutes,
      'words': words.map((word) => word.toJson()).toList(),
      'questions': questions.map((question) => question.toJson()).toList(),
    };
  }

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

QuizQuestionType _questionType(Object? value) {
  final name = value?.toString();
  return QuizQuestionType.values.firstWhere(
    (type) => type.name == name,
    orElse: () => QuizQuestionType.meaningChoice,
  );
}

String _imageCue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

String _normalizeDifficulty(Object? value) {
  switch (value?.toString().trim().toLowerCase()) {
    case 'easy':
      return 'Easy';
    case 'hard':
      return 'Hard';
    default:
      return 'Medium';
  }
}

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const [];
  return List.unmodifiable(
    value
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty),
  );
}

String _string(Object? value, {String fallback = ''}) {
  return value?.toString() ?? fallback;
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

List<WordExample> _examples(Object? value) {
  if (value is! Iterable) return const [];
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

List<WordPhrase> _phrases(Object? value) {
  if (value is! Iterable) return const [];
  return List.unmodifiable(
    value.map(WordPhrase.fromJson).where((item) {
      return item.phrase.trim().isNotEmpty;
    }),
  );
}

Map<String, dynamic> _questionWordJson(
  Map<String, dynamic> json,
  Object? wordData,
) {
  if (wordData is Map) return Map<String, dynamic>.from(wordData);

  final fallbackWord = _string(json['answer']);
  final fallbackId = fallbackWord.isNotEmpty
      ? fallbackWord
      : _string(json['id'], fallback: 'question-word');
  return {
    'id': fallbackId,
    'word': fallbackWord,
    'phonetic': '',
    'meaning': '',
    'definition': _string(json['prompt']),
    'partOfSpeech': '',
    'exampleSentence': '',
    'exampleTranslation': '',
    'imageCue': '',
    'difficulty': 'Medium',
    'tags': const <String>[],
  };
}

int? _int(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

int _intValue(Object? value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
