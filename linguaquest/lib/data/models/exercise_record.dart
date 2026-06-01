class ExerciseRecordDraft {
  const ExerciseRecordDraft({
    required this.id,
    required this.wordId,
    required this.exerciseType,
    required this.prompt,
    required this.options,
    required this.correctAnswer,
    required this.userAnswer,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.createdAt,
    this.confidence,
  });

  final String id;
  final String wordId;
  final String exerciseType;
  final String prompt;
  final List<String> options;
  final String correctAnswer;
  final String userAnswer;
  final bool isCorrect;
  final int responseTimeMs;
  final int? confidence;
  final DateTime createdAt;

  Map<String, dynamic> toJson({
    required String uid,
    required String sessionId,
  }) {
    return {
      'id': id,
      'sessionId': sessionId,
      'uid': uid,
      'wordId': wordId,
      'exerciseType': exerciseType,
      'prompt': prompt,
      'options': options,
      'correctAnswer': correctAnswer,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'responseTimeMs': responseTimeMs,
      'confidence': confidence,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
