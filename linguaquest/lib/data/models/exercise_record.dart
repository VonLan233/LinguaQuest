import 'custom_word.dart';

class ExerciseRecord {
  const ExerciseRecord({
    required this.id,
    required this.uid,
    required this.sessionId,
    required this.gameId,
    required this.wordId,
    required this.promptType,
    required this.isCorrect,
    required this.answer,
    required this.correctAnswer,
    required this.answerTimeMs,
    required this.dimension,
    required this.createdAt,
    this.prompt = '',
    this.options = const [],
    this.confidence = -1,
    this.wrongOption = '',
  });

  final String id;
  final String uid;
  final String sessionId;
  final String gameId;
  final String wordId;
  final String promptType;
  final bool isCorrect;
  final String answer;
  final String correctAnswer;
  final int answerTimeMs;
  final ReviewDimension dimension;
  final DateTime createdAt;

  /// 题目展示的提示文本（题干），默认为空字符串。
  final String prompt;

  /// 题目的可选项列表；对拼写题等无选项题型为空列表。
  final List<String> options;

  /// 用户提交答案时的置信度 0-100；-1 表示该次练习未记录置信度。
  final int confidence;

  /// 用户选错的选项文本；答对时为空字符串。
  final String wrongOption;

  ExerciseRecord copyWith({
    String? id,
    String? uid,
    String? sessionId,
    String? gameId,
    String? wordId,
    String? promptType,
    bool? isCorrect,
    String? answer,
    String? correctAnswer,
    int? answerTimeMs,
    ReviewDimension? dimension,
    DateTime? createdAt,
    String? prompt,
    List<String>? options,
    int? confidence,
    String? wrongOption,
  }) {
    return ExerciseRecord(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      sessionId: sessionId ?? this.sessionId,
      gameId: gameId ?? this.gameId,
      wordId: wordId ?? this.wordId,
      promptType: promptType ?? this.promptType,
      isCorrect: isCorrect ?? this.isCorrect,
      answer: answer ?? this.answer,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      answerTimeMs: answerTimeMs ?? this.answerTimeMs,
      dimension: dimension ?? this.dimension,
      createdAt: createdAt ?? this.createdAt,
      prompt: prompt ?? this.prompt,
      options: options ?? this.options,
      confidence: confidence ?? this.confidence,
      wrongOption: wrongOption ?? this.wrongOption,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'sessionId': sessionId,
      'gameId': gameId,
      'wordId': wordId,
      'promptType': promptType,
      'isCorrect': isCorrect,
      'answer': answer,
      'correctAnswer': correctAnswer,
      'answerTimeMs': answerTimeMs,
      'dimension': dimension.name,
      'createdAt': createdAt.toIso8601String(),
      'prompt': prompt,
      'options': options,
      'confidence': confidence,
      'wrongOption': wrongOption,
    };
  }

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    return ExerciseRecord(
      id: json['id'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      sessionId: json['sessionId'] as String? ?? '',
      gameId: json['gameId'] as String? ?? '',
      wordId: json['wordId'] as String? ?? '',
      promptType: json['promptType'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      answer: json['answer'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      answerTimeMs: json['answerTimeMs'] as int? ?? 0,
      dimension: _parseDimension(json['dimension']),
      createdAt: _parseDate(json['createdAt']),
      prompt: json['prompt'] as String? ?? '',
      options: _parseStringList(json['options']),
      confidence: json['confidence'] as int? ?? -1,
      wrongOption: json['wrongOption'] as String? ?? '',
    );
  }

  static ReviewDimension _parseDimension(Object? value) {
    final name = value?.toString();
    return ReviewDimension.values.firstWhere(
      (d) => d.name == name,
      orElse: () => ReviewDimension.confidence,
    );
  }

  static DateTime _parseDate(Object? value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  static List<String> _parseStringList(Object? value) {
    if (value is! Iterable) return const [];
    return List.unmodifiable(
      value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty),
    );
  }
}
