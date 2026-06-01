class LeaderboardEntry {
  const LeaderboardEntry({
    required this.uid,
    required this.name,
    required this.points,
    required this.xp,
    required this.streak,
    required this.totalStudyDays,
    this.avatarUrl,
  });

  final String uid;
  final String name;
  final String? avatarUrl;
  final int points;
  final int xp;
  final int streak;
  final int totalStudyDays;

  int get score => points > 0 ? points : xp;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '学习者',
      avatarUrl: json['avatarUrl'] as String?,
      points: (json['points'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      totalStudyDays: (json['totalStudyDays'] as num?)?.toInt() ?? 0,
    );
  }
}
