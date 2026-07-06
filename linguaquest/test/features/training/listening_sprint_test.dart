import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/training/training_session_screen.dart';

Word _w(String word) => Word(
      id: word,
      word: word,
      phonetic: '',
      meaning: 'meaning of $word',
      definition: 'meaning of $word',
      partOfSpeech: '',
      exampleSentence: '',
      exampleTranslation: '',
      imageCue: '',
      difficulty: 'A1',
      tags: const [],
    );

void main() {
  test('listening question hides the word in options and answers with it', () {
    final words = [_w('apple'), _w('banana'), _w('cherry'), _w('date')];
    final q = buildListeningQuestion(words[0], words, 0, 'listening prompt');
    expect(q.type, QuizQuestionType.listeningWordChoice);
    expect(q.answer, 'apple');
    expect(q.options, contains('apple'));
    expect(q.options.length, greaterThanOrEqualTo(2));
  });
}
