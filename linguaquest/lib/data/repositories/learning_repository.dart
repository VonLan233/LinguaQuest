import '../models/exercise_record.dart';
import '../models/lesson.dart';
import '../models/study_session.dart';
import '../models/user_profile.dart';

class LearningProgress {
  const LearningProgress({
    required this.completedLessonIds,
    required this.todayCompletedLessonIds,
    required this.todayReviewWordIds,
    required this.todayClaimedRewardIds,
  });

  final Set<String> completedLessonIds;
  final Set<String> todayCompletedLessonIds;
  final Set<String> todayReviewWordIds;
  final Set<String> todayClaimedRewardIds;

  factory LearningProgress.fromJson(Map<String, dynamic> json) {
    return LearningProgress(
      completedLessonIds: _stringSet(json['completedLessonIds']),
      todayCompletedLessonIds: _stringSet(json['todayCompletedLessonIds']),
      todayReviewWordIds: _stringSet(json['todayReviewWordIds']),
      todayClaimedRewardIds: _stringSet(json['todayClaimedRewardIds']),
    );
  }
}

class RewardClaimResult {
  const RewardClaimResult({
    required this.claimed,
    required this.user,
    required this.progress,
  });

  final bool claimed;
  final UserProfile user;
  final LearningProgress progress;

  factory RewardClaimResult.fromJson(Map<String, dynamic> json) {
    return RewardClaimResult(
      claimed: json['claimed'] as bool? ?? false,
      user: UserProfile.fromJson(
        Map<String, dynamic>.from(json['user'] as Map),
      ),
      progress: LearningProgress.fromJson(
        Map<String, dynamic>.from(json['progress'] as Map),
      ),
    );
  }
}

abstract class LearningRepository {
  Future<List<WordBook>> listWordBooks() async => const [];

  /// Drops any in-memory cache of bundled content so the next read re-loads
  /// from the asset bundle. No-op for repositories without an asset cache.
  Future<void> clearOfflineCache() async {}

  Future<List<Lesson>> listLessons();

  Future<LearningProgress?> loadLearningProgress(DateTime now);

  Future<List<Lesson>> listLessonsForWordBook(String wordBookId) async {
    return listLessons();
  }

  Future<void> recordStudySession(StudySession session);

  Future<void> recordExerciseRecords(List<ExerciseRecord> records);

  Future<RewardClaimResult?> claimReward({
    required String id,
    required int points,
    required DateTime now,
  });
}

Set<String> _stringSet(Object? value) {
  if (value is! Iterable) return const {};
  return value.map((item) => item.toString()).toSet();
}

abstract class OfflineWordbookRepository {
  Future<Set<String>> downloadedWordBookIds() async => {};
  Future<void> downloadWordBook(String id) async {
    throw UnsupportedError('Downloads require a connected build');
  }

  Future<void> removeDownloadedWordBook(String id) async {}
}
