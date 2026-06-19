# Overall Elegance Pass Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. One atomic commit per screen.

**Goal:** Make the five tab screens (home, training, ai-learning, discover, profile) feel calmer and more intentional — less "mechanical grid" — by applying a consistent spacing rhythm, clearer hierarchy, fewer nested boxes, and tokenized values. Purely visual; no behavior, data, navigation, or string changes.

**Architecture:** Each screen gets a focused refinement following the shared **Elegance Contract** below, plus its own audited shortlist. Guarded by the `test/widget_test.dart` integration suite (asserts by text + nav + some `find.byType(AppCard)`/`InkWell` with `findsWidgets`) and `flutter analyze`.

---

## Elegance Contract (applies to every screen)

1. **Vertical rhythm, not uniformity:** replace blanket `s12`/`s24` gaps with intentional rhythm — **`s32` between major sections**, `s20` for secondary breaks, `s16` within a group, `s12` tight/internal. The hero/first section gets the most air.
2. **One focal point:** strengthen the screen's hero/lead element (the daily-focus ring, the goal header, the profile identity block) via padding/size/weight so it anchors the screen; keep section headers typographically distinct (they already use `titleLarge`/`w800` — don't flatten them).
3. **Fewer boxes:** remove redundant nesting (e.g. an `AppCard` wrapping a second decorated `Container`); prefer whitespace grouping over tabular `Divider`s for *navigation* lists; vary card emphasis by importance rather than stacking identical cards.
4. **Tokenize:** replace hard-coded spacing/sizes (`8`,`10`,`12`,`14`, `fontSize: 13/15`, `radius 12`) with `AppTokens.*` / `theme.textTheme.*`. Keep the `88` bottom-nav inset (it clears the tab bar) unless a token exists.
5. **Trim quiet clutter:** drop a redundant pill/divider ONLY when nothing in `test/widget_test.dart` asserts it.

### HARD CONSTRAINTS (non-negotiable)
- **NO new user-facing strings and NO new ARB/l10n keys** (translation freeze). This explicitly EXCLUDES the audits' "add a 学习资源/应用设置 section header" suggestions unless an existing `l10n.*` key already carries that label. Reuse only existing keys/widgets.
- **NO navigation, data, controller, validator, or route changes.** Same `context.go/push`, same `ref.read(...notifier)` calls, same visible text.
- **Preserve every test finder:** all asserted texts, `find.byKey(ValueKey('profileDashboard'))`, `find.byKey(ValueKey('home...'))`, and any `find.byType(AppCard)`/`InkWell` counts (these use `findsWidgets`, so reducing card count is tolerated, but VERIFY the suite stays green — do not assume).
- **Conservative bias:** when a refinement risks behavior/tests, prefer the smaller spacing/tokenize change over bold restructuring. Run `flutter analyze` + full `flutter test` before committing; fix or revert anything that breaks.
- Atomic commit per screen, explicit `git add` paths, **no `Co-Authored-By`**.

---

## Task 1: Home (`lib/features/home/home_screen.dart`)
Shortlist (low-risk):
- Rhythm: vary the uniform `s12` section gaps — more air after the Daily-Focus hero (`s24`) and before the final/secondary sections (`s20`–`s24`).
- Emphasize the Daily-Focus hero: a touch more padding; bump the progress ring (≈82→96) so visual weight follows importance.
- Shortcuts list: replace tabular `Divider`s with `SizedBox(height: s12)` whitespace (navigation, not data).
- Tokenize hard-coded `10`/`8`/`vertical: 2`/`vertical: 8` and the `spacing: 8` pill wrap.
- KEEP all existing cards (several tests assert `find.byType(AppCard)`); do NOT remove the Learning-Signals card. Verify suite green.

## Task 2: Training hub (`lib/features/training/training_screen.dart`)
Shortlist:
- Rhythm: more air after the goal header (`s24`→`s32`) and after the dense game list (`s24`→`s28`).
- Readiness stats row: replace the thin vertical `_TrainingSignalDivider`s with whitespace (`SizedBox(width: s12)`, `Flexible` tiles).
- Locked game rows: wrap the row content in `Opacity(0.6)` so unavailable games recede. KEEP the "Coming Soon" `AppPill` (don't change pill counts/structure) — opacity alone conveys it.
- Tighten the goal-header top padding; reduce ListView horizontal padding `s20`→`s16` for wider cards.
- Tokenize the `_TrainingSignalDivider` magic numbers.

## Task 3: AI-Learning (`lib/features/ai_learning/ai_learning_screen.dart`)
Shortlist:
- Rhythm: major section break before "Tools" (`s24`/`s12`→`s32`); keep related sub-sections at `s16`.
- Fix the cramped tool-card padding (`symmetric(h: s8, v: s4)` → `h: s16, v: s12`).
- Replace the manual icon `Container` (tinted box) with the existing `IconCueBadge` (`learning_badges.dart`) to cut a nesting layer.
- Hero pill: change `PillVariant.streak`→`PillVariant.primary` (semantics: it's an intro, not a warning).
- Tokenize stray values.

## Task 4: Discover (`lib/features/discover/discover_screen.dart` + `lib/features/discover/shared_widgets.dart`)
Shortlist:
- Rhythm: `s32` between major sections; consistent within-set gaps.
- Reward-task list (`shared_widgets.dart`): the audit flagged the 5 stacked `AppCard`s as the main "mechanical grid." IF the suite stays green (finders use `findsWidgets`), consolidate into ONE `AppCard` with `Divider`s between `RewardTaskRow`s; otherwise just increase `RewardTaskRow` padding (`s12`→`s16`) and inter-element spacing. Verify tests.
- Nav cards: bold the title (`w700`), icon `32`→`36`.
- Tokenize `fontSize: 13`→`theme.textTheme.bodySmall`, `EdgeInsets.all(20)`→`s20`, dialog `SizedBox(6/10)`→`s8/s12`.

## Task 5: Profile (`lib/features/profile/profile_screen.dart`)
Shortlist:
- Remove the hero **double-box**: the `AppCard` wraps a second decorated `Container` (navy) with its own padding (s24 + s20 = 44px). Keep the navy brand-hero look but collapse to a single padding layer (e.g. `AppCard(padding: zero)` + the navy `Container` carrying the padding, OR move the navy fill onto the card) — one layer, not two.
- Rhythm: the seven identical `s24` section gaps → `s32` between major zones (header→stats→progress→settings→assets), `s16`/`s24` within.
- Pill spacing in the hero `s8`→`s12`.
- Settings/asset `Divider`s: thinner `hairline` (`thickness: 0.5`), tokenized `height`.
- Tokenize hard-coded `16`/`14`/`12`, `fontSize: 13/15`, `BorderRadius.circular(12)`→`radiusSmall`, divider `height: 14`→`s16`.
- DO NOT add new section-header label strings (translation freeze). Keep `find.byKey(ValueKey('profileDashboard'))` intact.

## Task 6: Final review + smoke
- `flutter analyze` clean; `flutter test` full suite green (report count); `flutter build apk --release` builds.
- Final code reviewer over the whole elegance diff: confirm (a) no new ARB keys / no new hardcoded user-facing strings, (b) no nav/data/route changes, (c) consistent rhythm applied, (d) all finders intact, (e) no dead code/unused imports.
- On-device eyeball is the user's pass.

## Self-review note
Every task is spacing/hierarchy/tokenize/de-box only. The integration suite + analyze are the safety net; any finder breakage is fixed by syncing (preserving intent) in the same commit, never by deleting a tested assertion.
