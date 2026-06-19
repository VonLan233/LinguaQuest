import 'dart:convert';

import 'package:http/http.dart' as http;

class AiRequest {
  const AiRequest({
    required this.featureType,
    required this.userId,
    required this.prompt,
    this.targetWord,
  });

  final String featureType;
  final String userId;
  final String prompt;
  final String? targetWord;
}

class AiResponse {
  const AiResponse({required this.success, required this.data, this.errorCode});

  final bool success;
  final Map<String, dynamic> data;
  final String? errorCode;
}

abstract class AiProvider {
  Future<AiResponse> generate(AiRequest request);
}

class MockAiProvider implements AiProvider {
  @override
  Future<AiResponse> generate(AiRequest request) async {
    final snippet = request.prompt.length > 30
        ? request.prompt.substring(0, 30)
        : request.prompt;
    switch (request.featureType) {
      case 'chat':
        return AiResponse(
          success: true,
          data: {
            'answer': 'Mock answer for: $snippet',
            'cautions': <String>[],
            'relatedWords': <String>[],
          },
        );
      case 'sentence_analysis':
        return AiResponse(
          success: true,
          data: {
            'mainClause': 'Mock main clause',
            'clauses': <String>[],
            'modifiers': <String>[],
            'translation': 'Mock translation',
            'vocabularyNotes': <String>[],
          },
        );
      case 'cloze':
        final word = request.targetWord ?? 'word';
        return AiResponse(
          success: true,
          data: {
            'passage': 'The ___ was very interesting.',
            'blanks': [
              {
                'index': 0,
                'answer': word,
                'options': [word, 'thing', 'idea', 'place'],
              },
            ],
            'explanations': <String>[],
          },
        );
      case 'writing_review':
        return AiResponse(success: true, data: {
          'totalScore': 75,
          'rubricScores': {
            'content': 18,
            'language': 15,
            'structure': 14,
            'vocabulary': 15,
            'accuracy': 13,
          },
          'mainIssues': [
            'Limited vocabulary variety',
            'Some grammar errors in complex sentences',
          ],
          'paragraphSuggestions': [
            {'paragraph': 1, 'suggestion': 'Strengthen your opening argument'},
          ],
          'highScoreExpressions': [
            'Furthermore, it is worth noting that...',
            'From the perspective of...',
          ],
          'grammarIssues': [
            {'original': 'I am agree', 'corrected': 'I agree', 'rule': 'Stative verb'},
          ],
          'rewrittenSample': 'Mock rewritten essay paragraph...',
        });
      default:
        return const AiResponse(
          success: false,
          data: {},
          errorCode: 'unknown_feature',
        );
    }
  }
}

class AiPolicyService {
  AiPolicyService({
    required this.provider,
    required this.dailyLimitPerUser,
    this.dailyCountLookup,
  });

  static const int _maxPromptLength = 2000;

  /// Deterministic minimal block-list for clearly disallowed requests.
  /// Intentionally small; extend as needed. Case-insensitive substring match.
  static const List<String> blockedKeywords = [
    'make a bomb',
    'build a bomb',
    'how to kill',
    '制造炸弹',
    '自杀方法',
  ];

  final AiProvider provider;
  final int dailyLimitPerUser;
  final Future<int> Function(String userId)? dailyCountLookup;

  String? validateRequest(AiRequest request) {
    final maxLength =
        request.featureType == 'writing_review' ? 3000 : _maxPromptLength;
    if (request.prompt.length > maxLength) return 'too_long';
    final lower = request.prompt.toLowerCase();
    for (final kw in blockedKeywords) {
      if (lower.contains(kw.toLowerCase())) return 'blocked';
    }
    return null;
  }

  Future<AiResponse> handle(AiRequest request) async {
    final err = validateRequest(request);
    if (err != null) {
      return AiResponse(success: false, data: {}, errorCode: err);
    }
    final lookup = dailyCountLookup;
    if (lookup != null) {
      final count = await lookup(request.userId);
      if (count >= dailyLimitPerUser) {
        return const AiResponse(
          success: false,
          data: {},
          errorCode: 'rate_limited',
        );
      }
    }
    return provider.generate(request);
  }
}

/// Talks to an OpenAI-compatible endpoint (OpenCode Zen / DeepSeek).
///
/// Safety: the API key is only ever placed in the Authorization header.
/// Upstream response bodies and the key are never copied into the returned
/// AiResponse, error codes, or logs. Any failure collapses to
/// `errorCode: 'ai_unavailable'`.
class RemoteAiProvider implements AiProvider {
  RemoteAiProvider({
    required this.client,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.timeout = const Duration(seconds: 30),
  });

  final http.Client client;
  final String apiKey;
  final String baseUrl;
  final String model;
  final Duration timeout;

  static const Map<String, String> _systemPrompts = {
    'chat':
        'You are a Chinese-learning assistant. Reply ONLY with strict JSON: '
        '{"answer": string, "cautions": string[], "relatedWords": string[]}. '
        'No markdown, no code fences.',
    'sentence_analysis':
        'Analyze the sentence. Reply ONLY with strict JSON: '
        '{"mainClause": string, "clauses": string[], "modifiers": string[], '
        '"translation": string, "vocabularyNotes": string[]}. '
        'No markdown, no code fences.',
    'cloze':
        'Create a cloze exercise for the target word. Reply ONLY with strict '
        'JSON: {"passage": string, "blanks": [{"index": number, "answer": '
        'string, "options": string[]}], "explanations": string[]}. '
        'No markdown, no code fences.',
    'writing_review':
        'You are an exam writing grader. Reply ONLY with strict JSON: '
        '{"totalScore": number, "rubricScores": {"content": number, '
        '"language": number, "structure": number, "vocabulary": number, '
        '"accuracy": number}, "mainIssues": string[], "paragraphSuggestions": '
        '[{"paragraph": number, "suggestion": string}], "highScoreExpressions": '
        'string[], "grammarIssues": [{"original": string, "corrected": string, '
        '"rule": string}], "rewrittenSample": string}. No markdown, no fences.',
  };

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final system = _systemPrompts[request.featureType];
    if (system == null) {
      return const AiResponse(
        success: false,
        data: {},
        errorCode: 'unknown_feature',
      );
    }
    final userContent = request.targetWord != null
        ? '${request.prompt}\n\nTarget word: ${request.targetWord}'
        : request.prompt;
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': userContent},
      ],
      'temperature': 0.3,
    });
    try {
      final res = await _postWithRetry(body);
      if (res.statusCode != 200) {
        return const AiResponse(
          success: false,
          data: {},
          errorCode: 'ai_unavailable',
        );
      }
      final outer = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = outer['choices'] as List;
      final content =
          (choices.first as Map)['message']['content'] as String;
      final data = jsonDecode(content) as Map<String, dynamic>;
      return AiResponse(success: true, data: data);
    } catch (_) {
      return const AiResponse(
        success: false,
        data: {},
        errorCode: 'ai_unavailable',
      );
    }
  }

  Future<http.Response> _postWithRetry(String body) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    var res = await client
        .post(uri, headers: headers, body: body)
        .timeout(timeout);
    if (res.statusCode >= 500) {
      res = await client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    }
    return res;
  }
}
