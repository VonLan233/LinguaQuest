import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/training/training_session_screen.dart';
import 'package:linguaquest/data/models/lesson.dart';

Word w(String s, String id) => Word.fromJson({'id': id, 'word': s, 'phoneticUK': '', 'phoneticUS': '', 'partOfSpeech': '', 'definitions': [s], 'englishDefinitions': [s]});

void main() {
  test('听力题选项打乱：答案不总在 index 0，且始终包含答案', () {
    final words = [w('一', '1'), w('二', '2'), w('三', '3'), w('四', '4'), w('五', '5')];
    var firstIsAnswer = 0;
    for (var i = 0; i < 10; i++) {
      final q = buildListeningQuestion(words[i % words.length], words, i, 'p');
      expect(q.options.contains(q.answer), isTrue);
      expect(q.options.length <= 4, isTrue);
      if (q.options.first == q.answer) firstIsAnswer++;
    }
    expect(firstIsAnswer < 10, isTrue, reason: '答案不应每题都在第一位');
  });
}
