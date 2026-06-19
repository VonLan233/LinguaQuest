import 'package:test/test.dart';

import '../lib/src/ai_policy.dart';

void main() {
  group('AiPolicyService', () {
    late AiPolicyService policy;

    setUp(() {
      policy = AiPolicyService(
        provider: MockAiProvider(),
        dailyLimitPerUser: 20,
      );
    });

    test('chat returns mock answer', () async {
      final response = await policy.handle(
        const AiRequest(
          featureType: 'chat',
          userId: 'user1',
          prompt: 'What does hello mean?',
        ),
      );
      expect(response.success, isTrue);
      expect(response.data['answer'], isA<String>());
      expect(response.data['cautions'], isA<List>());
      expect(response.data['relatedWords'], isA<List>());
    });

    test('sentence_analysis returns mock analysis', () async {
      final response = await policy.handle(
        const AiRequest(
          featureType: 'sentence_analysis',
          userId: 'user1',
          prompt: 'The quick brown fox jumps over the lazy dog.',
        ),
      );
      expect(response.success, isTrue);
      expect(response.data['mainClause'], isA<String>());
      expect(response.data['translation'], isA<String>());
    });

    test('cloze returns mock cloze with blanks', () async {
      final response = await policy.handle(
        const AiRequest(
          featureType: 'cloze',
          userId: 'user1',
          prompt: 'Generate cloze for: interesting',
          targetWord: 'interesting',
        ),
      );
      expect(response.success, isTrue);
      expect(response.data['passage'], isA<String>());
      expect(response.data['blanks'], isA<List>());
      final blanks = response.data['blanks'] as List;
      expect(blanks, isNotEmpty);
      expect(blanks.first['answer'], equals('interesting'));
    });

    test('prompt longer than 2000 chars returns too_long error', () async {
      final response = await policy.handle(
        AiRequest(
          featureType: 'chat',
          userId: 'user1',
          prompt: 'a' * 2001,
        ),
      );
      expect(response.success, isFalse);
      expect(response.errorCode, equals('too_long'));
    });

    test('unknown feature type returns error', () async {
      final response = await policy.handle(
        const AiRequest(
          featureType: 'unknown',
          userId: 'user1',
          prompt: 'test',
        ),
      );
      expect(response.success, isFalse);
    });
  });
}
