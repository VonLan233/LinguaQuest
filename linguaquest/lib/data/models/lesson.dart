enum QuizQuestionType {
  meaningChoice,
  chineseChoice,
  contextChoice,
  imageChoice,
  spelling,
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

  factory Word.fromJson(Map<String, dynamic> json) {
    return Word(
      id: _string(json['id']),
      word: _string(json['word']),
      phonetic: _string(json['phonetic']),
      meaning: _string(json['meaning']),
      definition: _string(json['definition']),
      partOfSpeech: _string(json['partOfSpeech']),
      exampleSentence: _string(json['exampleSentence']),
      exampleTranslation: _string(json['exampleTranslation']),
      imageCue: _string(json['imageCue']),
      difficulty: _string(json['difficulty'], fallback: 'Medium'),
      tags: _stringList(json['tags']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'meaning': meaning,
      'definition': definition,
      'partOfSpeech': partOfSpeech,
      'exampleSentence': exampleSentence,
      'exampleTranslation': exampleTranslation,
      'imageCue': imageCue,
      'difficulty': difficulty,
      'tags': tags,
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
  });

  final String id;
  final QuizQuestionType type;
  final String prompt;
  final String answer;
  final List<String> options;
  final String explanation;
  final Word word;

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

  bool get isTrainingPack => section == '训练场';

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

List<String> _stringList(Object? value) {
  if (value is! Iterable) return const [];
  return value.map((item) => item.toString()).toList();
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

Map<String, dynamic> _questionWordJson(
  Map<String, dynamic> json,
  Object? wordData,
) {
  if (wordData is Map) return Map<String, dynamic>.from(wordData);

  final fallbackWord = json['answer']?.toString() ?? '';
  final fallbackId = fallbackWord.isNotEmpty
      ? fallbackWord
      : json['id']?.toString() ?? 'question-word';
  return {
    'id': fallbackId,
    'word': fallbackWord,
    'phonetic': '',
    'meaning': '',
    'definition': json['prompt']?.toString() ?? '',
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
