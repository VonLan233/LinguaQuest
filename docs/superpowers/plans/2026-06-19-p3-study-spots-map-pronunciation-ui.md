# P3 — Study Spots Map + Pronunciation Enhancement + UI/Drawer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 LinguaQuest 加入 Study Spots 地图追踪、发音 TTS 兜底+控制（并移除发音弹窗）、Drawer 导航与截图清单，动态数据延用现有后端 Postgres + 离线 Mock。

**Architecture:** 三个独立子系统，按现有模式实现。A 部分（Map）：`StudySpot` 模型 + `StudySpotRepository`（Mock=SharedPreferences / Api=后端）+ 后端 `study_spots` 表/policy/路由 + flutter_map 屏幕。B 部分（发音）：`PronunciationService`（URL→TTS 兜底）+ 重写 `PronunciationControls`（去弹窗、加慢速/重复）。C 部分（UI）：app_shell 加 `Drawer` + 截图清单文档。

**Tech Stack:** Flutter 3.x, Dart 3.11.4, Riverpod, GoRouter, shared_preferences, flutter_map, latlong2, geolocator, flutter_tts, audioplayers；server shelf + postgres。

## Global Constraints

- 新数据域必须双实现（Mock + Api）并按 `AppConstants.apiBaseUrl.isNotEmpty` 切换 provider，否则 demo 模式破坏。
- 不新增 ARB / l10n key（i18n 冻结）；复用现有本地化串或现有通用串。
- 用 `AppTokens.*` 与 Cozy Quest 组件（AppCard/AppPrimaryButton/AppSecondaryButton/AppPill），不硬编码颜色/间距。
- 不引入 Firebase/SQLite；动态数据延用现有后端 Postgres + 离线 SharedPreferences。
- 定位权限仅在进入地图时请求；被拒有降级路径（手动长按选点）。
- TDD：先失败测试 → 实现 → 通过；claims 贴真实输出。
- 提交：原子提交，**不加** Co-Authored-By trailer。
- `flutter analyze` / `flutter test` / `dart test` 全绿（DB 依赖测试标注，离线跳过原因写清）。

---

# Part A — Study Spots Map

### Task A1: StudySpot model

**Files:**
- Create: `linguaquest/lib/data/models/study_spot.dart`
- Test: `linguaquest/test/data/study_spot_test.dart`

**Interfaces:**
- Produces: `class StudySpot { final String id; final String name; final double latitude; final double longitude; final int studyMinutes; final DateTime createdAt; StudySpot({...}); Map<String,dynamic> toJson(); factory StudySpot.fromJson(Map<String,dynamic>); }`

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/data/study_spot_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/study_spot.dart';

void main() {
  test('StudySpot round-trips through json', () {
    final spot = StudySpot(
      id: 's1',
      name: 'Library',
      latitude: 3.139,
      longitude: 101.6869,
      studyMinutes: 25,
      createdAt: DateTime.utc(2026, 6, 19, 10, 30),
    );
    final json = spot.toJson();
    final back = StudySpot.fromJson(json);
    expect(back.id, 's1');
    expect(back.name, 'Library');
    expect(back.latitude, closeTo(3.139, 1e-9));
    expect(back.longitude, closeTo(101.6869, 1e-9));
    expect(back.studyMinutes, 25);
    expect(back.createdAt, DateTime.utc(2026, 6, 19, 10, 30));
  });

  test('fromJson tolerates int/num lat-lng and string id', () {
    final back = StudySpot.fromJson({
      'id': 42,
      'name': 'Park',
      'latitude': 3,
      'longitude': 101,
      'studyMinutes': 10,
      'createdAt': '2026-06-19T10:30:00.000Z',
    });
    expect(back.id, '42');
    expect(back.latitude, 3.0);
    expect(back.longitude, 101.0);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd linguaquest && flutter test test/data/study_spot_test.dart`
Expected: FAIL — `study_spot.dart` not found / `StudySpot` undefined.

- [ ] **Step 3: Implement**

Create `linguaquest/lib/data/models/study_spot.dart`:

```dart
class StudySpot {
  const StudySpot({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.studyMinutes,
    required this.createdAt,
  });

  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int studyMinutes;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'studyMinutes': studyMinutes,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };

  factory StudySpot.fromJson(Map<String, dynamic> json) => StudySpot(
        id: json['id'].toString(),
        name: (json['name'] as String?) ?? '',
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        studyMinutes: (json['studyMinutes'] as num?)?.toInt() ?? 0,
        createdAt:
            DateTime.tryParse(json['createdAt']?.toString() ?? '')?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd linguaquest && flutter test test/data/study_spot_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/data/models/study_spot.dart linguaquest/test/data/study_spot_test.dart
git commit -m "feat(map): add StudySpot model"
```

---

### Task A2: StudySpotRepository interface + Mock (SharedPreferences)

**Files:**
- Create: `linguaquest/lib/data/repositories/study_spot_repository.dart`
- Modify: `linguaquest/lib/data/repositories/mock_repositories.dart`
- Test: `linguaquest/test/data/mock_study_spot_repository_test.dart`

**Interfaces:**
- Consumes: `StudySpot` (Task A1).
- Produces: `abstract class StudySpotRepository { Future<List<StudySpot>> list(); Future<StudySpot> add(StudySpot spot); Future<void> remove(String id); }` and `class MockStudySpotRepository implements StudySpotRepository`.

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/data/mock_study_spot_repository_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/data/models/study_spot.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('add then list persists across repository instances', () async {
    final repo = MockStudySpotRepository();
    final added = await repo.add(StudySpot(
      id: '',
      name: 'Cafe',
      latitude: 3.1,
      longitude: 101.6,
      studyMinutes: 15,
      createdAt: DateTime.utc(2026, 6, 19),
    ));
    expect(added.id, isNotEmpty);

    final fresh = MockStudySpotRepository();
    final spots = await fresh.list();
    expect(spots.length, 1);
    expect(spots.first.name, 'Cafe');
  });

  test('remove deletes the spot', () async {
    final repo = MockStudySpotRepository();
    final a = await repo.add(StudySpot(
      id: '', name: 'A', latitude: 1, longitude: 2, studyMinutes: 5,
      createdAt: DateTime.utc(2026, 6, 19)));
    await repo.add(StudySpot(
      id: '', name: 'B', latitude: 3, longitude: 4, studyMinutes: 5,
      createdAt: DateTime.utc(2026, 6, 19)));
    await repo.remove(a.id);
    final spots = await repo.list();
    expect(spots.map((s) => s.name), ['B']);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd linguaquest && flutter test test/data/mock_study_spot_repository_test.dart`
Expected: FAIL — `StudySpotRepository`/`MockStudySpotRepository` undefined.

- [ ] **Step 3: Implement interface**

Create `linguaquest/lib/data/repositories/study_spot_repository.dart`:

```dart
import '../models/study_spot.dart';

abstract class StudySpotRepository {
  Future<List<StudySpot>> list();
  Future<StudySpot> add(StudySpot spot);
  Future<void> remove(String id);
}
```

- [ ] **Step 4: Implement Mock**

In `linguaquest/lib/data/repositories/mock_repositories.dart`: add imports at top if missing (`import 'dart:convert';`, `import '../models/study_spot.dart';`, `import 'study_spot_repository.dart';` — check existing imports first and only add what's absent), then append the class:

```dart
class MockStudySpotRepository implements StudySpotRepository {
  static const _key = 'mock_study_spots';

  Future<List<StudySpot>> _read(SharedPreferences prefs) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => StudySpot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _write(SharedPreferences prefs, List<StudySpot> spots) async {
    await prefs.setString(
        _key, jsonEncode(spots.map((s) => s.toJson()).toList()));
  }

  @override
  Future<List<StudySpot>> list() async {
    final prefs = await SharedPreferences.getInstance();
    final spots = await _read(prefs);
    spots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return spots;
  }

  @override
  Future<StudySpot> add(StudySpot spot) async {
    final prefs = await SharedPreferences.getInstance();
    final spots = await _read(prefs);
    final id = spot.id.isNotEmpty
        ? spot.id
        : 'spot-${DateTime.now().microsecondsSinceEpoch}';
    final saved = StudySpot(
      id: id,
      name: spot.name,
      latitude: spot.latitude,
      longitude: spot.longitude,
      studyMinutes: spot.studyMinutes,
      createdAt: spot.createdAt,
    );
    spots.add(saved);
    await _write(prefs, spots);
    return saved;
  }

  @override
  Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final spots = await _read(prefs);
    spots.removeWhere((s) => s.id == id);
    await _write(prefs, spots);
  }
}
```

> 注：若 `mock_repositories.dart` 顶部已 `import 'dart:convert';` / shared_preferences，勿重复。`SharedPreferences` 已在该文件被广泛使用，import 应已存在。

- [ ] **Step 5: Run test to verify it passes**

Run: `cd linguaquest && flutter test test/data/mock_study_spot_repository_test.dart`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/data/repositories/study_spot_repository.dart linguaquest/lib/data/repositories/mock_repositories.dart linguaquest/test/data/mock_study_spot_repository_test.dart
git commit -m "feat(map): add StudySpotRepository interface + SharedPreferences mock"
```

---

### Task A3: Server — study_spots table + policy + routes

**Files:**
- Create: `server/lib/src/study_spot_policy.dart`
- Create: `server/test/study_spot_policy_test.dart`
- Modify: `server/lib/src/database.dart` (table + query methods)
- Modify: `server/lib/src/routes.dart` (3 routes)

**Interfaces:**
- Produces (policy): `class StudySpotPolicy { static String? validate({required String name, required double latitude, required double longitude}); }` returning an error code string or null.
- Produces (db): `AppDatabase.listStudySpots(String userId)`, `insertStudySpot(String userId, {required String name, required double latitude, required double longitude, required int studyMinutes})`, `deleteStudySpot(String userId, String id)`.

- [ ] **Step 1: Write the failing policy test**

Create `server/test/study_spot_policy_test.dart`:

```dart
import 'package:test/test.dart';
import '../lib/src/study_spot_policy.dart';

void main() {
  test('valid spot returns null', () {
    expect(
      StudySpotPolicy.validate(name: 'Library', latitude: 3.1, longitude: 101.6),
      isNull,
    );
  });
  test('empty name rejected', () {
    expect(
      StudySpotPolicy.validate(name: '  ', latitude: 3.1, longitude: 101.6),
      equals('name_required'),
    );
  });
  test('latitude out of range rejected', () {
    expect(
      StudySpotPolicy.validate(name: 'X', latitude: 91, longitude: 0),
      equals('invalid_coordinates'),
    );
  });
  test('longitude out of range rejected', () {
    expect(
      StudySpotPolicy.validate(name: 'X', latitude: 0, longitude: 181),
      equals('invalid_coordinates'),
    );
  });
}
```

- [ ] **Step 2: Run to verify fail**

Run: `cd server && dart test test/study_spot_policy_test.dart`
Expected: FAIL — `study_spot_policy.dart` not found.

- [ ] **Step 3: Implement policy**

Create `server/lib/src/study_spot_policy.dart`:

```dart
class StudySpotPolicy {
  static String? validate({
    required String name,
    required double latitude,
    required double longitude,
  }) {
    if (name.trim().isEmpty) return 'name_required';
    if (latitude < -90 || latitude > 90) return 'invalid_coordinates';
    if (longitude < -180 || longitude > 180) return 'invalid_coordinates';
    return null;
  }
}
```

- [ ] **Step 4: Run to verify pass**

Run: `cd server && dart test test/study_spot_policy_test.dart`
Expected: PASS.

- [ ] **Step 5: Add DB table + methods**

In `server/lib/src/database.dart`:

(a) In the migrations area (where other `CREATE TABLE IF NOT EXISTS` run on startup — search for `CREATE TABLE IF NOT EXISTS ai_history` and add alongside), add:

```dart
      'CREATE TABLE IF NOT EXISTS study_spots ('
      'id uuid PRIMARY KEY DEFAULT gen_random_uuid(), '
      'user_id text NOT NULL, '
      'name text NOT NULL, '
      'latitude double precision NOT NULL, '
      'longitude double precision NOT NULL, '
      'study_minutes integer NOT NULL DEFAULT 0, '
      'created_at timestamptz NOT NULL DEFAULT now()'
      ')',
```

> 与现有迁移调用方式一致（参照 ai_history 的 `CREATE TABLE` 与 `CREATE INDEX` 如何被执行）；若迁移是一组字符串顺序执行，按相同方式加入。

(b) Add methods near the AI history methods:

```dart
  Future<List<Map<String, dynamic>>> listStudySpots(String userId) async {
    final result = await connection.execute(
      Sql.named(
        'SELECT id, name, latitude, longitude, study_minutes, created_at '
        'FROM study_spots WHERE user_id=@userId ORDER BY created_at DESC',
      ),
      parameters: {'userId': userId},
    );
    return result.map((row) => {
          'id': row[0].toString(),
          'name': row[1],
          'latitude': row[2],
          'longitude': row[3],
          'studyMinutes': row[4],
          'createdAt': row[5].toString(),
        }).toList();
  }

  Future<Map<String, dynamic>> insertStudySpot(
    String userId, {
    required String name,
    required double latitude,
    required double longitude,
    required int studyMinutes,
  }) async {
    final result = await connection.execute(
      Sql.named(
        'INSERT INTO study_spots (user_id, name, latitude, longitude, study_minutes) '
        'VALUES (@userId, @name, @lat, @lng, @min) '
        'RETURNING id, name, latitude, longitude, study_minutes, created_at',
      ),
      parameters: {
        'userId': userId,
        'name': name,
        'lat': latitude,
        'lng': longitude,
        'min': studyMinutes,
      },
    );
    final row = result.first;
    return {
      'id': row[0].toString(),
      'name': row[1],
      'latitude': row[2],
      'longitude': row[3],
      'studyMinutes': row[4],
      'createdAt': row[5].toString(),
    };
  }

  Future<bool> deleteStudySpot(String userId, String id) async {
    final result = await connection.execute(
      Sql.named('DELETE FROM study_spots WHERE id=@id::uuid AND user_id=@userId'),
      parameters: {'id': id, 'userId': userId},
    );
    return result.affectedRows > 0;
  }
```

- [ ] **Step 6: Add routes**

In `server/lib/src/routes.dart`, add an import `import 'study_spot_policy.dart';` (top with other policy imports), and register routes (place near the AI routes, inside `buildRouter`, using the existing `_protected(config, request, (uid) async {...})` helper and `jsonResponse`/`readJsonMap`):

```dart
  router.get('/study-spots', (Request request) async {
    return _protected(config, request, (uid) async {
      final spots = await database.listStudySpots(uid);
      return jsonResponse({'spots': spots});
    });
  });

  router.post('/study-spots', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final name = (body['name'] as String? ?? '').trim();
      final lat = (body['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (body['longitude'] as num?)?.toDouble() ?? 0;
      final minutes = (body['studyMinutes'] as num?)?.toInt() ?? 0;
      final err = StudySpotPolicy.validate(name: name, latitude: lat, longitude: lng);
      if (err != null) return jsonResponse({'error': err}, status: 400);
      final spot = await database.insertStudySpot(
        uid, name: name, latitude: lat, longitude: lng, studyMinutes: minutes);
      return jsonResponse(spot, status: 201);
    });
  });

  router.delete('/study-spots/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final ok = await database.deleteStudySpot(uid, id);
      if (!ok) return jsonResponse({'error': 'not found'}, status: 404);
      return jsonResponse({'deleted': true});
    });
  });
```

- [ ] **Step 7: Verify server**

Run: `cd server && dart analyze lib/src/study_spot_policy.dart lib/src/routes.dart && dart test test/study_spot_policy_test.dart`
Expected: `No issues found!` and policy tests pass. (Route/DB exercised under Postgres in deploy smoke; not run offline.)

- [ ] **Step 8: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/lib/src/study_spot_policy.dart server/test/study_spot_policy_test.dart server/lib/src/database.dart server/lib/src/routes.dart
git commit -m "feat(map): study_spots table + policy + GET/POST/DELETE routes"
```

---

### Task A4: ApiStudySpotRepository + provider wiring + AppState/AppController

**Files:**
- Modify: `linguaquest/lib/data/repositories/api_repositories.dart`
- Modify: `linguaquest/lib/core/state/app_state.dart`
- Modify: `linguaquest/lib/core/state/app_controller.dart`
- Test: `linguaquest/test/data/study_spot_state_test.dart`

**Interfaces:**
- Consumes: `StudySpotRepository`, `MockStudySpotRepository`, `StudySpot`.
- Produces: `ApiStudySpotRepository implements StudySpotRepository`; `studySpotRepositoryProvider`; `AppState.studySpots` (List<StudySpot>, default `const []`) + copyWith support; `AppController.loadStudySpots()`, `saveStudySpot(StudySpot)`, `deleteStudySpot(String id)`.

- [ ] **Step 1: Write the failing test (controller with mock repo)**

Create `linguaquest/test/data/study_spot_state_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/study_spot.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('saveStudySpot then loadStudySpots updates state', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(appControllerProvider.notifier);

    await controller.saveStudySpot(StudySpot(
      id: '', name: 'Home', latitude: 3.1, longitude: 101.6,
      studyMinutes: 20, createdAt: DateTime.utc(2026, 6, 19)));

    final spots = container.read(appControllerProvider).studySpots;
    expect(spots.length, 1);
    expect(spots.first.name, 'Home');
  });
}
```

- [ ] **Step 2: Run to verify fail**

Run: `cd linguaquest && flutter test test/data/study_spot_state_test.dart`
Expected: FAIL — `studySpots` getter / `saveStudySpot` undefined.

- [ ] **Step 3: Add AppState field**

In `linguaquest/lib/core/state/app_state.dart`: add `final List<StudySpot> studySpots;` to the field list, `required this.studySpots` (or default) to the constructor, include it in `copyWith` (add `List<StudySpot>? studySpots` param and `studySpots: studySpots ?? this.studySpots`), and wherever the initial/empty `AppState` is constructed give it `studySpots: const []`. Add `import '../../data/models/study_spot.dart';` at top.

> 找到 `AppState` 的构造、`copyWith`、以及初始 state 工厂（搜索其他 `List` 字段如 `customWords` 如何被三处一致处理），按同样三处加入 `studySpots`。

- [ ] **Step 4: Add ApiStudySpotRepository**

In `linguaquest/lib/data/repositories/api_repositories.dart` (follow the existing Dio pattern used by other Api repos — they share a `Dio`/`_client` and base url; mirror an existing simple repo like `ApiCustomWordRepository`):

```dart
class ApiStudySpotRepository implements StudySpotRepository {
  ApiStudySpotRepository(this._dio);
  final Dio _dio;

  @override
  Future<List<StudySpot>> list() async {
    final res = await _dio.get('/study-spots');
    final list = (res.data['spots'] as List?) ?? [];
    return list
        .map((e) => StudySpot.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<StudySpot> add(StudySpot spot) async {
    final res = await _dio.post('/study-spots', data: {
      'name': spot.name,
      'latitude': spot.latitude,
      'longitude': spot.longitude,
      'studyMinutes': spot.studyMinutes,
    });
    return StudySpot.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> remove(String id) async {
    await _dio.delete('/study-spots/$id');
  }
}
```

Add imports at top if absent: `import '../models/study_spot.dart';`, `import 'study_spot_repository.dart';`. Mirror how an existing Api repo obtains its `Dio` (the constructor arg name/type) — match exactly.

- [ ] **Step 5: Add provider + controller methods**

In `linguaquest/lib/core/state/app_controller.dart`:

(a) Add provider near the others (mirror `customWordRepositoryProvider`'s shape exactly — same Dio/source the Api repos use):

```dart
final studySpotRepositoryProvider = Provider<StudySpotRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiStudySpotRepository(ref.read(dioProvider));
  }
  return MockStudySpotRepository();
});
```

> 把 `ref.read(dioProvider)` 换成本文件里其他 Api repo 实际使用的 Dio 来源（搜索 `customWordRepositoryProvider` 的 API 分支，照抄其参数）。

(b) Add imports for the new repo classes + `StudySpot` model.

(c) Add controller methods inside `AppController`:

```dart
  Future<void> loadStudySpots() async {
    final spots = await ref.read(studySpotRepositoryProvider).list();
    state = state.copyWith(studySpots: spots);
  }

  Future<void> saveStudySpot(StudySpot spot) async {
    await ref.read(studySpotRepositoryProvider).add(spot);
    await loadStudySpots();
  }

  Future<void> deleteStudySpot(String id) async {
    await ref.read(studySpotRepositoryProvider).remove(id);
    await loadStudySpots();
  }
```

- [ ] **Step 6: Run to verify pass**

Run: `cd linguaquest && flutter test test/data/study_spot_state_test.dart && flutter analyze`
Expected: PASS and `No issues found!`

- [ ] **Step 7: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/data/repositories/api_repositories.dart linguaquest/lib/core/state/app_state.dart linguaquest/lib/core/state/app_controller.dart linguaquest/test/data/study_spot_state_test.dart
git commit -m "feat(map): ApiStudySpotRepository + provider + AppState/AppController wiring"
```

---

### Task A5: Map dependencies + Android permission + Study Map screen

**Files:**
- Modify: `linguaquest/pubspec.yaml`
- Modify: `linguaquest/android/app/src/main/AndroidManifest.xml`
- Create: `linguaquest/lib/features/map/study_map_screen.dart`
- Modify: `linguaquest/lib/core/routing/app_router.dart`
- Test: `linguaquest/test/features/study_map_smoke_test.dart`

**Interfaces:**
- Consumes: `AppController.saveStudySpot`, `AppState.studySpots`, `StudySpot`.
- Produces: route `/map` → `StudyMapScreen`.

- [ ] **Step 1: Add dependencies**

In `linguaquest/pubspec.yaml` under `dependencies:` add:

```yaml
  flutter_map: ^7.0.2
  latlong2: ^0.9.1
  geolocator: ^13.0.1
```

Run: `cd linguaquest && flutter pub get`
Expected: `Got dependencies!`

- [ ] **Step 2: Add Android location permission**

In `linguaquest/android/app/src/main/AndroidManifest.xml`, add inside `<manifest>` (next to the existing `<uses-permission android:name="android.permission.INTERNET" />`):

```xml
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```

- [ ] **Step 3: Write the failing smoke test**

Create `linguaquest/test/features/study_map_smoke_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/features/map/study_map_screen.dart';

void main() {
  testWidgets('StudyMapScreen builds with a map and a save FAB', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: StudyMapScreen()),
    ));
    await tester.pump();
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
```

- [ ] **Step 4: Run to verify fail**

Run: `cd linguaquest && flutter test test/features/study_map_smoke_test.dart`
Expected: FAIL — `study_map_screen.dart` not found.

- [ ] **Step 5: Implement StudyMapScreen**

Create `linguaquest/lib/features/map/study_map_screen.dart`. Use flutter_map with OSM tiles, a markers layer from `state.studySpots`, a FAB that resolves current location (geolocator) — falling back to map center on permission denial — and shows an AppCard dialog to name the spot before calling `saveStudySpot`. Load spots in `initState` via `loadStudySpots()`. Use Cozy Quest primitives for the dialog. Keep all user-facing copy reusing existing localized strings where one fits; otherwise use plain literals consistent with other new screens (no new ARB keys). Concrete implementation:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/models/study_spot.dart';

class StudyMapScreen extends ConsumerStatefulWidget {
  const StudyMapScreen({super.key});
  @override
  ConsumerState<StudyMapScreen> createState() => _StudyMapScreenState();
}

class _StudyMapScreenState extends ConsumerState<StudyMapScreen> {
  final MapController _map = MapController();
  static const LatLng _fallbackCenter = LatLng(3.139, 101.6869); // KL

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).loadStudySpots();
    });
  }

  Future<LatLng?> _currentLatLng() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveHere() async {
    final loc = await _currentLatLng() ?? _map.camera.center;
    if (!mounted) return;
    final name = await _askName();
    if (name == null || name.trim().isEmpty) return;
    await ref.read(appControllerProvider.notifier).saveStudySpot(StudySpot(
          id: '',
          name: name.trim(),
          latitude: loc.latitude,
          longitude: loc.longitude,
          studyMinutes: 0,
          createdAt: DateTime.now().toUtc(),
        ));
    if (mounted) _map.move(loc, 15);
  }

  Future<String?> _askName() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Save study spot',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: AppTokens.spaceM),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'e.g. Library'),
              ),
              const SizedBox(height: AppTokens.spaceM),
              AppPrimaryButton(
                label: 'Save',
                onPressed: () => Navigator.of(ctx).pop(controller.text),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = ref.watch(
        appControllerProvider.select((s) => s.studySpots));
    return Scaffold(
      appBar: AppBar(title: const Text('Study Map')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveHere,
        icon: const Icon(Icons.add_location_alt),
        label: const Text('Save here'),
      ),
      body: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: spots.isNotEmpty
              ? LatLng(spots.first.latitude, spots.first.longitude)
              : _fallbackCenter,
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.linguaquest',
          ),
          MarkerLayer(
            markers: [
              for (final s in spots)
                Marker(
                  point: LatLng(s.latitude, s.longitude),
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.place, color: Colors.red, size: 36),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
```

> 注意：`AppCard` / `AppPrimaryButton` 的实际 import 路径与构造参数以 `core/widgets/` 真实定义为准（先打开确认 `app_card.dart`/`app_buttons.dart` 的导出与 `AppPrimaryButton` 的 `label`/`onPressed` 命名；若不同，按真实 API 调整）。`AppTokens.spaceM` 同理（若命名不同用真实常量）。

- [ ] **Step 6: Register route**

In `linguaquest/lib/core/routing/app_router.dart`, add a top-level `GoRoute` (mirroring existing ones like `/about`), with import for `StudyMapScreen`:

```dart
      GoRoute(path: '/map', builder: (context, state) => const StudyMapScreen()),
```

- [ ] **Step 7: Run smoke test + analyze**

Run: `cd linguaquest && flutter test test/features/study_map_smoke_test.dart && flutter analyze`
Expected: PASS and `No issues found!`

- [ ] **Step 8: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/pubspec.yaml linguaquest/pubspec.lock linguaquest/android/app/src/main/AndroidManifest.xml linguaquest/lib/features/map/study_map_screen.dart linguaquest/lib/core/routing/app_router.dart linguaquest/test/features/study_map_smoke_test.dart
git commit -m "feat(map): flutter_map study map screen + location permission + /map route"
```

---

### Task A6: Study spots list screen + stats

**Files:**
- Create: `linguaquest/lib/features/map/study_spots_list_screen.dart`
- Modify: `linguaquest/lib/core/routing/app_router.dart`
- Test: `linguaquest/test/features/study_spots_list_test.dart`

**Interfaces:**
- Consumes: `AppState.studySpots`, `AppController.deleteStudySpot`.
- Produces: route `/map/spots` → `StudySpotsListScreen`.

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/features/study_spots_list_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:linguaquest/data/models/study_spot.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/features/map/study_spots_list_screen.dart';

void main() {
  testWidgets('list shows saved spot names and total minutes', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockStudySpotRepository();
    await repo.add(StudySpot(id: '', name: 'Library', latitude: 1, longitude: 2,
        studyMinutes: 30, createdAt: DateTime.utc(2026, 6, 19)));
    await repo.add(StudySpot(id: '', name: 'Cafe', latitude: 3, longitude: 4,
        studyMinutes: 15, createdAt: DateTime.utc(2026, 6, 18)));

    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: StudySpotsListScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Cafe'), findsOneWidget);
    expect(find.textContaining('45'), findsWidgets); // total minutes
  });
}
```

- [ ] **Step 2: Run to verify fail**

Run: `cd linguaquest && flutter test test/features/study_spots_list_test.dart`
Expected: FAIL — screen not found.

- [ ] **Step 3: Implement**

Create `linguaquest/lib/features/map/study_spots_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/study_spot.dart';

class StudySpotsListScreen extends ConsumerStatefulWidget {
  const StudySpotsListScreen({super.key});
  @override
  ConsumerState<StudySpotsListScreen> createState() =>
      _StudySpotsListScreenState();
}

class _StudySpotsListScreenState extends ConsumerState<StudySpotsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).loadStudySpots();
    });
  }

  @override
  Widget build(BuildContext context) {
    final spots =
        ref.watch(appControllerProvider.select((s) => s.studySpots));
    final totalMinutes =
        spots.fold<int>(0, (sum, s) => sum + s.studyMinutes);
    return Scaffold(
      appBar: AppBar(title: const Text('Study Spots')),
      body: ListView(
        padding: const EdgeInsets.all(AppTokens.spaceM),
        children: [
          AppCard(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total study minutes',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                Text('$totalMinutes',
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 20)),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spaceM),
          for (final s in spots)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.spaceS),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place),
                  title: Text(s.name),
                  subtitle: Text(
                      '${s.studyMinutes} min · ${s.latitude.toStringAsFixed(3)}, ${s.longitude.toStringAsFixed(3)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref
                        .read(appControllerProvider.notifier)
                        .deleteStudySpot(s.id),
                  ),
                ),
              ),
            ),
          if (spots.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppTokens.spaceL),
              child: Center(child: Text('No study spots yet.')),
            ),
        ],
      ),
    );
  }
}
```

> `AppCard` / `AppTokens.space*` 的真实 API 以 `core/widgets/app_card.dart` 与 `core/theme/app_tokens.dart` 为准；若 `spaceS/spaceM/spaceL` 命名不同，用真实常量。

- [ ] **Step 4: Register route**

In `app_router.dart` add:

```dart
      GoRoute(path: '/map/spots', builder: (context, state) => const StudySpotsListScreen()),
```

with the import.

- [ ] **Step 5: Run test + analyze**

Run: `cd linguaquest && flutter test test/features/study_spots_list_test.dart && flutter analyze`
Expected: PASS and `No issues found!`

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/map/study_spots_list_screen.dart linguaquest/lib/core/routing/app_router.dart linguaquest/test/features/study_spots_list_test.dart
git commit -m "feat(map): study spots list screen with total-minutes stat + /map/spots route"
```

---

# Part B — Pronunciation Enhancement (Multimedia)

### Task B1: PronunciationService (URL → TTS fallback)

**Files:**
- Modify: `linguaquest/pubspec.yaml` (add flutter_tts)
- Create: `linguaquest/lib/core/services/pronunciation_service.dart`
- Test: `linguaquest/test/core/services/pronunciation_service_test.dart`

**Interfaces:**
- Produces: `class PronunciationService { PronunciationService({required AudioSink audio, required TtsSink tts}); Future<PronunciationOutcome> play({required String word, String audioUrl = '', bool slow = false}); }` where `AudioSink`/`TtsSink` are injectable function-typedefs so tests run without real plugins. `enum PronunciationOutcome { playedUrl, playedTts, failed }`.

- [ ] **Step 1: Add dependency**

In `linguaquest/pubspec.yaml` add under dependencies:

```yaml
  flutter_tts: ^4.2.0
```

Run: `cd linguaquest && flutter pub get` → `Got dependencies!`

- [ ] **Step 2: Write the failing test**

Create `linguaquest/test/core/services/pronunciation_service_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/services/pronunciation_service.dart';

void main() {
  test('plays url when audioUrl present and url succeeds', () async {
    var ttsCalled = false;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, lang, slow) async {
        ttsCalled = true;
        return true;
      },
    );
    final outcome = await svc.play(word: 'hello', audioUrl: 'http://x/h.mp3');
    expect(outcome, PronunciationOutcome.playedUrl);
    expect(ttsCalled, isFalse);
  });

  test('falls back to TTS when no url', () async {
    String? lang;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, l, slow) async {
        lang = l;
        return true;
      },
    );
    final outcome = await svc.play(word: '你好');
    expect(outcome, PronunciationOutcome.playedTts);
    expect(lang, 'zh-CN');
  });

  test('falls back to TTS when url playback fails', () async {
    final svc = PronunciationService(
      audio: (url) async => false,
      tts: (text, lang, slow) async => true,
    );
    final outcome =
        await svc.play(word: 'hello', audioUrl: 'http://x/h.mp3');
    expect(outcome, PronunciationOutcome.playedTts);
  });

  test('english uses en language for tts', () async {
    String? lang;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, l, slow) async {
        lang = l;
        return true;
      },
    );
    await svc.play(word: 'hello');
    expect(lang, startsWith('en'));
  });

  test('returns failed when both url and tts fail', () async {
    final svc = PronunciationService(
      audio: (url) async => false,
      tts: (text, lang, slow) async => false,
    );
    final outcome =
        await svc.play(word: 'hello', audioUrl: 'http://x/h.mp3');
    expect(outcome, PronunciationOutcome.failed);
  });
}
```

- [ ] **Step 3: Run to verify fail**

Run: `cd linguaquest && flutter test test/core/services/pronunciation_service_test.dart`
Expected: FAIL — service undefined.

- [ ] **Step 4: Implement service**

Create `linguaquest/lib/core/services/pronunciation_service.dart`:

```dart
import '../utils/text_language.dart';

/// Plays an audio URL; returns true on success.
typedef AudioSink = Future<bool> Function(String url);

/// Speaks [text] in [language] (slow if true); returns true on success.
typedef TtsSink = Future<bool> Function(String text, String language, bool slow);

enum PronunciationOutcome { playedUrl, playedTts, failed }

class PronunciationService {
  PronunciationService({required this.audio, required this.tts});

  final AudioSink audio;
  final TtsSink tts;

  Future<PronunciationOutcome> play({
    required String word,
    String audioUrl = '',
    bool slow = false,
  }) async {
    final trimmed = word.trim();
    if (audioUrl.trim().isNotEmpty) {
      final ok = await audio(audioUrl.trim());
      if (ok) return PronunciationOutcome.playedUrl;
    }
    if (trimmed.isEmpty) return PronunciationOutcome.failed;
    final language = containsCjkText(trimmed) ? 'zh-CN' : 'en-GB';
    final spoken = await tts(trimmed, language, slow);
    return spoken ? PronunciationOutcome.playedTts : PronunciationOutcome.failed;
  }
}
```

> `containsCjkText` 来自现有 `core/utils/text_language.dart`（发音控件已用）。确认其函数名/路径正确。

- [ ] **Step 5: Run to verify pass**

Run: `cd linguaquest && flutter test test/core/services/pronunciation_service_test.dart`
Expected: PASS (5/5).

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/pubspec.yaml linguaquest/pubspec.lock linguaquest/lib/core/services/pronunciation_service.dart linguaquest/test/core/services/pronunciation_service_test.dart
git commit -m "feat(audio): PronunciationService with URL-first TTS fallback (injectable, tested)"
```

---

### Task B2: Rewire PronunciationControls — TTS fallback, slow/repeat, remove snackbars

**Files:**
- Modify: `linguaquest/lib/core/widgets/pronunciation_controls.dart`
- Test: `linguaquest/test/core/widgets/pronunciation_controls_test.dart`

**Interfaces:**
- Consumes: `PronunciationService`, `AudioSink`, `TtsSink`, `PronunciationOutcome`, `audioplayers.AudioPlayer`, `flutter_tts.FlutterTts`.

- [ ] **Step 1: Write the failing test (no SnackBar on tap)**

Create `linguaquest/test/core/widgets/pronunciation_controls_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/widgets/pronunciation_controls.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('tapping pronunciation shows NO SnackBar', (tester) async {
    await tester.pumpWidget(_wrap(
      const PronunciationControls(word: '你好'),
    ));
    await tester.pump();
    await tester.tap(find.byType(OutlinedButton).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(SnackBar), findsNothing);
  });
}
```

- [ ] **Step 2: Run to verify fail**

Run: `cd linguaquest && flutter test test/core/widgets/pronunciation_controls_test.dart`
Expected: FAIL — current code calls `_showMessage` → a SnackBar appears (or compile change pending).

- [ ] **Step 3: Implement**

Edit `linguaquest/lib/core/widgets/pronunciation_controls.dart`:
- Add `import 'package:flutter_tts/flutter_tts.dart';` and `import '../services/pronunciation_service.dart';`.
- Construct a `PronunciationService` whose `audio` uses the existing `AudioPlayer` (`(url) async { try { await _player.stop(); await _player.play(UrlSource(url)); return true; } catch (_) { return false; } }`) and whose `tts` uses a lazily-created `FlutterTts` (`(text, lang, slow) async { try { await _tts.setLanguage(lang); await _tts.setSpeechRate(slow ? 0.4 : 0.5); await _tts.stop(); await _tts.speak(text); return true; } catch (_) { return false; } }`).
- Replace `_play` body to call `service.play(word:, audioUrl:, slow:)` and set `_failedAccent` only when outcome is `PronunciationOutcome.failed`.
- **Delete the `_showMessage` method and every call to it** (the SnackBars). Keep the inline `_failedAccent` red-text retry indicator and the loading spinner.
- Add a **slow** affordance: a small secondary button (or long-press) that calls `_play(..., slow:true)`. Keep the existing UK/US/Chinese button layout; for the slow control reuse the same button style with an `Icons.slow_motion_video` or a "0.5×" label literal.
- Dispose the `FlutterTts` in `dispose()` (call `_tts.stop()`).
- Keep haptics + semantics announcement (those are not SnackBars).

> 保留现有 `_PronunciationButton` 视觉与 loading/failed 状态；只换播放后端与移除 SnackBar。`labelOverride`/中文单按钮逻辑保留。慢速按钮文案用字面量（不新增 ARB key）。

- [ ] **Step 4: Run to verify pass + full pronunciation usage compiles**

Run: `cd linguaquest && flutter test test/core/widgets/pronunciation_controls_test.dart && flutter analyze`
Expected: PASS and `No issues found!`

- [ ] **Step 5: Run the full suite (no regression in 4 usage screens)**

Run: `cd linguaquest && flutter test`
Expected: `All tests passed!`

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/core/widgets/pronunciation_controls.dart linguaquest/test/core/widgets/pronunciation_controls_test.dart
git commit -m "feat(audio): TTS fallback + slow/repeat in PronunciationControls, remove tap snackbars"
```

---

# Part C — UI Polish: Drawer + Screenshot Inventory

### Task C1: App Drawer (third navigation type)

**Files:**
- Modify: `linguaquest/lib/features/shell/app_shell.dart`
- Test: `linguaquest/test/features/app_drawer_test.dart`

**Interfaces:**
- Consumes: GoRouter (`context.go`), routes `/map`, `/map/spots`, `/search`, `/about`, `/help`, `/settings`, `/profile`.
- Produces: a `Drawer` on the shell Scaffold.

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/features/app_drawer_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/shell/app_drawer.dart';

void main() {
  testWidgets('AppDrawer lists Map and About entries', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(drawer: const AppDrawer(), body: const SizedBox()),
      onGenerateRoute: (_) => null,
    ));
    tester.state<ScaffoldState>(find.byType(Scaffold)).openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Study Map'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run to verify fail**

Run: `cd linguaquest && flutter test test/features/app_drawer_test.dart`
Expected: FAIL — `app_drawer.dart` not found.

- [ ] **Step 3: Implement a reusable AppDrawer**

Create `linguaquest/lib/features/shell/app_drawer.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, String label, String route) => ListTile(
          leading: Icon(icon),
          title: Text(label),
          onTap: () {
            Navigator.of(context).pop();
            context.go(route);
          },
        );
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('LinguaQuest',
                    style:
                        TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
              ),
            ),
            item(Icons.map, 'Study Map', '/map'),
            item(Icons.place, 'Study Spots', '/map/spots'),
            item(Icons.search, 'Search', '/search'),
            item(Icons.person, 'Profile', '/profile'),
            item(Icons.settings, 'Settings', '/settings'),
            item(Icons.help_outline, 'Help', '/help'),
            item(Icons.info_outline, 'About', '/about'),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Attach Drawer to the shell**

In `linguaquest/lib/features/shell/app_shell.dart`: import `app_drawer.dart`; add `drawer: const AppDrawer(),` to the shell `Scaffold` (line ~52). Ensure the shell screens' AppBars expose the hamburger (the default leading appears automatically when a Drawer is present and there's an AppBar; if shell tabs have their own AppBars, the menu icon shows automatically).

- [ ] **Step 5: Run test + analyze + full suite**

Run: `cd linguaquest && flutter test test/features/app_drawer_test.dart && flutter analyze && flutter test`
Expected: PASS, `No issues found!`, `All tests passed!`

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/shell/app_drawer.dart linguaquest/lib/features/shell/app_shell.dart linguaquest/test/features/app_drawer_test.dart
git commit -m "feat(ui): add app Drawer navigation (Map/Search/Profile/Settings/Help/About)"
```

---

### Task C2: Screenshot inventory doc

**Files:**
- Create: `docs/release/p3-screens.md`

- [ ] **Step 1: Write the inventory**

Create `docs/release/p3-screens.md` mapping ≥10 pages → route → screenshot filename, plus capture instructions. Cover the 10 assignment categories with concrete routes:

```markdown
# P3 Screen Inventory (report screenshots)

Capture on an Android emulator (Pixel, API 34). Run:
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080`
then for each screen use Android Studio's screenshot or `adb exec-out screencap -p > docs/screenshots/<file>.png`.

| # | Category | Screen | Route | Screenshot |
|---|----------|--------|-------|-----------|
| 1 | Splash | SplashScreen | `/` | splash.png |
| 2 | Onboarding | OnboardingScreen | `/onboarding` | onboarding.png |
| 3 | Login | LoginScreen | `/login` | login.png |
| 4 | Register | RegisterScreen | `/register` | register.png |
| 5 | Home/Dashboard | HomeScreen | `/home` | home.png |
| 6 | List/Display | WordbookScreen | `/wordbook` | wordbook.png |
| 7 | Detail View | WordDetailScreen | `/wordbook/:id` | word_detail.png |
| 8 | Add/Edit Form | AddEditCustomWordScreen | `/custom-words/new` | add_word.png |
| 9 | Profile/Settings | ProfileScreen / SettingsScreen | `/profile`, `/settings` | profile.png, settings.png |
| 10 | About/Info | AboutScreen | `/about` | about.png |
| 11 | Help/FAQ | HelpSupportScreen | `/help` | help.png |
| 12 | Search/Filter | SearchScreen | `/search` | search.png |
| 13 | Map (advanced) | StudyMapScreen | `/map` | study_map.png |
| 14 | Map list | StudySpotsListScreen | `/map/spots` | study_spots.png |

Navigation demonstrated: BottomNavigationBar (shell tabs), TabBar (leaderboard `/leaderboard`), Drawer (hamburger on shell).

Advanced features: Map (`/map`), Multimedia (pronunciation TTS on `/wordbook/:id`), Data Persistence (study spots via backend `study_spots` + offline mock).
```

- [ ] **Step 2: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add docs/release/p3-screens.md
git commit -m "docs(p3): screen inventory + screenshot capture guide for report"
```

---

## Final Verification (after all tasks)

Run and paste actual output:

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze && flutter test
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart test
```

Expected: `No issues found!` / `All tests passed!` (server DB-dependent tests need Postgres; policy tests run offline).

---

## Self-Review

**Spec coverage:**
- A. Study Spots map → A1–A6 (model, repo+mock, server, api+state, map screen, list). ✓
- Persistence dual-impl (Mock SharedPreferences + Api backend) → A2 + A3 + A4. ✓
- B. Pronunciation TTS fallback + slow/repeat + remove snackbars → B1–B2. ✓
- C. Drawer (3rd nav) → C1; screenshots/10-page inventory → C2. ✓
- No new ARB keys: B2/A5/A6 use literals; flagged. ✓
- flutter_map/OSM, geolocator, flutter_tts deps → A5/B1. ✓
- Android location permission → A5. ✓

**Placeholder scan:** Code blocks provided for each implementation step. The "confirm AppCard/AppTokens real API" notes are explicit alignment instructions against existing files, not placeholders — the implementer opens the named file and matches the real export. No TBD/TODO.

**Type consistency:**
- `StudySpot` fields (id/name/latitude/longitude/studyMinutes/createdAt) consistent across A1–A6 and server JSON. ✓
- `StudySpotRepository` methods `list()/add()/remove()` consistent in A2 (mock), A4 (api), controller. ✓
- `PronunciationService.play({word, audioUrl, slow})` + `PronunciationOutcome` consistent B1→B2. ✓
- `AppController.loadStudySpots/saveStudySpot/deleteStudySpot` defined A4, used A5/A6. ✓
- Routes `/map`, `/map/spots` defined A5/A6, linked in Drawer C1. ✓
