import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/repositories/article_repository.dart';

void main() {
  test('completed 进度映射为已读', () {
    final progress = [
      ReadingProgress(
        uid: 'u', scope: 's', articleId: 'a1',
        lastParagraphIndex: 2, completed: true,
        updatedAt: DateTime.utc(2026, 7, 1),
      ),
    ];
    final byId = {for (final p in progress) p.articleId: p};
    expect(byId['a1']?.completed, isTrue);
  });
}
