import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/training/passage_cloze_questions.dart';

void main() {
  test('converts AI blanks into contextChoice questions', () {
    final ai = {
      'passage': 'I ___ to school and ___ a book.',
      'blanks': [
        {'index': 0, 'answer': 'walk', 'options': ['walk', 'run', 'fly', 'swim']},
        {'index': 1, 'answer': 'read', 'options': ['read', 'eat', 'cut', 'see']},
      ],
    };
    final qs = passageClozeQuestions(ai, const <Word>[]);
    expect(qs.length, 2);
    expect(qs[0].type, QuizQuestionType.contextChoice);
    expect(qs[0].answer, 'walk');
    expect(qs[0].options, containsAll(<String>['walk', 'run']));
    // The active blank is shown; the prompt references the passage.
    expect(qs[0].prompt, contains('school'));
  });

  test('returns empty when blanks are missing or malformed', () {
    expect(passageClozeQuestions(const {}, const <Word>[]), isEmpty);
    expect(passageClozeQuestions({'blanks': 'nope'}, const <Word>[]), isEmpty);
  });
}
