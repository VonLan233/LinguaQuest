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

  testWidgets('renders 6 language markers without exception (light & dark)',
      (tester) async {
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

  testWidgets('tapping an enabled marker shows a card with a learn action',
      (tester) async {
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

  testWidgets('tapping a coming-soon marker shows a disabled card',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_app(AppTheme.light()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lang-pin-en')));
    // pumpAndSettle 会因永久循环动画（_pulse）超时；用固定帧前进即可。
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('lang-card')), findsOneWidget);
    // 未开放：没有可用的开始按钮（用 coming-soon 标识替代）。
    expect(find.byKey(const ValueKey('lang-card-soon')), findsOneWidget);
  });
}
