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
      wordBookId: _wordBookIdOrDefault(json['wordBookId']),
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
  final normalized = normalizedStudyBookId(id);
  for (final book in studyBooks) {
    if (book.id == normalized) return book;
  }
  return StudyBookInfo(
    id: normalized,
    name: targetForStudyBookId(normalized),
    cover: studyPlanCoverEmoji(_languageForStudyBookId(normalized)),
    description: 'Vocabulary for ${targetForStudyBookId(normalized)}.',
  );
}

/// Keeps the real wordbook id from a server/stored plan; only falls back to
/// the default book when the value is missing or blank. (HSK-pivot used to
/// collapse everything to hsk1; with 15 books shipping that collapse is gone.)
String _wordBookIdOrDefault(Object? value) {
  final raw = (value as String?)?.trim() ?? '';
  return raw.isEmpty ? 'hsk1' : raw;
}

/// Emoji cover for the study-plan hero when a wordbook ships no artwork.
String studyPlanCoverEmoji(String language) {
  switch (language) {
    case 'ja':
      return '🗾';
    case 'en':
    case 'es':
    case 'fr':
    case 'ms':
      return '🔤';
    default:
      return '🀄';
  }
}

String normalizedStudyBookId(String? value) {
  final raw = value?.trim().toLowerCase().replaceAll('-', '_') ?? '';
  if (raw.isEmpty) return 'hsk1';
  return _targetToBookId[raw] ?? raw;
}

String studyBookIdForTarget(String? target) {
  final normalized = target?.trim().toLowerCase().replaceAll('-', '_') ?? '';
  if (normalized.isEmpty) return 'hsk1';
  return _targetToBookId[normalized] ?? normalized;
}

String targetForStudyBookId(String wordBookId) {
  final normalized = normalizedStudyBookId(wordBookId);
  return _bookIdToTarget[normalized] ?? wordBookId;
}

String _languageForStudyBookId(String wordBookId) {
  final normalized = normalizedStudyBookId(wordBookId);
  if (normalized.endsWith('_starter')) return normalized.split('_').first;
  if (normalized.startsWith('jlpt_')) return 'ja';
  if (normalized == 'en_basic') return 'en';
  if (normalized == 'es_basic') return 'es';
  if (normalized == 'fr_basic') return 'fr';
  if (normalized == 'ms_basic') return 'ms';
  return 'zh';
}

const _targetToBookId = <String, String>{
  'hsk 1': 'hsk1',
  'hsk1': 'hsk1',
  'hsk 2': 'hsk2',
  'hsk2': 'hsk2',
  'hsk 3': 'hsk3',
  'hsk3': 'hsk3',
  'hsk 4': 'hsk4',
  'hsk4': 'hsk4',
  'hsk 5': 'hsk5',
  'hsk5': 'hsk5',
  'hsk 6': 'hsk6',
  'hsk6': 'hsk6',
  'jlpt n5': 'jlpt_n5',
  'jlpt_n5': 'jlpt_n5',
  'jlpt n4': 'jlpt_n4',
  'jlpt_n4': 'jlpt_n4',
  'jlpt n3': 'jlpt_n3',
  'jlpt_n3': 'jlpt_n3',
  'jlpt n2': 'jlpt_n2',
  'jlpt_n2': 'jlpt_n2',
  'jlpt n1': 'jlpt_n1',
  'jlpt_n1': 'jlpt_n1',
  'daily english': 'en_basic',
  'business english': 'en_basic',
  'beginner': 'en_basic',
  'basic': 'en_basic',
  'english basics': 'en_basic',
  'english': 'en_basic',
  'spanish': 'es_basic',
  'español básico': 'es_basic',
  'french': 'fr_basic',
  'français débutant': 'fr_basic',
  'malay': 'ms_basic',
  'bahasa melayu asas': 'ms_basic',
  'cet 4': 'cet4',
  'cet_4': 'cet4',
  'cet4': 'cet4',
  'cet 6': 'cet6',
  'cet_6': 'cet6',
  'cet6': 'cet6',
  '考研': 'kaoyan',
};

const _bookIdToTarget = <String, String>{
  'hsk1': 'HSK 1',
  'hsk2': 'HSK 2',
  'hsk3': 'HSK 3',
  'hsk4': 'HSK 4',
  'hsk5': 'HSK 5',
  'hsk6': 'HSK 6',
  'jlpt_n5': 'JLPT N5',
  'jlpt_n4': 'JLPT N4',
  'jlpt_n3': 'JLPT N3',
  'jlpt_n2': 'JLPT N2',
  'jlpt_n1': 'JLPT N1',
  'en_basic': 'Daily English',
  'es_basic': 'Spanish',
  'fr_basic': 'French',
  'ms_basic': 'Malay',
  'cet4': 'CET-4',
  'cet6': 'CET-6',
  'kaoyan': 'Kaoyan',
};

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
