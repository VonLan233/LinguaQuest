# Cozy Quest 设计系统地基 Implementation Plan（Plan 1 / 5）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立 Cozy Quest 设计系统的地基——刷新设计 token、调整主题、退役旧扁平风格守卫、并产出一套核心共享组件（卡片、按钮、徽章、进度条、吉祥物空状态），供后续所有页面重做复用。

**Architecture:** 不动数据/状态/路由/i18n/后端。仅改 `core/theme` 与 `core/widgets`。token 改值即可让大量经由 `AppTheme` 别名与 `ColorScheme` 取色的旧屏幕自动继承新底色，降低迁移风险。每个组件 TDD：先写 widget 测试 → 跑红 → 实现 → 跑绿 → 提交。

**Tech Stack:** Flutter / Dart 3、Material 3、flutter_test。

**对应 spec:** `docs/superpowers/specs/2026-06-16-ui-redesign-cozy-quest-design.md`（§3 颜色、§5 形状/阴影、§6 组件、§7 吉祥物、§9 保留/弃用）。

**前置:** 在分支 `feat/ui-friendly-quest-reskin` 上工作。所有命令在 `linguaquest/` 目录下执行。

---

## File Structure

- `lib/core/theme/app_tokens.dart` — 修改：刷新亮色调色板为 Cozy Quest，新增中性/语义浅底 token、调整圆角、改 `cardShadow` 为单层柔影、新增 `progressGradient`。
- `lib/core/theme/app_theme.dart` — 修改：把中性容器色重指向暖色 token（背景已经由别名自动继承）。
- `test/core/theme/app_tokens_test.dart` — 修改：退役旧守卫断言，新增锁定关键 token 值的烟雾测试。
- `test/ui_style_guard_test.dart` — 删除：旧扁平守卫禁止阴影/渐变/卡片，与新风格冲突。
- `lib/core/widgets/app_card.dart` + `test/core/widgets/app_card_test.dart` — 新建：标准白卡（单层柔影）。
- `lib/core/widgets/app_button.dart` + `test/core/widgets/app_button_test.dart` — 新建：`AppPrimaryButton`（蓝实底 + 轻 3D 底边 + 按下下沉）与 `AppSecondaryButton`（描边）。
- `lib/core/widgets/app_pill.dart` + `test/core/widgets/app_pill_test.dart` — 新建：语义徽章胶囊（xp/success/streak/primary 变体）。
- `lib/core/widgets/app_progress_bar.dart` + `test/core/widgets/app_progress_bar_test.dart` — 新建：橙→绿渐变进度条。
- `lib/core/widgets/mascot_image.dart` + `test/core/widgets/mascot_image_test.dart` — 新建：蓝猫形象图片组件（用 `icon.png`）。
- `lib/core/widgets/mascot_empty_state.dart` + `test/core/widgets/mascot_empty_state_test.dart` — 新建：吉祥物贯穿的空状态。
- `pubspec.yaml` — 修改：注册 `lib/assets/image/` 目录，使 `icon.png` 可用。

---

## Task 1: 刷新设计 Token

**Files:**
- Modify: `lib/core/theme/app_tokens.dart`

- [ ] **Step 1: 写失败测试**（先改测试，锁定新 token 值）

替换 `test/core/theme/app_tokens_test.dart` 全部内容：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';

Future<T> _readWithBrightness<T>(
  WidgetTester tester,
  Brightness brightness,
  T Function(BuildContext) read,
) async {
  late T value;
  await tester.pumpWidget(
    Theme(
      data: ThemeData(brightness: brightness),
      child: Builder(
        builder: (c) {
          value = read(c);
          return const SizedBox();
        },
      ),
    ),
  );
  return value;
}

void main() {
  test('Cozy Quest neutral tokens are locked to warm-porcelain palette', () {
    expect(AppTokens.bgLight, const Color(0xFFFAF8F5)); // bgCanvas
    expect(AppTokens.surfaceSunken, const Color(0xFFF2EFEA));
    expect(AppTokens.hairline, const Color(0xFFECE7E0));
    expect(AppTokens.textPrimaryLight, const Color(0xFF233A66));
    expect(AppTokens.textSecondaryLight, const Color(0xFF6B6B73));
    expect(AppTokens.textHintLight, const Color(0xFFA59B8C));
  });

  test('semantic soft tokens exist', () {
    expect(AppTokens.xpSoft, const Color(0xFFFFF1D6));
    expect(AppTokens.successSoft, const Color(0xFFF2FAEC));
    expect(AppTokens.streakSoft, const Color(0xFFFFE2DC));
    expect(AppTokens.primarySoft, const Color(0xFFEAF2FC));
  });

  test('radii match spec', () {
    expect(AppTokens.radiusCard, 22);
    expect(AppTokens.radiusButton, 18);
    expect(AppTokens.radiusTile, 18);
    expect(AppTokens.radiusChip, 12);
  });

  test('progressGradient runs mango -> success', () {
    expect(AppTokens.progressGradient.colors.first, AppTokens.mango);
    expect(AppTokens.progressGradient.colors.last, AppTokens.success);
  });

  testWidgets('cardShadow present in light, empty in dark', (tester) async {
    final light = await _readWithBrightness(
      tester, Brightness.light, AppTokens.cardShadow);
    final dark = await _readWithBrightness(
      tester, Brightness.dark, AppTokens.cardShadow);
    expect(light, isNotEmpty);
    expect(dark, isEmpty);
  });

  testWidgets('semantic accents brighten on dark', (tester) async {
    final light = await _readWithBrightness(
      tester, Brightness.light, AppTokens.successColor);
    final dark = await _readWithBrightness(
      tester, Brightness.dark, AppTokens.successColor);
    expect(light, isNot(equals(dark)));
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/theme/app_tokens_test.dart`
Expected: FAIL —— `surfaceSunken`/`hairline`/`xpSoft`/`radiusTile`/`progressGradient` 等未定义，编译错误。

- [ ] **Step 3: 实现 token 变更**

在 `lib/core/theme/app_tokens.dart` 中做如下编辑。

(a) 圆角块替换为：

```dart
  // Radii.
  static const double radiusSmall = 12;
  static const double radiusChip = 12;
  static const double radiusButton = 18;
  static const double radiusTile = 18;
  static const double radiusCard = 22;
  static const double radiusSheet = 26;
  static const double radiusPill = 999;
```

(b) 亮色调色板块替换为（保留品牌色，刷新中性 + 新增语义浅底）：

```dart
  // Brand palette (light) — Cozy Quest.
  static const Color brandNavy = Color(0xFF233A66);
  static const Color azure = Color(0xFF2C7BE0);
  static const Color azurePressed = Color(0xFF1F5FAE);
  static const Color sky = Color(0xFF8FD0F2);
  static const Color success = Color(0xFF5FB23C);
  static const Color mango = Color(0xFFFFB22E);
  static const Color coral = Color(0xFFFF6B5A);
  static const Color amber = Color(0xFFF5A623);

  // Neutrals — warm porcelain.
  static const Color bgLight = Color(0xFFFAF8F5); // bgCanvas (定稿)
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceSunken = Color(0xFFF2EFEA);
  static const Color hairline = Color(0xFFECE7E0);
  static const Color chipLight = Color(0xFFEAF2FC); // = primarySoft
  static const Color textPrimaryLight = Color(0xFF233A66);
  static const Color textSecondaryLight = Color(0xFF6B6B73);
  static const Color textHintLight = Color(0xFFA59B8C);
  static const Color outlineLight = Color(0xFFECE7E0);

  // Semantic soft fills (badge / chip backgrounds).
  static const Color xpSoft = Color(0xFFFFF1D6);
  static const Color xpSoftText = Color(0xFFE08A00);
  static const Color successSoft = Color(0xFFF2FAEC);
  static const Color successSoftText = Color(0xFF3F7A22);
  static const Color streakSoft = Color(0xFFFFE2DC);
  static const Color streakSoftText = Color(0xFFE8503B);
  static const Color primarySoft = Color(0xFFEAF2FC);
  static const Color primarySoftText = Color(0xFF2C7BE0);
```

(c) 在 dark 调色板块**之后**、`_isDark` 之前，新增进度渐变常量：

```dart
  /// Standard progress fill: "from start (mango) to done (success)".
  static const LinearGradient progressGradient = LinearGradient(
    colors: [mango, success],
  );
```

(d) 把 `cardShadow` 的 light 分支替换为单层柔影：

```dart
  /// Soft single-layer elevation shadow used by cards.
  static List<BoxShadow> cardShadow(BuildContext c) => _isDark(c)
      ? const []
      : const [
          BoxShadow(
            color: Color(0x0F28283C), // ~6% cool-ink
            blurRadius: 22,
            offset: Offset(0, 6),
          ),
        ];
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/core/theme/app_tokens_test.dart`
Expected: PASS（6 个测试全绿）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/theme/app_tokens.dart test/core/theme/app_tokens_test.dart
git commit -m "feat(theme): refresh design tokens to Cozy Quest palette"
```

---

## Task 2: 主题中性色重指向暖底

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

> 背景已由 `paper = AppTokens.bgLight` 自动变成暖瓷白。本任务只把残留的冷蓝中性容器改指暖色 token，避免冷暖打架。主行动/选中态仍用蓝（primarySoft）。

- [ ] **Step 1: 写失败测试**

新建 `test/core/theme/app_theme_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_theme.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';

void main() {
  test('light theme scaffold uses warm porcelain background', () {
    final theme = AppTheme.light();
    expect(theme.scaffoldBackgroundColor, AppTokens.bgLight);
  });

  test('light theme low surface container is warm, not cool blue', () {
    final theme = AppTheme.light();
    expect(theme.colorScheme.surfaceContainerLow, AppTokens.bgLight);
    expect(theme.colorScheme.surfaceContainerLowest, AppTokens.surfaceLight);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS 或 FAIL 取决于现值——若 `surfaceContainerLow` 现为旧 `AppTokens.bgLight`（已在 Task 1 变暖），第一/二条可能已通过；继续 Step 3 做显式修正以确保稳定。

> 注：Task 1 已把 `bgLight` 变暖，故 `scaffoldBackgroundColor`/`surfaceContainerLow` 已暖。本任务核心是显式化并清掉 `surfaceContainer: AppTokens.chipLight` 之外的冷蓝硬编码。

- [ ] **Step 3: 实现**

在 `AppTheme.light()` 的 `.copyWith(...)` 中，把这两行替换：

原：
```dart
          surfaceContainerHigh: const Color(0xFFDDE8F4),
          surfaceContainerHighest: const Color(0xFFCFDEEF),
```
改为（中性暖灰，承载次级填充/分隔）：
```dart
          surfaceContainerHigh: AppTokens.surfaceSunken,
          surfaceContainerHighest: const Color(0xFFE8E2D9),
```

并把 `outline` 行：
```dart
          outline: const Color(0xFFBFD0E3),
```
改为：
```dart
          outline: AppTokens.hairline,
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/core/theme/app_theme_test.dart`
Expected: PASS（2 个测试）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/theme/app_theme.dart test/core/theme/app_theme_test.dart
git commit -m "feat(theme): repoint neutral containers to warm tokens"
```

---

## Task 3: 退役旧扁平风格守卫

**Files:**
- Delete: `test/ui_style_guard_test.dart`

> 旧守卫禁止 `BoxShadow`/`LinearGradient`/`elevation`/`Card`，与 Cozy Quest 刻意使用柔影与渐变冲突。新的 token 守卫已在 Task 1 的 `app_tokens_test.dart` 建立。

- [ ] **Step 1: 删除旧守卫测试**

```bash
git rm test/ui_style_guard_test.dart
```

- [ ] **Step 2: 跑全量测试确认无引用残留**

Run: `flutter test`
Expected: PASS（无文件再引用被删测试；若有编译错误说明别处 import 了它——本仓库无此引用）。

- [ ] **Step 3: 提交**

```bash
git commit -m "chore(test): retire flat-style guard incompatible with Cozy Quest"
```

---

## Task 4: AppCard 标准白卡

**Files:**
- Create: `lib/core/widgets/app_card.dart`
- Test: `test/core/widgets/app_card_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';
import 'package:linguaquest/core/widgets/app_card.dart';

void main() {
  testWidgets('AppCard renders child and applies card radius', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppCard(child: Text('hello')),
        ),
      ),
    );

    expect(find.text('hello'), findsOneWidget);

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppCard),
        matching: find.byType(Container),
      ).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(
      decoration.borderRadius,
      BorderRadius.circular(AppTokens.radiusCard),
    );
    expect(decoration.boxShadow, isNotEmpty);
  });

  testWidgets('AppCard fires onTap when tapped', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppCard(
            onTap: () => tapped = true,
            child: const Text('tap me'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('tap me'));
    expect(tapped, isTrue);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/widgets/app_card_test.dart`
Expected: FAIL —— `app_card.dart` 不存在。

- [ ] **Step 3: 实现**

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Standard white content card: warm single-layer shadow, [radiusCard] corners.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s16),
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTokens.radiusCard);
    final card = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: radius,
        boxShadow: AppTokens.cardShadow(context),
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: card,
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/core/widgets/app_card_test.dart`
Expected: PASS（2 个测试）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/widgets/app_card.dart test/core/widgets/app_card_test.dart
git commit -m "feat(widgets): add AppCard primitive"
```

---

## Task 5: AppPrimaryButton / AppSecondaryButton

**Files:**
- Create: `lib/core/widgets/app_button.dart`
- Test: `test/core/widgets/app_button_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/app_button.dart';

void main() {
  testWidgets('AppPrimaryButton shows label and fires onPressed',
      (tester) async {
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(
            label: '开始学习',
            onPressed: () => pressed = true,
          ),
        ),
      ),
    );
    expect(find.text('开始学习'), findsOneWidget);
    await tester.tap(find.byType(AppPrimaryButton));
    expect(pressed, isTrue);
  });

  testWidgets('AppPrimaryButton with null onPressed is disabled',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPrimaryButton(label: 'x', onPressed: null),
        ),
      ),
    );
    final gesture = tester.widget<GestureDetector>(
      find.descendant(
        of: find.byType(AppPrimaryButton),
        matching: find.byType(GestureDetector),
      ),
    );
    expect(gesture.onTap, isNull);
  });

  testWidgets('AppSecondaryButton renders outlined label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSecondaryButton(label: '稍后', onPressed: () {}),
        ),
      ),
    );
    expect(find.text('稍后'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/widgets/app_button_test.dart`
Expected: FAIL —— `app_button.dart` 不存在。

- [ ] **Step 3: 实现**

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Primary action button: azure fill, white label, soft 3D bottom edge that
/// sinks 2px on press.
class AppPrimaryButton extends StatefulWidget {
  const AppPrimaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton> {
  bool _down = false;

  bool get _enabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTokens.radiusButton);
    final sink = _down ? 2.0 : 0.0;
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: _enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: _enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: _enabled ? () => setState(() => _down = false) : null,
      child: AnimatedContainer(
        duration: AppTokens.fast,
        transform: Matrix4.translationValues(0, sink, 0),
        decoration: BoxDecoration(
          color: _enabled ? AppTokens.azure : AppTokens.hairline,
          borderRadius: radius,
          boxShadow: _enabled
              ? [
                  BoxShadow(
                    color: AppTokens.azurePressed,
                    offset: Offset(0, 4 - sink),
                    blurRadius: 0,
                  ),
                ]
              : const [],
        ),
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s16),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: Colors.white),
              const SizedBox(width: AppTokens.s8),
            ],
            Text(
              widget.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Secondary action: white fill, azure label, soft outline.
class AppSecondaryButton extends StatelessWidget {
  const AppSecondaryButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: AppTokens.azure,
        side: const BorderSide(color: AppTokens.primarySoftText, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/core/widgets/app_button_test.dart`
Expected: PASS（3 个测试）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/widgets/app_button.dart test/core/widgets/app_button_test.dart
git commit -m "feat(widgets): add AppPrimaryButton and AppSecondaryButton"
```

---

## Task 6: AppPill 语义徽章

**Files:**
- Create: `lib/core/widgets/app_pill.dart`
- Test: `test/core/widgets/app_pill_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';
import 'package:linguaquest/core/widgets/app_pill.dart';

void main() {
  testWidgets('AppPill renders label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPill(label: '+126 XP', variant: PillVariant.xp),
        ),
      ),
    );
    expect(find.text('+126 XP'), findsOneWidget);
  });

  testWidgets('AppPill xp variant uses xpSoft background', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppPill(label: 'XP', variant: PillVariant.xp),
        ),
      ),
    );
    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppPill),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, AppTokens.xpSoft);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/widgets/app_pill_test.dart`
Expected: FAIL —— `app_pill.dart` 不存在。

- [ ] **Step 3: 实现**

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

enum PillVariant { xp, success, streak, primary }

/// Small semantic capsule badge (XP / streak / status).
class AppPill extends StatelessWidget {
  const AppPill({
    required this.label,
    this.variant = PillVariant.primary,
    this.icon,
    super.key,
  });

  final String label;
  final PillVariant variant;
  final IconData? icon;

  ({Color bg, Color fg}) get _colors => switch (variant) {
        PillVariant.xp => (bg: AppTokens.xpSoft, fg: AppTokens.xpSoftText),
        PillVariant.success =>
          (bg: AppTokens.successSoft, fg: AppTokens.successSoftText),
        PillVariant.streak =>
          (bg: AppTokens.streakSoft, fg: AppTokens.streakSoftText),
        PillVariant.primary =>
          (bg: AppTokens.primarySoft, fg: AppTokens.primarySoftText),
      };

  @override
  Widget build(BuildContext context) {
    final c = _colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s12,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: c.fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: c.fg,
              fontWeight: FontWeight.w800,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/core/widgets/app_pill_test.dart`
Expected: PASS（2 个测试）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/widgets/app_pill.dart test/core/widgets/app_pill_test.dart
git commit -m "feat(widgets): add AppPill semantic badge"
```

---

## Task 7: AppProgressBar 渐变进度条

**Files:**
- Create: `lib/core/widgets/app_progress_bar.dart`
- Test: `test/core/widgets/app_progress_bar_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/app_progress_bar.dart';

void main() {
  testWidgets('AppProgressBar clamps value into 0..1', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: AppProgressBar(value: 1.5)),
        ),
      ),
    );
    final bar = tester.widget<AppProgressBar>(find.byType(AppProgressBar));
    expect(bar.value, 1.5); // raw value preserved
    expect(find.byType(FractionallySizedBox), findsOneWidget);
    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 1.0); // clamped for layout
  });

  testWidgets('AppProgressBar renders zero progress without overflow',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 200, child: AppProgressBar(value: 0)),
        ),
      ),
    );
    final fill = tester.widget<FractionallySizedBox>(
      find.byType(FractionallySizedBox),
    );
    expect(fill.widthFactor, 0.0);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/widgets/app_progress_bar_test.dart`
Expected: FAIL —— `app_progress_bar.dart` 不存在。

- [ ] **Step 3: 实现**

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Horizontal progress bar with sunken track and mango→success gradient fill.
class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    required this.value,
    this.height = 9,
    super.key,
  });

  /// 0..1; clamped for layout.
  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final factor = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTokens.radiusPill),
      child: Container(
        height: height,
        color: AppTokens.surfaceSunken,
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: factor,
          child: Container(
            decoration: const BoxDecoration(
              gradient: AppTokens.progressGradient,
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/core/widgets/app_progress_bar_test.dart`
Expected: PASS（2 个测试）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/widgets/app_progress_bar.dart test/core/widgets/app_progress_bar_test.dart
git commit -m "feat(widgets): add AppProgressBar gradient bar"
```

---

## Task 8: 注册吉祥物资产 + MascotImage

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/widgets/mascot_image.dart`
- Test: `test/core/widgets/mascot_image_test.dart`

- [ ] **Step 1: 注册资产目录**

在 `pubspec.yaml` 的 `assets:` 列表中，把单文件行
```yaml
    - lib/assets/image/icon_transparent.png
```
替换为目录注册（覆盖 `icon.png` 与未来新增插画）：
```yaml
    - lib/assets/image/
```
（保留其下 `lib/assets/data/*.json` 各行不动。）

- [ ] **Step 2: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/mascot_image.dart';

void main() {
  testWidgets('MascotImage loads the cat asset at requested size',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: MascotImage(size: 64)),
      ),
    );
    final image = tester.widget<Image>(
      find.descendant(
        of: find.byType(MascotImage),
        matching: find.byType(Image),
      ),
    );
    final provider = image.image as AssetImage;
    expect(provider.assetName, 'lib/assets/image/icon.png');
    expect(image.width, 64);
  });
}
```

- [ ] **Step 3: 跑测试确认失败**

Run: `flutter test test/core/widgets/mascot_image_test.dart`
Expected: FAIL —— `mascot_image.dart` 不存在。

- [ ] **Step 4: 实现**

```dart
import 'package:flutter/material.dart';

/// The LinguaQuest blue-cat mascot. A single source so swapping the artwork
/// (or adding expression variants later) happens in one place.
class MascotImage extends StatelessWidget {
  const MascotImage({this.size = 72, super.key});

  final double size;

  static const String _asset = 'lib/assets/image/icon.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
```

- [ ] **Step 5: 跑测试确认通过**

Run: `flutter test test/core/widgets/mascot_image_test.dart`
Expected: PASS（1 个测试）。

- [ ] **Step 6: 提交**

```bash
git add pubspec.yaml lib/core/widgets/mascot_image.dart test/core/widgets/mascot_image_test.dart
git commit -m "feat(widgets): register mascot asset and add MascotImage"
```

---

## Task 9: MascotEmptyState 吉祥物空状态

**Files:**
- Create: `lib/core/widgets/mascot_empty_state.dart`
- Test: `test/core/widgets/mascot_empty_state_test.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/mascot_image.dart';
import 'package:linguaquest/core/widgets/mascot_empty_state.dart';

void main() {
  testWidgets('MascotEmptyState shows mascot, title, message', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MascotEmptyState(
            title: '还没有错题',
            message: '继续学习，错词会自动收进来',
          ),
        ),
      ),
    );
    expect(find.byType(MascotImage), findsOneWidget);
    expect(find.text('还没有错题'), findsOneWidget);
    expect(find.text('继续学习，错词会自动收进来'), findsOneWidget);
  });

  testWidgets('MascotEmptyState renders optional action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MascotEmptyState(
            title: 't',
            message: 'm',
            action: FilledButton(onPressed: () {}, child: const Text('去学习')),
          ),
        ),
      ),
    );
    expect(find.text('去学习'), findsOneWidget);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/core/widgets/mascot_empty_state_test.dart`
Expected: FAIL —— `mascot_empty_state.dart` 不存在。

- [ ] **Step 3: 实现**

```dart
import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import 'mascot_image.dart';

/// Empty-state block fronted by the blue-cat mascot for a consistent,
/// encouraging "companion" personality across the app.
class MascotEmptyState extends StatelessWidget {
  const MascotEmptyState({
    required this.title,
    required this.message,
    this.action,
    super.key,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s24,
          vertical: AppTokens.s20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MascotImage(size: 96),
            const SizedBox(height: AppTokens.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppTokens.s20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: 跑测试确认通过**

Run: `flutter test test/core/widgets/mascot_empty_state_test.dart`
Expected: PASS（2 个测试）。

- [ ] **Step 5: 提交**

```bash
git add lib/core/widgets/mascot_empty_state.dart test/core/widgets/mascot_empty_state_test.dart
git commit -m "feat(widgets): add MascotEmptyState"
```

---

## Task 10: 地基整体验收

**Files:** 无新增（验收任务）。

- [ ] **Step 1: 全量分析**

Run: `flutter analyze`
Expected: `No issues found!`（若有告警，修复后重跑；不得带告警进入下一计划）。

- [ ] **Step 2: 全量测试**

Run: `flutter test`
Expected: All tests passed. 包含本计划新增的 token/theme/AppCard/AppButton/AppPill/AppProgressBar/MascotImage/MascotEmptyState 测试，且既有测试不回归。

> 若旧屏幕的 widget 测试因 token 改色断言具体颜色而失败：定位该测试，确认失败仅因预期颜色变化（非逻辑回归），更新其期望值为新 token；在 commit 信息中说明。

- [ ] **Step 3: 提交验收（如有测试修订）**

```bash
git add -A
git commit -m "test: update color expectations for Cozy Quest tokens"
```

---

## Self-Review（作者自查）

**Spec 覆盖：**
- §3 颜色 → Task 1（中性 + 品牌 + 语义浅底 + 进度渐变）✓
- §5 形状/阴影/动效 → Task 1（圆角、单层柔影）、Task 5（按下下沉 `fast`）✓
- §6 组件：AppCard(T4)、Primary/Secondary 按钮(T5)、AppPill(T6)、AppProgressBar(T7)；StatTile 已存在沿用、ProgressRing 已存在沿用 ✓
- §7 吉祥物 → Task 8 MascotImage + Task 9 MascotEmptyState ✓
- §9 弃用旧扁平守卫 → Task 3 ✓；暖底主题 → Task 2 ✓
- 底部导航：已有 `NavigationBarThemeData` 主题足够承载 5 Tab，**本计划不新建自定义 AppBottomNav**（YAGNI）；如核心流程页阶段证明不足再补，留待 Plan 2。

**占位符扫描：** 无 TBD/TODO；每个代码步骤含完整代码。

**类型一致性：** `PillVariant`(T6) 命名在测试与实现一致；`AppTokens` 新成员（`surfaceSunken/hairline/xpSoft/.../progressGradient/azurePressed/radiusTile/radiusChip`）在 T1 定义、在 T4-T9 引用，名称一致。`MascotImage`(T8) 被 T9 引用，路径 `lib/assets/image/icon.png` 与 pubspec 目录注册一致。

**范围：** 仅地基，独立可测、可交付；不触碰具体业务页面。后续 Plan 2-5 重做页面时复用本组件库。

## 后续计划（本计划完成后再各自撰写）

- **Plan 2 — 核心流程页**：首页、学习路径、词卡/识别题、复习中心、我的（+ 必要时自定义 AppBottomNav 与 AppShell）。
- **Plan 3 — 训练场 & 词书**：训练场、各训练小游戏、限时测试、词书总览/详情、自定义词 CRUD。
- **Plan 4 — 任务中心 & 发现**：任务中心、XP 任务、抽奖、社区、班级、排行、学习分析、AI 导师。
- **Plan 5 — 入门 & 设置 & 杂项**：splash/onboarding/登录注册/目标设置、设置全系、帮助、关于、通知、搜索。
