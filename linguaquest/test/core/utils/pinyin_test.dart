import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/utils/pinyin.dart';

void main() {
  group('normalizePinyin', () {
    test('strips tone marks and lowercases', () {
      expect(normalizePinyin('nǐ hǎo'), 'nihao');
      expect(normalizePinyin('Ài'), 'ai');
    });

    test('treats spaces, apostrophes and case as insignificant', () {
      expect(normalizePinyin('ni hao'), 'nihao');
      expect(normalizePinyin("xi'an"), 'xian');
      expect(normalizePinyin('  PÉNG you '), 'pengyou');
    });

    test('maps ü/v to u and keeps plain letters', () {
      expect(normalizePinyin('nǚ'), 'nu');
      expect(normalizePinyin('lv'), 'lu');
      expect(normalizePinyin('hello'), 'hello');
    });

    test('empty stays empty', () {
      expect(normalizePinyin(''), '');
      expect(normalizePinyin('   '), '');
    });

    test('toneless typed pinyin matches the canonical answer', () {
      // The quiz compares normalizePinyin(input) == normalizePinyin(answer).
      expect(normalizePinyin('ni hao'), normalizePinyin('nǐhǎo'));
      expect(normalizePinyin('PENGYOU'), normalizePinyin('péngyou'));
    });
  });
}
