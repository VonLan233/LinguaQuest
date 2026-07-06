# Design: Multi-language foundation + Japanese (LinguaQuest) — DEVELOPMENT_PLAN §2 + §3.1

Status: design (no source changes). Date: 2026-06-27.
Scope: turn the single-language (Chinese/HSK) app into a multi-language app with a
second language (Japanese: JLPT N5–N1 + JFT-Basic), two-level selection everywhere,
and fully **independent per-(language, wordbook) progress**.

This spec is deliberately honest about how invasive the progress-isolation refactor
is, and chooses the **minimal correct** design: namespace storage keys by a
`(language, wordBookId)` composite rather than rewriting persistence.

---

## 0. Current architecture (verified by reading the code)

### Single-language lock today
- `AppState.targetLanguage` exists (`app_state.dart:174`, default `'zh'`) but is
  used only for AI calls and the map achievement flag; it does **not** scope
  progress, wordbooks, or lessons.
- `currentWordBookId` (`app_state.dart:153`, initial `'hsk1'`) is a single global
  value. `WordBookAssetLoader._bookIds` (`wordbook_asset_loader.dart:11`) hard-codes
  `hsk1..hsk6`; all are Chinese. `_mappedWordBookId()` in the controller
  (`app_controller.dart:2217`) literally `return 'hsk1';`.
- Server `allowedWordBookIds` (`study_plan_policy.dart:2`) = `{hsk1..hsk6}`, and
  legacy ids collapse to `hsk1`.

### Where progress lives, and whether it is global (it is)
All per-progress persistence is **global** — NOT keyed by wordbook or language:

| Progress concern | Where persisted | Key today | Global? |
|---|---|---|---|
| current wordbook id | prefs | `linguaquest.currentWordBookId` | yes (single) |
| completed lessons | prefs | `linguaquest.completedLessons` | **yes — global** |
| today lessons/reviews/training/rewards | prefs | `linguaquest.today.*` | yes (global, day-scoped) |
| learned words / favorites / new-wordbook / mistakes (UserWord) | `MockUserWordRepository` prefs `linguaquest.user_words.<uid>`; server `user_words` table | keyed by `uid` only (+ a `word_book_id` *column* that is set from `lesson.section`, not the active book) | **mostly global per uid** |
| review queue / due / weak | derived from UserWord + CustomWord | n/a | global |
| vocab notebook / mistake cards (CustomWord) | `MockCustomWordRepository` (in-memory) / server `custom_words` | `uid` only | global |
| study plan | prefs `linguaquest.studyPlan.<uid>`; server `study_plans` (`uid UNIQUE`) | `uid` only — **exactly one plan per user** | global |
| reward tasks / point grants / notifications / assets | prefs keyed by `<uid>` | `uid` only | global (out of scope for isolation) |

Critical finding: **`completedLessonIds` is a single global set** and the
`study_plans` table has `uid UNIQUE` — one plan per user. Switching wordbook today
(`switchWordBook`, `app_controller.dart:641`) overwrites the single plan and reuses
the same global `completedLessonIds`, so progress from book A bleeds into book B.
The hard requirement (independent progress per (language, wordbook), restore on
switch, never wipe siblings) is therefore a **real change**, not a no-op.

Also note: `UserWord.wordBookId` is currently set to `lesson.section`
(`app_controller.dart:1950`), i.e. the lesson's display section string, **not** the
active wordbook id. That is a latent bug for isolation and must be corrected to the
real `(language, wordBookId)` composite.

---

## 1. Progress isolation design (the hard core)

### 1.1 The composite key
Introduce a single canonical scope token used everywhere progress is namespaced:

```
scope = "<language>::<wordBookId>"     e.g. "zh::hsk1", "ja::jlpt_n5"
```

- `language` is the ISO code already used by `targetLanguage` (`zh`, `ja`).
- `wordBookId` is the existing book id (`hsk1`, …) plus new Japanese ids
  (`jlpt_n5`..`jlpt_n1`, `jft_basic`).
- A pure helper `progressScope(language, wordBookId)` produces the token; it is the
  ONLY place the separator is defined.

### 1.2 SharedPreferences key scheme (client / mock = source of truth for MVP)
Today's global keys become **scoped** by appending `.<scope>`:

| Concern | Old key | New key |
|---|---|---|
| completed lessons | `linguaquest.completedLessons` | `linguaquest.completedLessons.<scope>` |
| today lessons | `linguaquest.today.lessons` | `linguaquest.today.lessons.<scope>` |
| today reviews | `linguaquest.today.reviews` | `linguaquest.today.reviews.<scope>` |
| today training (+games/xp) | `linguaquest.today.training*` | `…training*.<scope>` |
| today rewards | `linguaquest.today.rewards` | `…rewards.<scope>` |
| today date guard | `linguaquest.today.date` | keep **global** (one calendar day for whole app) |
| user words | `linguaquest.user_words.<uid>` | `linguaquest.user_words.<uid>.<scope>` |
| custom words (vocab notebook / mistakes) | in-memory / `custom_words` | scope filter (see 1.4) |
| study plan | `linguaquest.studyPlan.<uid>` | `linguaquest.studyPlan.<uid>.<scope>` |
| current language | (new) | `linguaquest.current_language` (global, single) |
| current wordbook **per language** | `linguaquest.currentWordBookId` | `linguaquest.currentWordBookId.<language>` |

Keep **out of scope** (deliberately global, YAGNI): theme, locale, reminder/sensory/
privacy settings, reward-task daily state, point-grant idempotency keys,
notifications, lottery assets, AI history, forum, study spots. These are
user/device-level, not language-progress-level. Reward/notification copy can stay
generic. (Open decision OD-3 covers whether daily reward tasks should be per-scope.)

### 1.3 The "current scope" pointer and switch flow
- New global pref `linguaquest.current_language` selects the active language.
- New per-language pref `linguaquest.currentWordBookId.<language>` remembers the
  last wordbook chosen *within* each language.
- The active scope is always `(currentLanguage, currentWordBookId[currentLanguage])`.
- Switching language OR wordbook = (a) persist the new pointer(s), then (b) **load**
  that scope's progress from its scoped keys into `AppState`. It never writes to any
  other scope's keys, so siblings are untouched by construction.

### 1.4 CustomWord (vocab notebook + mistake cards) scoping
`CustomWord` has no language/wordbook field today and is stored per-uid. Two options:
- **Chosen (minimal):** add an optional `scope` field to `CustomWord`
  (default `'zh::hsk1'` on read for legacy rows) and filter `list(uid)` by the active
  scope; writes stamp the current scope. Mock repo filters in memory; server adds a
  nullable `scope TEXT` column with a backfill default.
- Rejected: separate tables per language (over-engineered).

### 1.5 Migration of existing single-language data → `zh::hsk1`
One-shot, idempotent migration guarded by a flag `linguaquest.migrated.v2_scope`:
1. If flag set, skip.
2. For each global key in the table above, if the global key exists and the scoped
   `zh::hsk1` key does not, **copy** value to the `zh::hsk1` key (do not delete the
   global immediately — keep one release as a safety net, then remove in a follow-up).
3. `linguaquest.currentWordBookId` → `linguaquest.currentWordBookId.zh`.
4. Default `current_language = 'zh'`.
5. UserWord rows: on first scoped read, rows whose stored `wordBookId` is a
   section-string or empty are treated as belonging to `zh::<currentWordBookId>` and
   restamped. (Because today's `wordBookId` = `lesson.section`, the migration maps any
   non-book value to the resolved HSK book.)
6. Server: backfill `user_words.language='zh'` (new column), and split the single
   `study_plans` row — see 1.6.
7. Set the flag.

### 1.6 Server schema changes (additive, backward-compatible)
- `user_words`: add `language TEXT NOT NULL DEFAULT 'zh'`. Queries that load/scope a
  user's words add `AND language=@language AND word_book_id=@wordBookId`. The unique
  constraint (already dropped historically) is re-added as
  `(uid, language, word_book_id, word_id)` if uniqueness is desired.
- `study_plans`: the `uid UNIQUE` constraint **must change** to allow one plan per
  scope. Add `language TEXT NOT NULL DEFAULT 'zh'`; replace `UNIQUE(uid)` with
  `UNIQUE(uid, language, word_book_id)`. `load(uid)` becomes
  `load(uid, language, wordBookId)`; bootstrap loads the plan for the active scope.
- `allowedWordBookIds` in `study_plan_policy.dart` gains the Japanese ids; add an
  `allowedLanguages = {zh, ja}` set and validate `(language, wordBookId)` consistency
  (e.g. `jlpt_*` only valid with `ja`).
- `custom_words`: add nullable `scope TEXT` (see 1.4).
- All changes are `ADD COLUMN … DEFAULT`/constraint swaps run in the existing
  idempotent `CREATE TABLE IF NOT EXISTS` migration block in `database.dart`.

### 1.7 Exact state fields / files that change
- `app_state.dart`: add `currentLanguage` (String, default `'zh'`); thread through
  ctor + `copyWith`. `currentWordBookId` stays but is now interpreted *within*
  `currentLanguage`. No new progress collections — the existing
  `completedLessonIds`, `today*`, `userWords`, `customWords` are simply re-loaded per
  scope.
- `app_controller.dart`: all `_save*`/`_stringSet` helpers take/append the scope;
  `bootstrap` resolves scope and loads scoped values; `switchWordBook` becomes a
  scope-switch (load, not merge); add `switchLanguage`; `updateTargetLanguage` sets
  `currentLanguage` and triggers a scope load; `_recordLessonUserWords` /
  `updateTargetWordFlags` stamp the real active `(language, wordBookId)` instead of
  `lesson.section`.
- `mock_repositories.dart`: `MockUserWordRepository`, `MockStudyPlanRepository`,
  `MockCustomWordRepository` take a scope (or `(language, wordBookId)`) param on
  list/upsert/load/save.
- `api_repositories.dart` + server: pass `language`/`wordBookId` to the relevant
  endpoints.

---

## 2. Data model — language dimension

### 2.1 WordBook
Add `language` (String, default `'zh'`) and `examLevel`/`examType` already present.
`WordBook.fromJson` reads `json['language'] ?? 'zh'`. Asset JSON files gain
`"language": "zh"|"ja"`.

### 2.2 Word
Add optional Japanese fields (all default `''`/empty, ignored by Chinese/English):
- `kana` (reading in hiragana/katakana)
- `romaji`
- `themeTags` (reuse existing `tags`), `examLevel` (reuse `hskLevel` pattern with a
  generic `examLevel`/keep `hskLevel` for zh; add `jlptLevel` or a single
  `examLevel int?`). **Chosen:** keep `hskLevel`, add `examLevel` (generic int) and a
  `language`-aware getter; avoid a second nullable per exam.
- `meaning`/`definitions` already hold zh/en meanings; Japanese books populate
  `definitions` (zh meaning), `englishDefinitions` (en meaning), `examples`
  (`WordExample.en` = Japanese sentence, `.cn` = translation — or extend `WordExample`
  with an optional `ja`/reading; **chosen minimal:** put the Japanese sentence in `en`
  slot is misleading, so add `WordExample.translation` and store the Japanese sentence
  in `en` only for zh; for ja add `WordExample` fields `text`+`translation`. To keep
  one model, **chosen:** reuse `en`=source sentence, `cn`=translation regardless of
  language — semantically "source/target").
- `audioUrl` already derivable; Japanese books fill `audioUSUrl`/`audioUKUrl` (or a
  single `audioUrl` field — **chosen:** reuse existing audio fields).

### 2.3 Display branching (pinyin vs kana/romaji)
- The word-detail / list "phonetic" line is currently `word.phonetic`
  (`wordbook_screen.dart:476`). Replace with a language-aware accessor
  `word.phoneticFor(language)`:
  - `zh` → `phonetic` (pinyin)
  - `ja` → `kana` (primary) with `romaji` as secondary/subtitle
  - else → `phoneticUK/US`
- `hskLevel` chip shows only when `language=='zh'`; JLPT/JFT level chip shows for `ja`.
- Backward-compat: every new field defaults so existing zh JSON and serialized
  `Word.toJson()` round-trip unchanged.

---

## 3. State + controller

- Add `currentLanguage` to `AppState`; `currentWordBook`/`wordBooks` are filtered to
  the active language for selection UIs (keep the full list available for the picker).
- `WordBookAssetLoader._bookIds` becomes a per-language map:
  `{zh: [hsk1..hsk6], ja: [jlpt_n5..jlpt_n1, jft_basic]}`. `loadWordBooks()` loads all
  and tags each with its `language`; a `wordBooksForLanguage(lang)` filter feeds UIs.
- Switch flows:
  - `switchLanguage(lang)`: persist `current_language`; resolve that language's
    remembered wordbook (or its first book); load that scope's progress; re-source
    lessons via `listLessonsForWordBook(book, language)`.
  - `switchWordBook(id)`: now scoped to `currentLanguage`; **load** the target scope's
    `completedLessonIds`/`today*`/`userWords`/plan from its keys (do not reuse the
    in-memory sets). This is the key behavioral change vs today.
- Re-sourcing without wiping siblings: because each scope reads/writes only its own
  keys, switching is pure load. The migration (1.5) guarantees the legacy user lands
  in `zh::hsk1` with their existing data intact.

---

## 4. Two-level selection UI

A reusable widget `LanguageWordbookPicker` (two steps):
1. **Choose language** (cards: Chinese, Japanese; future langs disabled).
2. **Choose that language's wordbook / exam plan** (HSK1–6 for zh; JLPT N5–N1 + JFT
   for ja), reusing the existing wordbook card list from
   `study_plan_settings_screen.dart` (the `_WordBookPicker` around lines 565–620),
   generalized to accept a `language` + filtered book list.

Entry points to update (all call the same picker, differing only in what they do with
the result):
- Onboarding/welcome (`onboarding_screen.dart`) — first language+wordbook choice.
- Goal Setup (`auth/goal_setup_screen.dart`) — sets `targetExam`+plan; now also sets
  language.
- Home current-target switcher — quick switch of active scope.
- Profile language+wordbook switch.
- Settings / Study Plan (`profile/study_plan_settings_screen.dart`) — currently
  single-level (`_wordBookId`); add the language step above the existing book picker.

Result of the picker → `switchLanguage` then `switchWordBook` (or a combined
`switchScope(language, wordBookId)` convenience on the controller).

---

## 5. Japanese wordbooks (data + generator)

### 5.1 Book list
- `jlpt_n5`, `jlpt_n4`, `jlpt_n3`, `jlpt_n2`, `jlpt_n1` (JLPT levels)
- `jft_basic` (JFT-Basic, ~A2, ~700–1000 core words)
All `language: "ja"`, `category: "jlpt"`/`"jft"`, `examType: "JLPT N5"` etc.

### 5.2 Generator approach (mirror `generate_hsk_wordbooks.py`)
New `tools/generate_jlpt_wordbooks.py` mirroring the HSK generator structure
(download → cache in `/tmp` → map → write `linguaquest/lib/assets/data/wordbook_<id>.json`).

Public source (note): a widely used open JLPT vocabulary dataset is
**`elzup/jlpt-word-list`** / **`jamsinclair/open-anki-jlpt-decks`** / the
**`wkostelecky`/`davidluzgouveia` JLPT vocab CSV/JSON repos on GitHub** (JLPT N5–N1
word lists with kanji, kana reading, romaji-derivable, and English meaning). JFT-Basic
has no single canonical open list; approximate it from the N5 + high-frequency
everyday subset, or use the published JFT-Basic word list (~700 words) if licensing
permits. (OD-4: confirm exact dataset + license before generation.)

Field mapping (dataset → app schema):
| App field | Source |
|---|---|
| `word` | kanji/expression (or kana if no kanji) |
| `kana` | reading (hiragana/katakana) |
| `romaji` | transliterate from kana (e.g. `pykakasi`/`romkan`, or precomputed) |
| `definitions` (zh) | zh gloss (from a JMdict zh edition or translation; may be sparse — OD-4) |
| `englishDefinitions` (en) | English gloss from dataset |
| `examples` | example sentence + translation if dataset provides (e.g. Tatoeba); else empty (like HSK stubs) |
| `audioUKUrl/audioUSUrl` (audio) | a TTS/dictionary audio URL (e.g. an open Japanese TTS or dictionary voice endpoint); else empty |
| `difficulty` | level→Easy/Medium/Hard progression (N5 Easy … N1 Hard) |
| `themeTags`/`examTags` | dataset category tags if present |
| `examLevel`/level chip | JLPT level number |

Generator keeps zh-only fields empty for ja, and vice versa, exactly as the HSK
generator leaves `malayDefinitions`/`examples` empty.

---

## 6. Language map (§3.1)

`language_map_screen.dart` currently: China pin (`zh`, enabled) shows a confirm sheet
that calls `updateTargetLanguage('zh')` and nothing else; Japan pin (`ja`) is
`enabled: false` (coming-soon snackbar).

Change:
- Set the Japan pin `enabled: true`.
- On tapping an enabled pin, instead of a bare confirm, route into **step 2** of the
  `LanguageWordbookPicker` for that language:
  - China → Chinese wordbook selection (HSK1–6).
  - Japan → Japanese wordbook selection (JLPT N5–N1 + JFT-Basic).
- On confirm: write the chosen language to state via `switchLanguage(code)` and the
  chosen book via `switchWordBook(id)` (one-shot `switchScope`). Preserve the existing
  `first_map_language_at` achievement one-shot.

---

## 7. Decomposition into ordered, independently shippable sub-phases

Each phase compiles, ships, and is testable on its own. Earlier phases add
defaults/back-compat so the app keeps working as today until later phases light up.

- **P2a — Model language dimension (no behavior change).** Add `language` to
  WordBook (default `'zh'`); add `kana`/`romaji`/`examLevel` to Word (defaults). Add
  `phoneticFor(language)` / level-chip accessors. JSON round-trips unchanged. Ship:
  app identical, model ready. Test: model unit tests for defaults + ja accessors.

- **P2b — Progress isolation + migration (the hard core, zh only).** Add
  `currentLanguage`, scope helper, scoped storage keys, migration to `zh::hsk1`,
  scope-switch semantics for `switchWordBook`, fix UserWord stamping to real book id,
  server `language` columns + `study_plans` unique-key swap. Still only Chinese books,
  but now HSK1↔HSK6 keep independent progress. Ship: switching HSK books no longer
  bleeds progress. Test: switch-and-restore golden tests; migration idempotency;
  sibling-untouched assertions.

- **P2c — Two-level selection UI.** `LanguageWordbookPicker`; wire all entry points
  (onboarding, goal setup, home switcher, profile, study plan). With only zh books the
  language step shows Chinese + disabled Japanese. Ship: new UX, same content. Test:
  widget tests per entry point; picker returns correct `(language, wordBookId)`.

- **P2d — Japanese data.** `generate_jlpt_wordbooks.py`; add 6 ja JSON assets;
  `_bookIds` per-language map; loader tags `language: 'ja'`. Ship: Japanese books
  selectable; pinyin hidden, kana/romaji shown. Test: asset load tests; word-detail
  branch tests (zh shows pinyin/HSK, ja shows kana/romaji/JLPT).

- **P2e — Language map routing (§3.1).** Enable Japan pin; route China/Japan → the
  picker's step 2; confirm writes scope. Test: map widget test for both routes.

- **P2f — Per-language search / word-detail polish.** `search_screen.dart` and
  word-detail adapt phonetic/level/meaning columns by `currentLanguage`; search
  matches kana/romaji for ja. Test: search returns ja words by kana/romaji; detail
  layout snapshot per language.

Recommended order: P2a → P2b → P2c → P2d → P2e → P2f. P2b is the riskiest and gates
real isolation; P2d/P2e/P2f are mostly additive once P2a–P2c land.

---

## 8. Testing strategy per sub-phase

- **P2a:** unit tests — `Word.fromJson/toJson` round-trip with and without ja fields;
  `phoneticFor`/level accessors; WordBook `language` default.
- **P2b (most coverage):**
  - migration: run with legacy global keys present → assert `zh::hsk1` scoped keys
    populated, flag set, second run is a no-op.
  - isolation: complete a lesson in `zh::hsk1`, switch to `zh::hsk6`, assert
    `completedLessonIds` empty there; switch back, assert restored; assert hsk6 keys
    untouched after hsk1 writes.
  - server: `study_plans` upsert for two scopes of one uid coexist; `user_words`
    filtered by `language`.
- **P2c:** widget tests that each entry point opens the picker and the controller
  receives the right scope; golden for the two-step flow.
- **P2d:** asset-load test (all 6 ja books parse); ja word renders kana+romaji, no
  pinyin, JLPT chip.
- **P2e:** tapping China vs Japan pin lands on the right wordbook list; confirm sets
  scope + preserves `first_map_language_at`.
- **P2f:** search by kana/romaji; detail layout per language.
- Cross-cutting regression: existing zh/HSK flows (bootstrap, lesson complete,
  review, study plan) unchanged for a migrated user.

---

## 9. Risks

1. **Progress-data migration (highest).** A bad migration silently loses a real
   user's HSK progress. Mitigation: copy-don't-delete for one release; idempotent flag;
   keep global keys as fallback read until P2b+1; explicit golden tests.
2. **Server schema change to `study_plans` (`uid UNIQUE` → composite).** Constraint
   swap on a live table plus splitting the single existing plan into a scoped plan.
   Mitigation: additive `language` column with default, drop-and-recreate the unique
   constraint inside the existing idempotent migration block, backfill existing rows to
   `('zh', word_book_id)`.
3. **Size of the refactor.** Every `_save*`/load path in the 2700-line controller and 3
   repositories must thread the scope; easy to miss one and leak across scopes.
   Mitigation: a single `progressScope` helper + a thin `ScopedKeys` indirection so
   keys can only be built one way; phase P2b lands behind tests before any ja content.
4. **Japanese data quality / licensing.** Open JLPT datasets vary in completeness
   (zh meanings often missing) and license. Mitigation: pick a permissively licensed
   English-glossed list, leave zh meaning/examples empty like the HSK stubs, fill later.
5. **CustomWord scoping ambiguity.** Vocab-notebook/mistake cards predate scope;
   wrong default hides a user's notebook. Mitigation: default legacy `scope='zh::hsk1'`
   and show-all fallback if `scope` is null.

---

## 10. Open decisions

- **OD-1:** Single combined `switchScope(language, wordBookId)` vs separate
  `switchLanguage`+`switchWordBook`? (Lean: provide both; map/onboarding use combined.)
- **OD-2:** One generic `examLevel int?` on Word vs keep `hskLevel` and add
  `jlptLevel`? (Lean: keep `hskLevel`, add generic `examLevel` + language-aware chip.)
- **OD-3:** Are daily reward tasks / streak per-scope or global? (Lean: global —
  YAGNI; streak is a user-level habit metric.)
- **OD-4:** Exact public JLPT dataset + license, JFT-Basic source, and whether zh
  meanings are sourced now or deferred.
- **OD-5:** Keep `today.date` global (one app-wide day) vs per-scope? (Lean: global.)
- **OD-6:** Whether to physically delete legacy global keys after the safety release
  or keep them indefinitely.
- **OD-7:** Should `wordBooks` in `AppState` hold all languages (filter in UI) or only
  the active language (reload on switch)? (Lean: hold all; filter for pickers.)

---

## Critical files for implementation
- linguaquest/lib/core/state/app_controller.dart
- linguaquest/lib/core/state/app_state.dart
- linguaquest/lib/data/models/lesson.dart
- linguaquest/lib/data/repositories/mock_repositories.dart
- server/lib/src/database.dart
