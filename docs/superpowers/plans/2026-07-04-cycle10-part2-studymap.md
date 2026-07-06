# Cycle 10 Part 2：Study Map 完整恢复 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 恢复被 `ea68e35` 整体删除的 Study Map 功能（GPS/长按记录学习地点 + visitCount 就近累加 + 热力图 + 列表 + 后端持久化），适配当前架构。

**Architecture:** 以 `ea68e35^`（删除前）旧代码为**蓝本**（`git show ea68e35^:<path>` 取），重新集成到当前 Flutter（Riverpod provider apiBaseUrl 模式 + go_router）+ Dart shelf/Postgres server。**不是 git revert**（后续 Cycle 7/8/9 演进，revert 会冲突）。

**Tech Stack:** flutter_map ^7.0.2、latlong2 ^0.9.1（均已在）、geolocator（需 pub add，曾被 49eee53 删）、Dart shelf/postgres。

## Global Constraints
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 每 task 明确列出的文件（**禁 `git add -A/./-u`**）。
- flutter 命令在 `linguaquest/`，server 在 `server/`。现有测试全绿：`flutter test`/`analyze`、`dart test`/`analyze`。
- 所有 repository provider 走当前 `if (AppConstants.apiBaseUrl.isNotEmpty) → ApiX else MockX` 模式（模板见 `app_controller.dart` 的 `forumRepositoryProvider`）。
- **地图必须真实 OSM 瓦片**（用户 2026-06-29 强调），不可插画/静态图替代。
- **后端表 study_spots 已在线上（未 DROP）**——只用 `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` 迁移，**绝不 DROP/改现有列**。
- 需部署项用户已预授权（rsync + `deploy/vps_deploy.sh`）。
- 源：`docs/superpowers/specs/2026-07-04-cycle10-studymap-restore-qa3-fixes.md`（SM 节）。

## 已核实的旧代码蓝本（关键签名，实现时 `git show ea68e35^:<path>` 取完整）
- **StudySpot** (`lib/data/models/study_spot.dart`): `{String id, String name, double latitude, double longitude, int studyMinutes, DateTime createdAt, int visitCount=1}` + toJson/fromJson。
- **StudySpotRepository** (`lib/data/repositories/study_spot_repository.dart`): `Future<List<StudySpot>> list()` / `Future<StudySpot> add(StudySpot)` / `Future<StudySpot> recordVisit({required double latitude, required double longitude, required String name})` / `Future<void> remove(String id)`。
- **Api** (在 `api_repositories.dart`): `list()`→`GET /study-spots`（读 `response['spots']`）；`add`/`recordVisit`→`POST /study-spots`（body name/latitude/longitude...，返回 StudySpot json）。
- **Mock** (在 `mock_repositories.dart`): SharedPreferences 存储；`recordVisit` 就近累加——`Distance()` 算米，**≤100m 聚合**（`visitCount+1`），否则新建 `spot-${microsecondsSinceEpoch}`。
- **location_service** (`lib/core/services/location_service.dart`): `Future<LatLng?> currentLatLng()`——geolocator checkPermission/requestPermission/getCurrentPosition，denied/异常返回 null（never throws）。
- **state/controller**: `AppState.studySpots: List<StudySpot>=const[]`；`studySpotRepositoryProvider`（apiBaseUrl 模式）；`loadStudySpots()`/`saveStudySpot(spot)`/`deleteStudySpot(id)`/`recordStudyVisit({required String name, double? latitude, double? longitude})`（传坐标或取 GPS，null 静默 skip，失败 swallow）。
- **screen** (`lib/features/map/study_map_screen.dart`): imports 全在当前代码（flutter_map/latlong2/location_service/app_controller/app_tokens/app_card/app_button/fallback_back_button）；fallback 中心 `LatLng(3.139, 101.6869)` KL；`_saveHere()`（currentLatLng）/`_saveAt(loc)`（命名 dialog）；`onLongPress → _saveAt`；`TileLayer(urlTemplate:'https://tile.openstreetmap.org/{z}/{x}/{y}.png')`；**热力图** `CircleLayer` 每 spot：`radius:(12+visitCount*6).clamp(12,48)`、`color alpha:(0.15+visitCount*0.12).clamp(0.15,0.6)`；`MarkerLayer` 显示 spots。`study_spots_list_screen.dart` 列表显示 name+visitCount。
- **后端** `study_spot_policy.dart`: haversine + `nearestWithin(List<({double latitude,double longitude})> spots, withinMeters)→int?` + `validate(name/lat/lng)`。`routes.dart`: `GET /study-spots`（`listStudySpots(uid)`）、`POST /study-spots`（validate + 就近 upsert）、`DELETE /study-spots/<id>`（`deleteStudySpot(uid,id)`）——均需 bearer uid。
- **当前 study_spots 表**（`server/lib/src/database.dart:481`）: `id UUID, user_id TEXT, name TEXT, latitude/longitude DOUBLE, study_minutes INTEGER DEFAULT 0, created_at TIMESTAMPTZ`——**缺 visit_count 列**。
- 当前 `/map` 路由与 Drawer "Study Map" 入口**已移除**（`app_router.dart` 仅剩 language_map import）；加回时参考 language_map 的 router/drawer 写法。

---

### Task 1: 数据层（SM.1 — model + repo abstract + Api + Mock）

**Files:**
- Create: `linguaquest/lib/data/models/study_spot.dart`
- Create: `linguaquest/lib/data/repositories/study_spot_repository.dart`
- Modify: `linguaquest/lib/data/repositories/api_repositories.dart`（加 `ApiStudySpotRepository`）
- Modify: `linguaquest/lib/data/repositories/mock_repositories.dart`（加 `MockStudySpotRepository`）
- Test: `linguaquest/test/data/study_spot_test.dart`、`test/data/study_spot_record_visit_test.dart`、`test/data/mock_study_spot_repository_test.dart`（从 `ea68e35^` 恢复）

**实现要求：**
1. `git show ea68e35^:linguaquest/lib/data/models/study_spot.dart` 恢复 model 原样（无需适配，纯数据类）。
2. `git show ea68e35^:linguaquest/lib/data/repositories/study_spot_repository.dart` 恢复 abstract。
3. `ApiStudySpotRepository`：`git show ea68e35^:linguaquest/lib/data/repositories/api_repositories.dart` 找该类，恢复到当前 `api_repositories.dart`（用当前 `ApiClient`/`dio` 用法——照抄文件里其他 Api 类的 dio 调用风格确认一致）。
4. `MockStudySpotRepository`：`git show ea68e35^:linguaquest/lib/data/repositories/mock_repositories.dart` 找该类，恢复（含 SharedPreferences 读写 + 就近累加 ≤100m 逻辑原样）。
5. 恢复对应旧测试（`git show ea68e35^:linguaquest/test/data/study_spot_test.dart` 等），确认与恢复的接口匹配。

- [ ] Step 1: `git show` 恢复 model/repo/测试到新文件；grep 旧 api/mock 的 StudySpot 类恢复到当前文件对应位置
- [ ] Step 2: Run `cd linguaquest && flutter test test/data/study_spot_test.dart test/data/study_spot_record_visit_test.dart test/data/mock_study_spot_repository_test.dart` — Expected: PASS（就近累加 ≤100m 聚合、model 序列化）
- [ ] Step 3: `flutter analyze` — Expected: No issues
- [ ] Step 4: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/data/models/study_spot.dart lib/data/repositories/study_spot_repository.dart lib/data/repositories/api_repositories.dart lib/data/repositories/mock_repositories.dart test/data/study_spot_test.dart test/data/study_spot_record_visit_test.dart test/data/mock_study_spot_repository_test.dart
git commit -m "feat(map): 恢复 StudySpot model + repository(Api/Mock 就近累加≤100m) + 单测"
```

---

### Task 2: 定位服务 + geolocator 依赖 + Android 权限（SM.2）

**Files:**
- Create: `linguaquest/lib/core/services/location_service.dart`
- Modify: `linguaquest/pubspec.yaml`（`flutter pub add geolocator`）
- Modify: `linguaquest/android/app/src/main/AndroidManifest.xml`（加定位权限）

**实现要求：**
1. `cd linguaquest && flutter pub add geolocator`（解析 flutter 3.41 兼容版）。
2. `git show ea68e35^:linguaquest/lib/core/services/location_service.dart` 恢复 `currentLatLng()`（原样，never-throws 返回 LatLng?）。
3. `AndroidManifest.xml`：在 `<manifest>` 内加 `<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>` 和 `ACCESS_COARSE_LOCATION`（先 Read 确认未重复）。

- [ ] Step 1: `flutter pub add geolocator`；恢复 location_service.dart；改 AndroidManifest
- [ ] Step 2: Run `cd linguaquest && flutter analyze` — Expected: No issues（location_service 编译通过，geolocator 解析成功）
- [ ] Step 3: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/core/services/location_service.dart pubspec.yaml pubspec.lock android/app/src/main/AndroidManifest.xml
git commit -m "feat(map): 恢复 location_service(geolocator) + Android 定位权限"
```
> 无独立单测（geolocator 依赖平台，纯封装）；`analyze` 编译验证 + Task 5 设备验证。

---

### Task 3: 状态层（SM.3 — app_state + app_controller）

**Files:**
- Modify: `linguaquest/lib/core/state/app_state.dart`（加 `studySpots` 字段 + copyWith）
- Modify: `linguaquest/lib/core/state/app_controller.dart`（加 provider + load/save/delete/recordStudyVisit）
- Test: `linguaquest/test/data/study_spot_state_test.dart`（从 `ea68e35^` 恢复）

**Interfaces（Consumes）:** Task 1 的 `StudySpotRepository`/`StudySpot`；Task 2 的 `currentLatLng()`。

**实现要求：**
1. `app_state.dart`：加 `final List<StudySpot> studySpots;`（构造默认 `const []`）+ copyWith 分支 + 初始 state 的 `studySpots: const []`（照 `ea68e35^:app_state.dart` 的 :144/188/371/422/457 位置，适配当前 AppState 结构——当前 AppState 字段更多，插入到合适处）。
2. `app_controller.dart`：加 `studySpotRepositoryProvider`（**用当前 apiBaseUrl 模式**，模板 forumRepositoryProvider）；加 `loadStudySpots()`/`saveStudySpot(spot)`/`deleteStudySpot(id)`/`recordStudyVisit({required String name, double? latitude, double? longitude})`（`git show ea68e35^:app_controller.dart` 的 :2940-2985 恢复，`import location_service` 用 currentLatLng）。
3. 恢复 `test/data/study_spot_state_test.dart`。

- [ ] Step 1: 改 app_state（studySpots）；确认 RED（恢复的 state 测试引用 studySpots 尚未加时失败）
- [ ] Step 2: 改 app_controller（provider + 方法）
- [ ] Step 3: Run `cd linguaquest && flutter test test/data/study_spot_state_test.dart && flutter analyze` — Expected: PASS + No issues
- [ ] Step 4: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/core/state/app_state.dart lib/core/state/app_controller.dart test/data/study_spot_state_test.dart
git commit -m "feat(map): 恢复 studySpots 状态 + provider + load/save/delete/recordStudyVisit"
```

---

### Task 4: 后端端点 + visit_count 迁移（SM.5，需部署）

**Files:**
- Create: `server/lib/src/study_spot_policy.dart`
- Modify: `server/lib/src/routes.dart`（加 `/study-spots` GET/POST/DELETE）
- Modify: `server/lib/src/database.dart`（加 `visit_count` 列迁移 + listStudySpots/就近upsert/deleteStudySpot 方法）
- Test: `server/test/study_spot_policy_test.dart`（从 `ea68e35^` 恢复）

**实现要求：**
1. `git show ea68e35^:server/lib/src/study_spot_policy.dart` 恢复 policy（haversine + nearestWithin + validate）。
2. **schema 迁移**：当前 `study_spots` 表缺 `visit_count`。在 database.dart 现有 study_spots CREATE TABLE 之后，加 `ALTER TABLE study_spots ADD COLUMN IF NOT EXISTS visit_count INTEGER NOT NULL DEFAULT 1;`（照现有其它 ALTER 迁移风格，如 email_verified 那种）。**不 DROP、不改现有列。**
3. `database.dart` 恢复/新增方法：`listStudySpots(uid)`（SELECT + visit_count）、就近 upsert（`git show ea68e35^:server/lib/src/database.dart` grep study_spot 找旧实现；用 policy.nearestWithin 找 ≤阈值的既有 spot → UPDATE visit_count+1，否则 INSERT；**注意旧代码有 `6e258cb` 标注的「就近 upsert 非原子简化」ponytail 注释，一并恢复**）、`deleteStudySpot(uid,id)`。返回行含 visit_count（映射 StudySpot json 的 visitCount）。
4. `routes.dart` 恢复三端点（`git show ea68e35^:server/lib/src/routes.dart` 的 :1398-1430）：GET/POST/DELETE `/study-spots`，bearer uid 鉴权（照当前 routes 其它端点的 verifyToken/uid 提取方式），POST 走 validate + 就近 upsert，返回 `{'spots': [...]}`（GET）/ StudySpot json（POST）。
5. 恢复 `test/study_spot_policy_test.dart`。

- [ ] Step 1: 恢复 policy + 测试；Run `cd server && dart test test/study_spot_policy_test.dart` — Expected: PASS
- [ ] Step 2: database.dart 加 visit_count 迁移 + 方法；routes 加端点
- [ ] Step 3: Run `cd server && dart analyze && dart test` — Expected: No issues + 全绿
- [ ] Step 4: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server
git add lib/src/study_spot_policy.dart lib/src/routes.dart lib/src/database.dart test/study_spot_policy_test.dart
git commit -m "feat(server): 恢复 study-spots 端点 + 就近 upsert + visit_count 列迁移 + policy 单测"
```
> 部署由控制者统一执行（curl 带 token 验 GET/POST /study-spots）。

---

### Task 5: 屏幕 + 路由 + Drawer 入口 + 热力图（SM.4）

**Files:**
- Create: `linguaquest/lib/features/map/study_map_screen.dart`、`study_spots_list_screen.dart`
- Modify: `linguaquest/lib/core/routing/app_router.dart`（加 `/map` 路由）
- Modify: `linguaquest/lib/features/shell/app_drawer.dart`（加 "Study Map" 入口）
- Test: `linguaquest/test/features/study_map_smoke_test.dart`、`test/features/study_spots_list_test.dart`（从 `ea68e35^` 恢复）

**Interfaces（Consumes）:** Task 3 的 `studySpots` state + `loadStudySpots`/`saveStudySpot`；Task 2 的 `currentLatLng()`。

**实现要求：**
1. `git show ea68e35^:linguaquest/lib/features/map/study_map_screen.dart` + `study_spots_list_screen.dart` 恢复（imports 全在当前代码，直接用；热力图 CircleLayer 公式、fallback KL、_saveHere/_saveAt/onLongPress、TileLayer OSM 原样）。
2. `app_router.dart`：加 `/map → StudyMapScreen`（参考 language_map 路由写法，import study_map_screen）；列表页 `/map/spots` 或屏内导航照旧代码。
3. `app_drawer.dart`：加 "Study Map" 项 → `context.push('/map')`（参考 Drawer 现有项 + language_map "Choose Language" 项写法；文案用 l10n 或与旧代码一致）。
4. 恢复 smoke/list 测试。

- [ ] Step 1: 恢复两屏幕 + 测试
- [ ] Step 2: 加 /map 路由 + Drawer 入口
- [ ] Step 3: Run `cd linguaquest && flutter test test/features/study_map_smoke_test.dart test/features/study_spots_list_test.dart && flutter analyze` — Expected: PASS + No issues
- [ ] Step 4: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/features/map/study_map_screen.dart lib/features/map/study_spots_list_screen.dart lib/core/routing/app_router.dart lib/features/shell/app_drawer.dart test/features/study_map_smoke_test.dart test/features/study_spots_list_test.dart
git commit -m "feat(map): 恢复 Study Map 屏幕+列表+热力图 + /map 路由 + Drawer 入口"
```

---

## 全量验证（所有 task 后）
`cd linguaquest && flutter analyze && flutter test`；`cd server && dart analyze && dart test` — 全绿。

## 部署（Task 4 server）+ 设备验证
- 部署 server（visit_count 迁移 + /study-spots 端点）→ `deploy/vps_deploy.sh`（curl 带 token 验端点）。
- 连后端 APK 设备验证：Drawer → "Study Map" → 真 OSM 地图；"Save here"（有 GPS）或长按选点 → 命名 → spot 落库；重复就近（≤100m）→ visitCount 累加 + 热力图 circle 变大变浓；列表显示次数；kill/restart 持久化。

## 说明
- 恢复策略是「git show 蓝本 + 适配当前架构」，非 git revert。适配点：provider 用当前 apiBaseUrl 模式；组件/tokens 名当前均存在直接用；后端补 visit_count 列迁移；geolocator 重新 pub add；/map 路由与 Drawer 入口加回。
- 一处有意简化沿用旧标注：后端就近 upsert 非原子（`ponytail` 注释一并恢复，边界：并发下同点可能生成两条，学习地点低频可接受）。
