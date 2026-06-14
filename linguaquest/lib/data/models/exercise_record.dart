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
    };
  }
}
