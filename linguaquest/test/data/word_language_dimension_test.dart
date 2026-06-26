// Tests for P2a: language dimension on Word and WordBook models.
// All tests verify backward-compat (existing zh JSON unaffected) + new ja fields.

import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  group('WordBook language field', () {
    test('defaults to zh when language field absent from JSON', () {
      final book = WordBook.fromJson({
        'id': 'hsk1',
        'title': 'HSK 1',
        'examType': 'HSK',
        'words': <Map>[],
        'wordIds': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
        // No 'language' key — simulates existing HSK JSON
      });
      expect(book.language, 'zh');
    });

    test('reads language from JSON when present', () {
      final book = WordBook.fromJson({
        'id': 'jlpt_n5',
        'title': 'JLPT N5',
        'examType': 'JLPT',
        'language': 'ja',
        'words': <Map>[],
        'wordIds': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      });
      expect(book.language, 'ja');
    });

    test('toJson serializes language', () {
      final book = WordBook.fromJson({
        'id': 'jlpt_n5',
        'title': 'JLPT N5',
        'examType': 'JLPT',
        'language': 'ja',
        'words': <Map>[],
        'wordIds': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      });
      final json = book.toJson();
      expect(json['language'], 'ja');
    });

    test('toJson includes language zh for default books', () {
      final book = WordBook.fromJson({
        'id': 'hsk1',
        'title': 'HSK 1',
        'examType': 'HSK',
        'words': <Map>[],
        'wordIds': <String>[],
        'createdAt': DateTime.now().toIso8601String(),
      });
      final json = book.toJson();
      expect(json['language'], 'zh');
    });
  });

  group('Word Japanese fields', () {
    Map<String, dynamic> minimalWordJson({
      String id = 'test-word',
      String word = '你好',
    }) =>
        {
          'id': id,
          'word': word,
          'definitions': ['hello'],
          'englishDefinitions': ['hello'],
          'difficulty': 'Easy',
          'hskLevel': 1,
        };

    test('kana defaults to empty string when absent from JSON', () {
      final w = Word.fromJson(minimalWordJson());
      expect(w.kana, '');
    });

    test('romaji defaults to empty string when absent from JSON', () {
      final w = Word.fromJson(minimalWordJson());
      expect(w.romaji, '');
    });

    test('examLevel defaults to null when absent from JSON', () {
      final w = Word.fromJson(minimalWordJson());
      expect(w.examLevel, isNull);
    });

    test('kana/romaji/examLevel round-trip through toJson/fromJson', () {
      final jsonIn = {
        ...minimalWordJson(id: 'konnichiwa', word: 'こんにちは'),
        'kana': 'こんにちは',
        'romaji': 'konnichiwa',
        'examLevel': 5,
        'hskLevel': null,
      };
      final word = Word.fromJson(jsonIn);
      expect(word.kana, 'こんにちは');
      expect(word.romaji, 'konnichiwa');
      expect(word.examLevel, 5);

      final jsonOut = word.toJson();
      expect(jsonOut['kana'], 'こんにちは');
      expect(jsonOut['romaji'], 'konnichiwa');
      expect(jsonOut['examLevel'], 5);

      // Re-parse from toJson to confirm full round-trip
      final word2 = Word.fromJson(jsonOut);
      expect(word2.kana, 'こんにちは');
      expect(word2.romaji, 'konnichiwa');
      expect(word2.examLevel, 5);
    });

    test('existing zh word toJson still has hskLevel', () {
      final w = Word.fromJson(minimalWordJson());
      final json = w.toJson();
      expect(json['hskLevel'], 1);
    });

    test('existing zh word toJson has empty kana/romaji and null examLevel', () {
      final w = Word.fromJson(minimalWordJson());
      final json = w.toJson();
      expect(json['kana'], '');
      expect(json['romaji'], '');
      expect(json['examLevel'], isNull);
    });
  });

  group('Word.phoneticFor(language)', () {
    test('phoneticFor zh returns phonetic (pinyin)', () {
      final w = Word.fromJson({
        'id': 'ni',
        'word': '你',
        'phoneticUK': 'nǐ',
        'definitions': ['you'],
        'englishDefinitions': ['you'],
        'difficulty': 'Easy',
        'hskLevel': 1,
      });
      expect(w.phoneticFor('zh'), 'nǐ');
    });

    test('phoneticFor ja returns kana', () {
      final w = Word.fromJson({
        'id': 'konnichiwa',
        'word': 'こんにちは',
        'kana': 'こんにちは',
        'romaji': 'konnichiwa',
        'definitions': ['hello'],
        'englishDefinitions': ['hello'],
        'difficulty': 'Easy',
        'examLevel': 5,
      });
      expect(w.phoneticFor('ja'), 'こんにちは');
    });

    test('phoneticFor zh falls back gracefully when phonetic empty', () {
      final w = Word.fromJson({
        'id': 'test',
        'word': '测',
        'definitions': ['test'],
        'englishDefinitions': ['test'],
        'difficulty': 'Easy',
      });
      expect(w.phoneticFor('zh'), '');
    });

    test('phoneticFor ja falls back to romaji when kana empty', () {
      final w = Word.fromJson({
        'id': 'sakura',
        'word': '桜',
        'romaji': 'sakura',
        'definitions': ['cherry blossom'],
        'englishDefinitions': ['cherry blossom'],
        'difficulty': 'Easy',
        'examLevel': 4,
      });
      expect(w.phoneticFor('ja'), 'sakura');
    });

    test('phoneticFor unknown language returns empty string', () {
      final w = Word.fromJson({
        'id': 'word',
        'word': 'word',
        'phoneticUK': '/wɜːrd/',
        'definitions': ['word'],
        'englishDefinitions': ['word'],
        'difficulty': 'Easy',
      });
      // For unknown language, return empty (no zh pinyin, no ja kana)
      expect(w.phoneticFor('en'), '');
    });
  });

  group('Backward compatibility — existing HSK JSON loads unchanged', () {
    test('HSK word without new fields still parses correctly', () {
      final w = Word.fromJson({
        'id': 'yi',
        'word': '一',
        'phoneticUK': 'yī',
        'phoneticUS': 'yī',
        'audioUKUrl': '',
        'audioUSUrl': '',
        'partOfSpeech': 'number',
        'definitions': ['one', 'a/an'],
        'englishDefinitions': ['one', 'a/an'],
        'malayDefinitions': <String>[],
        'exampleSentences': [
          {'en': 'I have one book.', 'cn': '我有一本书。'},
        ],
        'collocations': <Map>[],
        'synonyms': <String>[],
        'antonyms': <String>[],
        'derivatives': <String>[],
        'rootAffix': '',
        'examTags': ['hsk1'],
        'difficulty': 'Easy',
        'imageUrl': '',
        'hskLevel': 1,
      });
      expect(w.hskLevel, 1);
      expect(w.kana, '');
      expect(w.romaji, '');
      expect(w.examLevel, isNull);
      expect(w.phonetic, 'yī');
      expect(w.phoneticFor('zh'), 'yī');
    });
  });
}
