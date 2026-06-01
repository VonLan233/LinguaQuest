import 'exercise_record.dart';
import 'lesson.dart';

class LessonResult {
  const LessonResult({
    required this.lessonId,
    required this.lessonTitle,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.xpEarned,
    required this.mistakes,
    required this.completedAt,
    this.exerciseRecords = const [],
    this.sessionMode = 'lesson',
    this.sessionSource = 'home',
  });

  final String lessonId;
  final String lessonTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int xpEarned;
  final List<QuizQuestion> mistakes;
  final DateTime completedAt;
  final List<ExerciseRecordDraft> exerciseRecords;
  final String sessionMode;
  final String sessionSource;

  double get accuracy {
    if (totalQuestions == 0) return 0;
    return correctAnswers / totalQuestions;
  }
}
