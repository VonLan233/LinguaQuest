class AnalyticsSummary {
  const AnalyticsSummary({
    required this.sessions,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.accuracy,
    required this.studyMinutes,
    required this.earnedPoints,
    required this.weakWords,
    required this.forumPosts,
    required this.streakDays,
    required this.totalStudyDays,
    required this.totalStudyMinutes,
    required this.points,
    required this.xp,
  });

  final int sessions;
  final int totalQuestions;
  final int correctAnswers;
  final double accuracy;
  final int studyMinutes;
  final int earnedPoints;
  final int weakWords;
  final int forumPosts;
  final int streakDays;
  final int totalStudyDays;
  final int totalStudyMinutes;
  final int points;
  final int xp;

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    return AnalyticsSummary(
      sessions: (json['sessions'] as num?)?.toInt() ?? 0,
      totalQuestions: (json['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (json['correctAnswers'] as num?)?.toInt() ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
      studyMinutes: (json['studyMinutes'] as num?)?.toInt() ?? 0,
      earnedPoints: (json['earnedPoints'] as num?)?.toInt() ?? 0,
      weakWords: (json['weakWords'] as num?)?.toInt() ?? 0,
      forumPosts: (json['forumPosts'] as num?)?.toInt() ?? 0,
      streakDays: (json['streakDays'] as num?)?.toInt() ?? 0,
      totalStudyDays: (json['totalStudyDays'] as num?)?.toInt() ?? 0,
      totalStudyMinutes: (json['totalStudyMinutes'] as num?)?.toInt() ?? 0,
      points: (json['points'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
    );
  }
}
