# Design Spec — Issue #77 §2 "AI Learning": Finish the Integration

- **Date:** 2026-06-26
- **Issue:** GitHub #77, section §2 "AI Learning"
- **Branch base:** `feat/P2-roadmap`
- **Scope class:** Finishing work (no new backend modules; UI integration + light backend verification)
- **Supersedes:** `docs/superpowers/specs/2026-06-25-ai-tooling-cleanup-design.md` (the "unhide working tools" portion of that shelved spec is subsumed here as Decision 1).

---

## 1. Overview

The four AI Learning tools — **Q&A**, **Sentence Analysis**, **Cloze**, **Writing Review** — already call the real backend through `appController.askAi(...)` / `appController.reviewWriting(...)` and render structured results. The work is to **finish** the integration, not to build new capability:

| Issue §2 sub-item | Status today | This spec does |
| --- | --- | --- |
| Real API calls | ✓ already (`askAi`/`reviewWriting` → `aiRepositoryProvider` → `/ai/*`) | Leave intact; verify only |
| Structured result display | ✓ already (`_AiChatResultCard`, `_AnalysisResultCard`, `_ClozeCard`, `_ResultView`) | Leave intact |
| Tools discoverable / not hidden | ✗ 4 working tools wear misleading "Coming Soon"/"In Planning" pills | **Unhide** (Decision 1) |
| Navigation entry points into AI | ✗ only word-detail links today | **Add** lesson-result + mistake-book entries (Decision 2) |
| Loading / error / empty / retry states | partial — loading ✓, error = SnackBar only, no empty/retry | **Add** persistent error card + Retry + empty guidance (Decision 3) |
| Backend param validation + unified errors | ✓ already consistent | **Verify + document** (Decision 4) |

**Grounding (path:line):**
- Hub: `linguaquest/lib/features/ai_learning/ai_learning_screen.dart:85-133` (`_AiToolRow` with `status:` pills; Confusion/Sentence at `:121-133` have **no** `onTap`).
- Screens: `ai_chat_screen.dart:42-63`, `ai_sentence_analysis_screen.dart:32-56`, `ai_cloze_screen.dart:44-71`, `ai_writing_review_screen.dart:45-70` — each does `result.isEmpty → SnackBar`; no persistent error/retry, no empty state.
- Controller: `linguaquest/lib/core/state/app_controller.dart:2426-2483` — `askAi`/`reviewWriting` catch errors → `state.copyWith(errorMessage: _friendlyError(e))` and return `{}`; success path sets `clearError: true`.
- Existing entry pattern: `linguaquest/lib/core/widgets/ai_word_support_link.dart` (pushes `/ai-learning?word=&example=&translation=`).
- Targets for new entries: `linguaquest/lib/features/quiz/lesson_result_screen.dart:294-329` (`_MistakeResultRow`), `linguaquest/lib/features/review/mistake_book_screen.dart:85-126` (`_MistakeWordRow`).
- Routes: `linguaquest/lib/core/routing/app_router.dart:167-187` — `/ai-chat?word=&example=`, `/ai-analysis`, `/ai-cloze?word=`, `/ai-writing-review`.
- Backend: `server/lib/src/routes.dart:983-1025` (`_handleAiRequest`, validates `prompt`), `:1307-1352` (writing-review, validates `prompt`); unified shape `{'error': <code>}` with status map.

---

## 2. Scope

### In scope
1. Remove the misleading status pill from the **4 working tools** so they read as available.
2. Add **two** new navigation entry points into AI Learning (lesson result + mistake book), reusing the `ai_word_support_link` approach.
3. Add **error (persistent card + Retry)** and **empty (pre-request guidance)** interaction states to the 4 AI screens; keep existing loading state.
4. **Verify** the 4 AI endpoints validate required params and return a consistent error JSON; add a guard only where genuinely missing.
5. Add l10n keys (en/zh/ms) for the new UI strings.
6. Widget tests for the three behaviours above.

### Out of scope (YAGNI)
- The **Confusion** and **Sentence** tools (`ai_learning_screen.dart:121-133`, no `onTap`) — genuinely unbuilt; **keep their "In Planning" pill**.
- Any redesign of the AI screens' result layouts, history UI, or the `WritingReviewResult` model.
- New backend endpoints, new AI features, or new repository methods.
- Word-detail AI link — already done; leave it.
- Changing `_friendlyError`, `askAi`/`reviewWriting` signatures, or the `{}`-on-error contract.

---

## 3. Files created / modified

### Modified (Flutter)
| File | Change |
| --- | --- |
| `lib/features/ai_learning/ai_learning_screen.dart` | Unhide 4 working tools (Decision 1). |
| `lib/features/ai_learning/ai_chat_screen.dart` | Add empty + error/retry states (Decision 3). |
| `lib/features/ai_learning/ai_sentence_analysis_screen.dart` | Add empty + error/retry states. |
| `lib/features/ai_learning/ai_cloze_screen.dart` | Add empty + error/retry states. |
| `lib/features/ai_learning/ai_writing_review_screen.dart` | Add error/retry state (input view already serves as "empty"). |
| `lib/features/quiz/lesson_result_screen.dart` | Add "Explain with AI" affordance to `_MistakeResultRow` (Decision 2). |
| `lib/features/review/mistake_book_screen.dart` | Add "Explain with AI" affordance to `_MistakeWordRow` (Decision 2). |
| `lib/l10n/app_en.arb`, `app_zh.arb`, `app_ms.arb` | New keys (Decision 5). |
| `lib/l10n/generated/*` | Regenerated via `flutter gen-l10n` (committed). |

### Created (Flutter — optional shared widget)
| File | Purpose |
| --- | --- |
| `lib/core/widgets/ai_error_card.dart` *(new, optional)* | Reusable `AiErrorCard(message, onRetry)` so the 4 screens don't each hand-roll the error card. If the reviewer prefers inlining, drop this file (see Open Decisions). |

### Modified / verified (backend)
| File | Change |
| --- | --- |
| `server/lib/src/routes.dart` | **Verification only** — `_handleAiRequest` (`:992`) and writing-review (`:1314`) already guard `prompt`. No code change expected unless §6 finds a gap. |

### Tests (created)
| File | Covers |
| --- | --- |
| `linguaquest/test/features/ai_learning/ai_learning_unhide_test.dart` | Decision 1 |
| `linguaquest/test/features/ai_learning/ai_explain_entry_test.dart` | Decision 2 (lesson result + mistake book) |
| `linguaquest/test/features/ai_learning/ai_error_retry_test.dart` | Decision 3 (error card + retry re-invokes) |

---

## 4. Decision 1 — Unhide the 4 working tools

**Problem:** In `ai_learning_screen.dart:85-133`, all six `_AiToolRow`s pass a `status:` string. The pill text is computed in `_AiToolRow.build` (`:166-169`):

```
trailing: AppPill(
  label: enabled ? 'Available' : status,   // enabled == onTap != null
  variant: enabled ? PillVariant.success : PillVariant.neutral,
)
```

The 4 working tools already pass `onTap`, so they **already render the green "Available" pill** — the `status:` values (`aiLearningStatusSoon`/`aiLearningStatusPlanning`) on those rows are *dead but misleading code* that implies "not ready". The real fix is two-fold:

1. **Stop passing a misleading `status` on enabled tools.** Make `_AiToolRow.status` **nullable** (`final String? status;`). Working tools omit it; the "Available" pill is driven purely by `enabled`.
2. **Keep the two unbuilt tools** (Confusion `:121-126`, Sentence `:128-133`) passing `status: l10n.aiLearningStatusPlanning` and **no** `onTap` → they keep the neutral "In Planning" pill.

Also localize the hard-coded `'Available'` string at `:167` to `l10n.aiLearningStatusAvailable` (key already exists per `aiLearningStatusAvailable` family — verify; if absent add it, see §5).

**Result:** Q&A, Sentence Analysis, Cloze, Writing Review show green **Available**; Confusion + Sentence show neutral **In Planning**. No behavioural/onTap change.

---

## 5. Decision 2 — Entry points into AI Learning

Reuse the `ai_word_support_link.dart` philosophy (an unobtrusive affordance that pushes into the AI flow) but target **`/ai-chat?word=<word>`** directly (word explanation), which the route already accepts (`app_router.dart:169-172`, reads `word` query param; `ai_chat_screen.dart:31-33` pre-fills `What does "<word>" mean?`).

### 5a. Lesson result screen — `_MistakeResultRow` (`lesson_result_screen.dart:294-329`)
Add a trailing icon button inside the row's `Row` (after the `Expanded` column), unobtrusive:

- Widget: `IconButton` (or `QuestIconButton` for Cozy Quest consistency) with `AppIcons.autoAwesome`, `tooltip: l10n.aiExplainWithAi`.
- `onPressed: () => context.push('/ai-chat?word=${Uri.encodeComponent(mistake.word.word)}')`.
- The mistake word is `mistake.word.word` (already shown at `:313`).

### 5b. Mistake book screen — `_MistakeWordRow` (`mistake_book_screen.dart:85-126`)
Same affordance, placed next to the existing `AppPill` at `:117-120`:

- `onPressed: () => context.push('/ai-chat?word=${Uri.encodeComponent(mistake.word.word)}')`.
- Word source: `mistake.word.word` (shown at `:105`).
- (Leave `_WeakCustomWordRow` `:128-173` as-is — it already navigates to word detail, which itself carries the AI link.)

**Design notes:** unobtrusive = a small icon button, not a full-width button; do not disturb the existing two-line text layout or the trailing pill. Use `context.push` (not `go`) so back returns to the result/mistake screen.

---

## 6. Decision 3 — Loading / error / empty / retry states

### Where state lives
Each of the 4 screens is already a `ConsumerStatefulWidget` holding `_result` and `_isLoading`. Add a **local** `String? _errorMessage` field plus a stored "last request" closure so Retry can replay it. We use **local** state (not `AppState.errorMessage`) for the persistent card because:
- `AppState.errorMessage` is global/transient and is cleared on the next successful AI call (`app_controller.dart:2456,2477`) — fine for a SnackBar, wrong for a per-screen persistent card that must survive until Retry.
- The screens already read `AppState.errorMessage` *once* after a failed call (e.g. `ai_chat_screen.dart:53`) — keep reading it to populate the **local** `_errorMessage`, then render the local copy.

### State machine per screen
```
EMPTY    : _result == null && _errorMessage == null && !_isLoading   → guidance text
LOADING  : _isLoading                                                 → existing spinner/disabled button
ERROR    : _errorMessage != null                                      → AiErrorCard(message, onRetry)
RESULT   : _result != null                                            → existing result card(s)
```

### Submit handler change (illustrative shape, applied to all 4)
- On submit: `setState(() { _isLoading = true; _result = null; _errorMessage = null; })`.
- After `await askAi(...)` / `reviewWriting(...)`:
  - if result **non-empty**: `_result = ...; _errorMessage = null;`
  - if result **empty**: read `ref.read(appControllerProvider).errorMessage` and store into **local** `_errorMessage` (fallback to `l10n.aiErrorGeneric`). **Replace** the SnackBar with the persistent card (keep an optional SnackBar only if reviewer wants both — default: drop it).
- Store the last invocation params (e.g. `_lastPrompt`, and for writing-review `_lastExamType`) so Retry re-runs with identical input. The text controllers still hold the input, so Retry can simply call the same `_submit()/_generate()` again — **Retry calls the existing submit method**, which re-reads the controller and re-invokes the API. No separate retry code path.

### EMPTY state
Before the first request (`_result == null && _errorMessage == null`), show short guidance under the input card:
- Q&A: `l10n.aiEmptyChat` ("Ask anything about Chinese — meanings, grammar, usage.")
- Sentence Analysis: `l10n.aiEmptyAnalysis`.
- Cloze: `l10n.aiEmptyCloze`.
- Writing Review: the `_InputView` (`ai_writing_review_screen.dart:118`) already is the pre-request state; add one guidance line `l10n.aiEmptyWriting` above the submit button. (No separate empty widget needed there.)
- Reuse `MascotEmptyState` (already imported in `mistake_book_screen.dart:14`) **only** if it fits; otherwise a plain centered `Text` inside an `AppCard` is acceptable and lighter.

### ERROR card — `AiErrorCard` (new optional widget)
`AppCard` containing: a warning icon, the `message`, and an `AppPrimaryButton(label: l10n.commonRetry, onPressed: onRetry)`. `commonRetry` already exists (`app_en.arb:32`, `app_zh.arb:32`, `app_ms.arb:32`). Built from Cozy Quest primitives (`AppCard`, `AppPrimaryButton`), consistent with the rest of the screens.

---

## 7. Decision 4 — Backend verification (light)

**Finding from `server/lib/src/routes.dart`:**

| Endpoint | Handler | Param guard | Error shape |
| --- | --- | --- | --- |
| `POST /ai/chat` (`:1256`) | `_handleAiRequest` (`:983`) | ✓ `prompt.isEmpty → 400` (`:992`) | ✓ `{'error': code}` + status map (`:1003-1011`) |
| `POST /ai/sentence-analysis` (`:1264`) | `_handleAiRequest` | ✓ same | ✓ same |
| `POST /ai/cloze` (`:1272`) | `_handleAiRequest` | ✓ same | ✓ same |
| `POST /ai/writing-review` (`:1307`) | inline | ✓ `prompt.isEmpty → 400` (`:1314`) | ✓ `{'error': code}` + status map (`:1329-1337`) |

**Conclusion:** All four already validate the required `prompt` and return a **consistent** `{'error': <code>}` JSON with an appropriate status (400 for `too_long`/`blocked`/empty-prompt, 429 `rate_limited`, 503 `ai_unavailable`, 422 fallback). **No backend code change is required** — document this and stop. (YAGNI: do **not** add per-feature `targetWord` validation; cloze tolerates an absent `targetWord` server-side, and the app always sends one.) The only action item is to **add a confirming server test** if one is missing (optional; see Open Decisions).

---

## 8. Decision 5 — l10n keys (en / zh / ms)

Add to `app_en.arb` (template), then mirror into `app_zh.arb` and `app_ms.arb`, then run `flutter gen-l10n`. **i18n is UNFROZEN for this issue.** Reused existing keys: `commonRetry`, `aiLearningStatusPlanning`.

| Key | en | zh | ms |
| --- | --- | --- | --- |
| `aiLearningStatusAvailable` | Available | 可用 | Tersedia |
| `aiExplainWithAi` | Explain with AI | 用 AI 讲解 | Jelaskan dengan AI |
| `aiErrorGeneric` | Something went wrong. Please try again. | 出错了，请重试。 | Sesuatu tidak kena. Sila cuba lagi. |
| `aiEmptyChat` | Ask anything about Chinese — meanings, grammar, or usage. | 关于中文的任何问题都可以问——词义、语法或用法。 | Tanya apa sahaja tentang bahasa Cina — maksud, tatabahasa atau penggunaan. |
| `aiEmptyAnalysis` | Paste a Chinese sentence to see its structure broken down. | 粘贴一个中文句子，查看它的结构拆解。 | Tampal ayat bahasa Cina untuk melihat huraian strukturnya. |
| `aiEmptyCloze` | Enter a word to generate a fill-in-the-blank exercise. | 输入一个词，生成填空练习。 | Masukkan perkataan untuk menjana latihan isi tempat kosong. |
| `aiEmptyWriting` | Paste your essay and pick an exam type to get scored feedback. | 粘贴你的作文并选择考试类型，获取评分反馈。 | Tampal karangan anda dan pilih jenis peperiksaan untuk maklum balas bermarkah. |

> Note: `aiLearningStatusAvailable` may already exist (the hub hard-codes `'Available'` at `ai_learning_screen.dart:167`). Verify before adding; if present, reuse it.

---

## 9. Testing approach

All widget tests run in **demo/mock mode** (`AppConstants.apiBaseUrl` empty) and override `aiRepositoryProvider` with a fake where failure simulation is needed.

### (a) `ai_learning_unhide_test.dart` — Decision 1
- Pump `AiLearningScreen` (it reads no router query → empty word path).
- Assert: the localized `aiLearningStatusSoon` text appears **0 times**; the localized `aiLearningStatusAvailable` ("Available") appears for the 4 working tools.
- Assert: `aiLearningStatusPlanning` ("In Planning") still appears exactly **twice** (Confusion + Sentence).

### (b) `ai_explain_entry_test.dart` — Decision 2
- Seed `AppState.lastResult` with a `LessonResult` containing one mistake (word = `"试"`).
- Pump `LessonResultScreen`; find the explain affordance (by tooltip `aiExplainWithAi` / icon), tap it, assert the router navigated to `/ai-chat?word=...` (use a spy `GoRouter` or a `redirect`/observer capturing the location).
- Repeat for `MistakeBookScreen` with a seeded `lastResult.mistakes`.

### (c) `ai_error_retry_test.dart` — Decision 3
- Override `aiRepositoryProvider` with a **fake repo that throws on the first `chat(...)` call and returns a valid map on the second** (counter-based).
- Pump `AiChatScreen`, enter a prompt, tap **Ask**.
  1. First call → controller catches, returns `{}`, sets `errorMessage`; assert the **AiErrorCard** (with `commonRetry` button) is shown and **no** result card.
  2. Tap **Retry** → second call succeeds; assert the error card is gone and `_AiChatResultCard` (answer text) renders.
- Also assert the **EMPTY** guidance (`aiEmptyChat`) shows on first pump before any submit.

**Gate:** `cd linguaquest && flutter analyze && flutter test` must pass; run `flutter gen-l10n` first. Backend: `cd server && dart test` (only if a confirming AI-validation test is added).

---

## 10. Open decisions
1. **Shared `AiErrorCard` widget vs inline** — create `lib/core/widgets/ai_error_card.dart` (recommended, 4 call sites) or inline per screen? Default: shared widget.
2. **Keep the SnackBar too?** Default: replace SnackBar with the persistent card (avoid double-surfacing). Reviewer may keep a transient SnackBar in addition.
3. **Entry affordance widget** — plain `IconButton` vs `QuestIconButton` (Cozy Quest). Default: `QuestIconButton` for visual consistency, falling back to `IconButton` if it crowds the row.
4. **Empty-state visual** — `MascotEmptyState` vs a light `AppCard` + `Text`. Default: light text card on the input screens (mascot may be too heavy mid-form).
5. **Confirming backend test** — add a `dart test` asserting `POST /ai/chat` with empty prompt → 400 `{'error':'prompt is required'}`? Default: yes, cheap, no production code change.

## 11. Risks
- **Router observability in tests** — capturing the pushed location for Decision 2 needs a test `GoRouter` with an observer/redirect; mitigate with a minimal router harness in the test file.
- **`AppState.errorMessage` clobbering** — because it is cleared on the next success, the screen must copy it into local state immediately after a failed call; a delayed read would miss it. Encoded in §6.
- **Cloze `targetWord`** — app always sends it; do not tighten the server to require it (would break nothing now but is out of scope and risks future callers).
- **l10n regeneration drift** — forgetting `flutter gen-l10n` breaks the build; it is the first step of the test gate.
- **Unhide false-confidence** — making tools "Available" assumes the backend is reachable; in demo mode the hub already shows the "demo responses" banner (`ai_learning_screen.dart:34-54`), so this is covered.
