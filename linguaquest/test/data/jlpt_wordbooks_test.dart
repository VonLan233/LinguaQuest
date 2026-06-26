import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  const expectedMinWords = {
    'jlpt_n5': 600,
    'jlpt_n4': 500,
    'jlpt_n3': 500,
    'jlpt_n2': 800,
    'jlpt_n1': 1000,
  };

  for (final entry in expectedMinWords.entries) {
    final bookId = entry.key;
    final minWords = entry.value;

    test('$bookId parses as a valid Japanese wordbook with kana+romaji', () {
      final file = File('lib/assets/data/wordbook_$bookId.json');
      expect(file.existsSync(), isTrue, reason: '$bookId asset must exist');

      final book = WordBook.fromJson(
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
      );

      expect(book.id, bookId);
      expect(book.language, 'ja',
          reason: '$bookId must have language == ja');
      expect(book.words.length, greaterThanOrEqualTo(minWords),
          reason: '$bookId must have at least $minWords words');
      expect(book.words.length, book.wordIds.length,
          reason: 'wordIds count must match words count');

      final ids = <String>{};
      for (final word in book.words) {
        expect(word.word.trim(), isNotEmpty,
            reason: 'every word must have characters: ${word.id}');
        expect(word.kana.trim(), isNotEmpty,
            reason: 'every ja word must have kana: ${word.word}');
        expect(word.romaji.trim(), isNotEmpty,
            reason: 'every ja word must have romaji: ${word.word}');
        expect(word.examLevel, isNotNull,
            reason: 'every ja word must have examLevel: ${word.word}');
        expect(word.audioUrl.trim(), isNotEmpty,
            reason: 'every ja word must have an audioUrl: ${word.word}');
        expect(ids.add(word.id), isTrue,
            reason: 'word ids must be unique, dup: ${word.id}');

        // English definitions must be present and non-empty.
        final enDefs = word.definitionsFor('en');
        expect(enDefs, isNotEmpty,
            reason: 'every ja word must have English definitions: ${word.word}');
      }
    });
  }

  test('all 11 wordbooks (6 HSK + 5 JLPT) are parseable side-by-side', () {
    const allIds = [
      'hsk1', 'hsk2', 'hsk3', 'hsk4', 'hsk5', 'hsk6',
      'jlpt_n5', 'jlpt_n4', 'jlpt_n3', 'jlpt_n2', 'jlpt_n1',
    ];
    for (final id in allIds) {
      final file = File('lib/assets/data/wordbook_$id.json');
      expect(file.existsSync(), isTrue, reason: '$id must exist');
      final book = WordBook.fromJson(
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
      );
      expect(book.id, id);
      expect(book.words, isNotEmpty, reason: '$id must have words');
    }
  });
}
