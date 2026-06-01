class AiConversation {
  const AiConversation({
    required this.id,
    required this.feature,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String feature;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory AiConversation.fromJson(Map<String, dynamic> json) {
    return AiConversation(
      id: json['id'] as String? ?? '',
      feature: json['feature'] as String? ?? 'qa',
      title: json['title'] as String? ?? 'AI 对话',
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class AiMessage {
  const AiMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String role;
  final String content;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  bool get isUser => role == 'user';

  factory AiMessage.fromJson(Map<String, dynamic> json) {
    return AiMessage(
      id: json['id'] as String? ?? '',
      conversationId: json['conversationId'] as String? ?? '',
      role: json['role'] as String? ?? 'assistant',
      content: json['content'] as String? ?? '',
      payload: Map<String, dynamic>.from(json['payload'] as Map? ?? const {}),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }
}

class AiConversationDetail {
  const AiConversationDetail({
    required this.conversation,
    required this.messages,
  });

  final AiConversation conversation;
  final List<AiMessage> messages;

  factory AiConversationDetail.fromJson(Map<String, dynamic> json) {
    return AiConversationDetail(
      conversation: AiConversation.fromJson(
        json['conversation'] as Map<String, dynamic>,
      ),
      messages: (json['messages'] as List<dynamic>? ?? const [])
          .map((item) => AiMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
