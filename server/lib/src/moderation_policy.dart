/// Content status lifecycle: pending → approved | rejected | hidden
enum ContentStatus { pending, approved, rejected, hidden }

/// Report reason categories
enum ReportReason { spam, inappropriate, harassment, misinformation, other }

class ModerationPolicy {
  /// Auto-approve rule: content passes basic length/content checks
  static ContentStatus autoApprove(String content) {
    if (content.trim().isEmpty) return ContentStatus.rejected;
    if (content.length > 5000) return ContentStatus.rejected;
    // In mock mode, all non-empty content under limit is auto-approved
    return ContentStatus.approved;
  }

  /// Validate a report submission
  static bool isValidReport(String reason, String? detail) {
    try {
      ReportReason.values.byName(reason);
      return true;
    } catch (_) {
      return false;
    }
  }
}
