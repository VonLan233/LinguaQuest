// test/features/discover/scope_tags_test.dart
//
// §8 (P4f): the user's current learning scope (e.g. "HSK 1" / "JLPT N5") is
// offered as a one-tap tag in compose and as a filter option in community.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/features/discover/community_screen.dart';
import 'package:linguaquest/features/discover/forum_compose_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('compose scope chip posts a scope-tagged post (§8 P4f)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Bootstrap so the controller resolves the default scope (zh::hsk1 → HSK 1).
    await container.read(appControllerProvider.notifier).bootstrap();

    final composeRouter = GoRouter(
      initialLocation: '/discover/community',
      routes: [
        GoRoute(
          path: '/discover/community',
          builder: (context, state) => const CommunityScreen(),
          routes: [
            GoRoute(
              path: 'compose',
              builder: (context, state) => const ForumComposeScreen(),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light(),
          routerConfig: composeRouter,
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Push the compose screen so context.pop() has a route to pop.
    composeRouter.push('/discover/community/compose');
    await tester.pumpAndSettle();

    // The current-scope chip is present.
    final chipFinder = find.byKey(const ValueKey('compose-scope-chip'));
    expect(chipFinder, findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'HSK 1'), findsOneWidget);

    // Fill the form, select the scope chip, and publish.
    await tester.enterText(find.byType(TextField).first, 'My HSK 1 progress');
    await tester.enterText(
      find.byType(TextField).last,
      'Sharing how my HSK 1 study is going.',
    );
    await tester.tap(chipFinder);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    // The newly created post carries the scope string as its tag.
    final posts = container.read(appControllerProvider).forumPosts;
    expect(posts.first.tag, 'HSK 1');
    expect(posts.first.title, 'My HSK 1 progress');
  });

  testWidgets('community scope filter narrows the list (§8 P4f)',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);
    await controller.bootstrap();

    // Seed posts: one tagged with the current scope, one with a topic tag.
    await controller.createForumPost(
      title: 'Scope post',
      body: 'Tagged with current scope.',
      tag: 'HSK 1',
    );
    await controller.createForumPost(
      title: 'Grammar post',
      body: 'Tagged Grammar.',
      tag: 'Grammar',
    );

    final router = GoRouter(
      initialLocation: '/community',
      routes: [
        GoRoute(
          path: '/community',
          builder: (context, state) => const CommunityScreen(),
        ),
        GoRoute(
          path: '/forum/compose',
          builder: (context, state) => const ForumComposeScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Both posts visible under "All".
    expect(find.text('Scope post'), findsOneWidget);
    expect(find.text('Grammar post'), findsOneWidget);

    // The scope filter chip is appended after the fixed topic filters; it may
    // be off-screen in the horizontal filter row, so scroll it into view first.
    final scopeChip = find.widgetWithText(ChoiceChip, 'HSK 1');
    await tester.scrollUntilVisible(
      scopeChip,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Select the scope filter chip → only the scope-tagged post remains.
    await tester.tap(scopeChip);
    await tester.pumpAndSettle();

    expect(find.text('Scope post'), findsOneWidget);
    expect(find.text('Grammar post'), findsNothing);
  });
}
