# P3 — Study Spots Map + 发音增强 + UI 打磨 — 设计文档

> 日期：2026-06-19 · 分支：feat/P3-Multimedia-Map-Data_Persistence · 状态：已确认，进入 writing-plans

## 背景与目标

作业 ASM2 P3 要求：改进 App 设计/UI（继续 Flutter）、≥10 个可工作页面、3 种导航（BottomNavigationBar / Drawer / TabBar）、一致的布局/配色/字体、所有页面截图；并集成 3 个高级功能：**Map**、**Multimedia**、**Data Persistence**（动态数据延用现有数据库）。

现状评估（已探查）：

- App 已极成熟：50+ 页面，覆盖全部 10 类（Splash/Login/Register/Onboarding/Home/List/Detail/Add-Edit/Profile-Settings/About/Help/Search）。
- 导航：BottomNavigationBar（`ShellRoute`，6 tab）+ TabBar（排行榜 global/friends/class）已有；**Drawer 缺失**。
- 主题：Cozy Quest 设计系统（`app_tokens.dart` / `app_theme.dart` / `core/widgets/`）统一。
- 多媒体：`audioplayers` 已用于发音（`core/widgets/pronunciation_controls.dart`），但 HSK 中文词常无音频 URL，按下不出声。
- 地图/定位：**完全没有**（无 flutter_map/geolocator）。
- 持久化：offline-first 仓库模式（Mock=SharedPreferences / Api=后端 Postgres via Dio）。

因此本次真正的新工作聚焦：**A. Study Spots 地图**（全新）、**B. 发音增强**（多媒体）、**C. UI 打磨 + Drawer 导航 + 截图清单**。数据持久化延用现有后端 Postgres + 离线 Mock，不引入 Firebase/SQLite。

## 范围与拆分

三个独立子功能，共用本 spec，各自独立实现/测试：

- **A. Study Spots（地图学习点追踪）**
- **B. 发音增强（Multimedia / TTS 兜底 + 控制 + 移除弹窗）**
- **C. UI 打磨 + Drawer 导航 + 截图清单**

持久化为横切关注点，遵循现有架构。

---

## A. Study Spots（地图学习点追踪）

### 用途
在学中文（HSK）App 中记录"我在哪里学习"：进入地图看当前位置；学习/复习后（或手动）保存"学习点"（经纬度 + 名称 + 学习时长 + 时间）；地图标记所有学习点；列表页看历史 + 总时长统计；可删除。满足作业"显示/追踪位置" + 数据持久化 + 学习主题，自包含（不依赖他人真实地理数据）。

### 技术选型
- 地图渲染：`flutter_map`（OpenStreetMap 瓦片，免费、无需 API key）+ `latlong2`。
- 定位：`geolocator`（当前位置 + 权限请求）。
- Android：`AndroidManifest.xml` 增加 `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` 权限。

### 数据模型
`StudySpot`（`lib/data/models/study_spot.dart`）：`id`、`name`、`latitude`、`longitude`、`studyMinutes`、`createdAt`。`toJson`/`fromJson`。

### 持久化（双实现，遵循 CLAUDE.md 铁律）
- 抽象 `StudySpotRepository`：`Future<List<StudySpot>> list()`、`Future<StudySpot> add(StudySpot)`、`Future<void> remove(String id)`。
- `MockStudySpotRepository`（`mock_repositories.dart`）：SharedPreferences 持久化（离线默认）。
- `ApiStudySpotRepository`（`api_repositories.dart`）：后端 `GET/POST/DELETE /study-spots`（Dio）。
- Provider `studySpotRepositoryProvider`（`app_controller.dart`）按 `AppConstants.apiBaseUrl.isNotEmpty` 切换。
- 状态：`AppState` 增 `List<StudySpot> studySpots`；`AppController` 增 `loadStudySpots()`、`saveStudySpot()`、`deleteStudySpot()`。

### 服务端
- `database.dart`：`CREATE TABLE IF NOT EXISTS study_spots (id uuid pk, user_id, name, latitude double precision, longitude double precision, study_minutes int, created_at)` + 查询方法（list/insert/delete by user）。
- `study_spot_policy.dart`：校验（名称非空、经纬度范围合法）。
- `routes.dart`：`GET /study-spots`、`POST /study-spots`、`DELETE /study-spots/<id>`（均 `_protected` 鉴权）。

### UI
- `lib/features/map/study_map_screen.dart`：flutter_map + 当前位置标记 + 学习点标记 + "保存此处为学习点" FAB（弹 AppCard 表单填名称/时长）。
- `lib/features/map/study_spots_list_screen.dart`：列表 + 总时长统计 + 删除。
- 路由 `/map`、`/map/spots`，入口放 Drawer（见 C）。
- 用 Cozy Quest 组件（AppCard/AppPrimaryButton/AppPill）。

### 失败/权限处理
- 定位权限被拒：显示可读提示 + "去设置"或"手动选点"降级（地图中心默认一个城市，允许长按选点）。
- 无网络：地图瓦片可能加载失败 → 显示占位 + 重试；学习点仍可离线保存（Mock）。

---

## B. 发音增强（Multimedia）

### 目标
HSK 中文词从"按下不出声"变"必出声"；移除点发音时的 SnackBar 弹窗；加播放控制。全 App 4 处发音统一生效（`word_detail` / `target_word_detail` / `lesson_preview` / `training_session`）。

### 实现
- 加 `flutter_tts`。
- 新建 `lib/core/services/pronunciation_service.dart`：`PronunciationService`
  - `play(word, {audioUrl, language, slow})`：**优先** `audioUrl`（audioplayers UrlSource）；URL 为空或播放失败 → **TTS 兜底**（中文 `zh-CN`、英文 `en-GB`/`en-US`，`slow` 时 setSpeechRate 0.4，正常 0.5）。
  - 暴露播放状态流/回调供 UI 显示。
- 改 `pronunciation_controls.dart`：
  - 接入 `PronunciationService`（URL→TTS 兜底）。
  - 加**慢速**按钮（或长按慢速）、**重复播放**。
  - **移除所有 `_showMessage` SnackBar 弹窗**（"US: 正在播放/不可用"那种）；改为仅按钮内联状态（播放中/加载/失败内联红字，已有）。
- 发音偏好（默认慢速开关、英文默认口音）：SharedPreferences。
- 不新增 ARB key（i18n 冻结）；复用现有发音文案，移除弹窗后未用文案保留即可（不删 ARB）。

### 失败处理
- URL 失败 → 自动 TTS 兜底，不弹窗；TTS 也不可用（极少）→ 按钮内联失败态。

---

## C. UI 打磨 + Drawer 导航 + 截图清单

### Drawer（补齐第 3 种导航）
- 在 `features/shell/app_shell.dart` 的 Scaffold 加 `Drawer`：品牌头 + 入口（Map、发音/学习设置、Search、About、Help、Settings、Profile）。
- BottomNav（已有）+ TabBar（已有）+ Drawer（新增）= 作业要求的 3 种导航齐备。

### 轻量打磨
- 新页面（Map/列表）一律用 Cozy Quest 组件，保证布局/配色/字体一致。
- 不重做现有页面设计（避免动现有测试与回归）。

### 截图清单（报告用）
- 整理 ≥10 页面 → 路由 → 截图的对照表，写入 `docs/release/p3-screens.md`：Splash `/`、Onboarding `/onboarding`、Login `/login`、Register `/register`、Home `/home`、Wordbook 列表 `/wordbook`、Word 详情 `/wordbook/:id`、Add/Edit `/custom-words/new`、Profile/Settings `/profile`、`/settings`、About `/about`、Help `/help`、Search `/search`、Study Map `/map`（新）。
- 截图采集方式说明（emulator + `flutter screenshot` 或手动）。

---

## 数据持久化（延用现有，跨切面）

- Study Spots：后端 `study_spots`（Postgres）+ Api 仓库；离线 `MockStudySpotRepository`（SharedPreferences）。
- 发音偏好：SharedPreferences。
- **不引入 Firebase/SQLite**（已确认延用现有数据库）。

## 依赖新增（pubspec）

- `flutter_map`、`latlong2`、`geolocator`、`flutter_tts`。

## 测试

- Flutter：
  - `StudySpot` 模型 toJson/fromJson 单测。
  - `MockStudySpotRepository`（SharedPreferences 往返）单测。
  - `PronunciationService` 选源逻辑单测（有 URL 走 URL；无 URL 走 TTS；URL 失败回退 TTS）——TTS/audio 用可注入的假实现，离线可跑。
  - widget 冒烟：map 屏构建、pronunciation controls 无弹窗。
- Server：`study_spot_policy_test.dart`（校验，离线纯测）；`study_spots` 路由测试（依赖 Postgres，标注）。
- 全程 `flutter analyze`/`flutter test`、`dart test` 绿。

## 受影响 / 新增文件（概览）

新增：`data/models/study_spot.dart`、`data/repositories/study_spot_repository.dart`、`features/map/study_map_screen.dart`、`features/map/study_spots_list_screen.dart`、`core/services/pronunciation_service.dart`、`server/lib/src/study_spot_policy.dart`、各测试、`docs/release/p3-screens.md`。
修改：`mock_repositories.dart`、`api_repositories.dart`、`app_controller.dart`、`app_state.dart`、`app_router.dart`、`app_shell.dart`、`pronunciation_controls.dart`、`pubspec.yaml`、`AndroidManifest.xml`、`server/lib/src/database.dart`、`server/lib/src/routes.dart`。

## 安全 / 约束

- 不新增 ARB key（i18n 冻结）。
- 新数据域双实现（Mock + Api），否则 demo 模式破坏。
- 用 `AppTokens.*` 与 Cozy Quest 组件，不硬编码样式。
- 原子提交，不加 Co-Authored-By trailer。
- 定位权限：仅在用户进入地图时请求；拒绝有降级路径。
