import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('recordVisit within 100m accumulates onto the same spot', () async {
    final repo = MockStudySpotRepository();
    await repo.recordVisit(latitude: 3.1390, longitude: 101.6869, name: 'A');
    final second = await repo.recordVisit(
        latitude: 3.13905, longitude: 101.68695, name: 'A');
    final spots = await repo.list();
    expect(spots.length, 1);
    expect(spots.first.visitCount, 2);
    expect(second.visitCount, 2);
  });

  test('recordVisit beyond 100m creates a new spot', () async {
    final repo = MockStudySpotRepository();
    await repo.recordVisit(latitude: 3.1390, longitude: 101.6869, name: 'A');
    await repo.recordVisit(latitude: 3.2000, longitude: 101.7000, name: 'B');
    final spots = await repo.list();
    expect(spots.length, 2);
    expect(spots.every((s) => s.visitCount == 1), isTrue);
  });
}
