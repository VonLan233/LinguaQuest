import 'package:flutter/material.dart';

import '../../data/models/app_notification.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../data/models/lottery.dart';
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
  });

  final String target;
  final DateTime deadline;
  final int dailyWords;
  final int remainingWords;
  final DateTime createdAt;

  int daysLeft(DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(deadline.year, deadline.month, deadline.day);
    return targetDay.difference(today).inDays.clamp(0, 9999).toInt() + 1;
  }

  Map<String, dynamic> toJson() {
    return {
      'target': target,
      'deadline': deadline.toIso8601String(),
      'dailyWords': dailyWords,
      'remainingWords': remainingWords,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LearningPlan.fromJson(Map<String, dynamic> json) {
    return LearningPlan(
      target: json['target'] as String? ?? 'Daily English',
      deadline: _date(json['deadline']) ?? DateTime.now(),
      dailyWords: json['dailyWords'] as int? ?? 10,
      remainingWords: json['remainingWords'] as int? ?? 0,
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
    required this.customWords,
    required this.themeMode,
    required this.reminderSettings,
    required this.completedLessonIds,
    required this.todayCompletedLessonIds,
    required this.todayReviewWordIds,
    required this.todayClaimedRewardIds,
    required this.notifications,
    required this.lotteryPrizes,
    required this.userAssets,
    this.user,
    this.lastResult,
    this.lastLotteryResult,
    this.learningPlan,
    this.errorMessage,
  });

  final bool isBootstrapped;
  final bool isLoading;
  final UserProfile? user;
  final List<Lesson> lessons;
  final List<CustomWord> customWords;
  final ThemeMode themeMode;
  final DailyReminderSettings reminderSettings;
  final LearningPlan? learningPlan;
  final Set<String> completedLessonIds;
  final Set<String> todayCompletedLessonIds;
  final Set<String> todayReviewWordIds;
  final Set<String> todayClaimedRewardIds;
  final List<AppNotification> notifications;
  final List<LotteryPrize> lotteryPrizes;
  final List<UserAsset> userAssets;
  final LessonResult? lastResult;
  final LotteryDrawResult? lastLotteryResult;
  final String? errorMessage;

  bool get isAuthenticated => user != null;

  int get unreadNotificationCount =>
      notifications.where((notification) => !notification.isRead).length;

  String? get learningTarget => learningPlan?.target ?? user?.targetExam;

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
    List<CustomWord>? customWords,
    ThemeMode? themeMode,
    DailyReminderSettings? reminderSettings,
    LearningPlan? learningPlan,
    bool clearLearningPlan = false,
    Set<String>? completedLessonIds,
    Set<String>? todayCompletedLessonIds,
    Set<String>? todayReviewWordIds,
    Set<String>? todayClaimedRewardIds,
    List<AppNotification>? notifications,
    List<LotteryPrize>? lotteryPrizes,
    List<UserAsset>? userAssets,
    LessonResult? lastResult,
    LotteryDrawResult? lastLotteryResult,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppState(
      isBootstrapped: isBootstrapped ?? this.isBootstrapped,
      isLoading: isLoading ?? this.isLoading,
      user: clearUser ? null : user ?? this.user,
      lessons: lessons ?? this.lessons,
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
      notifications: notifications ?? this.notifications,
      lotteryPrizes: lotteryPrizes ?? this.lotteryPrizes,
      userAssets: userAssets ?? this.userAssets,
      lastResult: lastResult ?? this.lastResult,
      lastLotteryResult: lastLotteryResult ?? this.lastLotteryResult,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }

  factory AppState.initial() {
    return const AppState(
      isBootstrapped: false,
      isLoading: false,
      lessons: [],
      customWords: [],
      themeMode: ThemeMode.system,
      reminderSettings: DailyReminderSettings.defaults,
      completedLessonIds: {},
      todayCompletedLessonIds: {},
      todayReviewWordIds: {},
      todayClaimedRewardIds: {},
      notifications: [],
      lotteryPrizes: [],
      userAssets: [],
    );
  }
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
