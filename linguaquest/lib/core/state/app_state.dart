import 'package:flutter/material.dart';

import '../../data/models/app_notification.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/study_plan.dart';
import '../../data/models/user_word.dart';
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

class AppState {
  AppState({
    required this.isBootstrapped,
    required this.isLoading,
    required this.wordBooks,
    required this.currentWordBookId,
    required this.lessons,
    required this.customWords,
    required this.userWords,
    required this.themeMode,
    required this.reminderSettings,
    required this.completedLessonIds,
    required this.todayCompletedLessonIds,
    required this.todayReviewWordIds,
    required this.todayClaimedRewardIds,
    required this.notifications,
    this.locale,
    this.user,
    this.lastResult,
    this.studyPlan,
    this.errorMessage,
    List<CustomWord>? reviewWords,
  }) : _reviewWords = List.unmodifiable(
         reviewWords ?? _buildReviewWords(userWords, customWords),
       );

  final bool isBootstrapped;
  final bool isLoading;
  final UserProfile? user;
  final List<WordBook> wordBooks;
  final String currentWordBookId;
  final List<Lesson> lessons;
  final List<CustomWord> customWords;
  final List<UserWord> userWords;
  final ThemeMode themeMode;
  final Locale? locale;
  final DailyReminderSettings reminderSettings;
  final StudyPlan? studyPlan;
  final Set<String> completedLessonIds;
  final Set<String> todayCompletedLessonIds;
  final Set<String> todayReviewWordIds;
  final Set<String> todayClaimedRewardIds;
  final List<AppNotification> notifications;
  final LessonResult? lastResult;
  final String? errorMessage;
  final List<CustomWord> _reviewWords;

  bool get isAuthenticated => user != null;

  int get unreadNotificationCount =>
      notifications.where((notification) => !notification.isRead).length;

  String? get learningTarget => studyPlan?.wordBookId ?? user?.targetExam;

  StudyBookInfo get currentStudyBook => studyBookInfoForId(
    studyPlan?.wordBookId ?? studyBookIdForTarget(user?.targetExam),
  );

  bool get isStudyPlanPaused => studyPlan?.isPaused ?? false;

  int get dailyNewTarget => studyPlan?.dailyNewTarget ?? user?.dailyGoal ?? 10;

  int get dailyReviewLimit => studyPlan?.dailyReviewLimit ?? dueWords.length;

  WordBook? get currentWordBook {
    for (final book in wordBooks) {
      if (book.id == currentWordBookId) return book;
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
      formalLessons.fold(0, (total, lesson) => total + lesson.words.length);

  int get completedLearningWords => formalLessons
      .where((lesson) => completedLessonIds.contains(lesson.id))
      .fold(0, (total, lesson) => total + lesson.words.length);

  int get trackedLearningWords => userWords
      .where((word) => word.status != 'Ignored' && !word.isIgnored)
      .length;

  int get masteredReviewWords => reviewWords
      .where((word) => word.masteryLevel >= 4 || word.status == 'Mastered')
      .length;

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

  List<CustomWord> get reviewWords => _reviewWords;

  List<CustomWord> get dueWords {
    final now = DateTime.now();
    final due = reviewWords.where((word) => word.isDue(now)).toList()
      ..sort((a, b) => a.nextReviewAt.compareTo(b.nextReviewAt));
    return due;
  }

  List<CustomWord> get reviewQueue => dueWords.take(dailyReviewLimit).toList();

  List<CustomWord> get weakWords {
    final weak = reviewWords.where((word) => word.isWeak).toList()
      ..sort((a, b) => b.wrongCount.compareTo(a.wrongCount));
    return weak;
  }

  AppState copyWith({
    bool? isBootstrapped,
    bool? isLoading,
    UserProfile? user,
    bool clearUser = false,
    List<WordBook>? wordBooks,
    String? currentWordBookId,
    List<Lesson>? lessons,
    List<CustomWord>? customWords,
    List<UserWord>? userWords,
    ThemeMode? themeMode,
    Locale? locale,
    DailyReminderSettings? reminderSettings,
    StudyPlan? studyPlan,
    bool clearStudyPlan = false,
    Set<String>? completedLessonIds,
    Set<String>? todayCompletedLessonIds,
    Set<String>? todayReviewWordIds,
    Set<String>? todayClaimedRewardIds,
    List<AppNotification>? notifications,
    LessonResult? lastResult,
    bool clearLastResult = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    final nextCustomWords = customWords ?? this.customWords;
    final nextUserWords = userWords ?? this.userWords;
    return AppState(
      isBootstrapped: isBootstrapped ?? this.isBootstrapped,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      wordBooks: wordBooks ?? this.wordBooks,
      currentWordBookId: currentWordBookId ?? this.currentWordBookId,
      lessons: lessons ?? this.lessons,
      customWords: nextCustomWords,
      userWords: nextUserWords,
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
      reminderSettings: reminderSettings ?? this.reminderSettings,
      studyPlan: clearStudyPlan ? null : studyPlan ?? this.studyPlan,
      completedLessonIds: completedLessonIds ?? this.completedLessonIds,
      todayCompletedLessonIds:
          todayCompletedLessonIds ?? this.todayCompletedLessonIds,
      todayReviewWordIds: todayReviewWordIds ?? this.todayReviewWordIds,
      todayClaimedRewardIds:
          todayClaimedRewardIds ?? this.todayClaimedRewardIds,
      notifications: notifications ?? this.notifications,
      lastResult: clearLastResult ? null : lastResult ?? this.lastResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      reviewWords: customWords == null && userWords == null
          ? _reviewWords
          : _buildReviewWords(nextUserWords, nextCustomWords),
    );
  }

  factory AppState.initial() {
    return AppState(
      isBootstrapped: false,
      isLoading: false,
      wordBooks: [],
      currentWordBookId: 'beginner',
      lessons: [],
      customWords: [],
      userWords: [],
      themeMode: ThemeMode.system,
      locale: null,
      reminderSettings: DailyReminderSettings.defaults,
      completedLessonIds: {},
      todayCompletedLessonIds: {},
      todayReviewWordIds: {},
      todayClaimedRewardIds: {},
      notifications: [],
    );
  }
}

List<CustomWord> _buildReviewWords(
  List<UserWord> userWords,
  List<CustomWord> customWords,
) {
  final seen = <String>{};
  final words = <CustomWord>[];
  for (final word in userWords) {
    if (!_isReviewEligibleStatus(word.status) || word.isIgnored) continue;
    final card = word.toReviewCard();
    if (seen.add(_reviewWordKey(card.word))) {
      words.add(card);
    }
  }
  for (final word in customWords) {
    if (!_isReviewEligibleStatus(word.status) || word.isIgnored) continue;
    if (seen.add(_reviewWordKey(word.word))) {
      words.add(word);
    }
  }
  return words;
}

String _reviewWordKey(String word) => word.trim().toLowerCase();

bool _isReviewEligibleStatus(String status) {
  return status != 'New' && status != 'Previewed' && status != 'Ignored';
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

  if (normalized == 'business-english') {
    return lesson.section == '商务英语' || _lessonHasTag(lesson, 'business');
  }
  if (normalized == 'daily-english') {
    return lesson.section == '日常英语' || _lessonHasTag(lesson, 'daily');
  }
  if (normalized == 'travel-english') {
    return lesson.section == '旅行英语' || _lessonHasTag(lesson, 'travel');
  }
  if (normalized == 'exam-core') {
    return lesson.section == '考试高频' ||
        _lessonHasTag(lesson, 'exam') ||
        _lessonHasTag(lesson, 'academic');
  }

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
