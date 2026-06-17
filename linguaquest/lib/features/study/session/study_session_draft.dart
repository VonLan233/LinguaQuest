import '../../../data/models/custom_word.dart';
import '../../../data/models/lesson.dart';
import 'session_queue_builder.dart';

class StudySessionDraft {
  const StudySessionDraft({
    required this.uid,
    required this.mode,
    required this.startedAt,
    required this.savedAt,
    required this.completedItems,
    required this.correctAnswers,
    required this.confidence,
    required this.reviewTargetRatio,
    required this.newTargetRatio,
    required this.dueReviewCount,
    required this.newWordCount,
    required this.weakWordCount,
    required this.queue,
    required this.answerLogs,
    required this.wrongItemIds,
    required this.scheduledWrongIds,
  });

  final String uid;
  final StudySessionEntryMode mode;
  final DateTime startedAt;
  final DateTime savedAt;
  final int completedItems;
  final int correctAnswers;
  final int confidence;
  final double reviewTargetRatio;
  final double newTargetRatio;
  final int dueReviewCount;
  final int newWordCount;
  final int weakWordCount;
  final List<StudySessionQueueItem> queue;
  final List<StudyAnswerLog> answerLogs;
  final Set<String> wrongItemIds;
  final Set<String> scheduledWrongIds;

  StudySessionQueuePlan get plan {
    return StudySessionQueuePlan(
      items: List.unmodifiable(queue),
      reviewTargetRatio: reviewTargetRatio,
      newTargetRatio: newTargetRatio,
      dueReviewCount: dueReviewCount,
      newWordCount: newWordCount,
      weakWordCount: weakWordCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'mode': mode.name,
      'startedAt': startedAt.toIso8601String(),
      'savedAt': savedAt.toIso8601String(),
      'completedItems': completedItems,
      'correctAnswers': correctAnswers,
      'confidence': confidence,
      'reviewTargetRatio': reviewTargetRatio,
      'newTargetRatio': newTargetRatio,
      'dueReviewCount': dueReviewCount,
      'newWordCount': newWordCount,
      'weakWordCount': weakWordCount,
      'queue': [for (final item in queue) _queueItemToJson(item)],
      'answerLogs': [for (final log in answerLogs) log.toJson()],
      'wrongItemIds': wrongItemIds.toList(),
      'scheduledWrongIds': scheduledWrongIds.toList(),
    };
  }

  factory StudySessionDraft.fromJson(Map<String, dynamic> json) {
    return StudySessionDraft(
      uid: json['uid'] as String? ?? '',
      mode: _mode(json['mode']),
      startedAt:
          DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      savedAt:
          DateTime.tryParse(json['savedAt'] as String? ?? '') ?? DateTime.now(),
      completedItems: json['completedItems'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      confidence: json['confidence'] as int? ?? 3,
      reviewTargetRatio: _double(json['reviewTargetRatio']),
      newTargetRatio: _double(json['newTargetRatio']),
      dueReviewCount: json['dueReviewCount'] as int? ?? 0,
      newWordCount: json['newWordCount'] as int? ?? 0,
      weakWordCount: json['weakWordCount'] as int? ?? 0,
      queue: [
        for (final item in json['queue'] as List? ?? const [])
          if (item is Map) _queueItemFromJson(Map<String, dynamic>.from(item)),
      ],
      answerLogs: [
        for (final item in json['answerLogs'] as List? ?? const [])
          if (item is Map) _answerLogFromJson(Map<String, dynamic>.from(item)),
      ],
      wrongItemIds: {
        for (final id in json['wrongItemIds'] as List? ?? const [])
          if (id is String) id,
      },
      scheduledWrongIds: {
        for (final id in json['scheduledWrongIds'] as List? ?? const [])
          if (id is String) id,
      },
    );
  }
}

Map<String, dynamic> _queueItemToJson(StudySessionQueueItem item) {
  return {
    'id': item.id,
    'wordId': item.wordId,
    'source': item.source.name,
    'step': item.step.name,
    'attempt': item.attempt,
    'affectsSchedule': item.affectsSchedule,
    'lessonWord': item.lessonWord?.toJson(),
    'customWord': item.customWord?.toJson(),
  };
}

StudySessionQueueItem _queueItemFromJson(Map<String, dynamic> json) {
  final lessonWordJson = json['lessonWord'];
  final customWordJson = json['customWord'];
  return StudySessionQueueItem(
    id: json['id'] as String? ?? '',
    wordId: json['wordId'] as String? ?? '',
    source: _source(json['source']),
    step: _step(json['step']),
    attempt: json['attempt'] as int? ?? 0,
    affectsSchedule: json['affectsSchedule'] as bool? ?? false,
    lessonWord: lessonWordJson is Map
        ? Word.fromJson(Map<String, dynamic>.from(lessonWordJson))
        : null,
    customWord: customWordJson is Map
        ? CustomWord.fromJson(Map<String, dynamic>.from(customWordJson))
        : null,
  );
}

StudyAnswerLog _answerLogFromJson(Map<String, dynamic> json) {
  return StudyAnswerLog(
    itemId: json['itemId'] as String? ?? '',
    wordId: json['wordId'] as String? ?? '',
    source: _source(json['source']),
    step: _step(json['step']),
    isCorrect: json['isCorrect'] as bool? ?? false,
    responseTimeMs: json['responseTimeMs'] as int? ?? 0,
    confidence: json['confidence'] as int? ?? 3,
    selectedAnswer: json['selectedAnswer'] as String? ?? '',
    wrongOption: json['wrongOption'] as String?,
    answeredAt:
        DateTime.tryParse(json['answeredAt'] as String? ?? '') ??
        DateTime.now(),
  );
}

StudySessionEntryMode _mode(Object? value) {
  return StudySessionEntryMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => StudySessionEntryMode.mixed,
  );
}

StudySessionItemSource _source(Object? value) {
  return StudySessionItemSource.values.firstWhere(
    (source) => source.name == value,
    orElse: () => StudySessionItemSource.newWord,
  );
}

StudySessionStep _step(Object? value) {
  return StudySessionStep.values.firstWhere(
    (step) => step.name == value,
    orElse: () => StudySessionStep.understanding,
  );
}

double _double(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
