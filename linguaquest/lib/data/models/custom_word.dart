import '../../core/utils/spaced_repetition.dart';

const _isInNewWordbookJsonKey =
    'isInNew'
    'Word'
    'Book';

enum ReviewDimension {
  meaningRecognition,
  meaningRecall,
  spelling,
  listening,
  context,
  confidence,
}

class CustomWord {
  const CustomWord({
    required this.id,
    required this.uid,
    required this.word,
    required this.meaning,
    required this.exampleSentence,
    required this.note,
    required this.tag,
    required this.difficulty,
    required this.status,
    required this.easeFactor,
    required this.intervalDays,
    required this.repetitionCount,
    required this.lapseCount,
    required this.masteryLevel,
    required this.correctCount,
    required this.wrongCount,
    required this.meaningRecognitionScore,
    required this.meaningRecallScore,
    required this.spellingScore,
    required this.listeningScore,
    required this.contextScore,
    required this.confidenceScore,
    required this.nextReviewAt,
    required this.createdAt,
    required this.updatedAt,
    this.source = 'custom',
    this.sourceWordId,
    this.wordBookId,
    this.isFavorite = false,
    this.isInNewWordbook = false,
    this.isIgnored = false,
    this.lastReviewedAt,
  });

  final String id;
  final String uid;
  final String word;
  final String meaning;
  final String exampleSentence;
  final String note;
  final String tag;
  final String difficulty;
  final String status;
  final double easeFactor;
  final int intervalDays;
  final int repetitionCount;
  final int lapseCount;
  final int masteryLevel;
  final int correctCount;
  final int wrongCount;
  final int meaningRecognitionScore;
  final int meaningRecallScore;
  final int spellingScore;
  final int listeningScore;
  final int contextScore;
  final int confidenceScore;
  final DateTime nextReviewAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String source;
  final String? sourceWordId;
  final String? wordBookId;
  final bool isFavorite;
  final bool isInNewWordbook;
  final bool isIgnored;
  final DateTime? lastReviewedAt;

  factory CustomWord.create({
    required String id,
    required String uid,
    required String word,
    required String meaning,
    required String exampleSentence,
    String note = '',
    String tag = '自定义',
    String difficulty = 'Medium',
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return CustomWord(
      id: id,
      uid: uid,
      word: word.trim(),
      meaning: meaning.trim(),
      exampleSentence: exampleSentence.trim(),
      note: note.trim(),
      tag: tag.trim().isEmpty ? '自定义' : tag.trim(),
      difficulty: difficulty,
      status: 'Learning',
      easeFactor: 2.5,
      intervalDays: 0,
      repetitionCount: 0,
      lapseCount: 0,
      masteryLevel: 0,
      correctCount: 0,
      wrongCount: 0,
      meaningRecognitionScore: 20,
      meaningRecallScore: 10,
      spellingScore: 10,
      listeningScore: 10,
      contextScore: 10,
      confidenceScore: 10,
      nextReviewAt: timestamp,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory CustomWord.fromJson(Map<String, dynamic> json) {
    return CustomWord(
      id: json['id'] as String,
      uid: json['uid'] as String,
      word: json['word'] as String,
      meaning: json['meaning'] as String,
      exampleSentence: json['exampleSentence'] as String? ?? '',
      note: json['note'] as String? ?? '',
      tag: json['tag'] as String? ?? '自定义',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      status: json['status'] as String? ?? _statusFromMastery(json),
      easeFactor: _double(json['easeFactor']) ?? 2.5,
      intervalDays: _int(json['intervalDays']) ?? 0,
      repetitionCount: _int(json['repetitionCount']) ?? 0,
      lapseCount: _int(json['lapseCount']) ?? 0,
      masteryLevel: _int(json['masteryLevel']) ?? 0,
      correctCount: _int(json['correctCount']) ?? 0,
      wrongCount: _int(json['wrongCount']) ?? 0,
      meaningRecognitionScore:
          _int(json['meaningRecognitionScore']) ?? _scoreFromMastery(json),
      meaningRecallScore:
          _int(json['meaningRecallScore']) ?? _scoreFromMastery(json),
      spellingScore: _int(json['spellingScore']) ?? _scoreFromMastery(json),
      listeningScore: _int(json['listeningScore']) ?? _scoreFromMastery(json),
      contextScore: _int(json['contextScore']) ?? _scoreFromMastery(json),
      confidenceScore: _int(json['confidenceScore']) ?? _scoreFromMastery(json),
      nextReviewAt: _date(json['nextReviewAt']) ?? DateTime.now(),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
      source: json['source'] as String? ?? 'custom',
      sourceWordId: json['sourceWordId'] as String?,
      wordBookId: json['wordBookId'] as String?,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isInNewWordbook: json[_isInNewWordbookJsonKey] as bool? ?? false,
      isIgnored: json['isIgnored'] as bool? ?? false,
      lastReviewedAt: _date(json['lastReviewedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'word': word,
      'meaning': meaning,
      'exampleSentence': exampleSentence,
      'note': note,
      'tag': tag,
      'difficulty': difficulty,
      'status': status,
      'easeFactor': easeFactor,
      'intervalDays': intervalDays,
      'repetitionCount': repetitionCount,
      'lapseCount': lapseCount,
      'masteryLevel': masteryLevel,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'meaningRecognitionScore': meaningRecognitionScore,
      'meaningRecallScore': meaningRecallScore,
      'spellingScore': spellingScore,
      'listeningScore': listeningScore,
      'contextScore': contextScore,
      'confidenceScore': confidenceScore,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'source': source,
      'sourceWordId': sourceWordId,
      'wordBookId': wordBookId,
      'isFavorite': isFavorite,
      _isInNewWordbookJsonKey: isInNewWordbook,
      'isIgnored': isIgnored,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
    };
  }

  int get averageMasteryScore {
    return (meaningRecognitionScore +
            meaningRecallScore +
            spellingScore +
            listeningScore +
            contextScore +
            confidenceScore) ~/
        6;
  }

  bool get isWeak =>
      status == 'Relearning' || wrongCount > correctCount || masteryLevel <= 1;

  bool isDue(DateTime now) {
    if (isIgnored || status == 'Ignored') return false;
    return !nextReviewAt.isAfter(now);
  }

  CustomWord reviewed({
    required bool isCorrect,
    DateTime? now,
    ReviewDimension dimension = ReviewDimension.confidence,
  }) {
    final timestamp = now ?? DateTime.now();
    final nextLevel = isCorrect
        ? (masteryLevel + 1).clamp(0, 5)
        : (masteryLevel - 1).clamp(0, 5);
    final interval = reviewIntervalForLevel(nextLevel).inDays;
    final nextEase = (easeFactor + (isCorrect ? 0.1 : -0.2))
        .clamp(1.3, 3.0)
        .toDouble();
    return copyWith(
      status: isCorrect ? _statusForMastery(nextLevel) : 'Relearning',
      easeFactor: nextEase,
      intervalDays: interval,
      repetitionCount: isCorrect ? repetitionCount + 1 : 0,
      lapseCount: lapseCount + (isCorrect ? 0 : 1),
      masteryLevel: nextLevel,
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
      nextReviewAt: nextReviewDateForLevel(nextLevel, timestamp),
      updatedAt: timestamp,
    );
  }

  CustomWord copyWith({
    String? id,
    String? uid,
    String? word,
    String? meaning,
    String? exampleSentence,
    String? note,
    String? tag,
    String? difficulty,
    String? status,
    double? easeFactor,
    int? intervalDays,
    int? repetitionCount,
    int? lapseCount,
    int? masteryLevel,
    int? correctCount,
    int? wrongCount,
    int? meaningRecognitionScore,
    int? meaningRecallScore,
    int? spellingScore,
    int? listeningScore,
    int? contextScore,
    int? confidenceScore,
    DateTime? nextReviewAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? source,
    String? sourceWordId,
    String? wordBookId,
    bool? isFavorite,
    bool? isInNewWordbook,
    bool? isIgnored,
    DateTime? lastReviewedAt,
    bool clearLastReviewedAt = false,
  }) {
    return CustomWord(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      note: note ?? this.note,
      tag: tag ?? this.tag,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      lapseCount: lapseCount ?? this.lapseCount,
      masteryLevel: masteryLevel ?? this.masteryLevel,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      source: source ?? this.source,
      sourceWordId: sourceWordId ?? this.sourceWordId,
      wordBookId: wordBookId ?? this.wordBookId,
      isFavorite: isFavorite ?? this.isFavorite,
      isInNewWordbook: isInNewWordbook ?? this.isInNewWordbook,
      isIgnored: isIgnored ?? this.isIgnored,
      lastReviewedAt: clearLastReviewedAt
          ? null
          : lastReviewedAt ?? this.lastReviewedAt,
    );
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

  static int _scoreFromMastery(Map<String, dynamic> json) {
    final mastery = _int(json['masteryLevel']) ?? 0;
    return (mastery * 20).clamp(0, 100).toInt();
  }

  static String _statusFromMastery(Map<String, dynamic> json) {
    final mastery = _int(json['masteryLevel']) ?? 0;
    return _statusForMastery(mastery);
  }

  static String _statusForMastery(int mastery) {
    if (mastery >= 5) return 'Mastered';
    if (mastery >= 2) return 'Review';
    return 'Learning';
  }

  static int _adjustScore(int score, bool isCorrect) {
    return (score + (isCorrect ? 12 : -18)).clamp(0, 100).toInt();
  }

  static int _scoreForDimension(
    ReviewDimension scoreDimension,
    ReviewDimension reviewDimension,
    int score,
    bool isCorrect,
  ) {
    if (scoreDimension != reviewDimension) return score;
    return _adjustScore(score, isCorrect);
  }
}
