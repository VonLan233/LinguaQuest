# CustomWord multilingual meanings — design

Date: 2026-06-18
Status: approved (user approved design 2026-06-18)

## Problem

When the app language is English (or Malay), saved custom/review words show their
meaning in **Chinese** (e.g. the weak word "ambiguous" renders as "含糊的"), or fall
back to a generic generated string ("Review vocabulary item for ambiguous.").

Root cause: `CustomWord` stores only a single scalar `meaning` (Chinese). When a
dictionary `Word` — which DOES carry `definitions` / `englishDefinitions` /
`malayDefinitions` — is converted into a `CustomWord`, those multilingual lists are
dropped. There is no real per-language meaning left to render, so
`customWordMeaningFor` either shows the Chinese `meaning` or synthesizes a filler
sentence.

The reported case ("ambiguous" in Home → Weak Words) reaches the UI through the
**`UserWord.toReviewCard()`** path, not only `addCustomWord`, so both conversion
boundaries must be handled.

## Decisions (user, 2026-06-18)

- **App-only.** No backend (`server/`) changes. Offline/demo mode is the default and
  its repository is in-memory, so the fix is complete there. In API mode the backend
  ignores the new fields (backward compatible) and rendering falls back to `meaning`.
- **Manual words show their original meaning verbatim** — no generated filler. If a
  custom word has no stored per-language definition, render the user's single
  `meaning` as-is regardless of UI language.

## Approach

Store the multilingual lists **on `CustomWord`** and populate them at the two
"dictionary `Word` → `CustomWord`" conversion boundaries. Rendering needs no further
change because all 7 display sites already call `customWordMeaningFor`.

### 1. Model — `lib/data/models/custom_word.dart`

Add three fields mirroring `Word`, each defaulting to `const []`:

```dart
final List<String> definitions;        // zh
final List<String> englishDefinitions; // en
final List<String> malayDefinitions;   // ms
```

Update: primary constructor, `CustomWord.create`, `fromJson` (missing keys → `const []`),
`toJson`, `copyWith`. Backward compatible — old JSON and the backend (which omits the
keys) decode to empty lists.

### 2. Resolver — `lib/core/utils/custom_word_localization.dart`

`customWordMeaningFor(word, languageCode)` becomes:

- `en` → first **Latin-script** `englishDefinitions` entry; else `meaning` verbatim.
- `ms` → `malayDefinitions` → first Latin `englishDefinitions` → `meaning`.
- `zh` / other → `definitions` → `meaning`.

No generated filler. **CJK guard (added after review):** some baked dictionary
data carries auto-generated English "definitions" that embed the Chinese gloss
(e.g. `A target vocabulary item commonly tested as "字母A".`). For `en`/`ms` the
resolver skips candidates that still contain CJK so Chinese never surfaces in a
Latin-script UI; it then falls back to `meaning` (the user's "show original"
choice). The `meaning` fallback itself is shown verbatim and is never CJK-guarded.
`wordFromCustomWord` keeps delegating to `customWordMeaningFor`.

### 3. Backfill A — "add to wordbook" (`addCustomWord` + `target_word_detail_screen.dart`)

`AppController.addCustomWord` gains optional params
`List<String>? definitions, englishDefinitions, malayDefinitions` (default null →
stored as `const []`). The target-word-detail call site passes the source
`word.definitions / word.englishDefinitions / word.malayDefinitions`.

### 4. Backfill B — target review cards (`app_state.dart` `_buildReviewWords`)

This is the path the reported "ambiguous" actually takes. `_buildReviewWords` gains a
`List<WordBook> wordBooks` parameter (already in `AppState`'s constructor scope, where
`_reviewWords` is computed). It builds a `Map<String, Word>` keyed by word id; after
`userWord.toReviewCard()` it looks up the source `Word` by `wordId` and, when found,
`copyWith`s the card's three lists from it. `UserWord` itself is untouched (no new
fields, no persistence change).

### 5. Manual words

Pass no lists (the three stay empty) → resolver returns the user's `meaning` verbatim.

### 6. Demo seed words (added after review)

In offline/demo mode the Home → Weak Words list is fed by two **seeded
`CustomWord`s** in `mock_repositories.dart` (`seed-1` "resilient", `seed-2`
"ambiguous") created with only a Chinese `meaning` — they bypass both backfill
boundaries (no source `Word`, no `sourceWordId`). The reported "ambiguous" case is
exactly one of these. So the seeds are given real `definitions` / `englishDefinitions`
/ `malayDefinitions` directly, otherwise the fix would not be observable in the
default demo build.

## Testing

`test/locale_aware_words_test.dart`:
- Replace the two assertions that expect `en`/`ms` to return
  "Review vocabulary item for ambiguous." / "Item kosa kata ulang kaji untuk ambiguous."
  with: a `CustomWord` carrying `englishDefinitions`/`malayDefinitions` returns those
  per language; a `CustomWord` with only `meaning` returns `meaning` verbatim for every
  language.
- Add a case asserting a review card backfilled from a source `Word` localizes
  correctly via `customWordMeaningFor` / `wordFromCustomWord`.

`flutter analyze` and `flutter test` must stay green.

## Out of scope (YAGNI / per decisions)

- Backend (`server/`) schema / routes / DTO.
- Multilingual input UI in add/edit custom word.
- `UserWord` model / persistence changes.
- Migration of previously-saved words (mock repo is in-memory; API mode falls back to
  `meaning`).

## Touched files

`custom_word.dart`, `custom_word_localization.dart`, `app_controller.dart`,
`target_word_detail_screen.dart`, `app_state.dart`, `user_word.dart`,
`data/repositories/mock_repositories.dart` (seed words),
`test/locale_aware_words_test.dart`.
The 7 render sites changed in the prior commit need no further edits.

## Known limitation

Asset-sourced target words (`lib/assets/data/wordbook_*.json`) ship **real**
`malayDefinitions` but auto-generated, CJK-contaminated `englishDefinitions`. With
the CJK guard those filler entries are rejected, so adding such a word and viewing
it in English falls back to the Chinese `meaning`. Producing real English glosses
for the asset corpus is dictionary-content work owned by the external translator
(see the i18n translation freeze), out of scope here. Malay UI and the seeded demo
words localize correctly today.
