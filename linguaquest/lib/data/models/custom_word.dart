import '../../core/utils/spaced_repetition.dart';

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
    required this.masteryLevel,
    required this.correctCount,
    required this.wrongCount,
    required this.nextReviewAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String uid;
  final String word;
  final String meaning;
  final String exampleSentence;
  final String note;
  final String tag;
  final String difficulty;
  final int masteryLevel;
  final int correctCount;
  final int wrongCount;
  final DateTime nextReviewAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CustomWord.create({
    required String id,
    required String uid,
    required String word,
    required String meaning,
    required String exampleSentence,
    String note = '',
    String tag = 'custom',
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
      tag: tag.trim().isEmpty ? 'custom' : tag.trim(),
      difficulty: difficulty,
      masteryLevel: 0,
      correctCount: 0,
      wrongCount: 0,
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
      tag: json['tag'] as String? ?? 'custom',
      difficulty: json['difficulty'] as String? ?? 'Medium',
      masteryLevel: json['masteryLevel'] as int? ?? 0,
      correctCount: json['correctCount'] as int? ?? 0,
      wrongCount: json['wrongCount'] as int? ?? 0,
      nextReviewAt: _date(json['nextReviewAt']) ?? DateTime.now(),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      updatedAt: _date(json['updatedAt']) ?? DateTime.now(),
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
      'masteryLevel': masteryLevel,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isWeak => wrongCount > correctCount || masteryLevel <= 1;

  bool isDue(DateTime now) => !nextReviewAt.isAfter(now);

  CustomWord reviewed({required bool isCorrect, DateTime? now}) {
    final timestamp = now ?? DateTime.now();
    final nextLevel = isCorrect
        ? (masteryLevel + 1).clamp(0, 5)
        : (masteryLevel - 1).clamp(0, 5);
    return copyWith(
      masteryLevel: nextLevel,
      correctCount: correctCount + (isCorrect ? 1 : 0),
      wrongCount: wrongCount + (isCorrect ? 0 : 1),
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
    int? masteryLevel,
    int? correctCount,
    int? wrongCount,
    DateTime? nextReviewAt,
    DateTime? createdAt,
    DateTime? updatedAt,
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
      masteryLevel: masteryLevel ?? this.masteryLevel,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
