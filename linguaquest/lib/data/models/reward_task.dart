class RewardTask {
  const RewardTask({
    required this.id,
    required this.title,
    required this.taskType,
    required this.condition,
    required this.points,
    required this.isAvailable,
    required this.isClaimed,
    this.claimedAt,
  });

  final String id;
  final String title;
  final String taskType;
  final String condition;
  final int points;
  final bool isAvailable;
  final bool isClaimed;
  final DateTime? claimedAt;

  factory RewardTask.fromJson(Map<String, dynamic> json) {
    return RewardTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      taskType: json['taskType'] as String? ?? 'general',
      condition: json['condition'] as String? ?? '',
      points: (json['points'] as num?)?.toInt() ?? 0,
      isAvailable: json['available'] as bool? ?? false,
      isClaimed: json['claimed'] as bool? ?? false,
      claimedAt: _date(json['claimedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'taskType': taskType,
      'condition': condition,
      'points': points,
      'available': isAvailable,
      'claimed': isClaimed,
      'claimedAt': claimedAt?.toIso8601String(),
    };
  }

  RewardTask copyWith({
    String? id,
    String? title,
    String? taskType,
    String? condition,
    int? points,
    bool? isAvailable,
    bool? isClaimed,
    DateTime? claimedAt,
  }) {
    return RewardTask(
      id: id ?? this.id,
      title: title ?? this.title,
      taskType: taskType ?? this.taskType,
      condition: condition ?? this.condition,
      points: points ?? this.points,
      isAvailable: isAvailable ?? this.isAvailable,
      isClaimed: isClaimed ?? this.isClaimed,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
