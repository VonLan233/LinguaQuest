import 'moderation_policy.dart';

class ForumPolicy {
  /// Auto-moderate new posts/comments
  static ContentStatus autoModeratePost(String title, String body) {
    if (title.trim().isEmpty || body.trim().isEmpty) {
      return ContentStatus.rejected;
    }
    if (title.length > 200 || body.length > 5000) {
      return ContentStatus.rejected;
    }
    return ContentStatus.approved;
  }

  static ContentStatus autoModerateComment(String body) {
    return ModerationPolicy.autoApprove(body);
  }
}
