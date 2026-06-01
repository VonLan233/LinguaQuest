class ClassGroup {
  const ClassGroup({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.teacherName,
    required this.role,
    required this.memberCount,
    required this.joinedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String name;
  final String description;
  final String teacherName;
  final String role;
  final int memberCount;
  final DateTime joinedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ClassGroup.fromJson(Map<String, dynamic> json) {
    return ClassGroup(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '学习班级',
      description: json['description'] as String? ?? '',
      teacherName: json['teacherName'] as String? ?? 'LinguaQuest',
      role: json['role'] as String? ?? 'student',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      joinedAt: _date(json['joinedAt']) ?? DateTime.now(),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }
}

class ClassProgressSummary {
  const ClassProgressSummary({
    required this.classGroup,
    required this.memberCount,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.members,
    required this.lessons,
    required this.weakWords,
  });

  final ClassGroup classGroup;
  final int memberCount;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final List<ClassMemberProgress> members;
  final List<ClassLessonProgress> lessons;
  final List<ClassWeakWord> weakWords;

  factory ClassProgressSummary.fromJson(Map<String, dynamic> json) {
    return ClassProgressSummary(
      classGroup: ClassGroup.fromJson(json['class'] as Map<String, dynamic>),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      members: (json['members'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ClassMemberProgress.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      lessons: (json['lessons'] as List<dynamic>? ?? const [])
          .map(
            (item) =>
                ClassLessonProgress.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      weakWords: (json['weakWords'] as List<dynamic>? ?? const [])
          .map((item) => ClassWeakWord.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ClassMemberProgress {
  const ClassMemberProgress({
    required this.uid,
    required this.name,
    required this.role,
    required this.points,
    required this.xp,
    required this.streak,
    required this.totalStudyDays,
    required this.totalStudyMinutes,
    required this.sessions,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.earnedPoints,
    required this.joinedAt,
    this.avatarUrl,
  });

  final String uid;
  final String name;
  final String? avatarUrl;
  final String role;
  final int points;
  final int xp;
  final int streak;
  final int totalStudyDays;
  final int totalStudyMinutes;
  final int sessions;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final int earnedPoints;
  final DateTime joinedAt;

  int get score => points > 0 ? points : xp;

  factory ClassMemberProgress.fromJson(Map<String, dynamic> json) {
    return ClassMemberProgress(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? '学习者',
      avatarUrl: json['avatarUrl'] as String?,
      role: json['role'] as String? ?? 'student',
      points: (json['points'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      totalStudyDays: (json['totalStudyDays'] as num?)?.toInt() ?? 0,
      totalStudyMinutes: (json['totalStudyMinutes'] as num?)?.toInt() ?? 0,
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      earnedPoints: (json['earnedPoints'] as num?)?.toInt() ?? 0,
      joinedAt: _date(json['joinedAt']) ?? DateTime.now(),
    );
  }
}

class ClassLessonProgress {
  const ClassLessonProgress({
    required this.lessonId,
    required this.sessions,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    this.lastPracticedAt,
  });

  final String lessonId;
  final int sessions;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final DateTime? lastPracticedAt;

  factory ClassLessonProgress.fromJson(Map<String, dynamic> json) {
    return ClassLessonProgress(
      lessonId: json['lessonId'] as String? ?? '',
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      lastPracticedAt: _date(json['lastPracticedAt']),
    );
  }
}

class ClassWeakWord {
  const ClassWeakWord({required this.wordId, required this.mistakeCount});

  final String wordId;
  final int mistakeCount;

  factory ClassWeakWord.fromJson(Map<String, dynamic> json) {
    return ClassWeakWord(
      wordId: json['wordId'] as String? ?? '',
      mistakeCount: (json['mistakeCount'] as num?)?.toInt() ?? 0,
    );
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
