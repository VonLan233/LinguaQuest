# Cycle 9 第二轮 QA + 设备复测修复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复 8 项（搜索精确拼音、地图视野、社区评论计数、阅读 AI 真接入、阅读筛选标题、积分文案、发帖校验、Me 标签截断）。

**Architecture:** 多为独立小改；2.1 服务端 SQL、2.2 服务端 env 配置（无代码），其余客户端。

**Tech Stack:** Flutter 3.41.6 + Riverpod + go_router；Dart shelf + PostgreSQL；ARB l10n（en/ms/zh）。

## Global Constraints

- 回复中文；commit **不带 Co-Authored-By**；每任务只 `git add` 本任务列出的路径，**禁 `git add -A/./-u`**。
- flutter 在 `linguaquest/`，server 在 `server/`。改 `.arb` 跑 `flutter gen-l10n` 并提交 `lib/l10n/generated/`；三 arb 同步。
- 每任务收尾跑相关测试 + analyze 并贴真实输出。
- 需部署项（2.1 代码 / 2.2 env）在 T7 统一部署（rsync + `deploy/vps_deploy.sh`，保留远程 `.env/.env.prod` + db 卷）。
- server 无 DB 测试 harness（现有 forum 测试均为纯逻辑），SQL 改动靠 `dart analyze` + 部署后设备复验。
- 不动 Cycle 7/8 修复。

---

## Task 1: 搜索精确拼音置顶（C）

**Files:**
- Modify: `linguaquest/lib/data/dictionary_search.dart`（`_matchPinyin` :247-253、`_matchRank` :255-266）
- Test: `linguaquest/test/dictionary_search_test.dart`（新增用例；`_word` helper 已有 `phonetic` 可选参数，来自 Cycle 8）

**背景：** `_matchPinyin` 只做子串匹配，`_matchRank` 对所有 '汉字拼音' 返回 rank 1 → 爱(精确)与 太/奶(子串)同 rank，爱未置顶。

- [ ] **Step 1: 写失败测试**

在 `test/dictionary_search_test.dart` 的 `group('dictionary_search', () {` 内加：
```dart
    test('P-pinyin-exact: 精确拼音 ai 置顶于子串拼音（爱 在 太 之前）', () {
      final ai = _word(id: 'ai', text: '爱', meaning: '爱', phonetic: 'ài');
      final tai = _word(id: 'tai', text: '太', meaning: '太', phonetic: 'tài');
      // 列表故意把子串匹配的 太 放前面，验证排序而非顺序侥幸。
      final book = _wordBook(id: 'hsk1', words: [tai, ai]);

      final results = searchDictionaryWords(
        wordBooks: [book],
        currentWordBookId: 'hsk1',
        scope: DictionarySearchScope.allWordBooks,
        query: 'ai',
      );

      expect(results.first.word.id, 'ai');
      expect(results.first.matchedBy, '汉字拼音精确');
      final taiResult = results.firstWhere((r) => r.word.id == 'tai');
      expect(taiResult.matchedBy, '汉字拼音'); // 子串
    });
```

- [ ] **Step 2: 跑测试确认失败**

Run: `cd linguaquest && flutter test test/dictionary_search_test.dart --plain-name "P-pinyin-exact"`
Expected: FAIL（当前 太 可能排在 爱 前，或 matchedBy 不是 '汉字拼音精确'）。

- [ ] **Step 3: `_matchPinyin` 区分精确/子串**

`dictionary_search.dart:247-253` 替换为：
```dart
_SearchMatch? _matchPinyin(String label, String value, String query) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  // 去声调后匹配：'ài' -> 'ai'，'tài' -> 'tai'。精确=整串相等，否则子串。
  final normalized = normalizePinyin(trimmed);
  if (!normalized.contains(query)) return null;
  final matchLabel = normalized == query ? '汉字拼音精确' : label;
  return _SearchMatch(label: matchLabel, preview: trimmed);
}
```

- [ ] **Step 4: `_matchRank` 精确置顶、子串降级**

`_matchRank`（:255-266）里，把现有 `if (result.matchedBy == '汉字拼音') return 1;` 那行替换为两行：
```dart
  if (result.matchedBy == '汉字拼音精确') return 1;
  if (result.matchedBy == '汉字拼音') return 2;
```

- [ ] **Step 5: 跑测试确认通过 + 全量**

Run: `cd linguaquest && flutter test test/dictionary_search_test.dart && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。旧拼音用例（Cycle 8 的 P-pinyin）仍绿（爱 仍是首条，现 matchedBy 变 '汉字拼音精确'——若旧用例断言 '汉字拼音' 则据实更新为精确）。

- [ ] **Step 6: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/data/dictionary_search.dart linguaquest/test/dictionary_search_test.dart
git commit -m "fix(search): 精确拼音匹配置顶（爱 命中 ai 排首），子串拼音降级"
```

---

## Task 2: 地图初始视野（F）

**Files:**
- Modify: `linguaquest/lib/features/map/language_map_screen.dart:95-96`（initialCenter/initialZoom）

**背景：** Cycle 8 的标签换行方案无效——真因是 `initialCenter LatLng(20,80)`+`zoom 2.2` 下 Japan(lng 138) 贴右缘、标签居中锚定溢出屏幕。改初始视野让 Asia 各 pin 有边距。无自动测试；由控制者在 T7 设备复验微调。

- [ ] **Step 1: 调整初始视野**

`language_map_screen.dart:95-96` 的 MapOptions：
```dart
  options: const MapOptions(
    initialCenter: LatLng(20, 80),
    initialZoom: 2.2,
```
改为：
```dart
  options: const MapOptions(
    initialCenter: LatLng(20, 100),
    initialZoom: 2.0,
```
（其余 minZoom/maxZoom 不变；保留 Cycle 8 的标签 ConstrainedBox。）

- [ ] **Step 2: analyze + 全量测试**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。

- [ ] **Step 3: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/map/language_map_screen.dart
git commit -m "fix(map): 调整初始视野让 Japanese 标签离屏幕右缘有余量"
```
> 视觉验收在 T7 设备复测：Japanese (日本語) 标签完整、Chinese/Malay 仍可见。若仍裁切，控制者微调 center/zoom 并追加 commit。

---

## Task 3: 阅读筛选后标题跟随主题（2.3）

**Files:**
- Modify: `linguaquest/lib/features/reading/reading_list_screen.dart:102`
- Modify: `linguaquest/lib/l10n/app_en.arb`、`app_ms.arb`、`app_zh.arb`（新增 `readingArticlesForTheme`）
- Regenerate: `linguaquest/lib/l10n/generated/`
- Test: `linguaquest/test/features/reading/reading_title_filter_test.dart`（新建，纯逻辑镜像）

**背景：** `reading_list_screen.dart:102` `SectionHeader(title: l10n.readingAllArticles)` 硬编码，不跟随 `_themeFilter`。

- [ ] **Step 1: 三 arb 新增 `readingArticlesForTheme`（放 `readingAllArticles` 之后）**

`app_en.arb`（:1121 `readingAllArticles` 之后）：
```json
  "readingArticlesForTheme": "{theme} articles",
```
`app_ms.arb`（:1035 之后）：
```json
  "readingArticlesForTheme": "Artikel {theme}",
```
`app_zh.arb`（:1035 之后）：
```json
  "readingArticlesForTheme": "{theme}文章",
```

- [ ] **Step 2: gen-l10n**

Run: `cd linguaquest && flutter gen-l10n`
Expected: `readingArticlesForTheme(Object theme)` 可用。

- [ ] **Step 3: 标题动态化**

`reading_list_screen.dart:102` 把：
```dart
              SectionHeader(title: l10n.readingAllArticles),
```
改为：
```dart
              SectionHeader(
                title: _themeFilter == null
                    ? l10n.readingAllArticles
                    : l10n.readingArticlesForTheme(
                        readingThemeLabel(l10n, _themeFilter!),
                      ),
              ),
```
（`readingThemeLabel(AppLocalizations, String)` 已在 `reading_labels.dart:4` 定义并已 import。）

- [ ] **Step 4: 写测试（标题选择逻辑）**

新建 `test/features/reading/reading_title_filter_test.dart`（镜像标题选择规则）：
```dart
import 'package:flutter_test/flutter_test.dart';

// 镜像 reading_list_screen 的标题选择：无主题筛选→all，否则→"{theme} articles"。
String titleFor(String? themeFilter, String allLabel, String themedLabel) =>
    themeFilter == null ? allLabel : themedLabel;

void main() {
  test('无主题筛选用 All articles', () {
    expect(titleFor(null, 'All articles', 'Travel articles'), 'All articles');
  });
  test('选了主题用 {theme} articles', () {
    expect(titleFor('travel', 'All articles', 'Travel articles'),
        'Travel articles');
  });
}
```

- [ ] **Step 5: 全量测试 + analyze**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。

- [ ] **Step 6: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/reading/reading_list_screen.dart linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/app_ms.arb linguaquest/lib/l10n/app_zh.arb linguaquest/lib/l10n/generated/ linguaquest/test/features/reading/reading_title_filter_test.dart
git commit -m "fix(reading): 筛选主题后标题跟随（{theme} articles）"
```

---

## Task 4: l10n 文案修正（2.4 Go 文案 + 2.6 Me 标签）

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb`、`app_ms.arb`、`app_zh.arb`（`discoverGoComplete` en/ms；`profileLearnedWords` en/ms/zh）
- Regenerate: `linguaquest/lib/l10n/generated/`

**背景：** ①`discoverGoComplete` en "Go +{points} XP" 让人误以为点击即领（三态逻辑已存在，仅文案误导；zh "去完成 +{points} XP" 已好）。②`profileLearnedWords` en "Words Learned" 比 Home "Learned" 长，窄屏 Me 页截断。

- [ ] **Step 1: 改 `discoverGoComplete`（2.4）**

`app_en.arb:326`：`"discoverGoComplete": "Go +{points} XP",` → `"discoverGoComplete": "Complete for +{points} XP",`
`app_ms.arb:326`：`"discoverGoComplete": "Pergi +{points} XP",` → `"discoverGoComplete": "Lengkapkan untuk +{points} XP",`
`app_zh.arb:326`：`"去完成 +{points} XP"` **不改**（已明确）。

- [ ] **Step 2: 改 `profileLearnedWords`（2.6）**

`app_en.arb:232`：`"profileLearnedWords": "Words Learned",` → `"profileLearnedWords": "Learned",`
`app_ms.arb:232`：`"profileLearnedWords": "Perkataan Dipelajari",` → `"profileLearnedWords": "Dipelajari",`
`app_zh.arb:232`：`"profileLearnedWords": "已学单词",` → `"profileLearnedWords": "已学",`

- [ ] **Step 3: gen-l10n + 全量测试 + analyze**

Run: `cd linguaquest && flutter gen-l10n && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。若有旧断言 "Go +5 XP" 或 "Words Learned" 的用例，据实更新。

- [ ] **Step 4: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/app_ms.arb linguaquest/lib/l10n/app_zh.arb linguaquest/lib/l10n/generated/
git commit -m "fix(i18n): 积分任务未完成文案改'Complete for'；Me 统计标签缩短为 Learned"
```

---

## Task 5: 发帖表单 inline 校验（2.5）

**Files:**
- Modify: `linguaquest/lib/features/discover/forum_compose_screen.dart`
- Test: `linguaquest/test/features/discover/forum_compose_validate_test.dart`（新建）

**背景：** 标题/正文用普通 `TextField`，空表单校验塞进页面中部 `_errorMessage`（:168-176），点 Publish 不滚动、易忽略。改 `Form`+`TextFormField`+`validator`，错误显示在对应输入框下方。文件现为全硬编码英文，**校验串保持硬编码英文以维持一致**（不引半套 l10n）。

- [ ] **Step 1: 加 Form key + 改 _submit 用 validate**

`forum_compose_screen.dart:21-26` 的 state 字段区，去掉 `String? _errorMessage;`，加 `final _formKey = GlobalKey<FormState>();`：
```dart
class _ForumComposeScreenState extends ConsumerState<ForumComposeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTag = 'General';
  bool _submitting = false;
```

`_submit()`（:35-78）替换为：
```dart
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    setState(() => _submitting = true);
    try {
      final post = await ref
          .read(appControllerProvider.notifier)
          .createForumPost(title: title, body: body, tag: _selectedTag);
      if (!mounted) return;
      if (post != null) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to publish post. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
```

- [ ] **Step 2: body 用 Form 包裹，TextField→TextFormField + validator**

`build` 的 `body: SafeArea(child: ListView(...))`（:97-185）：把 `ListView` 外层包一层 `Form(key: _formKey, child: ...)`，即 `body: SafeArea(child: Form(key: _formKey, child: ListView(...)))`。

标题 `TextField`（:109-117）改为：
```dart
            TextFormField(
              controller: _titleController,
              maxLength: 200,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'What is your question or topic?',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) return 'Please enter a title.';
                if (v.length > 200) {
                  return 'Title must be under 200 characters.';
                }
                return null;
              },
            ),
```

正文 `TextField`（:155-166）改为：
```dart
            TextFormField(
              controller: _bodyController,
              maxLength: 5000,
              maxLines: 8,
              minLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Share your question, tips, or story...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) return 'Please enter some content.';
                if (v.length > 5000) {
                  return 'Content must be under 5000 characters.';
                }
                return null;
              },
            ),
```

删除底部 `if (_errorMessage != null) ...[ ... ]`（原 :168-176）整块。

- [ ] **Step 3: 写 widget 测试**

新建 `test/features/discover/forum_compose_validate_test.dart`：空标题点 Publish → 显示 "Please enter a title." 且不提交。
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/discover/forum_compose_screen.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  testWidgets('空标题点 Publish 显示 inline 校验错误', (tester) async {
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const ForumComposeScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Publish'));
    await tester.pumpAndSettle();
    expect(find.text('Please enter a title.'), findsOneWidget);
  });
}
```
> 若 ForumComposeScreen 依赖 provider（scopeTag 读 appControllerProvider）在测试中报错，用 ProviderScope override 提供最小 state（参考现有 discover 测试模板）；空标题校验在提交前触发，不需真实网络。

- [ ] **Step 4: 全量测试 + analyze**

Run: `cd linguaquest && flutter test && flutter analyze`
Expected: PASS / `No issues found!`。

- [ ] **Step 5: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/discover/forum_compose_screen.dart linguaquest/test/features/discover/forum_compose_validate_test.dart
git commit -m "fix(community): 发帖改 Form inline 校验，错误显示在输入框下方"
```

---

## Task 6: 社区评论计数改真实数（2.1，server）

**Files:**
- Modify: `server/lib/src/database.dart`（`listForumPosts` :2088-2099、`getForumPost` :2101-2112）

**背景：** `listForumPosts`/`getForumPost` 用 `SELECT fp.*` 返回表列 `comment_count`（种子帖设了 6 但无评论行）；详情页 `listForumComments`（:2170-2180）只返回 `status='approved'` 的评论。改列表/单帖查询用实时 `COUNT(status='approved')`，与详情口径一致。`SELECT fp.*` 含 comment_count 列，需**显式枚举列**替换避免重名。

- [ ] **Step 1: 改 `listForumPosts` 用实时 COUNT**

`database.dart:2088-2099` 替换为：
```dart
  Future<List<Map<String, dynamic>>> listForumPosts({String? status}) async {
    final whereClause = status != null ? 'WHERE fp.status=@status' : '';
    final rows = await connection.execute(
      Sql.named(
        'SELECT fp.id, fp.author_id, fp.title, fp.body, fp.tag, fp.status, '
        'fp.like_count, '
        "(SELECT COUNT(*) FROM forum_comments fc "
        "WHERE fc.post_id=fp.id AND fc.status='approved') AS comment_count, "
        'fp.created_at, fp.updated_at, u.name AS author_name '
        'FROM forum_posts fp '
        'LEFT JOIN users u ON u.id = fp.author_id '
        '$whereClause ORDER BY fp.created_at DESC',
      ),
      parameters: {if (status != null) 'status': status},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }
```

- [ ] **Step 2: 改 `getForumPost` 同口径**

`database.dart:2101-2112` 替换为：
```dart
  Future<Map<String, dynamic>?> getForumPost(String id) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT fp.id, fp.author_id, fp.title, fp.body, fp.tag, fp.status, '
        'fp.like_count, '
        "(SELECT COUNT(*) FROM forum_comments fc "
        "WHERE fc.post_id=fp.id AND fc.status='approved') AS comment_count, "
        'fp.created_at, fp.updated_at, u.name AS author_name '
        'FROM forum_posts fp '
        'LEFT JOIN users u ON u.id = fp.author_id '
        'WHERE fp.id=@id::uuid LIMIT 1',
      ),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }
```
> 枚举的列覆盖 `forumPostDto` 所需字段（id/author_id/title/body/tag/status/like_count/comment_count/created_at/updated_at/author_name）；无 DB 测试 harness，正确性靠 analyze + 部署后设备复验。

- [ ] **Step 3: server analyze + 现有测试**

Run: `cd server && dart analyze && dart test`
Expected: `No issues found!` / 现有测试全绿（forum_routes_test 等纯逻辑不受影响）。

- [ ] **Step 4: Commit**
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/lib/src/database.dart
git commit -m "fix(server): 论坛列表/单帖评论数改实时 COUNT(approved)，与详情一致"
```

---

## Task 7: 全量验证 + 部署（2.1 代码 / 2.2 env）+ 构建 APK + 设备复验

**Files:** 无代码改动（除非验证发现问题）。

- [ ] **Step 1: 客户端 + 服务端全量验证**

Run:
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test && flutter analyze
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart test && dart analyze
```
Expected: 全 PASS / `No issues found!`。贴输出。

- [ ] **Step 2: 部署服务端（2.1 代码 + 2.2 env）**

rsync 上传 server 到 VPS 并部署（保留远程 `.env/.env.prod` + db 卷）：
```bash
rsync -az --delete --exclude='.env' --exclude='.env.prod' --exclude='.dart_tool' --exclude='build' \
  /Users/lanyichen/Codes/Mobile/ASM2/server/ intro-server:/home/deploy/linguaquest/server/
ssh intro-server 'cd /home/deploy/linguaquest/server && bash deploy/vps_deploy.sh'
```
Expected: 构建 + 重启成功，db 未动。
> **2.2 env（真 AI）**：需 VPS `.env.prod` 含 `AI_PROVIDER=remote` 与有效 `AI_API_KEY`（用户提供 / VPS 已有）。控制者**不读取/不记录**该密钥。若需用户设置，请用户在会话用 `! ssh intro-server '...'` 自行写入 env 后再重启；否则 2.2 标 pending（其余 7 项不受影响）。

- [ ] **Step 3: 部署后服务端抽样验证（2.1）**

Run（据部署脚本鉴权方式，必要时带 token；先取一个 approved 帖 id）：
```bash
curl -s https://api.vonlan233.top/health -o /dev/null -w "health %{http_code}\n"
```
Expected: `health 200`。评论计数一致性由设备复验确认（列表卡片评论数 == 详情 Comments(n)）。

- [ ] **Step 4: 构建 release APK**

Run: `cd linguaquest && flutter build apk --release`
Expected: `✓ Built build/app/outputs/flutter-apk/app-release.apk`。贴路径与大小。

- [ ] **Step 5: 设备复验（控制者执行）**

装 APK 到模拟器，复验：C 搜 "ai" 爱置顶；F 地图 Japanese 标签完整（不行则微调 T2 的 center/zoom 重构建）；2.1 社区列表评论数==详情；2.3 选 Travel 标题变 "Travel articles"；2.4 积分按钮 "Complete for +5 XP"；2.5 空标题 inline 报错；2.6 Me 标签 "Learned" 不截断；2.2（若已设 key）阅读段落 AI 无 "Mock" 字样。
> 本步由控制者用 adb/screencap 完成，非 subagent。发现问题回对应 Task 修复。

- [ ] **Step 6: 无新增改动不提交**（部署/构建非代码变更）。

---

## Self-Review 记录
- **Spec 覆盖：** C→T1；F→T2；2.3→T3；2.4+2.6→T4；2.5→T5；2.1→T6；2.2→T7(env)；构建/部署/复验→T7。8 项全覆盖。
- **类型一致：** '汉字拼音精确'/'汉字拼音' 标签与 rank 在 T1 内一致；`readingArticlesForTheme(theme)` T3 arb+调用一致；`_formKey`/validator T5 一致；`listForumPosts`/`getForumPost` 枚举列含 forumPostDto 所需字段 T6 一致。
- **据实核对项（非占位）：** dictionary_search 旧拼音用例断言、profile/discover 旧断言、forum_compose 测试的 provider override、部署鉴权方式、2.2 env 由用户提供 key。
- **需部署：** T6(2.1 代码)、T7(2.2 env) 在 T7 部署。2.2 无代码/无测试，纯 env。
