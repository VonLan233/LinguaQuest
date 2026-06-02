import 'package:linguaquest_server/src/notification_policy.dart';
import 'package:test/test.dart';

void main() {
  test(
    'generated notifications cover learning, review, check-in and activity',
    () {
      final notifications = generatedNotificationsForToday(
        now: DateTime.utc(2026, 6, 2, 9),
        dailyGoal: 12,
        hasStudyToday: false,
        dueReviewCount: 3,
        hasCheckedIn: false,
      );

      expect(
        notifications.map((notification) => notification['type']),
        containsAll([
          'learningReminder',
          'reviewDue',
          'checkInReminder',
          'activity',
        ]),
      );
      expect(
        notifications.map((notification) => notification['sourceKey']),
        containsAll([
          'learningReminder:2026-06-02',
          'reviewDue:2026-06-02',
          'checkInReminder:2026-06-02',
          'activity:2026-06-02',
        ]),
      );
    },
  );

  test(
    'generated notifications skip completed learning and empty review queue',
    () {
      final notifications = generatedNotificationsForToday(
        now: DateTime.utc(2026, 6, 2, 9),
        dailyGoal: 12,
        hasStudyToday: true,
        dueReviewCount: 0,
        hasCheckedIn: true,
      );

      expect(notifications, hasLength(1));
      expect(notifications.single['type'], 'activity');
      expect(notifications.single['targetRoute'], '/discover');
    },
  );

  test('notification type allow-list matches API contract', () {
    expect(notificationTypes, contains('learningReminder'));
    expect(notificationTypes, contains('reviewDue'));
    expect(notificationTypes, contains('checkInReminder'));
    expect(notificationTypes, contains('activity'));
    expect(notificationTypes, isNot(contains('remotePush')));
  });
}
