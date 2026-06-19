# Cozy Quest 训练场 & 词书重塑 Implementation Plan（Plan 4 / 6）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把训练场（2 屏）与词书/自定义词（5 屏）共 7 个屏幕的**视觉层**迁移到 Cozy Quest 组件库；保留全部数据接线、交互、导航与可见文案，使 `test/widget_test.dart` 持续通过。

**Architecture:** 视觉迁移。沿用 Plan 2/3 沉淀的约定（见记忆 cozy-quest-component-conventions）：`QuestPanel`→`AppCard`、`PillLabel`→`AppPill`、`EmptyState`→`MascotEmptyState`、主 CTA→`AppPrimaryButton`（注意底部栏的 `IntrinsicHeight` 工效坑）、次级→`AppSecondaryButton`、进度→`AppProgressBar`、保留 `StatTile`/`ProgressRing`/`SegmentedTabs`/`WordChoiceButton`/`PronunciationControls`/`ImageCueBadge`/`FilterPillButton`/`AiWordSupportLink`/`WordKnowledgeSections`/`TextFormField`/`SectionHeader`/`QuestListRow`/`BrandHeroCard`(或替换为 AppCard 英雄区)。

**Tech Stack:** Flutter / Dart 3、Material 3、flutter_test、Riverpod、GoRouter。

**对应 spec:** `docs/superpowers/specs/2026-06-16-ui-redesign-cozy-quest-design.md`（§2/§6/§7/§9）。

**前置:** 分支 `feat/ui-friendly-quest-reskin`，Plans 1-3 已合入。命令在 `linguaquest/` 下。提交**原子化、无 `Co-Authored-By`**；**显式 stage 文件,禁止 `git add -A`**。

---

## 安全网（每任务适用）

① 既有集成测试保持绿色；② 保留 l10n（不硬编码、不增删 .arb key，逐屏列出）；③ 保留数据选择器 + notifier 调用；④ 保留导航；⑤ 风格纪律（spec §2）；⑥ `flutter analyze` 干净；⑦ 每屏 `dart format`。

## 按钮/输入耦合（全计划）

- **词书目标词详情**："加入生词本"/"移出生词本" 被 `find.widgetWithText(FilledButton, ...)`（test ~2704/2709/2711）耦合。转 `AppPrimaryButton` 须同步把这些 finder 改 `AppPrimaryButton`；或保留 `FilledButton.icon` 仅 token 化。**优先保留 FilledButton 类型**（它带 icon + 动态 label，AppPrimaryButton 转换需谨慎），仅令外观协调；若转换则同步改 finder。
- **新增/编辑自定义词**：5 个 `TextFormField` 被 `find.byType(TextFormField)` 访问——**必须保留 `TextFormField`**（仅容器/按钮换组件）。
- **自定义词详情**：知识块 `WordKnowledgeSections` 由 `find.text('近义 / 反义')` 等展开——**保留 `WordKnowledgeSections` 实现**。"标记已记住" `FilledButton.icon`/"稍后复习" `OutlinedButton.icon` 经 grep 无类型耦合（按文案）→ 可转 `AppPrimaryButton`/`AppSecondaryButton`。
- **训练场 2 屏**：grep 确认无 `widgetWithText(FilledButton/OutlinedButton, ...)` 训练按钮耦合（测试仅 `find.text`）→ 按钮可自由转换；MCQ `_ChoiceAnswerButton`（OutlinedButton）→ 迁移 `WordChoiceButton` 或保留 token 化；`TextField`（拼写输入）保留。
- 通则：转任何按钮前先 `grep -n "widgetWithText(FilledButton\|widgetWithText(OutlinedButton\|byType(FilledButton\|byType(OutlinedButton\|byType(TextFormField" test/widget_test.dart` 比对该按钮文案。

---

## File Structure

- `lib/features/training/training_screen.dart` — 修改。
- `lib/features/training/training_session_screen.dart` — 修改。
- `lib/features/wordbook/wordbook_screen.dart` — 修改。
- `lib/features/wordbook/target_word_detail_screen.dart` — 修改。
- `lib/features/wordbook/custom_word_list_screen.dart` — 修改。
- `lib/features/wordbook/add_edit_custom_word_screen.dart` — 修改。
- `lib/features/wordbook/word_detail_screen.dart` — 修改。
- `test/widget_test.dart` — 修改：结构断言 + 必要时同步耦合 finder。
- 不改 `data/`、`core/state/`、`core/routing/`、`l10n/`、`server/`、`core/widgets/` 实现、`word_knowledge_sections.dart` 逻辑。

---

## Task 1: 训练场 Hub（training_screen）

**保留数据：** `ref.watch(appControllerProvider)` → `state.user`(xp/streak)、`state.currentWordBook`、`state.currentStudyBook.name`、`state.lessons.where((l)=>l.isTrainingPack)`。
**保留导航：** Campus Speed → `context.push('/timed-test/${speedLesson.id}')`；Word Rush → `/training/word-rush`；Survival → `/training/survival`；Spelling → `/training/spelling`。
**保留 l10n：** searchCurrentPlan、trainingDailyXpAvailable、trainingWeeklyXpPrefix、homeStreakLabel、trainingTimedTests、trainingCampusSpeed、trainingSpeedGame(Desc)、trainingSpecialDrills(Subtitle)、trainingSurvivor(Desc)、trainingSpelling(Desc)、trainingPassageCloze(Desc)、trainingListening(Desc)、trainingDueWords、trainingWeakWords、trainingComboTarget、trainingComingSoon（以现状为准）。
**映射：** `_TrainingGoalHeader`/`_TrainingGameRow`/`_TrainingReadinessLine` 的 `QuestPanel` → `AppCard`（游戏行用 `AppCard(onTap:)`）；`StatusBadge` → `AppPill`（锁定→中性/streak，连击→streak）；`PillLabel` → `AppPill`；`StatTile`/`SectionHeader`/`IconCueBadge` 保留。锁定游戏（Passage/Listening）保持不可点（`onTap: null`）+ `trainingComingSoon` 语义。

- [ ] **Step 1: 写失败测试**：在一个进入 `/training` 的测试（grep `find.text('训练场')` 或 tab 切换 `main shell supports deliberate horizontal tab swiping` 进入 training tab）后追加 `expect(find.byType(AppCard), findsWidgets);`。若无干净落点，退化为 analyze+全量 suite+清单核对（说明）。
- [ ] **Step 2: 跑确认失败**（或记录退化路径）。
- [ ] **Step 3: 实现**：改写 `training_screen.dart`（`_TrainingGoalHeader`、`_TrainingGameList`、`_TrainingGameRow`、`_TrainingReadinessLine`）。逐条对照保留清单。移除未用 import，`dart format`。
- [ ] **Step 4: 回归**：目标测试（如有）red→green；`flutter test` 全绿；`flutter analyze` 干净。
- [ ] **Step 5: 提交**：`git add lib/features/training/training_screen.dart test/widget_test.dart` → `git commit -m "feat(training): reskin training hub with Cozy Quest components"`。

---

## Task 2: 训练会话（training_session）

**保留数据/状态：** `ref.watch(appControllerProvider)` 用于 `_ensureQuestions()`：`state.lastResult?.mistakes`、`state.weakWords`、`state.dueWords`、`state.formalLessons`、`state.completedLessonIds`、`state.trainingWords`。本地状态全部保留（`_questions/_mistakes/_records/_index/_correct/_streak/_bestStreak/_remainingSeconds/_revives/_nodeRewards/_timer/_game/_checked/_lastCorrect/_selected` 等）与全部方法（`_ensureQuestions`/`_initialize`/计时/`_handlePrimary` 等）。
**保留 notifier/导航：** `ref.read(appControllerProvider.notifier).completeTraining(result:, gameId:, startedAt:, exerciseRecords:)`；返回 → `context.go('/training')`；完成 → `context.go('/lesson/${game.id}/result', extra: LessonResultViewArgs(result:, source: LessonResultSource.training))`；退出对话框保留。
**保留 l10n：** 全部 training* key（39 个，以现状为准，不增删）。
**映射：** `_TrainingStatusLine` `LinearProgressIndicator` → `AppProgressBar`（除非类型耦合）、5 个 `PillLabel` → `AppPill`；`_TrainingPromptPanel` 容器 → `AppCard`、`PillLabel` → `AppPill`、`ImageCueBadge`/`PronunciationControls` 保留；`_ChoiceAnswerButton`（OutlinedButton）→ `WordChoiceButton`（状态映射 idle/selected/correct/wrong，保留终态不可点）或保留 token 化；`_SpellingInput` `TextField` 保留；`_TrainingFeedback` 容器 → `AppCard`（success/streak 语义）；提交/下一题 `FilledButton.icon` → `AppPrimaryButton`（底部栏注意 `IntrinsicHeight` 坑）。

- [ ] **Step 1: 写失败测试**：训练会话由 `/training/:game` 进入；既有训练测试多为状态断言。若有测试停留于会话屏可加 `expect(find.byType(AppCard), findsWidgets);`，否则退化为 analyze+全量 suite+清单核对（说明）。先 grep 训练按钮耦合（预期无）。
- [ ] **Step 2: 跑确认失败/状态**。
- [ ] **Step 3: 实现**：改写各 inline widget；保留全部会话/计时逻辑与 MCQ 状态语义。`dart format`，移除未用 import。
- [ ] **Step 4: 回归**：`flutter test` 全绿（含 `timed test result returns to training instead of learning path`、`training completion does not unlock formal new-learning reward`）；`flutter analyze` 干净。
- [ ] **Step 5: 提交**：`git add lib/features/training/training_session_screen.dart test/widget_test.dart` → `git commit -m "feat(training): reskin training session with Cozy Quest components"`。

---

## Task 3: 词书总览（wordbook_screen）

**保留数据/notifier：** `state.formalLessons`、`state.currentWordBook`、`state.currentStudyBook`、`state.wordBooks`、`state.completedLearningWords`、`state.learningPathProgress`；切换书 → `ref.read(appControllerProvider.notifier).switchWordBook(bookId)`（snackbar `wordbookSwitched`/`wordbookSwitchFailed`）。
**保留导航：** 加卡 → `context.push('/custom-words')`；调整计划 → `context.push('/settings/study-plan')`；目标词 → `context.push('/wordbook/${word.id}')`；返回 fallback `/home`。
**保留 l10n：** wordbookTitle、wordbookImageBook、wordbookCustomTooltip、wordbookTargetWords、wordbookBookCount、wordbookCompletion、wordbookSwitch(Desc)、wordbookSwitched、wordbookSwitchFailed、wordbookTargetSection、wordbookTargetDesc、wordbookWordsLearned、wordbookTotalWords。
**映射：** `_StudyBookHero` `BrandHeroCard` → 保留或换 `AppCard` 英雄区（`ProgressRing` 保留）；`_WordBookSwitcher` `SegmentedTabs` 保留、其内 `QuestPanel` → `AppCard`；`_TargetWordRow` `QuestListRow` 保留或换 `AppCard` 行；`PillLabel` → `AppPill`；`StatusBadge` → `AppPill`；`SectionHeader`/`QuestIconButton` 保留。

- [ ] **Step 1: 写失败测试**：`home and wordbook tolerate empty lesson words and tags` 进入 wordbook——加 `expect(find.byType(AppCard), findsWidgets);`（确认该测试渲染 wordbook；否则退化）。
- [ ] **Step 2: 跑确认失败**。
- [ ] **Step 3: 实现**。`dart format`。
- [ ] **Step 4: 回归**：全绿 + analyze 干净。
- [ ] **Step 5: 提交**：`git commit -m "feat(wordbook): reskin wordbook overview with Cozy Quest components"`。

---

## Task 4: 目标词详情（target_word_detail_screen）

**保留数据/notifier：** `state.userWords`、`state.customWords`、`state.currentWordBook`、`state.wordBooks`、`state.formalLessons`、`state.errorMessage`；`updateTargetWordFlags(targetWord, wordBookId:, isFavorite?/isInNewWordbook?/isIgnored?)`、`addCustomWord(word:,meaning:,exampleSentence:,note:,tag:,difficulty:)`、`deleteCustomWord(id)`。保留 收藏/加入移出/忽略 三套流程与全部 snackbar。
**保留 l10n：** 全部 wordbook* 详情 key（17+，以现状为准）。
**保留导航：** 返回 fallback `/wordbook`。
**按钮策略（关键）：** 底部"加入生词本/移出生词本" `FilledButton.icon` 被类型耦合（test 2704/2709/2711）。**保留 `FilledButton.icon` 类型**，仅令外观与 Cozy Quest 协调（或转 `AppPrimaryButton` 并同步改这 3 处 finder——优先保留类型，风险更低）。收藏/忽略 `OutlinedButton.icon` → `AppSecondaryButton`（grep 确认无类型耦合）。
**映射：** `_WordHero`/`_DefinitionSections`/`_ExampleSections` 的 `QuestPanel` → `AppCard`；`PillLabel` → `AppPill`；`ImageCueBadge`/`PronunciationControls`/`AiWordSupportLink`/`WordKnowledgeSections` 保留；`StatusBadge` → `AppPill`。

- [ ] **Step 1: 写失败测试**：在 `target word detail can add the searched word to custom cards` 到达详情屏处加 `expect(find.byType(AppCard), findsWidgets);`（不改其 FilledButton finder——保留类型）。
- [ ] **Step 2: 跑确认失败**。
- [ ] **Step 3: 实现**（保留底部 FilledButton 类型）。`dart format`。
- [ ] **Step 4: 回归**：全绿（含 `target word detail can add the searched word to custom cards`）+ analyze 干净。
- [ ] **Step 5: 提交**：`git commit -m "feat(wordbook): reskin target word detail with Cozy Quest components"`。

---

## Task 5: 自定义词列表（custom_word_list_screen）

**保留数据/notifier：** `state.customWords`、`state.errorMessage`；删除 → 确认对话框 → `deleteCustomWord(word.id)`（snackbar `customWordsDeleted`/`customWordsDeleteFailed`）。本地 `_query`/`_filter`。
**保留导航：** FAB/空态 → `context.push('/custom-words/new')`；词条 → `context.push('/custom-words/${word.id}')`；返回 fallback `/wordbook`。
**保留 l10n：** commonCustomWords、commonAdd、customWordsMyCards(Subtitle)、customWordsCardCount、customWordsSearchLabel、customWordsNoMatchTitle/Message、customWordsAddCard、customWordsDeleteTitle/Content、commonCancel、commonDelete、customWordsDeleted、customWordsDeleteFailed。
**映射：** 空态 `EmptyState` → `MascotEmptyState(title: customWordsNoMatchTitle, message: customWordsNoMatchMessage, action: <加卡按钮 push '/custom-words/new'>)`；`_CustomWordTile` 容器 → `AppCard`（其 `LinearProgressIndicator` 掌握度 → `AppProgressBar(value: masteryLevel/5)`）；`PillLabel` → `AppPill`；`FilterPillButton`（搜索/筛选）保留；搜索 `TextField` 保留；`ImageCueBadge`/`QuestIconButton`/`SectionHeader` 保留；FAB 保留（或维持 FloatingActionButton）。

- [ ] **Step 1: 写失败测试/守卫**：该屏经 `/custom-words` 进入。若有测试停留可加 `expect(find.byType(AppCard), findsWidgets);`，否则退化为 analyze+全量 suite+清单核对（说明）。
- [ ] **Step 2: 跑确认失败/状态**。
- [ ] **Step 3: 实现**。`dart format`。
- [ ] **Step 4: 回归**：全绿 + analyze 干净。
- [ ] **Step 5: 提交**：`git commit -m "feat(wordbook): reskin custom word list with Cozy Quest components"`。

---

## Task 6: 新增/编辑自定义词（add_edit_custom_word_screen）

**保留数据/notifier：** `state.customWords`（编辑查找）；`addCustomWord(...)`/`updateCustomWord(CustomWord)`（trim 逻辑、tag 默认 '自定义'、snackbar `customWordsSaved`/`customWordsSaveFailed`）。本地 5 个 controller + `_difficulty` + `_formKey` + `_hydrated`。
**保留导航：** 返回 fallback `/custom-words`；保存成功 → `context.go('/custom-words')`。
**保留 l10n：** customWordsEditTitle/AddTitle、customWordsFieldWord/Meaning/Example/Note/Tag、customWordsDifficulty、customWordsSaveEdit/Create、commonRequired、customWordsSaved/SaveFailed。
**按钮/输入策略：** **5 个 `TextFormField` 必须保留**（`find.byType(TextFormField)` 耦合）+ 校验逻辑不变。`_DifficultySelector`（`FilterPillButton`）保留。保存 `FilledButton.icon` → `AppPrimaryButton`（grep 确认无类型耦合；表单底部按钮注意 `IntrinsicHeight`/stretch）。
**映射：** 仅按钮 + 可能的分组容器换 Cozy Quest；表单字段不动。整体可包一层 `AppCard` 或保持简洁表单。

- [ ] **Step 1: 写失败/守卫测试**：该屏由 `/custom-words/new`、`/custom-words/:id/edit` 进入。既有测试经 `find.byType(TextFormField)` 操作（如 `target word detail ...` 流可能不经此屏；`custom word ...` 流）。优先退化为 analyze+全量 suite+清单核对（保留 TextFormField 是关键），说明路径。
- [ ] **Step 2: 跑确认状态**。
- [ ] **Step 3: 实现**（保留全部 TextFormField + 校验）。`dart format`。
- [ ] **Step 4: 回归**：全绿（含任何 `find.byType(TextFormField)` 测试）+ analyze 干净。
- [ ] **Step 5: 提交**：`git commit -m "feat(wordbook): reskin add/edit custom word with Cozy Quest components"`。

---

## Task 7: 自定义词详情（word_detail_screen）

**保留数据/notifier：** `state.isLoading`、`state.customWords`、`state.errorMessage`；`reviewWord(id, isCorrect, dimension:, answerTimeMs:, confidence:, wrongOption:)`；仅当 `word.isDue(now) && !isLoading` 可点。snackbar `wordDetailMarkedRemembered`/`wordDetailScheduledSoon`/`wordDetailUpdateFailed`。
**保留导航：** 返回 fallback `/custom-words`；编辑 → `context.push('/custom-words/${word.id}/edit')`。
**保留 l10n：** wordDetailNotFound、commonEdit、wordDetailMasteryLabel、wordDetailNextReview、wordDetailReviewStats、wordDetailStatRemembered/Forgot/Mastery、wordDetailMarkRemembered、wordDetailScheduleSoon、wordDetailMarkedRemembered/ScheduledSoon/UpdateFailed。
**按钮策略：** "标记已记住" `FilledButton.icon` → `AppPrimaryButton`；"稍后复习" `OutlinedButton.icon` → `AppSecondaryButton`（grep 确认无类型耦合，预期无）。保留 enabled 条件。
**映射：** `QuestPanel`（hero / stats）→ `AppCard`；`PillLabel` → `AppPill`；`ImageCueBadge`/`PronunciationControls`/`AiWordSupportLink`/`WordKnowledgeSections.custom` 保留（知识块展开被 `find.text('近义 / 反义')` 耦合——**不改其实现**）；`_StatLine` 保留或微调。

- [ ] **Step 1: 写失败测试**：在 `custom word detail shows the full knowledge blocks` 到达详情屏处加 `expect(find.byType(AppCard), findsWidgets);`（不改其知识块 `find.text` 断言）。
- [ ] **Step 2: 跑确认失败**。
- [ ] **Step 3: 实现**。`dart format`。
- [ ] **Step 4: 回归**：全绿（含 `custom word detail shows the full knowledge blocks`）+ analyze 干净。
- [ ] **Step 5: 提交**：`git commit -m "feat(wordbook): reskin custom word detail with Cozy Quest components"`。

---

## Task 8: 训练场 & 词书整体验收

- [ ] **Step 1: 全量分析** `flutter analyze` → `No issues found!`
- [ ] **Step 2: 全量测试** `flutter test` → All tests passed!
- [ ] **Step 3: 残留核查** `grep -ln "QuestPanel" lib/features/training/*.dart lib/features/wordbook/*.dart` → 期望无输出（`word_knowledge_sections.dart` 若用 QuestPanel 可保留——它是知识块实现，不在本计划映射范围；若它用了则本步排除该文件并在报告说明）。
- [ ] **Step 4: 提交（如有修订）** `git commit -m "chore(ui): finalize Cozy Quest migration for training and wordbook"`。

---

## Self-Review（作者自查）

**Spec 覆盖：** §2 原则贯穿 7 屏；§6 组件全面落地；§7 吉祥物经 `MascotEmptyState`（自定义词空态）贯穿；§9 弃用 `QuestPanel`（本批 7 屏，`word_knowledge_sections` 除外）。
**占位符扫描：** 无 TBD；按钮策略对每类耦合给出明确决策（保留 FilledButton 类型 / 保留 TextFormField / 可转 + 同步 finder）；测试落点不可达给退化守卫。
**类型一致性：** 复用 Plan 1-3 组件 + 既有 `WordChoiceButton`/`SegmentedTabs`/`FilterPillButton`/`ProgressRing`/`PronunciationControls`/`WordKnowledgeSections`/`TextFormField`（不改实现）。
**范围：** 仅 7 屏视觉层 + `test/widget_test.dart`；不碰 data/state/routing/l10n/server/core-widgets 实现。

## 后续计划

- **Plan 5 — 发现/任务中心/班级/排行/分析/AI**：discover hub、xp-tasks、lucky-draw、community、ai-learning、leaderboard、progress、class-mode、class-progress、ai-tutor。
- **Plan 6 — 设置 + 入门/认证 + 杂项 + 清理**：settings 全系、help、about、notifications、search、splash、onboarding、login、register、goal-setup；并清理已无引用的旧 `QuestPanel` 等原语。
