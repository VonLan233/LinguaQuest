# Cycle 2 — "Coming Soon / In Planning" Features Design

Date: 2026-06-28
Branch: feat/P2-roadmap
Scope: Implement the four features still shown as placeholders in the UI:
two AI Learn tools (Confusable Words, Sentence Generation & Rewrite) and two
Training drills (Passage Cloze, Listening Sprint). Aligned to `DEVELOPMENT_PLAN`
§5 (AI Learning — wire existing pipeline, no new entries) and §6/§9 (training
breadth + audio).

User decisions (locked):
- Do all four.
- AI features reuse the **existing** AI pipeline (`/ai/<feature>` route →
  `AiPolicyService` → `RemoteAiProvider` DeepSeek / `MockAiProvider` → structured
  JSON; client `askAi` → repo → screen), exactly like `/ai-cloze`.
- Listening Sprint audio uses the **existing** `PronunciationService`.
- Passage Cloze passage is **AI-generated via the existing `/ai/cloze`** endpoint.

No new dependencies. No new abstractions beyond what each feature needs.

---

## Existing patterns being reused (verified)

**AI pipeline (template = "Today's Word Cloze"):**
- Client screen `lib/features/ai_learning/ai_cloze_screen.dart` — input → calls
  `ref.read(appControllerProvider.notifier).askAi(featureType, prompt, targetWord)`
  → renders structured result; loading/error/empty/retry via `AiErrorCard`.
- `lib/core/state/app_controller.dart` `askAi(...)` switches on `featureType` and
  calls the matching repo method.
- `lib/data/repositories/ai_repository.dart` (interface) +
  `api_repositories.dart` (`POST /ai/<feature>`, body `{prompt, targetWord,
  targetLanguage}`, returns `response.data!['data']`) + `mock_repositories.dart`
  (MockAiRepository).
- Route in `lib/core/routing/app_router.dart`.
- Server `server/lib/src/routes.dart` `router.post('/ai/<feature>', ... _handleAiRequest(request, '<feature>', uid))`.
- Server `server/lib/src/ai_policy.dart` — `buildSystemPrompt(feature, language)`
  case + `MockAiProvider.generate()` case. `RemoteAiProvider` needs no per-feature
  code (it sends the system prompt to DeepSeek).
- AI Learn screen `lib/features/ai_learning/ai_learning_screen.dart` — replace
  `status: l10n.aiLearningStatusPlanning` with `onTap: () => context.push('/<route>')`.

**Training drill engine:**
- `lib/features/training/training_screen.dart` — `_TrainingGameRow` with `onTap`
  routes to `/training/<id>`; `onTap: null` = "Coming Soon" pill.
- `lib/features/training/training_session_screen.dart` — `TrainingGameType` enum;
  `_buildQuestions()`/`_questionFor()` produce `List<QuizQuestion>`; answer
  validation (case-insensitive, trimmed), `ExerciseRecord` with a
  `ReviewDimension`, XP, and the `/lesson/<id>/result` flow.
- `QuizQuestion` (`lib/data/models/lesson.dart`): `{type, prompt, answer, options,
  explanation, word}`. `QuizQuestionType` already includes `contextChoice`,
  `listeningWordChoice`, `sentenceCloze`.
- Audio: `lib/core/services/pronunciation_service.dart` `play({word, audioUrl,
  slow, language})` (URL via audioplayers → flutter_tts fallback; language-aware
  zh→zh-CN, ja→ja-JP) and `lib/core/widgets/pronunciation_controls.dart`.

**l10n:** `lib/l10n/app_en.arb` / `app_zh.arb` / `app_ms.arb`. Keys
`aiLearningToolConfusion(Desc)`, `aiLearningToolSentence(Desc)`,
`trainingPassageCloze`, `trainingListening` already exist.

---

## Feature A — Confusable Words (AI Learn)

`featureType: 'confusion'`, route `/ai-confusion`.

- **Client:** `lib/features/ai_learning/ai_confusable_words_screen.dart`
  (`ConsumerStatefulWidget`, modeled on `ai_cloze_screen.dart`). A `TextField`
  for a word/term, an "Analyze" button, then states: empty (prompt to enter a
  word), loading (spinner), error (`AiErrorCard` + retry), result. Result renders
  a list of cards: each pair shows `word` vs `confusedWith`, the `distinction`,
  and `examples`.
- **Request:** `askAi(featureType:'confusion', prompt:'Distinguish words
  confusable with: <input>', targetWord:<input>)`.
- **Response JSON:** `{"pairs":[{"word":string,"confusedWith":string,
  "distinction":string,"examples":[string]}]}`. `word`/`confusedWith`/`examples`
  in the target language; `distinction` in English (matches the cloze
  "explanations in English" convention).
- **Server:** route `POST /ai/confusion`; `buildSystemPrompt` case `'confusion'`
  emitting that exact strict-JSON schema (no markdown/code fences);
  `MockAiProvider.generate()` case `'confusion'` returning a small deterministic
  sample built from `request.targetWord`.
- **Wiring:** `ai_repository.dart` interface method `generateConfusion(...)`;
  `api_repositories.dart` (`POST /ai/confusion`) + `mock_repositories.dart`;
  `app_controller.askAi` `'confusion'` case; route registration; enable the AI
  Learn row; l10n keys for the screen (input hint, button, section labels).

## Feature B — Sentence Generation & Rewrite (AI Learn)

`featureType: 'sentence_gen'`, route `/ai-sentence`.

- **Client:** `lib/features/ai_learning/ai_sentence_gen_screen.dart` (same
  template). A `TextField` (a word to build sentences for, or a sentence to
  rewrite), an "Generate" button, same four states. Result renders two sections:
  generated **sentences** and **rewrites**.
- **Request:** `askAi(featureType:'sentence_gen', prompt:'Generate example
  sentences and rewrites for: <input>', targetWord:<input>)`.
- **Response JSON:** `{"sentences":[{"sentence":string,"translation":string}],
  "rewrites":[{"original":string,"rewritten":string,"note":string}]}`.
  `sentence`/`rewritten` in the target language; `translation`/`note` in English.
- **Server + wiring:** identical structure to Feature A (route `/ai/sentence`,
  `buildSystemPrompt` + `MockAiProvider` cases for `'sentence_gen'`, repo +
  controller + route `/ai-sentence` + enable row + l10n).

## Feature C — Passage Cloze (Training drill)

`TrainingGameType.passageCloze('passage-cloze', AppIcons.article)`,
route `/training/passage-cloze`.

- Reuses the drill engine with an **async question source** (new for this game
  type; all current drills build questions synchronously from local state).
- On entry, `TrainingSessionScreen` (for `passageCloze`) calls the existing
  `/ai/cloze` once via `askAi(featureType:'cloze', prompt:<built from current
  wordbook words>, targetWord:<a current word>)`, showing a loading state. The
  returned `{passage, blanks:[{index,answer,options}]}` is converted into a
  `List<QuizQuestion>` — **one `contextChoice` question per blank**, where the
  prompt is the passage with that blank rendered as `____` (other blanks filled
  with their answers for readability), `options` = `blank.options`, `answer` =
  `blank.answer`, `word` = a best-effort match from the current wordbook (or a
  lightweight synthetic `Word` if no match, so recording still works).
- After questions are built, the **normal flow** handles answering, scoring, XP,
  `ExerciseRecord` (dimension: a reading/cloze dimension consistent with the
  engine), and the result screen.
- **Failure:** if the AI call fails or returns no usable blanks, show an error
  state with retry (reuse `AiErrorCard` styling) and a back action — never a
  blank/broken session.
- **Decomposition:** (1) add the async-question-source path to the engine; (2)
  the AI-blanks → `QuizQuestion` conversion (pure, unit-testable); (3) enable the
  Training row + route + l10n.

## Feature D — Listening Sprint (Training drill)

`TrainingGameType.listeningSprint('listening-sprint', AppIcons.hearing)`,
route `/training/listening-sprint`. Fully local (no AI).

- Questions built from the current wordbook + weak words (same sources the other
  drills use), type `listeningWordChoice`: the prompt panel shows an audio
  **play** button (the word text hidden) wired to `PronunciationService.play(
  word: w.word, audioUrl: w.audioUrl, language: currentLanguage)`; `options` = 4
  candidate words (correct + 3 distractors via the existing `_options` helper);
  `answer` = the spoken word.
- Answer/score/XP via the normal flow; `ExerciseRecord` `dimension:
  ReviewDimension.listening`; XP formula mirrors the existing choice drills.
- **Prompt rendering:** extend the session prompt panel to render the
  listening-play prompt for `listeningWordChoice` (the panel already renders an
  audio control for audio-spelling — reuse that control, hide the answer text).

---

## Testing

- **Server** (`server/test/`): extend `ai_system_prompt_test.dart` with
  `'confusion'` and `'sentence_gen'` cases (asserting the schema/keywords +
  language policy), and `ai_routes_test.dart` (or a focused new test) for the
  `MockAiProvider` output shape of both new feature types.
- **Client AI** (`linguaquest/test/`): extend `ai_learning_test.dart` with
  `MockAiRepository` coverage for `generateConfusion` and the sentence-gen method
  (request passes through, result parses).
- **Training drills** (`linguaquest/test/features/training/` — new): unit-test the
  AI-blanks → `QuizQuestion` conversion for Passage Cloze (blanks map to
  `contextChoice` questions with correct answer/options; passage rendered with the
  active blank), and the Listening Sprint question builder (type
  `listeningWordChoice`, 4 options incl. the answer, answer = the word). Model on
  `hsk1_quiz_test.dart` (answer/prompt invariants, no Chinese leakage in English
  prompts).
- After all tasks: `flutter analyze` + `flutter test` clean; `dart analyze` +
  `dart test` clean.

## Error handling (not optional)

- All four features: trust-boundary input handling (empty/over-long input
  guarded as the existing AI screens do — the AI request layer already enforces a
  prompt length cap server-side); network/AI failures surface a retryable error
  state, never a crash or silent empty success.
- Passage Cloze must degrade gracefully when the AI returns malformed/empty
  blanks (validate before building questions).

## Out of scope

- No changes to the existing four AI tools or three drills beyond enabling the new
  rows.
- No new TTS/cloud integration (Listening Sprint reuses `PronunciationService`).
- Deployment of the new server `/ai/confusion` + `/ai/sentence` routes to the live
  host is a follow-up step (like Cycle 1), gated on explicit approval.

## Plan decomposition (preview)

1. Server: `confusion` + `sentence_gen` prompts + mock + routes (+ tests).
2. Client AI: repo/controller/route/screens for Confusable Words + Sentence Gen
   (+ enable rows, l10n, tests).
3. Listening Sprint drill (enum + builder + prompt rendering + route + tests).
4. Passage Cloze: engine async-question path + AI-blanks→QuizQuestion conversion
   (+ route + tests).
5. l10n sweep (en/zh/ms) + final verification.
