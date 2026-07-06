import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/features/discover/my_favorites_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

/// 构建测试脚手架：ProviderScope 覆盖 forumRepositoryProvider → MockForumRepository，
/// 保证测试不打真实网络。
Widget _buildHarness({required Widget child, MockForumRepository? repo}) {
  final forumRepo = repo ?? MockForumRepository();
  return ProviderScope(
    overrides: [
      forumRepositoryProvider.overrideWithValue(forumRepo),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      theme: AppTheme.light(),
      home: child,
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MyFavoritesScreen', () {
    testWidgets('空收藏时显示空态文案', (tester) async {
      // MockForumRepository 默认无收藏 → listFavoritedPosts 返回 []
      await tester.pumpWidget(
        _buildHarness(child: const MyFavoritesScreen()),
      );
      await tester.pump(); // post-frame callback 触发
      await tester.pumpAndSettle(); // 等待 refreshFavoritedPosts 完成

      expect(
        find.text("You haven't favorited any posts yet."),
        findsOneWidget,
      );
    });

    testWidgets('有收藏时显示帖子标题', (tester) async {
      // 创建含有已收藏帖子的 mock repo
      final repo = MockForumRepository();
      // 先 toggleFavorite 某个种子帖子（id = mock-post-1）
      await repo.toggleFavorite('mock-post-1');

      // 从 repo 动态获取实际的收藏帖子标题，避免硬编码依赖 mock 种子数据
      final favoritedPosts = await repo.listFavoritedPosts();
      final actualTitle = favoritedPosts.isNotEmpty ? favoritedPosts.first.title : '';

      await tester.pumpWidget(
        _buildHarness(child: const MyFavoritesScreen(), repo: repo),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      // 验证实际帖子标题显示在列表中
      expect(
        find.textContaining(actualTitle, findRichText: true),
        findsAtLeastNWidgets(1),
      );
      // 空态文案不应显示
      expect(
        find.text("You haven't favorited any posts yet."),
        findsNothing,
      );
    });
  });
}
