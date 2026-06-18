# Design: "Learn Chinese (HSK)" transformation — English-locked UI + target-language scaffold

**Date:** 2026-06-18
**Branch:** `feat/hsk-target-language-flip` (off `codex/backend-reminder-updates`)
**Status:** Approved design → ready for implementation plan

## Goal

Flip the app from *Chinese-speakers-learn-English* to *English-speakers-learn-other-languages*.
For this branch the only **active** target language is **Chinese (HSK)**; other languages
(Spanish, French, Japanese) appear as **coming-soon** placeholders. The UI/system language is
**locked to English**. Other UI styles and copy stay unchanged for now ("文案暂时保持不变") —
only strings made *wrong* by the direction flip change.

This is the "structural flip + small HSK seed" slice. The full multi-table HSK data pipeline and
large dataset import (from the market-research plan) are a later branch.

## Decisions (locked via brainstorming)

- **Scope:** structural flip + small HSK seed (not the full pipeline).
- **Existing English content:** replaced by Chinese/HSK as the only active target; the
  target-language selector also lists Spanish/French/Japanese with a coming-soon pill.
- **Data model:** reuse/extend the existing rich `Word` model (one new field `hskLevel`).
- **Quiz direction:** Chinese word → English meaning, **pinyin shown** on cards.
- **Seed size:** **single wordbook = HSK band 1** (`wordbook_hsk1.json`), derived by script
  from the open dataset. (Dropped HSK 2 to save shipping/wiring effort; band 1 only.)
- **Data sourcing:** derive from `drkameleon/complete-hsk-vocabulary` via a one-off committed
  converter under `tools/`; no hand-typed Chinese.
- **Example sentences:** best-effort — included only where the source provides them; words
  without a sentence simply omit the context card/quiz type (factory already skips gracefully).
- **Strings policy:** UI is English-only and ARB is frozen → flipped/new strings are plain
  **English literals** in code. No new ARB keys. Existing Chinese literals not part of the flip
  stay untouched.

## Non-goals (this branch)

- Translating broad existing Chinese literals (`第 X 组`, `训练场`, study-book names, etc.).
- The normalized multi-table HSK schema (`word_level`/`meaning`/`classifier`/…).
- HSK bands 2–6 import; any non-Chinese target content.
- Removing the dormant `zh`/`ms` ARB files or `updateLocale` infra (kept like the dark-mode infra).

---

## Component design

### 1. UI locale lock (English only)

**File:** `lib/app.dart`

- `resolveAppLocale()` → always return `const Locale('en')` (ignore device locale).
- `MaterialApp.router` `locale:` → `const Locale('en')`; `localeResolutionCallback` →
  always return `const Locale('en')` (ignore `state.locale`).
- `state.locale` and `updateLocale()` remain but no longer drive the UI (dormant infra).

**Interface/contract:** the app renders English regardless of device language or any persisted
`linguaquest.locale` value. Verified by a widget test.

### 2. Target-language concept (Chinese active; others coming-soon)

**Files:** `lib/core/state/app_state.dart`, `lib/core/state/app_controller.dart`,
`lib/features/profile/settings_screen.dart`

- Add `String targetLanguage` to `AppState` (default `'zh'`), threaded through `copyWith`.
- Persist under SharedPreferences key `linguaquest.target_language`; load on bootstrap; add
  `Future<void> updateTargetLanguage(String code)` on `AppController` (mirrors `updateLocale`).
- **Repurpose `_LanguageSetting`** → "Target language" picker:
  - Title literal: `Target language`. Current-value label: `Chinese (中文)`.
  - Bottom sheet lists: **Chinese (中文) — selected** (active), and **Spanish / French /
    Japanese** rendered with the existing coming-soon pattern: `CompactEntryCard(enabled:false)`
    + `AppPill(label: 'Coming Soon', variant: PillVariant.neutral)` (same as
    `ai_learning_screen.dart` `_AiToolRow`).
  - Selecting Chinese calls `updateTargetLanguage('zh')` (no-op today); disabled rows do nothing.
  - No longer calls `updateLocale`.

**Interface/contract:** target language is a separate, persisted dimension from UI locale; only
`'zh'` is selectable; the UI shows future languages as visibly disabled.

### 3. Content model — reuse/extend `Word`

**File:** `lib/data/models/lesson.dart` (`Word`)

Add one field: `final int? hskLevel;` (nullable; default `null`; threaded through constructor,
`fromJson`/`toJson`, `copyWith` if present). Rendered as the literal `"HSK <n>"` where used.

Dataset → `Word` mapping (drkameleon entry shape:
`simplified`, `radical`, `frequency`, `pos[]`, `forms[0].traditional`,
`forms[0].transcriptions.pinyin`, `forms[0].meanings[]`, `forms[0].classifiers[]`):

| `Word` field | Source |
|---|---|
| `id` | `hsk1_<NNN>_<pinyin-ascii>` (stable, generated) |
| `word` | `simplified` |
| `phonetic` / `phoneticUK` / `phoneticUS` | `forms[0].transcriptions.pinyin` |
| `meaning` | `forms[0].meanings.join('; ')` (English) |
| `englishDefinitions` | `forms[0].meanings` (English) |
| `definitions` | `forms[0].meanings` (fallback so `definitionsFor('en')` is correct) |
| `malayDefinitions` | `const []` |
| `partOfSpeech` | `pos.join('/')` |
| `hskLevel` | `1` |
| `audioUKUrl` / `audioUSUrl` | `https://dict.youdao.com/dictvoice?audio=<simplified>&type=1` / `type=2` |
| `exampleSentences` | best-effort from source; `const []` when absent |
| `collocations` | one entry per `forms[0].classifiers[]` (量词), else `const []` |
| `difficulty` | `'Easy'` (band 1) |
| `tags` | `const []` (HSK level lives in `hskLevel`, not in ARB-mapped tags) |

`definitionsFor('en')` already returns `englishDefinitions` under English locale, so cards/quizzes
show English meanings with no consumer changes.

### 4. Seed converter (`tools/`)

**New:** `tools/hsk_seed/convert_hsk.dart` — one-off, committed (Dart, no extra deps; repo is Dart). Reads the source JSON from a local path (fetched via curl at conversion time) and writes the wordbook JSON.

- Input: `drkameleon/complete-hsk-vocabulary` HSK **3.0 band 1** list
  (`wordlists/exclusive/new/1.json`, verified to contain band-1 entries like 爱/爱好).
- Output: `lib/assets/data/wordbook_hsk1.json` matching the existing wordbook JSON shape
  (`id`, `title`, `titleEn`, `titleMs`, `category`, `examType`, `totalWords`, `words[]`, `wordIds[]`).
- Book metadata: `id:'hsk1'`, `titleEn:'HSK 1'`, `category:'hsk'`, `examType:'HSK 1'`.
- Script + generated JSON are both committed (reproducible; no hand-typed Chinese).
- Network fetch happens at conversion time (curl the source JSON locally), not at app runtime.

**Interface/contract:** running the script regenerates `wordbook_hsk1.json` deterministically; the
app loads it as a normal asset.

### 5. Wordbook / study-plan wiring swap

- `lib/data/wordbook_asset_loader.dart`: `_bookIds` → `['hsk1']`.
- `pubspec.yaml` assets: replace the four `wordbook_*.json` lines with `wordbook_hsk1.json`.
- `lib/data/models/study_plan.dart`:
  - `studyBooks` → single `StudyBookInfo(id:'hsk1', name:'HSK 1', cover:'🀄', description: <English>)`.
  - `studyBookIdForTarget(target)` → returns `'hsk1'` for HSK/中文 targets (default `'hsk1'`).
  - `normalizedStudyBookId(value)` → maps legacy ids and `'HSK 1'`→`'hsk1'`; default `'hsk1'`.
- New-user defaults: `mock_repositories.dart` register → `targetExam:'HSK 1'`, `level:'Beginner'`;
  study-plan defaults resolve `wordBookId:'hsk1'`.
- `lib/features/auth/goal_setup_screen.dart`: `targets` → `['HSK 1']`; `_target` default `'HSK 1'`.
- `lib/core/utils/ui_labels.dart`: `displayTarget` / `displayWordbookTitle` / `displayWordbookDescription`
  return English literals for `hsk1` / `'HSK 1'` (no ARB keys).

**Removed assets:** `wordbook_beginner.json`, `wordbook_ielts.json`, `wordbook_toefl.json`,
`wordbook_gre.json` deleted; all references repointed to `hsk1`.

### 6. Quiz direction flip — `lib/data/lesson_factory.dart`

All six hardcoded Chinese prompts → English literals (`meaning` is now English so `answer` stays
valid). `word.word` = Chinese characters; pinyin available via `word.phonetic`.

| Type | New prompt (English literal) | `answer` |
|---|---|---|
| meaningChoice | `Select the English meaning of "<word>".` | English meaning |
| chineseChoice (reverse) | `Select the Chinese word for: <meaning>` | `<word>` (characters) |
| contextChoice | `Choose the English meaning of "<word>" in: <sentence>` (skipped if no sentence) | English meaning |
| spelling | `Type the pinyin for this word: <meaning>` | pinyin |
| listeningWordChoice | `Play the audio and choose the word you hear.` | `<word>` |
| listeningMeaningChoice | `Play the audio and choose the English meaning.` | English meaning |

- **Pinyin spelling normalization:** spelling answers compared **toneless + lowercased + spaces
  stripped** (e.g. `nǐ hǎo` → `nihao`; accepts `ni hao`). Implemented in the answer-check path used
  by the spelling question type; covered by a unit test. (Locate the existing spelling comparison;
  add a `normalizePinyin()` helper rather than ad-hoc string compares.)
- Lesson titles (`第 X 组`), `训练场`, explanations: left as-is (non-goal).

### 7. Testing

- **Seed schema test:** every entry in `wordbook_hsk1.json` has non-empty `word`, `phonetic`
  (pinyin), ≥1 English meaning, and `hskLevel == 1`.
- **Locale lock test:** with an arbitrary device locale and a persisted non-en `state.locale`, the
  rendered `Localizations.localeOf` / app locale is `en`.
- **Wordbook/quiz test:** `wordbook_hsk1` loads; `lessonsFromWordBook` yields questions whose
  prompts are English and whose `answer` matches the mapped field; `normalizePinyin` accepts
  toneless input.
- **Repair existing tests:** grep for `beginner`/`ielts`/Chinese quiz-prompt assertions and update.
  Keep `test/widget_test.dart` and `test/core/theme/app_tokens_test.dart` green.
- **Gate:** `flutter analyze` and `flutter test` must pass with output shown (per CLAUDE.md).

## Data flow

1. App boot → locale forced `en`; `targetLanguage` loaded (`'zh'`).
2. New user → `targetExam:'HSK 1'` → study plan `wordBookId:'hsk1'`.
3. `WordBookAssetLoader` loads `wordbook_hsk1.json` → `WordBook(words: [Word…])` (Chinese word,
   pinyin in `phonetic`, English in `meaning`/`englishDefinitions`).
4. `lessonsFromWordBook` → lessons + English-prompt `QuizQuestion`s.
5. Study/quiz/review UI renders unchanged (reads the same `Word` fields), now showing Chinese
   characters + pinyin + English meanings.

## Risks / edge cases

- **Pinyin tone input:** users can't easily type tone marks → toneless matching is required, else
  spelling is unwinnable. Covered by `normalizePinyin` + test.
- **Existing persisted users** (demo) may already have `targetExam:'Daily English'` and a `beginner`
  study plan → `normalizedStudyBookId` must coerce legacy ids to `'hsk1'` so no dangling wordbook.
- **Youdao audio for Chinese:** `dictvoice?audio=<hanzi>` returns Mandarin TTS; acceptable for the
  seed. If a word fails, listening quiz still renders (audio best-effort).
- **drkameleon band-1 size (~500):** larger than the earlier ~300 estimate, but the script handles
  it; no manual effort. If too large for the seed, the script can cap to the first N by `frequency`.
