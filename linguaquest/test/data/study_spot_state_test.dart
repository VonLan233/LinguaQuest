import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/study_spot.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saveStudySpot then loadStudySpots updates state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    await controller.saveStudySpot(StudySpot(
        id: '',
        name: 'Home',
        latitude: 3.1,
        longitude: 101.6,
        studyMinutes: 20,
        createdAt: DateTime.utc(2026, 6, 19)));

    final spots = container.read(appControllerProvider).studySpots;
    expect(spots.length, 1);
    expect(spots.first.name, 'Home');
  });
}
