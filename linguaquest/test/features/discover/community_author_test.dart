import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/models/forum.dart';
import 'package:linguaquest/data/repositories/forum_repository.dart';
import 'package:linguaquest/features/discover/community_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// A minimal [ForumRepository] that returns exactly one post with a
/// configurable [authorName].
class _SinglePostRepo implements ForumRepository {
  _SinglePostRepo(this.authorName);

  final String authorName;

  @override
  Future<List<ForumPost>> listPosts() async => [
        ForumPost(
          id: 'test-post-1',
          authorId: 'author-1',
          authorName: authorName,
          title: 'Test Title',
          body: 'Test body content.',
          tag: 'General',
          status: 'approved',
          likeCount: 0,
          commentCount: 0,
          isLiked: false,
          isFavorited: false,
          createdAt: DateTime.utc(2026, 6, 1),
        ),
      ];

  @override
  Future<ForumPost> getPost(String id) async => (await listPosts()).first;

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
  Future<List<ForumComment>> listComments(String postId) async => [];

  @override
  Future<bool> toggleLike(String postId) async => false;

  @override
  Future<bool> toggleFavorite(String postId) async => false;

  @override
  Future<void> reportPost(String postId, String reason, {String? detail}) async {}

  @override
  Future<List<ForumPost>> listFavoritedPosts() async => const [];
}

Widget _buildHarness({required ForumRepository repo}) {
  return ProviderScope(
    overrides: [forumRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      theme: AppTheme.light(),
      home: const CommunityScreen(),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CommunityScreen — author avatar', () {
    testWidgets('renders authorName text for a post', (tester) async {
      await tester.pumpWidget(_buildHarness(repo: _SinglePostRepo('Lan')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Lan'), findsOneWidget);
    });

    testWidgets('renders a CircleAvatar next to the author name', (tester) async {
      await tester.pumpWidget(_buildHarness(repo: _SinglePostRepo('Lan')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('avatar initial letter matches first char of authorName',
        (tester) async {
      await tester.pumpWidget(_buildHarness(repo: _SinglePostRepo('Lan')));
      await tester.pump();
      await tester.pumpAndSettle();

      // The avatar should contain the initial 'L'.
      expect(find.text('L'), findsOneWidget);
    });
  });
}
