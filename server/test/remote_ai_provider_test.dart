import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../lib/src/ai_policy.dart';

http.Response _chatOk() {
  final content = jsonEncode({
    'answer': 'Hello means a greeting.',
    'cautions': <String>[],
    'relatedWords': ['hi', 'hey'],
  });
  return http.Response(
    jsonEncode({
      'choices': [
        {'message': {'content': content}},
      ],
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

RemoteAiProvider _provider(MockClient client) => RemoteAiProvider(
      client: client,
      apiKey: 'test-key',
      baseUrl: 'https://opencode.ai/zen/v1',
      model: 'deepseek-v4-flash-free',
    );

void main() {
  group('RemoteAiProvider', () {
    test('parses valid chat completion into structured data', () async {
      final client = MockClient((req) async => _chatOk());
      final provider = _provider(client);
      final res = await provider.generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(res.success, isTrue);
      expect(res.data['answer'], equals('Hello means a greeting.'));
      expect(res.data['relatedWords'], equals(['hi', 'hey']));
    });

    test('sends bearer key in Authorization header only', () async {
      String? auth;
      Object? bodyContainsKey;
      final client = MockClient((req) async {
        auth = req.headers['Authorization'];
        bodyContainsKey = req.body.contains('test-key');
        return _chatOk();
      });
      await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(auth, equals('Bearer test-key'));
      expect(bodyContainsKey, isFalse);
    });

    test('non-200 returns ai_unavailable without leaking upstream body', () async {
      final client = MockClient(
        (req) async => http.Response('upstream secret error 401', 401),
      );
      final res = await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(res.success, isFalse);
      expect(res.errorCode, equals('ai_unavailable'));
      expect(res.data, isEmpty);
    });

    test('malformed JSON content returns ai_unavailable', () async {
      final client = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': 'not json at all'}},
            ],
          }),
          200,
        ),
      );
      final res = await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(res.success, isFalse);
      expect(res.errorCode, equals('ai_unavailable'));
    });

    test('cloze parses blanks structure', () async {
      final content = jsonEncode({
        'passage': 'The ___ was nice.',
        'blanks': [
          {'index': 0, 'answer': 'movie', 'options': ['movie', 'car', 'sky', 'pen']},
        ],
        'explanations': <String>[],
      });
      final client = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': content}},
            ],
          }),
          200,
        ),
      );
      final res = await _provider(client).generate(
        const AiRequest(
          featureType: 'cloze',
          userId: 'u1',
          prompt: 'cloze',
          targetWord: 'movie',
        ),
      );
      expect(res.success, isTrue);
      final blanks = res.data['blanks'] as List;
      expect(blanks.first['answer'], equals('movie'));
    });
  });
}
