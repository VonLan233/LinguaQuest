import 'package:linguaquest_server/src/study_plan_policy.dart';
import 'package:test/test.dart';

void main() {
  test('accepts a complete study plan payload', () {
    final result = validateStudyPlanPayload({
      'wordBookId': 'exam-core',
      'dailyNewTarget': 20,
      'dailyReviewLimit': 40,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '7:05',
      'status': 'active',
    });

    expect(result.isValid, isTrue);
    expect(result.data!['reminderTime'], '07:05');
  });

  test('rejects invalid targets and ranges', () {
    final invalidBook = validateStudyPlanPayload({
      'wordBookId': 'unknown',
      'dailyNewTarget': 20,
      'dailyReviewLimit': 40,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '20:00',
    });
    expect(invalidBook.error, 'invalid wordBookId');

    final invalidRange = validateStudyPlanPayload({
      'wordBookId': 'exam-core',
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
      'wordBookId': 'daily-english',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-08-04',
      'targetFinishDate': '2026-06-04',
      'reminderTime': '20:00',
    });
    expect(invalidDate.error, 'targetFinishDate must be on or after startDate');

    final invalidTime = validateStudyPlanPayload({
      'wordBookId': 'daily-english',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-06-04',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '25:00',
    });
    expect(invalidTime.error, 'reminderTime must be HH:mm');
  });
}
