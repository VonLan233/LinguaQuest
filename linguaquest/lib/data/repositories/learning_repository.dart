import '../models/lesson.dart';
import '../models/study_session.dart';

abstract class LearningRepository {
  Future<List<Lesson>> listLessons({String? wordBookId});

  Future<void> recordStudySession(StudySession session);
}
