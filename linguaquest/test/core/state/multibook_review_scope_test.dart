import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_word.dart';

void main() {
  test(
    'switching language or book does not mix review and weak-word queues',
    () {
      final books = [
        for (final id in ['zh_starter', 'ja_starter', 'en_starter', 'en_basic'])
          WordBook.fromJson(
            jsonDecode(
                  File('lib/assets/data/wordbook_$id.json').readAsStringSync(),
                )
                as Map<String, dynamic>,
          ),
      ];
      final now = DateTime.now().subtract(const Duration(days: 1));
      final records = [
        for (final book in books)
          UserWord.create(
            uid: 'u',
            word: book.words.first,
            wordBookId: book.id,
            now: now,
          ).copyWith(status: 'Review', wrongCount: 3, masteryLevel: 1),
      ];
      var state = AppState.initial().copyWith(
        wordBooks: books,
        userWords: records,
      );
      for (final book in books) {
        state = state.copyWith(
          currentWordBookId: book.id,
          currentLanguage: book.language,
        );
        expect(state.reviewQueue.map((w) => w.word), [book.words.first.word]);
        expect(state.reviewQueue.single.wordBookId, book.id);
        expect(state.weakWords.map((w) => w.word), [book.words.first.word]);
      }
      expect(state.userWords, hasLength(4));
      expect(
        state.reviewWords,
        hasLength(3),
        reason: 'global history remains available',
      );
    },
  );
}
