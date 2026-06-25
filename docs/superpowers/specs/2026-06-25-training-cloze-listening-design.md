# Design Spec: Training — Passage Cloze & Listening Sprint

**Date:** 2026-06-25
**Branch base:** `main`
**Status:** Approved design, ready to plan/implement
**Scope owner:** Training feature

---

## 1. Overview / Goal

The Training tab (`features/training/training_screen.dart`) ships five working drills plus two **locked** rows that render a "Coming Soon" pill and have `onTap: null`:

- **Passage Cloze** (`l10n.trainingPassageCloze`, icon `AppIcons.article`) — `training_screen.dart` lines 82–87
- **Listening Sprint** (`l10n.trainingListening`, icon `AppIcons.hearing`) — `training_screen.dart` lines 88–93

This spec unlocks both by **extending the existing engine** `features/training/training_session_screen.dart` with two new `TrainingGameType` enum values. No new screen, no new route handler, no new repository, no new state. We reuse the existing question model (`QuizQuestion`), the existing choice UI (`_ChoiceInput` → `WordChoiceButton`), the existing audio primitive (`PronunciationControls`), the existing `_blankExample` helper, the existing insufficient-source empty state, the existing finish/XP/result flow, and existing ARB strings wherever they exist.

Goal: two fully playable drills that feel native to the engine, with the smallest possible diff (YAGNI / ponytail — reuse, don't rebuild).

---

## 2. Scope

### In scope
- Add `passageCloze('passage-cloze', AppIcons.article)` and `listening('listening', AppIcons.hearing)` to `enum TrainingGameType`.
- Handle both new values in **every** exhaustive `switch` over `TrainingGameType` in `training_session_screen.dart` (Dart will not compile otherwise — see §4).
- **Passage Cloze:** multiple-choice; prompt = example sentence with the target word blanked (`_blankExample`); answer = target word; options = distractor words. `ReviewDimension.context`.
- **Listening Sprint:** multiple-choice; prompt plays the word's audio via `PronunciationControls`; answer = word meaning; options = distractor meanings (same shape as `wordRush`/`meaningChoice`). `ReviewDimension.listening`.
- Wire `training_screen.dart`: replace `onTap: null` on the two rows with `context.push('/training/passage-cloze')` and `context.push('/training/listening')`.
- New/reused ARB keys (en/zh/ms) per §6.
- Tests per §7.

### Out of scope
- The route `/training/:game` (`core/routing/app_router.dart` ~line 288) already dispatches by `gameId` to `TrainingSessionScreen` and resolves it via `TrainingGameType.fromId`. **No router change is required.** Once the enum gains the two ids, the existing route serves them.
- AI passage generation. ARB copy `trainingPassageClozeDesc` ("…AI passage…") and `trainingPassageClozeSource` ("Today's words + AI passage") describe a future AI-authored long passage. This spec deliberately implements a **single-sentence cloze** from `word.exampleSentence` instead. Do not build an AI passage pipeline here.
- The **Confusion / Sentence AI tools** (易混词辨析 / AI 造句) are a *separate* feature and are explicitly NOT part of this work. `QuizQuestionType` already declares `confusableChoice`, `collocationChoice`, `derivativeChoice`, `sentenceCloze`, `listeningWordChoice`, `listeningMeaningChoice` — we reuse only the ones that map cleanly (see §5); we do not build the confusion/AI-sentence drills.
- No backend changes. `ExerciseRecord` is persisted via the existing `completeTraining` path with `gameId = type.id` and an existing `ReviewDimension` value — no new dimension, no schema change.

---

## 3. Files to change

| File | Change |
|---|---|
| `linguaquest/lib/features/training/training_session_screen.dart` | Add 2 enum values; extend 8 switch sites (§4); add 2 question builders (§5). |
| `linguaquest/lib/features/training/training_screen.dart` | Replace `onTap: null` on the two locked rows (lines 86, 92) with `context.push(...)`; the "Coming Soon" pill auto-disappears because `_TrainingGameRow` keys off `onTap == null`. |
| `linguaquest/lib/l10n/app_en.arb` | Add new keys (§6). |
| `linguaquest/lib/l10n/app_zh.arb` | Add new keys (§6). |
| `linguaquest/lib/l10n/app_ms.arb` | Add new keys (§6). |
| `linguaquest/lib/l10n/generated/*` | Regenerate via `flutter gen-l10n` and commit. |
| `linguaquest/test/...` (new test file) | Per §7. |

No changes to: `app_router.dart`, `lesson.dart`, `pronunciation_controls.dart`, `app_controller.dart`, `app_state.dart`, any repository, any server file.

---

## 4. Per-switch-arm change list (exhaustive)

Dart's exhaustive `switch` over an enum forces every site to handle the two new values; the compiler is the safety net. Every site below currently enumerates exactly `{ wordRush, survival, spelling }`. Each must gain `passageCloze` and `listening` arms.

1. **`enum TrainingGameType` declaration (lines 27–30).** Add:
   - `passageCloze('passage-cloze', AppIcons.article),`
   - `listening('listening', AppIcons.hearing);`
   (Move the trailing `;` to the last value.)

2. **`title(AppLocalizations l10n)` (lines 44–48).** Add:
   - `passageCloze => l10n.trainingPassageCloze`
   - `listening => l10n.trainingListening`
   (Both keys already exist — `app_en.arb` lines 417, 420.)

3. **`_ensureQuestions` — `minimumWords` (line 294).** Currently `spelling ? 1 : 3`. Both new games are multiple-choice and need distractors, so keep the `: 3` default (i.e. no change needed — both fall into the `else 3` branch). Add an inline comment noting that passageCloze/listening intentionally use the 3-distractor minimum. The `wordRush`-only fallback to `state.trainingWords` (lines 295–299) stays `wordRush`-specific; do not extend it.

4. **`_sourceWordsForGame` — `switch (game)` (lines 344–349).** Add:
   - `passageCloze =>` words that **have a non-empty `exampleSentence`** (see §5.1 for the exact source expression).
   - `listening =>` words preferring non-empty `audioUrl`, else fall back to the same pool (see §5.2). The trailing `source.isEmpty ? state.trainingWords : source` guard (line 350) already covers the empty case for both.

5. **`_buildQuestions` — `count` switch (lines 369–373).** Add a fixed count for each, mirroring `survival`/`spelling` (which use constants). Add two constants near `_spellingQuestionCount`/`_survivalQuestionCount`:
   - `static const _passageClozeQuestionCount = 12;`
   - `static const _listeningQuestionCount = 12;`
   Then: `passageCloze => _passageClozeQuestionCount`, `listening => _listeningQuestionCount`.

6. **`_questionFor` — `switch (game)` (lines 396–479).** Add a `case TrainingGameType.passageCloze:` and `case TrainingGameType.listening:` returning the `QuizQuestion` shapes in §5.

7. **`_progressFor` — `switch (game)` (lines 614–623).** Both new games are bounded by question count (no timer), so add `passageCloze` and `listening` to the **same group as `survival`/`spelling`**: `(_index + 1) / _questions.length`.

8. **`_advanceAfterFeedback` — `shouldFinish` switch (lines 593–597).** Add `passageCloze => _index >= _questions.length - 1` and `listening => _index >= _questions.length - 1` (same as `survival`/`spelling`).

9. **`_xpFor` — `switch (game)` (lines 654–663).** Add an XP formula for each. Both are recognition-style MCQ; mirror `wordRush` magnitude:
   - `passageCloze => (_correct * 3 + _bestStreak * 2 + accuracyBonus).clamp(0, 80).toInt()`
   - `listening => (_correct * 3 + _bestStreak * 2 + accuracyBonus).clamp(0, 80).toInt()`
   (Exact coefficients are an open decision — see §8; any clamp ≤ 90 is fine.)

10. **`_dimensionFor` (lines 637–648).** This switches on `question.type`, not on `game`, with a `default → meaningRecognition`. Because passageCloze emits `QuizQuestionType.contextChoice`, it already maps to `ReviewDimension.context` (line 645) — no change needed there, but **verify** it lands on that arm. Listening must map to `ReviewDimension.listening`; the cleanest approach is a **game guard at the top of `_dimensionFor`**: `if (game == TrainingGameType.listening) return ReviewDimension.listening;` (parallel to the existing `if (game == TrainingGameType.spelling)` guard at line 638). Passage cloze needs no guard if its question type is `contextChoice`.

11. **Non-switch but game-gated UI — `_TrainingPromptPanel` (lines 801–866).** Currently the audio button only renders for the spelling audio variant (`isAudioSpelling`, lines 817–819, 830–838). Extend the render condition so the Listening game **always** shows `PronunciationControls`. Add a `final isListening = game == TrainingGameType.listening;` and change the guard at line 830 to `if (isAudioSpelling || isListening) ...`. For listening, the prompt `Text(question.prompt)` shows the listening instruction (§6), not the word, so the answer isn't given away.

12. **Choice vs spelling input branch — `build` (lines 207–220).** The `if (game == TrainingGameType.spelling)` picks `_SpellingInput`; the `else` picks `_ChoiceInput`. Both new games are multiple-choice, so they correctly fall into the existing `else` → `_ChoiceInput`. **No change needed**, but confirm neither new value is accidentally added to a spelling branch. The bottom submit button (lines 235–244) is also `spelling`-only — correct as-is for MCQ (choices auto-submit via `onSelected`).

13. **`_promptType` (lines 626–635).** Returns `question.type.name` for non-spelling games — correct for both new games (no change). Listed here only to confirm it is **not** a `switch (game)` and needs no edit.

> Sites that do NOT need edits but are easy to mistake for needing them: `_dimensionFor` passage-cloze arm (type-driven), the input branch, the submit button, `_promptType`, `app_router.dart`. They are called out so the implementer doesn't add redundant arms.

---

## 5. Question-generation design

Both produce standard `QuizQuestion` objects consumed by `_ChoiceInput`. Reuse the existing `_options({answer, values, offset})` helper (lines 482–507) — it dedupes case-insensitively, puts the answer first, and fills up to 4 from the pool. `WordChoiceButton` shuffles/positions are derived from option order; matching follows existing engine behavior (no change).

### 5.1 Passage Cloze
- **Source words** (`_sourceWordsForGame`): start from the same learned/current-book/weak/due pools the other games use, then **filter to words with a non-empty `exampleSentence`**. Concretely:
  ```
  passageCloze => [
    ...currentBookWords,
    ...learnedWords,
    ...weakWords,
  ].where((w) => w.exampleSentence.trim().isNotEmpty).toList()
  ```
  (Reuse the locals `currentBookWords`, `learnedWords`, `weakWords` already computed at the top of `_sourceWordsForGame`, lines 332–340.) If the filtered list is empty, the existing `source.isEmpty ? state.trainingWords : source` fallback (line 350) applies; those fallback words may lack examples — see §9 risk.
- **Question shape** (`_questionFor`, new `case passageCloze`):
  - `type: QuizQuestionType.contextChoice` (so `_dimensionFor` yields `ReviewDimension.context` with no extra guard).
  - `prompt:` the cloze sentence directly from `_blankExample(word, localeCode)` (lines 509–516) — it replaces the first case-insensitive occurrence of the target word with `____`. Per the approved decision, **use `_blankExample` output directly as the prompt** (no wrapping ARB template needed). If a wrapping label is desired, use the new `trainingPromptPassageCloze` key (§6, optional) — default is raw `_blankExample`.
  - `answer: word.word`.
  - `options: _options(answer: word.word, values: words.map((w) => w.word), offset: index)`.
  - `explanation: l10n.trainingExplanationMeaningChoice(word.word, word.primaryDefinitionFor(localeCode))` — reuse existing key (line 446), or the new `trainingExplanationPassageCloze` if a sentence-aware explanation is wanted (§6, optional).

### 5.2 Listening Sprint
- **Source words** (`_sourceWordsForGame`): prefer words with audio, fall back to the general pool:
  ```
  listening => () {
    final pool = [...currentBookWords, ...learnedWords, ...weakWords, ...dueWords];
    final withAudio = pool.where((w) => w.audioUrl.trim().isNotEmpty).toList();
    return withAudio.length >= 3 ? withAudio : pool;
  }()
  ```
  `Word.audioUrl` is `audioUSUrl.isNotEmpty ? audioUSUrl : audioUKUrl` (lesson.dart line 107). If audio is empty, `PronunciationControls` falls back to TTS/announcement (its `else` branch, lines 182–192) — playable but degraded (see §9 risk).
- **Question shape** (`_questionFor`, new `case listening`):
  - `type: QuizQuestionType.meaningChoice` (matches the `wordRush` meaning-choice family; `_dimensionFor` is overridden to `listening` by the §4.10 game guard).
  - `prompt: l10n.trainingPromptListening` — a NEW instruction string ("Listen, then pick the meaning"; §6). The prompt must **not** contain the word or meaning (that's the whole challenge); audio carries the stimulus.
  - `answer: word.primaryDefinitionFor(localeCode)`.
  - `options: _options(answer: wordMeaning, values: words.map((w) => w.primaryDefinitionFor(localeCode)), offset: index)`.
  - `explanation: l10n.trainingExplanationMeaningChoice(word.word, wordMeaning)` — reuse existing key (line 446).
- **Audio playback:** `_TrainingPromptPanel` renders `PronunciationControls(word: question.word.word, audioUKUrl: question.word.audioUKUrl, audioUSUrl: question.word.audioUSUrl, compact: true)` whenever `isListening` (§4.11). Pass the URL fields so real audio plays (the existing spelling-audio call at line 833 omits URLs and relies on TTS — for listening we should pass URLs).

---

## 6. l10n key plan

### Reused (already present — DO NOT re-add)
| Key | Line in `app_en.arb` | Used for |
|---|---|---|
| `trainingPassageCloze` | 417 | `title()` + row label |
| `trainingListening` | 420 | `title()` + row label |
| `trainingExplanationMeaningChoice` | 446 | explanation for both new games |
| `trainingPromptContextChoice` | 444 | (reference; not strictly needed since cloze uses `_blankExample` raw) |
| `trainingPromptAudioSpelling` | 448 | (reference pattern for the listening prompt copy) |
| `trainingComingSoon`, `trainingSourceInsufficientTitle/Subtitle` | 408/430/431 | unchanged engine plumbing |

The descriptive keys `trainingPassageClozeDesc` (418), `trainingPassageClozeSource` (419), `trainingListeningDesc` (421), `trainingListeningSource` (422) already exist but are **not referenced by the current row UI** (the row shows only title + pill). They remain available for a future detail screen; no new wiring required.

### New keys (i18n is UNFROZEN — add to en/zh/ms, then `flutter gen-l10n`)
Exactly **one required** new key, plus **two optional**:

| Key | Required? | en value (proposed) | Notes |
|---|---|---|---|
| `trainingPromptListening` | **Required** | `"Listen to the audio, then choose the meaning."` | No-arg string. The listening prompt (no word/meaning leaked). |
| `trainingPromptPassageCloze` | Optional | `"Fill the blank: {example}"` | Only if we want a labeled wrapper instead of raw `_blankExample`. Default design uses raw `_blankExample`, so this is **not** added unless §8 decides otherwise. |
| `trainingExplanationPassageCloze` | Optional | `"\"{word}\" fits here: {example}"` | Only if a sentence-aware explanation is preferred over reusing `trainingExplanationMeaningChoice`. Default reuses the existing key, so **not** added unless §8 decides otherwise. |

**Net new keys in the default (lean) plan: 1** — `trainingPromptListening`. zh/ms translations to be filled by the implementer (placeholder-free, since it takes no args).

---

## 7. Testing approach

New widget/unit test file: `linguaquest/test/features/training/training_session_cloze_listening_test.dart` (follow conventions of any existing `test/features/training/*` or the spaced-repetition test).

For **each** new game (`passage-cloze`, `listening`):
1. Pump `TrainingSessionScreen(gameId: <id>)` inside a `ProviderScope` whose `appControllerProvider` is seeded (override or a test `AppState`) with ≥ 4 distinct words that **have example sentences** (for cloze) / **have `audioUrl`** (for listening), each with distinct meanings — enough to clear the `minimumWords = 3` gate and to fill 4 options.
2. Assert **question shape**:
   - Cloze: the visible prompt contains `____` (blank present) and the option list contains the target word; question `type` is `contextChoice`; dimension resolves to `context`.
   - Listening: a `PronunciationControls` widget is present (find by type / by the `pronunciation-*` key); the prompt text equals `trainingPromptListening` and does **not** contain the answer; question `type` is `meaningChoice`; dimension resolves to `listening`.
3. Assert **one correct answer advances**: tap the correct `WordChoiceButton`, pump past `_feedbackDuration` (520ms) where the game auto-advances, and assert progress/index moved (or, for the choice games, that feedback shows correct and the next question renders). Note these MCQ games auto-advance on selection like `survival`; no submit button.
4. Assert **one wrong answer is handled**: on a fresh question, tap a wrong option, assert the correct option is highlighted (`ChoiceState.correct`) and a mistake is recorded / the session does not crash, then advances.
5. **Insufficient-source empty state:** seed < 3 distinct eligible words and assert the `trainingSourceInsufficientTitle` empty state renders (engine already handles this at lines 138–159).

Also extend (if one exists) the `TrainingGameType` enumeration test to assert `fromId('passage-cloze')` and `fromId('listening')` resolve, and that every value's `title()` returns non-empty.

Verification commands (must show passing output before claiming done):
```
cd linguaquest
flutter gen-l10n
flutter analyze
flutter test test/features/training/training_session_cloze_listening_test.dart
flutter test
```

---

## 8. Open decisions

1. **XP coefficients** for the two new games (§4.9). Proposed `_correct*3 + _bestStreak*2 + accuracyBonus`, clamped ≤ 80. Confirm or tune.
2. **Question counts** (§4.5): proposed 12 each. Confirm (survival is 18, spelling is 9).
3. **Cloze prompt presentation:** raw `_blankExample` output (default, 0 new keys) vs. wrapped `trainingPromptPassageCloze` (1 extra key). Default = raw.
4. **Cloze explanation:** reuse `trainingExplanationMeaningChoice` (default, 0 new keys) vs. new sentence-aware `trainingExplanationPassageCloze`. Default = reuse.
5. **Listening source priority order** (§5.2): is `currentBook → learned → weak → due` the right preference, and is the "≥3 with audio else full pool" threshold acceptable?
6. **Cloze blank robustness:** `_blankExample` replaces only the first case-insensitive *substring* match of `word.word`. For inflected forms (the sentence has "running", the word is "run") it won't blank, leaving the answer visible in the sentence. Accept as-is (matches current spelling drill behavior) or add stemming? Proposed: accept as-is (YAGNI).

---

## 9. Risk notes

- **Words lacking example sentences (Cloze):** the source filter requires non-empty `exampleSentence`, but the `source.isEmpty → state.trainingWords` fallback (line 350) can reintroduce example-less words. For those, `_blankExample` returns `"____ (meaning)"` (lines 512–514) — the meaning is shown in parentheses, which **gives the answer away in the prompt** while options are still words. This is a soft-degraded but non-crashing state. Mitigation: prefer building questions only from filtered words; only fall back when the filtered pool is too small to meet `minimumWords`. Document in the empty-state path.
- **Words lacking audio (Listening):** `audioUrl` may be empty; `PronunciationControls` then announces via semantics / shows "Audio unavailable" rather than playing a clip (lines 182–192, 83–93). The drill is still answerable from the on-screen word? No — the listening prompt deliberately hides the word, so with no audio the learner has **no stimulus**. Mitigation: source prefers audio-bearing words (§5.2); when none exist the insufficient-source empty state should ideally trigger. Open decision 5 covers the threshold. Consider, as a follow-up (out of scope), surfacing the phonetic when audio is absent.
- **Inflected-form blanks (Cloze):** see open decision 6 — answer may remain visible in the sentence for irregular/inflected matches.
- **Auto-advance timing in tests:** the choice games advance after `_feedbackDuration` (520ms); tests must `pump` past it. Flaky timing if under-pumped.
- **Compiler-enforced completeness:** the chief safety net is that omitting any of the 8 switch arms in §4 fails compilation. `flutter analyze` will catch a missed site immediately; this is intended.

---
```
TrainingGameType.passageCloze('passage-cloze', AppIcons.article)  // example sentence → blanked, choose the word, dim=context
TrainingGameType.listening('listening', AppIcons.hearing)         // play audio, choose the meaning, dim=listening
```
