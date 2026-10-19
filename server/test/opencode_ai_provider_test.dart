import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:linguaquest_server/src/ai_policy.dart';
import 'package:linguaquest_server/src/auth.dart';
import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/database.dart';
import 'package:linguaquest_server/src/opencode_ai_provider.dart';
import 'package:linguaquest_server/src/routes.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

const _request = AiRequest(
  featureType: 'chat',
  userId: 'u',
  prompt: 'Explain 学习',
  targetWord: '学习',
  targetLanguage: 'zh',
);

http.Response _answer() => http.Response(
  jsonEncode({
    'info': {'role': 'assistant'},
    'parts': [
      {'type': 'reasoning', 'text': 'This must not appear in the answer.'},
      {
        'type': 'text',
        'text': '{"answer":"To study","cautions":[],"relatedWords":[]}',
      },
    ],
  }),
  200,
);

void main() {
  late List<http.Request> calls;
  late http.Response Function(http.Request) respond;
  late MockClient client;
  late OpenCodeAiProvider provider;
  setUp(() {
    calls = [];
    respond = (_) => _answer();
    client = MockClient((request) async {
      calls.add(request);
      if (request.method == 'DELETE') return http.Response('true', 200);
      if (request.url.path == '/session') {
        return http.Response('{"id":"ses_test"}', 200);
      }
      return respond(request);
    });
    provider = OpenCodeAiProvider(
      client: client,
      baseUrl: 'http://opencode:4096/',
      password: 'internal-secret',
      model: 'deepseek-v4.1-flash-free',
    );
  });

  test(
    'creates isolated session, forwards tutor prompt, and deletes session',
    () async {
      final result = await provider.generate(_request);
      expect(result.success, isTrue);
      expect(result.data['answer'], 'To study');
      expect(calls.map((r) => '${r.method} ${r.url.path}'), [
        'POST /session',
        'POST /session/ses_test/message',
        'DELETE /session/ses_test',
      ]);
      final body = jsonDecode(calls[1].body);
      expect(body['agent'], 'tutor');
      expect(body['model'], {
        'providerID': 'opencode',
        'modelID': 'deepseek-v4.1-flash-free',
      });
      expect(body['system'], contains('Chinese-learning assistant'));
      expect(body['parts'][0]['text'], contains('Target word: 学习'));
      expect(
        calls[1].headers['Authorization'],
        'Basic ${base64Encode(utf8.encode('opencode:internal-secret'))}',
      );
      expect(calls[1].body, isNot(contains('internal-secret')));
    },
  );

  test('honors a free cloze model override', () async {
    await provider.generate(
      const AiRequest(
        featureType: 'cloze',
        userId: 'u',
        prompt: 'Make a cloze',
        modelOverride: 'glm-5.3-flash-free',
      ),
    );
    expect(jsonDecode(calls[1].body)['model']['modelID'], 'glm-5.3-flash-free');
  });

  test('refuses paid overrides without calling upstream', () async {
    final result = await provider.generate(
      const AiRequest(
        featureType: 'cloze',
        userId: 'u',
        prompt: 'Make a cloze',
        modelOverride: 'deepseek-v4.1-flash',
      ),
    );
    expect(result.errorCode, 'ai_unavailable');
    expect(calls, isEmpty);
  });

  test('rejects unknown features before creating sessions', () async {
    final result = await provider.generate(
      const AiRequest(featureType: 'unknown', userId: 'u', prompt: 'hi'),
    );
    expect(result.errorCode, 'unknown_feature');
    expect(calls, isEmpty);
  });

  for (final failure in ['status', 'model', 'json', 'timeout']) {
    test(
      '$failure failure is sanitized and still deletes the session',
      () async {
        respond = (_) => switch (failure) {
          'status' => http.Response('upstream internal-secret', 503),
          'model' => http.Response(
            '{"info":{"error":{"message":"internal-secret"}},"parts":[]}',
            200,
          ),
          'json' => http.Response(
            '{"info":{},"parts":[{"type":"text","text":"not json"}]}',
            200,
          ),
          _ => throw TimeoutException('internal-secret'),
        };
        final result = await provider.generate(_request);
        expect(result.success, isFalse);
        expect(result.errorCode, 'ai_unavailable');
        expect(result.data, isEmpty);
        expect(calls.last.method, 'DELETE');
      },
    );
  }

  test('session creation failure does not generate a message', () async {
    final broken = OpenCodeAiProvider(
      client: MockClient((_) async => http.Response('secret', 401)),
      baseUrl: 'http://opencode:4096',
      password: 'p',
      model: 'deepseek-v4.1-flash-free',
    );
    expect((await broken.generate(_request)).errorCode, 'ai_unavailable');
  });

  test(
    'remote route uses OpenCode without a Zen API key and preserves history',
    () async {
      const config = AppConfig(
        port: 0,
        databaseUrl: 'unused',
        jwtSecret: 'test',
        aiProvider: 'opencode',
        opencodeServerPassword: 'internal-secret',
      );
      final database = _AiDatabase();
      final router = buildRouter(config, database, httpClient: client);
      final token = issueToken(
        config,
        uid: 'u',
        email: 'smoke@example.invalid',
      );
      final response = await router(
        Request(
          'POST',
          Uri.parse('http://localhost/ai/chat'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: '{"prompt":"Explain 学习"}',
        ),
      );
      expect(response.statusCode, 200);
      expect(
        jsonDecode(await response.readAsString())['data']['answer'],
        'To study',
      );
      expect(database.saved, isTrue);
      expect(calls, hasLength(3));
    },
  );
}

class _AiDatabase extends AppDatabase {
  _AiDatabase() : super(_UnusedConnection());
  bool saved = false;

  @override
  Future<int> countAiHistoryToday(String userId) async => 0;

  @override
  Future<Map<String, dynamic>> insertAiHistory(
    String userId,
    String featureType,
    String prompt,
    Map<String, dynamic> response,
  ) async {
    saved = true;
    return {'id': 'history-test', 'createdAt': '2026-10-19T00:00:00Z'};
  }
}

class _UnusedConnection implements Connection {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('Database connection must not be used');
}
