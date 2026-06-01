class ActivitySummary {
  const ActivitySummary({
    required this.completedLessonIds,
    required this.todayCompletedLessonIds,
    required this.todayReviewWordIds,
  });

  final Set<String> completedLessonIds;
  final Set<String> todayCompletedLessonIds;
  final Set<String> todayReviewWordIds;

  factory ActivitySummary.fromJson(Map<String, dynamic> json) {
    return ActivitySummary(
      completedLessonIds: _stringSet(json['completedLessonIds']),
      todayCompletedLessonIds: _stringSet(json['todayCompletedLessonIds']),
      todayReviewWordIds: _stringSet(json['todayReviewWordIds']),
    );
  }

  static const empty = ActivitySummary(
    completedLessonIds: {},
    todayCompletedLessonIds: {},
    todayReviewWordIds: {},
  );
}

Set<String> _stringSet(Object? value) {
  if (value is List) return value.map((item) => item.toString()).toSet();
  return <String>{};
}
