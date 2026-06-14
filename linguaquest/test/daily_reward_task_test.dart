import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/daily_reward_task.dart';
import 'package:linguaquest/data/repositories/reward_task_repository.dart';

void main() {
  test('daily reward task parses backend status flow', () {
    final incomplete = DailyRewardTask.fromJson({
      'id': 'newLearning',
      'title': '完成新学',
      'condition': '完成今日新学任务',
      'points': 20,
      'targetRoute': '/study/new',
      'status': 'incomplete',
    });

    expect(incomplete.isIncomplete, isTrue);
    expect(incomplete.isClaimable, isFalse);

    final claimable = incomplete.copyWith(
      status: DailyRewardTaskStatus.claimable,
    );
    expect(claimable.isClaimable, isTrue);
    expect(claimable.isClaimed, isFalse);

    final claimed = claimable.copyWith(status: DailyRewardTaskStatus.claimed);
    expect(claimed.isClaimed, isTrue);
  });

  test('unknown backend statuses stay safe and incomplete', () {
    final task = DailyRewardTask.fromJson({
      'id': 'forumInteraction',
      'title': '论坛互动',
      'condition': '发帖或评论通过审核',
      'points': 5,
      'targetRoute': '/discover',
      'status': 'unexpected',
    });

    expect(task.status, DailyRewardTaskStatus.incomplete);
  });

  test('reward snapshot can distinguish stale already-claimed responses', () {
    final claimedTask = DailyRewardTask.fromJson({
      'id': 'dailyCheckIn',
      'title': '每日签到',
      'condition': '当天打开并点击签到',
      'points': 5,
      'targetRoute': '/discover',
      'status': 'claimed',
    });

    final snapshot = RewardTaskSnapshot(
      dateKey: '2026-06-03',
      tasks: [claimedTask],
      claimed: false,
      alreadyClaimed: true,
    );

    expect(snapshot.claimed, isFalse);
    expect(snapshot.alreadyClaimed, isTrue);
    expect(snapshot.tasks.single.isClaimed, isTrue);
  });
}
