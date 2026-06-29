import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/profile/study_plan_settings_screen.dart';

void main() {
  final today = DateTime(2026, 6, 29);

  test('auto finish date = today + ceil(total/daily)', () {
    final d = studyPlanAutoFinishDate(
      totalWords: 100,
      dailyNewTarget: 10,
      today: today,
    );
    expect(d.difference(today).inDays, 10);
  });

  test('ceil rounds up partial days', () {
    final d = studyPlanAutoFinishDate(
      totalWords: 95,
      dailyNewTarget: 10,
      today: today,
    );
    expect(d.difference(today).inDays, 10); // ceil(9.5)=10
  });

  test('fallback to 30 days when total or daily is non-positive', () {
    expect(
      studyPlanAutoFinishDate(totalWords: 0, dailyNewTarget: 10, today: today)
          .difference(today)
          .inDays,
      30,
    );
    expect(
      studyPlanAutoFinishDate(totalWords: 100, dailyNewTarget: 0, today: today)
          .difference(today)
          .inDays,
      30,
    );
  });

  test('result is date-only (midnight)', () {
    final d = studyPlanAutoFinishDate(
      totalWords: 100,
      dailyNewTarget: 10,
      today: DateTime(2026, 6, 29, 13, 45),
    );
    expect(d.hour, 0);
    expect(d.minute, 0);
  });
}
