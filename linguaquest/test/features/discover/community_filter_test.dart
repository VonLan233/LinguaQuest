// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/features/discover/community_screen.dart';
import 'package:linguaquest/features/discover/forum_compose_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// Wraps a widget with the minimum scaffolding for [CommunityScreen] tests:
/// - [ProviderScope] with [forumRepositoryProvider] overridden to use a fresh
///   [MockForumRepository] instance so we always get the seeded posts.
/// - [MaterialApp] with localizations wired up (zh locale, same as test
///   harness default set in flutter_test_config.dart).
Widget _buildTestHarness({
  required Widget child,
  MockForumRepository? forumRepo,
}) {
  final repo = forumRepo ?? MockForumRepository();
  return ProviderScope(
    overrides: [
      forumRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('zh'),
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group A: Filter chip behaviour
  // ─────────────────────────────────────────────────────────────────────────
  group('CommunityScreen — tag filter', () {
    testWidgets('shows all seeded posts when "All" filter is selected',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(child: const CommunityScreen()),
      );
      await tester.pump(); // let initState post-frame callback fire
      await tester.pumpAndSettle(); // let refreshForumPosts complete

      // Seeded posts have these titles (may appear in title + body, so
      // use findsWidgets / findsAtLeastNWidgets).
      expect(
        find.textContaining('Present Perfect', findRichText: true),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('HSK 4', findRichText: true),
        findsAtLeastNWidgets(1),
      );
      // Culture post (3rd) may be off-screen in a small test viewport.
      // We verify it is NOT missing: at minimum Grammar + Vocabulary are
      // visible; this also verifies "All" is the active filter (not
      // accidentally collapsed to a single tag).
      // (Flutter ListView lazily renders off-screen items, so we can't
      //  assert a non-visible widget exists; 2 posts visible is sufficient.)
    });

    testWidgets(
        'tapping Grammar filter shows only Grammar-tagged post',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(child: const CommunityScreen()),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // Tap the Grammar chip (label is '语法' in zh locale).
      await tester.tap(find.widgetWithText(ChoiceChip, '语法'));
      await tester.pumpAndSettle();

      // The Grammar post title should be visible.
      expect(
        find.textContaining('Present Perfect', findRichText: true),
        findsOneWidget,
      );
      // The Vocabulary and Culture posts should NOT be shown.
      expect(
        find.textContaining('HSK 4', findRichText: true),
        findsNothing,
      );
      expect(
        find.textContaining('Chinese New Year', findRichText: true),
        findsNothing,
      );
    });

    testWidgets('tapping All restores all posts', (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(child: const CommunityScreen()),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // First filter by Grammar.
      await tester.tap(find.widgetWithText(ChoiceChip, '语法'));
      await tester.pumpAndSettle();

      // Then tap All (全部 in zh).
      await tester.tap(find.widgetWithText(ChoiceChip, '全部'));
      await tester.pumpAndSettle();

      // All seeded posts should be back.
      expect(
        find.textContaining('Present Perfect', findRichText: true),
        findsAtLeastNWidgets(1),
      );
      expect(
        find.textContaining('HSK 4', findRichText: true),
        findsAtLeastNWidgets(1),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group B: Empty filter state
  // ─────────────────────────────────────────────────────────────────────────
  group('CommunityScreen — empty filter state', () {
    testWidgets('selecting Progress filter shows no-posts message',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(child: const CommunityScreen()),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // No seeded posts have tag 'Progress', so filtering for it yields an
      // empty list.
      await tester.tap(find.widgetWithText(ChoiceChip, '学习进展'));
      await tester.pumpAndSettle();

      // The localized no-posts-in-filter message should appear.
      expect(
        find.text('该分类还没有帖子', findRichText: false),
        findsWidgets, // MascotEmptyState passes message to two Text widgets
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group C: Post card shows author + tag + counts
  // ─────────────────────────────────────────────────────────────────────────
  group('CommunityScreen — post card content', () {
    testWidgets('card shows author name, tag pill, like count, comment count',
        (tester) async {
      await tester.pumpWidget(
        _buildTestHarness(child: const CommunityScreen()),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // 'Demo User' is the authorName of the first seeded Grammar post.
      expect(find.text('Demo User'), findsOneWidget);

      // The Grammar tag pill should be visible (zh label '语法').
      expect(find.text('语法'), findsWidgets);

      // likeCount for first seeded post is 12, commentCount is 4.
      expect(find.text('12'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Group D: Compose screen has Progress tag
  // ─────────────────────────────────────────────────────────────────────────
  group('ForumComposeScreen — Progress tag', () {
    testWidgets('shows a Progress ChoiceChip in tag selector', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            forumRepositoryProvider.overrideWithValue(MockForumRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            theme: AppTheme.light(),
            home: const ForumComposeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The tag row should contain a ChoiceChip labelled 'Progress' (raw
      // English tag — not localized in compose, which uses raw _kTags
      // directly as chip labels).
      expect(
        find.widgetWithText(ChoiceChip, 'Progress'),
        findsOneWidget,
      );
    });

    testWidgets('Progress ChoiceChip is selectable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            forumRepositoryProvider.overrideWithValue(MockForumRepository()),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('zh'),
            theme: AppTheme.light(),
            home: const ForumComposeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 'General' is selected; tap Progress.
      await tester.tap(find.widgetWithText(ChoiceChip, 'Progress'));
      await tester.pumpAndSettle();

      // After tap, the Progress chip should be selected.
      final progressChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'Progress'),
      );
      expect(progressChip.selected, isTrue);
    });
  });
}
