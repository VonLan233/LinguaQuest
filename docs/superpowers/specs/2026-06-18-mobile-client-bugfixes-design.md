# Mobile Client Bugfixes Design

Date: 2026-06-18

## Scope

This spec covers the client-side bugfix set for the current Flutter app:

- Wordbook layout and user-progress display.
- Study plan wordbook selector visual parity.
- Mixed study save-and-resume behavior.
- Campus Sprint and training question localization.
- OPPO-safe reminder time picking.
- Training screen overflow and metric label polish.
- AI Learning UI entry restoration.
- Default demo/display name localization.
- Shared text overflow guards for high-risk compact components.

Backend reminder push, scheduled server workers, push-token storage, and remote push delivery are explicitly out of scope for this branch. Those changes should branch off later from this branch once the client fixes are stable.

## Context

The project is a Flutter client under `linguaquest/` with a Dart server under `server/`. Existing data support is stronger than the visible UI suggests:

- `server/lib/src/database.dart` already has `study_plans`, `user_words`, `study_sessions`, `review_events`, and `notifications`.
- `user_words` stores per-user target-word status, mastery, favorite/new-word flags, ignored state, and review scheduling fields.
- `study_sessions` stores completed session records and answer events, but not an in-progress draft.
- The client mock repositories persist `StudyPlan` and `UserWord` records through `SharedPreferences`.

The current client problems are mostly caused by UI using static catalog fields, hardcoded Chinese strings in generated questions, and compact widgets lacking explicit text bounds.

## Decisions

Use a focused client fix, not a broad backend migration.

Use i18n for every visible action label, including short labels such as "开始" and "复习". The Chinese strings should be `开始` and `复习`; English should be `Start` and `Review`; Malay should use existing localization style.

Do not globally cap the whole app's text scale. Instead, add layout bounds to compact high-risk widgets and screens. Global text-scale caps would hurt accessibility and could distort readable content.

For save-and-resume, add a local mixed-study draft first. A server-side draft table can be added later if cross-device resume becomes a product requirement.

For OPPO time picker issues, avoid the problematic Material clock dial by using input-only time picking for the study reminder flow.

## UI Design

### Wordbook Screen

`linguaquest/lib/features/wordbook/wordbook_screen.dart`

The current selected wordbook hero and horizontal book scroller should use user progress, not static catalog progress. Progress is calculated from `state.userWords`:

- Include only records with matching normalized `wordBookId`.
- Count a word as started/learned when status is not `New`, `Previewed`, or `Ignored`, and `isIgnored` is false.
- Total comes from the wordbook catalog `totalWords`.
- Clamp progress to `0.0..1.0`.

The small cover cards should show `learned / total`, not `includedWords / totalWords`.

Chinese wordbook titles/descriptions must avoid splitting "词汇" across lines. For known Chinese titles ending in `词汇`, render the title as two text runs or two lines so `词汇` stays together on the second line. Example: `GRE 高频` on line 1, `词汇` on line 2. The same treatment applies to study-plan wordbook cards where the title appears in compact space.

### Study Plan Selector

`linguaquest/lib/features/profile/study_plan_settings_screen.dart`

Replace the current pill-only `_StudyBookSelector` with a compact cover-card selector aligned with the wordbook screen:

- Use `WordbookCoverCard` for visual parity.
- Show localized title, localized description, and user progress.
- Use the same selected border treatment as the wordbook scroller.
- Keep the selector scrollable horizontally on narrow screens.

The plan hero can keep its summary role, but the selector itself should no longer look like a simplified unrelated component.

### Home Daily Task Console

`linguaquest/lib/features/home/home_screen.dart`

Replace the long primary and secondary labels with short localized labels:

- Chinese: `开始`, `复习`.
- English: `Start`, `Review`.
- Malay: localized short equivalents.

These labels must still be read from `AppLocalizations`; do not hardcode them in widgets.

Both buttons need bounded label containers:

- Equal-width columns when both actions are visible.
- Icon area does not shrink.
- Label area uses `Flexible`.
- One-line label with ellipsis or a small fitted text fallback.
- No horizontal overflow at narrow widths or high text scale.

### Training Screen

`linguaquest/lib/features/training/training_screen.dart`

The training feature cards should be overflow-safe in light mode and dark mode:

- Icon fixed at the leading edge.
- Title and description live in an `Expanded` text column.
- Status pill stays inside the card and is never allowed to push text outside.
- Title is one line with ellipsis.
- Description is at most two lines with ellipsis.
- Locked cards can be dimmed but must keep the same layout bounds.

The bottom readiness/status card should be redesigned as a compact three-column metric row:

- Chinese labels: `复习`, `弱项`, `连击`.
- English labels: `Review`, `Weak`, `Combo`.
- Malay labels: short localized equivalents.
- Each metric has a fixed icon zone and flexible value/label zone.
- Values use tabular/large text; labels are one line and bounded.
- The third metric must not clip on small screens.

### AI Learning Screen

`linguaquest/lib/features/ai_learning/ai_learning_screen.dart`

Restore the AI feature entries as non-navigating UI cards when functionality is not implemented.

The AI page should visually follow the Training screen card language:

- A compact header with the AI title and existing chat icon action.
- Optional word-context card when launched from a word.
- A vertical list of AI feature cards.
- Implemented/navigable entries may have `onTap`.
- Not-yet-implemented entries use `onTap: null`, show a localized status pill, and do not navigate.
- Keep all prior AI feature card names available as entries.

All AI cards need the same overflow rules as Training cards.

### Time Picker

`linguaquest/lib/features/profile/study_plan_settings_screen.dart`

The study-plan reminder time picker should use a stable input-first flow:

- Call `showTimePicker` with `initialEntryMode: TimePickerEntryMode.inputOnly`.
- Keep existing parsing and clamping behavior for invalid stored values.
- Preserve localized Material labels through the app locale.

This avoids the OPPO ROM clock-dial rendering issue shown in the supplied screenshot.

## Learning Resume Design

`linguaquest/lib/features/study/mixed_study_session_screen.dart`

The current "Save and leave" path records a `study_sessions` entry but does not persist the active queue. Re-entering rebuilds a fresh queue from `currentLesson`, which loses the half-finished position.

Add a local draft model for mixed study sessions:

- File: `linguaquest/lib/data/models/study_session_draft.dart`.
- Store key: include user id and mode, for example `linguaquest.study_session_draft.<uid>.<mode>`.
- Fields:
  - `uid`
  - `mode`
  - `lessonId`
  - `startedAt`
  - `savedAt`
  - `completedItems`
  - `correctAnswers`
  - `queue`
  - `answerLogs`
  - `wrongItemIds`
  - `scheduledWrongIds`
  - `confidence`

Draft queue items should serialize enough to rebuild from current app state:

- `wordId`
- `source`
- `step`
- `attempt`
- `affectsSchedule`

On screen initialization:

- Build the normal queue from current app state.
- Load draft for the current user and mode.
- Restore draft only if the lesson id still matches the current lesson and all queued word ids can be resolved.
- If restoration fails, clear the stale draft and start normally.

On "Save and leave":

- Persist the draft before leaving.
- Do not mark the current lesson complete.
- Keep already persisted review attempts as-is.

On finish:

- Call the existing completion path.
- Clear the draft after successful save.

On "Leave without saving":

- Clear the draft for this mode.

This is intentionally local-only. Server-side in-progress sessions can be added in a later branch if required.

## Localization Design

### Training Questions

`linguaquest/lib/data/lesson_factory.dart` currently generates training questions with hardcoded Chinese prompts and explanations. This causes Campus Sprint and related timed-test content to remain Chinese in English mode.

Move user-visible prompt generation to a localized path:

- Prefer rendering prompt/explanation through `AppLocalizations` at session time.
- Use `Word.primaryDefinitionFor(localeCode)` for meaning text.
- Keep answers and options aligned after localization.

The existing `quiz_localization.dart` helper can stay for baked option translation, but new training questions should avoid baking Chinese prompt strings in the first place.

### Default User Name

`linguaquest/lib/data/models/user_profile.dart`

Change the built-in demo/default raw name from `学习者` to a stable sentinel or neutral fallback that can be localized. The visible default should be localized at display time:

- Chinese: `探索者`.
- English: `Explorer`.
- Malay: localized equivalent.

If the user has set a custom name, display the stored name unchanged. Do not translate custom names.

Implement a helper near UI label utilities, for example:

- `displayUserName(UserProfile? user, AppLocalizations l10n)`
- Treat known untouched defaults (`学习者`, `Learner`, `Explorer`, empty demo fallback) as localizable default names.
- Return `user.name` unchanged for any custom name.

Update profile/home surfaces that display the default name to use this helper.

## Shared Overflow Guards

Update compact widgets instead of globally changing text scale:

- `AppPrimaryButton`: wrap icon and text in bounded row; text uses `Flexible`, `maxLines: 1`, and overflow handling.
- `AppSecondaryButton`: same label behavior; avoid `OutlinedButton.icon` if it does not provide enough internal control.
- `AppPill`: add optional `maxWidth` or internally use `Flexible` when constrained by parent; label is one line with ellipsis.
- `StatTile`: support a compact layout for three-column cards; fixed icon size and bounded text column.
- Feature rows/cards in Training and AI: constrain title, description, and status pill.

These guards should be verified under a narrow phone width and increased text scale.

## Tests

Add focused Flutter tests:

- Wordbook scroller uses `UserWord` progress rather than catalog included word counts.
- Study plan selector renders cover-card style wordbook choices.
- Home daily task buttons show localized short labels and do not overflow at narrow width.
- Training readiness card uses localized short labels.
- Training cards with long English text do not overflow in light mode.
- AI Learning shows all feature entries; unavailable entries do not navigate.
- Mixed study save-and-resume restores a saved local draft.
- Default user display name localizes untouched defaults and preserves custom names.
- Study plan reminder time picker uses input-only entry mode through the wrapper where testable.

Run relevant unit/widget tests first, then the broader Flutter test suite if time allows.

## Review Checklist

- All visible text added by this work goes through ARB/i18n.
- No server push/reminder worker work is included.
- No global text scale cap is introduced.
- Existing unrelated worktree changes are not modified.
- Draft resume is local-only and clears on successful completion.
- UI changes cover both light and dark themes where affected.
