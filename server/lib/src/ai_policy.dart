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
