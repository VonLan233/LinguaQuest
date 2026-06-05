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
    id: 'beginner',
    name: '入门基础词汇',
    cover: '🌱',
    description: '适合初级英语和日常表达入门的基础高频词。',
  ),
  StudyBookInfo(
    id: 'ielts',
    name: '雅思核心词汇',
    cover: '🎓',
    description: '覆盖雅思阅读、听力和写作中的高频学术词。',
  ),
  StudyBookInfo(
    id: 'toefl',
    name: '托福高频词汇',
    cover: '🌎',
    description: '面向托福场景的学术词汇和校园表达。',
  ),
  StudyBookInfo(
    id: 'gre',
    name: 'GRE 高频词汇',
    cover: '🧠',
    description: '强化 GRE 阅读和填空常见高阶词。',
  ),
  StudyBookInfo(
    id: 'cet4',
    name: '四级核心词汇',
    cover: '4️⃣',
    description: '大学英语四级核心词和常见搭配。',
  ),
  StudyBookInfo(
    id: 'cet6',
    name: '六级核心词汇',
    cover: '6️⃣',
    description: '大学英语六级阅读和听力高频词。',
  ),
  StudyBookInfo(
    id: 'kaoyan',
    name: '考研英语核心词汇',
    cover: '📚',
    description: '覆盖考研英语阅读、翻译和写作常见词。',
  ),
];

StudyBookInfo studyBookInfoForId(String id) {
  return studyBooks.firstWhere(
    (book) => book.id == normalizedStudyBookId(id),
    orElse: () => studyBooks.first,
  );
}

String normalizedStudyBookId(String? value) {
  final normalized = value?.trim().toLowerCase() ?? '';
  if (studyBooks.any((book) => book.id == normalized)) return normalized;
  if (normalized == 'daily-english') return 'beginner';
  if (normalized == 'exam-core') return 'ielts';
  if (normalized == 'business-english' || normalized == 'travel-english') {
    return 'beginner';
  }
  return studyBookIdForTarget(normalized);
}

String studyBookIdForTarget(String? target) {
  final normalized = target?.trim().toLowerCase() ?? '';
  if (normalized.contains('toefl') || normalized.contains('托福')) return 'toefl';
  if (normalized.contains('gre')) return 'gre';
  if (normalized.contains('cet-6') ||
      normalized.contains('cet6') ||
      normalized.contains('六级')) {
    return 'cet6';
  }
  if (normalized.contains('cet-4') ||
      normalized.contains('cet4') ||
      normalized.contains('四级')) {
    return 'cet4';
  }
  if (normalized.contains('考研')) return 'kaoyan';
  if (normalized.contains('ielts') ||
      normalized.contains('雅思') ||
      normalized.contains('exam') ||
      normalized.contains('考试') ||
      normalized.contains('大学英语')) {
    return 'ielts';
  }
  return 'beginner';
}

String targetForStudyBookId(String wordBookId) {
  switch (normalizedStudyBookId(wordBookId)) {
    case 'toefl':
      return 'TOEFL';
    case 'gre':
      return 'GRE';
    case 'cet4':
      return 'CET-4';
    case 'cet6':
      return 'CET-6';
    case 'kaoyan':
      return '考研';
    case 'ielts':
      return 'IELTS';
    case 'beginner':
      return 'Daily English';
  }
  return 'Daily English';
}

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
