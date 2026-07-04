// Tests for Bug A: ForumPostDetailScreen loads post by id via getPost()
// so navigating from My Favorites (empty forumPosts list) works correctly.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/models/forum.dart';
import 'package:linguaquest/data/repositories/forum_repository.dart';
import 'package:linguaquest/features/discover/forum_post_detail_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// Fake repo: listPosts() returns [] (simulates no posts loaded in memory),
/// getPost('fav-1') returns a real post.
class _FavoritesRepo implements ForumRepository {
  static final _post = ForumPost(
    id: 'fav-1',
    authorId: 'author-42',
    authorName: 'Alice',
    title: 'My favorited post',
    body: 'This post was favorited from another session.',
    tag: 'General',
    status: 'approved',
    likeCount: 5,
    commentCount: 1,
    isLiked: false,
    isFavorited: true,
    createdAt: DateTime.utc(2026, 1, 1),
  );

  @override
  Future<List<ForumPost>> listPosts() async => const [];

  @override
  Future<ForumPost> getPost(String id) async {
    if (id == 'fav-1') return _post;
    throw Exception('Post not found: $id');
  }

  @override
  Future<ForumPost> createPost({
    required String title,
    required String body,
    required String tag,
  }) async => throw UnimplementedError();

  @override
  Future<ForumComment> createComment({
    required String postId,
    required String body,
  }) async => throw UnimplementedError();

  @override
  Future<List<ForumComment>> listComments(String postId) async => const [];

  @override
  Future<bool> toggleLike(String postId) async => false;

  @override
  Future<bool> toggleFavorite(String postId) async => false;

  @override
  Future<void> reportPost(String postId, String reason,
      {String? detail}) async {}

  @override
  Future<List<ForumPost>> listFavoritedPosts() async => [_post];
}

Widget _buildHarness({required String postId}) {
  return ProviderScope(
    overrides: [
      forumRepositoryProvider.overrideWithValue(_FavoritesRepo()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light(),
      home: ForumPostDetailScreen(postId: postId),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ForumPostDetailScreen — load post by id (Bug A fix)', () {
    testWidgets(
        'shows post title when navigated from favorites (forumPosts list is empty)',
        (tester) async {
      await tester.pumpWidget(_buildHarness(postId: 'fav-1'));
      await tester.pumpAndSettle();

      // Post title must be visible
      expect(find.text('My favorited post'), findsOneWidget);
      // "Post not found" must NOT be shown
      expect(find.text('Post not found'), findsNothing);
    });

    testWidgets('shows "Post not found" for unknown postId', (tester) async {
      await tester.pumpWidget(_buildHarness(postId: 'unknown-id'));
      await tester.pumpAndSettle();

      expect(find.text('Post not found'), findsOneWidget);
    });
  });
}
