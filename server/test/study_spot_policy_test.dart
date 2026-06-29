import 'package:test/test.dart';
import '../lib/src/study_spot_policy.dart';

void main() {
  test('valid spot returns null', () {
    expect(
      StudySpotPolicy.validate(name: 'Library', latitude: 3.1, longitude: 101.6),
      isNull,
    );
  });
  test('empty name rejected', () {
    expect(
      StudySpotPolicy.validate(name: '  ', latitude: 3.1, longitude: 101.6),
      equals('name_required'),
    );
  });
  test('latitude out of range rejected', () {
    expect(
      StudySpotPolicy.validate(name: 'X', latitude: 91, longitude: 0),
      equals('invalid_coordinates'),
    );
  });
  test('longitude out of range rejected', () {
    expect(
      StudySpotPolicy.validate(name: 'X', latitude: 0, longitude: 181),
      equals('invalid_coordinates'),
    );
  });
  test('distanceMeters: same point is ~0', () {
    expect(StudySpotPolicy.distanceMeters(3.139, 101.6869, 3.139, 101.6869),
        lessThan(1));
  });
  test('distanceMeters: ~100m apart is within tolerance', () {
    // 0.0009 deg latitude ≈ 100 m.
    final d = StudySpotPolicy.distanceMeters(3.1390, 101.6869, 3.1399, 101.6869);
    expect(d, inInclusiveRange(90, 110));
  });
  test('nearestWithin: returns index of a spot within 100m', () {
    final spots = [
      (latitude: 3.1390, longitude: 101.6869),
      (latitude: 3.2000, longitude: 101.7000),
    ];
    expect(StudySpotPolicy.nearestWithin(spots, 3.13905, 101.68695), 0);
  });
  test('nearestWithin: returns null when nothing within 100m', () {
    final spots = [(latitude: 3.2000, longitude: 101.7000)];
    expect(StudySpotPolicy.nearestWithin(spots, 3.1390, 101.6869), isNull);
  });
}
