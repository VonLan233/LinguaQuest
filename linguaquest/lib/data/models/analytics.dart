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
    this.modalityAccuracy = const {},
    this.dailyXp = const [],
    this.topErrorTypes = const [],
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

  /// Per-modality accuracy: keys are 'meaning', 'listening', 'spelling', 'context'.
  /// Values are 0–100 (percent). Empty map = no data yet.
  final Map<String, int> modalityAccuracy;

  /// XP earned per day for up to 14/30 days (oldest first).
  /// If non-empty, the XP trend chart uses this instead of [sevenDayXp].
  final List<int> dailyXp;

  /// Ordered list of prompt types with the highest error rates (worst first).
  final List<String> topErrorTypes;

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
        'modalityAccuracy': modalityAccuracy,
        'dailyXp': dailyXp,
        'topErrorTypes': topErrorTypes,
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
            .map((e) => e as int)
            .toList(),
        weakestExerciseType:
            j['weakestExerciseType'] as String? ?? 'spelling',
        mostMissedWordIds:
            (j['mostMissedWordIds'] as List<dynamic>? ?? const [])
                .map((e) => e as String)
                .toList(),
        achievementCount: j['achievementCount'] as int? ?? 0,
        trainingXp: j['trainingXp'] as int? ?? 0,
        trainingRank: j['trainingRank'] as int? ?? -1,
        modalityAccuracy:
            (j['modalityAccuracy'] as Map<String, dynamic>? ?? const {})
                .map((k, v) => MapEntry(k, (v as num).toInt())),
        dailyXp: (j['dailyXp'] as List<dynamic>? ?? const [])
            .map((e) => e as int)
            .toList(),
        topErrorTypes: (j['topErrorTypes'] as List<dynamic>? ?? const [])
            .map((e) => e as String)
            .toList(),
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
        modalityAccuracy: {
          'meaning': 84,
          'listening': 71,
          'spelling': 63,
          'context': 77,
        },
        dailyXp: [120, 80, 95, 110, 70, 130, 45, 100, 90, 60, 85, 110, 75, 95],
        topErrorTypes: ['spelling', 'listening'],
      );
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    required this.isCurrentUser,
  });

  final int rank;
  final String userId;
  final String name;
  final int xp;
  final bool isCurrentUser;

  Map<String, dynamic> toJson() => {
        'rank': rank,
        'userId': userId,
        'name': name,
        'xp': xp,
        'isCurrentUser': isCurrentUser,
      };

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
        rank: j['rank'] as int? ?? 0,
        userId: j['userId'] as String? ?? '',
        name: j['name'] as String? ?? '',
        xp: j['xp'] as int? ?? 0,
        isCurrentUser: j['isCurrentUser'] as bool? ?? false,
      );
}

class LeaderboardResult {
  const LeaderboardResult({
    required this.dimension,
    required this.entries,
    required this.currentUserRank,
  });

  final String dimension;
  final List<LeaderboardEntry> entries;
  final int currentUserRank;

  Map<String, dynamic> toJson() => {
        'dimension': dimension,
        'entries': entries.map((e) => e.toJson()).toList(),
        'currentUserRank': currentUserRank,
      };

  factory LeaderboardResult.fromJson(Map<String, dynamic> j) =>
      LeaderboardResult(
        dimension: j['dimension'] as String? ?? 'global',
        entries: (j['entries'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntry.fromJson)
            .toList(),
        currentUserRank: j['currentUserRank'] as int? ?? -1,
      );
}
