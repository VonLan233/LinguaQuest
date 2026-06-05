import '../models/study_plan.dart';

abstract class StudyPlanRepository {
  Future<StudyPlan?> load(String uid);

  Future<StudyPlan> save(StudyPlan plan);

  Future<StudyPlan> reset(StudyPlan plan);
}
