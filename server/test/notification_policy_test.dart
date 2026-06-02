import 'package:linguaquest_server/src/notification_policy.dart';
import 'package:test/test.dart';

void main() {
  test(
    'generated notifications cover learning, review, check-in and activity',
    () {
      final notifications = generatedNotificationsForToday(
        dateKey: '2026-06-02',
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
        dateKey: '2026-06-02',
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

  test('check-in reminder target matches API contract', () {
    final notifications = generatedNotificationsForToday(
      dateKey: '2026-06-02',
      dailyGoal: 12,
      hasStudyToday: true,
      dueReviewCount: 0,
      hasCheckedIn: false,
    );

    final checkIn = notifications.singleWhere(
      (notification) => notification['type'] == 'checkInReminder',
    );
    expect(checkIn['targetRoute'], '/discover');
  });

  test('notification day window uses client local day and offset', () {
    final window = notificationDayWindow(
      nowUtc: DateTime.utc(2026, 6, 2, 21),
      localDate: '2026-06-03',
      timezoneOffsetMinutes: 8 * 60,
    );

    expect(window.dateKey, '2026-06-03');
    expect(window.startUtc, DateTime.utc(2026, 6, 2, 16));
    expect(window.endUtc, DateTime.utc(2026, 6, 3, 16));
  });

  test('notification query date and offset validation', () {
    expect(isNotificationDateKey('2026-06-02'), isTrue);
    expect(isNotificationDateKey('2026-02-30'), isFalse);
    expect(parseNotificationTimezoneOffsetMinutes('480'), 480);
    expect(parseNotificationTimezoneOffsetMinutes(null), isNull);
    expect(parseNotificationTimezoneOffsetMinutes(''), isNull);
    expect(parseNotificationTimezoneOffsetMinutes('invalid'), isNull);
    expect(parseNotificationTimezoneOffsetMinutes('900'), isNull);
  });
}
