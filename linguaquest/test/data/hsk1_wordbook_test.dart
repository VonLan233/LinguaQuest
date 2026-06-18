import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  final cjk = RegExp(r'[一-鿿]');

  test('wordbook_hsk1.json is a valid, non-trivial, English-meaning HSK seed', () {
    final file = File('lib/assets/data/wordbook_hsk1.json');
    expect(file.existsSync(), isTrue, reason: 'seed asset must exist');

    final book = WordBook.fromJson(
      Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
    );

    expect(book.id, 'hsk1');
    expect(book.titleEn, 'HSK 1');
    expect(book.words.length, greaterThan(100));

    final ids = <String>{};
    for (final word in book.words) {
      expect(word.word.trim(), isNotEmpty, reason: 'every word has characters');
      expect(word.phonetic.trim(), isNotEmpty, reason: 'every word has pinyin');
      expect(word.hskLevel, 1);
      expect(ids.add(word.id), isTrue, reason: 'word ids are unique: ${word.id}');

      // English meaning available under the English locale, and no Chinese
      // characters leak into the meaning the learner must select.
      final enMeanings = word.definitionsFor('en');
      expect(enMeanings, isNotEmpty);
      expect(word.meaning.trim(), isNotEmpty);
      expect(cjk.hasMatch(word.meaning), isFalse,
          reason: 'primary meaning must be English, not Chinese: ${word.word} -> ${word.meaning}');
      for (final m in enMeanings) {
        expect(cjk.hasMatch(m), isFalse,
            reason: 'english meaning has CJK: ${word.word} -> $m');
      }
    }
  });
}
