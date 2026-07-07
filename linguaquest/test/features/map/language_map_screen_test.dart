import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/features/map/language_map_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

Widget _app(ThemeData theme) => ProviderScope(
  child: MaterialApp(
    theme: theme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: const LanguageMapScreen(),
  ),
);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('renders 6 language markers without exception (light & dark)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      await tester.pumpWidget(_app(theme));
      await tester.pump();
      for (final code in ['zh', 'en', 'es', 'fr', 'ja', 'ms']) {
        expect(find.byKey(ValueKey('lang-pin-$code')), findsOneWidget);
      }
      // OSM 瓦片在无网络测试里加载失败仅是日志噪音，不应抛异常到测试。
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('tapping an enabled marker shows a card with a learn action', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(AppTheme.light()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lang-pin-zh')));
    // pumpAndSettle 会因永久循环动画（_pulse）超时；用固定帧前进即可。
    await tester.pump(const Duration(milliseconds: 100));
    // 卡片出现，含"开始学习"按钮（languageMapConfirm 文案含语言名）。
    expect(find.byKey(const ValueKey('lang-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('lang-card-start')), findsOneWidget);
  });

  testWidgets('tapping a newly-opened marker (en) shows an enabled card', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(AppTheme.light()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lang-pin-en')));
    // pumpAndSettle 会因永久循环动画（_pulse）超时；用固定帧前进即可。
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('lang-card')), findsOneWidget);
    // en 现已开放：显示开始学习按钮，不再是 coming-soon 标识。
    expect(find.byKey(const ValueKey('lang-card-start')), findsOneWidget);
    expect(find.byKey(const ValueKey('lang-card-soon')), findsNothing);
  });

  // 回归：每个 pin 各自点击必须选中自己对应的语言卡片。旧的“只断言卡片出现”
  // 会被相邻 marker 抢占点击的 bug 蒙混过关（被覆盖的 marker 抢到的仍是一张卡片）。
  // 这里断言卡片内展示的是被点语言的标签，才能真正暴露 zh/es 被 ja/fr 遮挡的问题。
  testWidgets('each pin selects its own language card (no overlap steal)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // code -> unique substring in the selected card label
    const expected = {
      'zh': 'Chinese',
      'en': 'English',
      'es': 'Español',
      'fr': 'Français',
      'ja': 'Japanese',
      'ms': 'Bahasa Melayu',
    };

    await tester.pumpWidget(_app(AppTheme.light()));
    await tester.pump();

    for (final entry in expected.entries) {
      await tester.tap(find.byKey(ValueKey('lang-pin-${entry.key}')));
      await tester.pump(const Duration(milliseconds: 100));
      final card = find.byKey(const ValueKey('lang-card'));
      expect(
        card,
        findsOneWidget,
        reason: 'Tapping ${entry.key} did not open a card',
      );
      expect(
        find.descendant(of: card, matching: find.textContaining(entry.value)),
        findsWidgets,
        reason:
            'Tapping ${entry.key} opened the wrong card, expected ${entry.value}',
      );
      // Close the card so the next marker tap is not affected.
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}
