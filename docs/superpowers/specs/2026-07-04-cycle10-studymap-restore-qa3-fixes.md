# Cycle 10 设计：Study Map 完整恢复 + 第三轮 QA 修复（8 项）

- **日期：** 2026-07-04
- **分支：** `feat/P2-roadmap`
- **来源：** 第三轮外部 QA 报告 `Codes/Mobile/testing3/LinguaQuest_APK_V3_Huangshen_Test_Report_2026-07-04.md`（针对连生产后端的 APK v1.0.3）。经 4 个探索 agent 核实根因后分诊。
- **范围：** 三部分——①**Study Map 完整恢复**（feature，之前被 `ea68e35` 整体删除）；②**8 个真 bug**（A-H）；③**服务端 TTS**（edge-tts，修复本地 flutter_tts 在缺中文语音包设备/模拟器上无声）。**需部署：Study Map 后端端点 + B 收藏计数 + TTS 微服务（server）。**
- **不纳入（已核实非 bug，报告说明即可）：** About 公司地图 marker 无反馈（`InteractiveFlag.none` 故意只读）；抽奖无法测（测试账号 0 XP，环境问题）。QA 报的"Study Map 缺失"本是发现性误解（Map 评分项已由 Language Map 承接），但用户决定**恢复独立 Study Map**，故纳入本轮。

## 全局约束（Global Constraints）
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 每项明确列出的文件（**禁 `git add -A/./-u`**——仓库有无关 untracked：`.DS_Store`、`__pycache__`、plan 草稿、`docs/testing/*`）。
- flutter 命令在 `linguaquest/`，server 在 `server/`。改 `.arb` 跑 `flutter gen-l10n` 并提交生成文件；三 arb（en/ms/zh）同步加/改键。
- 现有测试全绿：`flutter test`/`flutter analyze`；`dart test`/`dart analyze`（server）。
- 需部署项用户已预授权（rsync + `deploy/vps_deploy.sh`，保留远程 `.env/.env.prod` + db 卷）。
- **数据源约束**：所有 repository 走当前 `if (AppConstants.apiBaseUrl.isNotEmpty) → ApiXxx else MockXxx` 模式；正式 APK 用 `flutter build apk --release --dart-define=API_BASE_URL=https://api.vonlan233.top` 构建（README 已固化）。
- **地图约束（用户 2026-06-29 强调）**：Map 必须真实地图 API（OSM 瓦片），不可用插画/静态图替代。Study Map 用 `flutter_map + OSM`（依赖 `flutter_map: ^7.0.2`、`latlong2: ^0.9.1` 已在）。
- 不动 Cycle 7/8/9 已通过的修复；不动 Language Map / About 公司地图。

## 项目清单

| # | 简称 | 层 | 部署 |
|---|---|---|---|
| SM | Study Map 完整恢复 | client + server | ✅ |
| A | 收藏帖详情 "Post not found" | client | 否 |
| B | 收藏列表评论计数用旧值 | server | ✅ |
| C | 作者头像不进 Public Profile | client | 否 |
| D | Privacy 返回 Profile 长时间加载圈 | client | 否 |
| E | About 版本号显示 1.0.0 | client | 否 |
| F | 首页/个人页学习路径不一致 | client | 否 |
| G | Theme "Follow System" 换行挤压 | client | 否 |
| H | Daily Reminder 文案 "day 20:00" | client + l10n | 否 |
| TTS | 服务端语音合成（edge-tts） | client + server | ✅ |

---

## SM：Study Map 完整恢复

**背景：** `ea68e35`（"彻底删除 Study Map + Study Spot 前后端，保留线上表不 DROP"）删除了整套 Study Map。后端 `study_spots` 表**仍在**（未 DROP），但无端点。之后 Cycle 7/8/9 大量演进，故**不能 `git revert`**（会冲突）——以 `ea68e35^` 旧代码为**起点**重新集成到当前架构。

**恢复来源（从 `ea68e35^` 取旧代码为起点，逐一适配）：**
- `git show ea68e35^:<path>` 可取回每个被删文件的原始内容。

### SM.1 数据层
**文件：**
- Create `linguaquest/lib/data/models/study_spot.dart`（恢复原 41 行 model：`StudySpot { id, name, latitude, longitude, visitCount, ... }` + `fromJson`/`toJson`/`copyWith`；以旧代码为准，核对字段与后端返回一致）
- Create `linguaquest/lib/data/repositories/study_spot_repository.dart`（恢复 abstract `StudySpotRepository`：`listStudySpots()`、`recordVisit({name, lat, lng})` 等，签名以旧代码为准）
- Modify `linguaquest/lib/data/repositories/api_repositories.dart`（恢复 `ApiStudySpotRepository`：打 `/study-spot/*` 端点，路径以旧代码为准）
- Modify `linguaquest/lib/data/repositories/mock_repositories.dart`（恢复 `MockStudySpotRepository`：内存列表 + 就近累加 visitCount）

**就近累加（原 `e790228` 逻辑）：** `recordVisit` 时若新点与已有 spot 距离 < 阈值（原代码阈值，如 ~50m）则累加该 spot 的 `visitCount`，否则新建 spot。阈值与距离算法以旧代码为准。
> ponytail: 就近累加是 O(n) 线性扫描已有 spots；spot 数量小（个人学习地点），无需空间索引。原代码已如此标注。

### SM.2 定位服务 + 权限
**文件：**
- Create `linguaquest/lib/core/services/location_service.dart`（恢复原 geolocator 封装：`currentLatLng()` → `Future<LatLng?>`，无权限/无 GPS 时返回 null）
- Modify `linguaquest/pubspec.yaml`：`flutter pub add geolocator`（解析 flutter 3.41 兼容版；`geolocator` 曾被 `49eee53` 移除，现恢复）
- Modify `linguaquest/android/app/src/main/AndroidManifest.xml`：加 `ACCESS_FINE_LOCATION` + `ACCESS_COARSE_LOCATION` 权限

**权限/无 GPS 兜底：** `currentLatLng()` 返回 null 时，UI 提示 "Location unavailable — long-press the map to pick a spot."，用户长按地图选点（原 `study_map_screen.dart` 已有此兜底，保留——模拟器/评分环境无 GPS 时仍可用）。

### SM.3 状态层
**文件：** Modify `linguaquest/lib/core/state/app_state.dart` + `app_controller.dart`
- `app_state.dart`：加 `final List<StudySpot> studySpots;`（默认 `const []`）+ 构造/`copyWith`
- `app_controller.dart`：
  - 加 `studySpotRepositoryProvider`（`if (apiBaseUrl.isNotEmpty) ApiStudySpotRepository else MockStudySpotRepository`，与其余 15 仓库同模式）
  - `AppController` 加 `_studySpotRepository = ref.watch(studySpotRepositoryProvider)`
  - `loadStudySpots()`（拉列表填 state）、`recordVisit({name, lat, lng})`（就近累加后刷新 state）

### SM.4 屏幕 + 路由 + 入口
**文件：**
- Create `linguaquest/lib/features/map/study_map_screen.dart`（恢复 153 行；适配当前 `AppTokens`/`AppCard`/`AppButton`/`FallbackBackButton`——这些组件仍在。fallback 中心 KL `LatLng(3.139, 101.6869)`）
- Create `linguaquest/lib/features/map/study_spots_list_screen.dart`（恢复 80 行，列表显示 spot 名 + visitCount）
- Modify `linguaquest/lib/core/routing/app_router.dart`：恢复 `/map` → `StudyMapScreen`（列表可作 `/map/spots` 或屏幕内导航，以旧代码为准）
- Modify `linguaquest/lib/features/shell/app_drawer.dart`：Drawer 恢复 "Study Map" 项 → `context.push('/map')`

**热力图（原 `8445e16` 逻辑）：** 地图上叠加 `CircleLayer`，每个 spot 一个 circle，半径/透明度按 `visitCount` 加权（visitCount 越高越大/越浓）；marker 显示 spot。实现以旧代码为准。

### SM.5 后端（需部署）
**文件：**
- Create `server/lib/src/study_spot_policy.dart`（恢复原 51 行业务逻辑：就近累加/校验）
- Modify `server/lib/src/routes.dart`：恢复 `/study-spot/*` 端点（GET 列表 / POST 记录访问；路径、鉴权、payload 以旧代码为准，需 bearer token）
- 核对 `server/lib/src/database.dart` 的 `study_spots` 表 schema（已在，未 DROP）与恢复的 policy/routes 字段一致；如列名/类型有出入，以现存表为准调整代码（**不改表结构**，避免动生产数据）。

**验收（后端）：** `dart test`/`dart analyze` 绿；恢复原 `study_spot_policy_test.dart`（49 行）。部署后 `curl` 带 token 打 `/study-spot` 端点返回 200 + 记录/列表正常。

### SM.6 测试
恢复原测试（从 `ea68e35^`，适配当前接口）：
- `test/data/study_spot_test.dart`（model）
- `test/data/study_spot_state_test.dart`（state）
- `test/data/study_spot_record_visit_test.dart`（就近累加）
- `test/data/mock_study_spot_repository_test.dart`（mock repo）
- `test/features/study_map_smoke_test.dart`（屏幕 smoke）
- `test/features/study_spots_list_test.dart`（列表）
- server `test/study_spot_policy_test.dart`

**验收（SM 整体）：** `flutter test`/`analyze` + `dart test`/`analyze` 全绿；APK（连后端）Drawer → "Study Map" 打开真 OSM 地图；"Save here"（有 GPS）或长按选点 → 命名 → spot 落库；重复就近 → visitCount 累加；列表显示次数；热力图随 visitCount 变化；kill/restart 后 spot 持久化（连后端）。

---

## A：收藏帖详情 "Post not found"

**根因（agent 核实）：** `forum_post_detail_screen.dart:141` 只从内存 `state.forumPosts` 里 `where(id==postId).firstOrNull` 找帖；`state.forumPosts` 仅在 `CommunityScreen.initState`（`community_screen.dart:92`）调 `refreshForumPosts()` 时填充。从 My Favorites 直接进详情（未先进 Community）→ 列表空 → null → `forum_post_detail_screen.dart:201-205` 显示 "Post not found"。Mock 模式下 favorites 与 posts 共享同一内存对象故不暴露；连后端后两 API 分离才现形。

**方案：** 详情页改为**按 postId 直接拉单帖**，不再只依赖内存列表。
- `ForumRepository` 已有 `getForumPost(id)`（`ApiForumRepository` 打 `GET /forum/posts/{id}`，返回 `{post, comments}`——已存在，Cycle 9 curl 验证过）。
- `forum_post_detail_screen.dart`：改用 `FutureProvider`/加载态按 `widget.postId` 调 `getForumPost` 拉帖 + 评论；找到则渲染，404/null 才显示 "Post not found"（真不存在时）。保留内存列表作为快速首屏（可选：先用内存值秒显，再用单帖结果覆盖），但**不以内存为唯一来源**。

**验收：** widget/设备：从 My Favorites 直接进收藏帖详情，正常显示帖子 + 评论（非 "Post not found"）；从 Community 进详情仍正常。`flutter test`/`analyze` 绿。

---

## B：收藏列表评论计数用旧值（server，部署）

**根因（agent 核实）：** `database.dart:2283-2298` `listFavoritedPostsByUser` 的 SQL 用 `SELECT p.*`，返回表存的 `comment_count`（可能过时）；而 Cycle 9 已把 `listForumPosts`/`getForumPost` 改成实时子查询 `(SELECT COUNT(*) FROM forum_comments WHERE post_id=... AND status='approved')`。收藏端点是那次的遗漏。

**方案：** `listFavoritedPostsByUser` 的 SELECT 同口径改为实时子查询 `comment_count`（枚举列，替换 `p.*` 里的 comment_count，与 `listForumPosts` 完全一致口径 `status='approved'`）。

**验收：** server 单测：某 post 有 N 条 approved 评论 → 收藏列表返回该 post `commentCount==N`，与 `listForumPosts`/详情一致。`dart test`/`analyze` 绿。部署后 curl 对比一致。

---

## C：作者头像不进 Public Profile（client）

**根因（agent 核实）：** Public Profile 页存在（`public_profile_screen.dart`，路由 `/profile/:userId`）；但 `community_screen.dart:212` 的 `_AuthorAvatar` + 昵称**无点击**（点整卡片进帖子详情）；`forum_post_detail_screen.dart` 的 `_PostBody`（259-322）**完全没显示作者**；评论作者 `_CommentCard`（337-343）显示但无点击。`authorId` 字段在 `ForumPost`/`ForumComment` 均可用。

**方案：** 3 处接线到 `/profile/{authorId}`：
1. `community_screen.dart`：卡片作者头像+昵称行包 `GestureDetector(onTap: () => context.push('/profile/${post.authorId}'))`（注意与卡片整体 onTap 进详情不冲突——作者行的点击优先/独立）。
2. `forum_post_detail_screen.dart` `_PostBody`：在 tag/title 附近**新增作者行**（头像 + 昵称），包 `GestureDetector → /profile/${post.authorId}`。
3. `forum_post_detail_screen.dart` `_CommentCard`：评论作者昵称包 `GestureDetector → /profile/${comment.authorId}`。

**验收：** 设备：社区卡片点作者头像/昵称 → 进 Public Profile（非帖子详情）；帖子详情显示作者且可点进 Profile；评论作者可点进 Profile。`flutter test`/`analyze` 绿。

---

## D：Privacy 返回 Profile 长时间加载圈（client）

**根因（agent 核实）：** Privacy 开关触发 `app_controller.dart:424 updatePrivacySettings()`，第 430 行 `await client.dio.put('/privacy', ...)`；Profile 页 `profile_screen.dart:32` `ref.watch(appControllerProvider)` 监听全局 `AppState.isLoading`——PUT 挂起时 `isLoading` 不清 → 返回 Profile 后持续转圈。连后端（真实网络延迟）才明显。

**方案：**
- `updatePrivacySettings`：PUT 加错误兜底（已有 try/catch 打 debugPrint？核实）+ **不长期占用全局 `isLoading`**（隐私开关是后台同步，不应阻塞 Profile 首屏）。让隐私同步的 loading 与 Profile 展示解耦：Profile 页展示不依赖隐私 PUT 的完成。
- 具体：privacy 同步失败/超时不卡 UI（本地已 `setString` 持久化，UI 立即反映）；Profile 页加载态只反映其自身数据加载，不被隐私 PUT 拖住。

**验收：** 设备：改隐私开关 → 返回 Profile → 不再长时间转圈，Profile 正常显示。`flutter test`/`analyze` 绿。
> ponytail: 隐私设置本地 `SharedPreferences` 已即时持久化；后端 PUT 是尽力而为的同步，失败仅 debugPrint，不阻塞也不回滚 UI（信任边界：隐私值非资金/权限关键路径）。

---

## E：About 版本号显示 1.0.0（client，动态读）

**根因（agent 核实）：** `about_screen.dart:75` 用 `l10n.aboutVersion`，文案在 `app_en.arb:896` 硬编码 `"LinguaQuest · Version 1.0.0"`，与 `pubspec.yaml` 的 `1.0.3+3` 脱节。

**方案（用户选：动态读）：**
- `flutter pub add package_info_plus`（解析当前兼容版）。
- `about_screen.dart`：用 `PackageInfo.fromPlatform()` 读 `version`（运行时真实版本），拼成 "LinguaQuest · Version {version}"。
- l10n 键改为带参：`aboutVersion` = `"LinguaQuest · Version {version}"`（三 arb 同步；zh/ms 对应），调用 `l10n.aboutVersion(info.version)`。
- 读取用 `FutureBuilder`/一次性 future；读取中显示无版本号或占位，读到后显示。

**验收：** 设备：About 页版本号显示 `1.0.3`（与 APK 一致，随 pubspec 自动同步）。`flutter test`/`analyze` 绿。

---

## F：首页/个人页学习路径不一致（client）

**根因（agent 核实）：** 首页 `home_screen.dart:139-140,212-213` 用 `currentBook?.nameFor(localeCode) ?? displayTarget(...)`（本地化名）；个人页 `profile_screen.dart:91` 用 `state.currentStudyBook.name`（`app_state.dart:197-208`：book 存在时 `book.title` 英文，否则回退 `studyBookInfoForId(...)` 硬编码书名）。两路径取值逻辑不同 → 首页 "HSK 2" vs 个人页 "JLPT N5"。

**方案：** 统一两处走**同一取值逻辑**。以首页的 `currentBook?.nameFor(localeCode) ?? displayTarget(...)` 为准（本地化 + 与当前词书一致）——个人页 `profile_screen.dart:91` 改用相同逻辑（读同一 `currentBook` 源 + `nameFor(localeCode)`）。避免 `currentStudyBook.name` 的英文/回退分叉。核实回退分支为何产出 "JLPT N5"（`studyBookInfoForId` 对某 wordBookId 的映射），确保统一后首页/个人页显示同一书名。

**验收：** 设备：首页与个人页学习路径/词书名**一致**。`flutter test`/`analyze` 绿。

---

## G：Theme "Follow System" 换行挤压（client）

**根因（agent 核实 + 截图）：** `settings_screen.dart:278-295` 横向 `SegmentedButton<ThemeMode>` 三等分（System/Light/Dark），"Follow System" 在窄格内被挤成三行 "Follow/Syste/m"。dark mode 是**活的功能**（`themeMode` 完整接线，memory 已订正），不删控件。

**方案（用户选：改垂直三行）：** 把横向 `SegmentedButton` 换成**垂直三行选择列表**——三个选项各占整行（图标 + 标签 + 选中态），文案不再挤压。
- 用 `RadioListTile<ThemeMode>` ×3（System/Light/Dark），或等价的自定义可选行，包在现有 `_ThemeSettingCard` 内；选中调 `onChanged`（现有 `updateThemeMode`）。
- 保持 Cozy Quest 卡片风格（`AppCard`/`AppTokens`）；无障碍：每行可点、有语义标签、选中态清晰。

**验收：** 设备：Theme 三选项垂直排列，"Follow System" 完整单行显示不换行；三态切换正常（Light/Dark 实际生效）。`flutter test`/`analyze` 绿。

---

## H：Daily Reminder 文案 "day 20:00"（client + l10n）

**根因（agent 核实）：** `settings_screen.dart:43` 拼 `'${l10n.commonDay} ${state.reminderSettings.formattedTime}'`，`commonDay`（`app_en.arb:41`）= "day"，拼出 "day 20:00"。

**方案：** 新增专用 l10n 键 `settingsReminderDisplay` = en `"Daily · {time}"`（zh `"每日 · {time}"`、ms `"Harian · {time}"`；三 arb 同步带参）；`settings_screen.dart:43` 改用 `l10n.settingsReminderDisplay(state.reminderSettings.formattedTime)`。不再拼 `commonDay`。

**验收：** 设备：Daily Reminder 显示 "Daily · 20:00"（非 "day 20:00"）。`flutter test`/`analyze` 绿。

---

## TTS：服务端语音合成（edge-tts）（client + server，部署）

**根因（agent 核实）：** 客户端 `pronunciation_service.dart:26` 中文场景 `chineseTtsOnly` **只用本地 `flutter_tts`、主动跳过 audioUrl**；`pronunciation_controls.dart:63-76` 与 `article_reader_screen.dart:686` 的 tts sink = `_tts.setLanguage('zh-CN')` + `speak()`。本地 flutter_tts 依赖**设备安装的中文 TTS 语音数据**，模拟器/评分环境常缺失 → `setLanguage`/`speak` 失败或无声。非代码 bug，是本地 TTS 固有短板。**有利点：** 客户端 audio sink 已能播 `UrlSource`（audioplayers），只要 server 给音频 URL，中文改走 URL 即可，改动小。

**方案（用户选：运行时 edge-tts）：** server 提供 `/tts` 音频端点（微软 Edge 免费 neural TTS，无需 key），客户端中文单词/阅读句子改播该 URL，本地 flutter_tts 降级为兜底。

### TTS.1 服务端（需部署）
**集成方式：** docker-compose 加一个**独立 python edge-tts 微服务**（Dart API 保持纯 Dart，只做转发 + 缓存；edge-tts 用维护良好的 python 库最稳）。
- Create `server/tts/`（轻量 python 服务：`edge-tts` + 最小 HTTP，`POST/GET /synthesize?text=&voice=&rate=` → 返回 `audio/mpeg` mp3）。Dockerfile 基于 `python:3-slim` + `pip install edge-tts`。
- Modify `server/docker-compose.prod.yml`：加 `tts` service（内部网络，不对外暴露端口）；API 通过 `http://tts:PORT` 访问。
- Modify `server/lib/src/routes.dart`：加 `GET /tts?text=&lang=&slow=` 端点：
  - **输入校验**（信任边界）：`text` 非空且长度 ≤ 上限（如 500 字，防滥用）；`lang` 白名单 `{zh,en,ja}`；否则 400。
  - **voice 映射**：`zh`→`zh-CN-XiaoxiaoNeural`、`en`→`en-US-AriaNeural`、`ja`→`ja-JP-NanamiNeural`（具体音色实现时定）；`slow=true`→edge-tts `rate=-25%`。
  - **缓存**（降开销）：按 `sha256(text|voice|rate)` 存 mp3 到 volume 目录；命中直接回，未命中调 tts 微服务生成后落盘再回。
  - 返回 `Content-Type: audio/mpeg`（可加长 `Cache-Control`）。
  - `/tts` 是否需鉴权：读端点，可**免鉴权**（音频非敏感；与词库公开性一致）或复用 bearer——实现时按现有公开端点惯例定，倾向免鉴权简化客户端。
- Modify `server/lib/src/config.dart`：加 TTS 微服务地址/缓存目录 env（默认值，非密钥）。

> ponytail: 缓存用文件系统 + sha256 键，无需 DB/Redis；词/句重复率高，命中率好。edge-tts 走微软公共 endpoint（VPS 需能出网访问 `speech.platform.bing.com`，部署时验证）。

### TTS.2 客户端
**文件：** Modify `pronunciation_service.dart` + `pronunciation_controls.dart` + `article_reader_screen.dart`
- `pronunciation_service.dart`：中文不再无条件 `chineseTtsOnly` 跳过 URL。改为：**优先播 server TTS URL**（`{AppConstants.apiBaseUrl}/tts?text={encoded}&lang={zh/en/ja}&slow={bool}`，`Uri.encodeComponent` 编码 text）；audio sink 成功 → `playedUrl`；失败/无 apiBaseUrl → **fallback 本地 flutter_tts**（离线兜底保留）。
- `pronunciation_controls.dart` / `article_reader_screen.dart`：构造 server TTS URL 传入 `play(audioUrl: ttsUrl, ...)`；语言按当前 targetLanguage/文本映射。
- 保留 flutter_tts 实例作兜底（server 不可达/离线时仍能尝试本地）。

**验收（TTS 整体）：** server 单测：`/tts` 输入校验（空/超长/非法 lang → 400）、缓存命中不重复合成、voice 映射正确。客户端单测：`PronunciationService` 中文优先 URL、URL 失败 fallback tts。部署后 curl `GET /tts?text=你好&lang=zh` 返回 `audio/mpeg` 且非空。**设备复验（关键）：** 模拟器（无中文语音包）下点单词/阅读句子 Play → **能发出中文读音**（经 server），非静默；断开 server → fallback 本地不崩。`flutter test`/`analyze` + `dart test`/`analyze` 绿。

---

## 部署 & 验证

- **部署项**：SM 后端（`study_spot_policy.dart` + routes 端点）+ B（收藏计数 SQL）+ **TTS（docker-compose 加 tts 微服务 + `/tts` 端点）** → `deploy/vps_deploy.sh`（health 200，curl 带 token 验端点；`curl /tts?text=你好&lang=zh` 返回 audio/mpeg）。
- **APK**：`flutter build apk --release --dart-define=API_BASE_URL=https://api.vonlan233.top`。
- **设备复验**（连后端账号登录）：SM 全流程（Drawer→Study Map→定位/长按→命名→落库→visitCount 累加→热力图→列表→重启持久化）；A（收藏帖详情）；C（作者→Profile）；D（隐私返回不卡）；E（版本 1.0.3）；F（首页=个人页词书）；G（三行主题）；H（Daily · 20:00）；B（收藏计数一致）；**TTS（模拟器无中文语音包下，单词/阅读句子 Play 能发中文读音）**。

## 任务分解预览（writing-plans 细化）
Study Map 较大，按数据流拆多 task；bug 各自独立小改。
1. **SM.1** 数据层（model + repo abstract + Api/Mock）+ 单测
2. **SM.2** location_service + geolocator 依赖 + Android 权限
3. **SM.3** 状态层（app_state/app_controller provider + load/recordVisit）+ 就近累加单测
4. **SM.4** 屏幕（study_map_screen + list）+ 路由 + Drawer 入口 + 热力图 + smoke test
5. **SM.5** 后端（policy + routes 端点，核对表 schema）+ policy 单测
6. **A** 收藏详情按 id 拉单帖（client）
7. **B** 收藏计数 SQL（server）
8. **C** 作者头像 → Public Profile（3 处接线）
9. **D** 隐私返回 Profile 不卡（解耦 isLoading）
10. **E** About 版本号动态读（package_info_plus + l10n 带参）
11. **F** 首页/个人页词书统一取值
12. **G** Theme 垂直三行
13. **H** Daily Reminder 文案（l10n）
14. **TTS.1** 服务端：tts 微服务（python edge-tts）+ docker-compose + Dart `/tts` 端点（校验/voice映射/缓存）+ server 单测
15. **TTS.2** 客户端：`pronunciation_service` 中文优先 server URL + fallback 本地 + 单测
16. **验证 + 部署**（SM 后端 + B + TTS 微服务）+ 构建 APK + 设备复验全项

> SM 前端可与 bug A-H 并行；SM.5 后端与 B 同批部署。geolocator/package_info_plus 两个新依赖用 `flutter pub add` 解析（geolocator 恢复原有能力，package_info_plus 为动态版本号——均非"造轮子"，是恢复/标准能力）。
