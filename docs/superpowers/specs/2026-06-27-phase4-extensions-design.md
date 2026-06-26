# Phase 4 — Multi-Language Extensions Design Spec

Date: 2026-06-27
Scope: EXTEND existing features to Japanese / per-language. Minimal diffs, reuse-first. No new systems. No SQLite. No redesign.

Phase 4 finishes the DEVELOPMENT_PLAN items the multi-language foundation now enables. Each item is an extension of shipped infrastructure (multilang foundation §2, reading module §P3, achievements §7, AI §5, analytics §6, forum §5/§8). `Word` already carries `kana`/`romaji`/`examLevel`/`phoneticFor(lang)`; `Article` already carries `language`; progress is scoped `<lang>::<bookId>`; state holds `currentLanguage` + `currentWordBookId`.

---

## §9 — Japanese audio (language-aware TTS)

### Problem
`PronunciationService.play()` hard-codes `final language = containsCjkText(trimmed) ? 'zh-CN' : 'en-GB'`. Japanese kanji is CJK and mis-routes to `zh-CN` TTS; kana-only words route to `en-GB`. Audio URLs from JLPT data already pass through; the gap is TTS language selection.

### Minimal change
- `lib/core/services/pronunciation_service.dart`: add optional `String language = ''` to `play(...)`. Resolve a TTS locale: `'ja'`→`'ja-JP'`, `'zh'`→`'zh-CN'`, `''`/unknown → keep current CJK auto-detect fallback. audioUrl-first path unchanged (JLPT URLs win when present).
- `lib/core/widgets/pronunciation_controls.dart`: add optional `String language = ''`; pass into `_service.play(...)`. Widen the single-button branch: show the single Mandarin-style button when `containsCjkText(word) || language == 'ja'` (kana-only words aren't CJK).
- Call sites pass the owning language: `word_detail_screen`, `target_word_detail_screen`, `lesson_preview_screen`, `quiz_session_screen`, `training_session_screen` → `currentLanguage` (or the word's scope language). Reading passes `article.language` (already P3c). AI result audio → `currentLanguage`.

### Test
- Unit: `play(word:'こんにちは', language:'ja')` empty audioUrl → `TtsSink` gets `'ja-JP'`; `'zh'`→`'zh-CN'`; `''` keeps CJK fallback (regression).
- Widget: `PronunciationControls(word:'日本語', language:'ja')` renders one button, not UK/US pair.

### Deferred
Per-accent JP voices, pitch-accent, on-device JP audio packs.

---

## §5 — Multi-language AI Learning (use currentLanguage)

### Problem
`AppController.askAi()` / `reviewWriting()` pass `state.targetLanguage` into AI calls. AI Learning should explain the language being *learned* (zh or ja). `explainParagraph` already uses the article's `language`; the backend accepts `targetLanguage` and has `languageNameFor` covering `ja`.

### Minimal change
- `lib/core/state/app_controller.dart`: in `askAi()` replace the three `targetLanguage: state.targetLanguage` with `state.currentLanguage` (chat, sentence_analysis, cloze); same swap in `reviewWriting()`.
- Confirm server system-prompt builder handles `ja` (it has `languageNameFor`); add a `ja` case if any branch still assumes zh. No new wire fields — only the *value* sent changes.
- AI screens need no API change; optionally show the active language in headers.

### Test
- Controller: stub `aiRepository`, set `currentLanguage='ja'`, call `askAi(featureType:'chat')`, assert repo got `targetLanguage:'ja'`. Repeat cloze/sentence/reviewWriting.
- Backend: prompt-builder test asserting `ja` yields a Japanese system prompt.

### Deferred
Furigana in AI output, JP writing rubrics (keigo), decoupling wire field name.

---

## §6 — Per-language/wordbook analytics scope

### Problem
The analytics report doesn't label which (language, wordbook) scope is shown; reading metrics already come scoped via `readingResultsForScope()`.

### Minimal change
- `lib/features/quests/progress_analytics_screen.dart`: add a scope header chip showing `currentLanguage` + `currentWordBookId` (e.g. "JLPT N5"/"HSK 4") via the wordbook display-name helper from the picker. Ensure `reviewWords`-derived metrics reflect the current scope (filter by `progressScope(currentLanguage, currentWordBookId)` if not already scoped). Reading metrics already scoped.
- Server analytics: optional — only if the snapshot demonstrably mixes languages; prefer client-side scoping.

### Test
- Widget: `currentLanguage='ja'`, `currentWordBookId='jlpt_n5'` → header shows JLPT N5 scope label.

### Deferred
In-analytics scope switcher, cross-scope comparison dashboards.

---

## §10 — Multi-language achievements (Japanese + reading)

### Minimal change
- `server/lib/src/achievement_policy.dart`: add params `bool hasJapaneseStudy=false`, `bool hasReadingComprehension=false`, and two `Achievement`s: `first_japanese_lesson` (unlocked by hasJapaneseStudy), `first_reading` (unlocked by hasReadingComprehension). Mirror the `hasListening`/`firstMapLanguageAt` pattern.
- `server/lib/src/database.dart`: `hasJapaneseStudy(uid)` → `SELECT 1 FROM user_words WHERE uid=@uid AND language='ja' LIMIT 1`; `hasReadingRecord(uid)` → `SELECT 1 FROM exercise_records WHERE uid=@uid AND game_id LIKE 'reading-%' LIMIT 1`.
- `server/lib/src/routes.dart` `/achievements`: compute flags, pass into `evaluate(...)`. Public-profile call keeps defaults.
- Client: add icon mappings for any new `iconKey`.

### Test
- Server unit: `evaluate(hasJapaneseStudy:true)` unlocks `first_japanese_lesson`; `hasReadingComprehension:true` unlocks `first_reading`; both false → locked.

### Deferred
Per-JLPT-level achievements, reading streaks/counts.

---

## §7 — Offline cache status + manual refresh (NO SQLite)

### Minimal change
- `lib/features/profile/data_settings_screen.dart` (or settings): an "Offline content" section: a status row ("Available offline" for current scope, derived from the loaders completing) + a "Refresh content" button.
- A controller method `refreshOfflineContent()` that clears the memoized asset-loader future(s) and re-calls `loadWordBooks()` + article loader, then refreshes the current wordbook/lessons/articles in state. No persistence, no network fetch — reload bundled assets + rebuild in-memory state for the current scope.

### Test
- Controller: `refreshOfflineContent()` re-invokes the loader after cache reset and repopulates the current wordbook/articles.
- Widget: status row shows current scope + enabled Refresh button.

### Deferred
Real download/sync, partial eviction, storage-size reporting.

---

## §8 — Community language/wordbook tags

### Minimal change
- `tag` is already free-form text end-to-end (no schema change).
- `lib/features/discover/forum_compose_screen.dart`: extend `_kTags` with language/wordbook tags, or add a one-tap chip injecting the user's current scope tag (e.g. "JLPT N5" from currentLanguage+currentWordBookId). Keep `tag` a single string.
- `lib/features/discover/community_screen.dart`: add the same to `_kFilterOptions`; extend `_tagLabel`/`_tagVariant`. Filtering already matches by exact `tag`.
- Server: none required.

### Test
- Widget (compose): selecting the current-scope chip posts with `tag` == scope string.
- Widget (community): selecting a "JLPT N5" filter shows only those posts; "All" shows everything.

### Deferred
Structured language+wordbook fields, multi-tag posts, server validation.

---

## Ordered task list
- **P4a — §9 Japanese audio**: `pronunciation_service.dart` + `pronunciation_controls.dart` add `language`; wire call sites + reading + AI result.
- **P4b — §5 AI currentLanguage**: swap `targetLanguage`→`currentLanguage` in `askAi`/`reviewWriting`; verify server `ja` branch.
- **P4c — §10 achievements**: server policy + 2 db queries + `/achievements` wiring + client icon mapping.
- **P4d — §6 analytics scope**: scope header + scoped metrics.
- **P4e — §7 offline status/refresh**: `refreshOfflineContent()` + Data/Settings UI.
- **P4f — §8 community tags**: extend tag set + filter + label/variant.

Group A (Flutter-only): P4a, P4b, P4d, P4e, P4f. Group B (server+client): P4c.

## Top risks / open decisions
1. §9 kana-only words fail CJK detection — gate the single-button + `ja-JP` path on explicit `language=='ja'`, not auto-detect; keep CJK fallback only for empty-language default.
2. §6 scope source of truth — verify whether the analytics snapshot is already scoped vs global; prefer client-side filtering over a server param.
3. §10 `first_reading` relies on the `game_id LIKE 'reading-%'` convention reaching `exercise_records` server-side — confirm reading sessions sync; prefer the existing convention over a new `dimension`.
