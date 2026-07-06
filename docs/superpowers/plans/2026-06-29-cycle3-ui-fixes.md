# Cycle 3 UI 修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复四个设备测试报告的 UI 问题：语言选择器药丸右对齐、词书 Current 即时跟随切换、发帖/社区 chip 文字在 light mode 可读、语言选择地图游戏化美化（底图保持 OSM）。

**Architecture:** 纯客户端修复（`linguaquest/`）。问题 1-3 是聚焦改动（布局/状态/主题）；问题 4 把 `language_map_screen.dart` 从无状态重构为有状态、在真 OSM 地图之上叠加自定义 marker / 动画 / 点击卡片 / dark 遮罩。

**Tech Stack:** Flutter 3.41.6, Riverpod, go_router, flutter_map + OpenStreetMap 瓦片。

## Global Constraints

- 无新依赖；只用 Flutter 内置 + 现有包（flutter_map / latlong2 已在用）。
- 不破坏 light/dark 两套主题；改动后 `flutter analyze` 干净、`flutter test` 全绿。
- **地图底图必须是真实地图 API**：保留 `flutter_map` + OSM 官方瓦片 `https://tile.openstreetmap.org/{z}/{x}/{y}.png`，**不可换成 CartoDB/插画/伪地图**，不可替换地图引擎（rubric 必做项）。
- UI 文案优先复用现有 l10n key（本轮尽量不新增 ARB key，避免翻译 churn）。
- 命令从 `/Users/lanyichen/Codes/Mobile/ASM2/linguaquest` 运行。
- 行号可能因前序 task 轻微移位，按实际代码匹配，不要死认绝对行号。

---

### Task 1: 问题 1 — 语言选择器药丸右对齐

**Files:**
- Modify: `linguaquest/lib/core/widgets/language_wordbook_picker.dart`（`_LanguageRow.build` 的 `Row`，约 358-368 行）
- Test: `linguaquest/test/core/widgets/language_wordbook_picker_test.dart`

**Interfaces:** 无新接口；纯布局修复。

- [ ] **Step 1: 写失败测试**

在 `language_wordbook_picker_test.dart` 的 `group('LanguageWordbookPicker', ...)` 内加（复用文件里已有的 `_harness` / `_bothLangState`）：

```dart
    testWidgets('language rows use Expanded (no Spacer) for aligned pills',
        (tester) async {
      await tester.pumpWidget(_harness(state: _bothLangState()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // 语言行不应再使用 Spacer（药丸靠 Expanded 推到右内边距，右缘对齐）。
      expect(find.byType(Spacer), findsNothing);
    });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/widgets/language_wordbook_picker_test.dart -n "aligned pills"`
Expected: FAIL — 当前 `_LanguageRow` 用了 `Spacer`，`findsNothing` 失败。

- [ ] **Step 3: 改 `_LanguageRow`**

在 `_LanguageRow.build` 的 `Row` 中，把 `Flexible(child: Text(...))` 改为 `Expanded(child: Text(...))`，并删除其紧随的 `const Spacer(),`。即从：

```dart
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: ...,
            ),
          ),
          const Spacer(),
          if (isCurrent)
```

改为：

```dart
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: ...,
            ),
          ),
          if (isCurrent)
```

（`Text` 的 `style`/内容不变；只把 `Flexible`→`Expanded` 且删掉 `const Spacer(),` 这一行。）

- [ ] **Step 4: 跑测试 + analyze**

Run: `flutter test test/core/widgets/language_wordbook_picker_test.dart`
Expected: PASS（新测试 + 既有测试都过）
Run: `flutter analyze lib/core/widgets/language_wordbook_picker.dart`
Expected: No issues.

- [ ] **Step 5: 提交**

```bash
git add linguaquest/lib/core/widgets/language_wordbook_picker.dart linguaquest/test/core/widgets/language_wordbook_picker_test.dart
git commit -m "fix(picker): 语言行用 Expanded 让右侧药丸对齐"
```

---

### Task 2: 问题 2 — 词书 Current 即时跟随 + bootstrap 读键对称

**Files:**
- Modify: `linguaquest/lib/core/widgets/language_wordbook_picker.dart`（`_onBookSelected`，约 134-171 行）
- Modify: `linguaquest/lib/core/state/app_controller.dart`（bootstrap 的 `savedId`，约 290-295 行）
- Test: `linguaquest/test/core/widgets/language_wordbook_picker_test.dart`

**Interfaces:**
- Consumes: `AppController.switchWordBook(String) → Future<bool>`、`switchScope(String,String) → Future<bool>`（已存在）；`_currentWordBookIdForLangKey(String)`（app_controller 私有，约 202 行）。
- Produces: 切换成功后 sheet 不关闭、选中词书即时高亮 Current；bootstrap 读 per-language 键。

- [ ] **Step 1: 写失败测试**

在 picker 测试文件加（复用 `_harness`/`_zhState`，hsk1 为 current）。注意 `_FakeNotifier.switchWordBook` 已在文件中 stub 为返回 true 并记录调用——但它不会改 state.currentWordBookId。为让"即时高亮"可测，本测试断言两点：点击后 sheet 仍在（标题 `Choose Wordbook` 仍可见）、且 `switchWordBook` 被调用：

```dart
    testWidgets('selecting a wordbook keeps the sheet open (immediate highlight)',
        (tester) async {
      _FakeNotifier? captured;
      await tester.pumpWidget(_harness(
        state: _zhState(books: 6),
        capture: (n) => captured = n,
      ));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Chinese (中文)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('HSK2'));
      await tester.pumpAndSettle();
      // 切换被调用，但 sheet 不再立即关闭（标题仍在）。
      expect(captured!.switchCalls, contains('hsk2'));
      expect(find.text('Choose Wordbook'), findsOneWidget);
    });
```

> 若 `_harness` 的 capture 形参签名不同，按文件实际签名调整；`_zhState`/`_FakeNotifier`/`switchCalls` 均为该文件既有定义。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/widgets/language_wordbook_picker_test.dart -n "keeps the sheet open"`
Expected: FAIL — 当前 `_onBookSelected` 成功后调用 `widget.onDismiss()` 关闭 sheet，`Choose Wordbook` 不再可见。

- [ ] **Step 3: 改 `_onBookSelected`（不立即关闭）**

把成功分支里的 `widget.onDismiss();` 删除，改为 `setState(() {})` 触发重建（让新 `currentWordBookId` 反映为 Current）。即把：

```dart
    if (ok) {
      WordBook? selected;
      for (final b in booksBefore) {
        if (b.id == bookId) {
          selected = b;
          break;
        }
      }
      final label = selected?.nameFor(localeCode) ?? bookId;
      widget.onDismiss();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pickerSwitchSuccess(label))),
      );
    } else {
```

改为：

```dart
    if (ok) {
      WordBook? selected;
      for (final b in booksBefore) {
        if (b.id == bookId) {
          selected = b;
          break;
        }
      }
      final label = selected?.nameFor(localeCode) ?? bookId;
      // 不立即关闭 sheet：让选中词书即时高亮 Current，用户自行关闭。
      if (mounted) setState(() {});
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pickerSwitchSuccess(label))),
      );
    } else {
```

（`_onBookSelected` 所在的 `_LanguageWordbookPickerSheetState` 是 `ConsumerState`，`setState` 可用；失败分支不变。）

- [ ] **Step 4: 改 bootstrap 的 `savedId`（读键对称）**

在 `app_controller.dart` bootstrap 里 `_resolveCurrentWordBookId(...)` 的调用处，把：

```dart
      final currentWordBookId = _resolveCurrentWordBookId(
        books: wordBooks,
        savedId:
            studyPlan?.wordBookId ?? prefs.getString(_currentWordBookIdKey),
        target: user?.targetExam,
      );
```

改为（补上 per-language 键，与保存端双键写入对称）：

```dart
      final currentWordBookId = _resolveCurrentWordBookId(
        books: wordBooks,
        savedId: studyPlan?.wordBookId ??
            prefs.getString(_currentWordBookIdForLangKey(currentLanguage)) ??
            prefs.getString(_currentWordBookIdKey),
        target: user?.targetExam,
      );
```

（`currentLanguage` 在该作用域已定义；`_currentWordBookIdForLangKey` 为已存在的私有静态方法。）

- [ ] **Step 5: 跑测试 + analyze**

Run: `flutter test test/core/widgets/language_wordbook_picker_test.dart`
Expected: PASS（注意：文件里既有的"selecting Chinese ... switch"类测试若断言"切换后 sheet 关闭"，需同步更新为"sheet 仍在"——按实际报错调整既有断言，不要让它们假阳性挡路）。
Run: `flutter analyze lib/core/widgets/language_wordbook_picker.dart lib/core/state/app_controller.dart`
Expected: No issues.

- [ ] **Step 6: 全量回归（state 改动影响面）**

Run: `flutter test`
Expected: 全绿。bootstrap `savedId` 改动可能影响 app_controller 相关测试——若有断言旧行为的测试，按新（更正确的）行为更新。

- [ ] **Step 7: 提交**

```bash
git add linguaquest/lib/core/widgets/language_wordbook_picker.dart linguaquest/lib/core/state/app_controller.dart linguaquest/test/core/widgets/language_wordbook_picker_test.dart
git commit -m "fix(picker): 切换词书后即时高亮 Current（不立即关闭）+ bootstrap 读键对称"
```

---

### Task 3: 问题 3 — chip 文字颜色受控可读

**Files:**
- Modify: `linguaquest/lib/core/theme/app_theme.dart`（`chipLabelStyle` 定义，约 124-137 行；`chipTheme` 约 221-232 行无需改，labelStyle 引用同名变量）
- Test: `linguaquest/test/core/theme/app_theme_test.dart`（约 25-41 行的 chip 测试）

**Interfaces:**
- Produces: `ThemeData.chipTheme.labelStyle` 为普通 `TextStyle`（非 `WidgetStateTextStyle`），color = `scheme.onSurface`。

- [ ] **Step 1: 改测试为新行为（先改测试断言、确认它对当前代码失败）**

把 `app_theme_test.dart` 里 `test('light theme chip labels are readable...')` 整体替换为：

```dart
  test('chip labels carry a concrete onSurface color (light + dark)', () {
    for (final pair in {
      'light': AppTheme.light(),
      'dark': AppTheme.dark(),
    }.entries) {
      final labelStyle = pair.value.chipTheme.labelStyle;
      expect(labelStyle, isNotNull, reason: pair.key);
      // 普通 TextStyle，颜色受控为 onSurface（不再是 resolve 才有颜色的
      // WidgetStateTextStyle —— 那种在 ChoiceChip 上 color 解析为 null）。
      expect(labelStyle, isNot(isA<WidgetStateTextStyle>()), reason: pair.key);
      expect(labelStyle!.color, pair.value.colorScheme.onSurface,
          reason: pair.key);
      // 必须带具体字号，颜色才会被 chip 默认 merge 保留。
      expect(labelStyle.fontSize, isNotNull, reason: pair.key);
    }
  });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/theme/app_theme_test.dart -n "concrete onSurface color"`
Expected: FAIL — 当前 `labelStyle` 是 `WidgetStateTextStyle`，`isNot(isA<WidgetStateTextStyle>())` 失败。

- [ ] **Step 3: 改 `chipLabelStyle`**

在 `app_theme.dart` `_base` 里，把 `chipLabelStyle` 从 `WidgetStateTextStyle.resolveWith(...)` 整段替换为一个带确定颜色的普通 `TextStyle`：

```dart
    // 普通 TextStyle（非 WidgetStateTextStyle）：ChoiceChip 不会 resolve
    // WidgetStateTextStyle，会导致 label color 解析为 null、在 light 下白底白字。
    // 这里直接给 onSurface，light/dark 都可读；选中态靠 selectedColor 背景区分。
    final chipLabelStyle = chipBaseStyle.copyWith(
      color: scheme.onSurface,
      fontWeight: FontWeight.w600,
    );
```

`chipTheme` 里 `labelStyle: chipLabelStyle` 和 `secondaryLabelStyle: chipLabelStyle` 引用同名变量，无需改动。

- [ ] **Step 4: 跑测试 + analyze**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS
Run: `flutter analyze lib/core/theme/app_theme.dart`
Expected: No issues.

- [ ] **Step 5: 全量回归（全局 chip 主题改动）**

Run: `flutter test`
Expected: 全绿（若别处有断言旧 chip 选中色的测试，按新行为更新）。

- [ ] **Step 6: 提交**

```bash
git add linguaquest/lib/core/theme/app_theme.dart linguaquest/test/core/theme/app_theme_test.dart
git commit -m "fix(theme): chip label 用普通 TextStyle 带 onSurface 颜色（修 light 白底白字）"
```

---

### Task 4: 问题 4 — 语言选择地图游戏化美化（底图保持 OSM）

**Files:**
- Modify（整文件重写）: `linguaquest/lib/features/map/language_map_screen.dart`
- Test: `linguaquest/test/features/map/language_map_screen_test.dart`（新建或扩展既有）

**Interfaces:**
- Consumes: `AppController.updateTargetLanguage(String)`、`showLanguageWordbookPicker(context, initialLanguage:)`（均已存在）；l10n key `languageMapTitle` / `languageMapSelectPrompt` / `languageMapConfirm(language)` / `languageMapComingSoon(language)`（均已存在，见 `app_en.arb`）。
- Produces: 有状态的 `LanguageMapScreen`，真 OSM 底图 + 自定义 marker（标签气泡 + 圆形徽章 + 入场/呼吸动画）+ 点击弹卡片 + dark 遮罩。marker 仍带 `ValueKey('lang-pin-<code>')`。

- [ ] **Step 1: 写测试（冒烟 + marker key + 数据）**

新建 `linguaquest/test/features/map/language_map_screen_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
  testWidgets('renders 6 language markers without exception (light & dark)',
      (tester) async {
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
    await tester.pumpWidget(_app(AppTheme.light()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lang-pin-zh')));
    await tester.pumpAndSettle();
    // 卡片出现，含"开始学习"按钮（languageMapConfirm 文案含语言名）。
    expect(find.byKey(const ValueKey('lang-card')), findsOneWidget);
    expect(find.byKey(const ValueKey('lang-card-start')), findsOneWidget);
  });

  testWidgets('tapping a coming-soon marker shows a disabled card',
      (tester) async {
    await tester.pumpWidget(_app(AppTheme.light()));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('lang-pin-en')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('lang-card')), findsOneWidget);
    // 未开放：没有可用的开始按钮（用 coming-soon 标识替代）。
    expect(find.byKey(const ValueKey('lang-card-soon')), findsOneWidget);
  });
}
```

> 若 marker 因初始视口/尺寸在测试中不可点击，先用 `tester.binding.window` 设较大尺寸（如 `tester.view.physicalSize = const Size(1200, 2000)`，`tester.view.devicePixelRatio = 1.0`，并在末尾 `addTearDown(tester.view.reset)`）。FlutterMap 在测试里需要有界尺寸。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/features/map/language_map_screen_test.dart`
Expected: FAIL — 当前是无状态屏、无 `lang-card`/`lang-card-start` key、点击直接弹 sheet/snackbar。

- [ ] **Step 3: 整文件重写 `language_map_screen.dart`**

用下列完整实现替换整个文件（保留 `_LangPin` + `_langPins` 数据；屏改为有状态 + TickerProvider；自定义 marker + 卡片 + dark 遮罩 + 动画）：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../l10n/generated/app_localizations.dart';

/// 每个语言图钉的坐标与元数据。
class _LangPin {
  const _LangPin({
    required this.code,
    required this.label,
    required this.point,
    required this.enabled,
  });
  final String code;
  final String label;
  final LatLng point;
  final bool enabled;
}

const _langPins = [
  _LangPin(code: 'zh', label: 'Chinese (中文)', point: LatLng(39.9087, 116.3975), enabled: true),
  _LangPin(code: 'en', label: 'English', point: LatLng(38.0, -97.0), enabled: false),
  _LangPin(code: 'es', label: 'Spanish (Español)', point: LatLng(40.4, -3.7), enabled: false),
  _LangPin(code: 'fr', label: 'French (Français)', point: LatLng(46.6, 2.3), enabled: false),
  _LangPin(code: 'ja', label: 'Japanese (日本語)', point: LatLng(36.2, 138.2), enabled: true),
  _LangPin(code: 'ms', label: 'Malay (Bahasa Melayu)', point: LatLng(4.2, 101.9), enabled: false),
];

/// 全屏世界地图（真 OSM 瓦片）：国家 marker 代表可学语言。点击 marker 弹卡片，
/// 可学语言进入两级词书选择，未开放显示"即将开放"。
class LanguageMapScreen extends ConsumerStatefulWidget {
  const LanguageMapScreen({super.key});

  @override
  ConsumerState<LanguageMapScreen> createState() => _LanguageMapScreenState();
}

class _LanguageMapScreenState extends ConsumerState<LanguageMapScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _pulse;
  String? _selectedCode;

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..forward();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  _LangPin? get _selected =>
      _selectedCode == null ? null : _langPins.firstWhere((p) => p.code == _selectedCode);

  Future<void> _startLearning(_LangPin pin) async {
    await ref.read(appControllerProvider.notifier).updateTargetLanguage(pin.code);
    if (!mounted) return;
    await showLanguageWordbookPicker(context, initialLanguage: pin.code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final sel = _selected;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.languageMapTitle),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(20, 80),
              initialZoom: 2.2,
              minZoom: 1,
              maxZoom: 6,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.linguaquest',
              ),
              if (isDark)
                IgnorePointer(
                  child: Container(
                    color: const Color(0xFF0E1626).withValues(alpha: 0.55),
                  ),
                ),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _langPins.length; i++)
                    Marker(
                      point: _langPins[i].point,
                      width: 140,
                      height: 78,
                      alignment: Alignment.topCenter,
                      child: _LangMarker(
                        pin: _langPins[i],
                        index: i,
                        entrance: _entrance,
                        pulse: _pulse,
                        selected: _selectedCode == _langPins[i].code,
                        onTap: () =>
                            setState(() => _selectedCode = _langPins[i].code),
                      ),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          // 顶部引导条
          Positioned(
            top: AppTokens.s12,
            left: AppTokens.s16,
            right: AppTokens.s16,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.s16, vertical: AppTokens.s12),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Text(
                  l10n.languageMapSelectPrompt,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
          ),
          // 底部图例
          Positioned(
            left: AppTokens.s16,
            bottom: AppTokens.s16,
            child: IgnorePointer(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendDot(color: cs.primary, label: 'Available'),
                  const SizedBox(width: AppTokens.s12),
                  _LegendDot(color: cs.onSurfaceVariant, label: 'Coming soon'),
                ],
              ),
            ),
          ),
          // 选中卡片
          if (sel != null)
            Positioned(
              left: AppTokens.s16,
              right: AppTokens.s16,
              bottom: AppTokens.s16,
              child: _LangCard(
                key: const ValueKey('lang-card'),
                pin: sel,
                l10n: l10n,
                onClose: () => setState(() => _selectedCode = null),
                onStart: () => _startLearning(sel),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTokens.s8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: cs.onSurface)),
      ]),
    );
  }
}

class _LangMarker extends StatelessWidget {
  const _LangMarker({
    required this.pin,
    required this.index,
    required this.entrance,
    required this.pulse,
    required this.selected,
    required this.onTap,
  });
  final _LangPin pin;
  final int index;
  final Animation<double> entrance;
  final Animation<double> pulse;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = (index * 0.12).clamp(0.0, 0.6);
    final anim = CurvedAnimation(
      parent: entrance,
      curve: Interval(start, (start + 0.4).clamp(0.0, 1.0),
          curve: Curves.easeOutBack),
    );
    return GestureDetector(
      key: ValueKey('lang-pin-${pin.code}'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: Listenable.merge([entrance, pulse]),
        builder: (context, _) {
          final t = anim.value.clamp(0.0, 1.0);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * -10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusPill),
                      border: Border.all(color: cs.outlineVariant),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withValues(alpha: 0.18),
                            blurRadius: 6,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      pin.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: pin.enabled ? cs.onSurface : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  _Badge(pin: pin, selected: selected, pulse: pulse.value),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.pin, required this.selected, required this.pulse});
  final _LangPin pin;
  final bool selected;
  final double pulse;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final glow = pin.enabled || selected;
    final ring = (selected ? 44.0 : 36.0) *
        (1.0 + (pin.enabled ? pulse * 0.22 : 0.0));
    final dot = selected ? 30.0 : 26.0;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (glow)
            Container(
              width: ring,
              height: ring,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cs.primary.withValues(alpha: selected ? 0.30 : 0.16),
              ),
            ),
          Container(
            width: dot,
            height: dot,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: pin.enabled
                  ? LinearGradient(
                      colors: [cs.primary, AppTokens.sky],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: pin.enabled ? null : cs.surfaceContainerHighest,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: pin.enabled
                ? null
                : Icon(Icons.lock, size: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  const _LangCard({
    super.key,
    required this.pin,
    required this.l10n,
    required this.onClose,
    required this.onStart,
  });
  final _LangPin pin;
  final AppLocalizations l10n;
  final VoidCallback onClose;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surface,
      elevation: 8,
      borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    pin.label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                            fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                ),
              ],
            ),
            const SizedBox(height: AppTokens.s8),
            if (pin.enabled)
              SizedBox(
                width: double.infinity,
                child: AppPrimaryButton(
                  key: const ValueKey('lang-card-start'),
                  label: l10n.languageMapConfirm(pin.label),
                  onPressed: onStart,
                ),
              )
            else
              AppPill(
                key: const ValueKey('lang-card-soon'),
                label: l10n.languageMapComingSoon(pin.label),
                variant: PillVariant.neutral,
              ),
          ],
        ),
      ),
    );
  }
}
```

> 落地校验：`AppPrimaryButton(label:, onPressed:)`、`AppPill(label:, variant:)`、`AppTokens.radiusCard`/`radiusPill`/`s8`/`s12`/`s16`、`AppTokens.sky`、`PillVariant.neutral`、`languageMapConfirm(String)`/`languageMapComingSoon(String)`/`languageMapSelectPrompt` 均已存在；若某常量名不符，按各自源文件实际名调整（`app_tokens.dart` / `app_button.dart` / `app_pill.dart` / `app_en.arb`）。

- [ ] **Step 4: 跑测试 + analyze**

Run: `flutter test test/features/map/language_map_screen_test.dart`
Expected: PASS（若 marker 点击因视口不可达，按 Step 1 备注设大 `tester.view.physicalSize` 后重试）
Run: `flutter analyze lib/features/map/language_map_screen.dart`
Expected: No issues.

- [ ] **Step 5: 全量回归**

Run: `flutter test`
Expected: 全绿（既有 language_map 相关测试若断言旧的"点 marker 直接弹 sheet/snackbar"，按新卡片行为更新）。

- [ ] **Step 6: 提交**

```bash
git add linguaquest/lib/features/map/language_map_screen.dart linguaquest/test/features/map/language_map_screen_test.dart
git commit -m "feat(map): 语言地图游戏化（OSM 底图 + 自定义 marker/动画/点击卡片/dark 遮罩）"
```

---

## 最终验证（全部 task 后）

- [ ] 从 `linguaquest/`：`flutter analyze` 干净；`flutter test` 全绿。
- [ ] 出 release 包：`flutter build apk --release --dart-define=API_BASE_URL=https://api.vonlan233.top`。
- [ ] 装到 AVD 实测（登录后）：① 语言选择器右侧药丸对齐；② 切换词书 Current 即时跟随、重启后保持；③ 发帖页 Tag chips / 社区筛选 chips 在 light 下文字清晰可见；④ 语言地图美观、light/dark 协调、marker 带标签+动画、点击弹卡片、可学进词书选择、底图仍是真 OSM。

## 自检要点
- 问题 1 → Task 1；问题 2 → Task 2（UX + bootstrap 两处）；问题 3 → Task 3（含更新既有 chip 测试）；问题 4 → Task 4（地图重写，底图保持 OSM）。
- 无新依赖；无服务器改动；无需部署。
