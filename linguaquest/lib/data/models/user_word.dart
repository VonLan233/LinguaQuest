import '../../core/utils/spaced_repetition.dart';
import 'custom_word.dart';
import 'lesson.dart';

const _isInNewWordbookJsonKey =
    'isInNew'
    'Word'
    'Book';

const userWordStatuses = <String>{
  'New',
  'Previewed',
  'Learning',
  'Review',
  'Relearning',
  'Mastered',
  'Ignored',
};

class UserWord {
  const UserWord({
    required this.id,
    required this.uid,
    required this.wordId,
    required this.wordBookId,
    required this.word,
    required this.meaning,
    required this.exampleSentence,
    required this.difficulty,
    required this.status,
    required this.isFavorite,
    required this.isInNewWordbook,
    required this.isIgnored,
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
    required this.lastReviewedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String uid;
  final String wordId;
  final String wordBookId;
  final String word;
  final String meaning;
  final String exampleSentence;
  final String difficulty;
  final String status;
  final bool isFavorite;
  final bool isInNewWordbook;
  final bool isIgnored;
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
  final DateTime? lastReviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserWord.create({
    required String uid,
    required Word word,
    required String wordBookId,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return UserWord(
      id: 'user-word-$uid-${word.id}',
      uid: uid,
      wordId: word.id,
      wordBookId: wordBookId,
      word: word.word,
      meaning: word.meaning,
      exampleSentence: word.exampleSentence,
      difficulty: word.difficulty,
      status: 'New',
      isFavorite: false,
      isInNewWordbook: false,
      isIgnored: false,
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
      lastReviewedAt: null,
      createdAt: timestamp,
      updatedAt: timestamp,
    );
  }

  factory UserWord.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? 'New';
    return UserWord(
      id: json['id'] as String,
      uid: json['uid'] as String? ?? json['userId'] as String? ?? '',
      wordId: json['wordId'] as String,
      wordBookId: json['wordBookId'] as String? ?? '',
      word: json['word'] as String? ?? json['wordId'] as String,
      meaning: json['meaning'] as String? ?? '',
      exampleSentence: json['exampleSentence'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      status: userWordStatuses.contains(status) ? status : 'New',
      isFavorite: json['isFavorite'] as bool? ?? false,
      isInNewWordbook: json[_isInNewWordbookJsonKey] as bool? ?? false,
      isIgnored: json['isIgnored'] as bool? ?? status == 'Ignored',
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
      lastReviewedAt: _date(json['lastReviewedAt']),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'wordId': wordId,
      'wordBookId': wordBookId,
      'word': word,
      'meaning': meaning,
      'exampleSentence': exampleSentence,
      'difficulty': difficulty,
      'status': status,
      'isFavorite': isFavorite,
      _isInNewWordbookJsonKey: isInNewWordbook,
      'isIgnored': isIgnored,
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
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// A word is "weak" only when the learner has actually struggled with it —
  /// it is being relearned, or has been missed at least as often as recalled.
  /// A freshly learned word answered correctly (masteryLevel 0→1, wrongCount 0)
  /// must NOT count as weak, otherwise the mistake book fills with every studied
  /// word regardless of correctness.
  bool get isWeak => status == 'Relearning' || wrongCount > correctCount;

  bool isDue(DateTime now) {
    if (isIgnored || status == 'Ignored') return false;
    return !nextReviewAt.isAfter(now);
  }

  /// Builds the review-queue [CustomWord] for this target word. When [source]
  /// (the dictionary word this progress row tracks) is provided, its per-language
  /// definition lists are carried onto the card so the meaning localizes to the
  /// app language instead of only showing the Chinese [meaning].
  CustomWord toReviewCard({Word? source}) {
    return CustomWord(
      id: reviewCardId,
      uid: uid,
      word: word,
      meaning: meaning,
      definitions: source?.definitions ?? const [],
      englishDefinitions: source?.englishDefinitions ?? const [],
      localizedDefinitions: source?.localizedDefinitions ?? const {},
      malayDefinitions: source?.malayDefinitions ?? const [],
      exampleSentence: exampleSentence,
      note: 'Target word · $wordBookId',
      tag: isInNewWordbook ? 'Custom words' : 'Target word',
      difficulty: difficulty,
      status: status,
      easeFactor: easeFactor,
      intervalDays: intervalDays,
      repetitionCount: repetitionCount,
      lapseCount: lapseCount,
      masteryLevel: masteryLevel,
      correctCount: correctCount,
      wrongCount: wrongCount,
      meaningRecognitionScore: meaningRecognitionScore,
      meaningRecallScore: meaningRecallScore,
      spellingScore: spellingScore,
      listeningScore: listeningScore,
      contextScore: contextScore,
      confidenceScore: confidenceScore,
      nextReviewAt: nextReviewAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      source: 'target',
      sourceWordId: wordId,
      wordBookId: wordBookId,
      isFavorite: isFavorite,
      isInNewWordbook: isInNewWordbook,
      isIgnored: isIgnored,
      lastReviewedAt: lastReviewedAt,
    );
  }

  String get reviewCardId => 'target:$wordId';

  UserWord reviewed({
    required bool isCorrect,
    DateTime? now,
    ReviewDimension dimension = ReviewDimension.confidence,
  }) {
    final timestamp = now ?? DateTime.now();
    final nextLevel = isCorrect
        ? (masteryLevel + 1).clamp(0, 5)
        : (masteryLevel - 1).clamp(0, 5);
    final nextEase = (easeFactor + (isCorrect ? 0.1 : -0.2))
        .clamp(1.3, 3.0)
        .toDouble();
    final interval = isCorrect ? _nextIntervalDays(nextLevel, nextEase) : 0;
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
      nextReviewAt: isCorrect
          ? timestamp.add(Duration(days: interval))
          : nextReviewDateForLevel(0, timestamp),
      lastReviewedAt: timestamp,
      updatedAt: timestamp,
    );
  }

  UserWord learned({required bool hadMistake, DateTime? now}) {
    return reviewed(
      isCorrect: !hadMistake,
      now: now,
      dimension: hadMistake
          ? ReviewDimension.meaningRecognition
          : ReviewDimension.context,
    );
  }

  UserWord copyWith({
    String? id,
    String? uid,
    String? wordId,
    String? wordBookId,
    String? word,
    String? meaning,
    String? exampleSentence,
    String? difficulty,
    String? status,
    bool? isFavorite,
    bool? isInNewWordbook,
    bool? isIgnored,
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
    DateTime? lastReviewedAt,
    bool clearLastReviewedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserWord(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      wordId: wordId ?? this.wordId,
      wordBookId: wordBookId ?? this.wordBookId,
      word: word ?? this.word,
      meaning: meaning ?? this.meaning,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
      isInNewWordbook: isInNewWordbook ?? this.isInNewWordbook,
      isIgnored: isIgnored ?? this.isIgnored,
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
      lastReviewedAt: clearLastReviewedAt
          ? null
          : lastReviewedAt ?? this.lastReviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int _nextIntervalDays(int masteryLevel, double easeFactor) {
    final base = reviewIntervalForLevel(masteryLevel).inDays;
    if (base <= 1) return base;
    return (base * (easeFactor / 2.5)).round().clamp(1, 60).toInt();
  }

  static String _statusForMastery(int mastery) {
    if (mastery >= 5) return 'Mastered';
    if (mastery >= 1) return 'Review';
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
}
