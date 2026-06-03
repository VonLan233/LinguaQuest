enum DailyRewardTaskStatus { incomplete, claimable, claimed }

enum RewardEventType {
  newLearning,
  reviewDone,
  trainingChallenge,
  wrongCleanup,
  forumInteraction,
}

class DailyRewardTask {
  const DailyRewardTask({
    required this.id,
    required this.title,
    required this.condition,
    required this.points,
    required this.targetRoute,
    required this.status,
  });

  final String id;
  final String title;
  final String condition;
  final int points;
  final String targetRoute;
  final DailyRewardTaskStatus status;

  bool get isIncomplete => status == DailyRewardTaskStatus.incomplete;
  bool get isClaimable => status == DailyRewardTaskStatus.claimable;
  bool get isClaimed => status == DailyRewardTaskStatus.claimed;

  factory DailyRewardTask.fromJson(Map<String, dynamic> json) {
    return DailyRewardTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      condition: json['condition'] as String? ?? '',
      points: json['points'] as int? ?? 0,
      targetRoute: json['targetRoute'] as String? ?? '/discover',
      status: _statusFromName(json['status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'condition': condition,
      'points': points,
      'targetRoute': targetRoute,
      'status': status.name,
    };
  }

  DailyRewardTask copyWith({DailyRewardTaskStatus? status}) {
    return DailyRewardTask(
      id: id,
      title: title,
      condition: condition,
      points: points,
      targetRoute: targetRoute,
      status: status ?? this.status,
    );
  }

  static DailyRewardTaskStatus _statusFromName(String? value) {
    for (final status in DailyRewardTaskStatus.values) {
      if (status.name == value) return status;
    }
    return DailyRewardTaskStatus.incomplete;
  }
}
