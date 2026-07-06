import 'package:linguaquest_server/src/moderation_policy.dart';
import 'package:test/test.dart';

void main() {
  group('ModerationPolicy.autoApprove', () {
    test('returns approved for normal content', () {
      expect(
        ModerationPolicy.autoApprove('Hello, this is normal content.'),
        ContentStatus.approved,
      );
    });

    test('returns rejected for empty content', () {
      expect(ModerationPolicy.autoApprove(''), ContentStatus.rejected);
    });

    test('returns rejected for whitespace-only content', () {
      expect(ModerationPolicy.autoApprove('   '), ContentStatus.rejected);
    });

    test('returns rejected for content > 5000 chars', () {
      final longContent = 'a' * 5001;
      expect(ModerationPolicy.autoApprove(longContent), ContentStatus.rejected);
    });

    test('returns approved for content exactly at 5000 chars', () {
      final borderContent = 'a' * 5000;
      expect(
        ModerationPolicy.autoApprove(borderContent),
        ContentStatus.approved,
      );
    });
  });

  group('ModerationPolicy.isValidReport', () {
    test('returns true for valid reason: spam', () {
      expect(ModerationPolicy.isValidReport('spam', null), isTrue);
    });

    test('returns true for valid reason with detail', () {
      expect(
        ModerationPolicy.isValidReport('inappropriate', 'This is offensive.'),
        isTrue,
      );
    });

    test('returns true for all valid reasons', () {
      for (final reason in ['spam', 'inappropriate', 'harassment', 'misinformation', 'other']) {
        expect(ModerationPolicy.isValidReport(reason, null), isTrue);
      }
    });

    test('returns false for unknown reason', () {
      expect(ModerationPolicy.isValidReport('unknown_reason', null), isFalse);
    });

    test('returns false for empty reason', () {
      expect(ModerationPolicy.isValidReport('', null), isFalse);
    });
  });
}
