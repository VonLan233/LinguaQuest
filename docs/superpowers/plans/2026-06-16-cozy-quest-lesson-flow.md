# Cozy Quest 课程流重塑 Implementation Plan（Plan 3 / 5）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把课程/学习交互流的 4 个屏幕（课程预习、答题会话、课程结算、混合学习会话）的**视觉层**迁移到 Cozy Quest 组件库与暖瓷白 token；保留全部数据接线、交互机制、导航与可见文案，使既有集成测试 `test/widget_test.dart`（含 `quiz feedback stays visible`、`new word cards confirm before leaving after progress`、`lesson and quiz screens expose a working back path`、`lesson mistake appears in review center after result` 等）持续通过。

**Architecture:** 视觉迁移，非功能重写。这些是**交互最重、测试最脆弱**的屏幕，按钮与测试存在**类型耦合**，必须按下方「按钮策略」精确处理。容器 `QuestPanel`→`AppCard`、徽章 `PillLabel`→`AppPill`、空状态 `EmptyState`→`MascotEmptyState`；交互控件（答题选项 `WordChoiceButton`、信心选项、recall）按耦合规则保留或受控替换。每屏迁移后跑全量 `flutter test` 回归。

**Tech Stack:** Flutter / Dart 3、Material 3、flutter_test、Riverpod、GoRouter。

**对应 spec:** `docs/superpowers/specs/2026-06-16-ui-redesign-cozy-quest-design.md`（§2 原则、§6 组件、§7 吉祥物、§9 保留/弃用）。沿用 Plan 2 沉淀的组件约定（见记忆 cozy-quest-component-conventions）。

**前置:** 分支 `feat/ui-friendly-quest-reskin`，Plan 1 组件 + Plan 2 四屏已合入。命令在 `linguaquest/` 下执行。提交**原子化、无 `Co-Authored-By` trailer**；**显式 stage 文件，禁止 `git add -A`**（避免扫入 `.DS_Store`）。

---

## 不可破坏的安全网（每个任务都适用）

与 Plan 2 相同：① 既有集成测试保持绿色（行为/文案/导航回归守卫）；② 保留 l10n（不硬编码、不新增 .arb key）；③ 保留数据选择器与 notifier 调用；④ 保留导航路由；⑤ 风格纪律（spec §2，卡片单层柔影、彩色仅用于有意义处）；⑥ `flutter analyze` 必须 `No issues found!`。每屏迁移后 `dart format` 该文件。

## 按钮策略（关键 — 类型耦合）

- **答题/学习主行动按钮（检查/继续/重试，`commonCheck`/`commonContinue`/`commonRetry` 或 `quizCheck`/`quizContinue`/`quizRetry`）**：当前 `FilledButton.icon`，动态切换 label+icon。转 `AppPrimaryButton(label: ..., icon: ..., onPressed: ...)`。**必须同步**把 `test/widget_test.dart` 中 `find.widgetWithText(FilledButton, '继续')`（约 1751、1830 行，quiz 流）改为 `find.widgetWithText(AppPrimaryButton, '继续')`。所有 `find.text('检查')`/`find.text('继续')`（非类型耦合）保持可用（AppPrimaryButton 内含 Text）。
- **预习信心选项 `_ConfidenceOption`（`OutlinedButton.icon`，带选中态 + 图标）**：被 `find.widgetWithText(OutlinedButton, '认识')`（约 1866、4153 行）耦合。它是**选择控件而非 CTA**——**保留 `OutlinedButton.icon` 类型**，仅把颜色/描边改为 `AppTokens`（teal/mango/coral → `AppTokens.azure`/`AppTokens.mango`/`AppTokens.coral`，选中态 `AppTokens.primarySoft` 等）。不要换成 `AppSecondaryButton`/`AppPrimaryButton`（会丢图标/选中态并破坏 finder）。
- **MCQ 选项**：测试 helper `_tapOption` 先找 `WordChoiceButton` 再回退 `OutlinedButton`。答题屏已用 `WordChoiceButton`——**保留**。混合学习屏当前用裸 `OutlinedButton` 选项——可保留或迁移到 `WordChoiceButton`（helper 两者皆支持）；若迁移，token 化由 `WordChoiceButton` 内部保证。
- **混合学习知识卡信心 `SegmentedButton<int>`**：无类型耦合测试。可保留（token 化）或替换为 `RecallButtons`（核心组件，三色按钮）；若替换须保留 `studyRecallKnown/Fuzzy/Unknown` 文案与 1/3/5 信心映射语义。优先**保留 SegmentedButton** 以最小化风险（仅在 spec §2 角度收敛配色）。
- **结算/退出对话框按钮**：纯导航/动作，若无类型耦合测试可转 `AppPrimaryButton`/`AppSecondaryButton`；转前 grep 确认无 `widgetWithText(FilledButton/OutlinedButton, '<该按钮文案>')`。

> 通则：转任何按钮前，先 `grep -n "widgetWithText(FilledButton\|widgetWithText(OutlinedButton\|byType(FilledButton\|byType(OutlinedButton" test/widget_test.dart` 并比对该按钮文案；有耦合则同步改 finder 或保留类型。

---

## File Structure

- `lib/features/learning/lesson_preview_screen.dart` — 修改。
- `lib/features/quiz/quiz_session_screen.dart` — 修改。
- `lib/features/quiz/lesson_result_screen.dart` — 修改。
- `lib/features/study/mixed_study_session_screen.dart` — 修改。
- `test/widget_test.dart` — 修改：追加结构断言；同步被类型耦合的 finder（如 quiz 主按钮）。
- 不改 `data/`、`core/state/`、`core/routing/`、`l10n/`、`server/`、`core/widgets/`（`WordChoiceButton`/`RecallButtons`/`PronunciationControls` 复用，不改其实现）。

---

## Task 1: 课程预习屏（lesson_preview）重塑

**Files:** Modify `lib/features/learning/lesson_preview_screen.dart`、`test/widget_test.dart`。

**保留数据/状态：** `ref.watch(appControllerProvider).formalLessons` + 按 `widget.lessonId` 查找；本地 `_confidenceByWordId: Map<String,String>`、`_wordIndex: int`。Word 字段：image/word/phonetic/partOfSpeech/difficulty/meaning/definition/exampleSentence/exampleTranslation/imageCue。

**保留导航：** 最后一张且已选信心 → `context.push('/lesson/${widget.lessonId}/quiz')`；返回确认对话框 fallback → `/study/new`。

**保留 l10n key：** lessonPreviewTitle、lessonPreviewProgressMeta、lessonPreviewNoCards、lessonPreviewNoCardsBody、lessonPreviewAssessFirst、studyRecallKnown、studyRecallFuzzy、studyRecallUnknown、lessonPreviewLessonCards、lessonPreviewCardMeta、lessonPreviewContextExample、lessonPreviewPrevious、lessonPreviewNextCard、lessonPreviewEnterContext、lessonPreviewLeaveCardTitle、lessonPreviewLeaveCardContent、mixedContinueStudy、lessonPreviewLeave。

**按钮策略：** 信心选项 `_ConfidenceOption` 保留 `OutlinedButton.icon`（仅 token 化，见上）。底部「上一张」`OutlinedButton`、「下一张/进入语境」`FilledButton` —— 先 grep 确认 `lessonPreviewPrevious`/`lessonPreviewNextCard`/`lessonPreviewEnterContext` 的 zh 文案是否被 `widgetWithText(FilledButton/OutlinedButton, ...)` 耦合：若**无**耦合，可转 `AppSecondaryButton`（上一张）/`AppPrimaryButton`（下一张）；若**有**，保留类型并 token 化，或同步改 finder。

**组件映射：** `_WordStudyCard` 的 `QuestPanel` → `AppCard`；`_ContextSection` 的 `QuestPanel` → `AppCard`；`PillLabel`（partOfSpeech/difficulty）→ `AppPill`（中性/语义）；`ImageCueBadge` 保留；`PronunciationControls` 保留；空卡状态（lessonPreviewNoCards/Body）→ `MascotEmptyState`。`_MiniWordRow` 列表项容器收敛为轻量行（当前态高亮用 `AppTokens.primarySoft`）。顶部进度 `LinearProgressIndicator` → `AppProgressBar(value: (currentIndex+1)/words.length)`（除非被测试断言为 `LinearProgressIndicator` 类型——先 grep `LinearProgressIndicator` 于该 test 流；若被断言则保留）。

- [ ] **Step 1: 写失败测试**

先 `grep -n "widgetWithText(\(FilledButton\|OutlinedButton\)" test/widget_test.dart` 与 `grep -n "LinearProgressIndicator\|认识\|开始学习\|进入语境\|下一张\|上一张" test/widget_test.dart`，记录预习流的类型耦合点（已知：`OutlinedButton, '认识'` @1866/4153）。
在 `test/widget_test.dart` 的 `new word cards confirm before leaving after progress`（停留于预习屏）断言区追加：
```dart
    expect(find.byType(AppCard), findsWidgets);
```
（`app_card.dart` 已 import。）

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/widget_test.dart --name "new word cards confirm before leaving after progress"`
Expected: FAIL（预习屏尚无 `AppCard`）。

- [ ] **Step 3: 实现迁移**

按映射改写 `lesson_preview_screen.dart`（`build`、`_WordStudyCard`、`_ConfidenceSelector`、`_ConfidenceOption`、`_ContextSection`、`_MiniWordRow`），逐条对照保留清单与按钮策略。`_ConfidenceOption` 保留 OutlinedButton 类型。移除未用 import，`dart format` 该文件。

- [ ] **Step 4: 红→绿 + 全量回归**

Run: `flutter test test/widget_test.dart --name "new word cards confirm before leaving after progress"` → PASS。
Run: `flutter test` → All tests passed!（含 `lesson preview does not open training-only timed packs`、`lesson and quiz screens expose a working back path`、`regular quiz cannot open training-only timed packs`。）
Run: `flutter analyze` → `No issues found!`
若某 finder 因按钮类型变更失败：要么恢复类型，要么同步改 finder（在 commit 说明）。

- [ ] **Step 5: 提交**

```bash
git add lib/features/learning/lesson_preview_screen.dart test/widget_test.dart
git commit -m "feat(learning): reskin lesson preview with Cozy Quest components"
```

---

## Task 2: 答题会话屏（quiz_session）重塑

**Files:** Modify `lib/features/quiz/quiz_session_screen.dart`、`test/widget_test.dart`。

**保留数据/状态：** `appControllerProvider.select((s) => isTimed ? s.lessons : s.formalLessons)` + 按 lessonId 查找；`question = lesson.questions[_index]`、`progress = (_index+1)/lesson.questions.length`；`QuizQuestion.{type,prompt,answer,options,explanation,word}`；本地 `_textController/_mistakes/_mistakeQuestionIds/_index/_correct/_selected/_checked/_lastCorrect/_isSubmitting/_feedbackReady/_feedbackHoldToken`。答案判定 `answer?.toLowerCase() == question.answer.toLowerCase()`。

**保留 notifier/导航：** `ref.read(appControllerProvider.notifier).completeLesson(result, isTrainingChallenge: mode==timed)`；完成 → `context.go('/lesson/${lesson.id}/result', extra: LessonResultViewArgs(result: result, source: mode==timed ? LessonResultSource.timed : LessonResultSource.lesson))`；退出对话框语义保留。`LessonResult(...)` 构造字段保留。

**保留 l10n key：** quizNoLesson、quizNoQuestions、quizTimedTest、quizCampusSpeed、quizInputWord、quizCheck、quizContinue、quizRetry、quizCorrect、quizWrong、quizReinforce、quizLeaveTitle、quizLeaveContent、quizKeepAnswering、commonLeave（及实际使用到的全部 quiz* key——以代码现状为准，不增删）。

**按钮策略（关键）：** 主行动按钮（检查/继续/重试）`FilledButton.icon` → `AppPrimaryButton`，**同步改** `test/widget_test.dart` 中 `find.widgetWithText(FilledButton, '继续')`（quiz 流，约 1751/1830）→ `find.widgetWithText(AppPrimaryButton, '继续')`。MCQ 选项 `WordChoiceButton` **保留**。拼写题 `TextField` 保留（输入语义）。`_QuestionInput` 的选项状态映射（idle/selected/correct/wrong）保留。

**组件映射：** `_QuestionPromptPanel` 容器 → `AppCard`；其 `PillLabel`（题型/词性/难度）→ `AppPill`；`_FeedbackPanel` 容器 → `AppCard`（正确 success 语义浅底、错误 streak 语义浅底，文案/图标保留）；顶部进度 `LinearProgressIndicator` → `AppProgressBar(value: progress)`（除非测试按类型断言——先 grep）；计数 pill / 计时 pill → `AppPill`；`ImageCueBadge`/`PronunciationControls` 保留。

- [ ] **Step 1: 写失败测试 + 同步 finder**

grep 记录 quiz 按钮耦合（已知 `widgetWithText(FilledButton, '继续')` @~1751/1830）。在 `quiz feedback stays visible before continuing` 断言区追加：
```dart
    expect(find.byType(AppCard), findsWidgets);
```
并把该测试文件中 quiz 流的 `find.widgetWithText(FilledButton, '继续')` 两处改为 `find.widgetWithText(AppPrimaryButton, '继续')`（确认这两处属 quiz 流而非其它）。

- [ ] **Step 2: 跑测试确认失败**

Run: `flutter test test/widget_test.dart --name "quiz feedback stays visible before continuing"`
Expected: FAIL（无 `AppCard`；或 finder 暂未匹配——实现后转绿）。

- [ ] **Step 3: 实现迁移**

按映射改写 `quiz_session_screen.dart`（`build`、`_QuestionPromptPanel`、`_QuestionInput`、`_FeedbackPanel`）。主按钮转 `AppPrimaryButton`，保留动态 label（quizCheck/quizContinue/quizRetry）与 icon、`_handlePrimary` 逻辑、反馈延时 `_holdFeedback`。`WordChoiceButton`/`TextField` 保留。移除未用 import，`dart format`。

- [ ] **Step 4: 红→绿 + 全量回归**

Run: `flutter test test/widget_test.dart --name "quiz feedback stays visible before continuing"` → PASS。
Run: `flutter test` → All tests passed!（含 `lesson mistake appears in review center after result`、`lesson and quiz screens expose a working back path`、`regular quiz cannot open training-only timed packs`、`discover ...` 涉及完成课程的测试。）
Run: `flutter analyze` → `No issues found!`

- [ ] **Step 5: 提交**

```bash
git add lib/features/quiz/quiz_session_screen.dart test/widget_test.dart
git commit -m "feat(quiz): reskin quiz session with Cozy Quest components"
```

---

## Task 3: 课程结算屏（lesson_result）重塑

**Files:** Modify `lib/features/quiz/lesson_result_screen.dart`、（如需）`test/widget_test.dart`。

**保留数据：** `ref.watch(appControllerProvider)` → `state.lastResult`、`state.user?.xp`；`LessonResultViewArgs{result, source}`、`expectedLessonId`；结果解析 `result ?? ((expectedLessonId==null || lastResult?.lessonId==expectedLessonId) ? lastResult : null)`；`LessonResult.{lessonId,lessonTitle,totalQuestions,correctAnswers,xpEarned,mistakes,accuracy}`。

**保留导航：** 重做错题（training 且有错）→ `/training/spelling?source=mistakes`；去复习中心 → `/review`；返回 → `isTraining ? '/training' : '/learn'`；XP 用途链接 → `/discover`。

**保留 l10n key：** quizResultTitle、quizTimedResultTitle、quizGreatJob、quizLessonDone、quizChallengeSuccess、quizChallengeDone、quizMistakeReview、quizMistakeTimed、quizAccuracy、quizMistakes、quizAllCorrect、quizXpCredited、quizXpImpactBody、quizCurrentXp、quizXpBalanceUpdated、quizXpEarned、quizTotalXp、quizMistakeCount、quizTimedReward、quizLessonReward、quizViewXpUses、quizRetryMistakes、quizGoReviewCenter、quizBackLearningPath、quizBackTraining（以代码现状为准）。

**按钮策略：** `_ResultActions` 的 FilledButton/OutlinedButton 为导航动作。先 grep 这些按钮文案是否被类型耦合（`quizGoReviewCenter`/`quizBackLearningPath` 等的 zh 文案）；无耦合 → 去复习中心/重做错题转 `AppPrimaryButton`，返回转 `AppSecondaryButton`；有耦合 → 保留类型 + token 化或同步改 finder。

**组件映射：** `_ResultScoreSummary` 的 `QuestPanel` → `AppCard`（大号正确率数字保留；`LinearProgressIndicator` → `AppProgressBar(value: accuracy)`，除非类型耦合）；XP/总XP/错题数 `PillLabel` → `AppPill`（xp/primary/streak 语义）；`_XpImpactNotice` 容器 → `AppCard`（mango/xp 语义浅底）；`_PerfectResultRow` 满分行 → 可用 `MascotImage` 或保留 emoji 徽章（吉祥物贯穿，spec §7）；`_MistakeResultRow` → `AppCard` 列表项；`SectionHeader` 保留。

- [ ] **Step 1: 写失败/守卫测试**

grep 结算屏按钮耦合。`lesson and quiz screens expose a working back path` 经过结算屏返回——在其到达结算屏处追加 `expect(find.byType(AppCard), findsWidgets);`（若该测试确实渲染结算屏；否则用 `lesson mistake appears in review center after result` 路径，或退化为 analyze+全量 suite+清单核对，说明所选路径）。

- [ ] **Step 2: 跑测试确认失败/状态**（按所选路径）

- [ ] **Step 3: 实现迁移**

按映射改写 `lesson_result_screen.dart`（`build`、`_ResultScoreSummary`、`_XpImpactNotice`、`_PerfectResultRow`、`_MistakeResultRow`、`_ResultActions`）。逐条对照保留清单。`dart format`，移除未用 import。

- [ ] **Step 4: 全量回归**

Run: `flutter test` → All tests passed!
Run: `flutter analyze` → `No issues found!`
（若加了结构断言，先 red→green。）

- [ ] **Step 5: 提交**

```bash
git add lib/features/quiz/lesson_result_screen.dart test/widget_test.dart
git commit -m "feat(quiz): reskin lesson result with Cozy Quest components"
```

---

## Task 4: 混合学习会话屏（mixed_study_session）重塑

**Files:** Modify `lib/features/study/mixed_study_session_screen.dart`、（如需）`test/widget_test.dart`。

**保留数据/状态：** `ref.read(appControllerProvider)` slices：`state.dailyNewTarget`、`state.currentLesson?.words`、`state.dueWords`、`state.weakWords`、`state.formalLessons`、`state.customWords`、`state.errorMessage`；本地 `_queue/_answerLogs/_selected/_checked/_lastCorrect/_confidence/_completedItems/_correctAnswers`。

**保留 notifier/导航：** `reviewWord(wordId, isCorrect, dimension: ReviewDimension.confidence, answerTimeMs: ..., confidence: _confidence, wrongOption: ...)`；`completeMixedStudySession(lessonId, totalQuestions, correctAnswers, mistakeWordIds, answerEvents, startedAt, endedAt, completeCurrentLesson, xpEarned)`；管理复习队列 → `context.push('/review')`；完成 → `context.go('/home')`；退出对话框 `_ExitAction.{continueStudy,save,discard}` 语义保留。

**保留 l10n key：** studyRecallKnown/Fuzzy/Unknown、mixedTitleNew/Review/Mixed、mixedManageReviewQueue、mixedReviewRatio、mixedSelfAssessHint、mixedEnterRecognition、mixedAddLaterRecall、mixedMeaningPrompt、mixedShortRecallPrompt、mixedStepRecognition/ShortRecall/DueReview/Knowledge、mixedReviewQuickAnswer、mixedFeedbackCorrect/Wrong/Retry、mixedCompleteTitle/Body、mixedNoContentTitle/Body、mixedSaveAndHome、mixedSaveProgressTitle/Body、mixedContinueStudy、mixedLeaveWithoutSaving、mixedSaveAndLeave、mixedSaveReviewFailed、mixedSaveStudyFailed、commonCheck/Continue/Retry。

**按钮策略：** `_QuestionStep` 主行动 `FilledButton.icon`（检查/继续/重试）→ `AppPrimaryButton`（先 grep 确认这些 zh 文案在混合流是否被 `widgetWithText(FilledButton, ...)` 耦合；已知 quiz 流耦合 @1751/1830，混合流若复用同文案需确认归属——若耦合则同步改对应 finder）。MCQ 选项裸 `OutlinedButton` → 迁移到 `WordChoiceButton`（helper 兼容）或保留 token 化。知识卡 `SegmentedButton<int>` 信心选择**保留**（token 化）。

**组件映射：** `_KnowledgeCardStep`/`_QuestionStep` 容器 → `AppCard`；`PillLabel`（比例/进度/步骤类型）→ `AppPill`；`ImageCueBadge` 保留；`_CompleteView` 的 `EmptyState` → `MascotEmptyState`（完成庆祝,吉祥物贯穿）；顶部进度 `LinearProgressIndicator` → `AppProgressBar`（除非类型耦合）。

- [ ] **Step 1: 写失败/守卫测试**

grep 混合流按钮耦合。混合学习经 `/study/new`、`/study/review` 进入；既有测试 `home new-study entry opens standalone new learning flow`、`home review entry opens standalone review flow` 会进入此屏。在其稳定后追加 `expect(find.byType(AppCard), findsWidgets);`（若停留于该屏；否则退化为 analyze+suite+清单核对并说明）。

- [ ] **Step 2: 跑测试确认失败/状态**（按所选路径）

- [ ] **Step 3: 实现迁移**

按映射改写 `mixed_study_session_screen.dart`（`_KnowledgeCardStep`、`_QuestionStep`、`_CompleteView`、进度/计数）。保留全部会话逻辑（`_initializeQueue`/`_applySelfAssessment`/`_handleQuestionPrimary`/`_persistReviewAttempt`/`_scheduleWrongRecycle`/`_saveSessionProgress`/`_handleExit`）。`dart format`，移除未用 import。

- [ ] **Step 4: 全量回归**

Run: `flutter test` → All tests passed!（含 `home new-study entry ...`、`home review entry ...`、`discover check-in only counts same-day study`、`discover weak cleanup ...`。）
Run: `flutter analyze` → `No issues found!`

- [ ] **Step 5: 提交**

```bash
git add lib/features/study/mixed_study_session_screen.dart test/widget_test.dart
git commit -m "feat(study): reskin mixed study session with Cozy Quest components"
```

---

## Task 5: 课程流整体验收

**Files:** 无新增（验收）。

- [ ] **Step 1: 全量分析**

Run: `flutter analyze` → `No issues found!`

- [ ] **Step 2: 全量测试**

Run: `flutter test` → All tests passed!

- [ ] **Step 3: 残留旧原语核查（本计划 4 屏）**

Run: `grep -ln "QuestPanel" lib/features/learning/lesson_preview_screen.dart lib/features/quiz/quiz_session_screen.dart lib/features/quiz/lesson_result_screen.dart lib/features/study/mixed_study_session_screen.dart`
Expected: 无输出。

- [ ] **Step 4: 提交（如有核查后修订）**

```bash
git add lib/features/learning/lesson_preview_screen.dart lib/features/quiz/quiz_session_screen.dart lib/features/quiz/lesson_result_screen.dart lib/features/study/mixed_study_session_screen.dart
git commit -m "chore(ui): finalize Cozy Quest migration for lesson flow"
```

---

## Self-Review（作者自查）

**Spec 覆盖：** §2 原则贯穿 4 屏；§6 组件（AppCard/AppPill/AppPrimaryButton/AppProgressBar/MascotEmptyState）落地；§7 吉祥物经 `MascotEmptyState`（预习空卡、混合完成）与可选 `MascotImage`（满分庆祝）贯穿；§9 弃用 `QuestPanel`（本批 4 屏）。

**占位符扫描：** 无 TBD。按钮策略对每类按钮给出明确的「保留类型 / 转换 + 同步 finder」决策规则；对测试落点不可达给出退化守卫（analyze + 全量 suite + 清单核对）。屏幕 body 以「保留清单 + 组件映射 + 按钮策略 + 集成测试安全网」为完整规格（大型交互屏视觉迁移的恰当粒度）。

**类型一致性：** 复用 Plan 1 组件（签名一致）+ 既有 `WordChoiceButton`/`RecallButtons`/`PronunciationControls`/`ImageCueBadge`/`SegmentedButton`/`TextField`（不改实现）。

**范围：** 仅 4 屏视觉层 + `test/widget_test.dart`（结构断言 + 被迫的 finder 同步）；不碰 data/state/routing/l10n/server/core-widgets 实现。

## 后续计划

- **Plan 4 — 训练场 & 词书**：训练场、训练小游戏、限时测试、词书总览/详情、自定义词 CRUD。
- **Plan 5 — 任务中心/发现/班级/排行/分析 + 设置 + 入门/认证 + 杂项**，并清理已无引用的旧 `QuestPanel` 等原语。
