import 'package:linguaquest_server/src/reward_policy.dart';
import 'package:test/test.dart';

void main() {
  test('daily reward tasks expose all PRD task categories', () {
    final tasks = dailyRewardTaskDtos(
      behavior: const DailyRewardBehavior(
        checkedIn: true,
        newLearningDone: true,
        reviewDone: true,
        trainingChallengeDone: true,
        wrongCleanupDone: true,
        forumInteractionDone: true,
      ),
      claimedTaskIds: const {},
    );

    expect(tasks.map((task) => task['id']), containsAll(rewardTaskTypes));
    expect(tasks, hasLength(6));
    expect(tasks.every((task) => task['status'] == 'claimable'), isTrue);
  });

  test('task status moves from incomplete to claimable to claimed', () {
    final incomplete = dailyRewardTaskDtos(
      behavior: const DailyRewardBehavior(
        checkedIn: false,
        newLearningDone: false,
        reviewDone: false,
        trainingChallengeDone: false,
        wrongCleanupDone: false,
        forumInteractionDone: false,
      ),
      claimedTaskIds: const {},
    );
    expect(
      incomplete.singleWhere((task) => task['id'] == 'dailyCheckIn')['status'],
      'incomplete',
    );

    final claimable = dailyRewardTaskDtos(
      behavior: const DailyRewardBehavior(
        checkedIn: true,
        newLearningDone: false,
        reviewDone: false,
        trainingChallengeDone: false,
        wrongCleanupDone: false,
        forumInteractionDone: false,
      ),
      claimedTaskIds: const {},
    );
    expect(
      claimable.singleWhere((task) => task['id'] == 'dailyCheckIn')['status'],
      'claimable',
    );

    final claimed = dailyRewardTaskDtos(
      behavior: const DailyRewardBehavior(
        checkedIn: true,
        newLearningDone: false,
        reviewDone: false,
        trainingChallengeDone: false,
        wrongCleanupDone: false,
        forumInteractionDone: false,
      ),
      claimedTaskIds: const {'dailyCheckIn'},
    );
    expect(
      claimed.singleWhere((task) => task['id'] == 'dailyCheckIn')['status'],
      'claimed',
    );
  });
}
