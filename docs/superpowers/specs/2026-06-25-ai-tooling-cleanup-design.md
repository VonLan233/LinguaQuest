# AI Tooling Cleanup — Design Spec

- **Date:** 2026-06-25
- **Status:** Approved (decisions locked; one open decision flagged below)
- **Scope size:** Smallest of the AI cleanup specs. Net code **deletion**, no new features.

## 1. Overview / Goal

The AI surface in LinguaQuest has drifted out of sync with reality:

1. **Four fully-built, working AI tools are mislabeled as unavailable.** In
   `ai_learning_screen.dart`, AI Q&A, Sentence Analysis, Writing Review, and Cloze
   all have working `onTap` handlers that route to real screens wired to the
   `appControllerProvider` AI calls — yet they render `aiLearningStatusSoon`
   ("Coming Soon") / `aiLearningStatusPlanning` ("In Planning") status pills. To a
   user these read as "not yet built." (Note: the `_AiToolRow` widget *already*
   overrides the pill to a green "Available" success pill when `onTap != null` —
   see lines 158-169 — so the visible label is already correct, but the `status`
   parameter and its `aiLearningStatusSoon` strings are dead weight that imply
   otherwise and feed an unused-translation smell.)

2. **A redundant stub screen exists.** `features/quests/ai_tutor_screen.dart` is a
   display-only stub: it prefills a sample prompt (`aiTutorSamplePrompt`) into a
   `TextField` and shows one static sample-answer card (`aiTutorSampleAnswer`).
   There is **no submit button and no AI call** — it cannot do anything. It is
   reachable from two places, both of which should point at the real AI flow
   instead:
   - The Quest hub "AI Tutor" row (`quest_screen.dart`, route `/ai-tutor`,
     hardcoded `value: '暂未开放'`).
   - The AI Learning hub header icon button (`ai_learning_screen.dart` line 57-59,
     `QuestIconButton` → `context.push('/ai-tutor')`).

**Goal:** make the AI hub honestly reflect that the four tools are ready, fold the
"AI Tutor" entry point into the existing working AI flow, and delete the dead stub
screen + route + now-orphaned strings. Follow YAGNI: remove, don't add.

## 2. Scope

### In scope
- Drop the misleading `status` parameter / `aiLearningStatusSoon` pills from the
  four **built** AI tools in `ai_learning_screen.dart` (or switch them to an
  explicit ready/enabled state).
- Repoint the Quest hub "AI Tutor" row away from `/ai-tutor` to the real AI flow.
- Repoint the AI Learning hub header icon button (also currently `/ai-tutor`) to
  the same real AI flow.
- Replace the hardcoded `'暂未开放'` value on the quest row with a proper localized
  label (reuse an existing key if possible; a new ARB key is permitted since the
  i18n freeze is lifted).
- Delete `features/quests/ai_tutor_screen.dart`, its `GoRoute`, and its import.
- Note the ARB keys that become unused.

### Out of scope
- The two genuinely-unbuilt tools **Confusion** (`aiLearningToolConfusion`) and
  **Sentence** (`aiLearningToolSentence`): they have **no `onTap`** and keep their
  `aiLearningStatusPlanning` pill unchanged. Do not touch them.
- Any change to the four AI tool screens themselves
  (`ai_chat_screen.dart`, `ai_sentence_analysis_screen.dart`,
  `ai_writing_review_screen.dart`, `ai_cloze_screen.dart`) — they are confirmed
  working and stay as-is.
- Any backend / AI-prompt / repository changes.
- Removing the unused ARB keys themselves (optional cleanup, can be a follow-up;
  leaving orphaned keys does not break the build).

## 3. Confirmation of current state (grounded in source)

| Tool (ai_learning_screen.dart) | `onTap` route | Built? | Current `status` pill |
|---|---|---|---|
| AI Q&A (`aiLearningToolAiQA`) | `/ai-chat` | Yes → `AiChatScreen` | `aiLearningStatusSoon` |
| Sentence Analysis (`aiLearningToolAiAnalysis`) | `/ai-analysis` | Yes → `AiSentenceAnalysisScreen` | `aiLearningStatusSoon` |
| Cloze (`aiLearningToolCloze`) | `/ai-cloze` | Yes → `AiClozeScreen` | `aiLearningStatusPlanning` |
| Writing Review (`aiLearningToolAiWriting`) | `/ai-writing-review` | Yes → `AiWritingReviewScreen` | `aiLearningStatusSoon` |
| Confusion (`aiLearningToolConfusion`) | — (none) | **No** | `aiLearningStatusPlanning` (keep) |
| Sentence (`aiLearningToolSentence`) | — (none) | **No** | `aiLearningStatusPlanning` (keep) |

All four built screens are `ConsumerStatefulWidget`s that call
`ref.read(appControllerProvider.notifier).askAi(featureType: ..., prompt: ...)`
(or `WritingReviewResult` equivalent) with loading + error-snackbar handling —
i.e. genuinely functional, not stubs.

`ai_tutor_screen.dart` is the only stub: prefilled `TextField` + static
`AppCard` showing `aiTutorSampleAnswer`. No `askAi`, no button.

`/ai-tutor` is referenced in exactly **three** non-generated places:
`app_router.dart` (route + import), `quest_screen.dart` (row), and
`ai_learning_screen.dart` (header icon button). All three must be handled.

## 4. Files to change

### 4.1 `lib/features/ai_learning/ai_learning_screen.dart`
- **Built tools:** remove the misleading `status` arguments. Two clean options
  (implementer picks one; both satisfy the requirement):
  - **(A, preferred — least churn)** Make `_AiToolRow.status` optional and stop
    passing `aiLearningStatusSoon` for the four built rows. The widget already
    renders the green `'Available'` success pill whenever `onTap != null`, so the
    `status` value is only ever consumed in the disabled branch. Keep passing
    `status: l10n.aiLearningStatusPlanning` for the two unbuilt rows.
  - **(B)** Keep `status` required but pass a neutral ready label for built rows.
    Less clean; (A) is recommended.
- **Header icon button (lines 57-59):** repoint `onPressed:
  () => context.push('/ai-tutor')` to the chosen real target (see §6 Open
  Decision). The `aiLearningTooltip` string is fine and can stay.
- The hardcoded debug/demo banner string at line 46 is unrelated; leave it.

### 4.2 `lib/features/quests/quest_screen.dart`
- The `_QuestRow` for `questAiTutor` (lines 80-86):
  - Change `route: '/ai-tutor'` → the chosen real target (see §6).
  - Replace `value: '暂未开放'` (hardcoded, non-localized) with a localized label.
    **Reuse preferred:** there is no perfectly-fitting existing key, so a small
    new ARB key (e.g. `questAiTutorValue` = "Open" / "前往" / "Buka") is the
    cleanest. If a fitting existing label is found during implementation, prefer
    reuse and skip the new key.

### 4.3 `lib/core/routing/app_router.dart`
- Delete the import `import '../../features/quests/ai_tutor_screen.dart';` (line 34).
- Delete the `GoRoute(path: '/ai-tutor', ...)` block (lines 161-164).
- Leave `/ai-chat`, `/ai-analysis`, `/ai-cloze`, `/ai-writing-review`,
  `/ai-learning` routes untouched.

### 4.4 `lib/features/quests/ai_tutor_screen.dart`
- **Delete the file.**

### 4.5 Localization (`lib/l10n/app_en.arb`, `app_zh.arb`, `app_ms.arb`)
- If a new value label is needed (§4.2), add `questAiTutorValue` to **all three**
  ARB files and run `flutter gen-l10n`, committing the regenerated
  `lib/l10n/generated/` output (per CLAUDE.md convention).
- No other ARB additions.

## 5. Data / navigation flow

Before:
```
Quest hub "AI Tutor" row  ──/ai-tutor──►  AiTutorScreen (stub, dead end)
AI Learning hub header ☰  ──/ai-tutor──►  AiTutorScreen (stub, dead end)
```
After (target = /ai-learning, the recommended option):
```
Quest hub "AI Tutor" row  ──/ai-learning──►  AiLearningScreen (4 working tools)
AI Learning hub header ☰  ──/ai-learning──►  (or drop the button; see §6)
```
The four built tools' own routes are unchanged. No data model changes; `askAi`
flow untouched.

## 6. Open decision (flagged, must resolve before implementation)

**Where do the two `/ai-tutor` entry points repoint?**

- **Recommended: `/ai-learning`** — the AI Learning hub surfaces *all four*
  working tools, so "AI Tutor" naturally becomes "go to the AI hub." Best
  discoverability. Caveat: from the AI Learning hub itself, the header icon button
  pointing back to `/ai-learning` is a no-op/self-link — in that case prefer
  **removing** that header `QuestIconButton` (and its `aiLearningTooltip` usage)
  rather than self-routing.
- **Alternative: `/ai-chat`** — drops the user straight into the AI Q&A screen,
  which is the closest 1:1 behavioral match to what the old "AI Tutor" stub
  pretended to be (ask a question, get an explanation). Keeps the header button
  meaningful (deep-link from the hub into Q&A). Loses exposure of the other three
  tools.

Decision needed from the user. The two entry points may even resolve differently
(e.g. Quest row → `/ai-learning`, AI hub header → `/ai-chat`), but a single
consistent target is simpler and recommended.

## 7. Localization keys affected (become unused)

After deleting the stub + (option A) dropping the built-tool status pills, these
keys are no longer referenced from non-generated Dart and become **orphaned**:

- `aiTutorSamplePrompt`
- `aiTutorSampleAnswer`
- `aiTutorSubtitle`
- `aiTutorInputLabel`
- `aiTutorInstantFeedback`
- `aiLearningStatusSoon` — **only** orphaned if no built row uses it anymore;
  confirmed it is used only by the four built rows today, so it goes unused.
- `aiLearningStatusLater` — already unused today (no Dart reference found);
  noted for awareness, unrelated to this change.

`aiLearningStatusPlanning` stays **in use** (the two unbuilt tools).
`questAiTutor` / `questAiTutorBody` stay **in use** (the quest row title/body).

Orphaned keys may be left in place (harmless) or removed as optional cleanup;
removal across en/zh/ms must be symmetric and followed by `flutter gen-l10n`.

## 8. Testing approach

1. `flutter analyze` — must be clean. Specifically watch for: unused import of the
   deleted screen (must be gone), unused-variable / dead-code lints from the
   removed `status` args.
2. `flutter test` — full suite stays green. No test currently references
   `/ai-tutor`, `AiTutorScreen`, `aiTutorSample*`, `aiTutorInstantFeedback`,
   `aiTutorInputLabel`, `aiTutorSubtitle`, or `aiLearningStatusSoon` (grep of
   `test/` returned no matches), so deletions should not break tests.
3. `flutter gen-l10n` — only if a new ARB key was added; regenerate and commit
   `lib/l10n/generated/`.
4. **Dangling-reference check (manual/grep):** after the change,
   `grep -rn "ai-tutor\|AiTutorScreen" lib test` must return **zero** non-historical
   hits. Confirm both `/ai-tutor` push sites were repointed.
5. Smoke (optional, demo mode): from Quest hub tap "AI Tutor" → lands on the
   chosen real AI screen, not the stub.

## 9. Risks

- **Low overall** — this is a deletion + two route repoints.
- Main risk: missing the **second** `/ai-tutor` reference (the AI Learning hub
  header `QuestIconButton`). It is easy to fix only the Quest row and leave the
  header pointing at a now-deleted route, which would crash on tap. The grep in
  §8.4 is the guard against this.
- Minor: leaving the orphaned ARB keys is cosmetic, not a build breaker; only risk
  is an incomplete/asymmetric removal across locales if cleanup is attempted —
  hence "all three ARB files or none."
