import 'package:flutter_test/flutter_test.dart';

import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  group('MockAiRepository', () {
    late MockAiRepository repo;

    setUp(() {
      repo = MockAiRepository();
    });

    test('chat returns structured mock response', () async {
      final result = await repo.chat(
        prompt: 'What does hello mean?',
        targetLanguage: 'zh',
      );
      expect(result['answer'], isA<String>());
      expect(result['cautions'], isA<List>());
      expect(result['relatedWords'], isA<List>());
    });

    test('analyzeStatement returns mock analysis', () async {
      final result = await repo.analyzeStatement(
        prompt: 'The quick brown fox jumps over the lazy dog.',
        targetLanguage: 'zh',
      );
      expect(result['mainClause'], isA<String>());
      expect(result['translation'], isA<String>());
      expect(result['clauses'], isA<List>());
    });

    test('generateCloze returns mock cloze with blanks', () async {
      final result = await repo.generateCloze(
        prompt: 'Generate cloze for: interesting',
        targetLanguage: 'zh',
        targetWord: 'interesting',
      );
      expect(result['passage'], isA<String>());
      expect(result['blanks'], isA<List>());
      final blanks = result['blanks'] as List;
      expect(blanks, isNotEmpty);
      expect(blanks.first['answer'], equals('interesting'));
    });

    test('listHistory returns inserted entries after chat', () async {
      await repo.chat(prompt: 'test question 1', targetLanguage: 'zh');
      await repo.chat(prompt: 'test question 2', targetLanguage: 'zh');
      final history = await repo.listHistory();
      expect(history.length, equals(2));
      expect(history.first.featureType, equals('chat'));
    });

    test('deleteHistory removes entry from list', () async {
      await repo.chat(prompt: 'test question', targetLanguage: 'zh');
      final history = await repo.listHistory();
      expect(history.length, equals(1));
      await repo.deleteHistory(history.first.id);
      final afterDelete = await repo.listHistory();
      expect(afterDelete, isEmpty);
    });

    test('listHistory returns entries in reverse chronological order', () async {
      await repo.chat(prompt: 'first question', targetLanguage: 'zh');
      await repo.analyzeStatement(
        prompt: 'second sentence',
        targetLanguage: 'zh',
      );
      final history = await repo.listHistory();
      expect(history.length, equals(2));
      // Most recent first
      expect(history.first.featureType, equals('sentence_analysis'));
    });
  });
}
