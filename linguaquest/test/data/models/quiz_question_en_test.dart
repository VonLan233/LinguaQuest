import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  test('fromJson 读英文字段', () {
    final q = QuizQuestion.fromJson({
      'id': 'q1',
      'type': 'meaningChoice',
      'prompt': '老师姓什么？',
      'options': ['王', '李'],
      'answer': '王',
      'explanation': '文章说她叫王老师。',
      'promptEn': "What is the teacher's surname?",
      'optionsEn': ['Wang', 'Li'],
      'explanationEn': 'The text says she is Teacher Wang.',
    });
    expect(q.promptEn, "What is the teacher's surname?");
    expect(q.optionsEn, ['Wang', 'Li']);
    expect(q.explanationEn, 'The text says she is Teacher Wang.');
  });

  test('缺英文字段时为 null（向后兼容）', () {
    final q = QuizQuestion.fromJson({
      'id': 'q1',
      'type': 'meaningChoice',
      'prompt': 'p',
      'options': ['a', 'b'],
      'answer': 'a',
      'explanation': 'e',
    });
    expect(q.promptEn, isNull);
    expect(q.optionsEn, isNull);
    expect(q.explanationEn, isNull);
  });
}
