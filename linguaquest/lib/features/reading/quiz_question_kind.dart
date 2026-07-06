import '../../data/models/lesson.dart';

/// Derives a comprehension "kind" label for a reading [QuizQuestion], used only
/// for analytics (`ReadingResult.perKindCorrect`) — never affects the quiz
/// engine (OD-3: carry kind as a derived string, no enum churn).
///
/// The `QuizQuestion` model has no `kind` field, so we infer one from the shape:
/// two-option questions are treated as true/false; otherwise a generic single
/// choice. (When authored articles add a richer `kind` later, this is the single
/// place to read it.)
String comprehensionKind(QuizQuestion question) {
  if (question.options.length == 2) return 'trueFalse';
  return 'single';
}
