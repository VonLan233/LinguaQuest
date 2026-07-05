import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_word.dart';

void main() {
  Word word(String id) => Word.fromJson({'id': id, 'word': id});

  WordBook book(String id, int count) => WordBook(
    id: id,
    title: id,
    category: 'exam',
    examType: id,
    coverUrl: '',
    totalWords: count,
    includedWords: count,
    description: '',
    wordIds: const [],
    createdAt: DateTime(2026, 1, 1),
    words: [for (var i = 0; i < count; i++) word('$id-w$i')],
  );

  UserWord userWord(String wordId) => UserWord.create(
    uid: 'u',
    word: word(wordId),
    wordBookId: 'hsk1',
    now: DateTime(2026, 1, 1),
  );

  group('AppState.availableNewWords', () {
    test('offers every unstudied word in the current wordbook, not just a '
        '3-word lesson chunk', () {
      final state = AppState.initial().copyWith(
        wordBooks: [book('hsk1', 12)],
        currentWordBookId: 'hsk1',
      );
      // dailyNewTarget defaults to 10; the session must be able to draw at
      // least that many new words (bug 6.1 capped it at 3 via the lesson chunk).
      expect(state.availableNewWords.length, 12);
      expect(
        state.availableNewWords.take(state.dailyNewTarget).length,
        state.dailyNewTarget,
      );
    });

    test('excludes words already tracked in userWords, preserving order', () {
      final state = AppState.initial().copyWith(
        wordBooks: [book('hsk1', 5)],
        currentWordBookId: 'hsk1',
        userWords: [userWord('hsk1-w0'), userWord('hsk1-w2')],
      );
      expect(
        state.availableNewWords.map((w) => w.id).toList(),
        ['hsk1-w1', 'hsk1-w3', 'hsk1-w4'],
      );
    });

    test('is empty when there is no current wordbook', () {
      expect(AppState.initial().availableNewWords, isEmpty);
    });
  });
}
