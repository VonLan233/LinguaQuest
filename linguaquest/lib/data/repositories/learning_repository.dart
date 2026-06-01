import '../models/activity_summary.dart';
import '../models/lesson.dart';
import '../models/study_session.dart';
import '../models/target_word_progress.dart';
import '../models/user_profile.dart';

abstract class LearningRepository {
  Future<List<WordBook>> listWordBooks();

  Future<List<Lesson>> listLessons();

  Future<Map<String, dynamic>?> loadStudyPlan(String uid);

  Future<Map<String, dynamic>?> saveStudyPlan(
    String uid,
    Map<String, dynamic> data,
  );

  Future<void> clearStudyPlan(String uid);

  Future<List<TargetWordProgress>> listTargetWordProgress(String uid);

  Future<void> upsertTargetWordProgress(
    String uid,
    TargetWordProgress progress,
  );

  Future<ActivitySummary> loadActivitySummary(String uid);

  Future<UserProfile> recordStudySession(StudySession session);
}
