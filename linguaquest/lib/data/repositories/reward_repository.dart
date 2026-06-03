import '../models/daily_reward_task.dart';
import '../models/user_profile.dart';

class RewardTaskSnapshot {
  const RewardTaskSnapshot({
    required this.dateKey,
    required this.tasks,
    this.user,
    this.claimed,
    this.alreadyClaimed = false,
  });

  final String dateKey;
  final List<DailyRewardTask> tasks;
  final UserProfile? user;
  final bool? claimed;
  final bool alreadyClaimed;
}

abstract class RewardRepository {
  Future<RewardTaskSnapshot> listTasks(String uid);

  Future<RewardTaskSnapshot> checkIn(String uid);

  Future<RewardTaskSnapshot> claimTask(String uid, String taskId);

  Future<RewardTaskSnapshot> recordEvent(String uid, RewardEventType type);
}
