# Friendly Quest Frontend Reskin — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reskin the LinguaQuest Flutter app to the original, mascot-anchored "Friendly Quest" design language without changing any logic, navigation, or data.

**Architecture:** Tokens-first. Add a single `AppTokens` source of truth + refresh `app_theme.dart` so global changes propagate. Build a small shared component library, then apply it screen-by-screen. All user-facing text goes through `AppLocalizations`.

**Tech Stack:** Flutter (Material 3), Riverpod, go_router, flutter gen-l10n (ARB: en/zh/ms).

**Working agreements:** Branch `feat/ui-friendly-quest-reskin`. Atomic commits. **No `Co-Authored-By` trailer.** Do not modify `.DS_Store`. Reference spec: `docs/superpowers/specs/2026-06-15-frontend-friendly-quest-reskin-design.md`.

**Verification baseline (run before starting):** `cd linguaquest && flutter analyze && flutter test` — note the current pass/fail state so regressions are attributable. Baseline: analyze clean, 169 tests pass.

---

## AMENDMENT (2026-06-15) — Guardrail reconciliation

`test/ui_style_guard_test.dart` enforces a flat/list-based aesthetic that conflicts with the card-rich design. User decisions:

- **Adopt the richer look and rewrite the *visual* guard assertions** to enforce the new system. **Preserve** all behavioral/routing/i18n-boundary/async-safety guards (route paths, `formalLessons` usage, `displayWordTag`/`displayCustomTag`, no legacy English labels, etc.).
- **Rename `QuestCard` → `QuestPanel`** (file `quest_panel.dart`). The strings `QuestCard`/`quest_card.dart`/`MetricTile`/`metric_tile.dart` must not appear anywhere — update Task 4 and all references accordingly.
- **i18n = pragmatic:** new components receive strings from callers (no new hardcoded literals); migrate genuinely-stray literals; **leave guard-required inline Chinese** (`词汇全解`, `词组搭配`, `复习负荷`, `即时反馈`, `暂未开放`, `任务 XP`, etc.) as-is so those content guards stay valid.
- When a screen task introduces cards/shadows/gradients/rings, update the corresponding assertion in `ui_style_guard_test.dart` in the **same commit**, and keep `flutter test` green.

---

## File Structure

**Create:**
- `lib/core/theme/app_tokens.dart` — spacing, radii, shadow, semantic colors, durations.
- `lib/core/widgets/quest_card.dart` — `QuestCard`.
- `lib/core/widgets/stat_tile.dart` — `StatTile`.
- `lib/core/widgets/quest_list_row.dart` — `QuestListRow`.
- `lib/core/widgets/progress_ring.dart` — `ProgressRing`.
- `lib/core/widgets/status_badge.dart` — `StatusBadge` + `StatusTone`.
- `lib/core/widgets/segmented_tabs.dart` — `SegmentedTabs`.
- `lib/core/widgets/brand_hero_card.dart` — `BrandHeroCard`.
- `lib/core/widgets/recall_buttons.dart` — `RecallButtons`.
- `lib/core/widgets/word_choice_button.dart` — `WordChoiceButton`.
- `lib/core/widgets/mask_motif.dart` — `MaskMotifPainter` + `MaskBackdrop`.

**Modify:**
- `lib/core/theme/app_theme.dart` — palette + component themes.
- `lib/core/widgets/{empty_state,section_header,learning_badges}.dart` — adopt tokens.
- All feature screens under `lib/features/**` — apply components (Phase 3).
- `lib/l10n/app_en.arb`, `app_zh.arb`, `app_ms.arb` — new strings + migrated literals.

**Convention used by every screen task:** replace inline `Container`/`Card` panels with `QuestCard`; replace inline numeric panels with `StatTile`; replace inline `Row+InkWell` list items with `QuestListRow`; replace hardcoded `Color(...)`/`Colors.*`/`EdgeInsets.*`/`BorderRadius.*` with `AppTokens`/`colorScheme` equivalents; route every literal string through `AppLocalizations`.

---

## Phase 1 — Tokens & Theme

### Task 1: Add AppTokens

**Files:**
- Create: `lib/core/theme/app_tokens.dart`
- Test: `test/core/theme/app_tokens_test.dart`

- [ ] **Step 1: Write `app_tokens.dart`**

```dart
import 'package:flutter/material.dart';

/// Single source of truth for the "Friendly Quest" design tokens.
class AppTokens {
  const AppTokens._();

  // Spacing scale
  static const double s2 = 2;
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;

  // Radii
  static const double radiusSmall = 12;
  static const double radiusButton = 16;
  static const double radiusCard = 20;
  static const double radiusSheet = 24;
  static const double radiusPill = 999;

  // Durations
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 260);

  // Brand palette (light)
  static const Color brandNavy = Color(0xFF233A66);
  static const Color azure = Color(0xFF2C7BE0);
  static const Color sky = Color(0xFF8FD0F2);
  static const Color success = Color(0xFF5FB23C);
  static const Color mango = Color(0xFFFFB22E);
  static const Color coral = Color(0xFFFF6B5A);
  static const Color amber = Color(0xFFF5A623);

  static const Color bgLight = Color(0xFFF4F8FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color chipLight = Color(0xFFEAF1F9);
  static const Color textPrimaryLight = Color(0xFF1E2A44);
  static const Color textSecondaryLight = Color(0xFF6B7B95);
  static const Color textHintLight = Color(0xFF9AA8BE);
  static const Color outlineLight = Color(0xFFE4ECF5);

  // Brand palette (dark)
  static const Color bgDark = Color(0xFF0E1626);
  static const Color surfaceDark = Color(0xFF16223A);
  static const Color surfaceDarkHigh = Color(0xFF1E2D49);
  static const Color azureDark = Color(0xFF6FB0F5);
  static const Color textPrimaryDark = Color(0xFFE6EEF8);
  static const Color textSecondaryDark = Color(0xFF9DB0CC);

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  /// Soft elevation shadow used by cards (flat-with-depth).
  static List<BoxShadow> cardShadow(BuildContext c) => _isDark(c)
      ? const []
      : const [
          BoxShadow(
            color: Color(0x14233A66), // navy @ ~8%
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ];

  // Semantic accent accessors (brightened on dark).
  static Color successColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFF7FD05A) : success;
  static Color mangoColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFFC85C) : mango;
  static Color coralColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFF8A7B) : coral;
  static Color amberColor(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFFC04D) : amber;
}
```

- [ ] **Step 2: Write smoke test** `test/core/theme/app_tokens_test.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/theme/app_tokens.dart';

void main() {
  testWidgets('cardShadow is empty in dark, present in light', (tester) async {
    late List<BoxShadow> light;
    late List<BoxShadow> dark;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.light),
      home: Builder(builder: (c) {
        light = AppTokens.cardShadow(c);
        return const SizedBox();
      }),
    ));
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(brightness: Brightness.dark),
      home: Builder(builder: (c) {
        dark = AppTokens.cardShadow(c);
        return const SizedBox();
      }),
    ));
    expect(light, isNotEmpty);
    expect(dark, isEmpty);
  });
}
```

- [ ] **Step 3: Run** `flutter test test/core/theme/app_tokens_test.dart` — Expected: PASS.
- [ ] **Step 4: Commit** `feat(theme): add Friendly Quest design tokens`

### Task 2: Refresh app_theme palette + component themes

**Files:**
- Modify: `lib/core/theme/app_theme.dart`

- [ ] **Step 1:** Replace the brand color constants (lines ~8-22) with the Friendly Quest palette, aliasing to `AppTokens` (keep the old public names that screens reference — `teal`, `cyan`, `mango`, `leaf`, `ink`, `paper`, `mint`, `coral`, `success`, dark surfaces — but point them at the new hexes so existing references inherit the new look):
  - `teal` → `AppTokens.azure`, `deepTeal` → `AppTokens.brandNavy`, `cyan` → `AppTokens.sky`, `coral` → `AppTokens.coral`, `mango` → `AppTokens.mango`, `mint` → `AppTokens.chipLight`, `leaf` → `AppTokens.success`, `ink` → `AppTokens.textPrimaryLight`, `paper` → `AppTokens.bgLight`, `lightSurface` → `AppTokens.surfaceLight`, `success` → `AppTokens.success`, `darkPaper` → `AppTokens.bgDark`, `darkSurface` → `AppTokens.surfaceDark`, `darkSurfaceHigh`/`darkSurfaceHighest` → `AppTokens.surfaceDarkHigh`.
- [ ] **Step 2:** In `light()`, set scheme `primary: AppTokens.azure`, `secondary: AppTokens.sky`, `surface: AppTokens.surfaceLight`, `onSurface: AppTokens.textPrimaryLight`, `onSurfaceVariant: AppTokens.textSecondaryLight`, `outline`/`outlineVariant: AppTokens.outlineLight`, `error: AppTokens.coral`, container surfaces to white/`chipLight`. Set `scaffoldBackgroundColor: AppTokens.bgLight`.
- [ ] **Step 3:** In `dark()`, set `primary: AppTokens.azureDark`, `surface: AppTokens.surfaceDark`, `onSurface: AppTokens.textPrimaryDark`, `onSurfaceVariant: AppTokens.textSecondaryDark`, container surfaces to `surfaceDark`/`surfaceDarkHigh`. Set `scaffoldBackgroundColor: AppTokens.bgDark`.
- [ ] **Step 4:** In `_base`, update component themes:
  - `cardTheme`: `RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusCard))`, elevation 0.
  - `filledButtonTheme` / `outlinedButtonTheme`: radius `AppTokens.radiusButton`, weight w800.
  - `inputDecorationTheme`: radius `AppTokens.radiusCard`.
  - `bottomSheetTheme`/`dialogTheme`: radius `AppTokens.radiusSheet`.
  - Soften `textTheme` heavy weights from `w900` → `w800` for display/headline/title.
- [ ] **Step 5: Run** `flutter analyze` (Expected: no new errors) then `flutter test` (Expected: still green; fix any test asserting old hex).
- [ ] **Step 6: Commit** `feat(theme): apply Friendly Quest palette and component themes`

---

## Phase 2 — Shared Components

Each component task: write the widget, write a widget test (renders + key state), run the test, commit. All text params are `String` supplied by callers (callers pass l10n) — **components contain no hardcoded user-facing literals**.

### Task 3: MaskMotif painter
**Files:** Create `lib/core/widgets/mask_motif.dart`; Test `test/core/widgets/mask_motif_test.dart`.
- [ ] Implement `MaskBackdrop({Color color, double height, Widget? child})` painting the cat-mask twin-arc curve via `CustomPainter`. Pure decoration.
- [ ] Test: pumps `MaskBackdrop` inside `MaterialApp`, expects `find.byType(CustomPaint)` present, no exceptions.
- [ ] Commit `feat(ui): add cat-mask motif painter`

### Task 4: QuestCard
**Files:** Create `lib/core/widgets/quest_card.dart`; Test `test/core/widgets/quest_card_test.dart`.
- [ ] Implement:
```dart
class QuestCard extends StatelessWidget {
  const QuestCard({
    required this.child,
    this.padding = const EdgeInsets.all(AppTokens.s16),
    this.onTap,
    this.color,
    super.key,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  // Container with color (default colorScheme.surface), radiusCard,
  // AppTokens.cardShadow(context); wraps in InkWell when onTap != null.
}
```
- [ ] Test: renders child; tapping invokes `onTap`.
- [ ] Commit `feat(ui): add QuestCard`

### Task 5: StatTile
**Files:** Create `lib/core/widgets/stat_tile.dart`; Test alongside.
- [ ] Implement `StatTile({required String value, required String label, IconData? icon, Color? accent})` — large value (w800), label (secondary), optional leading icon badge.
- [ ] Test: shows value + label text.
- [ ] Commit `feat(ui): add StatTile`

### Task 6: QuestListRow
**Files:** Create `lib/core/widgets/quest_list_row.dart`; Test alongside.
- [ ] Implement `QuestListRow({required IconData icon, Color? iconColor, required String title, String? subtitle, Widget? trailing, String? value, VoidCallback? onTap, bool showChevron = true})` — leading icon badge, title/subtitle column, trailing widget or value text + chevron.
- [ ] Test: shows title; tap fires `onTap`; trailing `value` renders.
- [ ] Commit `feat(ui): add QuestListRow`

### Task 7: ProgressRing
**Files:** Create `lib/core/widgets/progress_ring.dart`; Test alongside.
- [ ] Implement `ProgressRing({required double progress (0..1), double size = 72, String? centerLabel, String? centerSubLabel, Color? color})` via `CustomPaint` arc + center text. Clamp progress.
- [ ] Test: renders centerLabel; does not throw for progress 0, 0.65, 1.
- [ ] Commit `feat(ui): add ProgressRing`

### Task 8: StatusBadge
**Files:** Create `lib/core/widgets/status_badge.dart`; Test alongside.
- [ ] Implement `enum StatusTone { neutral, info, success, warning, danger }` and `StatusBadge({required String label, StatusTone tone = StatusTone.neutral, IconData? icon})` mapping tones to token colors (danger→coral, warning→amber, success→success, info→azure, neutral→chip). Pill shape.
- [ ] Test: renders label for each tone without throwing.
- [ ] Commit `feat(ui): add StatusBadge`

### Task 9: SegmentedTabs
**Files:** Create `lib/core/widgets/segmented_tabs.dart`; Test alongside.
- [ ] Implement `SegmentedTabs({required List<String> labels, required int selectedIndex, required ValueChanged<int> onChanged})` — pill segmented control, selected = azure fill / white text.
- [ ] Test: tapping a segment fires `onChanged` with its index.
- [ ] Commit `feat(ui): add SegmentedTabs`

### Task 10: BrandHeroCard
**Files:** Create `lib/core/widgets/brand_hero_card.dart`; Test alongside.
- [ ] Implement `BrandHeroCard({required Widget child, EdgeInsetsGeometry padding})` — navy gradient surface (brandNavy→azure), `MaskBackdrop` overlay, radiusCard, white-on-navy default text color via `DefaultTextStyle`.
- [ ] Test: renders child without throwing.
- [ ] Commit `feat(ui): add BrandHeroCard`

### Task 11: RecallButtons
**Files:** Create `lib/core/widgets/recall_buttons.dart`; Test alongside.
- [ ] Implement `RecallButtons({required String unknownLabel, required String fuzzyLabel, required String knownLabel, required VoidCallback onUnknown, required VoidCallback onFuzzy, required VoidCallback onKnown})` — three pill buttons (coral / amber / success). Labels passed in (l10n).
- [ ] Test: each button fires its callback.
- [ ] Commit `feat(ui): add RecallButtons`

### Task 12: WordChoiceButton
**Files:** Create `lib/core/widgets/word_choice_button.dart`; Test alongside.
- [ ] Implement `enum ChoiceState { idle, selected, correct, wrong }` and `WordChoiceButton({required String letter, required String text, ChoiceState state = ChoiceState.idle, VoidCallback? onTap})` — letter chip + text, color per state.
- [ ] Test: renders text; tap fires `onTap` when idle.
- [ ] Commit `feat(ui): add WordChoiceButton`

### Task 13: Refresh existing shared widgets to tokens
**Files:** Modify `lib/core/widgets/empty_state.dart`, `section_header.dart`, `learning_badges.dart`.
- [ ] `EmptyState`: use `BrandMark`/mascot icon, token spacing/radii.
- [ ] `SectionHeader`: token spacing, title weight w800, optional trailing action style.
- [ ] `learning_badges.dart`: `PillLabel`/badges use `AppTokens` radii/spacing and semantic colors.
- [ ] Run `flutter test` (existing tests green).
- [ ] Commit `refactor(ui): adopt design tokens in shared widgets`

---

## Phase 3 — Apply to Screens

For **every** screen task below, the steps are the same and MUST be followed:

- [ ] **Step A:** Read the screen file. Inventory inline panels, rows, stat blocks, badges, hardcoded colors/insets/radii, and any hardcoded string literals.
- [ ] **Step B:** Replace inline panels → `QuestCard`; numeric blocks → `StatTile`; tappable list items → `QuestListRow`; status/strength chips → `StatusBadge`; segmented controls → `SegmentedTabs`; progress circles → `ProgressRing`; hero/profile/plan banners → `BrandHeroCard`; recall row → `RecallButtons`; quiz options → `WordChoiceButton`. Replace hardcoded `Color`/`Colors.*`/`EdgeInsets.*`/`BorderRadius.*` with `AppTokens`/`colorScheme`.
- [ ] **Step C (i18n):** Move every user-facing literal to a new key in `app_en.arb`, `app_zh.arb`, `app_ms.arb`; run `flutter gen-l10n`; reference via `AppLocalizations.of(context)`.
- [ ] **Step D:** `flutter analyze` (no new issues) and `flutter test` (green).
- [ ] **Step E:** Commit per screen — `style(<feature>): apply Friendly Quest design`.

> Do **not** change widget structure that carries behavior (callbacks, providers, navigation). Visual layer only.

### Group A — Shell & Home
- [ ] Task 14: `lib/features/shell/app_shell.dart` — refresh `_QuestBottomNav` (brand-colored selected state, mask accent, token spacing). Commit.
- [ ] Task 15: `lib/features/home/home_screen.dart` — hero daily-focus → `BrandHeroCard` + `ProgressRing`; learning signals → `StatTile`; quick links → `QuestListRow`/`QuestCard`; 薄弱词 chips → `StatusBadge`. Commit.

### Group B — Study flow
- [ ] Task 16: `lib/features/wordbook/word_detail_screen.dart` — apply components; **migrate the 4 hardcoded strings** (`没有找到这个词`, `复习统计`, `标记为记住`, `安排近期再练`) to l10n. Commit.
- [ ] Task 17: `lib/features/wordbook/target_word_detail_screen.dart` + `word_knowledge_sections.dart` — section cards via `QuestCard`, synonyms/antonyms with token colors. Commit.
- [ ] Task 18: `lib/features/quiz/quiz_session_screen.dart` — options → `WordChoiceButton`; progress bar/header tokens. Commit.
- [ ] Task 19: `lib/features/learning/learning_path_screen.dart` (+ `lesson_preview_screen.dart`, migrate `没有找到这节课`) — path nodes/cards via tokens + `StatusBadge`. Commit.

### Group C — Wordbook & Review
- [ ] Task 20: `lib/features/wordbook/wordbook_screen.dart` — switcher → `SegmentedTabs`; word rows → `QuestListRow`; progress pills → `StatusBadge`. Commit.
- [ ] Task 21: `lib/features/review/review_center_screen.dart` — status header → `BrandHeroCard`/`QuestCard`; counts → `StatTile`; queue rows → `QuestListRow`; strength → `StatusBadge`. Commit.
- [ ] Task 22: `lib/features/review/mistake_book_screen.dart` — apply components. Commit.

### Group D — Training, Discover, AI Learning
- [ ] Task 23: `lib/features/training/training_screen.dart` (+ `training_session_screen.dart`) — drill rows → `QuestListRow`/`QuestCard`; metrics → `StatTile`. Commit.
- [ ] Task 24: `lib/features/discover/discover_screen.dart` + `xp_tasks_screen.dart` + `shared_widgets.dart` — segmented tabs (推荐/任务/社区/活动) via `SegmentedTabs`; task rows tokens. Commit.
- [ ] Task 25: `lib/features/discover/community_screen.dart` + `lucky_draw_screen.dart` — apply components. Commit.
- [ ] Task 26: `lib/features/ai_learning/ai_learning_screen.dart` — tool grid → `QuestCard`; context card tokens; mascot avatar. Commit.

### Group E — Profile, Settings, Auth/Onboarding
- [ ] Task 27: `lib/features/profile/profile_screen.dart` — header → `BrandHeroCard`; stats → `StatTile`; settings rows → `QuestListRow`. Commit.
- [ ] Task 28: `lib/features/profile/{settings_screen,study_plan_settings_screen,about_screen,help_support_screen}.dart` — rows → `QuestListRow`, cards → `QuestCard`. Commit.
- [ ] Task 29: `lib/features/auth/{login_screen,register_screen,goal_setup_screen}.dart` + `lib/features/onboarding/{onboarding_screen,splash_screen}.dart` + `lib/features/notifications/notifications_screen.dart` + `lib/features/search/search_screen.dart` — token + component pass for consistency. Commit.
- [ ] Task 30: Sweep `lib/features/quests/*.dart` (ai_tutor, leaderboard, progress_analytics, class_mode, class_progress, quest_screen) + `lib/features/quiz/lesson_result_screen.dart` + `lib/features/study/*` + `lib/features/wordbook/{custom_word_list_screen,add_edit_custom_word_screen}.dart` — apply tokens/components. Commit per file or small group.

---

## Phase 4 — Polish & Verification

### Task 31: Dark-mode pass
- [ ] Run the app in dark mode; visually check each screen group for contrast/legibility; fix any screen still using a hardcoded light color. Commit fixes as `fix(ui): dark-mode contrast pass`.

### Task 32: i18n completeness audit
- [ ] `grep -rnP "['\"][\x{4e00}-\x{9fff}]+['\"]" linguaquest/lib --include=*.dart` returns no user-facing matches (only comments allowed).
- [ ] Confirm `app_en.arb`, `app_zh.arb`, `app_ms.arb` have matching keys; `flutter gen-l10n` clean.
- [ ] Commit `chore(l10n): finalize Friendly Quest strings`

### Task 33: Final verification
- [ ] `cd linguaquest && flutter analyze` — clean.
- [ ] `flutter test` — green.
- [ ] Screenshot each main screen in light + dark (via `/run` or device) and confirm against the spec's design language.
- [ ] Commit any final fixes.

---

## Self-Review Notes (coverage)

- Spec §"Color/Spacing/Radii/Depth/Type/Motion" → Tasks 1-2.
- Spec §"Signature Brand Elements" → Tasks 3, 7, 10 (motif, ring, hero) + mascot in Task 13/26/27.
- Spec §"Component library" → Tasks 3-13.
- Spec §"Rollout per screen group" → Tasks 14-30.
- Spec §"i18n" (all text + 5 migrations) → Step C on every screen task; migrations in Tasks 16 & 19; audit in Task 32.
- Spec §"Dark mode kept & adapted" → dark colors in Tasks 1-2; verification in Task 31.
- Spec §"Testing & Verification" → per-task `analyze`/`test`; Task 33.
- Spec §"No logic/nav changes" → enforced by Step B/"visual layer only" note.
