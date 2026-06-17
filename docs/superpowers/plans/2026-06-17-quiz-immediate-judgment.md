# Quiz Immediate-Judgment Flow + Top Notice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rework all answer flows so tapping a choice is judged instantly — correct highlights and auto-advances after a short pause; wrong marks the pick and lets the user re-select — and move in-session "completion/result" prompts from bottom SnackBars to a top-anchored notice that never covers the action area.

**Architecture:** Replace the two-step (select → "检查" → "继续"/"再试一次") state machine with an immediate-judgment machine in each session screen. Choice questions need no buttons; spelling keeps a submit button (text can't be judged on keystroke). First-attempt correctness recording into 错词/SM2/XP is **unchanged** — only the interaction timing changes. A new reusable `showTopNotice()` helper (Overlay-based, drops from the top, auto-dismisses) replaces the bottom in-session SnackBars.

**Tech Stack:** Flutter, Riverpod, flutter_test widget tests. Light mode only.

**Locked decisions (from user):**
- Interaction: **即时判定** — tapping a choice option judges immediately; no "检查" button for choice questions.
- Scoring: **首次答错即计错词** — first wrong attempt records the mistake (错词 + SM2 interval reset + no XP credit for that item) even if a later re-select is correct. **No change to recording logic.**
- Scope: **所有答题流程** — `quiz_session_screen` (lesson + timed), `mixed_study_session_screen`, `training_session_screen`.
- Auto-advance delay: **1500ms** (constant, easy to tune).
- On wrong: do **not** reveal the correct option; mark the wrong pick and allow re-select.
- On correct: highlight correct + show feedback card during the pause, then advance.

---

## File Structure

- `lib/core/widgets/top_notice.dart` — **Create.** `showTopNotice(BuildContext, String message, {IconData? icon, Duration duration})` using an `OverlayEntry` that slides in from the top, sits below the status bar, and auto-dismisses. One responsibility: transient top notice.
- `lib/features/quiz/quiz_session_screen.dart` — **Modify.** Immediate-judgment state machine; remove 检查/继续 buttons for choice; spelling keeps submit; 1500ms auto-advance.
- `lib/features/study/mixed_study_session_screen.dart` — **Modify.** Same immediate-judgment for question steps (knowledge cards keep their continue button); swap in-session bottom SnackBars for `showTopNotice`.
- `lib/features/study/review_study_screen.dart` — **Modify.** Swap the per-answer bottom SnackBars (`reviewStudyReinforced`, remembered/needs-reinforcement messages) for `showTopNotice`.
- `lib/features/training/training_session_screen.dart` — **Modify (verify-first).** Align to immediate-judgment/auto-advance only where it currently uses a select→check step; leave timer/streak mechanics intact.
- `test/widget_test.dart` — **Modify.** Rewrite the quiz flow + feedback-hold tests to the new interaction.
- `test/core/widgets/top_notice_test.dart` — **Create.** Unit/widget test for `showTopNotice`.

---

## Task 1: Top-anchored notice helper

**Files:**
- Create: `lib/core/widgets/top_notice.dart`
- Test: `test/core/widgets/top_notice_test.dart`

- [ ] **Step 1: Write the failing test** — pump a `MaterialApp` with a button that calls `showTopNotice(context, 'done')`; tap it; `pump()`; assert `find.text('done')` is visible; `pump(const Duration(seconds: 3))`; assert it's gone. Also assert the notice renders above mid-screen (its vertical center `dy` < screen height / 2) to prove it's top-anchored.
- [ ] **Step 2: Run it, confirm it fails** (`flutter test test/core/widgets/top_notice_test.dart`) — fails: `showTopNotice` undefined.
- [ ] **Step 3: Implement** `showTopNotice`:
  - Insert an `OverlayEntry` into `Overlay.of(context)`.
  - Position with a `Positioned(top: MediaQuery.paddingOf(context).top + 12, left/right: 16)`.
  - Wrap content in `SafeArea`, a `Material(elevation 0)` + `AppCard`-style container using `AppTokens` radius/colors (porcelain surface, hairline border, single `AppTokens.cardShadow`), optional leading icon.
  - Animate in with a short slide/fade (`AnimationController` owned by a small private `StatefulWidget`, or `TweenAnimationBuilder`), auto-remove after `duration` (default 1800ms). Guard against double-removal.
  - Localization-agnostic: it takes a pre-built `String` (callers pass `l10n.*`).
- [ ] **Step 4: Run test, confirm pass.**
- [ ] **Step 5: `flutter analyze` (clean) + commit** — `git add lib/core/widgets/top_notice.dart test/core/widgets/top_notice_test.dart` then `feat(widgets): add top-anchored in-session notice helper`. **No Co-Authored-By.**

---

## Task 2: quiz_session_screen — immediate judgment

**Files:**
- Modify: `lib/features/quiz/quiz_session_screen.dart`
- Modify: `test/widget_test.dart`

**New state machine (choice questions):**
- Remove the bottom `AppPrimaryButton` for choice questions (keep it ONLY for `QuizQuestionType.spelling` as a submit button labelled `l10n.quizCheck`, then after a correct submit it auto-advances; on wrong submit it re-enables the field).
- Track `String? _selected`, `bool _lockedCorrect`, and `Set<String> _wrongTries` (options tried and found wrong for the current question).
- `_QuestionInput.onSelected(option)` now calls a new `_judge(lesson, question, option)`:
  - If `_lockedCorrect` is true, ignore further taps.
  - Compute `isCorrect = option.toLowerCase() == question.answer.toLowerCase()`.
  - **Recording (unchanged semantics):** on first correct (when `!_mistakeQuestionIds.contains(question.id)`) `_correct++`; on wrong, `if (_mistakeQuestionIds.add(question.id)) _mistakes.add(question)`.
  - If correct: `setState` → `_selected = option; _lockedCorrect = true; _checked = true; _lastCorrect = true;` show `_FeedbackPanel(isCorrect: true)`; start `_autoAdvanceController` (1500ms); on complete call `_advance(lesson)`.
  - If wrong: `setState` → `_selected = option; _wrongTries.add(option); _checked = true; _lastCorrect = false;` show `_FeedbackPanel(isCorrect: false)` (which must NOT reveal the correct answer text — see panel note). Do **not** start the timer. Options remain tappable; tapping another option re-runs `_judge`.
- `_optionState(option)`: `_lockedCorrect && _isCorrectOption(option)` → `correct`; `_wrongTries.contains(option)` → `wrong`; `selected == option && !_lockedCorrect` → `selected`; else `idle`. `WordChoiceButton.onTap` is null only when `_lockedCorrect` (so wrong options stay re-selectable until correct).
- `_advance(lesson)`: if last question, build `LessonResult` (same fields) and `completeLesson(...)` then navigate to result; else `setState` increment `_index`, reset `_selected/_checked/_lastCorrect/_lockedCorrect/_wrongTries/_textController`.
- Replace `_feedbackHoldController`/`_holdFeedback`/`_feedbackReady` with `_autoAdvanceController` (`AnimationController(duration: const Duration(milliseconds: 1500))`), disposed in `dispose`. Add `static const _autoAdvanceDelay = Duration(milliseconds: 1500)`.

**Feedback panel on wrong:** `_FeedbackPanel` currently prints `question.explanation` for both. On wrong, keep a short "再试一次" style hint WITHOUT the correct answer/word reveal (so retry stays meaningful). Add a `bool revealAnswer` (true only when correct) and gate the reinforce block + explanation accordingly; on wrong show only `l10n.quizWrong` + a retry hint (reuse `l10n.quizRetry` or add a key if needed — prefer existing strings, no new translation work).

- [ ] **Step 1:** Rewrite the two quiz tests in `test/widget_test.dart` (the completion-with-retry flow ~lines 1637-1732 and the "feedback stays visible" hold test ~1733-1788) to the new model: tapping the correct `choice-...` key advances after `pump(const Duration(milliseconds: 1500))` with no button tap; tapping a wrong key shows wrong state, does not advance, and a subsequent correct tap advances. Run → confirm they FAIL against current code.
- [ ] **Step 2:** Implement the state machine above.
- [ ] **Step 3:** `flutter test test/widget_test.dart` → the rewritten quiz tests pass.
- [ ] **Step 4:** `flutter analyze` clean; full `flutter test` green.
- [ ] **Step 5:** Commit — `git add lib/features/quiz/quiz_session_screen.dart test/widget_test.dart` → `feat(quiz): judge choice answers instantly with auto-advance and re-select`. **No Co-Authored-By.**

---

## Task 3: mixed_study_session_screen — immediate judgment + top notice

**Files:**
- Modify: `lib/features/study/mixed_study_session_screen.dart`
- Modify: `test/widget_test.dart` (if mixed-study flow is asserted there)

- [ ] **Step 1:** Find any test asserting the mixed-study select→check flow; update to immediate judgment. Write/adjust a failing test for: correct question step auto-advances after 1500ms; wrong non-review step allows re-select.
- [ ] **Step 2:** Apply the same immediate-judgment machine to `_handleQuestionPrimary` question steps (knowledge/understanding cards keep their existing continue button). Preserve `_answerLogs`, `_wrongItemIds`, `_scheduleWrongRecycle`, `_persistReviewAttempt` exactly (recording semantics unchanged). Replace in-session bottom `SnackBar` calls that announce per-answer/daily-completion results with `showTopNotice`. Keep `_showSubmitError` as-is OR also route through `showTopNotice` (error is fine to keep bottom — decide by consistency; prefer top notice for the positive completion prompt the user flagged).
- [ ] **Step 3:** Tests pass.
- [ ] **Step 4:** analyze clean; full suite green.
- [ ] **Step 5:** Commit — `feat(study): instant judgment for mixed-study questions, top notice prompts`. **No Co-Authored-By.**

---

## Task 4: review_study_screen — top notice for per-answer prompts

**Files:**
- Modify: `lib/features/study/review_study_screen.dart`
- Modify: `test/widget_test.dart` (if it asserts these SnackBars)

- [ ] **Step 1:** If a test asserts the remembered/needs-reinforcement/reinforced SnackBar text, update finder expectations (text still shows, now via top notice). Write/adjust failing test.
- [ ] **Step 2:** Replace the three `ScaffoldMessenger...showSnackBar(...)` for `reviewStudyReinforced`, `reviewStudyRememberedMessage`, `reviewStudyNeedsReinforcementMessage` (lines ~178, ~205) with `showTopNotice(context, message, icon: ...)`. Keep the failure/error SnackBar (line ~194) as a bottom SnackBar (errors are not the flagged prompt). This is the screen whose bottom popup covers the action buttons.
- [ ] **Step 3:** Tests pass.
- [ ] **Step 4:** analyze clean; full suite green.
- [ ] **Step 5:** Commit — `feat(review): show per-answer prompts as top notice`. **No Co-Authored-By.**

---

## Task 5: training_session_screen — verify and align

**Files:**
- Modify: `lib/features/training/training_session_screen.dart` (only if it uses a select→check step)

- [ ] **Step 1:** Read the training session answer handling. If `wordRush`/`survival`/`spelling` games already judge on tap and auto-advance (timed games typically do), no behavioral change is needed — note this in the commit/report and STOP for this task. If any game uses a select→check button for choices, apply immediate judgment + auto-advance consistent with Task 2 (preserve timer/streak/scoring).
- [ ] **Step 2:** If changed, write/update a failing test then implement; if unchanged, document why with quoted code.
- [ ] **Step 3:** analyze clean; full suite green.
- [ ] **Step 4:** Commit only if changed — `feat(training): align answer judgment with instant-judgment flow`. **No Co-Authored-By.**

---

## Task 6: Final review + build smoke

- [ ] `flutter analyze` clean.
- [ ] `flutter test` — full suite green; report pass count.
- [ ] `flutter build apk --release` — confirm it builds (report the `✓ Built ...apk` line).
- [ ] Dispatch a final code reviewer over the whole diff (all commits in this plan) for spec compliance + quality. Note: on-device confirmation of the new feel (auto-advance timing, top-notice position, no flicker) is the user's eyeball pass.

---

## Self-Review notes
- **Spelling questions** intentionally retain a submit button — text input cannot be judged per-keystroke. Verified `QuizQuestionType.spelling` exists.
- **Recording unchanged:** every `_correct`/`_mistakes`/`_mistakeQuestionIds` and `completeLesson`/`reviewWord`/`completeMixedStudySession` call is preserved; only the trigger timing moves from button to tap.
- **No new translations:** reuse existing `l10n.*` keys (`quizCorrect`, `quizWrong`, `quizRetry`, `quizReinforce`, review messages). Translation backfill is handled separately by the user's translator.
- **Auto-advance + pumpAndSettle:** an active `AnimationController` makes `pumpAndSettle` wait; tests advance with explicit `pump(Duration(milliseconds: 1500))` to avoid timeouts.
