import 'package:linguaquest_server/src/review_policy.dart';
import 'package:test/test.dart';

void main() {
  test('review intervals match the PRD guide', () {
    expect(reviewIntervalForLevel(0), Duration.zero);
    expect(reviewIntervalForLevel(1), const Duration(days: 1));
    expect(reviewIntervalForLevel(2), const Duration(days: 3));
    expect(reviewIntervalForLevel(3), const Duration(days: 7));
    expect(reviewIntervalForLevel(4), const Duration(days: 14));
    expect(reviewIntervalForLevel(5), const Duration(days: 30));
  });

  test('mastery moves up and down within bounds', () {
    expect(nextMasteryLevel(current: 0, isCorrect: false), 0);
    expect(nextMasteryLevel(current: 0, isCorrect: true), 1);
    expect(nextMasteryLevel(current: 5, isCorrect: true), 5);
    expect(nextMasteryLevel(current: 3, isCorrect: false), 2);
  });
}
