import '../../../data/models/custom_word.dart';
import '../../../data/models/lesson.dart';

enum StudySessionEntryMode { mixed, newOnly, reviewOnly }

enum StudySessionItemSource { newWord, dueReview, weakReview }

enum StudySessionStep {
  understanding,
  recognition,
  shortRecall,
  reviewRecall,
  knowledgeCard,
}

enum StudySelfAssessment { known, fuzzy, unknown }

class StudySessionQueueItem {
  const StudySessionQueueItem({
    required this.id,
    required this.wordId,
    required this.source,
    required this.step,
    required this.attempt,
    required this.affectsSchedule,
    this.lessonWord,
    this.customWord,
  }) : assert(lessonWord != null || customWord != null);

  final String id;
  final String wordId;
  final StudySessionItemSource source;
  final StudySessionStep step;
  final Word? lessonWord;
  final CustomWord? customWord;
  final int attempt;
  final bool affectsSchedule;

  bool get isNewWord => source == StudySessionItemSource.newWord;

  bool get isReview => !isNewWord;

  bool get isKnowledgeCard => step == StudySessionStep.knowledgeCard;

  String get displayWord => lessonWord?.word ?? customWord!.word;

  String get meaning => lessonWord?.meaning ?? customWord!.meaning;

  String get exampleSentence =>
      lessonWord?.exampleSentence ?? customWord!.exampleSentence;

  String get difficulty => lessonWord?.difficulty ?? customWord!.difficulty;

  String get imageCue => lessonWord?.imageCue ?? _initialCue(displayWord);

  StudySessionQueueItem copyWith({
    StudySessionStep? step,
    int? attempt,
    bool? affectsSchedule,
  }) {
    return StudySessionQueueItem(
      id: id,
      wordId: wordId,
      source: source,
      step: step ?? this.step,
      lessonWord: lessonWord,
      customWord: customWord,
      attempt: attempt ?? this.attempt,
      affectsSchedule: affectsSchedule ?? this.affectsSchedule,
    );
  }
}

class StudySessionQueuePlan {
  const StudySessionQueuePlan({
    required this.items,
    required this.reviewTargetRatio,
    required this.newTargetRatio,
    required this.dueReviewCount,
    required this.newWordCount,
    required this.weakWordCount,
  });

  final List<StudySessionQueueItem> items;
  final double reviewTargetRatio;
  final double newTargetRatio;
  final int dueReviewCount;
  final int newWordCount;
  final int weakWordCount;
}

class StudyAnswerLog {
  const StudyAnswerLog({
    required this.itemId,
    required this.wordId,
    required this.source,
    required this.step,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.confidence,
    required this.selectedAnswer,
    required this.answeredAt,
    this.wrongOption,
  });

  final String itemId;
  final String wordId;
  final StudySessionItemSource source;
  final StudySessionStep step;
  final bool isCorrect;
  final int responseTimeMs;
  final int confidence;
  final String selectedAnswer;
  final String? wrongOption;
  final DateTime answeredAt;

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'wordId': wordId,
      'source': source.name,
      'step': step.name,
      'isCorrect': isCorrect,
      'responseTimeMs': responseTimeMs,
      'confidence': confidence,
      'selectedAnswer': selectedAnswer,
      'wrongOption': wrongOption,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}

class StudySessionQueueBuilder {
  const StudySessionQueueBuilder();

  StudySessionQueuePlan build({
    required List<Word> newWords,
    required List<CustomWord> dueWords,
    required List<CustomWord> weakWords,
    required int dailyGoal,
    StudySessionEntryMode mode = StudySessionEntryMode.mixed,
  }) {
    final goal = dailyGoal.clamp(1, 999).toInt();
    final due = [...dueWords]..sort(_priorityCustomWordSort);
    final weak = _uniqueWeakWords(weakWords, due);
    final fresh = newWords.take(goal).toList();
    final ratio = _ratioFor(due.length, fresh.length, mode);
    final reviewTarget = (goal * ratio.$1).round().clamp(0, goal).toInt();
    final newTarget = (goal - reviewTarget).clamp(0, goal).toInt();
    final selectedDue = mode == StudySessionEntryMode.newOnly
        ? <CustomWord>[]
        : due.take(reviewTarget == 0 ? due.length.clamp(0, 4) : reviewTarget);
    final selectedNew = mode == StudySessionEntryMode.reviewOnly
        ? <Word>[]
        : fresh.take(newTarget == 0 ? fresh.length : newTarget);

    final items = <StudySessionQueueItem>[];
    final dueQueue = selectedDue.toList();
    final newQueue = selectedNew.toList();
    final selectedWeakCount = weak.length < 3 ? weak.length : 3;
    final weakQueue = weak.take(selectedWeakCount).toList();

    for (var i = 0; i < dueQueue.length && i < 4; i++) {
      items.add(_reviewItem(dueQueue[i], StudySessionItemSource.dueReview));
    }
    dueQueue.removeRange(0, dueQueue.length < 4 ? dueQueue.length : 4);

    var newSinceReview = 0;
    while (dueQueue.isNotEmpty || newQueue.isNotEmpty || weakQueue.isNotEmpty) {
      if (dueQueue.isNotEmpty &&
          (items.isEmpty ||
              newSinceReview >= 2 ||
              _reviewShareBelow(items, ratio.$1))) {
        items.add(
          _reviewItem(dueQueue.removeAt(0), StudySessionItemSource.dueReview),
        );
        newSinceReview = 0;
        continue;
      }
      if (newQueue.isNotEmpty) {
        final word = newQueue.removeAt(0);
        items.addAll(_newWordItems(word));
        newSinceReview += 1;
        continue;
      }
      if (weakQueue.isNotEmpty) {
        items.add(
          _reviewItem(weakQueue.removeAt(0), StudySessionItemSource.weakReview),
        );
        newSinceReview = 0;
        continue;
      }
      if (dueQueue.isNotEmpty) {
        items.add(
          _reviewItem(dueQueue.removeAt(0), StudySessionItemSource.dueReview),
        );
      }
    }

    return StudySessionQueuePlan(
      items: List.unmodifiable(_spaceShortRecall(items)),
      reviewTargetRatio: ratio.$1,
      newTargetRatio: ratio.$2,
      dueReviewCount: selectedDue.length,
      newWordCount: selectedNew.length,
      weakWordCount: selectedWeakCount,
    );
  }

  List<StudySessionQueueItem> requeueWrongAnswer(
    List<StudySessionQueueItem> queue,
    StudySessionQueueItem item, {
    int answeredCount = 0,
  }) {
    final updated = [
      for (final queued in queue)
        if (queued.wordId != item.wordId) queued,
    ];
    final knowledge = item.copyWith(
      step: StudySessionStep.knowledgeCard,
      affectsSchedule: false,
    );
    final recall = item.copyWith(
      attempt: item.attempt + 1,
      step: item.isNewWord
          ? StudySessionStep.shortRecall
          : StudySessionStep.reviewRecall,
      affectsSchedule: false,
    );
    updated.insert(0, knowledge);
    final delay = 3 + (answeredCount % 4);
    final insertIndex = delay.clamp(1, updated.length).toInt();
    updated.insert(insertIndex, recall);
    updated.add(recall.copyWith(attempt: recall.attempt + 1));
    return List.unmodifiable(updated);
  }

  (double, double) _ratioFor(
    int dueCount,
    int newCount,
    StudySessionEntryMode mode,
  ) {
    if (mode == StudySessionEntryMode.newOnly) return (0.0, 1.0);
    if (mode == StudySessionEntryMode.reviewOnly) return (1.0, 0.0);
    if (dueCount == 0) return (0.0, 1.0);
    if (dueCount >= newCount * 2 && dueCount >= 6) return (0.7, 0.3);
    if (dueCount >= 3) return (0.5, 0.5);
    return (0.3, 0.7);
  }

  List<StudySessionQueueItem> _newWordItems(Word word) {
    return [
      StudySessionQueueItem(
        id: '${word.id}:understanding',
        wordId: word.id,
        source: StudySessionItemSource.newWord,
        step: StudySessionStep.understanding,
        lessonWord: word,
        attempt: 1,
        affectsSchedule: false,
      ),
      StudySessionQueueItem(
        id: '${word.id}:recognition',
        wordId: word.id,
        source: StudySessionItemSource.newWord,
        step: StudySessionStep.recognition,
        lessonWord: word,
        attempt: 1,
        affectsSchedule: true,
      ),
      StudySessionQueueItem(
        id: '${word.id}:shortRecall',
        wordId: word.id,
        source: StudySessionItemSource.newWord,
        step: StudySessionStep.shortRecall,
        lessonWord: word,
        attempt: 1,
        affectsSchedule: false,
      ),
    ];
  }

  StudySessionQueueItem _reviewItem(
    CustomWord word,
    StudySessionItemSource source,
  ) {
    return StudySessionQueueItem(
      id: '${word.id}:review',
      wordId: word.id,
      source: source,
      step: StudySessionStep.reviewRecall,
      customWord: word,
      attempt: 1,
      affectsSchedule: true,
    );
  }

  List<StudySessionQueueItem> _spaceShortRecall(
    List<StudySessionQueueItem> items,
  ) {
    final arranged = <StudySessionQueueItem>[];
    final delayed = <StudySessionQueueItem>[];
    for (final item in items) {
      if (item.step == StudySessionStep.shortRecall) {
        delayed.add(item);
        continue;
      }
      arranged.add(item);
      if (arranged.length % 5 == 0 && delayed.isNotEmpty) {
        arranged.add(delayed.removeAt(0));
      }
    }
    return [...arranged, ...delayed];
  }

  bool _reviewShareBelow(List<StudySessionQueueItem> items, double target) {
    if (items.isEmpty) return true;
    final reviewCount = items.where((item) => item.isReview).length;
    return reviewCount / items.length < target;
  }

  List<CustomWord> _uniqueWeakWords(
    List<CustomWord> weakWords,
    List<CustomWord> dueWords,
  ) {
    final dueIds = dueWords.map((word) => word.id).toSet();
    final result = <CustomWord>[];
    final addedIds = <String>{};
    for (final word in weakWords) {
      if (dueIds.contains(word.id)) continue;
      if (addedIds.add(word.id)) result.add(word);
    }
    return result..sort(_priorityCustomWordSort);
  }

  int _priorityCustomWordSort(CustomWord a, CustomWord b) {
    final weakCompare = b.wrongCount.compareTo(a.wrongCount);
    if (weakCompare != 0) return weakCompare;
    final masteryCompare = a.masteryLevel.compareTo(b.masteryLevel);
    if (masteryCompare != 0) return masteryCompare;
    return a.nextReviewAt.compareTo(b.nextReviewAt);
  }
}

String _initialCue(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '?';
  return String.fromCharCode(trimmed.runes.first).toUpperCase();
}
