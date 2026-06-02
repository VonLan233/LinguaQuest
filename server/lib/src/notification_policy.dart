const notificationTypes = {
  'learningReminder',
  'reviewDue',
  'checkInReminder',
  'activity',
};

List<Map<String, dynamic>> generatedNotificationsForToday({
  required DateTime now,
  required int dailyGoal,
  required bool hasStudyToday,
  required int dueReviewCount,
  required bool hasCheckedIn,
}) {
  final dateKey = notificationDateKey(now.toUtc());
  final notifications = <Map<String, dynamic>>[];
  if (!hasStudyToday) {
    notifications.add({
      'type': 'learningReminder',
      'title': '今日学习计划待完成',
      'body': '今天目标新学 $dailyGoal 词，先从当前词书开始。',
      'targetRoute': '/study/new',
      'sourceKey': 'learningReminder:$dateKey',
    });
  }
  if (dueReviewCount > 0) {
    notifications.add({
      'type': 'reviewDue',
      'title': '$dueReviewCount 个词到期复习',
      'body': '先清理复习队列，答错词会自动进入强化阶段。',
      'targetRoute': '/study/review',
      'sourceKey': 'reviewDue:$dateKey',
    });
  }
  if (!hasCheckedIn) {
    notifications.add({
      'type': 'checkInReminder',
      'title': '今天还没有打卡',
      'body': '完成一次学习或复习即可延续连续打卡。',
      'targetRoute': '/home',
      'sourceKey': 'checkInReminder:$dateKey',
    });
  }
  notifications.add({
    'type': 'activity',
    'title': '发现页积分任务已刷新',
    'body': '完成新学、复习和错词清理后可领取 XP。',
    'targetRoute': '/discover',
    'sourceKey': 'activity:$dateKey',
  });
  return notifications;
}

String notificationDateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
