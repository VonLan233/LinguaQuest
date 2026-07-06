# Frontend Exposure Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** Wire up completed-but-unreachable features: add entries for privacy/data/notifications screens, forum favorite + report + like-icon fix, listening-question audio control, and fix the broken recommendation "Start Practice" button.

**Architecture:** Mostly Flutter UI wiring of existing screens/state. One Flutter repo+state addition (forum report) against the EXISTING server `/reports` route. No new server routes needed (forum favorite route already exists at routes.dart:1213).

**Tech Stack:** Flutter, Riverpod, GoRouter.

## Global Constraints

- 原子提交，**不加** Co-Authored-By trailer。
- No new ARB/l10n keys (i18n frozen) — reuse existing localized strings or plain literals consistent with neighbouring code.
- Use AppTokens / Cozy Quest primitives; match existing patterns in the file being edited.
- Don't break existing tests: run `flutter analyze` + `flutter test` before each commit.
- Verified backend facts: server `/forum/posts/<id>/favorite` route EXISTS (routes.dart:1213); forum DTO already carries `isFavorited`; `AppController.toggleForumFavorite` + `ApiForumRepository.toggleFavorite` already exist. Server `POST /reports` EXISTS (routes.dart:1226, body: contentType/contentId/reason/detail).

---

### Task 1: Profile entries for Privacy / Data / Notifications

**Files:**
- Modify: `linguaquest/lib/features/profile/profile_screen.dart`
- Test: `linguaquest/test/features/profile_entries_test.dart` (Create)

**Context:** `profile_screen.dart` uses repeated `_SettingsItem(... onTap: () => context.push('/route'))` rows (see existing rows at lines ~82-141 pushing `/settings/study-plan`, `/wordbook`, `/custom-words`, `/mistake-book`, `/settings/reminder`, `/help`, `/about`). The screens `/profile/privacy`, `/profile/data`, `/notifications` are registered routes with complete screens but have NO entry from profile.

**Interfaces:** Adds three `_SettingsItem` rows navigating to `/profile/privacy`, `/profile/data`, `/notifications`.

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/features/profile_entries_test.dart`. Pump `ProfileScreen` inside a minimal GoRouter (mirror an existing profile/widget test setup in the repo — find one and copy its harness) and assert tappable rows for the three destinations exist. If a full-router harness is heavy, instead assert the screen's widget tree contains rows whose labels match the three new entries (use the existing `_SettingsItem` title text). Concretely, assert `find.text('Privacy')` (or the real label used), `find.text('Data')`, `find.text('Notifications')` are present after pumping ProfileScreen with a ProviderScope + MaterialApp.router harness copied from an existing test.

- [ ] **Step 2: Run red**

Run: `cd linguaquest && flutter test test/features/profile_entries_test.dart`
Expected: FAIL (entries absent).

- [ ] **Step 3: Implement**

In `profile_screen.dart`, add three `_SettingsItem` rows in the settings list (next to the existing ones, e.g. after the reminder/notification-adjacent section, before Help/About). Use the existing `_SettingsItem` constructor shape (icon, title, subtitle?, onTap). Labels: prefer existing localized strings if present (search `AppLocalizations` for privacy/data/notifications strings); else use literals `'Privacy'`, `'Data & storage'`, `'Notifications'`. Use `AppIcons` constants (e.g. lock/shield, storage/database, notifications). onTaps: `context.push('/profile/privacy')`, `context.push('/profile/data')`, `context.push('/notifications')`.

- [ ] **Step 4: Run green + analyze**

Run: `cd linguaquest && flutter test test/features/profile_entries_test.dart && flutter analyze`
Expected: PASS + `No issues found!`

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/profile/profile_screen.dart linguaquest/test/features/profile_entries_test.dart
git commit -m "feat(profile): add entries for privacy, data, and notifications screens"
```

---

### Task 2: Forum favorite button + report flow + like-icon fix

**Files:**
- Modify: `linguaquest/lib/features/discover/forum_post_detail_screen.dart`
- Modify: `linguaquest/lib/data/repositories/forum_repository.dart` (interface + both impls), `mock_repositories.dart`, `api_repositories.dart`
- Modify: `linguaquest/lib/core/state/app_controller.dart` (reportContent method)
- Test: `linguaquest/test/data/forum_report_test.dart` (Create)

**Context:** Forum detail AppBar (forum_post_detail_screen.dart:90-110) has a like IconButton calling `toggleForumLike`, but: (a) the like icon is the SAME for liked/unliked (`post.isLiked ? AppIcons.thumbUpAlt : AppIcons.thumbUpAlt`, line 97 — bug D), (b) no favorite button though `toggleForumFavorite` + server route + `isFavorited` DTO all exist, (c) no report control though server `/reports` exists. The Flutter forum repo has `toggleLike`/`toggleFavorite` but no `report`.

**Interfaces:**
- Produces: `ForumRepository.reportPost(String postId, String reason, {String? detail})` (Mock no-ops/returns; Api POSTs `/reports` with `{contentType:'post', contentId:postId, reason, detail}`); `AppController.reportForumPost(String postId, String reason, {String? detail})`.

- [ ] **Step 1: Write the failing test (Api report posts correct body)**

Create `linguaquest/test/data/forum_report_test.dart`. Construct `ApiForumRepository` with a mock Dio/ApiClient (mirror how other api_repositories tests inject the client — find an existing one; if none, test the Mock impl's report no-op + the controller wiring instead). Assert calling `reportPost('p1', 'spam')` issues `POST /reports` with body `contentType:'post', contentId:'p1', reason:'spam'`. If injecting Dio is impractical, instead write a controller-level test using `MockForumRepository` that records the report call, asserting `AppController.reportForumPost` invokes the repo.

- [ ] **Step 2: Run red**

Run: `cd linguaquest && flutter test test/data/forum_report_test.dart`
Expected: FAIL (reportPost undefined).

- [ ] **Step 3: Implement report chain**

- `forum_repository.dart`: add `Future<void> reportPost(String postId, String reason, {String? detail});` to the abstract interface.
- `mock_repositories.dart` `MockForumRepository`: implement `reportPost` as a no-op (or store in-memory) returning normally.
- `api_repositories.dart` `ApiForumRepository`: implement `reportPost` → `await _client.dio.post('/reports', data: {'contentType': 'post', 'contentId': postId, 'reason': reason, if (detail != null) 'detail': detail});` (match the real Dio access used by sibling methods like `toggleFavorite` at line 757).
- `app_controller.dart`: add `Future<void> reportForumPost(String postId, String reason, {String? detail}) async { await ref.read(forumRepositoryProvider).reportPost(postId, reason, detail: detail); }` (match how `toggleForumFavorite` reads its provider).

- [ ] **Step 4: Implement UI (favorite + report + like-icon fix)**

In `forum_post_detail_screen.dart` AppBar `actions:` (line ~93):
- **Like icon fix:** change line 97 to use two distinct icons, e.g. `post.isLiked ? AppIcons.thumbUp : AppIcons.thumbUpAlt` (find a real filled/outlined pair in `AppIcons`; if only one exists, differentiate by color — e.g. liked → primary color, unliked → default). The two states must look different.
- **Favorite button:** add an `IconButton` next to like, icon `post.isFavorited ? AppIcons.bookmark : AppIcons.bookmarkBorder` (use real AppIcons bookmark constants; if absent, add them to app_icons.dart following the existing pattern, or use star filled/outline), onPressed → `ref.read(appControllerProvider.notifier).toggleForumFavorite(widget.postId)`.
- **Report control:** add an overflow `PopupMenuButton` (or an IconButton) in actions with a "Report" item; on tap show a simple dialog/sheet to pick a reason (reuse existing reasons if any; else literals like 'Spam'/'Inappropriate'/'Other'), then call `reportForumPost(widget.postId, reason)` and show a brief confirmation via existing snackbar pattern in this screen.

Reuse existing localized strings where present; literals otherwise (no new ARB keys).

- [ ] **Step 5: Run green + analyze + full suite**

Run: `cd linguaquest && flutter test test/data/forum_report_test.dart && flutter analyze && flutter test`
Expected: PASS, `No issues found!`, `All tests passed!`

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/discover/forum_post_detail_screen.dart linguaquest/lib/data/repositories/forum_repository.dart linguaquest/lib/data/repositories/mock_repositories.dart linguaquest/lib/data/repositories/api_repositories.dart linguaquest/lib/core/state/app_controller.dart linguaquest/test/data/forum_report_test.dart
git commit -m "feat(forum): favorite button + report flow + distinct like icon states"
```

---

### Task 3: Listening question audio control

**Files:**
- Modify: `linguaquest/lib/features/quiz/quiz_session_screen.dart`
- Test: `linguaquest/test/features/listening_audio_test.dart` (Create)

**Context:** `_QuestionPromptPanel.build` (quiz_session_screen.dart:377) renders image badge + `question.prompt` text + pills, but for `listeningWordChoice`/`listeningMeaningChoice` (QuizQuestionType) there is NO audio play control — the user sees prompt text but cannot hear audio. `question.word` is a `Word` carrying `audioUKUrl`/`audioUSUrl` (and `audioUrl` getter). `PronunciationControls` (core/widgets/pronunciation_controls.dart) is the existing play widget (used in training_session_screen).

**Interfaces:** For listening question types, `_QuestionPromptPanel` additionally renders `PronunciationControls(word: question.word.word, audioUKUrl: question.word.audioUKUrl, audioUSUrl: question.word.audioUSUrl)`.

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/features/listening_audio_test.dart`. Build a `QuizQuestion` of type `listeningWordChoice` with a `Word` that has an audio URL, pump `_QuestionPromptPanel` (if private, pump the smallest public wrapper that renders it, or make a minimal MaterialApp around a constructed panel — if `_QuestionPromptPanel` is private, test via the public quiz screen with a seeded listening question, or refactor minimally to expose it for test). Assert a `PronunciationControls` widget is present for a listening question and absent for a non-listening question (e.g. meaningChoice).

- [ ] **Step 2: Run red**

Run: `cd linguaquest && flutter test test/features/listening_audio_test.dart`
Expected: FAIL (no PronunciationControls for listening).

- [ ] **Step 3: Implement**

In `_QuestionPromptPanel.build` (quiz_session_screen.dart:377-409), after the prompt `Text` (or below the pills), add:

```dart
if (question.type == QuizQuestionType.listeningWordChoice ||
    question.type == QuizQuestionType.listeningMeaningChoice) ...[
  const SizedBox(height: 12),
  PronunciationControls(
    word: question.word.word,
    audioUKUrl: question.word.audioUKUrl,
    audioUSUrl: question.word.audioUSUrl,
  ),
],
```

Add the import for `PronunciationControls` if absent. Confirm the `Word` field names (`audioUKUrl`/`audioUSUrl`) against `lib/data/models/lesson.dart` and adjust if the real getters differ.

- [ ] **Step 4: Run green + analyze + full suite**

Run: `cd linguaquest && flutter test test/features/listening_audio_test.dart && flutter analyze && flutter test`
Expected: PASS, `No issues found!`, `All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/quiz/quiz_session_screen.dart linguaquest/test/features/listening_audio_test.dart
git commit -m "feat(quiz): add audio playback control to listening questions"
```

---

### Task 4: Fix broken recommendation "Start Practice" button

**Files:**
- Modify: `linguaquest/lib/features/quests/progress_analytics_screen.dart`
- Test: covered by analyze + manual; add a widget test only if feasible.

**Context:** `_RecommendationCard` (progress_analytics_screen.dart:558-561) does `context.push('/study')` — but there is NO `/study` route (only `/study/new` and `/study/review`), so the button is broken. The `recommendation` carries `targetWordIds` and `exerciseType`. The fix must navigate to a REAL existing session route, passing the recommendation context as far as the existing routes support.

**Investigation required first:** open `lib/core/routing/app_router.dart` and the study session routes (`/study/new`, `/study/review`) and their screens to determine what query params they accept (e.g. wordIds). Determine the closest real route that can start a targeted practice.

**Interfaces:** The button navigates to a valid existing route. If a route supports word-id filtering, pass `recommendation.targetWordIds`; otherwise navigate to the most appropriate existing session route (e.g. `/study/review`) and document the limitation in the commit message.

- [ ] **Step 1: Fix the navigation**

Replace `context.push('/study')` with a valid route. Preferred: if `/study/review` or `/study/new` accepts a `wordIds` query param, build `'/study/review?wordIds=${recommendation.targetWordIds.join(',')}'` (URL-encode). If neither route accepts word filtering, route to the existing review/new session that best matches a "targeted practice" intent (`/study/review`), so the button at least works. Do NOT invent a new route/screen — wire to what exists.

- [ ] **Step 2: Verify**

Run: `cd linguaquest && flutter analyze && flutter test`
Expected: `No issues found!`, `All tests passed!`. Manually confirm (by reading the route table) that the new push target is a registered route.

- [ ] **Step 3: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib/features/quests/progress_analytics_screen.dart
git commit -m "fix(recommend): point Start Practice at a real session route (was broken /study)"
```

---

## Final Verification

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze && flutter test
```

Expected: `No issues found!` / `All tests passed!`

## Self-Review

**Spec coverage:** A (privacy/data/notifications entries)→Task 1. B (favorite+report)+D (like icon)→Task 2. C1 (listening audio)→Task 3. C2 (recommendation button)→Task 4. ✓
**Placeholder scan:** Tasks 1/2/4 contain "find the real X / confirm against real file" alignment notes (labels, AppIcons names, route params, Dio injection in tests) — these are explicit instructions to match real APIs, not TODOs. Each step has concrete code/targets.
**Type consistency:** `reportPost(postId, reason, {detail})` consistent across interface/Mock/Api/controller. `toggleForumFavorite`/`isFavorited` reused (already exist). `PronunciationControls(word, audioUKUrl, audioUSUrl)` matches its existing constructor.
