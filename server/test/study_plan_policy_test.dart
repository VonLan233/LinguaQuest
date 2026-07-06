import 'package:linguaquest_server/src/study_plan_policy.dart';
import 'package:test/test.dart';

void main() {
  test('accepts a complete study plan payload', () {
    final result = validateStudyPlanPayload({
      'wordBookId': 'hsk1',
      'dailyNewTarget': 20,
      'dailyReviewLimit': 40,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '7:05',
      'status': 'active',
    });

    expect(result.isValid, isTrue);
    expect(result.data!['wordBookId'], 'hsk1');
    expect(result.data!['reminderTime'], '07:05');
  });

  test('accepts every HSK wordbook id', () {
    for (final id in ['hsk1', 'hsk2', 'hsk3', 'hsk4', 'hsk5', 'hsk6']) {
      final result = validateStudyPlanPayload({
        'wordBookId': id,
        'dailyNewTarget': 10,
        'dailyReviewLimit': 20,
        'startDate': '2026-06-04',
        'targetFinishDate': '2026-08-04',
        'reminderTime': '08:00',
      });
      expect(result.isValid, isTrue, reason: '$id should be accepted');
      expect(result.data!['wordBookId'], id);
    }
  });

  test('accepts every JLPT wordbook id', () {
    for (final id in ['jlpt_n5', 'jlpt_n4', 'jlpt_n3', 'jlpt_n2', 'jlpt_n1']) {
      final result = validateStudyPlanPayload({
        'wordBookId': id,
        'dailyNewTarget': 10,
        'dailyReviewLimit': 20,
        'startDate': '2026-06-04',
        'targetFinishDate': '2026-08-04',
        'reminderTime': '08:00',
      });
      expect(result.isValid, isTrue, reason: '$id should be accepted');
      expect(result.data!['wordBookId'], id,
          reason: '$id should not be normalized to anything else');
    }
  });

  test('still rejects unknown wordbook ids after JLPT addition', () {
    for (final bad in ['jlpt_n6', 'jlpt_n0', 'jlpt', 'n5', 'totally-unknown']) {
      final result = validateStudyPlanPayload({
        'wordBookId': bad,
        'dailyNewTarget': 10,
        'dailyReviewLimit': 20,
        'startDate': '2026-06-04',
        'targetFinishDate': '2026-08-04',
        'reminderTime': '08:00',
      });
      expect(result.error, 'invalid wordBookId',
          reason: '$bad must be rejected');
    }
  });

  test('maps legacy English wordbook ids to hsk1 for backward compatibility', () {
    for (final legacy in ['beginner', 'ielts', 'toefl', 'gre', 'cet4', 'cet6',
        'kaoyan', 'daily-english', 'exam-core']) {
      final result = validateStudyPlanPayload({
        'wordBookId': legacy,
        'dailyNewTarget': 10,
        'dailyReviewLimit': 20,
        'startDate': '2026-06-04',
        'targetFinishDate': '2026-08-04',
        'reminderTime': '08:00',
      });
      expect(result.isValid, isTrue, reason: '$legacy should map to hsk1');
      expect(result.data!['wordBookId'], 'hsk1');
    }
  });

  test('rejects an unknown wordBookId', () {
    final invalidBook = validateStudyPlanPayload({
      'wordBookId': 'totally-unknown',
      'dailyNewTarget': 20,
      'dailyReviewLimit': 40,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '20:00',
    });
    expect(invalidBook.error, 'invalid wordBookId');
  });

  test('rejects invalid ranges', () {
    final invalidRange = validateStudyPlanPayload({
      'wordBookId': 'hsk1',
      'dailyNewTarget': 0,
      'dailyReviewLimit': 40,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '20:00',
    });
    expect(invalidRange.error, 'dailyNewTarget must be between 1 and 200');
  });

  test('rejects impossible dates and reminder times', () {
    final invalidDate = validateStudyPlanPayload({
      'wordBookId': 'hsk1',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-08-04',
      'targetFinishDate': '2026-06-04',
      'reminderTime': '20:00',
    });
    expect(invalidDate.error, 'targetFinishDate must be on or after startDate');

    final invalidTime = validateStudyPlanPayload({
      'wordBookId': 'hsk1',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '25:00',
    });
    expect(invalidTime.error, 'reminderTime must be HH:mm');
  });

  test('coerces string-like fields without throwing type errors', () {
    final result = validateStudyPlanPayload({
      'wordBookId': const _StringLike('hsk2'),
      'dailyNewTarget': '20',
      'dailyReviewLimit': '40',
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '7:05',
      'status': const _StringLike('paused'),
    });

    expect(result.isValid, isTrue);
    expect(result.data!['wordBookId'], 'hsk2');
    expect(result.data!['status'], 'paused');
  });

  test('preserves caller-provided reset timestamp', () {
    final resetAt = DateTime.utc(2026, 6, 4, 9, 30);
    final result = validateStudyPlanPayload({
      'wordBookId': 'hsk1',
      'dailyNewTarget': 20,
      'dailyReviewLimit': 40,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '7:05',
    }, now: resetAt);

    expect(result.isValid, isTrue);
    expect(result.data!['now'], resetAt);
  });
}

class _StringLike {
  const _StringLike(this.value);

  final String value;

  @override
  String toString() => value;
}
