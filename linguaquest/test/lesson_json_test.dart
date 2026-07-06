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

  test('new quiz question types round-trip through JSON correctly', () {
    // 验证4个新题型能被正确序列化和反序列化
    for (final typeName in [
      'sentenceCloze',
      'confusableChoice',
      'collocationChoice',
      'derivativeChoice',
    ]) {
      final question = QuizQuestion.fromJson({
        'id': 'q-$typeName',
        'type': typeName,
        'prompt': 'Test prompt for $typeName',
        'answer': 'allocate',
        'options': ['allocate', 'distribute', 'assign', 'deploy'],
        'explanation': 'Test explanation.',
        'word': {
          'id': 'allocate',
          'word': 'allocate',
          'meaning': '分配',
          'definitions': ['分配'],
          'partOfSpeech': 'verb',
        },
      });
      expect(
        question.type.name,
        typeName,
        reason: 'QuizQuestionType.$typeName should be parsed correctly',
      );
      // 序列化再反序列化
      final restored = QuizQuestion.fromJson(question.toJson());
      expect(restored.type.name, typeName);
      expect(restored.answer, 'allocate');
    }
  });

  test('lesson JSON tolerates null and non-string text fields', () {
    final lesson = Lesson.fromJson({
      'id': 42,
      'title': null,
      'section': 7,
      'status': null,
      'words': [
        {'id': 1, 'word': 2, 'meaning': null, 'difficulty': null},
      ],
      'questions': [
        {
          'id': 3,
          'prompt': null,
          'answer': 4,
          'explanation': 5,
          'word': {'id': 6, 'word': 7, 'meaning': 8},
        },
      ],
    });

    expect(lesson.id, '42');
    expect(lesson.title, '');
    expect(lesson.section, '7');
    expect(lesson.status, 'locked');
    expect(lesson.words.single.word, '2');
    expect(lesson.words.single.meaning, '');
    expect(lesson.words.single.difficulty, 'Medium');
    expect(lesson.questions.single.id, '3');
    expect(lesson.questions.single.prompt, '');
    expect(lesson.questions.single.answer, '4');
    expect(lesson.questions.single.explanation, '5');
    expect(lesson.questions.single.word.id, '6');
    expect(lesson.questions.single.word.word, '7');
    expect(lesson.questions.single.word.meaning, '8');
  });
}
