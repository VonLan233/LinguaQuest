class ReviewEvent {
  const ReviewEvent({
    required this.id,
    required this.uid,
    required this.wordId,
    required this.isCorrect,
    required this.answerTimeMs,
    required this.confidence,
    required this.reviewedAt,
    required this.masteryBefore,
    required this.masteryAfter,
    required this.nextReviewAt,
    this.wrongOption,
  });

  final String id;
  final String uid;
  final String wordId;
  final bool isCorrect;
  final int answerTimeMs;
  final int confidence;
  final String? wrongOption;
  final DateTime reviewedAt;
  final int masteryBefore;
  final int masteryAfter;
  final DateTime nextReviewAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'wordId': wordId,
      'isCorrect': isCorrect,
      'answerTimeMs': answerTimeMs,
      'confidence': confidence,
      'wrongOption': wrongOption,
      'reviewedAt': reviewedAt.toIso8601String(),
      'masteryBefore': masteryBefore,
      'masteryAfter': masteryAfter,
      'nextReviewAt': nextReviewAt.toIso8601String(),
    };
  }
}
