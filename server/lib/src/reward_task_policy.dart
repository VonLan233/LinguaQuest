const rewardTaskTypes = {
  'dailyCheckIn',
  'newLearning',
  'reviewDone',
  'trainingChallenge',
  'wrongCleanup',
  'forumInteraction',
};

class DailyRewardBehavior {
  const DailyRewardBehavior({
    required this.checkedIn,
    required this.newLearningDone,
    required this.reviewDone,
    required this.trainingChallengeDone,
    required this.wrongCleanupDone,
    required this.forumInteractionDone,
  });

  final bool checkedIn;
  final bool newLearningDone;
  final bool reviewDone;
  final bool trainingChallengeDone;
  final bool wrongCleanupDone;
  final bool forumInteractionDone;
}

class RewardTaskDefinition {
  const RewardTaskDefinition({
    required this.id,
    required this.title,
    required this.condition,
    required this.points,
    required this.targetRoute,
  });

  final String id;
  final String title;
  final String condition;
  final int points;
  final String targetRoute;
}

const rewardTaskDefinitions = <RewardTaskDefinition>[
  RewardTaskDefinition(
    id: 'dailyCheckIn',
    title: '每日签到',
    condition: '当天打开并点击签到',
    points: 5,
    targetRoute: '/discover',
  ),
  RewardTaskDefinition(
    id: 'newLearning',
    title: '完成新学',
    condition: '完成今日新学任务',
    points: 20,
    targetRoute: '/study/new',
  ),
  RewardTaskDefinition(
    id: 'reviewDone',
    title: '完成复习',
    condition: '完成今日到期复习',
    points: 15,
    targetRoute: '/study/review',
  ),
  RewardTaskDefinition(
    id: 'trainingChallenge',
    title: '训练场挑战',
    condition: '完成任意训练场游戏',
    points: 20,
    targetRoute: '/training',
  ),
  RewardTaskDefinition(
    id: 'wrongCleanup',
    title: '错词清理',
    condition: '今日错词再次答对',
    points: 10,
    targetRoute: '/review',
  ),
  RewardTaskDefinition(
    id: 'forumInteraction',
    title: '论坛互动',
    condition: '发帖或评论通过审核',
    points: 5,
    targetRoute: '/discover',
  ),
];

List<Map<String, dynamic>> dailyRewardTaskDtos({
  required DailyRewardBehavior behavior,
  required Set<String> claimedTaskIds,
}) {
  return [
    for (final definition in rewardTaskDefinitions)
      {
        'id': definition.id,
        'title': definition.title,
        'condition': definition.condition,
        'points': definition.points,
        'targetRoute': definition.targetRoute,
        'status': _statusFor(
          isDone: _isDone(definition.id, behavior),
          isClaimed: claimedTaskIds.contains(definition.id),
        ),
      },
  ];
}

RewardTaskDefinition? rewardTaskDefinitionById(String id) {
  for (final definition in rewardTaskDefinitions) {
    if (definition.id == id) return definition;
  }
  return null;
}

bool isRewardTaskDone(String id, DailyRewardBehavior behavior) {
  return _isDone(id, behavior);
}

String _statusFor({required bool isDone, required bool isClaimed}) {
  if (isClaimed) return 'claimed';
  if (isDone) return 'claimable';
  return 'incomplete';
}

bool _isDone(String id, DailyRewardBehavior behavior) {
  switch (id) {
    case 'dailyCheckIn':
      return behavior.checkedIn;
    case 'newLearning':
      return behavior.newLearningDone;
    case 'reviewDone':
      return behavior.reviewDone;
    case 'trainingChallenge':
      return behavior.trainingChallengeDone;
    case 'wrongCleanup':
      return behavior.wrongCleanupDone;
    case 'forumInteraction':
      return behavior.forumInteractionDone;
  }
  return false;
}
