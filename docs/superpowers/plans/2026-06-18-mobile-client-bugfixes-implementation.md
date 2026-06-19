# Mobile Client Bugfixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the client-side bugfix spec in `docs/superpowers/specs/2026-06-18-mobile-client-bugfixes-design.md` with TDD and atomic commits.

**Architecture:** Keep backend push/reminder work out of scope. Add small client helpers for localized labels, bounded compact text, wordbook progress, and mixed-study draft persistence. Update affected screens to consume those helpers rather than duplicating layout logic.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, SharedPreferences, Flutter gen-l10n, Flutter widget tests.

---

## File Map

- Modify `linguaquest/lib/l10n/app_en.arb`, `app_zh.arb`, `app_ms.arb`: short labels and localized default display name.
- Regenerate `linguaquest/lib/l10n/generated/*` with `flutter gen-l10n`.
- Modify `linguaquest/lib/core/utils/ui_labels.dart`: default username display helper and compact wordbook-title helpers.
- Modify `linguaquest/lib/core/widgets/app_button.dart`, `app_pill.dart`, `stat_tile.dart`: bounded compact text.
- Modify `linguaquest/lib/features/home/home_screen.dart`: localized short action labels.
- Modify `linguaquest/lib/features/wordbook/wordbook_screen.dart`: user-word progress and Chinese title wrapping.
- Modify `linguaquest/lib/features/profile/study_plan_settings_screen.dart`: wordbook cover selector and input-only time picker wrapper.
- Modify `linguaquest/lib/features/training/training_screen.dart`: overflow-safe light/dark cards and short readiness labels.
- Modify `linguaquest/lib/features/training/training_session_screen.dart`: localized training prompt/explanation generation.
- Modify `linguaquest/lib/features/ai_learning/ai_learning_screen.dart`: training-style disabled AI entries.
- Create `linguaquest/lib/data/models/study_session_draft.dart`: mixed-study draft serialization.
- Modify `linguaquest/lib/features/study/mixed_study_session_screen.dart`: save/restore local drafts.
- Modify tests in `linguaquest/test/widget_test.dart`, `notification_test.dart`, and widget-specific test files as needed.

## Task 1: Localized Short Labels and Default Name

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb`
- Modify: `linguaquest/lib/l10n/app_zh.arb`
- Modify: `linguaquest/lib/l10n/app_ms.arb`
- Modify: `linguaquest/lib/core/utils/ui_labels.dart`
- Modify: `linguaquest/lib/data/models/user_profile.dart`
- Test: `linguaquest/test/widget_test.dart`

- [ ] **Step 1: Add failing tests**

Add tests asserting:

```dart
test('default user display name localizes untouched defaults', () async {
  final en = await AppLocalizations.delegate.load(const Locale('en'));
  final zh = await AppLocalizations.delegate.load(const Locale('zh'));
  final ms = await AppLocalizations.delegate.load(const Locale('ms'));
  final user = UserProfile.demo();

  expect(displayUserName(user, l10n: en), 'Explorer');
  expect(displayUserName(user, l10n: zh), '探索者');
  expect(displayUserName(user, l10n: ms), isNot('学习者'));
});

test('custom user display name is preserved', () async {
  final en = await AppLocalizations.delegate.load(const Locale('en'));
  final user = UserProfile.demo().copyWith(name: 'Ava');

  expect(displayUserName(user, l10n: en), 'Ava');
});
```

- [ ] **Step 2: Verify red**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "default user display name localizes untouched defaults"`

Expected: FAIL because `displayUserName` is not defined or still returns `学习者`.

- [ ] **Step 3: Implement**

Add ARB keys:

```json
"homeStartLearning": "Start",
"homeReviewOnly": "Review",
"profileLearner": "Explorer"
```

```json
"homeStartLearning": "开始",
"homeReviewOnly": "复习",
"profileLearner": "探索者"
```

```json
"homeStartLearning": "Mula",
"homeReviewOnly": "Ulang Kaji",
"profileLearner": "Penjelajah"
```

Update `UserProfile.demo().name` to `Explorer`. Add `displayUserName(UserProfile? user, {required AppLocalizations l10n})` in `ui_labels.dart`, treating empty, `学习者`, `Learner`, `Explorer`, and `Pelajar` as untouched defaults.

- [ ] **Step 4: Regenerate and verify green**

Run: `cd linguaquest && flutter gen-l10n && flutter test test/widget_test.dart --plain-name "default user display name localizes untouched defaults" --plain-name "custom user display name is preserved"`

Expected: PASS for both tests.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/l10n linguaquest/lib/core/utils/ui_labels.dart linguaquest/lib/data/models/user_profile.dart linguaquest/test/widget_test.dart
git commit -m "fix(i18n): localize compact actions and default name"
```

## Task 2: Shared Overflow Guards and Home Actions

**Files:**
- Modify: `linguaquest/lib/core/widgets/app_button.dart`
- Modify: `linguaquest/lib/core/widgets/app_pill.dart`
- Modify: `linguaquest/lib/core/widgets/stat_tile.dart`
- Modify: `linguaquest/lib/features/home/home_screen.dart`
- Test: `linguaquest/test/core/widgets/app_button_test.dart`
- Test: `linguaquest/test/core/widgets/app_pill_test.dart`
- Test: `linguaquest/test/core/widgets/stat_tile_test.dart`
- Test: `linguaquest/test/widget_test.dart`

- [ ] **Step 1: Add failing tests**

Add narrow-width widget tests for short localized home buttons and compact widgets under text scale 1.6. Use `tester.takeException()` and expect null after pumping.

- [ ] **Step 2: Verify red**

Run: `cd linguaquest && flutter test test/core/widgets/app_button_test.dart test/core/widgets/app_pill_test.dart test/core/widgets/stat_tile_test.dart test/widget_test.dart --plain-name "does not overflow"`

Expected: at least one FAIL or overflow exception before layout guards.

- [ ] **Step 3: Implement**

In `AppPrimaryButton` and `AppSecondaryButton`, use an internal `Row` with fixed icon, `Flexible` text, `maxLines: 1`, and `TextOverflow.ellipsis`. In `AppPill`, bound label text similarly. In `StatTile`, add compact constructor args or a compact mode used by training readiness cards. In home, keep labels from `l10n.homeStartLearning` and `l10n.homeReviewOnly`.

- [ ] **Step 4: Verify green**

Run: `cd linguaquest && flutter test test/core/widgets/app_button_test.dart test/core/widgets/app_pill_test.dart test/core/widgets/stat_tile_test.dart test/widget_test.dart --plain-name "does not overflow"`

Expected: PASS, no overflow exception.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/core/widgets/app_button.dart linguaquest/lib/core/widgets/app_pill.dart linguaquest/lib/core/widgets/stat_tile.dart linguaquest/lib/features/home/home_screen.dart linguaquest/test/core/widgets/app_button_test.dart linguaquest/test/core/widgets/app_pill_test.dart linguaquest/test/core/widgets/stat_tile_test.dart linguaquest/test/widget_test.dart
git commit -m "fix(ui): bound compact action text"
```

## Task 3: Wordbook Progress and Study Plan Selector

**Files:**
- Modify: `linguaquest/lib/features/wordbook/wordbook_screen.dart`
- Modify: `linguaquest/lib/features/profile/study_plan_settings_screen.dart`
- Modify: `linguaquest/lib/core/utils/ui_labels.dart`
- Test: `linguaquest/test/widget_test.dart`

- [ ] **Step 1: Add failing tests**

Add tests verifying the wordbook scroller displays `0 / total` for a fresh user rather than catalog `includedWords / totalWords`, and that study plan selector renders `WordbookCoverCard`-style covers.

- [ ] **Step 2: Verify red**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "wordbook scroller uses user progress" --plain-name "study plan selector renders cover cards"`

Expected: FAIL on current static progress and pill selector.

- [ ] **Step 3: Implement**

Add helpers to compute learned counts from `UserWord` by normalized wordbook id. Use the helper in wordbook hero, scroller, and study-plan selector. Add compact Chinese title rendering for titles ending in `词汇`.

- [ ] **Step 4: Verify green**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "wordbook scroller uses user progress" --plain-name "study plan selector renders cover cards"`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/features/wordbook/wordbook_screen.dart linguaquest/lib/features/profile/study_plan_settings_screen.dart linguaquest/lib/core/utils/ui_labels.dart linguaquest/test/widget_test.dart
git commit -m "fix(wordbook): show user progress in selectors"
```

## Task 4: Training and AI UI/i18n

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb`
- Modify: `linguaquest/lib/l10n/app_zh.arb`
- Modify: `linguaquest/lib/l10n/app_ms.arb`
- Modify: `linguaquest/lib/features/training/training_screen.dart`
- Modify: `linguaquest/lib/features/training/training_session_screen.dart`
- Modify: `linguaquest/lib/features/ai_learning/ai_learning_screen.dart`
- Test: `linguaquest/test/widget_test.dart`

- [ ] **Step 1: Add failing tests**

Add tests verifying training readiness labels are `Review`, `Weak`, `Combo` in English; Training cards do not overflow in light mode; AI Learning shows all tool entries and disabled entries do not navigate; English Campus Sprint prompt contains no Chinese instructional prefix.

- [ ] **Step 2: Verify red**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "training readiness uses compact localized labels" --plain-name "ai learning keeps disabled entries" --plain-name "english training prompt is localized"`

Expected: FAIL before label/card/prompt updates.

- [ ] **Step 3: Implement**

Update ARB labels for `trainingDueWords`, `trainingWeakWords`, and `trainingComboTarget` to short strings. Refactor `_TrainingGameRow` and `_TrainingReadinessLine` to bounded layouts. Refactor AI cards to the same row/card pattern with disabled `onTap` for unavailable features. In `TrainingSessionScreen`, generate prompts/explanations from `AppLocalizations` and `primaryDefinitionFor(localeCode)` instead of using baked Chinese prompt text.

- [ ] **Step 4: Regenerate and verify green**

Run: `cd linguaquest && flutter gen-l10n && flutter test test/widget_test.dart --plain-name "training readiness uses compact localized labels" --plain-name "ai learning keeps disabled entries" --plain-name "english training prompt is localized"`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/l10n linguaquest/lib/features/training/training_screen.dart linguaquest/lib/features/training/training_session_screen.dart linguaquest/lib/features/ai_learning/ai_learning_screen.dart linguaquest/test/widget_test.dart
git commit -m "fix(training): localize prompts and compact cards"
```

## Task 5: OPPO-Safe Time Picker

**Files:**
- Modify: `linguaquest/lib/features/profile/study_plan_settings_screen.dart`
- Test: `linguaquest/test/widget_test.dart`

- [ ] **Step 1: Add failing test**

Add a test for a helper or wrapper asserting reminder time picker configuration uses `TimePickerEntryMode.inputOnly`.

- [ ] **Step 2: Verify red**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "study plan reminder picker uses input only mode"`

Expected: FAIL before wrapper exists.

- [ ] **Step 3: Implement**

Introduce a small wrapper function around `showTimePicker` and call it from `_pickReminderTime`, passing `initialEntryMode: TimePickerEntryMode.inputOnly`.

- [ ] **Step 4: Verify green**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "study plan reminder picker uses input only mode"`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/features/profile/study_plan_settings_screen.dart linguaquest/test/widget_test.dart
git commit -m "fix(plan): use stable reminder time input"
```

## Task 6: Mixed Study Local Draft Resume

**Files:**
- Create: `linguaquest/lib/data/models/study_session_draft.dart`
- Modify: `linguaquest/lib/features/study/mixed_study_session_screen.dart`
- Test: `linguaquest/test/widget_test.dart`

- [ ] **Step 1: Add failing tests**

Add tests for `StudySessionDraft` JSON roundtrip and for mixed study saving progress then reopening to restore completed count/remaining queue.

- [ ] **Step 2: Verify red**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "mixed study restores saved local draft"`

Expected: FAIL because draft persistence is not implemented.

- [ ] **Step 3: Implement**

Create draft model classes for session and queue items. In `MixedStudySessionScreen`, save draft on "Save and leave", restore valid draft during `_initializeQueue`, clear stale drafts, clear draft on successful finish, and clear draft on "Leave without saving".

- [ ] **Step 4: Verify green**

Run: `cd linguaquest && flutter test test/widget_test.dart --plain-name "mixed study restores saved local draft"`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/data/models/study_session_draft.dart linguaquest/lib/features/study/mixed_study_session_screen.dart linguaquest/test/widget_test.dart
git commit -m "fix(study): resume saved mixed sessions"
```

## Task 7: Full Verification and Review Fixes

**Files:**
- Modify only files needed to fix review/verification issues.

- [ ] **Step 1: Run formatting**

Run: `cd linguaquest && dart format lib test`

Expected: formatter completes and prints formatted files or `Changed 0 files`.

- [ ] **Step 2: Run focused tests**

Run: `cd linguaquest && flutter test test/core/widgets/app_button_test.dart test/core/widgets/app_pill_test.dart test/core/widgets/stat_tile_test.dart test/widget_test.dart`

Expected: all tests pass.

- [ ] **Step 3: Run analyzer**

Run: `cd linguaquest && flutter analyze`

Expected: `No issues found!`

- [ ] **Step 4: Review spec compliance**

Read `docs/superpowers/specs/2026-06-18-mobile-client-bugfixes-design.md` and check every bullet against changed files. Fix any missing client requirement.

- [ ] **Step 5: Review code quality**

Read all changed Dart files. Check for duplicated layout logic, hardcoded visible strings, stale drafts not being cleared, and unrelated backend reminder work. Fix issues.

- [ ] **Step 6: Commit final fixes if needed**

If fixes were needed:

```bash
git add linguaquest/lib linguaquest/test
git commit -m "fix(ui): address client bugfix review"
```

Expected: commit succeeds without co-author trailers.
