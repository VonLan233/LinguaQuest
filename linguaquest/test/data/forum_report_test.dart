import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MockForumRepository.reportPost', () {
    late MockForumRepository repo;

    setUp(() {
      repo = MockForumRepository();
    });

    test('reportPost completes without error for valid postId and reason', () async {
      await expectLater(
        repo.reportPost('mock-post-1', 'Spam'),
        completes,
      );
    });

    test('reportPost accepts detail parameter', () async {
      await expectLater(
        repo.reportPost('mock-post-1', 'Other', detail: 'Custom detail here'),
        completes,
      );
    });

    test('reportPost works with all supported reasons', () async {
      for (final reason in ['Spam', 'Inappropriate', 'Other']) {
        await expectLater(
          repo.reportPost('mock-post-1', reason),
          completes,
        );
      }
    });
  });
}
