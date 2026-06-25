import '../models/study_spot.dart';

abstract class StudySpotRepository {
  Future<List<StudySpot>> list();
  Future<StudySpot> add(StudySpot spot);
  Future<void> remove(String id);
}
