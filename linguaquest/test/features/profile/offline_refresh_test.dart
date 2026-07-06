// test/features/profile/offline_refresh_test.dart
//
// §7 (P4e): refreshOfflineContent() resets the bundled asset caches and
// repopulates state; the Data & Account screen shows an offline-status row and
// a working Refresh button.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/article_asset_loader.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/repositories/article_repository.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/features/profile/data_settings_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// MockLearningRepository that counts clearOfflineCache + listWordBooks calls.
class _SpyLearningRepository extends MockLearningRepository {
  int clearCalls = 0;
  int listCalls = 0;

  @override
  Future<void> clearOfflineCache() async {
    clearCalls++;
    return super.clearOfflineCache();
  }

  @override
  Future<List<WordBook>> listWordBooks() {
    listCalls++;
    return super.listWordBooks();
  }
}

/// MockArticleRepository that counts clearOfflineCache calls.
class _SpyArticleRepository extends MockArticleRepository {
  _SpyArticleRepository() : super(ArticleAssetLoader());
  int clearCalls = 0;

  @override
  Future<void> clearOfflineCache() async {
    clearCalls++;
    return super.clearOfflineCache();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('refreshOfflineContent resets caches and repopulates wordbooks',
      () async {
    final learning = _SpyLearningRepository();
    final article = _SpyArticleRepository();
    final container = ProviderContainer(
      overrides: [
        learningRepositoryProvider.overrideWithValue(learning),
        articleRepositoryProvider.overrideWithValue(article),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(appControllerProvider.notifier);
    await controller.bootstrap();

    expect(container.read(appControllerProvider).wordBooks, isNotEmpty);
    final listCallsAfterBootstrap = learning.listCalls;

    final ok = await controller.refreshOfflineContent();
    expect(ok, isTrue);

    // Both asset caches were cleared and wordbooks were re-loaded.
    expect(learning.clearCalls, 1);
    expect(article.clearCalls, 1);
    expect(learning.listCalls, greaterThan(listCallsAfterBootstrap));
    expect(container.read(appControllerProvider).wordBooks, isNotEmpty);
  });

  testWidgets('Data settings shows offline status + working refresh button',
      (tester) async {
    final learning = _SpyLearningRepository();
    final article = _SpyArticleRepository();

    final router = GoRouter(
      initialLocation: '/data',
      routes: [
        GoRoute(
          path: '/data',
          builder: (context, state) => const DataSettingsScreen(),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learningRepositoryProvider.overrideWithValue(learning),
          articleRepositoryProvider.overrideWithValue(article),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Bootstrap so the controller has a real scope for the status row.
    final element = tester.element(find.byType(DataSettingsScreen));
    final container = ProviderScope.containerOf(element);
    await container.read(appControllerProvider.notifier).bootstrap();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('offline-content-card')), findsOneWidget);
    expect(find.text('Available offline'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('offline-refresh-button')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('offline-refresh-button')));
    await tester.pumpAndSettle();

    expect(learning.clearCalls, greaterThanOrEqualTo(1));
    expect(find.text('Offline content refreshed'), findsOneWidget);
  });
}
