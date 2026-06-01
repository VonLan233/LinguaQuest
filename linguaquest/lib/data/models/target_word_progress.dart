import '../../core/utils/spaced_repetition.dart';
import 'custom_word.dart';

class TargetWordProgress {
  const TargetWordProgress({
    required this.wordId,
    required this.wordBookId,
    required this.status,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitionCount,
    required this.lapseCount,
    required this.correctCount,
    required this.wrongCount,
    required this.meaningRecognitionScore,
    required this.meaningRecallScore,
    required this.spellingScore,
    required this.listeningScore,
    required this.contextScore,
    required this.confidenceScore,
    required this.nextReviewAt,
    this.lastReviewedAt,
  });

  final String wordId;
  final String wordBookId;
  final String status;
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final int lapseCount;
  final int correctCount;
  final int wrongCount;
  final int meaningRecognitionScore;
  final int meaningRecallScore;
  final int spellingScore;
  final int listeningScore;
  final int contextScore;
  final int confidenceScore;
  final DateTime nextReviewAt;
  final DateTime? lastReviewedAt;

  factory TargetWordProgress.newWord({
    required String wordId,
    required String wordBookId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return TargetWordProgress(
      wordId: wordId,
      wordBookId: wordBookId,
      status: 'New',
      easeFactor: 2.5,
      intervalDays: 0,
      repetitionCount: 0,
      lapseCount: 0,
      correctCount: 0,
      wrongCount: 0,
      meaningRecognitionScore: 0,
      meaningRecallScore: 0,
      spellingScore: 0,
      listeningScore: 0,
      contextScore: 0,
      confidenceScore: 0,
      nextReviewAt: timestamp,
    );
  }

  factory TargetWordProgress.fromJson(Map<String, dynamic> json) {
    return TargetWordProgress(
      wordId: json['wordId'] as String,
      wordBookId: json['wordBookId'] as String? ?? '',
      status: json['status'] as String? ?? 'New',
      easeFactor: _double(json['easeFactor']) ?? 2.5,
      intervalDays: _int(json['intervalDays']) ?? 0,
      repetitionCount: _int(json['repetitionCount']) ?? 0,
      lapseCount: _int(json['lapseCount']) ?? 0,
      correctCount: _int(json['correctCount']) ?? 0,
      wrongCount: _int(json['wrongCount']) ?? 0,
      meaningRecognitionScore: _int(json['meaningRecognitionScore']) ?? 0,
      meaningRecallScore: _int(json['meaningRecallScore']) ?? 0,
      spellingScore: _int(json['spellingScore']) ?? 0,
      listeningScore: _int(json['listeningScore']) ?? 0,
      contextScore: _int(json['contextScore']) ?? 0,
      confidenceScore: _int(json['confidenceScore']) ?? 0,
      nextReviewAt: _date(json['nextReviewAt']) ?? DateTime.now(),
      lastReviewedAt: _date(json['lastReviewedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wordId': wordId,
      'wordBookId': wordBookId,
      'status': status,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'repetitionCount': repetitionCount,
      'lapseCount': lapseCount,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'meaningRecognitionScore': meaningRecognitionScore,
      'meaningRecallScore': meaningRecallScore,
      'spellingScore': spellingScore,
      'listeningScore': listeningScore,
      'contextScore': contextScore,
      'confidenceScore': confidenceScore,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  int get masteryLevel {
    final average =
        (meaningRecognitionScore +
            meaningRecallScore +
            spellingScore +
            listeningScore +
            contextScore +
            confidenceScore) ~/
        6;
    return (average / 20).round().clamp(0, 5).toInt();
  }

  bool get isLearned => status != 'New' && status != 'Ignored';

  bool get isWeak =>
      status == 'Relearning' || wrongCount > correctCount || masteryLevel <= 1;

  bool isDue(DateTime now) {
    return (status == 'Review' || status == 'Relearning') &&
        !nextReviewAt.isAfter(now);
  }

  TargetWordProgress reviewed({
    required bool isCorrect,
    required ReviewDimension dimension,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final nextLevel = isCorrect
        ? (masteryLevel + 1).clamp(0, 5).toInt()
        : (masteryLevel - 1).clamp(0, 5).toInt();
    final interval = isCorrect ? reviewIntervalForLevel(nextLevel).inDays : 1;
    final nextEase = (easeFactor + (isCorrect ? 0.1 : -0.2))
        .clamp(1.3, 3.0)
        .toDouble();
    return copyWith(
      status: isCorrect ? _statusForMastery(nextLevel) : 'Relearning',
      easeFactor: nextEase,
      intervalDays: interval,
      repetitionCount: isCorrect ? repetitionCount + 1 : 0,
      lapseCount: lapseCount + (isCorrect ? 0 : 1),
      correctCount: correctCount + (isCorrect ? 1 : 0),
      wrongCount: wrongCount + (isCorrect ? 0 : 1),
      meaningRecognitionScore: _scoreForDimension(
        ReviewDimension.meaningRecognition,
        dimension,
        meaningRecognitionScore,
        isCorrect,
      ),
      meaningRecallScore: _scoreForDimension(
        ReviewDimension.meaningRecall,
        dimension,
        meaningRecallScore,
        isCorrect,
      ),
      spellingScore: _scoreForDimension(
        ReviewDimension.spelling,
        dimension,
        spellingScore,
        isCorrect,
      ),
      listeningScore: _scoreForDimension(
        ReviewDimension.listening,
        dimension,
        listeningScore,
        isCorrect,
      ),
      contextScore: _scoreForDimension(
        ReviewDimension.context,
        dimension,
        contextScore,
        isCorrect,
      ),
      confidenceScore: _scoreForDimension(
        ReviewDimension.confidence,
        dimension,
        confidenceScore,
        isCorrect,
      ),
      nextReviewAt: timestamp.add(Duration(days: interval)),
      lastReviewedAt: timestamp,
    );
  }

  TargetWordProgress learnedToday({
    required bool hadMistake,
    required DateTime now,
  }) {
    return reviewed(
      isCorrect: !hadMistake,
      dimension: ReviewDimension.context,
      now: now,
    ).copyWith(
      status: hadMistake ? 'Relearning' : 'Review',
      nextReviewAt: hadMistake ? now : now.add(const Duration(days: 1)),
    );
  }

  TargetWordProgress copyWith({
    String? status,
    double? easeFactor,
    int? intervalDays,
    int? repetitionCount,
    int? lapseCount,
    int? correctCount,
    int? wrongCount,
    int? meaningRecognitionScore,
    int? meaningRecallScore,
    int? spellingScore,
    int? listeningScore,
    int? contextScore,
    int? confidenceScore,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
  }) {
    return TargetWordProgress(
      wordId: wordId,
      wordBookId: wordBookId,
      status: status ?? this.status,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      lapseCount: lapseCount ?? this.lapseCount,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      meaningRecognitionScore:
          meaningRecognitionScore ?? this.meaningRecognitionScore,
      meaningRecallScore: meaningRecallScore ?? this.meaningRecallScore,
      spellingScore: spellingScore ?? this.spellingScore,
      listeningScore: listeningScore ?? this.listeningScore,
      contextScore: contextScore ?? this.contextScore,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  static String _statusForMastery(int mastery) {
    if (mastery >= 5) return 'Mastered';
    return 'Review';
  }

  static int _scoreForDimension(
    ReviewDimension scoreDimension,
    ReviewDimension reviewDimension,
    int score,
    bool isCorrect,
  ) {
    if (scoreDimension != reviewDimension) return score;
    return (score + (isCorrect ? 24 : -18)).clamp(0, 100).toInt();
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static double? _double(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _int(Object? value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString());
  }
}
