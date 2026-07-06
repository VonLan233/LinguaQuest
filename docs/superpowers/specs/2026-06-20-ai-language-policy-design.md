# AI Output Language Policy + Multi-Language Generalization — Design

**Date:** 2026-06-20
**Status:** Approved (brainstorming complete, pending spec review)
**Author:** Claude (with VonLan233)

## Problem

The app is English-UI for English speakers learning a foreign language (HSK
Chinese today). The AI features (chat, sentence analysis, cloze, writing review)
return **explanations in Chinese** instead of English (see: asking about "卧槽"
returned a Chinese explanation). Explanations should be in English; only the
*learning content* (the Chinese being taught) should be in the target language.

Two coupled issues:
1. **Wrong explanation language.** AI explanatory text comes back in the target
   language instead of English.
2. **Hardcoded to Chinese.** The system prompts say "Chinese-learning
   assistant". The app already has a `targetLanguage` state (default `'zh'`,
   chosen via `target_language_picker.dart`) and intends to support more
   languages (Malay, Spanish, French, Japanese are "coming soon"). The AI must
   be parameterized by the learner's target language, not hardcoded.

## Goal & Scope

Make AI output language correct and language-agnostic:
- **Explanatory fields → English** (the UI language).
- **Learning-content fields → the learner's target language** (driven by
  `AppState.targetLanguage`, currently `'zh'`).
- Generalize the prompts so any future target language works by passing its
  code; no code change needed to add a language name mapping beyond one map.

**In scope:** server AI prompt construction + `AiRequest`; app AI repository +
controller plumbing of `targetLanguage`.

**Out of scope (do NOT touch):** the AI chat/feature **UI screens** (no
redesign — explicitly deferred by the user); JSON response structure / field
names; provider call logic, temperature, retry; the daily-limit / safety policy.

## Per-field language policy

For every feature, explanatory prose is English; content being taught stays in
the target language `{LANG}` (English name resolved from the code).

| Feature | English fields (explanation) | Target-language fields (content) |
|---|---|---|
| `chat` | `answer`, `cautions` | `relatedWords` |
| `sentence_analysis` | `translation`, `vocabularyNotes` | `mainClause`, `clauses`, `modifiers` |
| `cloze` | `explanations` | `passage`, `blanks[].answer`, `blanks[].options` |
| `writing_review` | `mainIssues`, `paragraphSuggestions[].suggestion`, `highScoreExpressions`, `grammarIssues[].rule` | `rewrittenSample` and any quoted student text (kept in the essay's original language) |

## Architecture

### Server: `server/lib/src/ai_policy.dart`

1. **`AiRequest`** gains `final String targetLanguage;` (default `'zh'`).
2. **Code→name map** (module-level const):
   ```dart
   const _languageNames = {
     'zh': 'Chinese', 'ms': 'Malay', 'es': 'Spanish',
     'fr': 'French', 'ja': 'Japanese',
   };
   String languageNameFor(String code) => _languageNames[code] ?? 'Chinese';
   ```
3. **System prompt becomes a builder.** Replace the static `_systemPrompts`
   const map with a function `String buildSystemPrompt(String featureType,
   String languageName)` that injects `languageName` and the per-field language
   rules into each feature's instruction (keeping the existing strict-JSON
   schema text unchanged). Returns `null`/throws `unknown_feature` for unknown
   featureType exactly as today.
4. **`RemoteAiProvider.generate`** resolves
   `languageNameFor(request.targetLanguage)` and builds the system prompt from
   it instead of reading the const map. `MockAiProvider` is unchanged in
   behavior (it ignores the language; still returns its mock JSON).

Example built prompt (chat, zh):
> You are a Chinese-learning assistant for English speakers. Write "answer" and
> "cautions" in English. Keep "relatedWords" in Chinese. Reply ONLY with strict
> JSON: {"answer": string, "cautions": string[], "relatedWords": string[]}. No
> markdown, no code fences.

### Server: `server/lib/src/routes.dart`

`_handleAiRequest` (chat/sentence_analysis/cloze) and the writing-review handler
read `targetLanguage` from the request body (`body['targetLanguage']` as String,
default `'zh'`) and pass it into the constructed `AiRequest`. No other route
logic changes.

### App: repository + controller

- **`AiRepository`** (`linguaquest/lib/data/repositories/ai_repository.dart`):
  the four methods (`chat`, `analyzeStatement`, `generateCloze`,
  `reviewWriting`) gain `required String targetLanguage`.
- **`ApiAiRepository`** (`api_repositories.dart`): include
  `'targetLanguage': targetLanguage` in each AI POST body. (Keeps the 60s
  receiveTimeout from the prior fix.)
- **`MockAiRepository`** (`mock_repositories.dart`): accept the param, ignore it
  (mock output unchanged).
- **`AppController.askAi` / `reviewWriting`** (`app_controller.dart`): pass
  `state.targetLanguage` to the repo calls.
- **UI screens unchanged** — they already call `askAi(...)`; the language is
  injected by the controller.

## Data flow

`AppState.targetLanguage ('zh')` → `AppController.askAi/reviewWriting` →
`AiRepository` method (`targetLanguage`) → `ApiAiRepository` POST body
`targetLanguage` → route reads it → `AiRequest.targetLanguage` →
`languageNameFor(code)` → `buildSystemPrompt(feature, name)` → LLM system
message.

## Backward compatibility

A request without `targetLanguage` defaults to `'zh'` → "Chinese", preserving
today's behavior. Unknown codes fall back to "Chinese". The JSON response
schema is byte-for-byte unchanged, so all existing app parsing and tests hold.

## Error handling

Unchanged. `buildSystemPrompt` returning null / unknown feature maps to the
existing `unknown_feature` error code. Provider failures, retries, and the
daily-limit policy are untouched.

## Testing

**Server:**
- `remote_ai_provider_test.dart`: assert the captured request's system message
  (a) names the resolved language ("Chinese" for `'zh'`) and (b) contains the
  English-explanation instruction; assert unknown code → "Chinese" fallback.
- `buildSystemPrompt` unit tests: each feature includes the language name + the
  correct per-field English/target-language rule; unknown feature → null/throws.
- `ai_routes_test.dart`: regression (MockAiProvider path unaffected); add a case
  that a posted `targetLanguage` reaches the request.

**App:**
- `ApiAiRepository`: assert each AI POST body includes `targetLanguage` (use the
  existing MockClient/dio test pattern).

**Live verification (after deploy):**
- `POST /ai/chat {"prompt":"卧槽是什么意思","targetLanguage":"zh"}` → `answer`
  is English, `relatedWords` are Chinese.

## Files touched

- `server/lib/src/ai_policy.dart` — AiRequest field, language-name map,
  buildSystemPrompt, provider wiring.
- `server/lib/src/routes.dart` — read `targetLanguage` in the AI handlers.
- `server/test/remote_ai_provider_test.dart`, `server/test/ai_routes_test.dart`
  — assertions above (+ a focused buildSystemPrompt test).
- `linguaquest/lib/data/repositories/ai_repository.dart` — interface params.
- `linguaquest/lib/data/repositories/api_repositories.dart` — send
  `targetLanguage`.
- `linguaquest/lib/data/repositories/mock_repositories.dart` — accept param.
- `linguaquest/lib/core/state/app_controller.dart` — pass
  `state.targetLanguage`.
