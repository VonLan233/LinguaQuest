import '../models/lesson.dart';
import '../models/exercise_record.dart';
import '../models/study_session.dart';

abstract class LearningRepository {
  Future<List<Lesson>> listLessons();

  Future<void> recordStudySession(StudySession session);

  Future<void> recordExerciseRecords(List<ExerciseRecord> records);
}
