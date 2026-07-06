import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  final cjk = RegExp(r'[一-鿿]');
  // generated from the public HSK dataset (tools/generate_hsk_wordbooks.py)
  const expectedMin = {2: 140, 3: 280, 4: 580, 5: 1280, 6: 2480};

  for (final level in [2, 3, 4, 5, 6]) {
    test('wordbook_hsk$level.json parses as a full, English-meaning HSK book',
        () {
      final file = File('lib/assets/data/wordbook_hsk$level.json');
      expect(file.existsSync(), isTrue);

      final book = WordBook.fromJson(
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
      );

      expect(book.id, 'hsk$level');
      expect(book.titleEn, 'HSK $level');
      // Real data, not a 3-word stub.
      expect(book.words.length, greaterThanOrEqualTo(expectedMin[level]!));
      expect(book.words.length, book.wordIds.length);

      final ids = <String>{};
      for (final word in book.words) {
        expect(word.word.trim(), isNotEmpty);
        expect(word.phonetic.trim(), isNotEmpty, reason: 'pinyin: ${word.word}');
        expect(word.hskLevel, level);
        expect(word.audioUrl.trim(), isNotEmpty, reason: 'audio: ${word.word}');
        expect(ids.add(word.id), isTrue, reason: 'dup id ${word.id}');

        final enMeanings = word.definitionsFor('en');
        expect(enMeanings, isNotEmpty, reason: 'meaning: ${word.word}');
        // No Chinese characters must leak into the English meaning.
        for (final m in enMeanings) {
          expect(cjk.hasMatch(m), isFalse,
              reason: 'CJK in meaning: ${word.word} -> $m');
        }
      }
    });
  }
}
