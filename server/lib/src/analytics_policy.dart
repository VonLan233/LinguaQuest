class LearningAnalytics {
  const LearningAnalytics({
    required this.streakDays,
    required this.totalStudyDays,
    required this.learnedWords,
    required this.masteredWords,
    required this.newWordsToday,
    required this.reviewsToday,
    required this.wordbookProgressPct,
    required this.todayMinutes,
    required this.totalMinutes,
    required this.averageAccuracyPct,
    required this.sevenDayXp,
    required this.weakestExerciseType,
    required this.mostMissedWordIds,
    required this.achievementCount,
    required this.trainingXp,
    required this.trainingRank,
  });

  final int streakDays;
  final int totalStudyDays;
  final int learnedWords;
  final int masteredWords;
  final int newWordsToday;
  final int reviewsToday;
  final int wordbookProgressPct;
  final int todayMinutes;
  final int totalMinutes;
  final int averageAccuracyPct;
  final List<int> sevenDayXp;
  final String weakestExerciseType;
  final List<String> mostMissedWordIds;
  final int achievementCount;
  final int trainingXp;
  final int trainingRank;

  Map<String, dynamic> toJson() => {
        'streakDays': streakDays,
        'totalStudyDays': totalStudyDays,
        'learnedWords': learnedWords,
        'masteredWords': masteredWords,
        'newWordsToday': newWordsToday,
        'reviewsToday': reviewsToday,
        'wordbookProgressPct': wordbookProgressPct,
        'todayMinutes': todayMinutes,
        'totalMinutes': totalMinutes,
        'averageAccuracyPct': averageAccuracyPct,
        'sevenDayXp': sevenDayXp,
        'weakestExerciseType': weakestExerciseType,
        'mostMissedWordIds': mostMissedWordIds,
        'achievementCount': achievementCount,
        'trainingXp': trainingXp,
        'trainingRank': trainingRank,
      };

  factory LearningAnalytics.fromJson(Map<String, dynamic> j) =>
      LearningAnalytics(
        streakDays: j['streakDays'] as int? ?? 0,
        totalStudyDays: j['totalStudyDays'] as int? ?? 0,
        learnedWords: j['learnedWords'] as int? ?? 0,
        masteredWords: j['masteredWords'] as int? ?? 0,
        newWordsToday: j['newWordsToday'] as int? ?? 0,
        reviewsToday: j['reviewsToday'] as int? ?? 0,
        wordbookProgressPct: j['wordbookProgressPct'] as int? ?? 0,
        todayMinutes: j['todayMinutes'] as int? ?? 0,
        totalMinutes: j['totalMinutes'] as int? ?? 0,
        averageAccuracyPct: j['averageAccuracyPct'] as int? ?? 0,
        sevenDayXp: (j['sevenDayXp'] as List<dynamic>? ?? const [])
            .cast<int>(),
        weakestExerciseType:
            j['weakestExerciseType'] as String? ?? 'spelling',
        mostMissedWordIds:
            (j['mostMissedWordIds'] as List<dynamic>? ?? const [])
                .cast<String>(),
        achievementCount: j['achievementCount'] as int? ?? 0,
        trainingXp: j['trainingXp'] as int? ?? 0,
        trainingRank: j['trainingRank'] as int? ?? -1,
      );

  static LearningAnalytics mock() => const LearningAnalytics(
        streakDays: 5,
        totalStudyDays: 12,
        learnedWords: 89,
        masteredWords: 34,
        newWordsToday: 8,
        reviewsToday: 12,
        wordbookProgressPct: 18,
        todayMinutes: 15,
        totalMinutes: 180,
        averageAccuracyPct: 78,
        sevenDayXp: [120, 80, 95, 110, 70, 130, 45],
        weakestExerciseType: 'spelling',
        mostMissedWordIds: ['hsk1_005_g', 'hsk1_012_m'],
        achievementCount: 3,
        trainingXp: 300,
        trainingRank: -1,
      );
}
