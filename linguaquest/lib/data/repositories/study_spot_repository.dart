import '../models/study_spot.dart';

abstract class StudySpotRepository {
  Future<List<StudySpot>> list();
  Future<StudySpot> add(StudySpot spot);
  Future<StudySpot> recordVisit({
    required double latitude,
    required double longitude,
    required String name,
  });
  Future<void> remove(String id);
}
