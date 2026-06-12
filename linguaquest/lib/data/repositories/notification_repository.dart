import '../models/app_notification.dart';

abstract class NotificationRepository {
  Future<void> ensureGenerated(String uid, List<AppNotification> notifications);

  Future<List<AppNotification>> list(
    String uid, {
    bool unreadOnly = false,
    AppNotificationType? type,
  });

  Future<AppNotification?> markRead(String uid, String id);

  Future<int> markAllRead(String uid);
}
