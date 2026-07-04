import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/study_spot.dart';

void main() {
  test('StudySpot round-trips through json', () {
    final spot = StudySpot(
      id: 's1',
      name: 'Library',
      latitude: 3.139,
      longitude: 101.6869,
      studyMinutes: 25,
      createdAt: DateTime.utc(2026, 6, 19, 10, 30),
    );
    final json = spot.toJson();
    final back = StudySpot.fromJson(json);
    expect(back.id, 's1');
    expect(back.name, 'Library');
    expect(back.latitude, closeTo(3.139, 1e-9));
    expect(back.longitude, closeTo(101.6869, 1e-9));
    expect(back.studyMinutes, 25);
    expect(back.createdAt, DateTime.utc(2026, 6, 19, 10, 30));
  });

  test('fromJson tolerates int/num lat-lng and string id', () {
    final back = StudySpot.fromJson({
      'id': 42,
      'name': 'Park',
      'latitude': 3,
      'longitude': 101,
      'studyMinutes': 10,
      'createdAt': '2026-06-19T10:30:00.000Z',
    });
    expect(back.id, '42');
    expect(back.latitude, 3.0);
    expect(back.longitude, 101.0);
  });
}
