# Class Mode — Full Backend Design Spec

> **SUPERSEDED (2026-06-26): Issue #77 §5(a) cancels the class-code feature. The class backend was never implemented; see 2026-06-26-issue77-community-design.md. This spec is retained for history only. (Unrelated to the deployed /study-spots map backend.)**

> **Status: optional polish — earns no SWE311 rubric marks; implement after the graded Map feature.**

Date: 2026-06-25
Author: design spec (no code in this document)
Scope: full-stack — Flutter app (`linguaquest/`) + shelf/PostgreSQL backend (`server/`)

---

## 1. Overview & goal

"Class Mode" today is a **pure frontend mock with no backend**:

- `linguaquest/lib/features/quests/class_mode_screen.dart` — the join button only pops a `SnackBar` via `l10n.classModeJoined(code)`; the `TextField` is pre-filled with `'LQ-2048'`; the "view progress" `AppSecondaryButton` calls `context.push('/class-progress')`.
- `linguaquest/lib/features/quests/class_progress_screen.dart` — renders **three hardcoded rows** (`92%`/`64%`/`38%`) with topic labels `classTopicExamSignals` / `classTopicTravelBasics` / `classTopicWorkplace` and fake "weak word" strings.

The goal is to make Class Mode **real, end to end**:

1. A teacher/owner can **create a class** and get a shareable **join code**.
2. A student can **join a class by code**.
3. The progress screen shows **real aggregated learning progress** of the class's members, computed from data already stored in the backend — no fabricated numbers.

This follows the project's offline-first contract: a new `classes` data domain with **both** a `MockClassRepository` and an `ApiClassRepository`, wired through a provider that switches on `AppConstants.apiBaseUrl` (CLAUDE.md: "new data domain → must provide both implementations and wire a provider this way").

---

## 2. Scope

### In scope (YAGNI floor)
- Create a class (creator auto-joins as owner).
- Join a class by **join code only** (idempotent if already a member).
- List "my classes" (classes I own or am a member of).
- View a class's **aggregated member progress by topic** (real data).
- Both repository implementations + provider wiring + controller methods + state fields.
- Server tables, routes, a pure `class_policy.dart`, idempotent migrations.
- New ARB keys (en/zh/ms) for new user-facing strings.

### Out of scope (explicitly NOT building)
- Roles beyond owner/member (no TA, no co-teacher, no per-member permissions).
- Admin console, member removal, class deletion/archival, renaming.
- Invitations by email/link, QR codes, push notifications.
- Per-student drill-down (only class-level aggregates).
- Leaderboards, assignments, due dates, grading.
- Leaving a class. (A member row, once created, stays. Revisit only if asked.)
- Server-side moderation of class names (a length/non-empty check is enough).

---

## 3. Data model

### 3.1 Server tables (idempotent `CREATE TABLE IF NOT EXISTS` in `server/lib/src/database.dart`)

Added in the same migration method that already creates `forum_posts` etc. (around `database.dart:480-523`), so they run on startup.

```
CREATE TABLE IF NOT EXISTS classes (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        TEXT NOT NULL,
  join_code   TEXT UNIQUE NOT NULL,
  owner_id    TEXT NOT NULL,                 -- users.id (kept as TEXT to match forum_posts.author_id convention)
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS class_members (
  class_id    UUID NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
  uid         TEXT NOT NULL,                 -- users.id
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (class_id, uid)
);

CREATE INDEX IF NOT EXISTS classes_join_code_idx ON classes(join_code);
CREATE INDEX IF NOT EXISTS class_members_uid_idx ON class_members(uid);
```

Notes:
- `id`/`join_code` typed as `UUID`/`TEXT` to mirror `forum_posts` (UUID PK, `gen_random_uuid()`).
- `owner_id` / `uid` are `TEXT` referencing `users(id)` informally, matching how `forum_posts.author_id` is `TEXT` (no FK) — stay consistent with the existing forum convention rather than adding FKs.
- `join_code` is `UNIQUE`; collisions are resolved by the policy's retry loop (§6).
- The composite PK on `class_members` makes **join idempotent at the storage layer** (`ON CONFLICT (class_id, uid) DO NOTHING`).

### 3.2 App models (`linguaquest/lib/data/models/class_info.dart`)

Two immutable models following the `ForumPost` pattern exactly (`fromJson` with null-safe defaults, `toJson`, `copyWith` where useful). Place both in one file `class_info.dart` (mirrors `forum.dart` holding `ForumPost` + `ForumComment`).

`ClassInfo`:

| field | type | JSON key | notes |
|---|---|---|---|
| `id` | `String` | `id` | |
| `name` | `String` | `name` | |
| `joinCode` | `String` | `joinCode` | shown so owner can share |
| `ownerId` | `String` | `ownerId` | |
| `memberCount` | `int` | `memberCount` | server-computed convenience count |
| `isOwner` | `bool` | `isOwner` | server-computed for the requesting uid |
| `createdAt` | `DateTime` | `createdAt` | ISO-8601 string, `DateTime.tryParse` fallback to `DateTime.now()` like `ForumPost` |

`ClassProgress` (the payload of `GET /classes/<id>/progress`):

| field | type | JSON key | notes |
|---|---|---|---|
| `classId` | `String` | `classId` | |
| `memberCount` | `int` | `memberCount` | members included in the aggregate |
| `topics` | `List<ClassTopicProgress>` | `topics` | one row per topic/wordbook |

`ClassTopicProgress` (one progress-screen row):

| field | type | JSON key | notes |
|---|---|---|---|
| `topicId` | `String` | `topicId` | the `word_book_id` (e.g. `hsk1`) |
| `topicLabel` | `String` | `topicLabel` | display label; see §5.4 for label resolution |
| `masteryPercent` | `int` | `masteryPercent` | 0–100, drives the `AppProgressBar` + `AppPill` |
| `weakWord` | `String?` | `weakWord` | most-missed word across members; nullable |

`fromJson`/`toJson` conventions copy `ForumPost`: `as String? ?? ''`, `as int? ?? 0`, nested lists via `whereType<Map>().map(...)`.

---

## 4. API contract

All endpoints are **`_protected`** (require a valid bearer token; the wrapper at `routes.dart:1559` returns `401 {'error':'missing or invalid bearer token'}` on failure). Responses use the existing `jsonResponse(...)` helper; bodies are read with `readJsonMap(request)`. New routes go in a `// ── Class routes ──` block in `server/lib/src/routes.dart`, styled like the forum block (`routes.dart:1118-1226`).

### 4.1 `POST /classes` — create a class

- **Auth:** required (uid = owner).
- **Request body:** `{ "name": "Form 4 Mandarin" }`
- **Behavior:** validate name (`ClassPolicy.isValidClassName`); generate a unique join code (`ClassPolicy.generateJoinCode`, retry on `UNIQUE` collision, §6); insert `classes` row; insert the owner into `class_members`.
- **Response `201`:**
  ```json
  { "class": { "id": "...", "name": "Form 4 Mandarin", "joinCode": "LQ-7Q3D",
               "ownerId": "<uid>", "memberCount": 1, "isOwner": true,
               "createdAt": "2026-06-25T..." } }
  ```
- **Errors:** `400 {"error":"name is required, 1–60 chars"}` on invalid name.

### 4.2 `POST /classes/join` — join by code

- **Auth:** required (uid = joining member).
- **Request body:** `{ "code": "LQ-7Q3D" }`
- **Behavior:** normalize the code (`ClassPolicy.normalizeJoinCode` — trim, uppercase); look up the class by `join_code`; if not found → `404`; else upsert membership with `ON CONFLICT (class_id, uid) DO NOTHING` (**idempotent** — re-joining is a success no-op).
- **Response `200`:** the joined class DTO (same shape as §4.1, with refreshed `memberCount`, `isOwner` for this uid).
- **Errors:** `404 {"error":"no class with that code"}`; `400 {"error":"code is required"}` for empty/whitespace code.

### 4.3 `GET /classes/mine` — list my classes

- **Auth:** required.
- **Behavior:** return every class where uid is the owner **or** a member (`owner_id = uid OR EXISTS member row`), newest first.
- **Response `200`:** `{ "classes": [ <ClassInfo DTO>, ... ] }` (empty list is valid).

### 4.4 `GET /classes/<id>/progress` — aggregated member progress

- **Auth:** required. The requester must be the owner or a member (else `403 {"error":"not a member of this class"}`); `404 {"error":"class not found"}` if id unknown.
- **Behavior:** aggregate **real** member learning data (§5).
- **Response `200`:**
  ```json
  { "progress": { "classId": "...", "memberCount": 12,
      "topics": [
        { "topicId": "hsk1", "topicLabel": "HSK 1", "masteryPercent": 78, "weakWord": "应该" },
        { "topicId": "hsk2", "topicLabel": "HSK 2", "masteryPercent": 41, "weakWord": "经济" }
      ] } }
  ```
- **Edge case:** a class with members who have no `user_words` rows yet → `topics: []` (the app shows an empty state, §5.4 / §8.5).

---

## 5. Progress aggregation — grounded in REAL stored data

### 5.1 Source table

The single source of truth is **`user_words`** (`database.dart:158-188`). It is the per-user, per-word learning record and already carries everything the progress screen needs:

- `uid` — member identity (join key to `class_members.uid`).
- `word_book_id` — **the topic dimension** (e.g. `hsk1`, `hsk2`). This is the same field `study_plans.word_book_id` references (`database.dart:366`), so "topic" == "wordbook".
- `word` — used to name the weak word.
- `mastery_level` — `INTEGER NOT NULL DEFAULT 0`. This is the per-word mastery the SRS engine maintains (also written by `review_events.mastery_after`). It is the canonical mastery metric.
- `wrong_count` / `correct_count` — used to find the weakest word.
- `status` — `'New' | 'Previewed' | 'Ignored' | ...`; rows with `status IN ('New','Previewed')` are not yet "studied" and `is_ignored` rows are excluded.

No new tracking is invented; the aggregation reads existing rows only.

### 5.2 Mastery scale

`mastery_level` is an integer on the SRS scale **0–5** (0 = new, 5 = fully mastered; confirmed by `review_events.mastery_before/after` semantics and the `user_words.mastery_level` default of 0). Define `MASTERY_MAX = 5` as a named constant in `class_policy.dart` so it is a single source of truth and unit-testable.

### 5.3 Formula (pure, in `class_policy.dart`)

For a class, gather all `user_words` rows whose `uid ∈ class_members(class_id)` **and** `is_ignored = FALSE` **and** `status NOT IN ('New','Previewed')` (i.e. words actually under study). Group by `word_book_id`:

```
masteryPercent(topic) = round( 100 * sum(mastery_level over rows in topic)
                                   / (MASTERY_MAX * count(rows in topic)) )
```

i.e. the class's average per-word mastery for that topic, normalized to 0–100. A topic with zero qualifying rows is omitted (not shown as 0%).

Weak word per topic:

```
weakWord(topic) = the `word` of the row in that topic with the highest
                  wrong_count (tie-break: lowest mastery_level, then lexical
                  order on `word` for determinism); null if no row has wrong_count > 0.
```

The DB layer (`database.dart`) does the `SELECT` (a single grouped query joining `class_members` and `user_words`); `ClassPolicy` does the **pure arithmetic** (`computeTopicMastery(rows)`, `pickWeakWord(rows)`) so the math is unit-testable without a database, mirroring how `review_policy.dart` / `study_plan_policy.dart` isolate rules.

### 5.4 Topic labels

`topicLabel` is resolved app-side, not hardcoded server-side. The server returns the raw `topicId` (`word_book_id`) and a best-effort `topicLabel` echoing the id. The app maps known wordbook ids → localized labels via the existing `core/utils/ui_labels.dart` indirection (same place exam targets are mapped); unknown ids fall back to the raw id. This keeps the three legacy ARB topic keys (`classTopicExamSignals` etc.) available as fallback labels but **no longer hardcodes the rows**.

---

## 6. `server/lib/src/class_policy.dart` — pure business rules

A pure, dependency-free class mirroring `forum_policy.dart` (`server/lib/src/forum_policy.dart`) — no DB, no clock, no RNG inside the tested functions, so `dart test` can cover it deterministically. The prompt's concern (`DateTime.now()`/random are awkward to test) is addressed by making **join-code generation a pure function of inputs** rather than a clock/RNG read:

```dart
class ClassPolicy {
  static const int masteryMax = 5;
  static const int joinCodeBodyLength = 4;     // "LQ-XXXX"

  /// Name validation: non-empty after trim, ≤ 60 chars.
  static bool isValidClassName(String name);

  /// Trim + uppercase a user-typed code for lookup. ("lq-7q3d " -> "LQ-7Q3D")
  static String normalizeJoinCode(String raw);

  /// DETERMINISTIC: derive a candidate code purely from inputs.
  /// Hash (ownerId + classSeed + attempt) -> base32 (Crockford, no I/O/0/1)
  /// -> "LQ-XXXX". `attempt` lets the route retry on UNIQUE collision
  /// without any RNG, so the same inputs always yield the same sequence.
  static String generateJoinCode({
    required String ownerId,
    required String classSeed,   // e.g. the new class UUID or a monotone counter
    int attempt = 0,
  });

  /// True when normalizeJoinCode(input) is a structurally valid code
  /// ("LQ-" + 4 base32 chars). Cheap pre-check before a DB lookup.
  static bool isWellFormedCode(String input);

  /// PURE aggregation helpers over plain row maps (no DB types):
  /// average per-word mastery for a topic, normalized 0..100.
  static int computeTopicMastery(List<Map<String, dynamic>> rowsInTopic);

  /// the most-missed word in a topic (highest wrong_count; tie-breaks as §5.3);
  /// null when no row has wrong_count > 0.
  static String? pickWeakWord(List<Map<String, dynamic>> rowsInTopic);
}
```

The route owns the **collision retry loop**: call `generateJoinCode(..., attempt: 0)`, try the insert; on `UNIQUE` violation increment `attempt` and retry (cap at, say, 8 attempts → `500` if exhausted). Because `attempt` is an explicit parameter, the generator itself stays pure and the retry policy is testable in isolation.

---

## 7. App architecture (`linguaquest/`)

### 7.1 Repository interface — `lib/data/repositories/class_repository.dart`

```dart
abstract class ClassRepository {
  Future<ClassInfo> createClass(String name);
  Future<ClassInfo> joinByCode(String code);
  Future<List<ClassInfo>> listMyClasses();
  Future<ClassProgress> loadProgress(String classId);
}
```

### 7.2 `MockClassRepository` (in `mock_repositories.dart`)

In-memory + `SharedPreferences`, **deterministic** (matches `MockForumRepository` style at `mock_repositories.dart`): integer id/code counters, no `DateTime.now()`-derived ids in test paths.

- Seeds one demo class (`name: "Demo Class"`, `joinCode: "LQ-2048"` to keep the screen's existing default working) with the current mock user as owner+member.
- `createClass`: append a deterministic class (`mock-class-${++counter}`, code derived from counter via the same scheme as `ClassPolicy.generateJoinCode` so Mock/Api agree in shape).
- `joinByCode("LQ-2048")` → success returning the seeded class; unknown code → throws `StateError('no class with that code')` (Api throws `DioException`; the controller catches both, §7.4).
- `loadProgress`: returns a **deterministic, plausible** aggregate derived from the seeded mock `user_words`/custom-words already in `MockLearningRepository` if reachable, else a fixed three-topic set echoing the legacy demo numbers — so offline demo mode still shows a populated screen. (This fixed fallback is the *only* place hardcoded sample numbers remain, and only in mock/demo mode.)
- Persists created/joined class ids to `SharedPreferences` under a `class_mode_*` key so they survive app restart in demo mode.

### 7.3 `ApiClassRepository` (in `api_repositories.dart`)

Dio-based, exactly mirroring `ApiForumRepository` (`api_repositories.dart:698`): `_client.dio.post/get`, unwrap `response.data!['class' | 'classes' | 'progress']`, map via `ClassInfo.fromJson` / `ClassProgress.fromJson`, `whereType<Map>()` for lists.

### 7.4 Provider wiring (`app_controller.dart`)

Add alongside `forumRepositoryProvider` (`app_controller.dart:130`):

```dart
final classRepositoryProvider = Provider<ClassRepository>((ref) {
  if (AppConstants.apiBaseUrl.isNotEmpty) {
    return ApiClassRepository(ref.read(apiClientProvider));
  }
  return MockClassRepository();
});
```

In the `AppController` Notifier, add `late final ClassRepository _classRepository;` and assign it in the same `build()`/init block where `_forumRepository = ref.watch(forumRepositoryProvider);` (`app_controller.dart:192`).

### 7.5 Controller methods (`app_controller.dart`)

Mirror the forum methods (`refreshForumPosts`/`createForumPost` at `app_controller.dart:2495+`): optimistic where safe, try/catch with `debugPrint`, update state via `copyWith`.

```dart
Future<ClassInfo?> createClass(String name)        // -> prepend to myClasses, return it (null on failure)
Future<ClassInfo?> joinClass(String code)          // -> add/refresh myClasses; returns class on success, null on failure
Future<void> refreshMyClasses()                    // -> state.myClasses
Future<void> loadClassProgress(String classId)     // -> state.activeClassProgress (+ isLoadingClassProgress flag)
```

`joinClass` distinguishes "bad code" (return null, screen shows error SnackBar) from success (navigate to progress).

### 7.6 State fields (`app_state.dart`)

Following `forumPosts` (declared, `copyWith`, default `const []` at `app_state.dart:128/179/349/396/437`):

| field | type | default |
|---|---|---|
| `myClasses` | `List<ClassInfo>` | `const []` |
| `activeClassProgress` | `ClassProgress?` | `null` |
| `isLoadingClassProgress` | `bool` | `false` |

Add each to the constructor, the field declarations, `copyWith` (nullable handling for `activeClassProgress`), and the initial-state factory.

### 7.7 Screen changes

**`class_mode_screen.dart`** (convert to `ConsumerStatefulWidget`):
- Keep the `TextField` (default `'LQ-2048'` still valid against the mock seed).
- Join button → `await ref.read(appControllerProvider.notifier).joinClass(code)`. On non-null result: SnackBar success + `context.push('/class-progress?classId=<id>')`. On null: error SnackBar (`l10n.classModeJoinFailed`).
- Add a "create class" affordance (small secondary button / dialog with a name field) calling `createClass`; on success show the returned `joinCode` so the owner can share it.
- The existing "view progress" button routes to `/class-progress`; if the user has ≥1 class, pass the first/selected `classId`.

**`class_progress_screen.dart`** (convert to `ConsumerWidget`):
- Read `classId` from the route (query param) — fall back to the user's first class.
- `initState`/`build` triggers `loadClassProgress(classId)`; watch `activeClassProgress` + `isLoadingClassProgress`.
- Render one `_ClassProgressRow` per `ClassTopicProgress` (label via `ui_labels`, `masteryPercent/100` into `AppProgressBar`, `"$masteryPercent%"` into the `AppPill`, `weakWord` into the subtitle).
- Loading → spinner; empty `topics` → `MascotEmptyState` with `l10n.classProgressEmpty`.
- **Remove the hardcoded `rows` list entirely.**

**Routing (`core/routing/app_router.dart`):** `/class-progress` gains an optional `classId` query param (no new route needed).

---

## 8. Internationalization (i18n UNFROZEN for this feature)

Add to `app_en.arb` (template), `app_zh.arb` (default runtime), `app_ms.arb`, then run `flutter gen-l10n` and commit `lib/l10n/generated/`. New keys:

| key | en (template) |
|---|---|
| `classModeCreate` | "Create class" |
| `classModeCreateHint` | "Class name" |
| `classModeCreated` | "Class created — share code {code}" (placeholder `code`) |
| `classModeJoinFailed` | "No class found for that code" |
| `classModeJoinSuccess` | "Joined {name}" (placeholder `name`) |
| `classModeMyClasses` | "My classes" |
| `classModeMemberCount` | "{count} members" (placeholder `count`, plural) |
| `classProgressEmpty` | "No class progress yet — members need to start studying" |
| `classProgressLoading` | "Loading class progress…" |
| `classModeNameRequired` | "Enter a class name (1–60 characters)" |

Existing keys retained as fallback labels: `classTopicExamSignals`, `classTopicTravelBasics`, `classTopicWorkplace`, `classProgressWeakWord`, `classModeJoined` (the last now only used by the mock SnackBar path if kept). zh/ms translations to be supplied alongside.

---

## 9. Testing

### 9.1 Server — `dart test` (run from `server/`)

**`server/test/class_policy_test.dart`** (pure, no DB — modeled on `forum_routes_test.dart` / `moderation_policy_test.dart`):
- `isValidClassName`: empty/whitespace → false; 60 chars → true; 61 → false.
- `normalizeJoinCode`: `" lq-7q3d "` → `"LQ-7Q3D"`.
- `generateJoinCode`: **determinism** — same `(ownerId, classSeed, attempt)` → identical code; different `attempt` → different code; output matches `"LQ-" + 4 base32` and `isWellFormedCode` accepts it.
- `isWellFormedCode`: rejects malformed (`"LQ-12"`, `"ABCD"`, `"LQ-0OI1"` if those chars are excluded).
- `computeTopicMastery`: e.g. three rows mastery `[5,5,0]` → `round(100*10/(5*3))` = `67`; empty list handled (caller omits topic).
- `pickWeakWord`: highest `wrong_count` wins; tie-break by lowest mastery then lexical; all-zero `wrong_count` → null.

**`server/test/class_routes_test.dart`** (route harness mirroring `study_plan_routes_test.dart`, which uses a `class _RouteTestDatabase extends AppDatabase` fake overriding just the methods under test — no live Postgres):
- `POST /classes` with valid name → `201`, body has a well-formed `joinCode`, `memberCount == 1`, `isOwner == true`; owner membership row inserted.
- `POST /classes` invalid name → `400`.
- `POST /classes/join` valid code → `200`, membership inserted; **second join with same uid → still `200`, no duplicate** (idempotent via `ON CONFLICT`).
- `POST /classes/join` unknown code → `404`.
- `GET /classes/mine` → returns owned + joined classes.
- `GET /classes/<id>/progress` non-member → `403`; member with `user_words` rows → aggregated topics with correct `masteryPercent`; member with no studied words → `topics: []`.
- Missing bearer token on any route → `401` (exercises `_protected`).

### 9.2 App — `flutter test` (run from `linguaquest/`)

- **`test/data/class_repository_test.dart`**: `MockClassRepository` determinism — `createClass` yields stable ids/codes; `joinByCode("LQ-2048")` succeeds; unknown code throws; `loadProgress` returns a populated `ClassProgress`; SharedPreferences persistence round-trip.
- **Controller test**: `createClass`/`joinClass`/`refreshMyClasses`/`loadClassProgress` mutate `AppState` correctly (e.g. `joinClass` populates `myClasses`; failure returns null and leaves state intact).
- **Widget tests** for both screens (mock repo via ProviderScope override):
  - `class_mode_screen`: typing a code + tapping join calls the controller; success navigates; failure shows the error SnackBar; create flow surfaces the join code.
  - `class_progress_screen`: renders one row per topic from a stubbed `ClassProgress`; shows the empty state when `topics` is empty; shows a spinner while loading. Assert **no hardcoded `92%/64%/38%`** remain.

Both `flutter analyze` and `flutter test` must pass before PR (CLAUDE.md).

---

## 10. Migration & back-compat

- New tables use `CREATE TABLE IF NOT EXISTS` + `CREATE INDEX IF NOT EXISTS`, run in the existing startup migration path (`database.dart`), idempotent on every boot — matches the forum/study-plan precedent. No destructive DDL.
- Existing data untouched; `classes`/`class_members` are additive.
- **Offline/demo mode unaffected:** with `AppConstants.apiBaseUrl` empty the provider picks `MockClassRepository`, so the app still runs with no backend (the offline-first contract). The mock seeds `LQ-2048` so the legacy default code keeps working.
- ARB additions are backward-compatible (new keys only; legacy topic keys retained).

---

## 11. Open decisions

1. **Topic dimension granularity.** We treat `word_book_id` as "topic". If a class spans many wordbooks the screen could get long — do we cap to top-N topics by member coverage? (Proposed: show all, ordered by `memberCount`-weighted study volume; revisit if noisy.)
2. **Which members count toward the aggregate.** Currently: all `class_members`. Should the owner's own progress be excluded (teacher isn't a "student")? Proposed: include everyone for v1; add an `exclude_owner` later if asked.
3. **Join-code charset/length.** "LQ-" + 4 Crockford-base32 chars ≈ 1M codes. Enough for coursework scale; bump body length if collision retries become common.
4. **Class selection UX.** The progress route needs a `classId`. For a user in multiple classes, do we add a class picker on `class_mode_screen`, or default to most-recently-joined? Proposed: most-recent default + a simple dropdown if `myClasses.length > 1`.
5. **`weakWord` privacy.** Surfacing a class-wide weak word is mild; if any member-level privacy concern arises, gate behind the existing `user_privacy` flags. Out of scope for v1 but noted.

---

## 12. Risks

- **Aggregation cost.** `GET /classes/<id>/progress` joins `class_members` × `user_words`; for large classes this is a wide scan. Mitigation: the existing `class_members_uid_idx` + `user_words` indexes; aggregate in a single grouped SQL query, not N+1.
- **Mastery-scale drift.** If the SRS later changes `mastery_level`'s max, `MASTERY_MAX` must move with it. Mitigation: single named constant in `class_policy.dart`, covered by a test.
- **Mock/Api divergence.** The two repos must agree on JSON shape or the screen breaks in one mode only. Mitigation: shared `ClassInfo.fromJson`/`toJson` is the contract; widget tests run against the mock, route tests against the server DTOs — keep the field tables in §3.2/§4 as the single spec.
- **Owner-as-TEXT id.** Following forum's no-FK `author_id` convention means an orphaned `owner_id` is possible if a user is deleted (forum has the same trait). Acceptable for an optional feature; `class_members` still cascades on class deletion.
- **Idempotency correctness.** Join must never create duplicate membership; relies on the composite PK + `ON CONFLICT DO NOTHING`. Covered by the "second join → still 200, no duplicate" route test.
