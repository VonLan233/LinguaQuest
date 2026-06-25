class AiHistoryEntry {
  const AiHistoryEntry({
    required this.id,
    required this.featureType,
    required this.prompt,
    required this.response,
    required this.createdAt,
  });

  final String id;
  final String featureType;
  final String prompt;
  final Map<String, dynamic> response;
  final DateTime createdAt;

  factory AiHistoryEntry.fromJson(Map<String, dynamic> json) {
    return AiHistoryEntry(
      id: json['id'] as String,
      featureType: json['featureType'] as String,
      prompt: json['prompt'] as String,
      response: json['response'] as Map<String, dynamic>? ?? const {},
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'featureType': featureType,
      'prompt': prompt,
      'response': response,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class WritingReviewResult {
  const WritingReviewResult({
    required this.totalScore,
    required this.rubricScores,
    required this.mainIssues,
    required this.paragraphSuggestions,
    required this.highScoreExpressions,
    required this.grammarIssues,
    required this.rewrittenSample,
  });

  final int totalScore;
  final Map<String, int> rubricScores;
  final List<String> mainIssues;
  final List<Map<String, String>> paragraphSuggestions;
  final List<String> highScoreExpressions;
  final List<Map<String, String>> grammarIssues;
  final String rewrittenSample;

  factory WritingReviewResult.fromJson(Map<String, dynamic> json) {
    Map<String, int> parseRubric(dynamic raw) {
      if (raw is Map) {
        return raw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0));
      }
      return const {};
    }

    List<String> parseStringList(dynamic raw) {
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return const [];
    }

    List<Map<String, String>> parseMapList(dynamic raw) {
      if (raw is List) {
        return raw.whereType<Map>().map((e) {
          return e.map((k, v) => MapEntry(k.toString(), v.toString()));
        }).toList();
      }
      return const [];
    }

    return WritingReviewResult(
      totalScore: (json['totalScore'] as num?)?.toInt() ?? 0,
      rubricScores: parseRubric(json['rubricScores']),
      mainIssues: parseStringList(json['mainIssues']),
      paragraphSuggestions: parseMapList(json['paragraphSuggestions']),
      highScoreExpressions: parseStringList(json['highScoreExpressions']),
      grammarIssues: parseMapList(json['grammarIssues']),
      rewrittenSample: json['rewrittenSample'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalScore': totalScore,
      'rubricScores': rubricScores,
      'mainIssues': mainIssues,
      'paragraphSuggestions': paragraphSuggestions,
      'highScoreExpressions': highScoreExpressions,
      'grammarIssues': grammarIssues,
      'rewrittenSample': rewrittenSample,
    };
  }

  static WritingReviewResult empty() => const WritingReviewResult(
    totalScore: 0,
    rubricScores: {},
    mainIssues: [],
    paragraphSuggestions: [],
    highScoreExpressions: [],
    grammarIssues: [],
    rewrittenSample: '',
  );
}
