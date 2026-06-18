const notificationTypes = {
  'learningReminder',
  'reviewDue',
  'checkInReminder',
  'activity',
};

List<Map<String, dynamic>> generatedNotificationsForToday({
  required String dateKey,
  required int dailyGoal,
  required bool hasStudyToday,
  required int dueReviewCount,
  required bool hasCheckedIn,
}) {
  final notifications = <Map<String, dynamic>>[];
  if (!hasStudyToday) {
    notifications.add({
      'type': 'learningReminder',
      'title': '今日学习计划待完成',
      'body': '今天目标新学 $dailyGoal 词，先从当前词书开始。',
      'targetRoute': '/study/new',
      'sourceKey': 'learningReminder:$dateKey',
      'params': {'dailyGoal': dailyGoal},
    });
  }
  if (dueReviewCount > 0) {
    notifications.add({
      'type': 'reviewDue',
      'title': '$dueReviewCount 个词到期复习',
      'body': '先清理复习队列，答错词会自动进入强化阶段。',
      'targetRoute': '/study/review',
      'sourceKey': 'reviewDue:$dateKey',
      'params': {'dueCount': dueReviewCount},
    });
  }
  if (!hasCheckedIn) {
    notifications.add({
      'type': 'checkInReminder',
      'title': '今天还没有打卡',
      'body': '完成一次学习或复习即可延续连续打卡。',
      'targetRoute': '/discover',
      'sourceKey': 'checkInReminder:$dateKey',
      'params': <String, dynamic>{},
    });
  }
  notifications.add({
    'type': 'activity',
    'title': '发现页积分任务已刷新',
    'body': '完成新学、复习和错词清理后可领取 XP。',
    'targetRoute': '/discover',
    'sourceKey': 'activity:$dateKey',
    'params': {'kind': 'activity'},
  });
  return notifications;
}

String notificationDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool isNotificationDateKey(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final parts = value.split('-').map(int.parse).toList();
  final parsed = DateTime.utc(parts[0], parts[1], parts[2]);
  return parsed.year == parts[0] &&
      parsed.month == parts[1] &&
      parsed.day == parts[2];
}

int? parseNotificationTimezoneOffsetMinutes(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final parsed = int.tryParse(value);
  if (parsed == null || parsed < -14 * 60 || parsed > 14 * 60) return null;
  return parsed;
}

class NotificationDayWindow {
  const NotificationDayWindow({
    required this.dateKey,
    required this.startUtc,
    required this.endUtc,
  });

  final String dateKey;
  final DateTime startUtc;
  final DateTime endUtc;
}

NotificationDayWindow notificationDayWindow({
  required DateTime nowUtc,
  String? localDate,
  int timezoneOffsetMinutes = 0,
}) {
  final localNow = nowUtc.toUtc().add(Duration(minutes: timezoneOffsetMinutes));
  final dateKey = localDate == null || localDate.isEmpty
      ? notificationDateKey(localNow)
      : localDate;
  final parts = dateKey.split('-').map(int.parse).toList();
  final localStartAsUtc = DateTime.utc(parts[0], parts[1], parts[2]);
  final startUtc = localStartAsUtc.subtract(
    Duration(minutes: timezoneOffsetMinutes),
  );
  return NotificationDayWindow(
    dateKey: dateKey,
    startUtc: startUtc,
    endUtc: startUtc.add(const Duration(days: 1)),
  );
}
