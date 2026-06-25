/// A personalised practice recommendation derived from a user's mastery-
/// dimension weak spots.
class Recommendation {
  const Recommendation({
    required this.targetWordIds,
    required this.exerciseType,
    required this.reason,
    required this.priority,
    required this.estimatedMinutes,
  });

  /// The word ids that this recommendation targets.
  final List<String> targetWordIds;

  /// Exercise type label (e.g. 'listeningWordChoice', 'sentenceCloze').
  final String exerciseType;

  /// Human-readable explanation shown in the UI.
  final String reason;

  /// 1 = high priority, 2 = medium, 3 = low.
  final int priority;

  /// Rough number of minutes expected to complete the practice set.
  final int estimatedMinutes;

  Recommendation copyWith({
    List<String>? targetWordIds,
    String? exerciseType,
    String? reason,
    int? priority,
    int? estimatedMinutes,
  }) {
    return Recommendation(
      targetWordIds: targetWordIds ?? this.targetWordIds,
      exerciseType: exerciseType ?? this.exerciseType,
      reason: reason ?? this.reason,
      priority: priority ?? this.priority,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }

  Map<String, dynamic> toJson() => {
        'targetWordIds': targetWordIds,
        'exerciseType': exerciseType,
        'reason': reason,
        'priority': priority,
        'estimatedMinutes': estimatedMinutes,
      };

  factory Recommendation.fromJson(Map<String, dynamic> j) => Recommendation(
        targetWordIds: (j['targetWordIds'] as List<dynamic>? ?? const [])
            .map((e) => e.toString())
            .toList(),
        exerciseType: j['exerciseType'] as String? ?? '',
        reason: j['reason'] as String? ?? '',
        priority: j['priority'] as int? ?? 3,
        estimatedMinutes: j['estimatedMinutes'] as int? ?? 0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recommendation &&
          exerciseType == other.exerciseType &&
          priority == other.priority &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(exerciseType, priority, reason);
}
