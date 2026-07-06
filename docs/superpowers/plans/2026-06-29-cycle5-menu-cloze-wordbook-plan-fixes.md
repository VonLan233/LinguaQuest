# Cycle 5 修复实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复 6 项用户反馈：home 汉堡图标主题色、Passage Cloze 超时、词书切换后计划仍显示 HSK1、目标完成日期改自动推算、Campus Sprint 移出 Timed Tests、清理 IELTS/TOEFL/GRE 残留。

**Architecture:** 客户端 Flutter（Riverpod）+ 服务端 Dart shelf。改动以最小面修复确切根因：图标显式着色；服务端超时常量；解除 study_plan 的 hsk1 硬编码并让显示层走真实 `state.wordBooks`；设置页日期自动推算；训练页分组重排；死文案删除。

**Tech Stack:** Flutter 3.41.6, Riverpod, go_router；Dart shelf + PostgreSQL；flutter gen-l10n。

## Global Constraints

- 全程中文回复（用户偏好）；commit **不带 Co-Authored-By**。
- App 为 light-only；"主题色"用 `Theme.of(context).colorScheme.*` token，不重新引入暗色模式开关。
- 线上 `/wordbooks` 已含全部 15 本（hsk1-6 / jlpt_n5-n1 / en_basic/es_basic/fr_basic/ms_basic）；服务端 `allowedWordBookIds` 已接受全部 id。客户端缺 `language` 默认 `'zh'`。
- `WordBook.title` 对全部词书均为可读名（"HSK 2"/"JLPT N5"/"English Basics"/"Español Básico"/"Français Débutant"/"Bahasa Melayu Asas"）；显示名优先用 `WordBook.nameFor(localeCode)`/`title`，不用 `displayWordbookTitle(id)`（它对 en_basic 等会返回原始 id）。
- 不改 `normalizedStudyBookId` 的"进度统计"语义（`wordbook_progress.dart` 仍依赖它），避免进度回归；只在显示/比较处改用真实 id。
- `studyBookIdForTarget`/`StudyPlan.defaultsFor` 保持新用户默认 hsk1（仅 `StudyPlan.fromJson` 改为保留真实 id）。
- 服务端改动用户**已预授权部署**到 `api.vonlan233.top`；部署在最后一步执行。
- 现有测试必须保持绿色：`flutter test` / `flutter analyze`（client，在 `linguaquest/`）；`dart test` / `dart analyze`（server，在 `server/`）。
- 测试 harness 复用现有模式：`test/features/quests/progress_analytics_screen_test.dart` 的 `_FakeAppController extends AppController { AppState build() => _state; }` + `_buildHarness(child, state)`（ProviderScope 覆盖 `appControllerProvider` + MaterialApp + l10n delegates + `locale: Locale('en')`）。

---

### Task 1: home 顶栏汉堡图标主题着色（#1）

**Files:**
- Modify: `linguaquest/lib/features/home/home_screen.dart:66`
- Test: `linguaquest/test/features/home/home_menu_icon_test.dart`（新建）

**Interfaces:**
- Consumes: `AppIcons.menu`（IconData）、`Theme.of(context).colorScheme.onSurface`。
- Produces: 无（仅 UI）。

- [ ] **Step 1: 写失败测试**

新建 `linguaquest/test/features/home/home_menu_icon_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/theme/app_icons.dart';
import 'package:linguaquest/features/home/home_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

void main() {
  testWidgets('home menu (hamburger) icon uses theme onSurface color', (
    tester,
  ) async {
    final state = AppState.initial().copyWith(isBootstrapped: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(() => _FakeAppController(state)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const HomeScreen(),
        ),
      ),
    );
    await tester.pump();

    final iconWidget = tester.widget<Icon>(find.byIcon(AppIcons.menu));
    final ctx = tester.element(find.byIcon(AppIcons.menu));
    expect(iconWidget.color, Theme.of(ctx).colorScheme.onSurface);
  });
}
```

> 若 `HomeScreen` 在该最小 state 下渲染抛错，按 `progress_analytics_screen_test.dart` 的方式补齐 `AppState` 必要字段（user / lessons 等），保持断言不变。

- [ ] **Step 2: 跑测试确认失败**

Run: `cd linguaquest && flutter test test/features/home/home_menu_icon_test.dart`
Expected: FAIL（当前 `Icon(AppIcons.menu)` 无 color，`iconWidget.color` 为 null ≠ onSurface）。

- [ ] **Step 3: 实现**

`home_screen.dart:64-67` 由：

```dart
                  child: const Padding(
                    padding: EdgeInsets.all(AppTokens.s4),
                    child: Icon(AppIcons.menu, size: 24),
                  ),
```

改为：

```dart
                  child: Padding(
                    padding: const EdgeInsets.all(AppTokens.s4),
                    child: Icon(
                      AppIcons.menu,
                      size: 24,
                      color: Theme.of(ctx).colorScheme.onSurface,
                    ),
                  ),
```

> 该 `Icon` 处于 `Builder(builder: (ctx) => ...)` 内（home_screen.dart:58-69），`ctx` 即 Builder 的 context，可直接用。删去外层 `const`。

- [ ] **Step 4: 跑测试确认通过**

Run: `cd linguaquest && flutter test test/features/home/home_menu_icon_test.dart`
Expected: PASS。

- [ ] **Step 5: analyze + 提交**

```bash
cd linguaquest && flutter analyze lib/features/home/home_screen.dart test/features/home/home_menu_icon_test.dart
git add linguaquest/lib/features/home/home_screen.dart linguaquest/test/features/home/home_menu_icon_test.dart
git commit -m "fix(home): 汉堡菜单图标跟随主题色(onSurface)"
```
Expected: `No issues found!`，提交成功。

---

### Task 2: 服务端 cloze 超时 30s→50s（#2）

**Files:**
- Modify: `server/lib/src/ai_policy.dart:334`
- Test: `server/test/remote_ai_provider_test.dart`（追加一个 test）

**Interfaces:**
- Consumes: `RemoteAiProvider({required client, required apiKey, required baseUrl, required model, Duration timeout})`。
- Produces: 默认 `timeout == Duration(seconds: 50)`。

- [ ] **Step 1: 写失败测试**

在 `server/test/remote_ai_provider_test.dart` 的 `main()` 内追加（import 若缺则补 `package:linguaquest_server/src/ai_policy.dart` 对应路径——按该文件现有 import 写法）：

```dart
  test('RemoteAiProvider default timeout is 50s', () {
    final provider = RemoteAiProvider(
      client: http.Client(),
      apiKey: 'k',
      baseUrl: 'https://example.test/v1',
      model: 'm',
    );
    expect(provider.timeout, const Duration(seconds: 50));
  });
```

> 若该测试文件未 import `package:http/http.dart as http`，按文件现有引用方式补齐；构造一个 `http.Client()` 仅用于占位、不发请求。

- [ ] **Step 2: 跑测试确认失败**

Run: `cd server && dart test test/remote_ai_provider_test.dart -n "RemoteAiProvider default timeout is 50s"`
Expected: FAIL（当前默认 30s）。

- [ ] **Step 3: 实现**

`ai_policy.dart:334`：

```dart
    this.timeout = const Duration(seconds: 30),
```
改为：
```dart
    this.timeout = const Duration(seconds: 50),
```

- [ ] **Step 4: 跑测试确认通过**

Run: `cd server && dart test test/remote_ai_provider_test.dart`
Expected: PASS（含新测试与原有测试）。

- [ ] **Step 5: analyze + 提交**

```bash
cd server && dart analyze lib/src/ai_policy.dart test/remote_ai_provider_test.dart
git add server/lib/src/ai_policy.dart server/test/remote_ai_provider_test.dart
git commit -m "fix(ai): cloze 等远程模型超时 30s→50s(客户端 60s,留余量)"
```
Expected: `No issues found!`。

> 部署期 env `AI_CLOZE_MODEL=<更快模型>` 在 Task 8 部署步骤处理，本任务不改部署配置。

---

### Task 3: 解除 study_plan 的 hsk1 硬编码（模型 + 状态）（#3 核心）

**Files:**
- Modify: `linguaquest/lib/data/models/study_plan.dart:92`（`StudyPlan.fromJson`）+ 新增 `studyPlanCoverEmoji`
- Modify: `linguaquest/lib/core/state/app_state.dart:198-200`（`currentStudyBook`）
- Test: `linguaquest/test/features/profile/study_plan_wordbook_test.dart`（新建）

**Interfaces:**
- Produces:
  - `StudyPlan.fromJson(json)` 保留 `json['wordBookId']` 原值（非空），空/缺省回退 `'hsk1'`。
  - `String studyPlanCoverEmoji(String language)` → `'ja'`→`'🗾'`；`'en'/'es'/'fr'/'ms'`→`'🔤'`；其它→`'🀄'`。
  - `AppState.currentStudyBook` 优先用 `currentWordBook`（真实 WordBook）：`id=book.id, name=book.title, cover=studyPlanCoverEmoji(book.language), description=book.description`；无 wordBooks 时回退 `studyBookInfoForId(studyPlan?.wordBookId ?? '')`。
- Consumes: `AppState.currentWordBook`（已存在，app_state.dart:208-213，按 `currentWordBookId` 命中，空则 `wordBooks.first`）。

- [ ] **Step 1: 写失败测试**

新建 `linguaquest/test/features/profile/study_plan_wordbook_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/study_plan.dart';

WordBook _book(String id, String title, String language) => WordBook(
  id: id,
  title: title,
  category: 'basic',
  examType: 'Basic',
  coverUrl: '',
  totalWords: 30,
  includedWords: 30,
  description: 'desc-$id',
  wordIds: const [],
  createdAt: DateTime(2026, 1, 1),
  words: const [],
  language: language,
);

void main() {
  test('StudyPlan.fromJson keeps the real wordBookId', () {
    final plan = StudyPlan.fromJson({
      'uid': 'u1',
      'wordBookId': 'en_basic',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-06-20',
      'targetFinishDate': '2026-07-20',
      'reminderTime': '20:00',
      'status': 'active',
    });
    expect(plan.wordBookId, 'en_basic');
  });

  test('StudyPlan.fromJson falls back to hsk1 when wordBookId missing/empty', () {
    expect(StudyPlan.fromJson({'uid': 'u1'}).wordBookId, 'hsk1');
    expect(
      StudyPlan.fromJson({'uid': 'u1', 'wordBookId': '  '}).wordBookId,
      'hsk1',
    );
  });

  test('studyPlanCoverEmoji maps language to emoji', () {
    expect(studyPlanCoverEmoji('ja'), '🗾');
    expect(studyPlanCoverEmoji('en'), '🔤');
    expect(studyPlanCoverEmoji('zh'), '🀄');
    expect(studyPlanCoverEmoji('unknown'), '🀄');
  });

  test('currentStudyBook reflects the current wordbook, not hsk1', () {
    final state = AppState.initial().copyWith(
      wordBooks: [
        _book('hsk1', 'HSK 1', 'zh'),
        _book('en_basic', 'English Basics', 'en'),
      ],
      currentWordBookId: 'en_basic',
    );
    expect(state.currentStudyBook.id, 'en_basic');
    expect(state.currentStudyBook.name, 'English Basics');
    expect(state.currentStudyBook.cover, '🔤');
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd linguaquest && flutter test test/features/profile/study_plan_wordbook_test.dart`
Expected: FAIL（`fromJson` 现归一 hsk1；`studyPlanCoverEmoji` 不存在编译失败；`currentStudyBook.id` 现为 hsk1）。

- [ ] **Step 3a: 改 `study_plan.dart`**

`study_plan.dart:92`：

```dart
      wordBookId: normalizedStudyBookId(json['wordBookId'] as String?),
```
改为：
```dart
      wordBookId: _wordBookIdOrDefault(json['wordBookId']),
```

在 `normalizedStudyBookId`（第161行）上方新增两个顶层函数：

```dart
/// Keeps the real wordbook id from a server/stored plan; only falls back to
/// the default book when the value is missing or blank. (HSK-pivot used to
/// collapse everything to hsk1; with 15 books shipping that collapse is gone.)
String _wordBookIdOrDefault(Object? value) {
  final raw = (value as String?)?.trim() ?? '';
  return raw.isEmpty ? 'hsk1' : raw;
}

/// Emoji cover for the study-plan hero when a wordbook ships no artwork.
String studyPlanCoverEmoji(String language) {
  switch (language) {
    case 'ja':
      return '🗾';
    case 'en':
    case 'es':
    case 'fr':
    case 'ms':
      return '🔤';
    default:
      return '🀄';
  }
}
```

> 不改 `normalizedStudyBookId` / `studyBookIdForTarget` / `studyBooks`（仍供 `wordbook_progress` 与回退用）。

- [ ] **Step 3b: 改 `app_state.dart`**

`app_state.dart:198-200`：

```dart
  StudyBookInfo get currentStudyBook => studyBookInfoForId(
    studyPlan?.wordBookId ?? studyBookIdForTarget(user?.targetExam),
  );
```
改为：
```dart
  StudyBookInfo get currentStudyBook {
    final book = currentWordBook;
    if (book != null) {
      return StudyBookInfo(
        id: book.id,
        name: book.title,
        cover: studyPlanCoverEmoji(book.language),
        description: book.description,
      );
    }
    return studyBookInfoForId(studyPlan?.wordBookId ?? '');
  }
```

> `studyPlanCoverEmoji` 来自 `study_plan.dart`，该文件已被 `app_state.dart` import（`StudyBookInfo`/`studyBookInfoForId` 即来自它）。

- [ ] **Step 4: 跑测试确认通过**

Run: `cd linguaquest && flutter test test/features/profile/study_plan_wordbook_test.dart`
Expected: PASS（4 个 test 全过）。

- [ ] **Step 5: 跑相关回归 + analyze + 提交**

```bash
cd linguaquest && flutter test test/widget_test.dart && flutter analyze lib/data/models/study_plan.dart lib/core/state/app_state.dart test/features/profile/study_plan_wordbook_test.dart
```
Expected: widget_test 全绿（goal_setup 用例仍断言 hsk1，因 `studyBookIdForTarget` 未改，通过）；`No issues found!`。

```bash
git add linguaquest/lib/data/models/study_plan.dart linguaquest/lib/core/state/app_state.dart linguaquest/test/features/profile/study_plan_wordbook_test.dart
git commit -m "fix(study-plan): fromJson 保留真实词书 id + currentStudyBook 反映当前词书(解除 hsk1 硬编码)"
```

---

### Task 4: 学习计划设置页显示真实词书（#3 显示层）

> 依赖 Task 3。

**Files:**
- Modify: `linguaquest/lib/features/profile/study_plan_settings_screen.dart`（`_wordBookForId` 382-389；hero 构造 97；`_PlanHeroCard` 504/509；selector 高亮 599-601）
- Modify: `linguaquest/lib/features/profile/settings_screen.dart:35`
- Modify: `linguaquest/lib/features/profile/profile_screen.dart:85-88`
- Test: `linguaquest/test/features/profile/study_plan_settings_book_test.dart`（新建）

**Interfaces:**
- Consumes: Task 3 的 `currentStudyBook.name`；`WordBook.nameFor(localeCode)`。
- Produces: `_wordBookForId(books, id)` 按**原始 id** 匹配（不再 normalize）。

- [ ] **Step 1: 写失败测试**

新建 `linguaquest/test/features/profile/study_plan_settings_book_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/auth.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/study_plan.dart';
import 'package:linguaquest/features/profile/study_plan_settings_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

WordBook _book(String id, String title, String language) => WordBook(
  id: id,
  title: title,
  category: 'hsk',
  examType: title,
  coverUrl: '',
  totalWords: 100,
  includedWords: 100,
  description: 'desc-$id',
  wordIds: const [],
  createdAt: DateTime(2026, 1, 1),
  words: const [],
  language: language,
);

void main() {
  testWidgets('study plan hero shows the selected wordbook (HSK 2), not HSK 1', (
    tester,
  ) async {
    final user = UserProfile(
      uid: 'u1',
      name: 'V',
      email: 'v@example.com',
      avatar: '',
      level: 'Beginner',
      targetExam: 'HSK 2',
      dailyGoal: 10,
      xp: 0,
      streak: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    final plan = StudyPlan.fromJson({
      'uid': 'u1',
      'wordBookId': 'hsk2',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-06-20',
      'targetFinishDate': '2026-07-20',
      'reminderTime': '20:00',
      'status': 'active',
    });
    final state = AppState.initial().copyWith(
      isBootstrapped: true,
      user: user,
      wordBooks: [_book('hsk1', 'HSK 1', 'zh'), _book('hsk2', 'HSK 2', 'zh')],
      currentWordBookId: 'hsk2',
      studyPlan: plan,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(() => _FakeAppController(state)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const StudyPlanSettingsScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('HSK 2'), findsWidgets);
  });

  test('_wordBookForId matches by raw id', () {
    final books = [_book('hsk1', 'HSK 1', 'zh'), _book('hsk2', 'HSK 2', 'zh')];
    expect(wordBookForIdForTest(books, 'hsk2')?.id, 'hsk2');
    expect(wordBookForIdForTest(books, 'missing'), isNull);
  });
}
```

> `StudyPlanSettingsScreen` 的精确类名/构造以文件内为准（若非 `const StudyPlanSettingsScreen()` 则按文件调整）。`UserProfile` 字段以 `lib/data/models/auth.dart` 实际定义为准（若字段名不同，按真实模型补齐，保持断言不变）。

- [ ] **Step 2: 跑测试确认失败**

Run: `cd linguaquest && flutter test test/features/profile/study_plan_settings_book_test.dart`
Expected: FAIL（hero 经 `studyBookInfoForId` 显示 "HSK 1"；`wordBookForIdForTest` 未导出/`_wordBookForId` 仍 normalize 返回 first）。

- [ ] **Step 3a: 改 `_wordBookForId`（study_plan_settings_screen.dart:382-389）**

```dart
WordBook? _wordBookForId(List<WordBook> books, String id) {
  for (final book in books) {
    if (normalizedStudyBookId(book.id) == normalizedStudyBookId(id)) {
      return book;
    }
  }
  return null;
}
```
改为：
```dart
WordBook? _wordBookForId(List<WordBook> books, String id) {
  for (final book in books) {
    if (book.id == id) return book;
  }
  return null;
}

/// Test-only accessor for [_wordBookForId].
WordBook? wordBookForIdForTest(List<WordBook> books, String id) =>
    _wordBookForId(books, id);
```

- [ ] **Step 3b: hero 用真实词书（study_plan_settings_screen.dart:97）**

`final book = studyBookInfoForId(_wordBookId);` 改为：

```dart
    final book = selectedWordBook != null
        ? StudyBookInfo(
            id: selectedWordBook.id,
            name: selectedWordBook.nameFor(localeCode),
            cover: studyPlanCoverEmoji(selectedWordBook.language),
            description: selectedWordBook.description,
          )
        : studyBookInfoForId(_wordBookId);
```

> `selectedWordBook` 已在 81 行计算（`_wordBookForId(state.wordBooks, _wordBookId)`），修了 3a 后即为正确词书。`localeCode` 已在 80 行。`studyPlanCoverEmoji` 来自 study_plan.dart（该文件已 import）。

- [ ] **Step 3c: `_PlanHeroCard` 用 `book.name`/`book.description`（504/509）**

第 503-505：
```dart
                    Text(
                      displayWordbookTitle(book.id, l10n: l10n),
                      style: theme.textTheme.titleLarge,
                    ),
```
改为：
```dart
                    Text(
                      book.name,
                      style: theme.textTheme.titleLarge,
                    ),
```
第 508-513：
```dart
                    Text(
                      displayWordbookDescription(book.id, l10n: l10n),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
```
改为：
```dart
                    Text(
                      book.description,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
```

- [ ] **Step 3d: selector 高亮按真实 id（599-601）**

```dart
              final selected =
                  normalizedStudyBookId(selectedId) ==
                  normalizedStudyBookId(book.id);
```
改为：
```dart
              final selected = selectedId == book.id;
```

- [ ] **Step 3e: settings_screen.dart:35 + profile_screen.dart 用 `currentStudyBook.name`**

`settings_screen.dart` 第 35 行的 `displayWordbookTitle(state.currentStudyBook.id, l10n: l10n)` 改为 `state.currentStudyBook.name`：
```dart
              subtitle:
                  '${state.currentStudyBook.name} · ${l10n.commonNew} ${state.dailyNewTarget} · ${l10n.commonReview} ${state.dailyReviewLimit}',
```

`profile_screen.dart` 第 85-88：
```dart
              value: displayWordbookTitle(
                state.currentStudyBook.id,
                l10n: l10n,
              ),
```
改为：
```dart
              value: state.currentStudyBook.name,
```

> 若改后 `settings_screen.dart` / `profile_screen.dart` 不再使用 `displayWordbookTitle`，删除其 import（`flutter analyze` 会报 unused import）。

- [ ] **Step 4: 跑测试确认通过**

Run: `cd linguaquest && flutter test test/features/profile/study_plan_settings_book_test.dart`
Expected: PASS。

- [ ] **Step 5: 回归 + analyze + 提交**

```bash
cd linguaquest && flutter test && flutter analyze lib/features/profile/study_plan_settings_screen.dart lib/features/profile/settings_screen.dart lib/features/profile/profile_screen.dart test/features/profile/study_plan_settings_book_test.dart
```
Expected: 全绿；`No issues found!`。

```bash
git add linguaquest/lib/features/profile/study_plan_settings_screen.dart linguaquest/lib/features/profile/settings_screen.dart linguaquest/lib/features/profile/profile_screen.dart linguaquest/test/features/profile/study_plan_settings_book_test.dart
git commit -m "fix(study-plan): 设置/资料/设置页显示当前词书真实名称(不再恒显 HSK 1)"
```

---

### Task 5: 目标完成日期改为按每日词数自动推算（#4）

> 依赖 Task 4（`_wordBookForId` 已按真实 id 匹配，`_save` 取 totalWords 才正确）。

**Files:**
- Modify: `linguaquest/lib/features/profile/study_plan_settings_screen.dart`（删 `_targetFinishDate`/`_pickTargetFinishDate`/`clampStudyPlanPickerInitialDate`/`rejectChangedExpiredTargetFinishDate`；新增 `studyPlanAutoFinishDate`；改 `_save`、`_PlanDateTimeSection`、`_initializeFromState`、`build` 接线）
- Modify: `linguaquest/test/widget_test.dart`（删 2 个废弃 test；改 1 个 save test）
- Test: `linguaquest/test/features/profile/study_plan_auto_date_test.dart`（新建）

**Interfaces:**
- Produces: `DateTime studyPlanAutoFinishDate({required int totalWords, required int dailyNewTarget, required DateTime today})` —— `today.add(Duration(days: (totalWords/dailyNewTarget).ceil().clamp(1, 3650)))`；`dailyNewTarget<=0 || totalWords<=0` 时回退 `today + 30 天`；返回值为 date-only（00:00）。

- [ ] **Step 1: 写失败测试（新文件）**

新建 `linguaquest/test/features/profile/study_plan_auto_date_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/profile/study_plan_settings_screen.dart';

void main() {
  final today = DateTime(2026, 6, 29);

  test('auto finish date = today + ceil(total/daily)', () {
    final d = studyPlanAutoFinishDate(
      totalWords: 100,
      dailyNewTarget: 10,
      today: today,
    );
    expect(d.difference(today).inDays, 10);
  });

  test('ceil rounds up partial days', () {
    final d = studyPlanAutoFinishDate(
      totalWords: 95,
      dailyNewTarget: 10,
      today: today,
    );
    expect(d.difference(today).inDays, 10); // ceil(9.5)=10
  });

  test('fallback to 30 days when total or daily is non-positive', () {
    expect(
      studyPlanAutoFinishDate(totalWords: 0, dailyNewTarget: 10, today: today)
          .difference(today)
          .inDays,
      30,
    );
    expect(
      studyPlanAutoFinishDate(totalWords: 100, dailyNewTarget: 0, today: today)
          .difference(today)
          .inDays,
      30,
    );
  });

  test('result is date-only (midnight)', () {
    final d = studyPlanAutoFinishDate(
      totalWords: 100,
      dailyNewTarget: 10,
      today: DateTime(2026, 6, 29, 13, 45),
    );
    expect(d.hour, 0);
    expect(d.minute, 0);
  });
}
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd linguaquest && flutter test test/features/profile/study_plan_auto_date_test.dart`
Expected: FAIL（`studyPlanAutoFinishDate` 不存在，编译失败）。

- [ ] **Step 3a: 新增 `studyPlanAutoFinishDate`（顶层，紧邻 `_studyPlanDateOnly`）**

```dart
/// Auto-derives the study-plan finish date from the wordbook size and the
/// daily new-word target, so the date stays bound to the daily pace instead
/// of being manually picked.
DateTime studyPlanAutoFinishDate({
  required int totalWords,
  required int dailyNewTarget,
  required DateTime today,
}) {
  final base = _studyPlanDateOnly(today);
  if (totalWords <= 0 || dailyNewTarget <= 0) {
    return base.add(const Duration(days: 30));
  }
  final days = (totalWords / dailyNewTarget).ceil().clamp(1, 3650);
  return base.add(Duration(days: days));
}
```

- [ ] **Step 3b: 删除手填日期相关代码**

删除 `_targetFinishDate` 字段（第46行 `var _targetFinishDate = ...;`）。
删除 `_pickTargetFinishDate` 方法（第335-350行整段）。
删除 `clampStudyPlanPickerInitialDate`（第430-441行整段）。
删除 `rejectChangedExpiredTargetFinishDate`（第391-399行整段）。
删除 `_initializeFromState` 中 `_targetFinishDate = plan.targetFinishDate;`（第228行）。

- [ ] **Step 3c: `build` 接线（189-195）改为不传日期**

```dart
              _PlanDateTimeSection(
                targetFinishDate: _targetFinishDate,
                reminderTimeLabel: _reminderTimeLabel,
                onPickDate: _pickTargetFinishDate,
                onPickTime: _pickReminderTime,
                l10n: l10n,
              ),
```
改为：
```dart
              _PlanDateTimeSection(
                reminderTimeLabel: _reminderTimeLabel,
                onPickTime: _pickReminderTime,
                l10n: l10n,
              ),
```

- [ ] **Step 3d: `_PlanDateTimeSection` 只留提醒时间（791-832）**

整类改为：
```dart
class _PlanDateTimeSection extends StatelessWidget {
  const _PlanDateTimeSection({
    required this.reminderTimeLabel,
    required this.onPickTime,
    required this.l10n,
  });

  final String reminderTimeLabel;
  final VoidCallback onPickTime;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s8,
      ),
      child: _PlanActionRow(
        icon: AppIcons.schedule,
        title: l10n.studyPlanReminderTime,
        subtitle: reminderTimeLabel,
        onTap: onPickTime,
      ),
    );
  }
}
```

- [ ] **Step 3e: `_save` 自动推算日期（255-275）**

将：
```dart
    final today = _dateOnly(DateTime.now());
    final finishDate = _dateOnly(_targetFinishDate);
    final basePlan = state.studyPlan ?? _fallbackPlan(user.uid);
    if (rejectChangedExpiredTargetFinishDate(
      finishDate: finishDate,
      originalFinishDate: basePlan.targetFinishDate,
      today: today,
    )) {
      _showMessage(AppLocalizations.of(context).studyPlanInvalidDate);
      return;
    }

    final plan = basePlan.copyWith(
      uid: user.uid,
      wordBookId: _wordBookId,
      dailyNewTarget: int.parse(_dailyNewController.text.trim()),
      dailyReviewLimit: int.parse(_dailyReviewController.text.trim()),
      targetFinishDate: finishDate,
      reminderTime: _reminderTimeLabel,
      updatedAt: DateTime.now(),
    );
```
改为：
```dart
    final today = _dateOnly(DateTime.now());
    final dailyNew = int.parse(_dailyNewController.text.trim());
    final selectedWordBook = _wordBookForId(state.wordBooks, _wordBookId);
    final finishDate = studyPlanAutoFinishDate(
      totalWords: selectedWordBook?.totalWords ?? 0,
      dailyNewTarget: dailyNew,
      today: today,
    );
    final basePlan = state.studyPlan ?? _fallbackPlan(user.uid);

    final plan = basePlan.copyWith(
      uid: user.uid,
      wordBookId: _wordBookId,
      dailyNewTarget: dailyNew,
      dailyReviewLimit: int.parse(_dailyReviewController.text.trim()),
      targetFinishDate: finishDate,
      reminderTime: _reminderTimeLabel,
      updatedAt: DateTime.now(),
    );
```

> 删除后若 `formatShortDate`、`studyPlanInvalidDate`、`_dateOnly`（如不再被引用）等出现 unused，按 `flutter analyze` 提示清理 import/局部（`_dateOnly` 仍被 `today` 使用，保留）。

- [ ] **Step 4: 跑新测试确认通过**

Run: `cd linguaquest && flutter test test/features/profile/study_plan_auto_date_test.dart`
Expected: PASS。

- [ ] **Step 5: 修现有 widget_test.dart 的受影响用例**

Run（先看失败）：`cd linguaquest && flutter test test/widget_test.dart`
Expected: 编译失败/用例失败（引用了已删的 `clampStudyPlanPickerInitialDate` / `rejectChangedExpiredTargetFinishDate`，及手填日期保存断言）。

修改 `test/widget_test.dart`：
1. 删除整个 `test('study plan picker initial date stays inside selectable bounds', () { ... });`（约第1272行起，调用 `clampStudyPlanPickerInitialDate`）。
2. 删除整个 `test('study plan save rejects a changed expired target date', () { ... });`（约第2843行起，调用 `rejectChangedExpiredTargetFinishDate`）。
3. 在 "study plan save" 成功流用例（约第2783-2840行，`.copyWith(targetFinishDate: DateTime(2026, 1, 15))` 后保存）中，把末尾断言：
   ```dart
       expect(
         studyPlanRepository.savedPlan?.targetFinishDate,
         DateTime(2026, 1, 15),
       );
   ```
   改为（保存后日期应为自动推算，不再等于手填值）：
   ```dart
       final saved = studyPlanRepository.savedPlan!;
       // 自动推算后不再等于手填的 2026-01-15，且晚于 startDate。
       expect(saved.targetFinishDate, isNot(DateTime(2026, 1, 15)));
       expect(saved.targetFinishDate.isAfter(saved.startDate), isTrue);
   ```
   > 该用例若原本断言 `find.text('Target completion date cannot be earlier than today.')` findsNothing —— 现已无日期选择/校验文案，保留该 `findsNothing` 断言仍成立（文案不再出现），无需改动其余部分。

Run（确认通过）：`cd linguaquest && flutter test test/widget_test.dart`
Expected: PASS。

- [ ] **Step 6: analyze + 提交**

```bash
cd linguaquest && flutter analyze lib/features/profile/study_plan_settings_screen.dart test/widget_test.dart test/features/profile/study_plan_auto_date_test.dart
git add linguaquest/lib/features/profile/study_plan_settings_screen.dart linguaquest/test/widget_test.dart linguaquest/test/features/profile/study_plan_auto_date_test.dart
git commit -m "feat(study-plan): 移除手填完成日期,改按每日词数自动推算(与每日词数捆绑)"
```
Expected: `No issues found!`。

---

### Task 6: Campus Sprint 移到 Timed Tests 上方（#5）

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb` + `linguaquest/lib/l10n/app_zh.arb`（新增 `trainingCampusSection`）
- Modify: `linguaquest/lib/features/training/training_screen.dart:44-65`
- Test: `linguaquest/test/features/training/training_layout_test.dart`（新建）

**Interfaces:**
- Produces: 新 l10n `trainingCampusSection`（EN: `"Campus Sprint"`，ZH: `"校园速测"`）。

- [ ] **Step 1: 加 l10n key**

`app_en.arb` 在 `trainingTimedTests` 条目附近新增：
```json
  "trainingCampusSection": "Campus Sprint",
```
`app_zh.arb` 对应新增：
```json
  "trainingCampusSection": "校园速测",
```
（注意保持 JSON 逗号合法；放在已有 `training*` 键附近。）

- [ ] **Step 2: 重新生成 l10n**

Run: `cd linguaquest && flutter gen-l10n`
Expected: 无错误；`lib/l10n/generated/app_localizations*.dart` 出现 `trainingCampusSection` getter。

- [ ] **Step 3: 写失败测试**

新建 `linguaquest/test/features/training/training_layout_test.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/section_header.dart';
import 'package:linguaquest/features/training/training_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

class _FakeAppController extends AppController {
  _FakeAppController(this._state);
  final AppState _state;
  @override
  AppState build() => _state;
}

void main() {
  testWidgets('Campus Sprint section appears above Timed Tests', (
    tester,
  ) async {
    final state = AppState.initial().copyWith(isBootstrapped: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appControllerProvider.overrideWith(() => _FakeAppController(state)),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: const TrainingScreen(),
        ),
      ),
    );
    await tester.pump();

    final campus = find.text('Campus Sprint');
    final timed = find.text('Timed Tests');
    expect(campus, findsWidgets);
    expect(timed, findsOneWidget);
    final campusY = tester.getTopLeft(campus.first).dy;
    final timedY = tester.getTopLeft(timed).dy;
    expect(campusY, lessThan(timedY)); // Campus Sprint 在 Timed Tests 之上
  });
}
```

> EN 下 `trainingCampusSection` 与 `trainingCampusSpeed` 均渲染 "Campus Sprint"，故用 `findsWidgets` + 取 `.first` 的 y 比较；`trainingTimedTests` = "Timed Tests"。若 `TrainingScreen` 在最小 state 下需要更多字段，按 harness 补齐。

- [ ] **Step 4: 跑测试确认失败**

Run: `cd linguaquest && flutter test test/features/training/training_layout_test.dart`
Expected: FAIL（当前 Campus Sprint 在 Timed Tests 分组**内**，y 晚于 header）。

- [ ] **Step 5: 实现（training_screen.dart 44-65）**

当前：
```dart
        SectionHeader(title: l10n.trainingTimedTests),
        const SizedBox(height: AppTokens.s12),
        _TrainingGameList(
          children: [
            _TrainingGameRow(
              icon: AppIcons.school,
              title: l10n.trainingCampusSpeed,
              color: AppTokens.successColor(context),
              onTap: speedLesson == null
                  ? null
                  : () => context.push('/timed-test/${speedLesson.id}'),
            ),
            _TrainingGameRow(
              icon: AppIcons.timer,
              title: l10n.trainingSpeedGame,
              color: AppTokens.mangoColor(context),
              onTap: () => context.push('/training/word-rush'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s24),
```
改为：
```dart
        SectionHeader(title: l10n.trainingCampusSection),
        const SizedBox(height: AppTokens.s12),
        _TrainingGameList(
          children: [
            _TrainingGameRow(
              icon: AppIcons.school,
              title: l10n.trainingCampusSpeed,
              color: AppTokens.successColor(context),
              onTap: speedLesson == null
                  ? null
                  : () => context.push('/timed-test/${speedLesson.id}'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s24),
        SectionHeader(title: l10n.trainingTimedTests),
        const SizedBox(height: AppTokens.s12),
        _TrainingGameList(
          children: [
            _TrainingGameRow(
              icon: AppIcons.timer,
              title: l10n.trainingSpeedGame,
              color: AppTokens.mangoColor(context),
              onTap: () => context.push('/training/word-rush'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s24),
```

> Campus Sprint 路由/限时玩法不变（仍 `/timed-test/${speedLesson.id}`）。

- [ ] **Step 6: 跑测试确认通过 + 回归**

Run: `cd linguaquest && flutter test test/features/training/training_layout_test.dart && flutter test`
Expected: PASS；全量绿。

- [ ] **Step 7: analyze + 提交**

```bash
cd linguaquest && flutter analyze
git add linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/app_zh.arb linguaquest/lib/l10n/generated linguaquest/lib/features/training/training_screen.dart linguaquest/test/features/training/training_layout_test.dart
git commit -m "feat(training): Campus Sprint 独立分组移至 Timed Tests 上方(保留限时)"
```
Expected: `No issues found!`。

---

### Task 7: 清理 IELTS / TOEFL / GRE 残留（#6）

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb` + `app_zh.arb`（删 12 条考试词条 + 改 `discoverForumPost2Title`）
- Modify: `linguaquest/lib/core/utils/ui_labels.dart`（删 IELTS/TOEFL/GRE case 分支）
- Modify: `linguaquest/lib/features/ai_learning/ai_writing_review_screen.dart:33`（`_examTypes`）
- Modify: `linguaquest/test/ai_writing_review_test.dart`（更新断言）

**Interfaces:**
- Produces: `_examTypes = ['General', 'Academic', 'Business', 'Casual']`（无考试名）。

- [ ] **Step 1: 删除 arb 死文案 + 改论坛示例**

在 `app_en.arb` 删除这些键（及其紧随的 `@`-metadata 若有）：
`labelTargetIELTS`、`labelTargetTOEFL`、`labelTargetGRE`、`labelWordTagIELTS`、`labelWordTagTOEFL`、`labelWordTagGRE`、`wordbookNameIELTS`、`wordbookDescIELTS`、`wordbookNameTOEFL`、`wordbookDescTOEFL`、`wordbookNameGRE`、`wordbookDescGRE`。
并改：
```json
  "discoverForumPost2Title": "How do you memorize 'abstract' in IELTS reading?",
```
为：
```json
  "discoverForumPost2Title": "How do you memorize the word 'abstract'?",
```
在 `app_zh.arb` 删除同名 12 键，并改：
```json
  "discoverForumPost2Title": "雅思阅读里怎么记 abstract?",
```
为：
```json
  "discoverForumPost2Title": "怎么记住 abstract 这个词？",
```
> 删除键时确保 JSON 逗号合法（不要留下尾随逗号/缺逗号）。

- [ ] **Step 2: 删除 ui_labels.dart 的 IELTS/TOEFL/GRE case**

删除以下分支（保持其余 `switch` 合法）：
- `displayTarget`（l10n 版，约19-25行）：`case 'IELTS': case '雅思核心词汇': return l10n.labelTargetIELTS;`、`case 'TOEFL': ...`、`case 'GRE': ...` 三段。
- `displayTarget`（无 l10n 版，约47-53行）：`case 'IELTS': case '雅思核心词汇': return '雅思核心词汇';`、`case 'TOEFL': return '托福高频词汇';`、`case 'GRE': return 'GRE 高频词汇';`。
- `displayWordTag`（约298-302行 + 无 l10n 版约340-344行）：IELTS/TOEFL/GRE / 雅思/托福/GRE 分支。
- `displayWordbookTitle`（约375-379行）：`case 'ielts'/'toefl'/'gre'` 三段。
- `displayWordbookDescription`（约404-408行）：`case 'ielts'/'toefl'/'gre'` 三段。

> 删 case 后这些函数的 `default` 兜底接管（返回原值/通用文案），不影响编译。`beginner`/`cet4`/`cet6`/`kaoyan` 等其它 legacy case 保留（不在本次范围）。

- [ ] **Step 3: 改 `_examTypes`（ai_writing_review_screen.dart:33）**

```dart
  static const _examTypes = ['General', 'IELTS', 'CET-4', 'CET-6', 'TOEFL'];
```
改为：
```dart
  static const _examTypes = ['General', 'Academic', 'Business', 'Casual'];
```
> `_submit` 仍以 `_selectedExamType == 'General' ? null : _selectedExamType` 传给 `reviewWriting(examType: ...)`，新值为中性写作风格字符串，语义保持。

- [ ] **Step 4: 重新生成 l10n**

Run: `cd linguaquest && flutter gen-l10n`
Expected: 无错误；生成文件中不再有 `labelTargetIELTS` 等 getter。

- [ ] **Step 5: 更新 ai_writing_review 测试**

修改 `test/ai_writing_review_test.dart`：
- `examType: 'IELTS'`（约202行）→ `examType: 'Academic'`（用例名保持，验证非 General 时 examType 透传）。
- dropdown 断言（约247-251行）：
  ```dart
      expect(find.text('General'), findsOneWidget);
      expect(find.text('IELTS'), findsOneWidget);
      ...
      expect(find.text('TOEFL'), findsOneWidget);
  ```
  改为：
  ```dart
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Academic'), findsOneWidget);
      expect(find.text('Business'), findsOneWidget);
      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('IELTS'), findsNothing);
      expect(find.text('TOEFL'), findsNothing);
  ```
- 点选用例（约297-303行）：`find.text('IELTS')` → `find.text('Academic')`（选中态断言同步改为 Academic）。

- [ ] **Step 6: 跑测试 + 全量回归**

Run: `cd linguaquest && flutter test test/ai_writing_review_test.dart && flutter test`
Expected: PASS；全量绿。

- [ ] **Step 7: grep 校验 + analyze + 提交**

Run: `cd linguaquest && grep -rniE "ielts|toefl|gre|雅思|托福" lib --include="*.dart" --include="*.arb" | grep -v "/generated/"`
Expected: 无"用户可见 UI 文案"命中（注释类如 `wordbook_cover_card.dart` 可顺手清理；若保留注释不算 Fail）。

```bash
cd linguaquest && flutter analyze
git add linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/app_zh.arb linguaquest/lib/l10n/generated linguaquest/lib/core/utils/ui_labels.dart linguaquest/lib/features/ai_learning/ai_writing_review_screen.dart linguaquest/test/ai_writing_review_test.dart
git commit -m "chore(i18n): 清理 IELTS/TOEFL/GRE 死文案 + 写作批改改中性风格 + 论坛示例去考试名"
```
Expected: `No issues found!`。

---

### Task 8: 全量验证 + 设备复测 + 服务端部署

**Files:** 无代码改动（验证 + 部署）。

- [ ] **Step 1: 客户端全量**

Run: `cd linguaquest && flutter analyze && flutter test`
Expected: `No issues found!`；全部测试通过（贴出末尾汇总行）。

- [ ] **Step 2: 服务端全量**

Run: `cd server && dart analyze && dart test`
Expected: `No issues found!`；全部通过。

- [ ] **Step 3: 构建 release APK 并装到 AVD**

Run: `cd linguaquest && flutter build apk --release --dart-define=API_BASE_URL=https://api.vonlan233.top`
Expected: `✓ Built build/app/outputs/flutter-apk/app-release.apk`。
启动 AVD（`LinguaQuest_Pixel_6_API_35`）并 `adb install -r` 安装。

- [ ] **Step 4: 设备复测（抓 logcat）**

逐项验证并记录：
- #1 home 汉堡图标在浅色背景上为清晰深色。
- #3 用测试账号（2862597783@qq.com / 114514）登录，切换 HSK1→HSK2、中文→English：计划 Hero、设置页、个人资料处均显示所选词书名（不再恒 HSK 1）。
- #3 snackbar：复现"Unable to switch wordbook right now"。开 `adb logcat | grep -iE "flutter|dio|exception"` 抓切换瞬间日志。**若复现到确定性异常**（如某写请求 4xx/超时），记录后回到对应 task 补针对性修复并重跑；**若不复现**（多次切换均成功反映），记为"已随显示层修复消除/瞬时网络"，在测试记录中说明。
- #4 设置页无手填完成日期项；改每日词数后保存，剩余天数随之变化。
- #5 Campus Sprint 在 Timed Tests 之上，点击仍进限时测。
- #6 写作批改下拉为 General/Academic/Business/Casual；无 IELTS/TOEFL。

- [ ] **Step 5: 部署服务端（用户已预授权）**

部署 `server/` 当前分支到 `api.vonlan233.top`，并设置环境变量 `AI_CLOZE_MODEL=<更快模型>`（按 OpenCode Zen 可用目录选择；不确定则留空，回退默认模型——不退化）。按项目既有部署方式执行（若仓库无部署脚本，则在本步骤询问用户确切部署命令/通道后执行）。

- [ ] **Step 6: 部署后实测 cloze**

```bash
TOKEN=$(curl -s -X POST https://api.vonlan233.top/auth/login -H "Content-Type: application/json" -d '{"email":"2862597783@qq.com","password":"114514"}' --max-time 15 | python3 -c "import sys,json;print(json.load(sys.stdin)['token'])")
curl -s -X POST https://api.vonlan233.top/ai/cloze -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d '{"prompt":"Write a SHORT passage (2-3 sentences) with 3-4 blanks using these words: hello, world","targetWord":"hello","targetLanguage":"en"}' -w "\nHTTP=%{http_code} TIME=%{time_total}s\n" --max-time 70 | head -c 400
```
Expected: `HTTP=200`，TIME 稳定（设了更快模型应 <20s；否则 <50s）；设备上 Passage Cloze 不再"网络请求失败"。

---

## 任务依赖与执行顺序

1（独立）→ 2（独立）→ **3 → 4 → 5**（同域顺序，4/5 依赖 3，5 依赖 4）→ 6（独立，动 l10n）→ 7（独立，动 l10n）→ 8（验证+部署）。6 与 7 都 `flutter gen-l10n`，顺序执行无冲突。
