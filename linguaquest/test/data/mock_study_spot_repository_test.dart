import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/data/models/study_spot.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add then list persists across repository instances', () async {
    final repo = MockStudySpotRepository();
    final added = await repo.add(StudySpot(
      id: '',
      name: 'Cafe',
      latitude: 3.1,
      longitude: 101.6,
      studyMinutes: 15,
      createdAt: DateTime.utc(2026, 6, 19),
    ));
    expect(added.id, isNotEmpty);

    final fresh = MockStudySpotRepository();
    final spots = await fresh.list();
    expect(spots.length, 1);
    expect(spots.first.name, 'Cafe');
  });

  test('remove deletes the spot', () async {
    final repo = MockStudySpotRepository();
    final a = await repo.add(StudySpot(
      id: '', name: 'A', latitude: 1, longitude: 2, studyMinutes: 5,
      createdAt: DateTime.utc(2026, 6, 19)));
    await repo.add(StudySpot(
      id: '', name: 'B', latitude: 3, longitude: 4, studyMinutes: 5,
      createdAt: DateTime.utc(2026, 6, 19)));
    await repo.remove(a.id);
    final spots = await repo.list();
    expect(spots.map((s) => s.name), ['B']);
  });
}
