import 'database.dart';

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

  /// Per-modality accuracy: keys 'meaning', 'listening', 'spelling', 'context'.
  final Map<String, int> modalityAccuracy;

  /// XP per day for up to 14 days (oldest→newest).
  final List<int> dailyXp;

  /// Prompt types ordered by error rate descending.
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
        weakestExerciseType: j['weakestExerciseType'] as String? ?? 'spelling',
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

// ── Analytics aggregation helpers ────────────────────────────────────────────

/// Maps a prompt_type string to one of the four modality buckets.
String _promptTypeToModality(String promptType) {
  final lower = promptType.toLowerCase();
  if (lower.contains('listen')) return 'listening';
  if (lower.contains('spell') || lower == 'spelling') return 'spelling';
  if (lower.contains('context') || lower.contains('cloze')) return 'context';
  // meaningChoice, chineseChoice, confusableChoice, collocationChoice, etc.
  return 'meaning';
}

/// Computes real analytics by aggregating over existing DB tables.
/// Returns a [LearningAnalytics] object with live data.
/// On any error / new user with no rows, all fields default to 0/empty.
Future<LearningAnalytics> computeAnalytics(
  AppDatabase database,
  String uid,
) async {
  try {
    return await _doCompute(database, uid);
  } catch (_) {
    // Graceful fallback: new user or DB error → zero-state
    return const LearningAnalytics(
      streakDays: 0,
      totalStudyDays: 0,
      learnedWords: 0,
      masteredWords: 0,
      newWordsToday: 0,
      reviewsToday: 0,
      wordbookProgressPct: 0,
      todayMinutes: 0,
      totalMinutes: 0,
      averageAccuracyPct: 0,
      sevenDayXp: [],
      weakestExerciseType: '',
      mostMissedWordIds: [],
      achievementCount: 0,
      trainingXp: 0,
      trainingRank: -1,
    );
  }
}

Future<LearningAnalytics> _doCompute(
  AppDatabase database,
  String uid,
) async {
  final conn = database.connection;

  // ── 1. Streak from users table ─────────────────────────────────────────────
  final userRows = await conn.execute(
    r'SELECT streak FROM users WHERE id = $1',
    parameters: [uid],
  );
  final streakDays = userRows.isEmpty
      ? 0
      : (userRows.first[0] as int? ?? 0);

  // ── 2. Learned & mastered words (user_words) ───────────────────────────────
  final wordCountRows = await conn.execute(
    r'''SELECT
      COUNT(*) FILTER (WHERE status NOT IN ('New','Previewed','Ignored')) AS learned,
      COUNT(*) FILTER (WHERE mastery_level >= 4) AS mastered,
      COUNT(*) AS total
    FROM user_words WHERE uid = $1''',
    parameters: [uid],
  );
  final int learnedWords = wordCountRows.isEmpty
      ? 0
      : (wordCountRows.first[0] as int? ?? 0);
  final int masteredWords = wordCountRows.isEmpty
      ? 0
      : (wordCountRows.first[1] as int? ?? 0);
  final int totalWords = wordCountRows.isEmpty
      ? 0
      : (wordCountRows.first[2] as int? ?? 0);
  final int wordbookProgressPct =
      totalWords == 0 ? 0 : (masteredWords * 100 ~/ totalWords);

  // ── 3. Study sessions ──────────────────────────────────────────────────────
  final sessionRows = await conn.execute(
    r'''SELECT
      COUNT(DISTINCT started_at::date) AS study_days,
      COALESCE(SUM(EXTRACT(epoch FROM ended_at - started_at) / 60.0), 0)::int AS total_min,
      COALESCE(SUM(CASE WHEN started_at::date = CURRENT_DATE THEN EXTRACT(epoch FROM ended_at - started_at) / 60.0 ELSE 0 END), 0)::int AS today_min
    FROM study_sessions WHERE uid = $1''',
    parameters: [uid],
  );
  final int totalStudyDays = sessionRows.isEmpty
      ? 0
      : (sessionRows.first[0] as int? ?? 0);
  final int totalMinutes = sessionRows.isEmpty
      ? 0
      : (sessionRows.first[1] as int? ?? 0);
  final int todayMinutes = sessionRows.isEmpty
      ? 0
      : (sessionRows.first[2] as int? ?? 0);

  // ── 4. 7-day XP (zero-filled) ─────────────────────────────────────────────
  final xpRows = await conn.execute(
    r'''SELECT started_at::date AS day, SUM(xp_earned)::int AS xp
    FROM study_sessions
    WHERE uid = $1 AND started_at >= CURRENT_DATE - INTERVAL '6 days'
    GROUP BY started_at::date
    ORDER BY started_at::date''',
    parameters: [uid],
  );
  // Build a map date→xp then fill all 7 days
  final xpMap = <String, int>{};
  for (final row in xpRows) {
    final day = row[0].toString().substring(0, 10); // 'YYYY-MM-DD'
    xpMap[day] = row[1] as int? ?? 0;
  }
  final sevenDayXp = List.generate(7, (i) {
    final date = DateTime.now()
        .subtract(Duration(days: 6 - i))
        .toIso8601String()
        .substring(0, 10);
    return xpMap[date] ?? 0;
  });

  // ── 5. Average accuracy from review_events ─────────────────────────────────
  final accuracyRows = await conn.execute(
    r'''SELECT COALESCE(AVG(CASE WHEN is_correct THEN 100 ELSE 0 END), 0)::int
    FROM review_events WHERE uid = $1''',
    parameters: [uid],
  );
  final int averageAccuracyPct =
      accuracyRows.isEmpty ? 0 : (accuracyRows.first[0] as int? ?? 0);

  // ── 6. Per-modality accuracy from exercise_records ────────────────────────
  final modalityRows = await conn.execute(
    r'''SELECT prompt_type,
      COUNT(*) AS attempts,
      SUM(CASE WHEN is_correct THEN 1 ELSE 0 END) AS correct
    FROM exercise_records WHERE uid = $1
    GROUP BY prompt_type
    HAVING COUNT(*) > 0''',
    parameters: [uid],
  );

  // Accumulate per-modality totals
  final modalityAttempts = <String, int>{};
  final modalityCorrect = <String, int>{};
  for (final row in modalityRows) {
    final promptType = row[0] as String? ?? '';
    final attempts = row[1] as int? ?? 0;
    final correct = row[2] as int? ?? 0;
    final modality = _promptTypeToModality(promptType);
    modalityAttempts[modality] = (modalityAttempts[modality] ?? 0) + attempts;
    modalityCorrect[modality] = (modalityCorrect[modality] ?? 0) + correct;
  }
  final modalityAccuracy = <String, int>{};
  for (final modality in ['meaning', 'listening', 'spelling', 'context']) {
    final attempts = modalityAttempts[modality] ?? 0;
    if (attempts > 0) {
      modalityAccuracy[modality] =
          (modalityCorrect[modality] ?? 0) * 100 ~/ attempts;
    }
  }

  // ── 7. Weakest exercise types / topErrorTypes ─────────────────────────────
  final errorRows = await conn.execute(
    r'''SELECT prompt_type,
      COUNT(*) AS attempts,
      SUM(CASE WHEN NOT is_correct THEN 1 ELSE 0 END) AS errors
    FROM exercise_records WHERE uid = $1
    GROUP BY prompt_type
    HAVING COUNT(*) >= 2
    ORDER BY (SUM(CASE WHEN NOT is_correct THEN 1 ELSE 0 END)::float / COUNT(*)) DESC
    LIMIT 5''',
    parameters: [uid],
  );
  final topErrorTypes =
      errorRows.map((r) => r[0] as String? ?? '').toList();
  final String weakestExerciseType =
      topErrorTypes.isNotEmpty ? topErrorTypes.first : 'spelling';

  // ── 8. Most-missed word IDs from user_words (wrong_count DESC) ────────────
  final missedRows = await conn.execute(
    r'''SELECT word_id FROM user_words
    WHERE uid = $1 AND wrong_count > 0
    ORDER BY wrong_count DESC LIMIT 5''',
    parameters: [uid],
  );
  final mostMissedWordIds =
      missedRows.map((r) => r[0] as String? ?? '').toList();

  // ── 9. Today's new words & reviews ───────────────────────────────────────
  final todayActivityRows = await conn.execute(
    r'''SELECT
      COUNT(*) FILTER (WHERE status IN ('Learning', 'Review') AND created_at::date = CURRENT_DATE) AS new_today,
      0::int AS reviews_today
    FROM user_words WHERE uid = $1''',
    parameters: [uid],
  );
  final int newWordsToday = todayActivityRows.isEmpty
      ? 0
      : (todayActivityRows.first[0] as int? ?? 0);

  final reviewsTodayRows = await conn.execute(
    r'''SELECT COUNT(*) FROM review_events
    WHERE uid = $1 AND reviewed_at::date = CURRENT_DATE''',
    parameters: [uid],
  );
  final int reviewsToday = reviewsTodayRows.isEmpty
      ? 0
      : (reviewsTodayRows.first[0] as int? ?? 0);

  return LearningAnalytics(
    streakDays: streakDays,
    totalStudyDays: totalStudyDays,
    learnedWords: learnedWords,
    masteredWords: masteredWords,
    newWordsToday: newWordsToday,
    reviewsToday: reviewsToday,
    wordbookProgressPct: wordbookProgressPct,
    todayMinutes: todayMinutes,
    totalMinutes: totalMinutes,
    averageAccuracyPct: averageAccuracyPct,
    sevenDayXp: sevenDayXp,
    weakestExerciseType: weakestExerciseType,
    mostMissedWordIds: mostMissedWordIds,
    achievementCount: 0,  // kept as 0; achievement unlocks handled separately
    trainingXp: 0,        // kept as 0; training XP is from leaderboard route
    trainingRank: -1,
    modalityAccuracy: modalityAccuracy,
    dailyXp: sevenDayXp, // same source, kept as alias for now
    topErrorTypes: topErrorTypes,
  );
}
