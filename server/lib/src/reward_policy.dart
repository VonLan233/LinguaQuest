import 'notification_policy.dart';

class RewardValidation {
  const RewardValidation({
    required this.points,
    required this.canonicalSourceId,
  });

  final int points;
  final String canonicalSourceId;
}

RewardValidation? validatedRewardPoints({
  required String sourceType,
  required String sourceId,
  required int requestedPoints,
  DateTime? nowUtc,
}) {
  if (requestedPoints <= 0 || sourceId.isEmpty) return null;
  final rewardDay = (nowUtc ?? DateTime.now().toUtc()).toUtc();
  switch (sourceType) {
    case 'study_lesson':
      if (sourceId.contains(':')) return null;
      return requestedPoints <= 30
          ? RewardValidation(
              points: requestedPoints,
              canonicalSourceId: sourceId,
            )
          : null;
    case 'training_session':
      final parts = _dailySourceIdParts(sourceId, rewardDay);
      if (parts == null) return null;
      return requestedPoints <= 30
          ? RewardValidation(
              points: requestedPoints,
              canonicalSourceId: _canonicalDailySourceId(
                parts.first,
                rewardDay,
              ),
            )
          : null;
    case 'review_word':
      final parts = _dailySourceIdParts(sourceId, rewardDay);
      if (parts == null) return null;
      return requestedPoints == 3
          ? RewardValidation(
              points: requestedPoints,
              canonicalSourceId: _canonicalDailySourceId(
                parts.first,
                rewardDay,
              ),
            )
          : null;
    case 'reward_task':
      final parts = _dailySourceIdParts(sourceId, rewardDay);
      if (parts == null) return null;
      final taskId = parts.first;
      final points = switch (taskId) {
        'daily-checkin' => requestedPoints == 5 ? requestedPoints : null,
        'new-learning' => requestedPoints == 20 ? requestedPoints : null,
        'review-done' => requestedPoints == 15 ? requestedPoints : null,
        'training-challenge' => requestedPoints == 20 ? requestedPoints : null,
        'weak-cleanup' => requestedPoints == 10 ? requestedPoints : null,
        _ => null,
      };
      return points == null
          ? null
          : RewardValidation(
              points: points,
              canonicalSourceId: _canonicalDailySourceId(taskId, rewardDay),
            );
    default:
      return null;
  }
}

List<String>? _dailySourceIdParts(String sourceId, DateTime nowUtc) {
  final parts = sourceId.split(':');
  if (parts.length != 2) return null;
  final id = parts.first.trim();
  final dateKey = parts.last.trim();
  if (id.isEmpty || dateKey.isEmpty) return null;
  if (!isNotificationDateKey(dateKey)) return null;
  if (!_isDateKeyInRewardWindow(dateKey, nowUtc)) return null;
  return [id, dateKey];
}

bool _isDateKeyInRewardWindow(String dateKey, DateTime nowUtc) {
  final rewardDay = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day);
  final parts = dateKey.split('-').map(int.parse).toList();
  final requestedDay = DateTime.utc(parts[0], parts[1], parts[2]);
  final difference = requestedDay.difference(rewardDay).inDays;
  return difference >= -1 && difference <= 1;
}

String _canonicalDailySourceId(String id, DateTime nowUtc) {
  return '$id:${notificationDateKey(nowUtc.toUtc())}';
}
