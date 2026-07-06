# Cycle 4 设计 — Study Spot 增强 · Passage Cloze 提速 · 词书补全与多语言

日期：2026-06-29
分支：feat/P2-roadmap
范围：三个相互独立的子系统，合为一轮：
- ① Study Spot / Study Map 增强（返回箭头 + 自动记录学习地点与次数 + 热力图图层）
- ② Passage Cloze 提速（减小生成量 + 明确加载提示 + 可配 cloze 模型口子）
- ③ 词书补全与多语言开放（HSK2-6 同步完整数据 + en/es/fr/ms 各一本测试词书 + 开放为可学）

通用约束：
- 无新依赖（`flutter_map`/`CircleLayer`、`geolocator`、`latlong2` 均已在用）。
- 不破坏 light/dark；`flutter analyze` + `flutter test` 全绿，`dart analyze` + `dart test` 全绿。
- 地图底图保持真实 OSM 瓦片（rubric 必做项，见 [[swe311-coursework-rubric]]）。
- 服务器 schema 变更必须幂等（可重复执行不破坏既有数据）。

---

## ① Study Spot / Study Map 增强

### 现状（调查所得）
- `lib/features/map/study_map_screen.dart`、`lib/features/map/study_spots_screen.dart` 的 `AppBar` 都无 `leading` 返回按钮；现成 `lib/core/widgets/fallback_back_button.dart` 可复用。
- `StudySpot`（`lib/data/models/study_spot.dart`）字段：id/uid/name/latitude/longitude/note/createdAt，**无次数字段**。
- 记录方式纯手动：`study_map_screen.dart` 的 FAB `_addCurrentLocation` → `_locateMe()`（用 `geolocator`，封装在 `lib/core/services/location_service.dart`）取坐标 → 弹框输名 → `AppController.addStudySpot`。
- `StudySpotRepository`（`lib/data/repositories/study_spot_repository.dart`）：`listSpots()`/`addSpot(...)`/`deleteSpot(id)`，Mock(SharedPreferences) + Api(`/study-spots`)。
- 服务器 `study_spots` 表（`server/lib/src/database.dart`）+ `study_spot_policy.dart` + routes，**无次数列**。
- `flutter_map: ^7.0.2`，无 heatmap 插件，但自带 `CircleLayer`/`CircleMarker`。

### 设计
1. **返回箭头**：两页 `AppBar` 各加 `leading: const FallbackBackButton(fallbackLocation: '/home')`。
2. **次数字段**：`StudySpot` 加 `visitCount`（int，默认 1）；`fromJson`/`toJson` 增补；服务器 `study_spots` 表加 `visit_count` 列（幂等 `ALTER TABLE ... ADD COLUMN IF NOT EXISTS`，默认 1）。
3. **就近累加仓库方法**：`StudySpotRepository.recordVisit({required double latitude, required double longitude, required String name})`：
   - 用 `latlong2.Distance()` 找最近已有点；**距离 ≤ 100m → 该点 `visitCount++` 并更新时间戳；否则新建**（visitCount=1）。
   - Mock：在本地列表内聚合并持久化。Api：`POST /study-spots`（body 带 lat/lng/name），服务器执行就近 upsert（≤100m 累加，否则插入），返回该 spot（含 visitCount）。
   - `study_spot_policy.dart` 承载就近判定 + 累加/插入纯逻辑（可单测）。
   - 手动添加复用 `recordVisit`（name 用用户输入）；自动记录 name 用本地化默认名（如"学习地点"）。`addStudySpot` 改为内部走 `recordVisit`。
4. **自动记录挂钩**：`AppController.recordStudyVisit()`：取当前定位（`location_service`）→ `recordVisit(默认名)` → 刷新 `state.studySpots`。在 `completeLesson(...)` 与 `completeTraining(...)` **成功之后**调用；**定位被拒/超时/失败一律静默跳过**（仅 `debugPrint`，绝不抛出、不阻塞学习完成）。
5. **热力图**：`study_map_screen.dart` 在现有 `MarkerLayer` **下方**加一层 `CircleLayer`：每个 spot 一个 `CircleMarker`，`radius` 与 `color` 透明度按 `visitCount` 加权（次数越高越大越浓）。图钉保留可点查看详情/次数。`study_spots_screen.dart` 列表每条显示学习次数。

### 错误处理
定位拒绝/超时 → 自动记录跳过，不报错不阻塞；手动添加始终可用；服务器 upsert 失败 → 客户端回退为不计数（不崩，沿用现有错误流）。

### 测试
- 单元：就近聚合（<100m 累加、>100m 新建）—— `study_spot_policy`（服务器）+ Mock 仓库（客户端）。
- widget：两页存在返回按钮；`CircleLayer` 随 visitCount 渲染（Study Map 冒烟）。
- 服务器：`study_spot_policy` upsert + visit_count 累加测试。

---

## ② Passage Cloze 提速

### 现状（实测诊断）
带 token 实测 `POST /ai/cloze`：**200，耗时约 22 秒**。后端无故障；慢源于免费模型 `deepseek-v4-flash-free`（`server/lib/src/config.dart` `aiModel`）生成整段 cloze JSON 的输出量大。客户端 `lib/features/training/passage_cloze_screen.dart` 入口已有 loading/error/retry，但加载态文案不够明确。

### 设计
1. **减小生成量（主要提速）**：收紧 `server/lib/src/ai_policy.dart` 的 `buildSystemPrompt('cloze', ...)` —— 明确要求"一段简短的 $language 短文（2~3 句话）+ **恰好 3~4 个空**"，并要求短文精炼。输出 token 显著减少，预计 22s → 约 8~12s。客户端 `passage_cloze_screen` 的 prompt 文案同步收紧（"短"段落）。
2. **明确加载提示**：`passage_cloze_screen` 加载态显示明确文案（如"AI 正在生成短文，约需 10~20 秒…"）+ spinner。失败重试沿用现有。
3. **可配 cloze 模型口子（默认不变）**：`config.dart` 加 `aiClozeModel`（env `AI_CLOZE_MODEL`，**默认空 → 回退 `aiModel`**）；`AiRequest` 加可选 `modelOverride`；`_handleAiRequest` 对 `featureType=='cloze'` 传入 `aiClozeModel`（非空时）；`RemoteAiProvider.generate` 用 `request.modelOverride ?? model`。默认行为完全不变（仍用 flash），仅为将来拿到更快模型时可单独给 cloze 配置，不影响其它 AI。免费 provider 当前仅 flash 档无更快选项，故本轮默认不换模型。

### 测试
- 服务器：`ai_system_prompt_test` 断言 cloze 提示含"3~4 个空 / 简短短文"约束（关键词）；`RemoteAiProvider` 在 `modelOverride` 非空时用 override、为空时用默认（单测）。
- 客户端：`passage_cloze_screen` 加载态显示明确文案（widget 断言文案存在）。

---

## ③ 词书补全与多语言开放

### 现状（调查所得）
- 线上 `/wordbooks` 11 本：hsk1=489 完整，**hsk2-6 各仅 3 词 stub**（`server/data/wordbooks_p0.json`），jlpt_n5-n1 完整（`server/data/wordbooks_jlpt.json`）。HSK 书无 `language` 字段（客户端 `WordBook.fromJson` 默认 'zh'，`lib/data/models/lesson.dart`）。
- **客户端 assets 已有完整 HSK2-6**：`lib/assets/data/wordbook_hsk2..6.json` = 147/358/1040/2400/2500 词（`tools/generate_hsk_wordbooks.py` 从开源库生成）。
- 开放面相关：`kSupportedLanguages`（`language_wordbook_picker.dart`，en/es/fr/ms = hasBooks:false）、`_langPins`（`language_map_screen.dart`，en/es/fr/ms = enabled:false）、`study_plan_policy.dart`（allowedWordBookIds = hsk1-6 + jlpt_n5-n1）、`wordbook_asset_loader._bookIds`、routes `_wordBookDataFiles`。

### 设计
1. **HSK2-6 补全（零采集）**：用脚本把客户端完整 `lib/assets/data/wordbook_hsk1..6.json` 合成**完整版** `server/data/wordbooks_p0.json`（覆盖现有 stub 版，仍是单一 HSK 文件、6 本完整、id 不变、无重复）。`/wordbooks` 即返回完整 HSK2-6。
2. **en/es/fr/ms 各一本测试词书**：新增 `tools/generate_extra_wordbooks.py`，每语种生成一本 ~30 常用词词书：
   - 顶层字段对齐现有 WordBook 结构：`id`（`en_basic`/`es_basic`/`fr_basic`/`ms_basic`）、`title`/`titleEn`/`titleMs`、`category:'basic'`、`examType`、`language`（en/es/fr/ms）、`totalWords`/`includedWords`、`description`、`wordIds`、`createdAt`、`words[]`。
   - 每词：`id`、`word`、`phoneticUK`/`phoneticUS`（可留空或简单音标）、`audioUKUrl`/`audioUSUrl`（有道 dictvoice，按语种 `le` 参数）、`partOfSpeech`、`definitions`/`englishDefinitions`（英文释义）、`malayDefinitions`（可空）、`difficulty`、其余列表字段空。
   - 输出到 `server/data/wordbooks_extra.json`（4 本一组）+ 客户端 `lib/assets/data/wordbook_<id>.json`（各一本）。
3. **开放 6 处改点**：
   - `kSupportedLanguages`：en/es/fr/ms → `hasBooks: true`。
   - `_langPins`（language_map_screen）：en/es/fr/ms → `enabled: true`。
   - `study_plan_policy.dart`：`allowedWordBookIds` 加 `en_basic/es_basic/fr_basic/ms_basic`（hsk2-6/jlpt 已在）；若有 `allowedLanguages` 集合则加 en/es/fr/ms。
   - `wordbook_asset_loader._bookIds`：加 4 个新书 id。
   - routes `_wordBookDataFiles`：加 `wordbooks_extra.json`。
   - `pubspec.yaml` assets：确认 `lib/assets/data/` 已整目录纳入（新 json 自动包含）；如为逐文件登记则补登记。
4. **结果**：6 种语言全部可选 —— 中文 HSK1-6 完整、日语 JLPT N5-N1 完整、en/es/fr/ms 各一本测试书；地图 6 国 marker 全部可学。**充分覆盖 current 切换测试**（LANG-9）。

### 测试
- 服务器：`/wordbooks` 返回中 hsk2-6 词数 > 3（完整）、含 4 个 `*_basic` 书且带正确 `language`；数据文件 shape 测（extra 4 本、各语言正确、words 非空）。
- 客户端：picker 显示 6 种语言皆可选（widget）；`languageLabel`/`kSupportedLanguages` 含 6 语言。

---

## 跨部分：部署
本轮服务器改动较多，需统一部署到线上 `api.vonlan233.top`（rsync 排除密钥 + `vps_deploy.sh`，DB 不动除幂等迁移）：
- `wordbooks_p0.json`（完整 HSK2-6）、新增 `wordbooks_extra.json`；
- `study_spots` 表 `visit_count` 列（幂等迁移）+ 就近 upsert 端点；
- `ai_policy.dart` cloze 提示收紧 + `config` 的 `AI_CLOZE_MODEL`（默认不设）。
部署为最后一步，经用户同意后执行。客户端改动随 release APK 生效。

## 不在本轮范围
- 不引入 heatmap 第三方插件（用 CircleLayer 加权）。
- 不全局更换 AI 模型（仅留 cloze 可配口子，默认不变）。
- en/es/fr/ms 仅各一本测试书（非完整课程级词表）。
- 不做逆地理编码（自动记录用默认名 + 坐标，不解析地址）。

## 计划分解（预览）
1. ①-a 返回箭头（两页 + widget 测）。
2. ①-b 自动记录：StudySpot.visitCount + recordVisit 就近聚合(Mock/Api) + AppController hook + 服务器表列/policy/route + 单测。
3. ①-c 热力图 CircleLayer（+ 列表显示次数 + 冒烟测）。
4. ② Passage Cloze：cloze 提示收紧 + 加载提示 + AI_CLOZE_MODEL 口子 + 测。
5. ③-a HSK2-6 完整数据同步服务器（脚本生成完整 wordbooks_p0.json + 服务器测）。
6. ③-b en/es/fr/ms 测试词书生成 + 开放 6 处改点 + 客户端/服务器测。
