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
    this.lastStudyDate,
    this.emailVerified = true,
    this.currentWordBookId,
    this.language,
  });

  final String uid;
  final String name;
  final String email;
  final String? avatarUrl;
  final String targetExam;
  final String level;
  final int dailyGoal;
  final int xp;
  final int streak;
  final DateTime? lastStudyDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool emailVerified;
  final String? currentWordBookId;
  final String? language;

  factory UserProfile.demo() {
    final now = DateTime.now();
    return UserProfile(
      uid: 'demo-user',
      name: 'Explorer',
      email: 'learner@lingua.quest',
      targetExam: 'Daily English',
      level: 'Elementary',
      dailyGoal: 10,
      xp: 120,
      streak: 3,
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
      xp: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      emailVerified: json['emailVerified'] as bool? ?? true,
      lastStudyDate: _date(json['lastStudyDate']),
      currentWordBookId: json['currentWordBookId'] as String?,
      language: json['language'] as String?,
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
      'xp': xp,
      'streak': streak,
      'emailVerified': emailVerified,
      'lastStudyDate': lastStudyDate?.toIso8601String(),
      'currentWordBookId': currentWordBookId,
      'language': language,
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
    int? xp,
    int? streak,
    DateTime? lastStudyDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? emailVerified,
    String? currentWordBookId,
    String? language,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      targetExam: targetExam ?? this.targetExam,
      level: level ?? this.level,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      xp: xp ?? this.xp,
      streak: streak ?? this.streak,
      lastStudyDate: lastStudyDate ?? this.lastStudyDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      emailVerified: emailVerified ?? this.emailVerified,
      currentWordBookId: currentWordBookId ?? this.currentWordBookId,
      language: language ?? this.language,
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
