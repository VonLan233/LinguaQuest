# Issue #77 §5 — Class-Code Removal + Community Improvements — Design Spec

Date: 2026-06-26
Author: design spec (no code in this document)
Scope: Flutter app (`linguaquest/`) only. **No server changes.**
i18n status: **UNFROZEN** for this work (we add and remove ARB keys).

---

## 1. Overview & mapping to §5

GitHub issue #77 §5 「班级社区功能」 has two authoritative decisions:

- **(a) Cancel / remove the class-code feature entirely.** There is no real class
  management — `class_mode_screen.dart` is a pure frontend mock (a `TextField`
  pre-filled with `'LQ-2048'` whose join button only pops a `SnackBar` via
  `l10n.classModeJoined(code)`; the "view progress" button pushes
  `/class-progress`, a hardcoded 3-row mock). It has **no backend** and earns no
  rubric marks. §5(a) says cut it. → **PART A** (clean deletion).
- **(b) Improve the community / forum experience.** The forum backend already
  supports tag, like, comment, favorite, and report. §5(b) asks for a better
  browsing experience, not new infrastructure. → **PART B** (additive UI on top
  of the existing forum repo + server).

This spec is **app-only**. No class tables exist in the server (the class
backend was never built), so there is nothing to delete server-side.

### Relationship to the superseded class-backend spec

`docs/superpowers/specs/2026-06-25-class-mode-backend-design.md` proposed a full
class backend. §5(a) **cancels** that direction. That spec must be marked
**SUPERSEDED** (see §4). It was never implemented, so marking it is a one-line
banner edit with no code impact. **Do not** confuse this with the *deployed*
`/study-spots` MAP backend — that is a separate, graded feature and must not be
touched here.

---

## 2. Scope

### In scope

- **PART A:** Delete the two class screens; remove their routes + imports; remove
  the "Class Mode" quest row; remove all `class*` l10n keys from 3 ARBs; mark the
  class-backend spec SUPERSEDED.
- **PART B:** Client-side **tag filter** on the community screen; **redesigned
  post card** (author + relative time + colored tag badge + like/comment counts);
  a **"Progress" tag** for learning-update posts plus an optional "Share an
  update" quick entry; add the needed l10n keys.

### Out of scope (YAGNI)

- **Reply threading.** Flat comments already exist
  (`forum_post_detail_screen.dart` `_CommentCard` / `_submitComment`) and fully
  satisfy §5's "comment or reply" intent. Nested/threaded replies require a
  parent-id schema change, recursive rendering, and collapse/expand UX — high
  cost, low marginal value. **We explicitly do NOT build threading.**
- **No new XP system.** The Progress-tag post reuses the *existing*
  `createForumPost` flow, which already grants the existing
  `RewardEventType.forumInteraction` XP reward
  (`app_controller.dart:1114-1136`). No new reward type.
- **No server changes**, except note the one optional `authorName` gap in §6
  (deferred, app degrades gracefully).
- **No class backend** of any kind.

---

## 3. PART A — exact removal surface

Grep already confirms the *only* references to the class feature are the ones
below (`grep -rn "class-mode\|class-progress\|ClassModeScreen\|ClassProgressScreen"`).

### 3.1 Files to delete

- `linguaquest/lib/features/quests/class_mode_screen.dart` (whole file)
- `linguaquest/lib/features/quests/class_progress_screen.dart` (whole file)

### 3.2 `lib/core/routing/app_router.dart`

- Remove import `import '../../features/quests/class_mode_screen.dart';` (line 35)
- Remove import `import '../../features/quests/class_progress_screen.dart';` (line 36)
- Remove the `/class-mode` `GoRoute` (lines 156-159)
- Remove the `/class-progress` `GoRoute` (lines 160-163)

### 3.3 `lib/features/quests/quest_screen.dart`

- Remove the "Class Mode" `_QuestRow` (lines 72-78, the block with
  `icon: AppIcons.groups`, `title: l10n.questClassMode`,
  `body: l10n.questClassModeBody`, `value: l10n.questClassCode`,
  `route: '/class-mode'`).
- Also remove the preceding `const SizedBox(height: 10)` (line 71) that spaced it,
  so the Analytics row and the AI-Tutor row stay correctly spaced. (The remaining
  rows keep their own leading spacers.)

### 3.4 l10n keys to REMOVE (all 3 ARBs: `app_en.arb`, `app_zh.arb`, `app_ms.arb`)

Remove these keys **and** any sibling `@key` metadata entries if present:

1. `questClassMode`  ← appears **twice** in each ARB (line 150 *and* a duplicate
   at line ~788/765). **Remove BOTH occurrences.** (The second is in the
   `questTitle`/`questDailyQuests` block.) After removal, grep must show zero
   `questClassMode` in non-generated files.
2. `questClassModeBody`
3. `questClassCode`
4. `classModeTitle`
5. `classModeSubtitle`
6. `classModeJoined` (placeholder `{code}` — remove its `@classModeJoined`
   metadata too if present)
7. `classModeJoin`
8. `classModeViewProgress`
9. `classProgressTitle`
10. `classProgressOverview`
11. `classProgressSubtitle`
12. `classProgressWeakWord` (placeholder `{word}` — remove metadata too)
13. `classTopicExamSignals`
14. `classTopicTravelBasics`
15. `classTopicWorkplace`

After editing the ARBs, run `flutter gen-l10n` so the generated
`AppLocalizations` no longer exposes these getters. Then `flutter analyze` must
be clean (any leftover `l10n.classX` reference would fail compile — verify there
are none after deleting the screens + quest row).

**Risk control (do this FIRST, before deleting keys):** grep every key above
across `lib/` and `test/` excluding `lib/l10n/generated/`. The current grep shows
all usages live only in the two screens being deleted and the one quest row being
removed. Deleting source first, then keys, guarantees no dangling reference.

### 3.5 No server change

No class tables, routes, or DTOs exist. PART A touches the app only.

---

## 4. Superseded-spec note

Add a one-line banner at the very top of
`docs/superpowers/specs/2026-06-25-class-mode-backend-design.md`, directly under
the H1, replacing/above its existing status blockquote:

```
> **SUPERSEDED (2026-06-26): Issue #77 §5(a) cancels the class-code feature.
> The class backend was never implemented; see
> 2026-06-26-issue77-community-design.md. This spec is retained for history only.
> (Unrelated to the deployed /study-spots map backend.)**
```

No other change to that file. Do not touch `study_spots` / `/study-spots`.

---

## 5. PART B — Forum improvements

All additive, reusing the existing forum repo (`listPosts`, `createPost`,
`listComments`, like/favorite/report) and the existing Cozy Quest primitives
(`AppCard`, `AppPill`, `AppTokens`, `AppIcons`).

### 5.1 Tag filter on `community_screen.dart`

- Add a single client-side filter state to `_CommunityScreenState`:
  `String _selectedFilter = 'All';`
- Render a horizontal filter-chip row directly under the AppBar (above the
  `ListView` of posts), using Material `ChoiceChip`s (consistent with
  `forum_compose_screen.dart`'s existing chip usage), wrapped in a horizontally
  scrollable row so it never overflows.
- Filter options, in order: **All, Grammar, Vocabulary, Culture, General,
  Progress** (Progress is the new tag introduced in §5.3).
- Filtering is **purely client-side**: derive the displayed list as
  `_selectedFilter == 'All' ? posts : posts.where((p) => p.tag == _selectedFilter)`.
  No new repo call; `refreshForumPosts()` still loads the full list on init.
- Empty filtered result: show the existing `MascotEmptyState` (reuse its
  title/message, optionally localize — see §7) so a filter with no matches reads
  cleanly rather than as a blank screen.
- Chip labels are localized (see §7); the underlying compared value is the raw
  English tag string stored on the post (`post.tag`), so the comparison stays
  stable across locales.

### 5.2 Redesigned post card (`_ForumPostCard`)

Keep `AppCard` + tap → `/forum/posts/${post.id}`. Reorder/extend the card body to
show, top to bottom:

1. **Header row:** author name (`post.authorName`, `titleSmall`/`labelLarge`,
   `FontWeight.w700`) on the left; **relative timestamp** (e.g. "2h ago", "3d
   ago", "just now") on the right in `bodySmall` / `onSurfaceVariant`. Compute
   relative time from `post.createdAt` with a small local helper (no new
   dependency — simple `DateTime.now().difference(createdAt)` buckets:
   now/minutes/hours/days, fall back to a short date for >7d). Localize the unit
   labels (see §7) or keep them compact and language-neutral; decision deferred
   to §8.
2. **Tag badge:** keep the existing `AppPill` with `icon: AppIcons.tag`. Use a
   **tag-colored variant**: map tag → `PillVariant`
   (e.g. Grammar→`primary`, Vocabulary→`xp`, Culture→`streak`,
   General→`success`, Progress→`success` or a distinct variant). Exact mapping is
   a small switch in the card; reuse only existing `PillVariant` values (no new
   variants — YAGNI). The pill **label** is the localized tag text.
3. **Title** (`titleMedium`, `w700`) — unchanged.
4. **Body preview** (`maxLines: 3`, ellipsis) — unchanged.
5. **Footer counts row:** keep the existing like icon + `likeCount` and comment
   icon + `commentCount` (already present, lines 106-135). No change needed
   beyond spacing for the new header.

All widgets are existing primitives; this is layout only. No model or repo
change required for the card *as rendered against the mock repo*, because the
mock seeds `authorName` and `createdAt` (see §6).

### 5.3 "Progress" tag — learning-update flow

- In `forum_compose_screen.dart`, extend `_kTags` to include `'Progress'`:
  `const _kTags = ['Grammar', 'Vocabulary', 'Culture', 'General', 'Progress'];`
  The chip set, selection, and submit are unchanged — `createForumPost(tag:
  _selectedTag)` already passes the tag through. So a "learning update" is just a
  normal post tagged `Progress`.
- **Optional quick entry** on the community screen ("Share an update"): a
  secondary affordance (e.g. a labeled button/quick-action above the list, or a
  second mini-FAB) that navigates to `/forum/compose`. Since the compose screen
  cannot currently receive a pre-selected tag via route, the cleanest minimal
  option is: keep the single existing FAB ("New Post") and **add one labeled
  entry** "Share an update" that also pushes `/forum/compose`; pre-selecting the
  Progress tag is a **deferred decision** (§8) — it would need a query param on
  `/forum/compose`. Default plan: ship the Progress tag + the labeled entry; do
  **not** add the query param unless §8 decides to.
- **XP:** publishing any forum post (including a Progress post) already triggers
  the existing `RewardEventType.forumInteraction` reward via the existing
  `createForumPost` path (`app_controller.dart:1114-1136`). **No new XP.**

### 5.4 Reply threading — OUT OF SCOPE

Stated explicitly per §2: flat comments already satisfy "comment or reply".
Threading is not built.

---

## 6. Data / model checks

`ForumPost` (`lib/data/models/forum.dart`) **already exposes** both fields the
card needs:

- `authorName` (line 19; `fromJson` defaults to `'Anonymous'` when the server
  omits it, line 34).
- `createdAt` (`DateTime`, line 28; `fromJson` parses ISO or falls back to
  `DateTime.now()`, lines 43-45).

So **no model change is required.** The card can be built today.

**Mock repo** (`mock_repositories.dart`): seed posts set both `authorName`
(e.g. 'Demo User', 'LinguaLearner', 'CultureExplorer', lines 1282/1297/1312) and
`createdAt`, and `createPost` sets `authorName: 'You'` (line 1196). So in offline
demo mode the card shows real author + time. ✅

**Server gap (note, do NOT fix here):** the live backend's `_forumPostDto`
(`server/lib/src/routes.dart:1390-1409`) returns `authorId` but **NOT**
`authorName`, and the query is `SELECT * FROM forum_posts` with **no JOIN to
`users`** (`database.dart:1964`). Against a real backend, `authorName` therefore
falls back to `'Anonymous'`. `createdAt` **is** returned (line 1406) and parses
fine. Consequence: the card degrades gracefully (shows "Anonymous" + correct
time) — acceptable for this app-only change. **Optional future server task
(deferred, §8):** add `author_name` to `_forumPostDto` via a `JOIN users u ON
u.id = forum_posts.author_id` selecting `u.name`. Not required for §5(b) and
out of scope for this spec.

---

## 7. l10n keys to ADD (all 3 ARBs, en/zh/ms)

These are **new** keys (i18n is unfrozen). Tag *filter labels* and the Progress
tag must be localized; relative-time labels are listed but their use depends on
§8.

| Key | en | zh | ms |
|---|---|---|---|
| `communityFilterAll` | All | 全部 | Semua |
| `communityTagGrammar` | Grammar | 语法 | Tatabahasa |
| `communityTagVocabulary` | Vocabulary | 词汇 | Kosa kata |
| `communityTagCulture` | Culture | 文化 | Budaya |
| `communityTagGeneral` | General | 综合 | Umum |
| `communityTagProgress` | Progress | 学习进展 | Kemajuan |
| `communityShareUpdate` | Share an update | 分享学习进展 | Kongsi kemajuan |
| `communityNewPost` | New Post | 发帖 | Catatan baharu |
| `communityNoPostsInFilter` | No posts in this category yet | 该分类还没有帖子 | Tiada catatan dalam kategori ini |
| `communityTimeJustNow` | Just now | 刚刚 | Sebentar tadi |
| `communityTimeMinutesAgo` `{count}` | {count}m ago | {count} 分钟前 | {count} minit lalu |
| `communityTimeHoursAgo` `{count}` | {count}h ago | {count} 小时前 | {count} jam lalu |
| `communityTimeDaysAgo` `{count}` | {count}d ago | {count} 天前 | {count} hari lalu |

Notes:
- The three `communityTime*Ago` keys use an ICU `{count}` placeholder (add
  matching `@key` metadata with `placeholders: { count: { type: int } }`).
- `communityNewPost` replaces the current hardcoded `'New Post'` AppBar title and
  the FAB intent; reuse it rather than leaving the string hardcoded.
- The tag-label keys are used for chip labels and the card's tag pill; the
  stored/compared value remains the raw English tag.
- If §8 decides to keep timestamps language-neutral/compact, the three
  `communityTime*Ago` keys may be dropped — list them now so the plan is complete.

Run `flutter gen-l10n` after adding.

## l10n keys to REMOVE

The 15 class keys enumerated in **§3.4** (note `questClassMode` appears twice per
ARB — remove both).

---

## 8. Open decisions

1. **Relative-time localization vs. compact neutral.** Localize via the three
   `communityTime*Ago` keys, or render compact neutral strings ("2h", "3d")
   with no ARB keys? (Default: localize, keys listed in §7.)
2. **Pre-select Progress tag from the quick entry.** Should "Share an update"
   pre-select the Progress tag in compose (needs a `?tag=Progress` query param on
   `/forum/compose`), or just open compose with the default tag? (Default: just
   open compose; do not add the query param.)
3. **Quick-entry placement.** "Share an update" as a labeled button above the
   list, a second FAB, or fold into the existing single FAB's intent? (Default:
   one labeled entry above the list + keep the existing FAB.)
4. **Tag→PillVariant color mapping.** Confirm the exact mapping (Grammar/
   Vocabulary/Culture/General/Progress → which `PillVariant`). (Default proposed
   in §5.2; reuse existing variants only.)
5. **Optional server `authorName` JOIN.** Defer entirely (app degrades to
   "Anonymous"), or schedule a follow-up server task? (Default: defer; out of
   scope.)

---

## 9. Testing approach (widget tests)

New tests under `linguaquest/test/features/` (none exist for discover today):

**PART A — feature gone:**
- `app_router` builds without the `class_mode`/`class_progress` imports; assert
  no `GoRoute` matches `/class-mode` or `/class-progress` (navigating there
  yields the router's error/fallback, not a `ClassModeScreen`).
- A guard test (grep-style or analyzer-backed) that `ClassModeScreen` /
  `ClassProgressScreen` symbols no longer exist — effectively covered by
  `flutter analyze` passing after deletion.
- `quest_screen` widget test: pump `QuestScreen`, assert it renders the Daily/
  Achievements/Leaderboard/Analytics/AI-Tutor rows and **does not** render a
  "Class Mode" row (the localized `questClassMode` string is absent).

**PART B — community:**
- **Tag filter filters posts:** pump `CommunityScreen` with a mock repo seeded
  with posts across tags; tap the "Grammar" chip; assert only Grammar-tagged post
  titles are shown and others are gone; tap "All" to restore.
- **Empty filter state:** select a tag with no posts; assert the empty-state
  (localized `communityNoPostsInFilter`) renders.
- **Post card shows author + tag + counts:** assert the card renders
  `post.authorName`, the tag pill label, a relative-time string, and both
  `likeCount` and `commentCount`.
- **Compose has Progress tag:** pump `ForumComposeScreen`; assert a "Progress"
  `ChoiceChip` exists, is selectable, and submitting calls `createForumPost(tag:
  'Progress')` (verify via the mock controller / repo capturing the tag).

**Gates:** `flutter analyze` and `flutter test` must both pass; run
`flutter gen-l10n` before testing so generated getters match the ARBs.

---

## 10. Risks

- **Dangling l10n references.** Removing keys before deleting their usages would
  break the build. Mitigation: delete source (screens + quest row) **first**,
  then keys, then `gen-l10n`, then `analyze`. Grep (§3.4) confirms usages are
  contained to the deleted files.
- **Duplicate `questClassMode` key.** Each ARB defines it twice (line 150 and
  ~788/765). Missing the second occurrence leaves a dead key (harmless but
  untidy) — remove both; verify with a final grep.
- **`authorName` shows "Anonymous" on live backend.** Documented (§6),
  acceptable, mock mode unaffected. Do not silently "fix" by touching the server
  in this change.
- **Do not touch `/study-spots` / `study_spots`.** The superseded class spec is
  unrelated to the graded map backend; only the banner line changes.
