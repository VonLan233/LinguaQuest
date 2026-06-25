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
}
