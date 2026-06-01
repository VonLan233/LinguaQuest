import 'package:flutter/material.dart';

import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/reward_task.dart';
import '../../data/models/target_word_progress.dart';
import '../../data/models/user_profile.dart';

class DailyReminderSettings {
  const DailyReminderSettings({
    required this.enabled,
    required this.hour,
    required this.minute,
  });

  final bool enabled;
  final int hour;
  final int minute;

  String get formattedTime {
    final paddedHour = hour.toString().padLeft(2, '0');
    final paddedMinute = minute.toString().padLeft(2, '0');
    return '$paddedHour:$paddedMinute';
  }

  DailyReminderSettings copyWith({bool? enabled, int? hour, int? minute}) {
    return DailyReminderSettings(
      enabled: enabled ?? this.enabled,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
    );
  }

  Map<String, dynamic> toJson() {
    return {'enabled': enabled, 'hour': hour, 'minute': minute};
  }

  factory DailyReminderSettings.fromJson(Map<String, dynamic> json) {
    return DailyReminderSettings(
      enabled: json['enabled'] as bool? ?? true,
      hour: json['hour'] as int? ?? 20,
      minute: json['minute'] as int? ?? 0,
    );
  }

  static const defaults = DailyReminderSettings(
    enabled: true,
    hour: 20,
    minute: 0,
  );
}

class LearningPlan {
  const LearningPlan({
    required this.target,
    required this.deadline,
    required this.dailyWords,
    required this.remainingWords,
    required this.createdAt,
    this.wordBookId = 'beginner',
    this.dailyReviewLimit = 20,
    this.status = 'active',
  });

  final String target;
  final String wordBookId;
  final DateTime deadline;
  final int dailyWords;
  final int dailyReviewLimit;
  final int remainingWords;
  final String status;
  final DateTime createdAt;

  int daysLeft(DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(deadline.year, deadline.month, deadline.day);
    return targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'target': target,
      'wordBookId': wordBookId,
      'deadline': deadline.toIso8601String(),
      'dailyWords': dailyWords,
      'dailyReviewLimit': dailyReviewLimit,
      'remainingWords': remainingWords,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  LearningPlan copyWith({
    String? target,
    String? wordBookId,
    DateTime? deadline,
    int? dailyWords,
    int? dailyReviewLimit,
    int? remainingWords,
    String? status,
    DateTime? createdAt,
  }) {
    return LearningPlan(
      target: target ?? this.target,
      wordBookId: wordBookId ?? this.wordBookId,
      deadline: deadline ?? this.deadline,
      dailyWords: dailyWords ?? this.dailyWords,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      remainingWords: remainingWords ?? this.remainingWords,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory LearningPlan.fromJson(Map<String, dynamic> json) {
    return LearningPlan(
      target: json['target'] as String? ?? 'Daily English',
      wordBookId:
          json['wordBookId'] as String? ??
          wordBookIdForTarget(json['target'] as String?),
      deadline: _date(json['deadline']) ?? DateTime.now(),
      dailyWords: json['dailyWords'] as int? ?? 10,
      dailyReviewLimit: json['dailyReviewLimit'] as int? ?? 20,
      remainingWords: json['remainingWords'] as int? ?? 0,
      status: json['status'] as String? ?? 'active',
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _date(Object? value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}

class AppState {
  const AppState({
    required this.isBootstrapped,
    required this.isLoading,
    required this.lessons,
    required this.wordBooks,
    required this.targetWordProgress,
    required this.customWords,
    required this.themeMode,
    required this.reminderSettings,
    required this.completedLessonIds,
    required this.todayCompletedLessonIds,
    required this.todayReviewWordIds,
    required this.todayClaimedRewardIds,
    required this.rewardTasks,
    this.user,
    this.lastResult,
    this.learningPlan,
    this.errorMessage,
  });

  final bool isBootstrapped;
  final bool isLoading;
  final UserProfile? user;
  final List<Lesson> lessons;
  final List<WordBook> wordBooks;
  final Map<String, TargetWordProgress> targetWordProgress;
  final List<CustomWord> customWords;
  final ThemeMode themeMode;
  final DailyReminderSettings reminderSettings;
  final LearningPlan? learningPlan;
  final Set<String> completedLessonIds;
  final Set<String> todayCompletedLessonIds;
  final Set<String> todayReviewWordIds;
  final Set<String> todayClaimedRewardIds;
  final List<RewardTask> rewardTasks;
  final LessonResult? lastResult;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  String? get learningTarget => learningPlan?.target ?? user?.targetExam;

  String get activeWordBookId =>
      learningPlan?.wordBookId ?? wordBookIdForTarget(learningTarget);

  WordBook? get currentWordBook {
    for (final book in wordBooks) {
      if (book.id == activeWordBookId) return book;
    }
    return wordBooks.isEmpty ? null : wordBooks.first;
  }

  List<Lesson> get formalLessons => applyLearningTargetProgression(
    learningLessonsForTarget(lessons, learningTarget),
    completedLessonIds,
  );

  Lesson? get currentLesson {
    for (final lesson in formalLessons) {
      if (lesson.status == 'current') return lesson;
    }
    for (final lesson in formalLessons) {
      if (lesson.status != 'completed' && lesson.status != 'locked') {
        return lesson;
      }
    }
    return formalLessons.isEmpty ? null : formalLessons.last;
  }

  int get totalLearningWords =>
      currentWordBook?.includedWords ??
      formalLessons.fold(0, (total, lesson) => total + lesson.words.length);

  int get completedLearningWords {
    final bookId = activeWordBookId;
    final progressed = targetWordProgress.values
        .where(
          (progress) => progress.wordBookId == bookId && progress.isLearned,
        )
        .length;
    if (progressed > 0) return progressed;
    return formalLessons
        .where((lesson) => completedLessonIds.contains(lesson.id))
        .fold(0, (total, lesson) => total + lesson.words.length);
  }

  Set<String> get todayCompletedFormalLessonIds => {
    for (final lesson in formalLessons)
      if (todayCompletedLessonIds.contains(lesson.id)) lesson.id,
  };

  int get todayLearningWords => formalLessons
      .where((lesson) => todayCompletedLessonIds.contains(lesson.id))
      .fold(0, (total, lesson) => total + lesson.words.length);

  double get learningPathProgress {
    if (totalLearningWords == 0) return 0;
    return (completedLearningWords / totalLearningWords).clamp(0.0, 1.0);
  }

  List<CustomWord> get dueWords {
    final now = DateTime.now();
    return customWords.where((word) => word.isDue(now)).toList();
  }

  List<TargetReviewWord> get dueTargetWords {
    final book = currentWordBook;
    if (book == null) return const [];
    final now = DateTime.now();
    final due = <TargetReviewWord>[];
    for (final word in book.words) {
      final progress = targetWordProgress[word.id];
      if (progress == null || !progress.isDue(now)) continue;
      due.add(TargetReviewWord(word: word, progress: progress));
    }
    return due;
  }

  List<TargetReviewWord> get weakTargetWords {
    final book = currentWordBook;
    if (book == null) return const [];
    final weak = <TargetReviewWord>[];
    for (final word in book.words) {
      final progress = targetWordProgress[word.id];
      if (progress == null || !progress.isLearned || !progress.isWeak) {
        continue;
      }
      weak.add(TargetReviewWord(word: word, progress: progress));
    }
    weak.sort((a, b) => b.progress.wrongCount.compareTo(a.progress.wrongCount));
    return weak;
  }

  Word? targetWordById(String id) {
    for (final book in wordBooks) {
      for (final word in book.words) {
        if (word.id == id) return word;
      }
    }
    return null;
  }

  List<CustomWord> get weakWords {
    final weak = customWords.where((word) => word.isWeak).toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return weak;
  }

  AppState copyWith({
    bool? isBootstrapped,
    bool? isLoading,
    UserProfile? user,
    bool clearUser = false,
    List<Lesson>? lessons,
    List<WordBook>? wordBooks,
    Map<String, TargetWordProgress>? targetWordProgress,
    List<CustomWord>? customWords,
    ThemeMode? themeMode,
    DailyReminderSettings? reminderSettings,
    LearningPlan? learningPlan,
    bool clearLearningPlan = false,
    Set<String>? completedLessonIds,
    Set<String>? todayCompletedLessonIds,
    Set<String>? todayReviewWordIds,
    Set<String>? todayClaimedRewardIds,
    List<RewardTask>? rewardTasks,
    LessonResult? lastResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppState(
      isBootstrapped: isBootstrapped ?? this.isBootstrapped,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      lessons: lessons ?? this.lessons,
      wordBooks: wordBooks ?? this.wordBooks,
      targetWordProgress: targetWordProgress ?? this.targetWordProgress,
      customWords: customWords ?? this.customWords,
      themeMode: themeMode ?? this.themeMode,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      learningPlan: clearLearningPlan
          ? null
          : learningPlan ?? this.learningPlan,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      todayCompletedLessonIds:
          todayCompletedLessonIds ?? this.todayCompletedLessonIds,
      todayReviewWordIds: todayReviewWordIds ?? this.todayReviewWordIds,
      todayClaimedRewardIds:
          todayClaimedRewardIds ?? this.todayClaimedRewardIds,
      rewardTasks: rewardTasks ?? this.rewardTasks,
      lastResult: lastResult ?? this.lastResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory AppState.initial() {
    return const AppState(
      isBootstrapped: false,
      isLoading: false,
      lessons: [],
      wordBooks: [],
      targetWordProgress: {},
      customWords: [],
      themeMode: ThemeMode.system,
      reminderSettings: DailyReminderSettings.defaults,
      completedLessonIds: {},
      todayCompletedLessonIds: {},
      todayReviewWordIds: {},
      todayClaimedRewardIds: {},
      rewardTasks: [],
    );
  }
}

class TargetReviewWord {
  const TargetReviewWord({required this.word, required this.progress});

  final Word word;
  final TargetWordProgress progress;
}

String wordBookIdForTarget(String? target) {
  final normalized = target?.trim().toLowerCase() ?? '';
  if (normalized.contains('ielts') || normalized.contains('雅思')) {
    return 'ielts';
  }
  if (normalized.contains('toefl') || normalized.contains('托福')) {
    return 'toefl';
  }
  if (normalized.contains('gre')) return 'gre';
  if (normalized.contains('gmat')) return 'gmat';
  if (normalized.contains('sat')) return 'sat';
  return 'beginner';
}

List<Lesson> learningLessonsForTarget(List<Lesson> lessons, String? target) {
  final formal = lessons.where((lesson) => !lesson.isTrainingPack).toList();
  final focused = formal
      .where((lesson) => lessonMatchesLearningTarget(lesson, target))
      .toList();
  return focused.isEmpty ? formal : focused;
}

List<Lesson> applyLearningTargetProgression(
  List<Lesson> lessons,
  Set<String> completedLessonIds,
) {
  if (lessons.isEmpty) return lessons;
  final firstIncomplete = lessons.indexWhere(
    (lesson) => !completedLessonIds.contains(lesson.id),
  );
  if (firstIncomplete == -1) {
    return [for (final lesson in lessons) lesson.copyWith(status: 'completed')];
  }
  return [
    for (var index = 0; index < lessons.length; index++)
      lessons[index].copyWith(
        status: completedLessonIds.contains(lessons[index].id)
            ? 'completed'
            : index == firstIncomplete
            ? 'current'
            : 'locked',
      ),
  ];
}

bool lessonMatchesLearningTarget(Lesson lesson, String? target) {
  final normalized = target?.trim().toLowerCase() ?? '';
  if (normalized.isEmpty) return true;

  if (normalized.contains('business') || normalized.contains('商务')) {
    return lesson.section == '商务英语' || _lessonHasTag(lesson, 'business');
  }
  if (normalized.contains('daily') || normalized.contains('日常')) {
    return lesson.section == '日常英语' || _lessonHasTag(lesson, 'daily');
  }
  if (normalized.contains('travel') || normalized.contains('旅行')) {
    return lesson.section == '旅行英语' || _lessonHasTag(lesson, 'travel');
  }
  if (normalized.contains('ielts') ||
      normalized.contains('toefl') ||
      normalized.contains('muet') ||
      normalized.contains('cet') ||
      normalized.contains('exam') ||
      normalized.contains('雅思') ||
      normalized.contains('托福') ||
      normalized.contains('考试') ||
      normalized.contains('大学英语')) {
    return lesson.section == '考试高频' ||
        _lessonHasTag(lesson, 'exam') ||
        _lessonHasTag(lesson, 'academic');
  }

  return true;
}

bool _lessonHasTag(Lesson lesson, String tag) {
  return lesson.words.any(
    (word) => word.tags.any((item) => item.toLowerCase() == tag),
  );
}
