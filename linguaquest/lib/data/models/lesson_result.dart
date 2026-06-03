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
  });

  final String lessonId;
  final String lessonTitle;
  final int totalQuestions;
  final int correctAnswers;
  final int xpEarned;
  final List<QuizQuestion> mistakes;
  final DateTime completedAt;

  double get accuracy {
    if (totalQuestions == 0) return 0;
    return correctAnswers / totalQuestions;
  }

  LessonResult copyWith({int? xpEarned}) {
    return LessonResult(
      lessonId: lessonId,
      lessonTitle: lessonTitle,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      xpEarned: xpEarned ?? this.xpEarned,
      mistakes: mistakes,
      completedAt: completedAt,
    );
  }
}
