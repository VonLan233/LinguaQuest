# Cozy Quest 核心 Hub 屏幕重塑 Implementation Plan（Plan 2 / 5）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 4 个核心 hub/列表屏幕（首页、我的、学习路径、复习中心）的**视觉层**迁移到 Plan 1 建立的 Cozy Quest 组件库与暖瓷白 token，验证设计系统在真实业务屏上跑得通；保留全部数据接线、导航与可见文案，使既有集成测试 `test/widget_test.dart` 持续通过。

**Architecture:** 这是**视觉迁移**而非功能重写。每个屏幕：① 保留所有 `ref.watch(appControllerProvider.select(...))` 选择器、所有 `context.go/push(...)` 导航、所有 `AppLocalizations` 文案 key（逐项在任务中列出，必须原样保留）；② 把旧共享原语（`QuestPanel`/`EmptyState`/裸 `FilledButton`/`LinearProgressIndicator` 等）替换为 Cozy Quest 组件（`AppCard`/`MascotEmptyState`/`AppPrimaryButton`/`AppProgressBar`/`AppPill`），并按 spec §2「乔布斯级克制」原则收敛布局（单焦点、舍得留白、单层柔影、字阶克制、色彩有纪律）；③ 行为不变。

**风险隔离:** 课程流（`/lesson/:id` 预习、`/lesson/:id/quiz` 答题、`/lesson/:id/result` 结算）含交互机制且对应测试最脆弱（"quiz feedback stays visible"、"working back path"），**移至 Plan 3**，不在本计划内。

**Tech Stack:** Flutter / Dart 3、Material 3、flutter_test、Riverpod、GoRouter。

**对应 spec:** `docs/superpowers/specs/2026-06-16-ui-redesign-cozy-quest-design.md`（§2 原则、§6 组件、§7 吉祥物、§9 保留/弃用）。

**前置:** 分支 `feat/ui-friendly-quest-reskin`，Plan 1 已合入（`AppCard`/`AppPrimaryButton`/`AppSecondaryButton`/`AppPill`/`AppProgressBar`/`MascotImage`/`MascotEmptyState` 已就绪）。所有命令在 `linguaquest/` 下执行。提交**原子化、无 `Co-Authored-By` trailer**。

---

## 不可破坏的安全网（每个任务都适用）

1. **既有集成测试必须保持绿色。** `test/widget_test.dart` 通过可见文案 + 导航断言这些屏幕。迁移后跑 `flutter test`，所有既有测试必须通过。若某条因「找不到文案/控件」失败：定位原因——若是因为我**删改了可见文案或导航**，那是回归，必须修复迁移使文案/路由原样保留；只有当失败纯粹因为控件类型断言（极少，本套件主要按文案/Scrollable/InkWell 断言）时，才在征得结构等价后更新该断言并在 commit 说明。
2. **保留 l10n。** 不得硬编码用户可见字符串；所有文案继续走任务中列出的 `l10n.*` getter。不得新增未在 `.arb` 定义的 key（本计划不改文案，只换视觉）。
3. **保留数据接线。** 每个 `ref.watch(appControllerProvider.select((s) => ...))` 选择器与每个 `ref.read(appControllerProvider.notifier).xxx(...)` 调用原样保留（任务中逐条列出）。
4. **保留导航。** 每个 `context.go(...)`/`context.push(...)` 目标路由字符串原样保留（任务中逐条列出）。
5. **风格纪律（spec §2）：** 卡片统一 `AppCard`（单层柔影、`radiusCard`）；彩色仅用于 XP/进度/连击/状态（`AppPill` 语义变体 + `AppProgressBar` 渐变）；其余中性。禁止双层阴影、禁止渐变滥用（渐变仅 `AppProgressBar` 与吉祥物英雄区）。
6. **`flutter analyze` 必须 `No issues found!`。**

---

## File Structure

- `lib/features/home/home_screen.dart` — 修改：视觉层迁移到 Cozy Quest 组件。
- `lib/features/profile/profile_screen.dart` — 修改：同上。
- `lib/features/learning/learning_path_screen.dart` — 修改：同上。
- `lib/features/review/review_center_screen.dart` — 修改：同上。
- `test/widget_test.dart` — 修改：在既有 home / review 测试中**追加**结构断言，锁定新组件出现（不删除既有断言）。
- 可能微调：上述屏幕引用的 inline 私有 widget（同文件内）随之改写。**不改** `data/`、`core/state/`、`core/routing/`、`l10n/`、`server/`。

---

## Task 1: 首页 Cozy Quest 重塑

**Files:**
- Modify: `lib/features/home/home_screen.dart`
- Modify: `test/widget_test.dart`（向既有 home 测试追加结构断言）

**必须原样保留的数据选择器**（来自 `home_screen.dart`，全部基于 `final state = ref.watch(appControllerProvider)` 或等价 select）：
`state.user`、`state.currentWordBook`、`state.reviewQueue.length`、`state.dailyNewTarget`、`state.isStudyPlanPaused`、`state.todayLearningWords`、`state.todayReviewWordIds.length`、`state.currentLesson`、`state.formalLessons`、`state.unreadNotificationCount`、`state.completedLearningWords`、`state.masteredReviewWords`、`state.dueWords`、`state.weakWords`。今日进度计算：`dailyProgress = (todayWork / totalWork).clamp(0.0, 1.0)`，其中 `todayWork = todayLearningWords + todayReviewWordIds.length`、`totalWork = isStudyPlanPaused ? 0 : dailyNewTarget + reviewTarget`、`reviewTarget = isStudyPlanPaused ? 0 : dueCount`。

**必须原样保留的导航：**
头像→`context.go('/profile')`；搜索框→`context.push('/search')`；通知铃→`context.push('/notifications')`；调整计划→`context.push('/settings/study-plan')`；开始学习/新学→`context.push('/study/new')`；复习→`context.push('/study/review')`；词书→`context.push('/wordbook')`；每日文章→`context.go('/ai-learning')`；学习路径→`context.push('/learn')`；今日单词卡→无词 `context.push('/wordbook')` / 有词 `context.push('/wordbook/${wordOfDay.id}')`；弱词区按钮→`context.push('/study/review')`；弱词项→`context.push('/custom-words/${word.id}')`。

**必须原样保留的 l10n key：** `homePersonalSpace`、`homeSearchHint`、`homeNotifications`、`homePlanPaused`、`homeTodayCompleted`、`homeTodayProgress`、`homeTaskConsole`、`homeResumePlan`、`homeStartLearning`、`homeReviewOnly`、`homeAdjustPlan`、`homeStreakDays`、`homeWordbookShortcut`、`homeDailyArticle`、`homeDailyArticleSubtitle`、`homeLearningPath`、`homeLearningPathSubtitle`、`homeWordOfDay`、`homeOpenWordCard`、`homeWeakWords`、`homeNoWeakWords`、`homeWeakWordsReview`、`homeWeakWordsEmptyHint`、`homeLearned`、`homeMastered`、`homeReviewLabel`、`commonWords`、`commonReview`、`commonMastery`。

**组件映射（视觉层替换）：**
- 所有 `QuestPanel(...)` 容器 → `AppCard(...)`（内边距默认 `AppTokens.s16`；卡间距 `AppTokens.s12`）。
- 今日焦点头像区：用 `MascotImage(size: 40)` 作为问候头像（点击仍 `context.go('/profile')`，外层包 `InkWell`/`GestureDetector` 保留语义）；连击用 `AppPill(variant: PillVariant.streak, icon: Icons.local_fire_department_rounded, label: l10n.homeStreakDays(streak))`；XP/目标等小标签用 `AppPill`（XP→`PillVariant.xp`，普通信息→`PillVariant.primary`）。
- 今日进度环 `_DailyProgressRing`（基于 `CircularProgressIndicator`）**必须保留为环形**——既有测试 `home progress uses the combined new and review target` 断言 `find.byType(CircularProgressIndicator)` 且 `value == 4/14`、文案「今天完成 4/14 词」「29%」「今日」。迁移时保留该环与这些文案/数值，仅把其外层容器换 `AppCard`、收敛周边布局。**不要**把首页今日进度改成 `AppProgressBar`（会破坏该测试）。`AppProgressBar` 可用于其他线性进度场景，但首页今日进度保持环形。
- 任务控制台主行动（开始学习/恢复计划）→ `AppPrimaryButton(label: ..., onPressed: ...)`；次级（调整计划）→ `AppSecondaryButton` 或文本按钮（保留路由）。
- 三联学习信号（学/复/掌握）→ 复用既有 `StatTile`（已 token 化）排成一行，置于一张 `AppCard` 内。
- 弱词空状态（`homeNoWeakWords`/`homeWeakWordsEmptyHint`）→ `MascotEmptyState(title: l10n.homeNoWeakWords, message: l10n.homeWeakWordsEmptyHint, action: <去复习按钮，push '/study/review'>)`。
- 计划暂停提示（`homePlanPaused`）→ 放入一张柔色 `AppCard`（中性，不抢戏）。

**布局收敛（spec §2）：** 一屏聚焦「今天该学什么」。顶部问候行（吉祥物 + 名称/书目 + 连击 pill）→ 今日任务英雄 `AppCard`（大号进度数字 + `AppProgressBar` + 主 CTA）→ 三联 `StatTile` 卡 → 快捷入口（词书/文章/路径，列表式 `AppCard`）→ 今日单词卡 → 弱词区（有则列表，空则 `MascotEmptyState`）。去除多余分隔与装饰，间距用 `AppTokens.s12/s16/s20`。

- [ ] **Step 1: 写失败测试（向既有 home 测试追加结构断言）**

打开 `test/widget_test.dart`，找到测试 `testWidgets('renders redesigned home dashboard for an existing learner', ...)`。在其断言区（首页渲染并稳定后、该 test 闭合前）追加：

```dart
    // Cozy Quest 卡片已落地首页。
    expect(find.byType(AppCard), findsWidgets);
```

并确保该文件顶部 import 区含：
```dart
import 'package:linguaquest/core/widgets/app_card.dart';
```
（若已存在勿重复添加。仅断言 `AppCard`——不要断言 `AppProgressBar`，因首页今日进度保持环形 `CircularProgressIndicator`。）

- [ ] **Step 2: 跑该测试确认失败**

Run: `flutter test test/widget_test.dart --name "renders redesigned home dashboard for an existing learner"`
Expected: FAIL —— 首页尚未使用 `AppCard`，`findsWidgets` 落空。

- [ ] **Step 3: 实现迁移**

按上面的「组件映射 + 布局收敛」改写 `lib/features/home/home_screen.dart` 的 `build` 及其 inline 私有 widget（`_DailyFocusHeader`/`_DailyTaskPanel`/`_DailyProgressRing`/`_HomeLearningSignals`/`_HomeInfoLink`/`_HomeShortcutList`/`_WeakWordLink`/`_SoftPanel` 等）。逐条对照上面三份「保留」清单——每个选择器、每个路由、每个 l10n key 必须仍在代码中且语义一致。删除对 `QuestPanel` 的依赖（改用 `AppCard`）；空状态改 `MascotEmptyState`。不得改动 `home_screen.dart` 以外文件。

实现约束：
- import 新增 `package:linguaquest/core/widgets/app_card.dart` 等所需组件；移除不再使用的 import（避免 analyze 告警）。
- 数字强调：今日进度/关键计数用大号 `fontWeight: w800`（参考 `Theme.of(context).textTheme` 的 headline/display + `AppTokens` 文本色）。
- 彩色纪律：除 XP/连击/进度/状态外一律中性文本色（`colorScheme.onSurface`/`onSurfaceVariant`）。

- [ ] **Step 4: 跑测试确认通过 + 全量回归**

Run: `flutter test test/widget_test.dart --name "renders redesigned home dashboard for an existing learner"`
Expected: PASS。
Run: `flutter test`
Expected: All tests passed!（既有 home 相关测试——progress 计算、search 入口、word-of-day、new-study/review 入口——全绿，证明数据/导航/文案未回归。）
Run: `flutter analyze`
Expected: `No issues found!`

> 若某条既有 home 测试失败：对照失败信息，确认是否因可见文案/路由被改动。是则修复迁移恢复文案/路由；不是（纯控件类型断言且结构等价）则更新断言并在 commit 说明。

- [ ] **Step 5: 提交**

```bash
git add lib/features/home/home_screen.dart test/widget_test.dart
git commit -m "feat(home): reskin home dashboard with Cozy Quest components"
```

---

## Task 2: 我的（Profile）Cozy Quest 重塑

**Files:**
- Modify: `lib/features/profile/profile_screen.dart`

**必须原样保留的数据选择器：** `state.user`（name/email/targetExam/level/xp/streak）、`state.reviewWords`（掌握数 = `masteryLevel >= 4 || status == 'Mastered'` 计数）、`state.completedLearningWords`、`state.learningPathProgress`、`state.totalLearningWords`、`state.currentStudyBook.name`、`state.customWords.length`、`state.weakWords.length`、`state.themeMode`、`state.reminderSettings`、`state.locale`、`state.userAssets`。helper `newWordbookCount(state) => state.customWords.length`。

**必须原样保留的导航 / notifier 调用：**
学习计划→`context.push('/settings/study-plan')`；词书→`context.push('/wordbook')`；自定义词→`context.push('/custom-words')`；错题本→`context.push('/mistake-book')`；主题→`context.push('/settings/theme')`；提醒→`context.push('/settings/reminder')`；帮助→`context.push('/help')`；关于→`context.push('/about')`；语言切换→`ref.read(appControllerProvider.notifier).updateLocale(locale)`（`Locale('zh'|'ms'|'en')`，bottom sheet）；登出→`ref.read(appControllerProvider.notifier).logout()` 然后 `context.go('/onboarding')`。

**必须原样保留的 l10n key：** `profileLearner`、`profileNoEmail`、`profileLearnedWords`、`profileMasteredWords`、`profileStreakDays`、`profileCurrentBookProgress`、`profilePlanLabel`、`profileHelpTitle`、`profileAboutTitle`、`profileAssetsTitle`、`profileAssetsSubtitle`、`profileAssetsEmpty`、`profileAssetMeta`、`profileLogout`、`commonWords`、`commonWordbook`、`commonCustomWords`、`commonMistakeBook`、`commonTheme`、`commonDailyReminder`、`commonXP`、`settingsReminderOff`、`settingsThemeLight`、`settingsThemeDark`、`settingsThemeSystem`、`languageSetting`、`onboardingTagPillStreak`。helper `displayTarget`/`displayLevel`/`displayLotteryCategory`（来自 `core/utils/ui_labels.dart`）原样保留。

**组件映射：**
- 头部 `BrandHeroCard` → 保留为英雄区，但内部头像换 `MascotImage(size: 72)`（吉祥物贯穿，spec §7）；XP/连击仍用 `AppPill`（XP→`PillVariant.xp`，连击→`PillVariant.streak`）。（`BrandHeroCard` 是品牌英雄卡，允许其品牌底色；若它内部用渐变/双阴影违反 §2，则在本任务内把其改为 `AppCard` + 藏青底块 `AppTokens.brandNavy` 的简化英雄区。优先后者以贴合「单层柔影」。）
- 三联统计（学/掌握/连击）→ 既有 `StatTile` 排一行，置于 `AppCard`。
- 进度卡 `_ProfileProgressCard`：保留 `ProgressRing`（token 化）或改 `AppProgressBar(value: learningPathProgress)` + 大数字；二选一，优先 `ProgressRing` 表「完成度」。整卡用 `AppCard`。
- 所有 `QuestPanel` 分组容器 → `AppCard`；`_SettingsGroup`/`_SettingsItem` 行用 `AppCard` 承载、行间 `AppTokens.hairline` 分隔。
- 资产空状态（`profileAssetsEmpty`）→ `MascotEmptyState(title: l10n.profileAssetsTitle, message: l10n.profileAssetsEmpty)`（无 action）。
- 登出按钮 → `AppSecondaryButton(label: l10n.profileLogout, onPressed: ...)`。

**布局收敛：** 英雄区（吉祥物 + 名/邮/目标·等级 + XP/连击 pill）→ 三联 `StatTile` 卡 → 完成度 `AppCard`（仅当 `totalLearningWords > 0`）→ 设置分组若干 `AppCard` → 资产区（列表或 `MascotEmptyState`）→ 登出。

- [ ] **Step 1: 写失败/守卫测试**

本屏无独立 widget 测试且集成套件对 profile 主要按文案断言。新建一个轻量结构守卫，复用既有 `test/widget_test.dart` 的 app 启动 harness不现实（harness 庞大）。改为**在迁移后**以 `flutter analyze` + 全量 `flutter test`（既有 `profile new wordbook count uses custom copies only` 等测试）作为回归守卫，并人工核对「保留清单」。**因此本任务 TDD 形式为：先改一处可断言的纯展示——把头像换 `MascotImage`，作为吉祥物贯穿的可验证锚点。** 在 `test/widget_test.dart` 找到会渲染 Profile 的路径（main shell tab 切换测试 `main shell supports deliberate horizontal tab swiping` 会进入 profile tab），或新增断言较脆。**简化裁决：** 本任务不新增测试，验证以 analyze + 全量 suite 绿 + 保留清单核对为准（见 Step 3-4）。在 commit 说明此点。

> 说明：profile 屏纯展示+设置跳转，既有集成套件已通过文案/tab 行为覆盖其关键路径；为其单独搭建种子化 harness 成本高、收益低（YAGNI）。结构正确性由「保留清单逐条核对 + analyze + 全量 suite」保证。

- [ ] **Step 2: 实现迁移**

按「组件映射 + 布局收敛」改写 `lib/features/profile/profile_screen.dart` 的 `build` 与 inline 私有 widget（`_ProfileHeader`/`_ProfileStatsRow`/`_ProfileProgressCard`/`_SettingsGroup`/`_SettingsItem`/`_LanguageSettingsItem`/`_AssetInventory`/`_AssetRow` 等）。逐条对照三份「保留」清单。移除对 `QuestPanel` 的依赖；空状态用 `MascotEmptyState`；登出用 `AppSecondaryButton`。不改其他文件。

- [ ] **Step 3: 全量回归 + 核对**

Run: `flutter analyze`
Expected: `No issues found!`
Run: `flutter test`
Expected: All tests passed!（含 `profile new wordbook count uses custom copies only`、`main shell ... tab swiping`、`logout keeps lesson status ...` 等。）
人工核对：打开改后文件，确认「保留清单」中每个选择器/路由/notifier 调用/l10n key 仍在且语义一致。

- [ ] **Step 4: 提交**

```bash
git add lib/features/profile/profile_screen.dart
git commit -m "feat(profile): reskin profile screen with Cozy Quest components"
```

---

## Task 3: 学习路径 Cozy Quest 重塑

**Files:**
- Modify: `lib/features/learning/learning_path_screen.dart`

**必须原样保留的数据：** `ref.watch(appControllerProvider)` → `state.formalLessons`、`state.isStudyPlanPaused`。每个 lesson 渲染字段：`lesson.section`、`lesson.title`、`lesson.description`、`lesson.status`（`'locked'|'current'|'completed'`）、`lesson.xpReward`、`lesson.estimatedMinutes`、`lesson.words.length`、`lesson.words.first.imageCue`（空则 `'?'`）。

**必须原样保留的导航：** lesson 预览模态内 FilledButton→`context.push('/lesson/${lesson.id}')`；锁定项 `onTap: null`（不可点）；词书→`context.push('/wordbook')`；调整计划→`context.push('/settings/study-plan')`。

**必须原样保留的 l10n key：** `learningPathTitle`、`reviewCenterPlanPaused`、`learningPathLessonCompleted`、`learningPathLessonCurrent`、`learningPathLessonLocked`、`commonXP`、`commonWords`、`learningPathOpenWordbook`、`learningPathAdjustPlan`、`learningPathStartLearning`。

**组件映射：**
- 每个 `_PathNode` 课程节点 → `AppCard`（锁定态降饱和/中性；当前态用 `AppTokens.primarySoft` 描边或左侧强调；完成态成功语义）。
- 节点上的 XP/时长/词数 `PillLabel` → `AppPill`（XP→`PillVariant.xp`，时长/词数→`PillVariant.primary`，状态→对应语义）。
- 状态徽章 `StatusBadge` → `AppPill`：completed→`PillVariant.success`、current→`PillVariant.primary`、locked→中性（保留 `StatusBadge` 亦可，若其已 token 化且符合 §2；优先 `AppPill` 统一）。
- 预览模态底部 FilledButton（开始学习）→ `AppPrimaryButton(label: l10n.learningPathStartLearning, onPressed: () => context.push('/lesson/${lesson.id}'))`。
- 暂停 banner（`reviewCenterPlanPaused`）→ 中性 `AppCard`。
- 词书/调整计划底部按钮 → `AppSecondaryButton` / 文本按钮（保留路由）。
- 节点间 `_PathConnector` 竖线保留（细化为 `AppTokens.hairline` 颜色、克制）。

**布局收敛：** 顶部 AppBar（标题 `learningPathTitle` + 返回）→ 暂停时 `AppCard` 提示 → 课程节点 `AppCard` 列表（路径感由 `_PathConnector` + 状态色表达）→ 底部词书/调整计划次级入口。

- [ ] **Step 1: 写失败测试**

集成套件 `lesson preview does not open training-only timed packs`、`regular quiz cannot open training-only timed packs` 会经由学习路径打开预览。为锁定迁移，在 `test/widget_test.dart` 找到 `testWidgets('lesson preview does not open training-only timed packs', ...)`，在其进入学习路径并稳定后追加结构断言：

```dart
    expect(find.byType(AppCard), findsWidgets);
```
并确保该文件已 import `package:linguaquest/core/widgets/app_card.dart`（Task 1 已加则复用）。

> 若该测试的导航路径不便插入断言（例如它不在 `/learn` 屏停留），改为在最贴近「停留于 `/learn`」的既有测试处追加；若确无合适落点，则本任务改用「analyze + 全量 suite 绿 + 保留清单核对」作为守卫并在 commit 说明（与 Task 2 同策略）。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/widget_test.dart --name "lesson preview does not open training-only timed packs"`
Expected: FAIL（学习路径尚未用 `AppCard`）。若该测试不停留于 `/learn` 致断言不可达，转 Task 2 式守卫。

- [ ] **Step 3: 实现迁移**

按映射改写 `lib/features/learning/learning_path_screen.dart`（`build`、`_PausedBanner`、`_PathNode`、`_PathConnector`、预览模态 `_showPreview`）。逐条对照保留清单。移除不用的 import。

- [ ] **Step 4: 全量回归**

Run: `flutter test test/widget_test.dart --name "lesson preview does not open training-only timed packs"`
Expected: PASS。
Run: `flutter test`
Expected: All tests passed!
Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: 提交**

```bash
git add lib/features/learning/learning_path_screen.dart test/widget_test.dart
git commit -m "feat(learning): reskin learning path with Cozy Quest components"
```

---

## Task 4: 复习中心 Cozy Quest 重塑

**Files:**
- Modify: `lib/features/review/review_center_screen.dart`
- Modify: `test/widget_test.dart`（向既有 review 测试追加结构断言）

**必须原样保留的数据选择器：** `state.isStudyPlanPaused`、`state.reviewQueue`、`state.dueWords.length`、`state.weakWords`、`state.lastResult?.mistakes ?? const []`、`state.customWords.length`、`state.dailyReviewLimit`、`_ReviewTile` 内 `appControllerProvider.select((s) => s.isLoading)`。word 字段：`word.word`、`word.meaning`、`word.nextReviewAt`、`word.masteryLevel`、`word.source`、`word.sourceWordId`。

**必须原样保留的导航 / notifier 调用：** 记忆/遗忘按钮→`ref.read(appControllerProvider.notifier).reviewWord(word.id, isCorrect)`；新增自定义词→`context.push('/custom-words/new')`；查看错题本→`context.push('/mistake-book')`；弱词项→`word.source == 'target'` 时 `context.push('/wordbook/${word.sourceWordId ?? word.id}')`，否则 `context.push('/custom-words/${word.id}')`；导入错题→`ref.read(appControllerProvider.notifier).addMistakesToCustomWords(_selectedIds)`。`formatRelativeDue(word.nextReviewAt, DateTime.now())` 与 `wordInitialCue(...)` helper 保留。

**必须原样保留的 l10n key：** `reviewCenterTitle`、`reviewCenterPlanPaused`、`reviewCenterPlanPausedHint`、`reviewCenterTodayDone`、`reviewCenterCardsDue`、`reviewCenterDailyCap`、`reviewCenterTodayDue`、`mistakeBookTitle`、`commonCustomWords`、`reviewCenterEmpty`、`wordbookAddCustom`、`reviewCenterForgot`、`reviewCenterRemembered`、`reviewCenterPostponedMessage`、`reviewCenterCloserReviewMessage`、`reviewCenterUpdateFailed`、`mistakeBookMistakes`、`mistakeBookNoLessonMistakes`、`commonLesson`、`reviewCenterAddMistakeCards`、`reviewCenterAddSelected`。

**组件映射：**
- 复习信号面板 `QuestPanel`（_ReviewQueueSignals 三联）→ `AppCard` + 既有 `StatTile`。
- 复习卡 `_ReviewTile` 每张 → `AppCard`；掌握度 `PillLabel` → `AppPill`（按掌握度选语义：高→success，低→streak/中性）；到期时间小标签 → `AppPill(PillVariant.primary)` 或中性文本。
- 记忆/遗忘按钮 → 「记得」`AppPrimaryButton`（或 success 语义的主行动），「忘了」`AppSecondaryButton`（或 streak 语义）。保留 `reviewWord` 调用与 snackbar。
- 空状态 `EmptyState`（`reviewCenterEmpty`）→ `MascotEmptyState(title: l10n.reviewCenterTodayDone, message: l10n.reviewCenterEmpty, action: <新增自定义词按钮 push '/custom-words/new'>)`。
- 错题/弱词行 `_LessonMistakeRow`/`_WeakWordRow` → `AppCard` 列表项；错题导入 `_MistakeWordImporter` 选择行保留勾选语义，容器换 `AppCard`。

**布局收敛：** AppBar（`reviewCenterTitle` + 返回）→ 状态头（暂停/完成/待复习数，大号数字）→ 三联信号 `AppCard` → 「今日待复习」区：空则 `MascotEmptyState`，否则 `_ReviewTile` 卡列表（每卡含词/义/到期/掌握 + 记得/忘了双按钮）→ 错题与弱词区（错题导入 + 列表）。

- [ ] **Step 1: 写失败测试（向既有 review 测试追加结构断言）**

打开 `test/widget_test.dart`，找到 `testWidgets('review flow confirms before leaving after progress', ...)`（该测试进入 `/review` 相关流）。在其进入复习中心并稳定后追加：

```dart
    expect(find.byType(AppCard), findsWidgets);
```
确保已 import `app_card.dart`。

> 若 `review flow confirms before leaving after progress` 实际停留在 mixed study session 而非 `/review` 屏，改在 `lesson mistake appears in review center after result` 测试（其断言出现在复习中心）处追加该结构断言；选能真正渲染 `ReviewCenterScreen` 的测试落点。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/widget_test.dart --name "lesson mistake appears in review center after result"`
Expected: FAIL（复习中心尚未用 `AppCard`）。

- [ ] **Step 3: 实现迁移**

按映射改写 `lib/features/review/review_center_screen.dart`（`build`、`_ReviewStatusHeader`、`_ReviewQueueSignals`、`_ReviewSignal`、`_ReviewTile`、`_LessonMistakeRow`、`_WeakWordRow`、`_MistakeWordImporter`、`_MistakeSelectionRow`）。逐条对照保留清单。`reviewWord`/`addMistakesToCustomWords` 调用与所有 snackbar 文案原样保留。空状态用 `MascotEmptyState`。

- [ ] **Step 4: 全量回归**

Run: `flutter test test/widget_test.dart --name "lesson mistake appears in review center after result"`
Expected: PASS。
Run: `flutter test`
Expected: All tests passed!（含 `review queues dedupe ...`、`lesson mistake appears in review center after result`。）
Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 5: 提交**

```bash
git add lib/features/review/review_center_screen.dart test/widget_test.dart
git commit -m "feat(review): reskin review center with Cozy Quest components"
```

---

## Task 5: 地基整体验收（核心 Hub 屏）

**Files:** 无新增（验收）。

- [ ] **Step 1: 全量分析**

Run: `flutter analyze`
Expected: `No issues found!`

- [ ] **Step 2: 全量测试**

Run: `flutter test`
Expected: All tests passed!（既有集成套件 + Plan 1 组件测试 + 本计划追加的结构断言全绿。）

- [ ] **Step 3: 残留旧原语核查**

Run: `grep -rn "QuestPanel" lib/features/home lib/features/profile lib/features/learning/learning_path_screen.dart lib/features/review`
Expected: 无输出（这 4 屏已不再依赖 `QuestPanel`）。若仍有，回到对应任务替换为 `AppCard`。
（注：`QuestPanel` 定义与其他未迁移屏幕仍可保留，留待后续计划；本步只验证本计划 4 屏已迁移。）

- [ ] **Step 4: 提交（如有核查后修订）**

```bash
git add -A
git commit -m "chore(ui): finalize Cozy Quest migration for core hub screens"
```

---

## Self-Review（作者自查）

**Spec 覆盖：** §2 原则贯穿 4 屏布局收敛；§6 组件（AppCard/AppPill/AppProgressBar/AppPrimaryButton/AppSecondaryButton/StatTile/ProgressRing）落地；§7 吉祥物经 `MascotImage`（首页/我的头像）与 `MascotEmptyState`（弱词/资产/复习空态）贯穿；§9 保留数据/状态/路由/i18n、弃用 `QuestPanel`（本批 4 屏）。课程流（预习/答题/结算）显式延后到 Plan 3（风险隔离，已在文首声明）。

**占位符扫描：** 无 TBD。Task 2/3 对「测试落点不可达」给出了明确的退化守卫策略（analyze + 全量 suite + 保留清单核对）而非占位。屏幕 body 未逐行抄写最终代码——这是大型既有屏的**视觉迁移**，以「精确保留清单 + 组件映射 + 布局收敛 + 既有集成测试安全网」作为完整规格；这是该类重构的恰当粒度，非占位符。

**类型一致性：** 引用的组件名（`AppCard`/`AppPrimaryButton`/`AppSecondaryButton`/`AppPill`/`PillVariant.{xp,success,streak,primary}`/`AppProgressBar`/`MascotImage`/`MascotEmptyState`）均为 Plan 1 已交付且签名一致；既有 `StatTile`/`ProgressRing`/`StatusBadge` 复用。

**范围：** 仅 4 屏视觉层 + `test/widget_test.dart` 追加断言；不碰 data/state/routing/l10n/server。

## 后续计划

- **Plan 3 — 课程流 + 混合学习**：`/lesson/:id` 预习、`/lesson/:id/quiz` 答题、`/lesson/:id/result` 结算、`/study/new`+`/study/review` 混合学习。
- **Plan 4 — 训练场 & 词书**：训练场、训练小游戏、限时测试、词书总览/详情、自定义词 CRUD。
- **Plan 5 — 任务中心/发现/班级/排行/分析 + 设置 + 入门/认证 + 杂项**，并清理已无引用的旧 `QuestPanel` 等原语。
