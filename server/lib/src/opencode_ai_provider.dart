import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_policy.dart';

/// Uses the official OpenCode runtime: Zen's free tier rejects direct API calls.
class OpenCodeAiProvider implements AiProvider {
  OpenCodeAiProvider({
    required this.client,
    required this.baseUrl,
    required this.password,
    required this.model,
    this.timeout = const Duration(seconds: 50),
  });

  final http.Client client;
  final String baseUrl;
  final String password;
  final String model;
  final Duration timeout;

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final system = buildSystemPrompt(
      request.featureType,
      languageNameFor(request.targetLanguage),
    );
    if (system == null) {
      return const AiResponse(
        success: false,
        data: {},
        errorCode: 'unknown_feature',
      );
    }
    final selectedModel = request.modelOverride ?? model;
    // Never silently fall back to a paid model, including cloze overrides.
    if (!selectedModel.endsWith('-free') && selectedModel != 'big-pickle') {
      return _unavailable;
    }
    final headers = {
      'Content-Type': 'application/json',
      if (password.isNotEmpty)
        'Authorization':
            'Basic ${base64Encode(utf8.encode('opencode:$password'))}',
    };
    Uri endpoint(String path) =>
        Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}$path');
    String? sessionId;
    try {
      final created = await client
          .post(
            endpoint('/session'),
            headers: headers,
            body: jsonEncode({'title': 'LinguaQuest ${request.featureType}'}),
          )
          .timeout(const Duration(seconds: 5));
      if (created.statusCode != 200) return _unavailable;
      sessionId =
          (jsonDecode(created.body) as Map<String, dynamic>)['id'] as String;
      final response = await client
          .post(
            endpoint('/session/${Uri.encodeComponent(sessionId)}/message'),
            headers: headers,
            body: jsonEncode({
              'agent': 'tutor',
              'model': {'providerID': 'opencode', 'modelID': selectedModel},
              'system': system,
              'parts': [
                {
                  'type': 'text',
                  'text': request.targetWord == null
                      ? request.prompt
                      : '${request.prompt}\n\nTarget word: ${request.targetWord}',
                },
              ],
            }),
          )
          .timeout(timeout);
      if (response.statusCode != 200) return _unavailable;
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      if ((result['info'] as Map?)?['error'] != null) return _unavailable;
      final text = (result['parts'] as List)
          .where((part) => part['type'] == 'text')
          .map((part) => part['text'] as String)
          .join('\n');
      return AiResponse(
        success: true,
        data: jsonDecode(text) as Map<String, dynamic>,
      );
    } on TimeoutException {
      if (sessionId != null) {
        try {
          await client
              .post(
                endpoint('/session/${Uri.encodeComponent(sessionId)}/abort'),
                headers: headers,
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {}
      }
      return _unavailable;
    } catch (_) {
      return _unavailable;
    } finally {
      if (sessionId != null) {
        try {
          // Application history is stored in PostgreSQL, not in OpenCode.
          await client
              .delete(
                endpoint('/session/${Uri.encodeComponent(sessionId)}'),
                headers: headers,
              )
              .timeout(const Duration(seconds: 5));
        } catch (_) {
          // Cleanup failure must not discard a completed learning response.
        }
      }
    }
  }

  static const _unavailable = AiResponse(
    success: false,
    data: {},
    errorCode: 'ai_unavailable',
  );
}
