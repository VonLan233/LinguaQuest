import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/features/discover/forum_compose_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  // appControllerProvider 依赖 SharedPreferences，测试中需提供 mock 初始值
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('空标题点 Publish 显示 inline 校验错误', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // 提供 mock forum repository，防止 ForumComposeScreen 内部 provider 初始化失败
          forumRepositoryProvider.overrideWithValue(MockForumRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ForumComposeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 不填写任何内容，直接点 Publish
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    // 空标题的 inline 校验错误应出现在标题输入框下方
    expect(find.text('Please enter a title.'), findsOneWidget);
  });

  testWidgets('空正文点 Publish 显示 inline 校验错误', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          forumRepositoryProvider.overrideWithValue(MockForumRepository()),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ForumComposeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 填写标题但不填写正文
    await tester.enterText(
      find.byType(TextFormField).first,
      'A valid title',
    );
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();

    // 空正文的 inline 校验错误应出现
    expect(find.text('Please enter some content.'), findsOneWidget);
    // 标题已填写，不应出现标题错误
    expect(find.text('Please enter a title.'), findsNothing);
  });
}
