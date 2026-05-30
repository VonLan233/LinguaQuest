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
