import 'package:test/test.dart';

import '../lib/src/ai_policy.dart';

void main() {
  group('languageNameFor', () {
    test('maps known codes to English names', () {
      expect(languageNameFor('zh'), 'Chinese');
      expect(languageNameFor('ja'), 'Japanese');
      expect(languageNameFor('es'), 'Spanish');
      expect(languageNameFor('fr'), 'French');
      expect(languageNameFor('ms'), 'Malay');
    });
    test('falls back to Chinese for unknown/empty', () {
      expect(languageNameFor('xx'), 'Chinese');
      expect(languageNameFor(''), 'Chinese');
    });
  });

  group('buildSystemPrompt', () {
    test('chat: explanations English, relatedWords target language', () {
      final p = buildSystemPrompt('chat', 'Chinese')!;
      expect(p, contains('Chinese-learning assistant'));
      expect(p, contains('"answer" and "cautions" in English'));
      expect(p, contains('"relatedWords"'));
      expect(p, contains('Chinese'));
    });
    test('sentence_analysis: clause fields stay target language', () {
      final p = buildSystemPrompt('sentence_analysis', 'Japanese')!;
      expect(p, contains('Japanese'));
      expect(p, contains('"translation" and "vocabularyNotes" in English'));
    });
    test('cloze: passage/options target language, explanations English', () {
      final p = buildSystemPrompt('cloze', 'Chinese')!;
      expect(p, contains('"explanations" in English'));
      expect(p, contains('"passage"'));
    });
    test('writing_review: feedback English', () {
      final p = buildSystemPrompt('writing_review', 'Chinese')!;
      expect(p, contains('in English'));
      expect(p, contains('"rewrittenSample"'));
    });
    test('unknown feature returns null', () {
      expect(buildSystemPrompt('nope', 'Chinese'), isNull);
    });
  });
}
