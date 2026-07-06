# Cycle 10 Part 1：QA3 Bug 修复（A/C/B/E/F/G/H）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复第三轮 QA 的 7 个客户端/服务端真 bug（收藏帖 404、作者 Profile 接线、收藏计数、About 版本号、首页/个人页词书一致、主题控件换行、提醒文案）。

**Architecture:** 客户端 Flutter（Riverpod + go_router）为主，1 项 server（Dart shelf + Postgres）。沿用现有 repository/provider 模式。

**Tech Stack:** Flutter 3.41.6、flutter_riverpod、go_router、package_info_plus（新增）、Dart shelf/postgres。

## Global Constraints
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 每个 task 明确列出的文件（**禁 `git add -A/./-u`**——仓库有无关 untracked：`.DS_Store`、`__pycache__`、`docs/testing/*`、`pubspec.yaml` 版本改动 1.0.3+3）。
- flutter 命令在 `linguaquest/`，server 在 `server/`。
- 改 `.arb` 必须跑 `flutter gen-l10n` 并把生成的 `lib/l10n/generated/*.dart` 一并 commit；三 arb（en/ms/zh）同步。
- 现有测试全绿：`flutter test`/`flutter analyze`；`dart test`/`dart analyze`（server）。
- 正式 APK 用 `flutter build apk --release --dart-define=API_BASE_URL=https://api.vonlan233.top` 构建。
- **不含 Bug D**（Privacy 返回 Profile 卡加载圈）——根因在当前代码未坐实（profile/privacy 均无 loading 态），移出待设备复现。
- 源：`docs/superpowers/specs/2026-07-04-cycle10-studymap-restore-qa3-fixes.md`。

---

### Task 1: 论坛帖详情按 id 加载 + 作者 Profile 接线（Bug A + C 合并）

**合并理由：** A 和 C 都改 `forum_post_detail_screen.dart`，拆开会 old_string 锚点漂移。

**Files:**
- Modify: `linguaquest/lib/features/discover/forum_post_detail_screen.dart`
- Modify: `linguaquest/lib/features/discover/community_screen.dart`
- Test: `linguaquest/test/features/discover/forum_detail_favorites_test.dart`（新建）

**Interfaces（先读实际代码确认）：**
- `ForumRepository.getPost(String id) → Future<ForumPost>`（抽象方法，`forum_repository.dart`，Cycle 9 已用；**用实际方法名，勿假设 getForumPost**）
- `ForumPost.authorId` / `ForumComment.authorId`（`data/models/forum.dart`，均已存在）
- 路由 `/profile/:userId`（`app_router.dart`）→ `context.push('/profile/${authorId}')`（`go_router`，community_screen 已 import，forum_post_detail_screen 需确认 import）

**根因（已核实）：**
- **A**：`forum_post_detail_screen.dart` 详情只从内存 `state.forumPosts` 按 id 查帖（`ref.watch(appControllerProvider.select((s) => s.forumPosts.where((p)=>p.id==widget.postId).firstOrNull))`）；从 My Favorites 直进时列表空 → null → "Post not found"。
- **C**：`community_screen.dart` 卡片作者头像/昵称行无点击；`forum_post_detail_screen.dart` 的 `_PostBody` 不显示作者；`_CommentCard` 评论作者无点击。

**实现要求（A —— 用最小 Edit，勿重写整个文件）：**
1. 先 Read `forum_post_detail_screen.dart` 全文，确认现有 State 类的字段/方法（`_loadComments`、`_submitComment`、`createForumComment`/`toggleForumLike`/`reportForumPost` 等实际名——**照抄现有，勿臆造**）。
2. State 类加字段 `ForumPost? _post; bool _loadingPost = true; bool _postNotFound = false;`。
3. `initState` 除现有 `_loadComments()` 外，加 `_loadPost()`：`try { final repo = ref.read(forumRepositoryProvider); final post = await repo.getPost(widget.postId); if (mounted) setState(() { _post = post; _loadingPost = false; }); } catch (_) { if (mounted) setState(() { _loadingPost = false; _postNotFound = true; }); }`。
4. 把原来 `ref.watch(...forumPosts...firstOrNull)` 的 `post` 来源改为局部 `_post`；build 开头：`if (_loadingPost) return <现有 Scaffold+CircularProgressIndicator>; if (_postNotFound || _post == null) return <现有 Post-not-found 空态 widget>;`（复用文件里现有的 AppBar / 空态组件，勿新造 MascotEmptyState 除非文件已用它）。
5. 其余 build 逻辑（评论列表、输入栏、点赞/收藏/举报 action）保持不变，只把 `post` 引用指向 `_post!`。

**实现要求（C —— 3 处加 GestureDetector）：**
1. `community_screen.dart` 卡片作者行（头像 `_AuthorAvatar(name: post.authorName)` + 昵称 Text 所在的 Row/Flexible）：外包 `GestureDetector(onTap: () => context.push('/profile/${post.authorId}'), child: <原 Row>)`。
2. `forum_post_detail_screen.dart` `_PostBody`：在 tag/title 上方新增作者行（头像 + 昵称），包 `GestureDetector(onTap: () => context.push('/profile/${post.authorId}'))`。若 `_PostBody` 无头像组件，复用 community_screen 的 `_AuthorAvatar`（或内联 CircleAvatar 取首字母）。
3. `forum_post_detail_screen.dart` `_CommentCard`：评论作者昵称 Text 包 `GestureDetector(onTap: () => context.push('/profile/${comment.authorId}'))`。
4. 确认 `forum_post_detail_screen.dart` 顶部 `import 'package:go_router/go_router.dart';`，无则加。

- [ ] **Step 1: 写失败测试**（`test/features/discover/forum_detail_favorites_test.dart`）

用 fake `ForumRepository`（`listPosts` 返回 `[]` 模拟没进过 Community，`getPost('fav-1')` 返回一个帖），`ProviderScope(overrides: [forumRepositoryProvider.overrideWithValue(fakeRepo)])` 包 `ForumPostDetailScreen(postId: 'fav-1')`，`pumpAndSettle` 后断言帖标题可见、`find.text('Post not found')` findsNothing。**先读现有 forum/community 测试文件确认 fake repo 需实现的完整接口、ProviderScope 与 MaterialApp+localizations 的搭法，照其风格。**

- [ ] **Step 2: 运行验证失败**

Run: `cd linguaquest && flutter test test/features/discover/forum_detail_favorites_test.dart`
Expected: FAIL（当前从空 forumPosts 查 → 显示 Post not found）

- [ ] **Step 3: 实现 A + C**（按上方"实现要求"，最小 Edit）

- [ ] **Step 4: 运行验证通过**

Run: `cd linguaquest && flutter test test/features/discover/forum_detail_favorites_test.dart && flutter analyze`
Expected: PASS；analyze 无 error

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/features/discover/forum_post_detail_screen.dart lib/features/discover/community_screen.dart test/features/discover/forum_detail_favorites_test.dart
git commit -m "fix(discover): 帖详情按 id 拉单帖(修从收藏进404) + 作者头像/昵称/评论者可点进 Public Profile"
```

---

### Task 2: 收藏列表评论计数改实时子查询（Bug B，server，部署项）

**Files:**
- Modify: `server/lib/src/database.dart`（`listFavoritedPostsByUser`，约 :2283-2298）

**根因（已核实）：** `listFavoritedPostsByUser` 用 `SELECT p.*` 返回表存 `comment_count`（过时）；Cycle 9 已把 `listForumPosts`/`getForumPost` 改成实时子查询。收藏端点是遗漏。

**验证策略：** server 无 DB 集成测试框架（现有 `forum_favorites_test.dart` 仅测 DTO 纯函数，不连库）。故本 task **不写占位单测**，靠 `dart analyze`（对照 `listForumPosts` 已验证的枚举列写法）+ 部署后 curl 对比验证（与 Cycle 9 验 2.1 同法）。

- [ ] **Step 1: 读现状对照**

Run: `cd server && grep -n "comment_count\|SELECT p\.\*\|listForumPosts\|listFavoritedPostsByUser" lib/src/database.dart`
确认 `listForumPosts` 的实时子查询写法，作为 `listFavoritedPostsByUser` 的口径样板。

- [ ] **Step 2: 改 SQL**（`database.dart` `listFavoritedPostsByUser`）

把 `SELECT p.*, u.name AS author_name` 改为**枚举列 + 实时子查询 comment_count**（列清单与 `listForumPosts` 完全一致口径）：
```sql
SELECT p.id, p.author_id, p.title, p.body, p.tag, p.status,
       p.like_count,
       (SELECT COUNT(*) FROM forum_comments fc
        WHERE fc.post_id=p.id AND fc.status='approved') AS comment_count,
       p.created_at, p.updated_at, u.name AS author_name
FROM forum_posts p
JOIN forum_favorites f ON f.post_id = p.id
LEFT JOIN users u ON u.id = p.author_id
WHERE f.user_id = @userId AND p.status = 'approved'
ORDER BY p.created_at DESC
```
（**先读实际 old SQL 作精确 old_string；列名以 forum_posts 实际 schema 为准，对照 listForumPosts 枚举的列。**）

- [ ] **Step 3: 验证**

Run: `cd server && dart analyze lib/src/database.dart`
Expected: No issues found
（评论计数正确性在部署后 curl 验证：`/forum/favorites` 的 commentCount == `/forum/posts` == 详情。）

- [ ] **Step 4: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server
git add lib/src/database.dart
git commit -m "fix(server): 收藏列表 commentCount 改实时 COUNT(approved) 子查询，与帖列表/详情一致"
```

---

### Task 3: About 版本号动态读（Bug E）

**Files:**
- Modify: `linguaquest/pubspec.yaml`（加 `package_info_plus`）
- Modify: `linguaquest/lib/features/profile/about_screen.dart`（版本显示处，约 :74-79）
- Modify: `linguaquest/lib/l10n/app_en.arb`（`aboutVersion` :896）、`app_ms.arb`、`app_zh.arb`（同键，改带参 `{version}`）
- Regen: `lib/l10n/generated/*.dart`（gen-l10n）
- Test: `linguaquest/test/features/profile/about_version_test.dart`（新建）

**根因（已核实）：** `about_screen.dart` 用 `l10n.aboutVersion`（`app_en.arb:896` 硬编码 "LinguaQuest · Version 1.0.0"），与 pubspec `1.0.3+3` 脱节。

- [ ] **Step 1: 加依赖**

Run: `cd linguaquest && flutter pub add package_info_plus`
Expected: pubspec.yaml/lock 更新，pub get 成功

- [ ] **Step 2: 写失败测试**（`test/features/profile/about_version_test.dart`）

`PackageInfo.setMockInitialValues(appName:'LinguaQuest', packageName:'com.example.linguaquest', version:'1.0.3', buildNumber:'3', buildSignature:'')`，pump `AboutScreen`（en locale），`await tester.pump(const Duration(milliseconds: 300))`，断言 `find.text('LinguaQuest · Version 1.0.3')` findsOneWidget、`...1.0.0` findsNothing。**先读现有 about/profile 测试确认 AboutScreen 的构造与 localizations 搭法。**

- [ ] **Step 3: 运行验证失败**

Run: `cd linguaquest && flutter test test/features/profile/about_version_test.dart`
Expected: FAIL（当前硬编码 1.0.0）

- [ ] **Step 4: 改 arb（三个）+ about_screen**

三 arb `aboutVersion` 改带参（保留各自前缀）：en `"LinguaQuest · Version {version}"`、zh `"词境星球 · 版本 {version}"`、ms `"LinguaQuest · Versi {version}"`（**先读三 arb 的实际当前值作精确 old_string；en 需补 `@aboutVersion` placeholders 元数据**）。
`about_screen.dart`：`import 'package:package_info_plus/package_info_plus.dart';`；把 `Text(l10n.aboutVersion, ...)` 换成 `FutureBuilder<PackageInfo>(future: PackageInfo.fromPlatform(), builder: (c, snap) => Text(l10n.aboutVersion(snap.data?.version ?? ''), style: <原 style>))`（**读实际 :74-79 作 old_string；保留原 style**）。

- [ ] **Step 5: gen-l10n + 验证**

Run: `cd linguaquest && flutter gen-l10n && flutter test test/features/profile/about_version_test.dart && flutter analyze`
Expected: 生成成功；测试 PASS；analyze 无 error

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/features/profile/about_screen.dart lib/l10n/app_en.arb lib/l10n/app_ms.arb lib/l10n/app_zh.arb lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_en.dart lib/l10n/generated/app_localizations_ms.dart lib/l10n/generated/app_localizations_zh.dart pubspec.yaml pubspec.lock test/features/profile/about_version_test.dart
git commit -m "fix(about): 版本号改 package_info_plus 动态读(随 pubspec)，aboutVersion 改带参"
```

---

### Task 4: 首页/个人页词书名统一（Bug F）

**Files:**
- Modify: `linguaquest/lib/features/profile/profile_screen.dart`（build 顶部加 localeCode + Plan 项 value，约 :29-34 与 :88-93）
- Test: `linguaquest/test/features/profile/profile_wordbook_consistency_test.dart`（新建）

**根因（已核实）：** 首页 `home_screen.dart` 用 `state.currentWordBook?.nameFor(localeCode)`；个人页 `profile_screen.dart:91` 用 `state.currentStudyBook.name`（`app_state.dart:197` getter 走 `book.title` 英文/回退 `studyBookInfoForId` 硬编码）→ 首页/个人页不一致。

**实现要求：** profile_screen `build` 顶部加 `final localeCode = Localizations.localeOf(context).languageCode;`；把 Plan 项 `value: state.currentStudyBook.name` 改为 `value: state.currentWordBook?.nameFor(localeCode) ?? state.currentStudyBook.name`（与 home 同源；fallback 保留原值防空）。**先读 profile_screen 实际 :29-34 与 :88-93 作精确 old_string；确认 `_SettingsItem` 的 value 参数名。**

- [ ] **Step 1: 写失败测试**

override `appControllerProvider` 为含一个 `currentWordBookId` + 对应 `WordBook`（title 'HSK 2'）的 state，分别 pump HomeScreen 与 ProfileScreen（同 state、同 locale），断言两屏都显示同一 `nameFor(locale)` 值。**先读现有 profile/home widget 测试确认 state override 与路由搭法（GoRouter 或 MaterialApp）。** 若整屏 pump 过重，可只断言 profile 项显示 `currentWordBook.nameFor(locale)` 而非 `currentStudyBook.name`（当二者不同时）。

- [ ] **Step 2: 运行验证失败**

Run: `cd linguaquest && flutter test test/features/profile/profile_wordbook_consistency_test.dart`
Expected: FAIL

- [ ] **Step 3: 实现**（profile_screen 改 value + localeCode）

- [ ] **Step 4: 运行验证通过**

Run: `cd linguaquest && flutter test test/features/profile/profile_wordbook_consistency_test.dart && flutter analyze`
Expected: PASS；analyze 无 error

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/features/profile/profile_screen.dart test/features/profile/profile_wordbook_consistency_test.dart
git commit -m "fix(profile): 词书名统一走 currentWordBook.nameFor(locale)，与首页一致"
```

---

### Task 5: Theme 控件改垂直三行（Bug G）

**Files:**
- Modify: `linguaquest/lib/features/profile/settings_screen.dart`（`_ThemeSettingCard`，约 :253-305）
- Test: `linguaquest/test/features/profile/settings_theme_layout_test.dart`（新建）

**根因（已核实）：** `_ThemeSettingCard` 横向 `SegmentedButton<ThemeMode>` 三等分，"Follow System" 窄格被挤成多行。dark mode 是活的功能，保留。subtitle 键 `settingsThemeSystemSubtitle`/`LightSubtitle`/`DarkSubtitle` **已存在**（arb :262/264/266）。

**实现要求：** 把 `SegmentedButton<ThemeMode>(...)` 换成 3 个 `RadioListTile<ThemeMode>`（System/Light/Dark，各 `value`/`groupValue: themeMode`/`onChanged: (m){ if(m!=null) onChanged(m); }`/`title: Text(l10n.settingsThemeX)`/`subtitle: Text(l10n.settingsThemeXSubtitle)`/`secondary: Icon(...)`/`contentPadding: EdgeInsets.zero`），中间 `Divider`。保留卡片标题 Row（icon + `l10n.settingsTheme`）。**读实际 :253-305 作精确 old_string。注意 RadioListTile 图标用 `secondary:` 不是 `leading:`。**

- [ ] **Step 1: 写失败测试**

pump `_ThemeSettingCard(themeMode: ThemeMode.system, onChanged: (m){...})`（若 `_ThemeSettingCard` 私有，测 SettingsScreen 或把断言放在可见 widget 层）。断言 `find.byType(RadioListTile<ThemeMode>)` findsNWidgets(3)、`find.byType(SegmentedButton<ThemeMode>)` findsNothing、`find.text('Follow System')` findsOneWidget；tap 第 2 个 radio → onChanged 收到 `ThemeMode.light`。**若 `_ThemeSettingCard` 私有无法直接构造，改为 pump 完整 SettingsScreen（需 provider override）并断言同上。**

- [ ] **Step 2: 运行验证失败**

Run: `cd linguaquest && flutter test test/features/profile/settings_theme_layout_test.dart`
Expected: FAIL（当前是 SegmentedButton）

- [ ] **Step 3: 实现**（SegmentedButton → 3× RadioListTile）

- [ ] **Step 4: 运行验证通过**

Run: `cd linguaquest && flutter test test/features/profile/settings_theme_layout_test.dart && flutter analyze`
Expected: PASS；analyze 无 error

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/features/profile/settings_screen.dart test/features/profile/settings_theme_layout_test.dart
git commit -m "fix(settings): 主题选择改垂直三行 RadioListTile，Follow System 不再挤压换行"
```

---

### Task 6: Daily Reminder 文案（Bug H）

**Files:**
- Modify: `linguaquest/lib/features/profile/settings_screen.dart`（:43 拼接处）
- Modify: 三 arb（新增 `settingsReminderDisplay`）
- Regen: `lib/l10n/generated/*.dart`
- Test: `linguaquest/test/features/profile/settings_reminder_display_test.dart`（新建）

**根因（已核实）：** `settings_screen.dart:43` `'${l10n.commonDay} ${state.reminderSettings.formattedTime}'`，`commonDay`="day" → "day 20:00"。`settingsReminderOff`、`formattedTime`、`reminderSettings.enabled` 均已存在。

**实现要求：** 三 arb 新增 `settingsReminderDisplay`：en `"Daily · {time}"`、zh `"每日 · {time}"`、ms `"Harian · {time}"`（带 `{time}` placeholder，en 补 `@settingsReminderDisplay` 元数据）。`settings_screen.dart:43` 改 `l10n.settingsReminderDisplay(state.reminderSettings.formattedTime)`。**读实际 :39-46 作 old_string。**

- [ ] **Step 1: 写失败测试**

override `appControllerProvider` 为 `reminderSettings.enabled==true`、`formattedTime` 产出 "20:00" 的 state，pump SettingsScreen（en），断言 `find.text('Daily · 20:00')` findsOneWidget、`find.text('day 20:00')` findsNothing。**读 DailyReminderSettings(:59) 构造确认造 20:00 的字段（hour/minute 或别的）。**

- [ ] **Step 2: 运行验证失败**

Run: `cd linguaquest && flutter test test/features/profile/settings_reminder_display_test.dart`
Expected: FAIL（当前 "day 20:00"）

- [ ] **Step 3: 改 arb + settings_screen + gen-l10n**

- [ ] **Step 4: 运行验证通过**

Run: `cd linguaquest && flutter gen-l10n && flutter test test/features/profile/settings_reminder_display_test.dart && flutter analyze`
Expected: 生成成功；PASS；analyze 无 error

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/features/profile/settings_screen.dart lib/l10n/app_en.arb lib/l10n/app_ms.arb lib/l10n/app_zh.arb lib/l10n/generated/app_localizations.dart lib/l10n/generated/app_localizations_en.dart lib/l10n/generated/app_localizations_ms.dart lib/l10n/generated/app_localizations_zh.dart test/features/profile/settings_reminder_display_test.dart
git commit -m "fix(settings): Daily Reminder 文案改 'Daily · {time}'，不再拼 commonDay"
```

---

## 全量验证（所有 task 后）
Run: `cd linguaquest && flutter analyze && flutter test`；`cd server && dart analyze && dart test`
Expected: 全绿。

## 部署（Task 2 server B）
`cd server && rsync + deploy/vps_deploy.sh`（health 200；curl `/forum/favorites` 带 token 验 commentCount 一致）。

## 说明
- **Bug D 移出**：根因未坐实（profile/privacy 无 loading 态），待连后端设备复现确认（可能环境误报或 public-profile 混淆），届时归 Cycle 11 或补 task。
- 每个 task 的完整 old/new 由 implementer 读实际代码落实（本 plan 给精确文件:行号、已核实的根因/方案/API 名、测试行为）——避免草案臆造的方法名/键。所有引用的 getter/键（getPost、currentWordBook、settingsThemeXSubtitle、settingsReminderOff、formattedTime）均已核实存在。
