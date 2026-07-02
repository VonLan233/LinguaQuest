import 'package:test/test.dart';
import 'package:linguaquest_server/src/routes.dart';

void main() {
  test('收藏帖 DTO 标记 isFavorited=true', () {
    final row = {
      'id': 'p1',
      'author_id': 'u2',
      'author_name': 'A',
      'title': 't',
      'body': 'b',
      'tag': 'General',
      'status': 'approved',
      'like_count': 1,
      'comment_count': 0,
      'created_at': DateTime.utc(2026, 7, 1),
      'updated_at': DateTime.utc(2026, 7, 1),
    };
    final dto = forumPostDto(row, isLiked: false, isFavorited: true);
    expect(dto['isFavorited'], isTrue);
    expect(dto['id'], 'p1');
  });
}
