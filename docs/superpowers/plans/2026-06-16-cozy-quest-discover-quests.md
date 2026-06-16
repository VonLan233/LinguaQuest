# Cozy Quest 发现/任务中心/班级/分析/AI 重塑 Implementation Plan（Plan 5 / 6）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 把发现/任务中心/班级/排行/分析/AI 共 11 个屏幕的**视觉层**迁移到 Cozy Quest 组件库；保留全部数据/notifier/导航/文案，使 `test/widget_test.dart` 持续通过。

**Architecture:** 视觉迁移。沿用既有约定（记忆 cozy-quest-component-conventions）。这些屏幕大多是简单展示屏（**无 widget 测试**），回归风险低；唯 **XP 任务**（文案 + InkWell ancestor 测试耦合 + 共享 `shared_widgets.dart`）与 **抽奖**（`drawLottery` notifier + FilledButton）需谨慎。**不改** `core/widgets/` 实现（含 `learning_badges.dart` 的 `PillLabel`/`IconCueBadge`/`QuestIconButton`、`quest_list_row.dart`、`status_badge.dart`、`section_header.dart`）——这些被已完成屏幕复用，仅在本计划屏幕内**停止使用** `QuestPanel`/`StatusBadge`/`PillLabel`，替换为 `AppCard`/`AppPill`。`SectionHeader`/`IconCueBadge`/`QuestIconButton`/`FallbackBackButton` 可继续复用。

**Tech Stack:** Flutter / Dart 3、Material 3、flutter_test、Riverpod、GoRouter。

**对应 spec:** `docs/superpowers/specs/2026-06-16-ui-redesign-cozy-quest-design.md`（§2/§6/§7/§9）。

**前置:** 分支 `feat/ui-friendly-quest-reskin`，Plans 1-4 已合入（含 `PillVariant.neutral`、`AppSecondaryButton.icon`）。命令在 `linguaquest/` 下。提交**原子化、无 `Co-Authored-By`**；**显式 stage 文件,禁止 `git add -A`**。

---

## 安全网（每任务适用）

① 既有集成测试保持绿色；② 保留 l10n（不增删 key，逐屏列出）；③ 保留数据/notifier；④ 保留导航；⑤ 风格纪律（spec §2）；⑥ `flutter analyze` 干净；⑦ 每屏 `dart format`。

## 通用映射

`QuestPanel` → `AppCard`；`PillLabel`/`StatusBadge` → `AppPill`（语义：XP→xp、进度/信息→primary、达成→success、紧迫/警告→streak、纯信息标签→neutral）；`FilledButton(.icon)` 主 CTA → `AppPrimaryButton`（**仅当无类型耦合**——先 grep）；`OutlinedButton(.icon)` → `AppSecondaryButton`（支持 icon）；`LinearProgressIndicator` → `AppProgressBar`（除非类型耦合）；`TextField` 输入保留；空态 → `MascotEmptyState`。`QuestListRow` 作为列表行容器可换 `AppCard(onTap:)`（其内部 InkWell 保留以满足 ancestor 测试）。

---

## File Structure

- `lib/features/discover/discover_screen.dart`、`xp_tasks_screen.dart`、`lucky_draw_screen.dart`、`community_screen.dart`、`shared_widgets.dart`
- `lib/features/ai_learning/ai_learning_screen.dart`
- `lib/features/quests/quest_screen.dart`、`leaderboard_screen.dart`、`progress_analytics_screen.dart`、`class_mode_screen.dart`、`class_progress_screen.dart`、`ai_tutor_screen.dart`
- `test/widget_test.dart` — 仅必要时（XP 任务结构断言；保留所有文案/InkWell 断言）
- 不改 `data/`、`core/state/`、`core/routing/`、`l10n/`、`server/`、`core/widgets/` 实现

---

## Task 1: 发现 Hub + 社区（discover_screen + community_screen）

两屏均无 notifier 逻辑、无 widget 测试。

**discover_screen.dart 保留：** `state.user`(xp/streak)；导航 `context.push('/discover/xp-tasks'|'/discover/lucky-draw'|'/discover/community')`；l10n: commonXP、homeStreakLabel、discoverXpTasks(Subtitle)、discoverLuckyDraw(Subtitle)、discoverCommunityPosts(Subtitle)。映射：`_DiscoverNavCard`（Ink+Container）→ `AppCard(onTap:)`；XP/连击 `PillLabel` → `AppPill`(xp/streak)。
**community_screen.dart 保留：** 静态；l10n: discoverCommunityPosts、communityPostCheckinTitle/Tag/Body、communityPostAbstractTitle、communityPostMistakeTag、communityPostAbstractBody。映射：`_ForumPost` `QuestPanel` → `AppCard`；`StatusBadge`(tag) → `AppPill`(neutral/streak)。

- [ ] **Step 1:** 退化守卫（无测试落点）：实现后 `flutter analyze` 干净 + 全量 `flutter test` 绿 + 保留清单 grep 核对。先 `grep -n "widgetWithText(FilledButton\|widgetWithText(OutlinedButton" test/widget_test.dart`（确认 discover/community 无类型耦合）。
- [ ] **Step 2:** 实现两屏迁移；移除未用 import；`dart format` 两文件。
- [ ] **Step 3:** `flutter analyze` 干净；`flutter test` 全绿（含 `discover check-in only counts same-day study` 等——它们点 `find.text('发现')` 进 discover tab，不受卡片类型影响）。
- [ ] **Step 4:** grep 核对：`grep -oE "l10n\.[a-zA-Z]+"` 两文件无 key 丢失；`grep -n "QuestPanel\|PillLabel\|StatusBadge"` 期望无。
- [ ] **Step 5:** 提交：`git add lib/features/discover/discover_screen.dart lib/features/discover/community_screen.dart` → `git commit -m "feat(discover): reskin discover hub and community with Cozy Quest components"`。

---

## Task 2: XP 任务（xp_tasks_screen + shared_widgets）— 谨慎（测试耦合）

**保留数据/notifier：** `state.user`、`state.todayClaimedRewardIds`、`state.todayCompletedFormalLessonIds`、`state.todayReviewWordIds`、`state.todayTrainingGameIds`、`state.customWords`、`state.weakWords`；`claimLocalReward(id:, points:, isAvailable:)`（snackbar `discoverClaimedMessage`/`discoverCannotClaim`）。5 个任务的 isDone/isClaimed/onTap 逻辑全部保留（含 weak-cleanup 的 `reviewedMistakeToday && weakWords.isEmpty`）。
**保留导航：** onTap 各 `context.go('/home')`、`context.push('/study/new')`、`context.push('/study/review')`、`context.go('/training')`、`context.push('/review')`。
**保留 l10n：** discoverXpTasks、discoverDailyCheckin(Condition)、discoverNewLearning(Condition)、discoverReviewDone(Condition)、discoverTrainingChallenge(Condition)、discoverWeakCleanup(Condition)、discoverClaimedMessage、discoverCannotClaim、discoverViewProfile、discoverClaimed、discoverClaim、discoverGoComplete。
**关键测试耦合（`shared_widgets.dart` 的 RewardTaskRow/RewardTaskList）：** 测试用 `find.text('去完成 +5 XP')`/`find.text('领取 +20 XP')`/`find.textContaining('已入账')`（来自 `discoverGoComplete`/`discoverClaim`/`discoverClaimed`——**文案必须原样**）+ `find.ancestor(of: find.text('错词清理'), matching: find.byType(InkWell))`（任务行必须有 **InkWell** 祖先）。迁移 `RewardTaskList` 的 `QuestPanel` → `AppCard`、`RewardTaskRow` 的 `QuestListRow` → `AppCard(onTap:)` 或保留行结构,但**必须保留每行的 InkWell**(AppCard 的 onTap 即提供 InkWell)与三态徽章文案;`StatusBadge` 三态徽章 → `AppPill`(success/primary/streak),**但徽章文本仍是 discoverClaimed/Claim/GoComplete**。

- [ ] **Step 1:** `grep -n "去完成\|领取\|已入账\|错词清理\|find.byType(InkWell)\|积分任务" test/widget_test.dart` 记录耦合。**不改测试**（文案与 InkWell ancestor 都靠迁移保留）。可选：在 `discover check-in only counts same-day study` 到达 XP 任务屏处加 `expect(find.byType(AppCard), findsWidgets);`（不动其它断言）。
- [ ] **Step 2:** 跑该测试确认失败（若加了断言）。
- [ ] **Step 3:** 实现 `xp_tasks_screen.dart` + `shared_widgets.dart` 迁移。保留全部任务逻辑、文案、InkWell 行。`dart format` 两文件。
- [ ] **Step 4:** `flutter test` 全绿（**务必**含 `discover check-in only counts same-day study`、`discover weak cleanup does not auto-complete without mistakes`、`discover weak cleanup waits until all weak words are clear`、`training completion does not unlock formal new-learning reward`）；`flutter analyze` 干净。**若任一 discover 测试失败**：多半是文案或 InkWell ancestor 丢失——修复迁移恢复之，绝不改测试断言。
- [ ] **Step 5:** 提交：`git add lib/features/discover/xp_tasks_screen.dart lib/features/discover/shared_widgets.dart test/widget_test.dart` → `git commit -m "feat(discover): reskin xp tasks with Cozy Quest components"`。

---

## Task 3: 抽奖（lucky_draw_screen）

**保留数据/notifier：** `state.user`(xp)、`state.isLoading`、`state.userAssets`、`state.lotteryPrizes`、`state.lastLotteryResult`；`drawLottery()`；`canDraw = user != null && user.xp >= lotteryDrawCost && !isLoading`；结果对话框（保留 keep-looking / view-assets→`/profile`）。
**保留 l10n：** discoverLuckyDraw、luckyDrawCostLine、luckyDrawBalanceHint、luckyDrawInventoryCount、luckyDrawNoBoost、luckyDrawNow、luckyDrawInsufficient、luckyDrawShortfall、luckyDrawFailed、luckyDrawSuccessTitle、luckyDrawReward、luckyDrawDeducted、luckyDrawKeepLooking、luckyDrawViewAssets、luckyDrawPoolLoading。
**按钮耦合：** grep 确认抽奖 `FilledButton.icon` 无类型耦合（lucky-draw 无 widget 测试）→ 转 `AppPrimaryButton`（保留 loading 时的禁用/进度语义：loading 时 `onPressed: null` + 可在按钮旁/内显示进度）。
**映射：** `_LotteryPanel`/`_ProbabilityList` 的 `QuestPanel` → `AppCard`；`StatusBadge`(inventory/no-boost) → `AppPill`(primary/neutral)；`ImageCueBadge` 保留；抽奖按钮 → `AppPrimaryButton`。

- [ ] **Step 1:** 退化守卫（无测试）：grep 确认无 `widgetWithText(FilledButton, <抽奖文案>)`。
- [ ] **Step 2:** 实现迁移；保留 `drawLottery`/canDraw/结果对话框/snackbar。`dart format`。
- [ ] **Step 3:** `flutter analyze` 干净；`flutter test` 全绿。
- [ ] **Step 4:** grep 核对 l10n/notifier/路由。
- [ ] **Step 5:** 提交：`git commit -m "feat(discover): reskin lucky draw with Cozy Quest components"`。

---

## Task 4: AI 学习 Hub（ai_learning_screen）

**保留数据：** 无 Riverpod；读 query params `word`/`example`/`translation`。
**保留导航：** `context.push('/ai-tutor')`。
**保留 l10n：** aiLearningTitle、aiLearningTooltip、aiLearningPillError、aiLearningCurrentWord、aiLearningToolsTitle、aiLearningToolAiQA(Desc)、aiLearningStatusSoon、aiLearningToolAiAnalysis(Desc)、aiLearningToolAiWriting(Desc)、aiLearningStatusLater、aiLearningToolCloze(Desc)、aiLearningStatusPlanning、aiLearningToolConfusion(Desc)、aiLearningToolSentence(Desc)。
**映射：** `_AiWordContextCard`/`_AiToolLink`/`QuestPanel` → `AppCard`；`StatusBadge`(soon/later/planning) → `AppPill`(neutral/primary)；`QuestListRow`(planned tools) → `AppCard` 行；`SectionHeader`/`QuestIconButton`/`IconCueBadge` 保留。

- [ ] **Step 1:** 退化守卫（无测试，但 `/ai-learning` 是 tab——`main shell ... tab swiping` 可能经过；若可在其加 `expect(find.byType(AppCard), findsWidgets);` 则加，否则退化）。grep 确认无类型耦合。
- [ ] **Step 2:** 实现；`dart format`。
- [ ] **Step 3:** `flutter analyze` 干净；`flutter test` 全绿。
- [ ] **Step 4:** grep 核对。
- [ ] **Step 5:** 提交：`git commit -m "feat(ai-learning): reskin ai learning hub with Cozy Quest components"`。

---

## Task 5: 任务中心 Hub + 排行 + 分析（quest_screen + leaderboard_screen + progress_analytics_screen）

三屏无 notifier 逻辑、无 widget 测试（leaderboard/progress 用 Riverpod 只读）。
**quest_screen.dart 保留：** 静态；导航 `_QuestRow` route → `context.push('/leaderboard'|'/progress'|'/class-mode'|'/ai-tutor')`；l10n: questCenterTitle/Subtitle、questDailyTask(Body)、questAchievements(Body/Value)、questLeaderboard(Body)、questWeekly、questAnalytics(Body)、questTrend、questClassMode(Body)、questClassCode、questAiTutor(Body)。映射：`_QuestRow` Material/InkWell → `AppCard(onTap:)`；`PillLabel` → `AppPill`；`IconCueBadge`/`SectionHeader` 保留。
**leaderboard_screen.dart 保留：** `state.user`、`state.todayTrainingXp`；l10n: questLeaderboard、leaderboardDefaultName、leaderboardTitle/Subtitle、leaderboardEmptyTitle/Body、leaderboardOnlyValidXp。映射：`_EmptyTrainingLeaderboard` → `MascotEmptyState`（吉祥物贯穿）；`_LeaderboardTile`（CircleAvatar + PillLabel）→ `AppCard` 行 + `AppPill`(xp)；`SectionHeader`/`IconCueBadge` 保留。
**progress_analytics_screen.dart 保留：** `state.reviewWords`、`state.todayTrainingXp`、`state.dueWords`；计算 mastered/attempts/correct/accuracy 不变；`LinearProgressIndicator(value: dueWords.length/reviewWords.length)` → `AppProgressBar`；l10n: questAnalytics、analyticsDataTitle/Subtitle、analyticsAssetsDue、analyticsCards、homeMastered、analyticsTrainingXp、analyticsAccuracy。映射：`_ProgressSignals` 四联 → `AppCard` + `StatTile`（或保留信号行,容器换 AppCard）；复习负荷条 → `AppProgressBar`。（注:`'复习负荷'` 是硬编码中文——保留原样,不引入新 key。）

- [ ] **Step 1:** 退化守卫（无测试）。grep 确认无类型耦合。
- [ ] **Step 2:** 实现三屏；`dart format` 三文件。
- [ ] **Step 3:** `flutter analyze` 干净；`flutter test` 全绿。
- [ ] **Step 4:** grep 核对三屏 l10n/选择器/路由。
- [ ] **Step 5:** 提交：`git add lib/features/quests/quest_screen.dart lib/features/quests/leaderboard_screen.dart lib/features/quests/progress_analytics_screen.dart` → `git commit -m "feat(quests): reskin quest hub, leaderboard and analytics with Cozy Quest components"`。

---

## Task 6: 班级模式 + 班级进度 + AI 导师（class_mode + class_progress + ai_tutor）

三屏无 Riverpod 业务、无 widget 测试。
**class_mode_screen.dart 保留：** 本地 `_codeController`（'LQ-2048'）；join → snackbar `classModeJoined(code)`；view → `context.push('/class-progress')`；l10n: questClassMode、classModeTitle/Subtitle、questClassCode、classModeJoined、classModeJoin、classModeViewProgress。映射：班级码 `TextField` 保留；join `FilledButton.icon` → `AppPrimaryButton`；view `OutlinedButton.icon` → `AppSecondaryButton(icon:)`；可包 `AppCard`。
**class_progress_screen.dart 保留：** 静态 demo rows；back fallback `/class-mode`；l10n: classProgressTitle、classProgressOverview/Subtitle、classTopicExamSignals、classTopicTravelBasics、classTopicWorkplace、classProgressWeakWord。映射：`_ClassProgressRow`（Icon + Column + PillLabel）→ `AppCard` 行 + `AppPill`(primary)；可加进度条 `AppProgressBar`（百分比已有）。
**ai_tutor_screen.dart 保留：** 本地 `_promptController`（初始 `aiTutorSamplePrompt`）、`_promptInitialized`；`TextField`(minLines2 maxLines4) 保留；l10n: questAiTutor、aiTutorSamplePrompt、aiTutorSubtitle、aiTutorInputLabel、aiTutorSampleAnswer（`'即时反馈'` 硬编码标题保留原样）。映射：示例答案 Row 容器 → `AppCard`；`SectionHeader` 保留。

- [ ] **Step 1:** 退化守卫（无测试）。grep 确认无类型耦合（class-mode join/view 无 `widgetWithText(FilledButton/OutlinedButton, ...)`）。
- [ ] **Step 2:** 实现三屏；保留 TextField；`dart format` 三文件。
- [ ] **Step 3:** `flutter analyze` 干净；`flutter test` 全绿。
- [ ] **Step 4:** grep 核对。
- [ ] **Step 5:** 提交：`git add lib/features/quests/class_mode_screen.dart lib/features/quests/class_progress_screen.dart lib/features/quests/ai_tutor_screen.dart` → `git commit -m "feat(quests): reskin class mode, class progress and ai tutor with Cozy Quest components"`。

---

## Task 7: 整体验收

- [ ] **Step 1:** `flutter analyze` → `No issues found!`
- [ ] **Step 2:** `flutter test` → All tests passed!
- [ ] **Step 3:** 残留核查 `grep -ln "QuestPanel" lib/features/discover/*.dart lib/features/ai_learning/*.dart lib/features/quests/*.dart` → 期望无输出。
- [ ] **Step 4:** 提交（如有修订）`git commit -m "chore(ui): finalize Cozy Quest migration for discover and quests"`。

---

## Self-Review（作者自查）

**Spec 覆盖：** §2 原则贯穿 11 屏；§6 组件落地；§7 吉祥物经 `MascotEmptyState`（排行空态）贯穿；§9 弃用 `QuestPanel`（本批 11 屏）。
**占位符扫描：** 无 TBD；XP 任务的文案 + InkWell ancestor 耦合给出明确保留要求；其余无测试屏用退化守卫（analyze + 全量 suite + 清单核对）。硬编码中文（`'复习负荷'`/`'即时反馈'`）明确要求保留原样,不引入新 key。
**类型一致性：** 复用 Plan 1-4 组件（含 neutral pill、secondary icon）+ 既有 `SectionHeader`/`IconCueBadge`/`QuestIconButton`/`StatTile`/`TextField`（不改实现）。
**范围：** 仅 11 屏 + `shared_widgets.dart` + 必要 test 断言；不碰 data/state/routing/l10n/server/core-widgets 实现。

## 后续计划

- **Plan 6 — 设置 + 入门/认证 + 杂项 + 清理**：settings 全系（settings、study-plan、theme、reminder）、help、about、notifications、search；splash、onboarding、login、register、goal-setup；并清理已无引用的旧 `QuestPanel`/`QuestListRow`/`StatusBadge` 等原语（若全 App 已不再引用）。
