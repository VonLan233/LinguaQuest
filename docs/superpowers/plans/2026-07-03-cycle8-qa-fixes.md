# Cycle 8 外部 QA 修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复外部 QA 报告的 9 项既有问题（抽奖文案/按钮、AI 文案/截断、搜索拼音、统计截断、地图标签、单复数、按钮换行）。

**Architecture:** 全部客户端小改，按文件聚合成独立任务；l10n 改动跑 gen-l10n。无服务端、无部署。

**Tech Stack:** Flutter 3.41.6 + Riverpod + go_router；ARB l10n（en/ms/zh）。

## Global Constraints

- 回复中文；commit **不带 Co-Authored-By**；每任务只 `git add` 本任务列出的路径，**禁 `git add -A/./-u`**（仓库有无关 untracked）。
- flutter 命令在 `linguaquest/`。改 `.arb` 后必须跑 `flutter gen-l10n` 并提交 `lib/l10n/generated/` 生成文件；三个 arb（en/ms/zh）签名保持一致。
- 每任务收尾跑 `flutter test`（全量）+ `flutter analyze`，贴真实输出；旧断言据实修。
- 不改词义/词书数据；不动 Cycle 7 修复。答案判定不涉及。

---

## Task 1: 抽奖修复（cost/remaining 写反 + 按钮固定底部 + 库存单复数）

**Files:**
- Modify: `linguaquest/lib/features/discover/lucky_draw_screen.dart`（:177 参数顺序；:22-36 与 :54-143 结构）
- Modify: `linguaquest/lib/l10n/app_en.arb:920`（库存 plural）
- Regenerate: `linguaquest/lib/l10n/generated/`（gen-l10n）
- Test: `linguaquest/test/lucky_draw_deducted_test.dart`（新建）

**背景（root cause）：** 生成方法签名按占位符字母序 = `luckyDrawDeducted(Object balance, Object cost)`；调用处 `:177` 传 `(result.cost, result.balanceAfter)` → 数值进错槽。库存 `luckyDrawInventoryCount` arb 无 plural → "1 items"。"Draw now" 按钮在 ListView 内奖池列表之后 → 需滚到底。

- [ ] **Step 1: 写失败测试（锁死 deducted 参数顺序）**

新建 `linguaquest/test/lucky_draw_deducted_test.dart`：
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/l10n/generated/app_localizations_en.dart';

void main() {
  test('luckyDrawDeducted 按 (balance, cost) 顺序渲染：消耗30余13', () {
    final l10n = AppLocalizationsEn();
    // 生成签名为 luckyDrawDeducted(balance, cost)。余额13、消耗30。
    expect(
      l10n.luckyDrawDeducted(13, 30),
      'Deducted 30 XP, 13 XP remaining.',
    );
  });
}
```

- [ ] **Step 2: 跑测试（此时应通过——它锁的是生成签名语义，作为回归基线）**

Run: `cd linguaquest && flutter test test/lucky_draw_deducted_test.dart`
Expected: PASS（若 FAIL，说明生成签名参数序与预期不符，据 `app_localizations_en.dart` 里 `luckyDrawDeducted` 真实签名调整测试参数）。

- [ ] **Step 3: 修调用处参数顺序**

`lucky_draw_screen.dart:177` 把：
```dart
            Text(l10n.luckyDrawDeducted(result.cost, result.balanceAfter)),
```
改为：
```dart
            Text(l10n.luckyDrawDeducted(result.balanceAfter, result.cost)),
```

- [ ] **Step 4: 库存文案改 plural**

`app_en.arb:920` 把：
```json
  "luckyDrawInventoryCount": "{count} items in stock",
```
改为：
```json
  "luckyDrawInventoryCount": "{count, plural, =1{1 item in stock} other{{count} items in stock}}",
```
（ms/zh 已含 `{count}` 且无单复数问题，不改。）

- [ ] **Step 5: "Draw now" 按钮固定到底部——重构 LuckyDrawScreen + _LotteryPanel**

`lucky_draw_screen.dart` 的 `LuckyDrawScreen.build` body（:29-34）改为：
```dart
      body: const SafeArea(child: _LotteryPanel()),
```

`_LotteryPanel.build`（:54-144 的 `return Column(...)`）整体替换为：可滚动内容用 `Expanded(ListView(...))`，主按钮区放固定底部。把现有的**成本 AppCard 子树（原 :57-108）**和**概率 AppCard（原 :110）**原样作为 ListView children；把现有的**抽奖按钮 Stack（原 :112-127）+ 不足提示（原 :128-136）+ View my assets（原 :137-141）**原样移入底部 footer：
```dart
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTokens.s20),
            children: [
              // ↓ 原 :57-108 的成本信息 AppCard 子树，原样粘贴
              AppCard(
                padding: const EdgeInsets.all(AppTokens.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ImageCueBadge(cue: '🎁', size: 52),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.luckyDrawCostLine(lotteryDrawCost),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                l10n.luckyDrawBalanceHint(user?.xp ?? 0),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Wrap(
                      spacing: AppTokens.s8,
                      runSpacing: AppTokens.s8,
                      children: [
                        AppPill(
                          label: l10n.luckyDrawInventoryCount(inventoryCount),
                          variant: PillVariant.primary,
                          icon: AppIcons.inventory2,
                        ),
                        AppPill(
                          label: l10n.luckyDrawNoBoost,
                          variant: PillVariant.neutral,
                          icon: AppIcons.balance,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              AppCard(child: _ProbabilityList(prizes: state.lotteryPrizes)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AppPrimaryButton(
                    onPressed: canDraw ? () => _draw(context, ref) : null,
                    icon: state.isLoading ? null : AppIcons.casino,
                    label: canDraw
                        ? l10n.luckyDrawNow
                        : l10n.luckyDrawInsufficient,
                  ),
                  if (state.isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if ((user?.xp ?? 0) < lotteryDrawCost) ...[
                const SizedBox(height: AppTokens.s8),
                Text(
                  l10n.luckyDrawShortfall(lotteryDrawCost - (user?.xp ?? 0)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.s12),
              AppSecondaryButton(
                label: l10n.luckyDrawViewMyAssets,
                onPressed: () => context.go('/discover/assets'),
              ),
            ],
          ),
        ),
      ],
    );
```
（`_LotteryPanel` 顶部的 `l10n/theme/state/user/canDraw/inventoryCount` 局部变量 :44-53 保持不动。`_draw`、`_ProbabilityList` 等不动。）

- [ ] **Step 6: gen-l10n + 全量测试 + analyze**

Run: `cd linguaquest && flutter gen-l10n && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。库存 count=1 显示 "1 item in stock"。

- [ ] **Step 7: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/discover/lucky_draw_screen.dart linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/generated/ linguaquest/test/lucky_draw_deducted_test.dart
git commit -m "fix(lucky-draw): 修正扣除/余额文案顺序 + Draw now 固定底部 + 库存单复数"
```

---

## Task 2: AI Learning 显示（Q&A 占位符 + 工具名截断）

**Files:**
- Modify: `linguaquest/lib/features/ai_learning/ai_chat_screen.dart:119`
- Modify: `linguaquest/lib/l10n/app_en.arb`、`app_ms.arb`、`app_zh.arb`（新增 `aiQuestionHint`）
- Modify: `linguaquest/lib/core/widgets/compact_entry_card.dart:62-70`（maxLines）
- Regenerate: `linguaquest/lib/l10n/generated/`

**背景：** `ai_chat_screen.dart:119` 占位符硬编码 `'Type your question about English...'`（应 Chinese）；`compact_entry_card.dart` 标题 `maxLines:1` 截断长工具名。

- [ ] **Step 1: 三个 arb 新增 `aiQuestionHint`（放在 `aiEmptyChat` 之后）**

`app_en.arb`（`aiEmptyChat` 行 1043 之后）加：
```json
  "aiQuestionHint": "Type your question about Chinese...",
```
`app_ms.arb`（`aiEmptyChat` 行 957 之后）加：
```json
  "aiQuestionHint": "Taip soalan anda tentang bahasa Cina...",
```
`app_zh.arb`（`aiEmptyChat` 行 957 之后）加：
```json
  "aiQuestionHint": "输入你关于中文的问题……",
```
（注意 JSON 逗号：若插在某键后、后面还有键，行尾加逗号。）

- [ ] **Step 2: gen-l10n**

Run: `cd linguaquest && flutter gen-l10n`
Expected: 无错误；`l10n.aiQuestionHint` 可用。

- [ ] **Step 3: ai_chat_screen 用 l10n**

`ai_chat_screen.dart:119` 所在的 `InputDecoration`：把 `hintText: 'Type your question about English...'` 改为 `hintText: l10n.aiQuestionHint`，并把该 `InputDecoration` 前的 `const` 去掉（改为非 const，因 hintText 运行时取值）。确认该 build 方法内已有 `l10n`（`AppLocalizations.of(context)`）；若无则在方法顶部加 `final l10n = AppLocalizations.of(context);`。

- [ ] **Step 4: CompactEntryCard 标题放宽到 2 行**

`compact_entry_card.dart:62-70` 把 `maxLines: 1,` 改为 `maxLines: 2,`（`overflow: TextOverflow.ellipsis` 保留）。

- [ ] **Step 5: 全量测试 + analyze**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。

- [ ] **Step 6: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/ai_learning/ai_chat_screen.dart linguaquest/lib/core/widgets/compact_entry_card.dart linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/app_ms.arb linguaquest/lib/l10n/app_zh.arb linguaquest/lib/l10n/generated/
git commit -m "fix(ai): Q&A 占位符改中文 l10n + 工具名卡片放宽两行"
```

---

## Task 3: 搜索无声调拼音优先命中

**Files:**
- Modify: `linguaquest/lib/data/dictionary_search.dart`（import + `_matchPinyin` + `_targetWordMatch` + `_matchRank`）
- Modify: `linguaquest/test/dictionary_search_test.dart`（`_word` 加可选参数 + 新测试）

**背景：** `_targetWordMatch`（:157-179）无拼音匹配；"ai" 命中英文释义 train/car（上车/下车）。已有 `core/utils/pinyin.dart` 的 `normalizePinyin`（去声调+去空格，`ài→ai`、`xià chē→xiache`）未被搜索使用。

**Interfaces:**
- Consumes: `normalizePinyin(String) -> String`（`lib/core/utils/pinyin.dart`）。
- Produces: 新 `matchedBy` 标签 `'汉字拼音'`，`_matchRank` 中 rank 1。

- [ ] **Step 1: `_word` 测试 helper 加可选 phonetic / englishDefinitions**

`test/dictionary_search_test.dart:203-221` 的 `_word` 改为：
```dart
Word _word({
  required String id,
  required String text,
  required String meaning,
  String phonetic = '',
  List<String> englishDefinitions = const [],
}) {
  return Word(
    id: id,
    word: text,
    phonetic: phonetic,
    meaning: meaning,
    definition: '$text definition',
    partOfSpeech: 'noun',
    exampleSentence: '',
    exampleTranslation: '',
    imageCue: 'A',
    difficulty: 'Medium',
    tags: const [],
    englishDefinitions: englishDefinitions,
  );
}
```

- [ ] **Step 2: 写失败测试**

在 `test/dictionary_search_test.dart` 的 `group('dictionary_search', () {` 内（最后一个 test 之后）加：
```dart
    test('P-pinyin: 无声调拼音 ai 优先命中 爱（而非英文释义里 train/car）', () {
      final ai = _word(id: 'ai', text: '爱', meaning: '爱', phonetic: 'ài');
      final shangche = _word(
        id: 'shangche',
        text: '上车',
        meaning: '上车',
        englishDefinitions: const ['to get on or into (a bus, train, car etc)'],
      );
      final book = _wordBook(id: 'hsk1', words: [shangche, ai]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'hsk1',
        scope: DictionarySearchScope.allWordBooks,
        query: 'ai',
      );

      expect(results.first.word.id, 'ai');
      expect(results.first.matchedBy, '汉字拼音');
    });
```

- [ ] **Step 3: 跑测试确认失败**

Run: `cd linguaquest && flutter test test/dictionary_search_test.dart --plain-name "P-pinyin"`
Expected: FAIL（当前无拼音匹配，`results.first` 是 上车 或断言 matchedBy 不符）。

- [ ] **Step 4: dictionary_search 加拼音匹配**

`dictionary_search.dart` 顶部 import（:1-2 之后）加：
```dart
import '../core/utils/pinyin.dart';
```
`_targetWordMatch`（:162）在第一行 `_matchText('英文单词/词组', word.word, query) ??` 之后、`// Japanese phonetic` 之前插入一行：
```dart
      _matchPinyin('汉字拼音', word.phonetic, query) ??
```
在 `_matchText`（:238-243）函数之后新增：
```dart
_SearchMatch? _matchPinyin(String label, String value, String query) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  // 去声调后子串匹配：'ài' -> 'ai'，'xià chē' -> 'xiache'。
  if (!normalizePinyin(trimmed).contains(query)) return null;
  return _SearchMatch(label: label, preview: trimmed);
}
```
`_matchRank`（:248 `if (word.startsWith(query)) return 1;` 之后）加：
```dart
  if (result.matchedBy == '汉字拼音') return 1;
```

- [ ] **Step 5: 跑测试确认通过**

Run: `cd linguaquest && flutter test test/dictionary_search_test.dart`
Expected: PASS（新用例 + 原有用例全绿；注意 "zh word NOT found by kana query" 等旧用例不回归——拼音匹配对空 phonetic 返回 null）。

- [ ] **Step 6: 全量测试 + analyze**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。

- [ ] **Step 7: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/data/dictionary_search.dart linguaquest/test/dictionary_search_test.dart
git commit -m "fix(search): 无声调拼音匹配并置顶（爱 命中 ai），复用 normalizePinyin"
```

---

## Task 4: 首页统计标签截断（StatTile 纵向布局）

**Files:**
- Modify: `linguaquest/lib/core/widgets/stat_tile.dart:22-69`
- Test: `linguaquest/test/features/stat_tile_test.dart`（新建）

**背景：** `StatTile` 是横向 `Row(icon + Column(value,label))`，三列均分时 icon(36)+gap 挤占，label `maxLines:1` 截断。用于 home/profile/review 三处同款"3 列统计"，改纵向对三处一致。

- [ ] **Step 1: 写 widget 测试（长标签完整可见，不被 ellipsis 截断）**

新建 `linguaquest/test/features/stat_tile_test.dart`：
```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/stat_tile.dart';

void main() {
  testWidgets('StatTile 在窄列中完整显示长标签', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Row(
          children: [
            Expanded(
              child: StatTile(value: '12', label: 'Mastered', icon: Icons.star),
            ),
            Expanded(
              child: StatTile(value: '3', label: 'Review', icon: Icons.replay),
            ),
            Expanded(
              child: StatTile(value: '0', label: 'Learned', icon: Icons.school),
            ),
          ],
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Mastered'), findsOneWidget);
    expect(find.text('Review'), findsOneWidget);
    expect(find.text('Learned'), findsOneWidget);
    // 纵向布局下无 RenderFlex overflow（pumpAndSettle 不抛异常即通过）。
  });
}
```

- [ ] **Step 2: 跑测试（记录基线）**

Run: `cd linguaquest && flutter test test/features/stat_tile_test.dart`
Expected: 当前横向布局在极窄 Expanded 下 label 被 ellipsize，`find.text('Mastered')` 仍能找到（Text 存在），此测试主要验证改后无 overflow。若当前通过，作为回归基线；改布局后仍须通过。

- [ ] **Step 3: StatTile 改纵向**

`stat_tile.dart:22-69` 的 `build` 的 `return Row(...)` 整体替换为：
```dart
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accentColor = accent ?? colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(height: AppTokens.s8),
        ],
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppTokens.s2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 4: 跑测试 + 全量 + analyze**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。若 home/profile/review 有 widget 测试断言横向布局细节，据纵向更新。

- [ ] **Step 5: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/core/widgets/stat_tile.dart linguaquest/test/features/stat_tile_test.dart
git commit -m "fix(ui): StatTile 改纵向布局，统计标签不再截断"
```

---

## Task 5: 个人页 streak 单复数

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb:237`、`app_ms.arb:237`、`app_zh.arb:237`（`profileStreakDays` 改带参 plural）
- Modify: `linguaquest/lib/features/profile/profile_screen.dart:256`
- Regenerate: `linguaquest/lib/l10n/generated/`

**背景：** `profileStreakDays` 现为无参 `"days streak"`，profile 用 `'$streak ${l10n.profileStreakDays}'` → "1 days streak"。改为带 `{count}` 的 plural（签名从 getter 变 method，三 arb 必须同步）。

- [ ] **Step 1: 三个 arb 改 `profileStreakDays` 为带参**

`app_en.arb:237`：
```json
  "profileStreakDays": "{count, plural, =1{1 day streak} other{{count} days streak}}",
```
`app_ms.arb:237`：
```json
  "profileStreakDays": "{count} hari berturut-turut",
```
`app_zh.arb:237`：
```json
  "profileStreakDays": "连续 {count} 天",
```

- [ ] **Step 2: gen-l10n**

Run: `cd linguaquest && flutter gen-l10n`
Expected: `profileStreakDays` 变为 `String profileStreakDays(num count)`（或 int）。

- [ ] **Step 3: 改 profile 调用处**

`profile_screen.dart:256` 把：
```dart
          label: '$streak ${l10n.profileStreakDays}',
```
改为：
```dart
          label: l10n.profileStreakDays(streak),
```
（`streak` 为该处已有的 int 变量；若类型不符据实转换。）

- [ ] **Step 4: 全量测试 + analyze**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。streak=1 显示 "1 day streak"。若有旧断言 "days streak" 拼接，据实更新。

- [ ] **Step 5: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/app_ms.arb linguaquest/lib/l10n/app_zh.arb linguaquest/lib/l10n/generated/ linguaquest/lib/features/profile/profile_screen.dart
git commit -m "fix(i18n): profile streak 单复数（1 day streak）"
```

---

## Task 6: 语言地图 Japanese 标签出界

**Files:**
- Modify: `linguaquest/lib/features/map/language_map_screen.dart:285-292`（`_LangMarker` 标签 Text）

**背景：** marker 固定 `width:140`，标签 `Text('Japanese (日本語)')` 单行约 146px 溢出且屏幕右缘裁切。让标签在 marker 宽度内换 2 行。

- [ ] **Step 1: 标签 Text 约束宽度 + 换行**

`language_map_screen.dart:285-292` 的 `child: Text(pin.label, style: ...)` 替换为：
```dart
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 124),
                      child: Text(
                        pin.label,
                        maxLines: 2,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pin.enabled
                              ? cs.onSurface
                              : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
```
（124 = marker 宽 140 − 左右 padding 8×2；换行后每行 < 140，横向不溢出。）

- [ ] **Step 2: analyze + 全量测试**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。

- [ ] **Step 3: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/map/language_map_screen.dart
git commit -m "fix(map): 语言标签约束宽度换行，Japanese 不再出界"
```

---

## Task 7: 词条详情底部按钮换行

**Files:**
- Modify: `linguaquest/lib/features/wordbook/target_word_detail_screen.dart:51-105`（底部 Row → 纵向堆叠）

**背景：** 底部 `bottomNavigationBar` 里 Favorite / Add 两按钮并排（各半宽），"Add to custom words" 换行成 3 行。改纵向堆叠（各占整行）。

- [ ] **Step 1: 底部按钮 Row → Column（stretch）**

`target_word_detail_screen.dart:54` 的 `child: Row(` 那层改为纵向堆叠。把 `:54-104` 的 `Row(children: [ Expanded(child: AppSecondaryButton...), const SizedBox(width:12), Expanded(child: FilledButton.icon...) ])` 替换为：
```dart
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSecondaryButton(
                onPressed: () => _toggleFavorite(
                  context,
                  ref,
                  word,
                  wordBookId,
                  progress?.isFavorite ?? false,
                  l10n,
                ),
                label: progress?.isFavorite == true
                    ? l10n.wordbookFavorited
                    : l10n.wordbookFavorite,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppTokens.azure,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                  ),
                ),
                onPressed: () => _toggleNewWordbook(
                  context,
                  ref,
                  word,
                  wordBookId,
                  isInNewWordbook,
                  l10n,
                ),
                icon: Icon(
                  isInNewWordbook ? AppIcons.checkCircle : AppIcons.addCircle,
                ),
                label: Text(
                  isInNewWordbook
                      ? l10n.wordbookRemoveCustomWord
                      : l10n.wordbookAddToCustomWords,
                ),
              ),
            ],
          ),
```
（去掉两个 `Expanded`（Column 里非法）；`minimumSize: Size.fromHeight(48)` 让 FilledButton 全宽等高；`AppSecondaryButton` 在 stretch Column 下自动全宽。）

- [ ] **Step 2: analyze + 全量测试**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。"Add to custom words" 单行显示。

- [ ] **Step 3: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/wordbook/target_word_detail_screen.dart
git commit -m "fix(ui): 词条详情底部按钮纵向堆叠，Add to custom words 不再换行"
```

---

## Task 8: 全量验证 + 构建 APK

**Files:** 无代码改动（除非验证发现问题）。

- [ ] **Step 1: 全量测试 + analyze**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: 全 PASS / `No issues found!`。贴输出。

- [ ] **Step 2: 构建 release APK**

Run: `cd linguaquest && flutter build apk --release`
Expected: `✓ Built build/app/outputs/flutter-apk/app-release.apk`。贴产物路径与大小。

- [ ] **Step 3: 无新增改动不提交**（构建非代码变更）。若验证中修了 bug，按文件单独 commit。

---

## Self-Review 记录

- **Spec 覆盖：** A→T1；B→T2；C→T3；D→T4；E→T2；F→T6；G→T1；H(streak)→T5、H(stock)→T1；I→T7；构建→T8。9 项全覆盖。
- **类型一致：** `luckyDrawDeducted(balance, cost)` 顺序 T1 测试与调用一致；`_matchPinyin`/`'汉字拼音'`/rank1 在 T3 内一致；`aiQuestionHint` T2 三 arb + 调用一致；`profileStreakDays(count)` T5 三 arb + 调用一致。
- **据实核对项（非占位，给了回退）：** `AppLocalizationsEn` 类名与 `luckyDrawDeducted` 生成参数序、`ai_chat_screen` build 内 `l10n` 是否已存在、`profile_screen` `streak` 变量类型、各 widget 旧测试断言。
- **无服务端 / 无部署。** l10n 改动在 T1(stock)/T2(hint)/T5(streak)，各自 gen-l10n。
