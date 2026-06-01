class UserProfile {
  const UserProfile({
    required this.uid,
    required this.name,
    required this.email,
    required this.targetExam,
    required this.level,
    required this.dailyGoal,
    required this.xp,
    required this.streak,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.dailyNewTarget = 10,
    this.dailyReviewLimit = 20,
    this.currentWordBookId = 'beginner',
    this.points = 0,
    this.totalStudyDays = 0,
    this.totalStudyMinutes = 0,
    this.lastStudyDate,
  });

  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final String targetExam;
  final String level;
  final int dailyGoal;
  final int dailyNewTarget;
  final int dailyReviewLimit;
  final String currentWordBookId;
  final int xp;
  final int points;
  final int streak;
  final int totalStudyDays;
  final int totalStudyMinutes;
  final DateTime? lastStudyDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.demo() {
    final now = DateTime.now();
    return UserProfile(
      uid: 'demo-user',
      name: '学习者',
      email: 'learner@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      dailyNewTarget: 10,
      dailyReviewLimit: 20,
      currentWordBookId: 'beginner',
      xp: 120,
      points: 120,
      streak: 3,
      totalStudyDays: 3,
      totalStudyMinutes: 36,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      targetExam: json['targetExam'] as String? ?? 'Daily English',
      level: json['level'] as String? ?? 'Elementary',
      dailyGoal: json['dailyGoal'] as int? ?? 10,
      dailyNewTarget: json['dailyNewTarget'] as int? ?? 10,
      dailyReviewLimit: json['dailyReviewLimit'] as int? ?? 20,
      currentWordBookId: json['currentWordBookId'] as String? ?? 'beginner',
      xp: json['xp'] as int? ?? 0,
      points: json['points'] as int? ?? json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      totalStudyDays: json['totalStudyDays'] as int? ?? 0,
      totalStudyMinutes: json['totalStudyMinutes'] as int? ?? 0,
      lastStudyDate: _date(json['lastStudyDate']),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'avatarUrl': avatarUrl,
      'targetExam': targetExam,
      'level': level,
      'dailyGoal': dailyGoal,
      'dailyNewTarget': dailyNewTarget,
      'dailyReviewLimit': dailyReviewLimit,
      'currentWordBookId': currentWordBookId,
      'xp': xp,
      'points': points,
      'streak': streak,
      'totalStudyDays': totalStudyDays,
      'totalStudyMinutes': totalStudyMinutes,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? uid,
    String? name,
    String? email,
    String? avatarUrl,
    String? targetExam,
    String? level,
    int? dailyGoal,
    int? dailyNewTarget,
    int? dailyReviewLimit,
    String? currentWordBookId,
    int? xp,
    int? points,
    int? streak,
    int? totalStudyDays,
    int? totalStudyMinutes,
    DateTime? lastStudyDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      targetExam: targetExam ?? this.targetExam,
      level: level ?? this.level,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      dailyNewTarget: dailyNewTarget ?? this.dailyNewTarget,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      currentWordBookId: currentWordBookId ?? this.currentWordBookId,
      xp: xp ?? this.xp,
      points: points ?? this.points,
      streak: streak ?? this.streak,
      totalStudyDays: totalStudyDays ?? this.totalStudyDays,
      totalStudyMinutes: totalStudyMinutes ?? this.totalStudyMinutes,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
