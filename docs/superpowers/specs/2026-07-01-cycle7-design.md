# Cycle 7 设计：反馈修复合集（11 项）

- **日期：** 2026-07-01
- **分支：** `feat/P2-roadmap`
- **来源：** 用户原始反馈 2 项 + 意见反馈7.1.docx 7 项 + 设备复测新增 2 项，共 **11 项**，用户决定全部合入 Cycle 7 一次交付。

## 全局约束（Global Constraints）
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 本 spec 明确列出的改动文件（**禁 `git add -A/./-u`**——仓库有无关 untracked：`.DS_Store`、`tools/__pycache__/*.pyc`、旧 plan 文档）。
- flutter 命令在 `linguaquest/`，dart/python 生成器在仓库根 `tools/`，server 在 `server/`。
- 现有测试全绿：`flutter test` / `flutter analyze`；`dart test` / `dart analyze`（server）。改动触发的旧断言回归必须修。
- 需部署的 Part：**B（词书数据）、G（生词去重后端）、H（收藏后端端点）**——用户已预授权部署（rsync + `deploy/vps_deploy.sh`，保留远程 `.env/.env.prod` + db 卷）。
- 词书数据源 `drkameleon/complete-hsk-vocabulary`，释义照搬源库，只改"选哪个 form/义项"，不自造。
- 答案判定一律**文本匹配**（现状），本轮任何选项改动不得改成索引匹配。

## 项目映射表

| # | 简称 | 层 | 需部署 |
|---|---|---|---|
| A | 注册引导选词书 | 客户端 + 状态 | 否 |
| B | HSK 释义/拼音修正 | 生成器 + 数据 + 服务端数据 | ✅ |
| C | 阅读答题隐藏翻译 + 英文提示 | 客户端 + 资产迁移脚本 | 否 |
| D | 阅读完成跳转 + 列表标已读 | 客户端 | 否 |
| E | 高亮色：key 词标记后变红 | 客户端 | 否 |
| F | 错题本"查看全部"入口 | 客户端 | 否 |
| G | 生词重复标记去重 | 客户端 + 服务端 | ✅ |
| H | 社区"我的收藏"入口 | 客户端 + 服务端 | ✅ |
| I | 限时挑战选项打乱 | 客户端 | 否 |
| J | 生词本入口易发现性 | 客户端 | 否 |
| K | 阅读 TTS 转圈（完成回调+超时） | 客户端 | 否 |

---

## Part A：注册验证后引导选词书

**根因：** `verify_email_screen.dart:50` 验证成功后硬编码 `context.go('/home')`，跳过完整存在的 `/goal-setup`；且 `_applyAuthenticatedUser`→`_ensureStudyPlan`→`_loadOrCreateStudyPlan` 会**自动伪造默认计划**（targetExam='Daily English'）→ `studyPlan!=null`，使 `studyPlan==null` 无法区分"未选词书的新用户"。

**方案（用户已选：去自动默认计划，用 `studyPlan==null` 判断）：**
1. **停止伪造默认计划**：改 `_loadOrCreateStudyPlan`——服务端无该用户计划时**返回 null**（不再构造默认 plan）；`_ensureStudyPlan` 以 null 更新 state。
2. **路由按 `studyPlan==null` 分流**：
   - `verify_email_screen.dart:50`：`context.go(ref.read(appControllerProvider).studyPlan == null ? '/goal-setup' : '/home')`。
   - `splash_screen.dart:56`：`if (isAuthenticated) context.go(studyPlan==null ? '/goal-setup' : '/home'); else context.go('/onboarding');`。
   - `login_screen.dart`（authenticated 分支）：同样 `studyPlan==null ? '/goal-setup' : '/home'`。
3. `completeGoalSetup` 已建并存 plan（现状），保存后 `context.go('/home')`（现状）。
4. **容错**：home 及各屏对 `studyPlan==null` 已有兜底；回归 `flutter test`，修任何断言"验证后 studyPlan 非 null"的旧用例。

**验收：** 单测：`_loadOrCreateStudyPlan` 无 plan 返回 null；widget：验证成功且无 plan → 路由 `/goal-setup`，有 plan → `/home`。设备：注册新账号 → 输验证码 → 进选词书页；老账号登录直达主页。

---

## Part B：HSK 英文释义/拼音取错 + POS 泄漏

**根因：** 源库每字有多个 `form`，姓氏/专有名词读音（拼音首字母大写，如 `Bǎi`）常排在 `forms[0]`；生成器取 `forms.first` → 取到 "surname Bai" + 大写拼音；另 `partOfSpeech = pos.join('/')` → "a/nr/d/b/v/g" 被客户端拼进拼音显示。
- 证据：`百` forms[0]=`Bǎi`/surname Bai，forms[1]=`bǎi`/hundred；`白` forms[0]=`Bái`/surname，forms[1]=`bái`/white；`班` 同理。
- 影响：HSK1-6，义项错 ~119 词；POS 泄漏 ~2000+ 词。

**方案（用户已选：显示去 POS + 重生成修义项）：**

### B1：客户端显示去 POS
- `wordbook_screen.dart:476-479`：`phonetic · partOfSpeech` → **只显 `word.phonetic`**。
- 核查词详情页是否也拼 POS，一并去掉（若有）。
- 对所有词书即时生效。

### B2：生成器"选常用 form"
两个生成器各自实现同一规则：
- **选 form**：`forms` 中优先选拼音**首字母小写**的 form（常用词），取第一个小写 form；全大写才退回 forms[0]。用所选 form 的拼音 + 义项。
- **义项过滤**：聚合义项时**跳过以 "surname " 开头**的义项；保留其余英文义项；仍过滤 CJK。
- `convert_hsk.dart`（HSK1，约 42/64 行）与 `generate_hsk_wordbooks.py`（HSK2-6，约 82-94 行）。
- POS 字段数据里保留原样（不展示），无需改 POS 生成。

### B3：重生成 + 服务端 + 部署
- 跑 `convert_hsk.dart` 重生成 `wordbook_hsk1.json`；跑 `generate_hsk_wordbooks.py` 重生成 `wordbook_hsk2..6.json`。
- 跑 `tools/sync_p0_from_assets.py` 同步进 `server/data/wordbooks_p0.json`。
- 抽样校验：`百`→"hundred"(bǎi)、`白`→"white"(bái)、`班`→"team; class; grade"(bān)、姓氏义项消失。
- 部署服务端 `wordbooks_p0.json`。

**验收：** 生成器加最小自检（`百/白/班` 主义非 surname、拼音小写）；grep 断言修正；客户端拼音行无 `/` POS；`flutter test`/`analyze` 绿；部署后 `curl /wordbooks/hsk1` 抽样确认。

---

## Part C：阅读答题隐藏翻译 + 题目英文提示

**根因：** ① `_startComprehension`（`article_reader_screen.dart:307-319`）用 `showModalBottomSheet` 半屏模态，遮不住身后正文的 `_showTranslation`（初值 true）翻译。② 题目模型 `QuizQuestion`（`lesson.dart:432-475`）无英文字段，`articles_*.json` 题目/选项全中文（共 15 题 / 5 篇）。

**方案（用户已选：脚本给题库加英文字段）：**
1. **答题时隐藏翻译**：`_startComprehension` 打开 sheet 前 `setState(_showTranslation=false)`，`await` 结束后恢复原值。译文正文答题期间不可见（正文本身仍在身后但翻译行被隐藏——标题翻译 `:193-200` 与段落翻译 `:500-510` 都受 `showTranslation` 控制）。
2. **模型加可选英文字段**：`QuizQuestion` 增 `final String? promptEn; final List<String>? optionsEn; final String? explanationEn;`（可选，向后兼容；`fromJson` 读同名 key，缺失为 null）。
3. **一次性资产迁移脚本**：`tools/add_reading_question_en.py` 读 `articles_hsk1.json`/`articles_jlpt_n5.json`，为每题写入 `promptEn`/`optionsEn`/`explanationEn`（15 题，脚本内 curated 英文，离线确定，可 review）。
4. **UI 显示英文提示**：`reading_comprehension_screen.dart` 题干（`:148-153`）下方显示 `question.promptEn`（若非 null）；选项按钮显示 `optionsEn[i]`（若有）。

**验收：** 单测：`QuizQuestion.fromJson` 读英文字段 + 缺失为 null 兼容；widget：sheet 打开时正文翻译隐藏、关闭后恢复；题干/选项显示英文提示；迁移后 grep 15 题均有 `promptEn`；`flutter test`/`analyze` 绿。

---

## Part D：阅读完成后跳转 + 列表标已读

**根因：** ① `_startComprehension` 未接 `showModalBottomSheet` 返回值（sheet `:122` 完成时 pop(true)），无导航动作。② `reading_list_screen.dart` 的 `_future` 仅 `initState`（`:36`）加载一次，返回列表不重新执行；`completeReading`（`app_controller.dart:3066-3078`）已存 `completed:true`，但列表读的是旧缓存。

**方案：**
1. **完成后返回列表**：`_startComprehension` 接返回值，`if (result == true && context.mounted) context.pop();`（回到阅读列表页）。
2. **列表刷新进度**：`reading_list_screen` 从 `article_reader` 返回后重载进度——用 `context.push(...).then((_) => setState(() => _future = _load()))`，或将进度改为 `ref.watch` FutureProvider。取**最小改动**：进入阅读页的 push 调用 `.then` 后 `setState` 重新 `_load()`。
3. 完成路径确保调用 `completeReading`（标记 `completed:true`）。

**验收：** 单测/widget：sheet 返回 true → 列表页 pop；`completeReading` 后列表项 `done==true` 显示绿标；设备：读完点完成 → 回列表 → 该篇显"已读"。`flutter test`/`analyze` 绿。

---

## Part E：高亮色——key 词标记后变红

**根因：** `word_segmenter.dart:217` `if (vocab.role=='key') return WordClass.key;` 在检查 reviewWord（`:231`）**之前** return，导致作者关键词（蓝）即使被加入生词本/需复习，也永不显红。

**方案：** 调整 `classifyToken` 优先级——**"用户已标记为需复习/生词"的状态优先于作者 key 角色**：先判 reviewWord/unknown 状态，再判 key。即把 `:231` 的 reviewWord 判定移到 key 判定之前（保持 known/newWord 相对顺序不变）。

**验收：** 单测：一个 role=='key' 的词，在 reviewWords 集合中 → `classifyToken` 返回 `WordClass.unknown`（红），不在则返回 `key`（蓝）；其余优先级用例不回归。`flutter test`/`analyze` 绿。

---

## Part F：错题本"查看全部"入口

**根因：** `review_center_screen.dart:103/105` 用 `.take(3)` 只显 3 词（摘要设计，非 bug）；完整页 `mistake_book_screen.dart` 已显示全部并有路由 `/mistake-book`；`home_screen` 弱词摘要下**无跳转入口**，用户以为只有 3 个。"题目固定"是 weakWords 按 wrongCount 静态倒序排序的正常表现。

**方案（轻量，不改摘要逻辑）：**
- `home_screen` 弱词摘要区（及 `review_center_screen` 摘要区若无）加一个"查看全部 / See all"按钮 → `context.push('/mistake-book')`。
- 复用现有 `/mistake-book` 页（已显示全部），无需改错题本本身。

**验收：** widget：home 弱词区存在跳 `/mistake-book` 的按钮；点击导航正确。`flutter test`/`analyze` 绿。

---

## Part G：生词重复标记去重

**根因：** ① 前端 `addCustomWord`（`app_controller.dart:848-879`）不按 word 去重，`id` 每次 `microsecondsSinceEpoch` 唯一。② 后端 `POST /custom-words`（`routes.dart:304-317`）无 (uid,word) 校验；`upsertCustomWord`（`database.dart:861-914`）`ON CONFLICT (id)` 而 id 永远新 → 永不去重。

**方案（前后端双层，防数据完整性问题）：**
1. **前端幂等**：`addCustomWord` 开头 `final existing = state.customWords.where((w) => w.word == word.trim()).firstOrNull; if (existing != null) return existing;`（已存在则直接返回，不再新建，UI 仍提示"已在生词本"）。
2. **后端唯一约束 + upsert by (uid,word)**：`custom_words` 表加 `UNIQUE(uid, word)`（迁移：建 `IF NOT EXISTS` 唯一索引；建前先按 (uid,word) 去重已有脏数据保留最早一条）；`upsertCustomWord` 改 `ON CONFLICT (uid, word) DO UPDATE`（或 POST 前查 (uid,word) 存在则返回既有）。
3. 迁移需处理已存在的重复行（保留最早/合并进度），再建唯一索引，避免建索引失败。

**验收：** server 单测：同 (uid,word) 二次 POST 只留一行、返回既有；去重迁移不丢已有词。前端单测：重复 `addCustomWord` 不增列表长度。`dart test`/`analyze` + `flutter test` 绿。部署后 `curl` 复测同词二次添加不重复。

---

## Part H：社区"我的收藏"入口

**根因：** 后端 `forum_favorites` 表 + `toggleFavorite`/`hasFavorited` + `GET /forum/posts` 返回 `isFavorited` 均已完备，帖子详情页有收藏按钮；但**缺"列出用户收藏"端点、缺"我的收藏"页/入口**，社区列表卡片也无收藏按钮 → 用户无法查看收藏。

**方案（用户已选：加"我的收藏"入口）：**
1. **后端端点**：`GET /forum/favorites`（`routes.dart` 在 favorite POST 后新增）→ `database.dart` 新增 `listFavoritedPostsByUser(userId)`（JOIN forum_favorites，返回 DTO 带 isFavorited=true）。
2. **客户端仓库**：`ForumRepository` 加 `Future<List<ForumPost>> listFavoritedPosts();`；`ApiForumRepository` 实现调 `GET /forum/favorites`。
3. **状态**：`app_controller` 加 `refreshFavoritedPosts()`；`AppState` 加 `List<ForumPost> favoritedPosts`（含 copyWith）。
4. **UI**：新建 `my_favorites_screen.dart`（列表复用 `community_screen` 卡片样式，空态提示）；路由 `/forum/favorites`；社区页/发现页加"我的收藏"入口（`community_screen` 顶部 action 或 `discover_screen` 条目）。
5. l10n：加 `communityMyFavorites` 等字符串（en）。

**验收：** server 单测：`listFavoritedPostsByUser` 只返回该用户收藏且 isFavorited=true。widget：`my_favorites_screen` 展示收藏列表 + 空态；入口可达。`flutter test`/`analyze` + `dart test` 绿。部署后 `curl /forum/favorites` 抽样确认。

---

## Part I：限时挑战选项打乱

**根因：** `training_session_screen.dart` `_options`（`:494-519`，`:518` return）与 `buildListeningQuestion`（`:1053-1079`，`:1075` return）生成选项后**未 shuffle**，答案（先 `add`）永远第一位（=A）。参考正确实现 `lesson_factory.dart:357-379` 用 `..shuffle(Random(seed))`。判定是文本匹配（`quiz_session_screen.dart:276-278`），打乱后仍正确。

**方案：**
- 两处返回前加确定性打乱：`return List.unmodifiable(options..shuffle(Random(seed)));`，seed 用现有可复现种子（如 `offset`/`index` 派生，保证同题稳定、不同题不同序）。
- 不改答案判定（保持文本匹配）。

**验收：** 单测：给定 seed，答案不总在 index 0；同 seed 结果稳定；选项集合仍含正确答案且去重为 4 项。`flutter test`/`analyze` 绿。

---

## Part J：生词本入口易发现性

**根因：** 生词本功能完整（`/custom-words` 列表页 + CRUD + 后端持久化），Profile/Wordbook/Review Center 均有入口；但阅读页"Add to vocab notebook"加词后**无引导**，用户不知去哪看 → 以为"没入口"。

**方案（最小、不新增导航层）：**
- 阅读页添加成功的 SnackBar（`article_reader_screen.dart:802-821` 附近）加一个 `SnackBarAction`："查看 / View" → `context.push('/custom-words')`。
- 用户加词后一键直达生词本，解决易发现性。

**验收：** widget：加词后 SnackBar 含"查看"action，点击导航 `/custom-words`。`flutter test`/`analyze` 绿。

---

## Part K：阅读 TTS 转圈（完成回调 + 超时）

**根因：** flutter_tts `speak()` 在 Android 上 Future 永不 complete → `article_reader_screen.dart:_play`（`:697-712`）的 `await _service.play()` 永久挂起 → `_loading=false` 永不执行 → 一直转圈。无超时、无完成回调、Future 挂起 try-catch 也无效。

**方案（用户已选：完成回调 + 超时兜底，不加依赖）：**
1. **完成回调 + Completer 包装**：TTS 回调（`article_reader_screen.dart:664-676` 的 `tts:` 闭包 / `pronunciation_service.dart`）改用 `_tts.setCompletionHandler(() => completer.complete(true))`，`speak()` 不再 `await`，返回 `completer.future`。
2. **超时兜底**：`completer.future.timeout(Duration(seconds: 8), onTimeout: () => false)`，保证无论如何 loading 会结束。
3. 同步检查 `pronunciation_controls.dart` 是否同款问题，一并修（若共用 service 则一处修复）。
4. 保留 catch 兜底（异常路径也 return false 并重置 loading）。

**验收：** 单测：TTS 回调在完成时 resolve；超时路径 8s 后返回 false（用 fake/短超时验证）；loading 状态在成功/超时/异常三路径都会重置。`flutter test`/`analyze` 绿。设备：点 Play 正常播放且转圈结束；异常时 8s 内恢复可点击。

---

## 任务分解预览（writing-plans 细化）

独立可并行的客户端小改：A、E、F、I、J、K、D、C。数据/后端需部署：B、G、H。建议任务顺序（按依赖/风险）：

1. **A** 注册引导（状态 + 路由 + 回归）。
2. **B1** 显示去 POS；**B2** 改生成器；**B3** 重生成 + 同步服务端 + 部署。
3. **C** 模型英文字段 + 迁移脚本 + 隐藏翻译 + UI 提示。
4. **D** 完成跳转 + 列表刷新。
5. **E** 高亮优先级。
6. **F** 错题本入口。
7. **G** 生词去重（前端幂等 + 后端唯一约束 + 迁移 + 部署）。
8. **H** 收藏端点 + 页面 + 入口（+ 部署）。
9. **I** 限时选项打乱。
10. **J** 生词本 SnackBar 入口。
11. **K** TTS 完成回调 + 超时。
12. **验证 + 部署**：全量测试 + 设备复测 + 服务端部署（B/G/H）。

> B/G/H 三项含服务端与部署；其余为纯客户端。C 的英文提示为 curated 一次性迁移（15 题）。J 只加一个 SnackBarAction（功能已存在）。
