enum AppNotificationType {
  learningReminder,
  reviewDue,
  checkInReminder,
  activity,
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.uid,
    required this.type,
    required this.title,
    required this.body,
    required this.targetRoute,
    required this.isRead,
    required this.createdAt,
    this.readAt,
    this.sourceKey,
  });

  final String id;
  final String uid;
  final AppNotificationType type;
  final String title;
  final String body;
  final String targetRoute;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;
  final String? sourceKey;

  bool get isLearningType =>
      type == AppNotificationType.learningReminder ||
      type == AppNotificationType.reviewDue ||
      type == AppNotificationType.checkInReminder;

  AppNotification markRead({DateTime? now}) {
    if (isRead) return this;
    return copyWith(isRead: true, readAt: (now ?? DateTime.now()).toUtc());
  }

  AppNotification copyWith({
    String? id,
    String? uid,
    AppNotificationType? type,
    String? title,
    String? body,
    String? targetRoute,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
    bool clearReadAt = false,
    String? sourceKey,
    bool clearSourceKey = false,
  }) {
    return AppNotification(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      targetRoute: targetRoute ?? this.targetRoute,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: clearReadAt ? null : readAt ?? this.readAt,
      sourceKey: clearSourceKey ? null : sourceKey ?? this.sourceKey,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'type': type.name,
      'title': title,
      'body': body,
      'targetRoute': targetRoute,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
      'sourceKey': sourceKey,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] as String,
      uid: json['uid'] as String,
      type: appNotificationTypeFromName(json['type']?.toString()),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      targetRoute: json['targetRoute'] as String? ?? '/home',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: _date(json['createdAt']) ?? DateTime.now().toUtc(),
      readAt: _date(json['readAt']),
      sourceKey: json['sourceKey'] as String?,
    );
  }
}

AppNotificationType appNotificationTypeFromName(String? value) {
  for (final type in AppNotificationType.values) {
    if (type.name == value) return type;
  }
  return AppNotificationType.activity;
}

String appNotificationTypeLabel(AppNotificationType type, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (type) {
      case AppNotificationType.learningReminder:
        return l10n.notificationTypeLearningReminder;
      case AppNotificationType.reviewDue:
        return l10n.notificationTypeReviewDue;
      case AppNotificationType.checkInReminder:
        return l10n.notificationTypeCheckIn;
      case AppNotificationType.activity:
        return l10n.notificationTypeActivity;
    }
  }
  switch (type) {
    case AppNotificationType.learningReminder:
      return '学习提醒';
    case AppNotificationType.reviewDue:
      return '复习到期';
    case AppNotificationType.checkInReminder:
      return '打卡提醒';
    case AppNotificationType.activity:
      return '活动消息';
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value.toString())?.toUtc();
}
