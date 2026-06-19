# Material Symbols (Rounded) Icon Migration Plan

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development. Atomic commits.

**Goal:** Replace stock Material `Icons.*` across the app with **Material Symbols, Rounded** (friendly, monochrome, colorable) via a central `AppIcons` indirection, keeping behavior/data/nav/strings/tree-shaking intact and the test suite green.

**Architecture:** `material_symbols_icons` (Apache-2.0, already added — commit `13339c8`) exposes `Symbols.<name>_rounded` constants. A single `lib/core/theme/app_icons.dart` maps every distinct icon to its rounded constant; all call sites use `AppIcons.<name>`. A global `IconThemeData(weight:400, grade:0, opticalSize:24, fill:0)` gives the clean unselected look; selected/active states pass `fill: 1`. No use of `get.dart`/`symbols_map.dart` → tree-shaking preserved.

**Source of truth:** the spike report's complete `Icons.* → Symbols.*_rounded` mapping (147 distinct icons; 3 flagged substitutes: `info_outline→info_rounded`, `person_add_alt_1→person_add_rounded`, `play_circle_outline→play_circle_rounded`). The compiler verifies every constant exists.

---

## Task 1: `AppIcons` indirection + global icon theme
**Files:** Create `lib/core/theme/app_icons.dart`; Modify `lib/core/theme/app_theme.dart`.

- [ ] Create `AppIcons` — a `class AppIcons { AppIcons._(); static const IconData <camelName> = Symbols.<name>_rounded; ... }` with ONE entry per DISTINCT base icon (collapse `_outlined`/`_rounded`/`outline` variants of the same glyph into a single entry; e.g. `Icons.home_outlined` and `Icons.home_rounded` both → `AppIcons.home = Symbols.home_rounded`). camelCase the canonical Material name (`local_fire_department` → `localFireDepartment`, `sports_esports` → `sportsEsports`). Include `starBorder = Symbols.star_border_rounded` (used by `app_button.dart`'s rating default). Import `package:material_symbols_icons/symbols.dart`. Use ONLY static `Symbols.*_rounded` constants (never `get.dart`/`symbols_map.dart`).
- [ ] Run `flutter analyze lib/core/theme/app_icons.dart` — the compiler confirms every `Symbols.*_rounded` constant exists. Fix any typo'd/missing constant against the package (`~/.pub-cache/hosted/pub.dev/material_symbols_icons-*/lib/symbols.dart`).
- [ ] In `app_theme.dart` `_base(...)`, add a global `iconTheme: const IconThemeData(weight: 400, grade: 0, opticalSize: 24, fill: 0)` (both light & dark inherit via `_base`). Keep existing `appBarTheme`/`navigationBarTheme` icon colors; only add the Material-Symbols axis defaults globally.
- [ ] `flutter analyze` clean; `flutter test` green (179). No call sites changed yet, so the suite must be unaffected.
- [ ] Commit: `feat(icons): add AppIcons indirection (Material Symbols Rounded) + global icon theme`. No Co-Authored-By.

## Task 2: Migrate shared widgets + shell (incl. selected-state fill)
**Files:** `lib/core/widgets/**` and `lib/features/shell/app_shell.dart`.
- [ ] Replace every `Icons.<x>` with `AppIcons.<camelName>` per the mapping.
- [ ] **Shell nav selected state:** `app_shell.dart` currently uses separate `icon` (outline) + `selectedIcon` (filled) per tab. With Material Symbols, use the SAME `AppIcons.<tab>` constant for both and express selection via `fill`: pass `fill: selected ? 1 : 0` to the `Icon` in `_QuestTabIcon` (remove the now-redundant `selectedIcon` field or set it equal). Preserve the selected/unselected color logic and the `Semantics`. This keeps the filled-when-active affordance.
- [ ] `app_button.dart` rating default (`Icons.star_rounded`/`Icons.star_border_rounded`): map to `AppIcons.star`/`AppIcons.starBorder` (or `AppIcons.star` with `fill:1`/`fill:0`); keep the widget's filled-vs-empty behavior. Update `test/core/widgets/app_button_test.dart:102` finder accordingly.
- [ ] `test/core/widgets/stat_tile_test.dart:21` (`Icons.bolt`) → `AppIcons.bolt` IF stat_tile or its test references it; sync the finder.
- [ ] `flutter analyze` clean; `flutter test` green. Commit: `refactor(icons): migrate shared widgets + shell to AppIcons`. No Co-Authored-By.

## Task 3: Migrate feature screens — batch A
**Files:** `lib/features/{home,profile,quiz,study,review,learning}/**`.
- [ ] Replace every `Icons.<x>` → `AppIcons.<camelName>`. No nav/data/string changes.
- [ ] Update `test/widget_test.dart` `find.byIcon(Icons.route_outlined)` (lines ~62, ~830, ~848) → `find.byIcon(AppIcons.route)` and `find.byIcon(Icons.play_arrow_rounded)` (~4240) → `AppIcons.playArrow`. (These assert icons rendered by these feature screens.)
- [ ] `flutter analyze` clean; `flutter test` green. Commit: `refactor(icons): migrate home/profile/quiz/study/review to AppIcons`. No Co-Authored-By.

## Task 4: Migrate feature screens — batch B
**Files:** `lib/features/{training,discover,ai_learning,wordbook,onboarding,auth,notifications,search,quests}/**` and any remaining `lib/**` with `Icons.`.
- [ ] Replace every `Icons.<x>` → `AppIcons.<camelName>`.
- [ ] After this task, `grep -rn "Icons\." lib/ --include="*.dart"` should return NOTHING except `AppIcons`/`IconData` references (no stock `Icons.` left). Verify and report the grep.
- [ ] `flutter analyze` clean; `flutter test` green. Commit: `refactor(icons): migrate remaining features to AppIcons`. No Co-Authored-By.

## Task 5: Final review + build smoke
- [ ] `grep -rn "Icons\." lib/` → only `AppIcons` (confirm zero stock `Icons.` usages remain). Confirm no import of `get.dart`/`symbols_map.dart` anywhere.
- [ ] `flutter analyze` clean; `flutter test` full suite green (report count); `flutter build apk --release` builds AND still tree-shakes (look for the "tree-shaken" MaterialSymbols line; confirm the icon font shrinks — if it does NOT tree-shake, investigate a stray dynamic reference).
- [ ] Final code reviewer over the whole migration diff: (a) every `AppIcons` entry resolves to a real rounded constant, (b) selected-state fill works in shell/buttons, (c) the 6 test finders updated correctly, (d) no behavior/nav/string changes, (e) tree-shaking intact, (f) no leftover `Icons.` or dynamic Symbols import.
- [ ] On-device eyeball is the user's pass (the rounded icon set across the app).

## Self-review notes
- Collapsing `_outlined`/`_rounded` variants into one `AppIcons` entry is intentional — Material Symbols expresses outline-vs-fill via the `fill` axis (global `fill:0`), not separate glyphs. Selected states opt into `fill:1`.
- The 3 flagged substitutes are visually equivalent rounded glyphs; acceptable.
- Keep the dependency-only commit `13339c8` as the base; this plan adds `AppIcons` + call-site swaps on top.
