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
    for (final target in ['zh', 'ja', 'en']) {
      for (final helper in ['zh', 'ja', 'en']) {
        test('$helper explanations for $target content', () {
          final prompt = buildSystemPrompt(
            'chat',
            languageNameFor(target),
            helperLanguage: helper,
          )!;
          expect(
            prompt,
            contains('${languageNameFor(target)}-learning assistant'),
          );
          expect(
            prompt,
            contains('"answer" and "cautions" in ${languageNameFor(helper)}'),
          );
          expect(prompt, contains('${languageNameFor(target)} words'));
        });
      }
    }
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
    test('cloze: short passage, 3-4 blanks, target language', () {
      final p = buildSystemPrompt('cloze', 'Chinese')!;
      expect(p, contains('"explanations" in English'));
      expect(p, contains('"passage"'));
      expect(p, contains('2-3 sentences'));
      expect(p, contains('EXACTLY 3 to 4 blanks'));
    });
    test('reading_explain: structured fields, content language vs English', () {
      final p = buildSystemPrompt('reading_explain', 'Chinese')!;
      expect(p, contains('Chinese paragraph'));
      expect(p, contains('"gist"'));
      expect(p, contains('"keyWords"'));
      expect(p, contains('"grammarPoints"'));
      expect(p, contains('"structure"'));
      expect(p, contains('"translation"'));
      expect(p, contains('"practice"'));
      expect(p, contains('No markdown'));
    });
    test('writing_review: feedback English', () {
      final p = buildSystemPrompt('writing_review', 'Chinese')!;
      expect(p, contains('in English'));
      expect(p, contains('"rewrittenSample"'));
    });
    test('unknown feature returns null', () {
      expect(buildSystemPrompt('nope', 'Chinese'), isNull);
    });
    test('buildSystemPrompt covers confusion and sentence_gen', () {
      final confusion = buildSystemPrompt('confusion', 'Chinese');
      expect(confusion, isNotNull);
      expect(confusion, contains('"pairs"'));
      expect(confusion, contains('No markdown'));

      final sentence = buildSystemPrompt('sentence_gen', 'Chinese');
      expect(sentence, isNotNull);
      expect(sentence, contains('"sentences"'));
      expect(sentence, contains('"rewrites"'));
    });
  });
}
