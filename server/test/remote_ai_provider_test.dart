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

    test('sentence_analysis round-trip parses structure', () async {
      final content = jsonEncode({
        'mainClause': 'The fox jumps',
        'clauses': <String>[],
        'modifiers': ['quick', 'brown'],
        'translation': '狐狸跳',
        'vocabularyNotes': <String>[],
      });
      final client = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': content}},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        ),
      );
      final res = await _provider(client).generate(
        const AiRequest(
          featureType: 'sentence_analysis',
          userId: 'u1',
          prompt: 'The quick brown fox jumps',
        ),
      );
      expect(res.success, isTrue);
      expect(res.data['mainClause'], equals('The fox jumps'));
      expect(res.data['translation'], equals('狐狸跳'));
      expect(res.data['modifiers'], isA<List>());
    });

    test('writing_review round-trip parses rubric and suggestions', () async {
      final content = jsonEncode({
        'totalScore': 82,
        'rubricScores': {
          'content': 18,
          'language': 17,
          'structure': 16,
          'vocabulary': 16,
          'accuracy': 15,
        },
        'mainIssues': ['x'],
        'paragraphSuggestions': <dynamic>[],
        'highScoreExpressions': <String>[],
        'grammarIssues': <dynamic>[],
        'rewrittenSample': 'rewritten',
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
          featureType: 'writing_review',
          userId: 'u1',
          prompt: 'My essay',
        ),
      );
      expect(res.success, isTrue);
      expect(res.data['totalScore'], equals(82));
      expect(res.data['rubricScores'], isA<Map>());
      expect(res.data['rewrittenSample'], equals('rewritten'));
    });

    test('empty choices list returns ai_unavailable', () async {
      final client = MockClient(
        (req) async => http.Response(
          jsonEncode({'choices': []}),
          200,
        ),
      );
      final res = await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(res.success, isFalse);
      expect(res.errorCode, equals('ai_unavailable'));
    });
  });
}
