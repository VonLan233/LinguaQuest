import 'notification_policy.dart';

int? validatedRewardPoints({
  required String sourceType,
  required String sourceId,
  required int requestedPoints,
}) {
  if (requestedPoints <= 0 || sourceId.isEmpty) return null;
  switch (sourceType) {
    case 'study_lesson':
      if (sourceId.contains(':')) return null;
      return requestedPoints <= 30 ? requestedPoints : null;
    case 'training_session':
      if (!_hasDailySourceId(sourceId)) return null;
      return requestedPoints <= 30 ? requestedPoints : null;
    case 'review_word':
      if (!_hasDailySourceId(sourceId)) return null;
      return requestedPoints == 3 ? requestedPoints : null;
    case 'reward_task':
      final parts = _dailySourceIdParts(sourceId);
      if (parts == null) return null;
      final taskId = parts.first;
      return switch (taskId) {
        'daily-checkin' => requestedPoints == 5 ? requestedPoints : null,
        'new-learning' => requestedPoints == 20 ? requestedPoints : null,
        'review-done' => requestedPoints == 15 ? requestedPoints : null,
        'training-challenge' => requestedPoints == 20 ? requestedPoints : null,
        'weak-cleanup' => requestedPoints == 10 ? requestedPoints : null,
        _ => null,
      };
    default:
      return null;
  }
}

bool _hasDailySourceId(String sourceId) =>
    _dailySourceIdParts(sourceId) != null;

List<String>? _dailySourceIdParts(String sourceId) {
  final parts = sourceId.split(':');
  if (parts.length != 2) return null;
  final id = parts.first.trim();
  final dateKey = parts.last.trim();
  if (id.isEmpty || dateKey.isEmpty) return null;
  if (!isNotificationDateKey(dateKey)) return null;
  return [id, dateKey];
}
