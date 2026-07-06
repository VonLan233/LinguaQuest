import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Builds the writing-review prompt sent to the grader, prepending exam
/// context when provided. Returns the essay unchanged when no context exists.
String buildWritingReviewPrompt(
  String essay, {
  String? examType,
  Object? targetScore,
}) {
  final lines = <String>[];
  if (examType != null && examType.isNotEmpty) {
    lines.add('Exam type: $examType');
  }
  if (targetScore != null) {
    lines.add('Target score: $targetScore');
  }
  if (lines.isEmpty) return essay;
  return '${lines.join('\n')}\n\nEssay:\n$essay';
}

class AiRequest {
  const AiRequest({
    required this.featureType,
    required this.userId,
    required this.prompt,
    this.targetWord,
    this.targetLanguage = 'zh',
    this.modelOverride,
  });

  final String featureType;
  final String userId;
  final String prompt;
  final String? targetWord;
  final String targetLanguage;

  /// When non-null, overrides the provider's default model for this request.
  final String? modelOverride;
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
      case 'reading_explain':
        return const AiResponse(
          success: true,
          data: {
            'gist': 'Mock gist of the paragraph.',
            'keyWords': [
              {
                'word': '示例',
                'reading': 'shìlì',
                'meaning': 'example',
              },
            ],
            'grammarPoints': ['Mock grammar point'],
            'structure': 'Mock sentence structure analysis.',
            'translation': 'Mock English translation of the paragraph.',
            'practice': [
              {
                'prompt': 'Mock practice question?',
                'answer': '示例',
                'options': ['示例', '其它', '别的', '另一个'],
              },
            ],
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
      case 'confusion':
        final word = request.targetWord ?? 'word';
        return AiResponse(
          success: true,
          data: {
            'pairs': [
              {
                'word': word,
                'confusedWith': 'similar',
                'distinction': 'Mock distinction for $word.',
                'examples': <String>[],
              },
            ],
          },
        );
      case 'sentence_gen':
        final word = request.targetWord ?? 'word';
        return AiResponse(
          success: true,
          data: {
            'sentences': [
              {'sentence': 'Mock sentence with $word.', 'translation': 'Mock translation.'},
            ],
            'rewrites': [
              {'original': word, 'rewritten': 'Mock rewrite.', 'note': 'Mock note.'},
            ],
          },
        );
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

const _languageNames = <String, String>{
  'zh': 'Chinese',
  'ms': 'Malay',
  'es': 'Spanish',
  'fr': 'French',
  'ja': 'Japanese',
};

/// Resolves a target-language code (e.g. 'zh') to its English name. Unknown or
/// empty codes fall back to Chinese (the only language shipping today).
String languageNameFor(String code) => _languageNames[code] ?? 'Chinese';

/// Builds the LLM system prompt for [featureType] in [language] (an English
/// language name). Explanatory fields are English; taught content stays in
/// [language]. Returns null for an unknown feature.
String? buildSystemPrompt(String featureType, String language) {
  switch (featureType) {
    case 'chat':
      return 'You are a $language-learning assistant for English speakers. '
          'Write "answer" and "cautions" in English. Keep "relatedWords" as '
          '$language words. Reply ONLY with strict JSON: '
          '{"answer": string, "cautions": string[], "relatedWords": string[]}. '
          'No markdown, no code fences.';
    case 'sentence_analysis':
      return 'Analyze the $language sentence. Keep "mainClause", "clauses", '
          'and "modifiers" in the original $language; write "translation" and '
          '"vocabularyNotes" in English. Reply ONLY with strict JSON: '
          '{"mainClause": string, "clauses": string[], "modifiers": string[], '
          '"translation": string, "vocabularyNotes": string[]}. '
          'No markdown, no code fences.';
    case 'cloze':
      return 'Create a short $language cloze exercise. Write a SHORT $language '
          'passage of only 2-3 sentences containing EXACTLY 3 to 4 blanks. '
          'Keep the "passage" and each blank\'s "answer" and "options" in '
          '$language; write "explanations" in English. Be concise. Reply ONLY '
          'with strict JSON: {"passage": string, "blanks": [{"index": number, '
          '"answer": string, "options": string[]}], "explanations": string[]}. '
          'No markdown, no code fences.';
    case 'reading_explain':
      return 'Explain the $language paragraph for an English speaker learning '
          '$language. Keep "keyWords" entries\' "word" and "reading" in '
          '$language; write every other field ("gist", each key word\'s '
          '"meaning", "grammarPoints", "structure", "translation") in English. '
          'For "practice", each item\'s "prompt" and "options" stay in '
          '$language and "answer" must be one of its "options". Reply ONLY with '
          'strict JSON: {"gist": string, "keyWords": [{"word": string, '
          '"reading": string, "meaning": string}], "grammarPoints": string[], '
          '"structure": string, "translation": string, "practice": '
          '[{"prompt": string, "answer": string, "options": string[]}]}. '
          'No markdown, no code fences.';
    case 'writing_review':
      return 'You are a $language writing grader for English speakers. Write '
          'all feedback ("mainIssues", "paragraphSuggestions", '
          '"highScoreExpressions", and each grammar issue\'s "rule") in '
          'English; keep "rewrittenSample" and any quoted student text in the '
          'language of the original essay. Reply ONLY with strict JSON: '
          '{"totalScore": number, "rubricScores": {"content": number, '
          '"language": number, "structure": number, "vocabulary": number, '
          '"accuracy": number}, "mainIssues": string[], "paragraphSuggestions": '
          '[{"paragraph": number, "suggestion": string}], '
          '"highScoreExpressions": string[], "grammarIssues": [{"original": '
          'string, "corrected": string, "rule": string}], "rewrittenSample": '
          'string}. No markdown, no fences.';
    case 'confusion':
      return 'Identify words commonly confused with the target word in '
          '$language. Keep each pair\'s "word", "confusedWith", and "examples" '
          'in $language; write "distinction" in English. Reply ONLY with strict '
          'JSON: {"pairs": [{"word": string, "confusedWith": string, '
          '"distinction": string, "examples": string[]}]}. '
          'No markdown, no code fences.';
    case 'sentence_gen':
      return 'For the target word or sentence, write natural example sentences '
          'and improved rewrites in $language. Keep "sentence" and "rewritten" '
          'in $language; write "translation" and "note" in English. Reply ONLY '
          'with strict JSON: {"sentences": [{"sentence": string, "translation": '
          'string}], "rewrites": [{"original": string, "rewritten": string, '
          '"note": string}]}. No markdown, no code fences.';
  }
  return null;
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
    this.timeout = const Duration(seconds: 50),
  });

  final http.Client client;
  final String apiKey;
  final String baseUrl;
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
    final userContent = request.targetWord != null
        ? '${request.prompt}\n\nTarget word: ${request.targetWord}'
        : request.prompt;
    final body = jsonEncode({
      'model': request.modelOverride ?? model,
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
    try {
      final res = await client.post(uri, headers: headers, body: body).timeout(timeout);
      if (res.statusCode >= 500) {
        return client.post(uri, headers: headers, body: body).timeout(timeout);
      }
      return res;
    } on TimeoutException {
      return client.post(uri, headers: headers, body: body).timeout(timeout);
    }
  }
}
