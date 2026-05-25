import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/utils/spaced_repetition.dart';
import 'package:linguaquest/data/models/custom_word.dart';

void main() {
  test('review intervals follow the blueprint', () {
    expect(reviewIntervalForLevel(0), Duration.zero);
    expect(reviewIntervalForLevel(1), const Duration(days: 1));
    expect(reviewIntervalForLevel(2), const Duration(days: 3));
    expect(reviewIntervalForLevel(3), const Duration(days: 7));
    expect(reviewIntervalForLevel(4), const Duration(days: 14));
    expect(reviewIntervalForLevel(5), const Duration(days: 30));
  });

  test('custom word review updates mastery and counters', () {
    final now = DateTime(2026, 5, 25, 10);
    final word = CustomWord.create(
      id: '1',
      uid: 'u1',
      word: 'focus',
      meaning: '专注',
      exampleSentence: 'Focus on one lesson.',
      now: now,
    );

    final correct = word.reviewed(isCorrect: true, now: now);
    expect(correct.masteryLevel, 1);
    expect(correct.correctCount, 1);
    expect(correct.nextReviewAt, now.add(const Duration(days: 1)));

    final wrong = correct.reviewed(isCorrect: false, now: now);
    expect(wrong.masteryLevel, 0);
    expect(wrong.wrongCount, 1);
  });
}
