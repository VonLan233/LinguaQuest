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

int nextMasteryLevel({required int current, required bool isCorrect}) {
  return isCorrect ? (current + 1).clamp(0, 5) : (current - 1).clamp(0, 5);
}

DateTime nextReviewAt({required int masteryLevel, required DateTime now}) {
  final interval = reviewIntervalForLevel(masteryLevel);
  if (interval == Duration.zero) {
    return DateTime(now.year, now.month, now.day, 23, 59, 59);
  }
  return now.add(interval);
}
