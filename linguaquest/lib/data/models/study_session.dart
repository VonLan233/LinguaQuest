import 'exercise_record.dart';

class StudySession {
  const StudySession({
    required this.id,
    required this.uid,
    required this.lessonId,
    required this.startedAt,
    required this.endedAt,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.xpEarned,
    required this.mistakeWordIds,
    this.exerciseRecords = const [],
    this.mode = 'lesson',
    this.source = 'home',
  });

  final String id;
  final String uid;
  final String lessonId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int totalQuestions;
  final int correctAnswers;
  final int xpEarned;
  final List<String> mistakeWordIds;
  final List<ExerciseRecordDraft> exerciseRecords;
  final String mode;
  final String source;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'lessonId': lessonId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'xpEarned': xpEarned,
      'earnedPoints': xpEarned,
      'mode': mode,
      'source': source,
      'mistakeWordIds': mistakeWordIds,
      'exerciseRecords': [
        for (final record in exerciseRecords)
          record.toJson(uid: uid, sessionId: id),
      ],
    };
  }
}
