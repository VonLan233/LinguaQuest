import '../models/lesson.dart';
import '../models/study_session.dart';

abstract class LearningRepository {
  Future<List<WordBook>> listWordBooks() async => const [];

  Future<List<Lesson>> listLessons();

  Future<List<Lesson>> listLessonsForWordBook(String wordBookId) async {
    return listLessons();
  }

  Future<void> recordStudySession(StudySession session);
}
