Duration reviewIntervalForLevel(int masteryLevel) {
  switch (masteryLevel.clamp(0, 5)) {
    case 0:
      return Duration.zero;
    case 1:
      return const Duration(days: 1);
    case 2:
      return const Duration(days: 3);
    case 3:
      return const Duration(days: 7);
    case 4:
      return const Duration(days: 14);
    default:
      return const Duration(days: 30);
  }
}

DateTime nextReviewDateForLevel(int masteryLevel, DateTime now) {
  final interval = reviewIntervalForLevel(masteryLevel);
  if (interval == Duration.zero) {
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }
  return now.add(interval);
}
