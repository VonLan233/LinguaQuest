# Cozy Quest 设置/入门/认证/杂项 + 清理 Implementation Plan（Plan 6 / 6 · 收尾）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`).

**Goal:** 把剩余的设置/杂项/入门/认证屏幕（settings hub/theme/reminder、study-plan、help、about、notifications、search、mistake-book、splash、onboarding、login、register、goal-setup）的视觉层迁移到 Cozy Quest 组件库，并在全 App 不再引用后**删除旧原语** `QuestPanel`/`QuestListRow`/`StatusBadge`，使 `test/widget_test.dart` 持续通过。

**Architecture:** 视觉迁移 + 末端清理。沿用既有约定。这是**测试耦合最密集**的一批——study-plan（LinearProgressIndicator/TextFormField）、login/onboarding（FilledButton/OutlinedButton '登录' 类型耦合）、goal-setup（`_StableChoiceButton` 尺寸稳定 + ValueKey）、splash（route_outlined/'再试一次'/LinearProgressIndicator）。**逐屏精确保留**。

**Tech Stack:** Flutter / Dart 3、Material 3、flutter_test、Riverpod、GoRouter。

**前置:** Plans 1-5 已合入。命令在 `linguaquest/` 下。提交**原子化、无 `Co-Authored-By`**；**显式 stage 文件,禁止 `git add -A`**。

---

## 安全网（每任务适用）

① 既有集成测试绿色；② 保留 l10n（不增删 key）；③ 保留数据/notifier；④ 保留导航；⑤ 风格纪律；⑥ analyze 干净；⑦ 每屏 `dart format`。

## 关键测试耦合（全计划）

- **study-plan**:加载条 `find.byType(LinearProgressIndicator)`(`findsOneWidget`/`findsNWidgets(2)`)——**保留 `LinearProgressIndicator`,严禁换 `AppProgressBar`**;数字字段 `find.byType(TextFormField)` + `digitsOnly`——**保留 `TextFormField`**;保存按钮 `find.text('保存学习计划')`(按文案,可转 `AppPrimaryButton`,文案不变)。
- **login**:`find.widgetWithText(FilledButton, '登录')`(@~776)——转 `AppPrimaryButton` 须同步改该 finder;`find.byType(TextFormField).at(0/1)`——**保留 2 个 TextFormField**;`'欢迎回来'` 文案保留。
- **onboarding**:`find.widgetWithText(OutlinedButton, '登录')`(@~765)——转 `AppSecondaryButton` 须同步改该 finder;`'注册账号'` 文案、`Icons.route_outlined` 图标保留。
- **goal-setup**:`_StableChoiceButton`(`AnimatedContainer` 高 48)被 `tester.getSize(find.byKey(ValueKey('choice-IELTS')))` 断言**选中前后尺寸不变**——**保留选项卡为固定高 48 的结构 + 全部 `ValueKey('choice-...')`**,不要把选项卡换成 AppCard/AppPrimaryButton(尺寸会变)。
- **splash**:`find.text('再试一次')`(commonRetry)、`Icons.route_outlined`(onboarding)、加载 `LinearProgressIndicator`——保留类型。
- 通则:转任何按钮前 `grep -n "widgetWithText(FilledButton\|widgetWithText(OutlinedButton\|byType(LinearProgressIndicator\|byType(TextFormField\|byKey(const ValueKey('choice" test/widget_test.dart`。

---

## File Structure

- `lib/features/profile/settings_screen.dart`（SettingsScreen + ThemeSettingsScreen + ReminderSettingsScreen 三类同文件）
- `lib/features/profile/study_plan_settings_screen.dart`、`help_support_screen.dart`、`about_screen.dart`
- `lib/features/notifications/notifications_screen.dart`
- `lib/features/search/search_screen.dart`
- `lib/features/review/mistake_book_screen.dart`
- `lib/features/onboarding/splash_screen.dart`、`onboarding_screen.dart`
- `lib/features/auth/login_screen.dart`、`register_screen.dart`、`goal_setup_screen.dart`
- 清理：`lib/core/widgets/quest_panel.dart`、`quest_list_row.dart`、`status_badge.dart`（仅当全 App 零引用才删）
- `test/widget_test.dart`（仅必要 finder 同步 + 可选结构断言）
- 不改 `data/`、`core/state/`、`core/routing/`、`l10n/`、`server/`、其余 `core/widgets/` 实现

---

## Task 1: 设置 Hub + 主题 + 提醒（settings_screen.dart 三类）

**保留数据/notifier：** Settings: `state.currentStudyBook/dailyNewTarget/dailyReviewLimit/reminderSettings/themeMode/locale`；`updateLocale(locale)`。Theme: `state.themeMode`；`updateThemeMode(value)`。Reminder: `state.reminderSettings`；`updateReminderSettings(copyWith(...))`。
**保留导航：** `/settings/study-plan`、`/settings/reminder`、`/settings/theme`；back。
**保留 l10n：** settingsAppBar、commonStudyPlan/New/Review/DailyReminder/Day、settingsReminderOff、commonTheme、languageSetting、settingsSoundFeedback(Subtitle)、settingsThemeSystem(Subtitle)/Light(Subtitle)/Dark(Subtitle)、settingsReminderTitle/Time/Disabled/Description。
**耦合：** theme/reminder 由 notifier 单元测试覆盖（`theme and reminder settings persist locally` 调 notifier，不点 UI）→ UI 可自由迁移。**保留 `SwitchListTile`**（提醒开关，语义清晰）或换 `Switch`（无类型耦合，二者皆可——优先保留 SwitchListTile）。
**映射：** `_SettingsAction`/`_LanguageSetting`/`_SettingsInfoLine`/`_ThemeOption` 的 Material/InkWell 容器 → `AppCard(onTap:)`；语言选项 radio sheet 保留；theme radio 行 → `AppCard` 行。色彩纪律。

- [ ] **Step 1:** grep 耦合（确认 settings/theme/reminder 无按钮类型耦合）。退化守卫（无直接 UI 测试断言这些屏）。
- [ ] **Step 2:** 实现三类迁移；`dart format`。
- [ ] **Step 3:** `flutter analyze` 干净；`flutter test` 全绿（含 `theme and reminder settings persist locally`、`reminder settings update syncs into the saved study plan`）。
- [ ] **Step 4:** grep 核对 l10n/notifier。
- [ ] **Step 5:** 提交：`git commit -m "feat(settings): reskin settings, theme and reminder with Cozy Quest components"`。

---

## Task 2: 学习计划设置（study_plan_settings_screen）— 高耦合

**保留数据/notifier：** `state.user/lessons/completedLessonIds/studyPlan/isLoading/errorMessage`；本地 `_dailyNewController/_dailyReviewController/_wordBookId/_targetFinishDate/_reminderTime`；`ref.listenManual`；`updateStudyPlan(plan)`、`toggleStudyPlanPaused()`、`resetStudyPlan()`。
**保留导航：** `/wordbook`；back。
**保留 l10n：** 全部 studyPlan* + wordbookSwitch/wordbookWordsLearned（以现状为准，不增删）。
**关键耦合（务必）：**
- 加载时的 `LinearProgressIndicator`(底部保存条 + 顶部)——**保留 `LinearProgressIndicator` 类型**(测试 `find.byType(LinearProgressIndicator) findsOneWidget`/`findsNWidgets(2)`)。**不要**把它换成 `AppProgressBar`。
- `_NumberField` 的 `TextFormField` + `FilteringTextInputFormatter.digitsOnly`——**保留 `TextFormField`**(测试找 `EditableText`/`TextFormField` + digitsOnly,断言值 '10'/'20'/'33'/'44')。
- 保存按钮文案 `'保存学习计划'`(studyPlanSave)——可转 `AppPrimaryButton`(`find.text` 按文案,文案不变即可)。
- 错误文案、`'学习计划已保存。'`、`'目标完成日期不能早于今天。'` 等保留。
**映射：** `_PlanHeroCard` Container → `AppCard`(内 `LinearProgressIndicator` 保留为进度环/条? ——hero 内的进度若被测试断言则保留;否则可 `AppProgressBar`。**保守:保留 hero 内现有进度控件类型**);`PillLabel` → `AppPill`;`_StudyBookPill`/`_PlanActionRow` Material/InkWell → `AppCard` 行;`_PlanActions` 的 `OutlinedButton.icon`/`FilledButton.tonalIcon` → `AppSecondaryButton`/`AppPrimaryButton`(grep 确认无类型耦合;保存条的 `FilledButton.icon` 文案 `studyPlanSave` 按 `find.text` → 转 `AppPrimaryButton` 可,文案不变);`SectionHeader`/`IconCueBadge`/`QuestIconButton` 保留。**所有 `LinearProgressIndicator` 与 `TextFormField` 保持类型不变。**

- [ ] **Step 1:** `grep -n "保存学习计划\|byType(LinearProgressIndicator)\|byType(TextFormField)\|byType(EditableText)\|目标完成日期\|学习计划已保存" test/widget_test.dart` 记录耦合。可选在 `study plan settings shows a loading bar while saving` 加 `expect(find.byType(AppCard), findsWidgets);`（不动 LinearProgressIndicator 断言）。
- [ ] **Step 2:** 跑确认失败（若加断言）。
- [ ] **Step 3:** 实现；**保留所有 LinearProgressIndicator + TextFormField 类型**；`dart format`。
- [ ] **Step 4:** `flutter test` 全绿（**务必**含全部 6 个 study-plan 测试：loading bar、save error、numeric digits only、unchanged expired date、resyncs、fallback preserves edits）；`flutter analyze` 干净。任一失败→修复迁移恢复类型/文案,绝不改测试断言。
- [ ] **Step 5:** 提交：`git commit -m "feat(settings): reskin study plan settings with Cozy Quest components"`。

---

## Task 3: 帮助 + 关于（help_support_screen + about_screen）

**保留：** 静态；help l10n: profileHelpTitle、helpFaqReviewScheduleQ/A、helpFaqCustomWordsQ/A、helpFaqAiTutorQ/A、helpContactSupport。about l10n: profileAboutTitle、aboutVersion、aboutIntro、aboutGoalTitle/Subtitle、aboutTeamTitle/Subtitle、aboutCoreTitle/Subtitle、aboutPrivacyTitle/Subtitle。back。
**映射：** help: `QuestPanel`(FAQ ExpansionTile + 支持邮箱)→ `AppCard`;`QuestListRow`(支持邮箱行)→ `AppCard` 行。about: `BrandHeroCard` 保留或换 `AppCard` navy 英雄;`QuestPanel`(intro + 信息组)→ `AppCard`;`QuestListRow`×4(目标/团队/核心/隐私)→ `AppCard` 行。`SectionHeader` 保留。ExpansionTile 保留(交互)。

- [ ] **Step 1:** 退化守卫(无测试)。grep 确认无类型耦合。
- [ ] **Step 2:** 实现两屏(**移除对 QuestPanel/QuestListRow 的使用**,为 Task 10 清理铺路);`dart format`。
- [ ] **Step 3:** `flutter analyze` 干净;`flutter test` 全绿。
- [ ] **Step 4:** grep 核对 l10n;`grep -n "QuestPanel\|QuestListRow"` 两文件期望无。
- [ ] **Step 5:** 提交:`git commit -m "feat(profile): reskin help and about with Cozy Quest components"`。

---

## Task 4: 通知中心（notifications_screen）

**保留数据/notifier：** `state.notifications/unreadNotificationCount`;本地 `_filter`;`markAllNotificationsRead()`、`openNotification(notification)`(返回动态路由 `/home`/`/discover`/`/training`/`/ai-learning`/`/profile` 或 push)。
**保留 l10n：** notificationTitle、notificationMarkAllRead、notificationCenter(Desc)、notificationUnreadCount、notificationEmptyTitle/EmptyUnread/EmptyAll、notificationBackHome、notificationFilterAll/Unread/Learning/Activity。
**映射：** `_NotificationFilterTabs`/`_NotificationFilterTab` 保留(自定义 tab,或换 `SegmentedTabs`——保守保留);空态 `EmptyState` → `MascotEmptyState`;`_NotificationRow` Material/InkWell → `AppCard(onTap:)`(保留 `openNotification`);`PillLabel` → `AppPill`;`IconCueBadge`/`_UnreadDot`/`SectionHeader` 保留;标记全部已读按钮保留。

- [ ] **Step 1:** 退化守卫(`notifications` 无专门 widget 测试——grep 确认)。可选断言。
- [ ] **Step 2:** 实现;`dart format`。
- [ ] **Step 3:** analyze 干净;`flutter test` 全绿。
- [ ] **Step 4:** grep 核对 l10n/notifier;`QuestPanel\|StatusBadge` 期望无。
- [ ] **Step 5:** 提交:`git commit -m "feat(notifications): reskin notification center with Cozy Quest components"`。

---

## Task 5: 搜索（search_screen）

**保留数据/导航：** `state.currentWordBook/wordBooks/currentWordBookId/formalLessons/customWords`;`ref.listenManual`;本地 `_query/_scope/_isSearching/_targetWords/_customWords`(防抖搜索);导航 `/wordbook/${id}`、`/custom-words/${id}`、`/custom-words/new`。
**保留 l10n：** searchTitle、searchFieldLabel、searchScopeSummary、searchCurrentWordbookScope、searchAllWordbooksScope、searchStartTitle/Message、searchNoResultsTitle/Message、wordbookAddCustom、commonCustomWords、searchCurrentPlan。
**映射：** 搜索 `TextField` 保留(防抖逻辑不变);`FilterPillButton`(scope) 保留;空态 `EmptyState`×2 → `MascotEmptyState`;`_TargetWordTile`/`_CustomWordTile` Material/InkWell → `AppCard(onTap:)`;`PillLabel` → `AppPill`;`ImageCueBadge` 保留;搜索中 `CircularProgressIndicator` 保留。
**耦合：** `home search bar opens search instead of wordbook` 测试经 `/search`——它点首页搜索框进 search,断言到达;保留搜索 `TextField` 与到达行为。

- [ ] **Step 1:** grep `search` 耦合。可选断言。
- [ ] **Step 2:** 实现;保留防抖 + TextField + 导航;`dart format`。
- [ ] **Step 3:** analyze 干净;`flutter test` 全绿(含 `home search bar opens search instead of wordbook`、`wordbook and search hide training-only target words`)。
- [ ] **Step 4:** grep 核对。
- [ ] **Step 5:** 提交:`git commit -m "feat(search): reskin search with Cozy Quest components"`。

---

## Task 6: 错题本（mistake_book_screen）

**保留数据/notifier：** 探索该文件确认(`lib/features/review/mistake_book_screen.dart`)——保留其 `appControllerProvider` 选择器、任何 notifier 调用、导航、全部 l10n（以现状为准，逐一 grep 保留）。
**映射：** `QuestListRow`×2 → `AppCard` 行;`StatusBadge`×2 → `AppPill`。其余按通用映射。
**耦合：** `lesson mistake appears in review center after result` 涉及复习中心(已迁移),mistake-book 自身可能无专门测试——grep 确认。

- [ ] **Step 1:** 先 `Read` mistake_book_screen.dart 全文,列出其选择器/notifier/导航/l10n。grep 耦合。
- [ ] **Step 2:** 实现(移除 QuestListRow/StatusBadge 使用);`dart format`。
- [ ] **Step 3:** analyze 干净;`flutter test` 全绿。
- [ ] **Step 4:** grep 核对;`QuestListRow\|StatusBadge` 该文件期望无。
- [ ] **Step 5:** 提交:`git commit -m "feat(review): reskin mistake book with Cozy Quest components"`。

---

## Task 7: 启动页 + 入门（splash_screen + onboarding_screen）

**splash 保留：** `bootstrap()`;`state.isBootstrapped/isLoading/errorMessage/isAuthenticated`;`context.go(isAuthenticated ? '/home' : '/onboarding')`;l10n: splashTagline、commonRetry。**保留 `BrandMark`、加载 `LinearProgressIndicator`、`Icons.refresh_rounded` 重试 `FilledButton.icon`**(测试 `find.text('再试一次')` 按文案——转按钮须保文案;`LinearProgressIndicator` 类型保留)。'LinguaQuest' 硬编码标题保留。
**onboarding 保留：** 静态;`context.go('/register')`、`context.go('/login')`;l10n: onboardingFeature*、onboardingTagWorld/Streak、onboardingTagline、onboardingRegisterButton、commonLogin。**保留 `Icons.route_outlined`**(测试 `find.byIcon(Icons.route_outlined)`——它来自 `_OnboardingStepRow` 的某步图标,保留该图标);**注册按钮文案 `'注册账号'`(onboardingRegisterButton) 保留**。
**耦合(关键):** onboarding 登录按钮 `find.widgetWithText(OutlinedButton, '登录')`(@~765)——若转 `AppSecondaryButton` 须同步改该 finder 为 `widgetWithText(AppSecondaryButton, '登录')`;注册 `FilledButton`(`'注册账号'`)按 `find.text` 无类型耦合 → 可转 `AppPrimaryButton`。
**映射：** onboarding `PillLabel`×3 → `AppPill`;`_OnboardingStepRow` 容器/Divider → 收敛(`ImageCueBadge` + 图标保留);按钮按上策略。splash 重试/加载保留类型(或重试转 AppPrimaryButton 但保文案)。`BrandMark`/`SectionHeader` 保留。

- [ ] **Step 1:** `grep -n "widgetWithText(OutlinedButton, '登录')\|注册账号\|route_outlined\|再试一次\|启动失败" test/widget_test.dart` 记录。决定 onboarding 登录按钮:保留 OutlinedButton 或转 AppSecondaryButton + 改 finder(二选一,**优先转 AppSecondaryButton + 改 finder** 以统一)。
- [ ] **Step 2:** 实现两屏;若转 onboarding 登录按钮,同步改 `widgetWithText(OutlinedButton, '登录')` → `widgetWithText(AppSecondaryButton, '登录')`。`dart format`。
- [ ] **Step 3:** `flutter test` 全绿(**务必**含 `starts at onboarding when no session exists`、`failed login stays on login screen and shows error`、`bootstrap failure can retry without restarting the app`、`session load failure falls back to onboarding`);`flutter analyze` 干净。
- [ ] **Step 4:** grep 核对(route_outlined/注册账号/再试一次 文案与图标在;LinearProgressIndicator 在)。
- [ ] **Step 5:** 提交:`git commit -m "feat(onboarding): reskin splash and onboarding with Cozy Quest components"`。

---

## Task 8: 登录 + 注册（login_screen + register_screen）— 高耦合

**login 保留：** `state.isLoading/errorMessage`;`login(email, password)`;`context.go('/register')`、`context.go('/home')`;`_formKey`、`_emailValidator`(含'@')、`_passwordValidator`(>=6);**2 个 `TextFormField`(email/password)保留**(测试 `find.byType(TextFormField).at(0/1)`);l10n: authLoginTitle、authWelcomeBack(Subtitle)、authEmail(Hint)、authPassword(Hint)、commonLogin、authRegisterNew。**`'欢迎回来'`(authWelcomeBack)文案保留。**
**login 耦合(关键):** 登录提交 `find.widgetWithText(FilledButton, '登录')`(@~776)——转 `AppPrimaryButton` 须同步改该 finder 为 `widgetWithText(AppPrimaryButton, '登录')`。
**register 保留：** `state.isLoading/errorMessage`;`register(name, email, password)`;`context.go('/login')`、`context.go('/goal-setup')`;3 个 `TextFormField`(name/email/password)+ validators 保留;l10n: authRegisterTitle、authCreateProfile(Subtitle)、authStep1of2、authNickname(Hint)、authEmail(Hint)、authPassword(Hint)、authContinueToGoal、authHaveAccount、authNameRequired/EmailRequired/EmailInvalid/PasswordRequired、authAccountCreated。
**register 耦合:** 提交 `FilledButton` 文案 `authContinueToGoal`——grep 确认是否 `widgetWithText(FilledButton, ...)` 耦合(`mock register rejects duplicate email` 是 notifier 测试,可能不点 UI)。无耦合 → 转 `AppPrimaryButton`。
**映射：** login `BrandHeroCard` 保留或换 AppCard navy;`QuestPanel`(表单)→ `AppCard`;2 个 TextFormField 保留;登录 `FilledButton.icon`(带 spinner)→ `AppPrimaryButton`(保留 loading 语义 + 改 finder)。register `SectionHeader`/`PillLabel`(step)→ AppPill;3 个 TextFormField 保留;提交按钮 → `AppPrimaryButton`(若无耦合)。`TextButton`(切换登录/注册)保留或 → 文本按钮。

- [ ] **Step 1:** `grep -n "widgetWithText(FilledButton, '登录')\|byType(TextFormField)\|欢迎回来\|继续\|authContinueToGoal\|该邮箱已经注册" test/widget_test.dart` 记录。决定:login 提交转 `AppPrimaryButton` + 改 `widgetWithText(FilledButton, '登录')` → `widgetWithText(AppPrimaryButton, '登录')`。register 提交据 grep 决定。
- [ ] **Step 2:** 实现两屏;**保留全部 TextFormField + validators**;同步改 login finder;`dart format`。
- [ ] **Step 3:** `flutter test` 全绿(**务必**含 `failed login stays on login screen and shows error`(它先在 onboarding 点 '登录' OutlinedButton→login 屏,再填 TextFormField,再点 '登录' FilledButton/AppPrimaryButton,断言 '欢迎回来' + 错误)、`mock register rejects duplicate email`);`flutter analyze` 干净。
- [ ] **Step 4:** grep 核对(2/3 个 TextFormField 在、validators 在、'欢迎回来' 在)。
- [ ] **Step 5:** 提交:`git commit -m "feat(auth): reskin login and register with Cozy Quest components"`。

---

## Task 9: 目标设置（goal_setup_screen）— 高耦合(尺寸稳定)

**保留数据/notifier：** `ref.listenManual`;`state.wordBooks/lessons/completedLessonIds/user/currentWordBookId/studyPlan`;`completeGoalSetup(targetExam:, level:, dailyGoal:, deadline:)`;`_initializeFromState`/`_save`/`_pickDeadline`/`_dailyWordsForDeadline`。
**保留导航：** `context.push('/wordbook')`;`context.go('/home')`;back fallback `/home`。
**保留 l10n：** goalSetupTitle、goalSetupSelectPlan(Subtitle)、authStep2of2、commonWords/Day、goalSetupTarget、goalSetupDailyGoal、goalSetupDeadlinePlan、goalSetupDeadlineHint、goalSetupPickDate、goalSetupChangeDate、goalSetupClearDate、goalSetupEnterApp（+ `_PlanSnapshotLine` 全部 key）。
**关键耦合(务必):** `_StableChoiceButton` 是 `AnimatedContainer(height: 48)`,被 `tester.getSize(find.byKey(const ValueKey('choice-IELTS')))` 断言**选中前后尺寸不变**(test `goal setup choices keep a stable size when selected`)。**保留:**(a)每个选项卡的 `ValueKey('choice-<value>')`;(b)固定高度 48 的 `AnimatedContainer` 结构(选中仅变边框/图标,不变尺寸)。**不要**把 `_StableChoiceButton` 换成 `AppCard`/`AppPrimaryButton`(会改尺寸/布局,破坏 getSize 断言)。
**映射(限定):** `_PlanSnapshotLine` 容器 → `AppCard`;`PillLabel`×N → `AppPill`;日期 `OutlinedButton.icon` → `AppSecondaryButton(icon:)`(grep 确认无耦合);保存 `FilledButton.icon`(goalSetupEnterApp)→ `AppPrimaryButton`(`goal setup starts from the current learning profile` 点 '调整计划' 文案,非此按钮;确认无类型耦合);`SectionHeader`/`QuestIconButton`(清除日期)保留。**`_StableChoiceButton`、`_ChoiceList`、`_ChoiceSection` 保持结构与 ValueKey 与高度 48 不变(仅可 token 化颜色)。**

- [ ] **Step 1:** `grep -n "byKey(const ValueKey('choice\|getSize\|调整计划\|goalSetupEnterApp\|进入" test/widget_test.dart` 记录。确认 `_StableChoiceButton` 不动。
- [ ] **Step 2:** 实现(仅迁移快照卡/pills/日期&保存按钮;**选项卡 + ValueKey + 高度 48 不变**);`dart format`。
- [ ] **Step 3:** `flutter test` 全绿(**务必**含 `goal setup choices keep a stable size when selected`、`goal setup starts from the current learning profile`、`deadline picker initial date stays inside selectable bounds`);`flutter analyze` 干净。尺寸测试失败→恢复选项卡结构。
- [ ] **Step 4:** grep 核对(ValueKey('choice- 仍在、completeGoalSetup 在)。
- [ ] **Step 5:** 提交:`git commit -m "feat(auth): reskin goal setup with Cozy Quest components"`。

---

## Task 10: 删除旧原语（QuestPanel / QuestListRow / StatusBadge）

仅当全 App 零引用才删（`PillLabel` 必须保留——仍广泛使用）。

- [ ] **Step 1:** 逐一核查引用：
  - `grep -rn "QuestPanel" lib --include=*.dart | grep -v "quest_panel.dart"` → 期望仅 0 行（定义文件外无引用）。
  - `grep -rn "QuestListRow" lib --include=*.dart | grep -v "quest_list_row.dart"` → 期望 0。
  - `grep -rn "StatusBadge" lib --include=*.dart | grep -v "status_badge.dart"` → 期望 0（**注意** `word_knowledge_sections.dart` 之前保留——若它仍用 StatusBadge,则 StatusBadge **不删**,在报告说明并保留该文件）。
- [ ] **Step 2:** 对零引用者 `git rm lib/core/widgets/<file>.dart`；同时删其测试（若有 `test/core/widgets/<file>_test.dart`）。保留仍被引用者。
- [ ] **Step 3:** `flutter analyze` → `No issues found!`（无悬空 import）；`flutter test` 全绿。
- [ ] **Step 4:** 提交：`git commit -m "chore(widgets): remove retired QuestPanel/QuestListRow/StatusBadge primitives"`（按实际删除的列出）。

---

## Task 11: 全局收尾验收

- [ ] **Step 1:** `flutter analyze` → `No issues found!`
- [ ] **Step 2:** `flutter test` → All tests passed!
- [ ] **Step 3:** 全局残留核查 `grep -rln "QuestPanel" lib/features` → 期望无。
- [ ] **Step 4:** 提交（如有修订）。

---

## Self-Review（作者自查）

**Spec 覆盖：** §2/§6/§7/§9 贯穿；§9 弃用并**删除**旧原语（零引用者）。吉祥物经 `MascotEmptyState`（通知/搜索空态）贯穿。
**占位符扫描：** 无 TBD；高耦合屏（study-plan/login/onboarding/goal-setup）逐条给出类型保留 / finder 同步 / 尺寸稳定的精确要求；Task 6 要求实现前先 Read mistake_book。
**类型一致性：** 复用 Plan 1-5 组件；保留 `LinearProgressIndicator`/`TextFormField`/`SwitchListTile`/`_StableChoiceButton`/`BrandMark`/`PillLabel`/`SectionHeader`/`FilterPillButton`/`ImageCueBadge`。
**范围：** 13 屏 + 旧原语删除 + 必要 test finder 同步；不碰 data/state/routing/l10n/server。

## 完成后

全 6 个计划完成 → 整个前端迁移到 Cozy Quest 设计系统。可考虑：整体 `flutter analyze` + `flutter test` 终验、（用户授权后）合并/开 PR。
