import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../lib/src/ai_policy.dart';

http.Client _capturingClient(List<String> capturedModels) {
  return MockClient((request) async {
    final body = jsonDecode(request.body) as Map<String, dynamic>;
    capturedModels.add(body['model'] as String);
    return http.Response(
      jsonEncode({
        'choices': [
          {
            'message': {'content': '{"answer":"ok","cautions":[],"relatedWords":[]}'}
          }
        ]
      }),
      200,
    );
  });
}

void main() {
  test('uses base model when no override', () async {
    final captured = <String>[];
    final provider = RemoteAiProvider(
      client: _capturingClient(captured),
      apiKey: 'k',
      baseUrl: 'https://example.test/v1',
      model: 'base-model',
    );
    await provider.generate(const AiRequest(
        featureType: 'chat', userId: 'u', prompt: 'hi'));
    expect(captured.single, 'base-model');
  });

  test('uses modelOverride when provided', () async {
    final captured = <String>[];
    final provider = RemoteAiProvider(
      client: _capturingClient(captured),
      apiKey: 'k',
      baseUrl: 'https://example.test/v1',
      model: 'base-model',
    );
    await provider.generate(const AiRequest(
        featureType: 'chat',
        userId: 'u',
        prompt: 'hi',
        modelOverride: 'fast-model'));
    expect(captured.single, 'fast-model');
  });
}
