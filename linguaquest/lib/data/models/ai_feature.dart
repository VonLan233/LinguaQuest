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
