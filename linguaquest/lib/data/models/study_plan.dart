class StudyPlan {
  const StudyPlan({
    required this.id,
    required this.uid,
    required this.wordBookId,
    required this.dailyNewTarget,
    required this.dailyReviewLimit,
    required this.startDate,
    required this.targetFinishDate,
    required this.reminderTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String uid;
  final String wordBookId;
  final int dailyNewTarget;
  final int dailyReviewLimit;
  final DateTime startDate;
  final DateTime targetFinishDate;
  final String reminderTime;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isPaused => status == 'paused';

  int daysLeft(DateTime now) {
    final today = DateTime.utc(now.year, now.month, now.day);
    final targetDay = DateTime.utc(
      targetFinishDate.year,
      targetFinishDate.month,
      targetFinishDate.day,
    );
    final diff = targetDay.difference(today).inDays;
    return diff < 0 ? 0 : diff + 1;
  }

  StudyPlan copyWith({
    String? id,
    String? uid,
    String? wordBookId,
    int? dailyNewTarget,
    int? dailyReviewLimit,
    DateTime? startDate,
    DateTime? targetFinishDate,
    String? reminderTime,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudyPlan(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      wordBookId: wordBookId ?? this.wordBookId,
      dailyNewTarget: dailyNewTarget ?? this.dailyNewTarget,
      dailyReviewLimit: dailyReviewLimit ?? this.dailyReviewLimit,
      startDate: startDate ?? this.startDate,
      targetFinishDate: targetFinishDate ?? this.targetFinishDate,
      reminderTime: reminderTime ?? this.reminderTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'id': id,
      'wordBookId': wordBookId,
      'dailyNewTarget': dailyNewTarget,
      'dailyReviewLimit': dailyReviewLimit,
      'startDate': _dateKey(startDate),
      'targetFinishDate': _dateKey(targetFinishDate),
      'reminderTime': reminderTime,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final uid = json['uid'] as String? ?? json['userId'] as String? ?? '';
    return StudyPlan(
      id: json['id'] as String? ?? 'study-plan-$uid',
      uid: uid,
      wordBookId: normalizedStudyBookId(json['wordBookId'] as String?),
      dailyNewTarget: _intInRange(json['dailyNewTarget'], 1, 200, 10),
      dailyReviewLimit: _intInRange(json['dailyReviewLimit'], 0, 500, 20),
      startDate: _date(json['startDate']) ?? today,
      targetFinishDate:
          _date(json['targetFinishDate']) ??
          today.add(const Duration(days: 30)),
      reminderTime: normalizedReminderTime(json['reminderTime'] as String?),
      status: normalizedPlanStatus(json['status'] as String?),
      createdAt: _dateTime(json['createdAt']) ?? now,
      updatedAt: _dateTime(json['updatedAt']) ?? now,
    );
  }

  static StudyPlan defaultsFor({
    required String uid,
    required String targetExam,
    required int dailyGoal,
    DateTime? targetFinishDate,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return StudyPlan(
      id: 'study-plan-$uid',
      uid: uid,
      wordBookId: studyBookIdForTarget(targetExam),
      dailyNewTarget: dailyGoal.clamp(1, 200).toInt(),
      dailyReviewLimit: (dailyGoal * 2).clamp(5, 500).toInt(),
      startDate: today,
      targetFinishDate: targetFinishDate ?? today.add(const Duration(days: 30)),
      reminderTime: '20:00',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
  }
}

class StudyBookInfo {
  const StudyBookInfo({
    required this.id,
    required this.name,
    required this.cover,
    required this.description,
  });

  final String id;
  final String name;
  final String cover;
  final String description;
}

const studyBooks = [
  StudyBookInfo(
    id: 'hsk1',
    name: 'HSK 1',
    cover: '🀄',
    description: 'Core vocabulary for HSK Level 1.',
  ),
];

StudyBookInfo studyBookInfoForId(String id) {
  return studyBooks.firstWhere(
    (book) => book.id == normalizedStudyBookId(id),
    orElse: () => studyBooks.first,
  );
}

// Only one book exists for now; every legacy/exam/HSK target resolves to it.
String normalizedStudyBookId(String? value) => 'hsk1';

String studyBookIdForTarget(String? target) => 'hsk1';

String targetForStudyBookId(String wordBookId) => 'HSK 1';

String normalizedPlanStatus(String? value) {
  return value == 'paused' ? 'paused' : 'active';
}

String normalizedReminderTime(String? value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value ?? '');
  if (match == null) return '20:00';
  final hour = int.tryParse(match.group(1) ?? '') ?? 20;
  final minute = int.tryParse(match.group(2) ?? '') ?? 0;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return '20:00';
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int _intInRange(Object? value, int min, int max, int fallback) {
  final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
  if (parsed == null) return fallback;
  return parsed.clamp(min, max).toInt();
}

DateTime? _date(Object? value) {
  final parsed = _dateTime(value);
  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

DateTime? _dateTime(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
