class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.targetRoute,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final String? targetRoute;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      targetRoute: json['targetRoute'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
