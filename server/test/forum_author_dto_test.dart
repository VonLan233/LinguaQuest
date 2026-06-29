import 'package:linguaquest_server/src/routes.dart';
import 'package:test/test.dart';

void main() {
  group('forumPostDto — authorName field', () {
    Map<String, dynamic> _minimalRow({Object? authorName}) => {
          'id': 'a1b2c3d4-0000-0000-0000-000000000001',
          'author_id': 'user-1',
          'author_name': authorName,
          'title': 'Test Post',
          'body': 'Test body',
          'tag': 'General',
          'status': 'approved',
          'like_count': 0,
          'comment_count': 0,
          'created_at': DateTime.utc(2026, 1, 1),
          'updated_at': DateTime.utc(2026, 1, 1),
        };

    test('returns author_name as authorName when present', () {
      final dto = forumPostDto(
        _minimalRow(authorName: 'Vinnie'),
        isLiked: false,
        isFavorited: false,
      );
      expect(dto['authorName'], 'Vinnie');
    });

    test('falls back to "User" when author_name is null', () {
      final dto = forumPostDto(
        _minimalRow(authorName: null),
        isLiked: false,
        isFavorited: false,
      );
      expect(dto['authorName'], 'User');
    });

    test('includes expected keys alongside authorName', () {
      final dto = forumPostDto(
        _minimalRow(authorName: 'TestUser'),
        isLiked: true,
        isFavorited: false,
      );
      expect(dto['id'], 'a1b2c3d4-0000-0000-0000-000000000001');
      expect(dto['authorId'], 'user-1');
      expect(dto['authorName'], 'TestUser');
      expect(dto['isLiked'], isTrue);
      expect(dto['isFavorited'], isFalse);
    });
  });
}
