/// Recommendation policy — derives personalised practice suggestions from
/// per-word mastery dimension scores.
///
/// This file has **no** dependency on shelf, the database, or any I/O: it is
/// a pure-logic unit so it can be tested without infrastructure.
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

  /// The exercise type label (e.g. 'listeningWordChoice').
  final String exerciseType;

  /// A human-readable explanation for the recommendation.
  final String reason;

  /// 1 = high, 2 = medium, 3 = low.
  final int priority;

  /// Rough number of minutes expected to complete the practice set.
  final int estimatedMinutes;

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
}

class RecommendationPolicy {
  const RecommendationPolicy._();

  static const int _weakThreshold = 30;
  static const int _maxWordsPerRec = 5;

  /// Generate practice recommendations from per-word dimension scores.
  ///
  /// [wordStats] is a list of maps, each containing:
  ///   - `wordId` (String)
  ///   - `listeningScore` (int, 0-100)
  ///   - `contextScore` (int, 0-100)
  ///   - `meaningRecallScore` (int, 0-100)
  ///   - `wrongCount` (int)
  ///
  /// [studyPlanDeadline] is an ISO date string for future use (not yet used
  /// in priority calculations but kept in the API for forward-compatibility).
  static List<Recommendation> generate({
    required List<Map<String, dynamic>> wordStats,
    String studyPlanDeadline = '',
  }) {
    if (wordStats.isEmpty) return const [];

    final recs = <Recommendation>[];

    // ── Priority 1: listening weakness ───────────────────────────────────────
    final listeningWeak = wordStats
        .where((w) => (_intField(w, 'listeningScore') ?? 100) < _weakThreshold)
        .take(_maxWordsPerRec)
        .map((w) => w['wordId'] as String)
        .toList();
    if (listeningWeak.isNotEmpty) {
      recs.add(Recommendation(
        targetWordIds: listeningWeak,
        exerciseType: 'listeningWordChoice',
        reason: 'Your listening recognition for these words is weak',
        priority: 1,
        estimatedMinutes: listeningWeak.length,
      ));
    }

    // ── Priority 2: context weakness ─────────────────────────────────────────
    final contextWeak = wordStats
        .where((w) => (_intField(w, 'contextScore') ?? 100) < _weakThreshold)
        .take(_maxWordsPerRec)
        .map((w) => w['wordId'] as String)
        .toList();
    if (contextWeak.isNotEmpty) {
      recs.add(Recommendation(
        targetWordIds: contextWeak,
        exerciseType: 'sentenceCloze',
        reason: 'You struggle to use these words in context',
        priority: 2,
        estimatedMinutes: contextWeak.length,
      ));
    }

    // ── Priority 3: meaning recall weakness ──────────────────────────────────
    final meaningWeak = wordStats
        .where(
          (w) => (_intField(w, 'meaningRecallScore') ?? 100) < _weakThreshold,
        )
        .take(_maxWordsPerRec)
        .map((w) => w['wordId'] as String)
        .toList();
    if (meaningWeak.isNotEmpty) {
      recs.add(Recommendation(
        targetWordIds: meaningWeak,
        exerciseType: 'meaningChoice',
        reason: 'You have difficulty recalling the meanings of these words',
        priority: 3,
        estimatedMinutes: meaningWeak.length,
      ));
    }

    return recs;
  }

  static int? _intField(Map<String, dynamic> map, String key) {
    final v = map[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }
}
