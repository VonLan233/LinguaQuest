import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/seed/seed_lessons.dart';

void main() {
  test('lesson JSON round trip keeps words and questions parseable', () {
    final lesson = seedLessons().first;
    final restored = Lesson.fromJson(lesson.toJson());

    expect(restored.id, lesson.id);
    expect(
      restored.words.singleWhere((word) => word.id == 'w-allocate').word,
      'allocate',
    );
    expect(restored.questions.first.type, QuizQuestionType.meaningChoice);
    expect(restored.questions.first.word.id, lesson.questions.first.word.id);
  });

  test('quiz question JSON tolerates a missing word object', () {
    final question = QuizQuestion.fromJson({
      'id': 'question-missing-word',
      'type': 'meaningChoice',
      'prompt': 'Choose the meaning.',
      'answer': 'allocate',
      'options': ['分配', '比较'],
      'word': null,
    });

    expect(question.word.id, 'allocate');
    expect(question.word.word, 'allocate');
  });
}
