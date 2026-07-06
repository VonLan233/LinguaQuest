import 'package:test/test.dart';

import '../lib/src/forum_policy.dart';
import '../lib/src/moderation_policy.dart';

void main() {
  group('ForumPolicy', () {
    test('autoModeratePost approves valid title + body', () {
      final status = ForumPolicy.autoModeratePost(
        'How do I use the present perfect?',
        'I am confused about when to use "have done" vs "did". Can anyone help?',
      );
      expect(status, equals(ContentStatus.approved));
    });

    test('autoModeratePost rejects empty title', () {
      final status = ForumPolicy.autoModeratePost('', 'some body text');
      expect(status, equals(ContentStatus.rejected));
    });

    test('autoModeratePost rejects empty body', () {
      final status = ForumPolicy.autoModeratePost('Some title', '');
      expect(status, equals(ContentStatus.rejected));
    });

    test('autoModeratePost rejects title over 200 chars', () {
      final longTitle = 'a' * 201;
      final status = ForumPolicy.autoModeratePost(longTitle, 'valid body');
      expect(status, equals(ContentStatus.rejected));
    });

    test('autoModeratePost rejects body over 5000 chars', () {
      final longBody = 'a' * 5001;
      final status = ForumPolicy.autoModeratePost('valid title', longBody);
      expect(status, equals(ContentStatus.rejected));
    });

    test('autoModeratePost accepts title exactly 200 chars', () {
      final title = 'a' * 200;
      final status = ForumPolicy.autoModeratePost(title, 'valid body');
      expect(status, equals(ContentStatus.approved));
    });

    test('autoModeratePost accepts body exactly 5000 chars', () {
      final body = 'a' * 5000;
      final status = ForumPolicy.autoModeratePost('valid title', body);
      expect(status, equals(ContentStatus.approved));
    });

    test('autoModerateComment approves non-empty short body', () {
      final status = ForumPolicy.autoModerateComment('Great post!');
      expect(status, equals(ContentStatus.approved));
    });

    test('autoModerateComment rejects empty body', () {
      final status = ForumPolicy.autoModerateComment('');
      expect(status, equals(ContentStatus.rejected));
    });

    test('autoModerateComment rejects whitespace-only body', () {
      final status = ForumPolicy.autoModerateComment('   ');
      expect(status, equals(ContentStatus.rejected));
    });

    test('autoModerateComment rejects body over 5000 chars', () {
      final status = ForumPolicy.autoModerateComment('a' * 5001);
      expect(status, equals(ContentStatus.rejected));
    });
  });
}
