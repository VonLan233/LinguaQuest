import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/data/models/forum.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MockForumRepository', () {
    late MockForumRepository repo;

    setUp(() {
      repo = MockForumRepository();
    });

    test('listPosts returns seeded posts', () async {
      final posts = await repo.listPosts();
      expect(posts.length, greaterThanOrEqualTo(3));
    });

    test('listPosts returns posts with correct tags', () async {
      final posts = await repo.listPosts();
      final tags = posts.map((p) => p.tag).toSet();
      // Seeded posts have Grammar, Vocabulary, Culture tags
      expect(tags, containsAll(['Grammar', 'Vocabulary', 'Culture']));
    });

    test('createPost adds to list', () async {
      final before = await repo.listPosts();
      final beforeCount = before.length;

      await repo.createPost(
        title: 'Test post title',
        body: 'Test post body with some content',
        tag: 'General',
      );

      final after = await repo.listPosts();
      expect(after.length, equals(beforeCount + 1));
    });

    test('createPost returns post with correct fields', () async {
      final post = await repo.createPost(
        title: 'My New Post',
        body: 'Interesting content here',
        tag: 'Grammar',
      );
      expect(post.title, equals('My New Post'));
      expect(post.body, equals('Interesting content here'));
      expect(post.tag, equals('Grammar'));
      expect(post.likeCount, equals(0));
      expect(post.commentCount, equals(0));
      expect(post.isLiked, isFalse);
      expect(post.isFavorited, isFalse);
    });

    test('createComment appends to post', () async {
      final posts = await repo.listPosts();
      final postId = posts.first.id;

      final before = await repo.listComments(postId);
      expect(before, isEmpty);

      await repo.createComment(postId: postId, body: 'Great post!');

      final after = await repo.listComments(postId);
      expect(after.length, equals(1));
      expect(after.first.body, equals('Great post!'));
      expect(after.first.postId, equals(postId));
    });

    test('createComment increments commentCount on post', () async {
      final posts = await repo.listPosts();
      final postId = posts.first.id;
      final initialCount = posts.first.commentCount;

      await repo.createComment(postId: postId, body: 'A comment');

      final updatedPosts = await repo.listPosts();
      final updatedPost = updatedPosts.firstWhere((p) => p.id == postId);
      expect(updatedPost.commentCount, equals(initialCount + 1));
    });

    test('toggleLike returns true then false', () async {
      final posts = await repo.listPosts();
      final postId = posts.first.id;
      final initialLikeCount = posts.first.likeCount;

      final liked = await repo.toggleLike(postId);
      expect(liked, isTrue);

      final postsAfterLike = await repo.listPosts();
      final likedPost = postsAfterLike.firstWhere((p) => p.id == postId);
      expect(likedPost.isLiked, isTrue);
      expect(likedPost.likeCount, equals(initialLikeCount + 1));

      final unliked = await repo.toggleLike(postId);
      expect(unliked, isFalse);

      final postsAfterUnlike = await repo.listPosts();
      final unlikedPost = postsAfterUnlike.firstWhere((p) => p.id == postId);
      expect(unlikedPost.isLiked, isFalse);
      expect(unlikedPost.likeCount, equals(initialLikeCount));
    });

    test('toggleFavorite returns true then false', () async {
      final posts = await repo.listPosts();
      final postId = posts.first.id;

      final favorited = await repo.toggleFavorite(postId);
      expect(favorited, isTrue);

      final unfavorited = await repo.toggleFavorite(postId);
      expect(unfavorited, isFalse);
    });

    test('getPost returns correct post', () async {
      final posts = await repo.listPosts();
      final target = posts.first;

      final fetched = await repo.getPost(target.id);
      expect(fetched.id, equals(target.id));
      expect(fetched.title, equals(target.title));
    });

    test('getPost throws for unknown id', () async {
      expect(
        () => repo.getPost('non-existent-post-id'),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('ForumPost', () {
    test('fromJson/toJson round-trip', () {
      final original = ForumPost(
        id: 'post-123',
        authorId: 'user-456',
        authorName: 'Alice',
        title: 'Test Title',
        body: 'Test body content',
        tag: 'Grammar',
        status: 'approved',
        likeCount: 5,
        commentCount: 2,
        isLiked: true,
        isFavorited: false,
        createdAt: DateTime.utc(2026, 6, 1, 12, 0, 0),
      );

      final json = original.toJson();
      final restored = ForumPost.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.authorId, equals(original.authorId));
      expect(restored.authorName, equals(original.authorName));
      expect(restored.title, equals(original.title));
      expect(restored.body, equals(original.body));
      expect(restored.tag, equals(original.tag));
      expect(restored.status, equals(original.status));
      expect(restored.likeCount, equals(original.likeCount));
      expect(restored.commentCount, equals(original.commentCount));
      expect(restored.isLiked, equals(original.isLiked));
      expect(restored.isFavorited, equals(original.isFavorited));
    });

    test('fromJson handles missing fields with defaults', () {
      final post = ForumPost.fromJson({'id': 'abc'});
      expect(post.id, equals('abc'));
      expect(post.tag, equals('General'));
      expect(post.status, equals('approved'));
      expect(post.likeCount, equals(0));
      expect(post.commentCount, equals(0));
      expect(post.isLiked, isFalse);
      expect(post.isFavorited, isFalse);
      expect(post.authorName, equals('Anonymous'));
    });

    test('copyWith produces updated copy', () {
      final original = ForumPost(
        id: 'x',
        authorId: 'u',
        authorName: 'Bob',
        title: 'Old Title',
        body: 'Old body',
        tag: 'General',
        status: 'approved',
        likeCount: 0,
        commentCount: 0,
        isLiked: false,
        isFavorited: false,
        createdAt: _kFixedDate,
      );

      final updated = original.copyWith(likeCount: 3, isLiked: true);
      expect(updated.likeCount, equals(3));
      expect(updated.isLiked, isTrue);
      expect(updated.title, equals('Old Title')); // unchanged
    });
  });

  group('ForumComment', () {
    test('fromJson/toJson round-trip', () {
      final original = ForumComment(
        id: 'comment-1',
        postId: 'post-1',
        authorId: 'user-1',
        authorName: 'Bob',
        body: 'This is a comment',
        createdAt: DateTime.utc(2026, 6, 2, 8, 0, 0),
      );

      final json = original.toJson();
      final restored = ForumComment.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.postId, equals(original.postId));
      expect(restored.authorId, equals(original.authorId));
      expect(restored.authorName, equals(original.authorName));
      expect(restored.body, equals(original.body));
    });
  });
}

final _kFixedDate = DateTime.utc(2026, 1, 1);
