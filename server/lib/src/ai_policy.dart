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
  AiPolicyService({required this.provider, required this.dailyLimitPerUser});

  static const int _maxPromptLength = 2000;

  final AiProvider provider;
  final int dailyLimitPerUser;

  String? validateRequest(AiRequest request) {
    if (request.prompt.length > _maxPromptLength) return 'too_long';
    return null;
  }

  Future<AiResponse> handle(AiRequest request) async {
    final err = validateRequest(request);
    if (err != null) return AiResponse(success: false, data: {}, errorCode: err);
    return provider.generate(request);
  }
}
