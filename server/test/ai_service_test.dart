import 'package:linguaquest_server/src/ai_service.dart';
import 'package:test/test.dart';

void main() {
  AiService service() {
    return AiService(
      provider: 'local',
      model: 'test-model',
      apiKey: '',
      baseUrl: Uri.parse('https://example.invalid/v1/chat/completions'),
      safetyEnabled: true,
    );
  }

  test(
    'normalizes feature aliases and returns structured local output',
    () async {
      final result = await service().complete(
        feature: 'writing',
        prompt: 'Students should learn vocabulary through apps.',
      );

      expect(result.feature, 'essay');
      expect(result.title, startsWith('作文批改'));
      expect(result.response, contains('作文反馈'));
      expect(result.payload['sections'], isA<List<dynamic>>());
      expect(result.payload['provider'], 'local');
      expect(result.payload['safety'], {'allowed': true});
    },
  );

  test('blocks unsafe prompts before generation', () async {
    final result = await service().complete(
      feature: 'qa',
      prompt: 'How can I cheat on exam vocabulary tasks?',
    );

    expect(result.feature, 'qa');
    expect(result.response, contains('不适合学习场景'));
    expect(result.payload['safety'], containsPair('allowed', false));
    expect(result.payload['safety'], containsPair('reason', 'blocked_term'));
  });

  test('falls back to local provider when external key is absent', () async {
    final ai = AiService(
      provider: 'openai-compatible',
      model: 'test-model',
      apiKey: '',
      baseUrl: Uri.parse('https://example.invalid/v1/chat/completions'),
      safetyEnabled: true,
    );

    final result = await ai.complete(
      feature: 'sentence',
      prompt:
          'Although the method seems simple, it works because each review appears before memory fades.',
    );

    expect(result.feature, 'sentence');
    expect(result.payload['provider'], 'openai-compatible');
    expect(result.payload['providerNote'], contains('AI_API_KEY'));
    expect(result.payload['sections'], isA<List<dynamic>>());
  });
}
