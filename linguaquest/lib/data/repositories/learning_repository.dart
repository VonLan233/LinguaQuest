import '../models/lesson.dart';
import '../models/study_session.dart';

abstract class LearningRepository {
  Future<List<Lesson>> listLessons();

  Future<void> recordStudySession(StudySession session);
}
