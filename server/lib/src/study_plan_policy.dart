const allowedStudyPlanStatuses = {'active', 'paused'};
const allowedWordBookIds = {
  'beginner',
  'ielts',
  'toefl',
  'gre',
};

class StudyPlanValidationResult {
  const StudyPlanValidationResult._({this.data, this.error});

  final Map<String, dynamic>? data;
  final String? error;

  bool get isValid => data != null;

  factory StudyPlanValidationResult.valid(Map<String, dynamic> data) {
    return StudyPlanValidationResult._(data: data);
  }

  factory StudyPlanValidationResult.invalid(String error) {
    return StudyPlanValidationResult._(error: error);
  }
}

StudyPlanValidationResult validateStudyPlanPayload(
  Map<String, dynamic> body, {
  DateTime? now,
}) {
  final wordBookId = normalizeStudyPlanWordBookId(body['wordBookId']);
  if (!allowedWordBookIds.contains(wordBookId)) {
    return StudyPlanValidationResult.invalid('invalid wordBookId');
  }

  final dailyNewTarget = _intValue(body['dailyNewTarget']);
  if (dailyNewTarget == null || dailyNewTarget < 1 || dailyNewTarget > 200) {
    return StudyPlanValidationResult.invalid(
      'dailyNewTarget must be between 1 and 200',
    );
  }

  final dailyReviewLimit = _intValue(body['dailyReviewLimit']);
  if (dailyReviewLimit == null ||
      dailyReviewLimit < 0 ||
      dailyReviewLimit > 500) {
    return StudyPlanValidationResult.invalid(
      'dailyReviewLimit must be between 0 and 500',
    );
  }

  final startDate = parseStudyPlanDate(body['startDate']);
  final targetFinishDate = parseStudyPlanDate(body['targetFinishDate']);
  if (startDate == null || targetFinishDate == null) {
    return StudyPlanValidationResult.invalid(
      'startDate and targetFinishDate are required',
    );
  }
  if (targetFinishDate.isBefore(startDate)) {
    return StudyPlanValidationResult.invalid(
      'targetFinishDate must be on or after startDate',
    );
  }

  final reminderTime = normalizeReminderTime(body['reminderTime']);
  if (reminderTime == null) {
    return StudyPlanValidationResult.invalid('reminderTime must be HH:mm');
  }

  final status = (body['status']?.toString() ?? 'active').trim();
  if (!allowedStudyPlanStatuses.contains(status)) {
    return StudyPlanValidationResult.invalid('invalid status');
  }

  return StudyPlanValidationResult.valid({
    'wordBookId': wordBookId,
    'dailyNewTarget': dailyNewTarget,
    'dailyReviewLimit': dailyReviewLimit,
    'startDate': startDate,
    'targetFinishDate': targetFinishDate,
    'reminderTime': reminderTime,
    'status': status,
    'now': now ?? DateTime.now().toUtc(),
  });
}

String normalizeStudyPlanWordBookId(Object? value) {
  final normalized = (value?.toString() ?? '').trim().toLowerCase();
  if (allowedWordBookIds.contains(normalized)) return normalized;
  if (normalized == 'daily-english') return 'beginner';
  if (normalized == 'exam-core') return 'ielts';
  // Backward compatibility: silently map deprecated wordbooks to beginner
  if (const {
    'business-english',
    'travel-english',
    'cet4',
    'cet6',
    'kaoyan',
  }.contains(normalized)) {
    return 'beginner';
  }
  return normalized;
}

DateTime? parseStudyPlanDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime)
    return DateTime.utc(value.year, value.month, value.day);
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return null;
  return DateTime.utc(parsed.year, parsed.month, parsed.day);
}

String? normalizeReminderTime(Object? value) {
  final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch('$value');
  if (match == null) return null;
  final hour = int.tryParse(match.group(1) ?? '');
  final minute = int.tryParse(match.group(2) ?? '');
  if (hour == null || minute == null) return null;
  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

int? _intValue(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '');
}
