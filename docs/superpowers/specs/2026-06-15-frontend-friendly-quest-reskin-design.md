# Frontend Reskin — "Friendly Quest" Design System

**Date:** 2026-06-15
**Branch:** `feat/ui-friendly-quest-reskin`
**Status:** Approved design → ready for implementation plan

## Summary

A **pure visual reskin** of the LinguaQuest Flutter app (`linguaquest/`) to an
original, brand-aligned design language called **"Friendly Quest."** The app's
information architecture, navigation, business logic, data layer, and Riverpod
state are **unchanged**. Only the presentation layer changes: design tokens,
the theme, shared UI components, and per-screen visual composition.

The design is inspired by — but does **not** copy — two provided reference sets
(`reference.png` grid and `../LinguaQuest_UI_Single_Pages/`). It is anchored to
the product's brand icon: a friendly, slightly mysterious navy **masked-cat**
mascot on a glossy sky-blue tile, with a leaf-green "LINGUA" + white "QUEST"
wordmark.

## Goals

- Establish a centralized, reusable design-token + component layer.
- Apply a cohesive, original, mascot-anchored visual language across all screens.
- Preserve all existing behavior, navigation, and data flow exactly.
- Keep dark-mode support, deriving a dark variant of the new design.
- Route **all** user-facing text through `AppLocalizations` (i18n) — no
  hardcoded strings, including new component labels.

## Non-Goals

- No changes to business logic, repositories, models, routing, or state.
- No new features or screen-flow changes.
- No structural refactor beyond extracting repeated UI into shared widgets.
- No unrelated refactoring.

## Design Principles

1. **Calm white canvas** with navy ink — content-first.
2. **One confident azure** for interactive/primary actions; restraint elsewhere.
3. **Color used semantically:** green = known/completed, mango = streak/XP/rewards,
   coral = unknown/weak/error, amber = fuzzy/medium.
4. **Soft depth** — gentle shadow tokens, not harsh Material elevation.
5. **Generous rounding** and consistent spacing.
6. **A recurring cat-mask arc motif** ties screens together and signals the brand.

## Design Tokens

### Color — Light

| Role | Hex |
|---|---|
| Brand navy (ink / dark surfaces) | `#233A66` |
| Primary action (azure) | `#2C7BE0` |
| Sky accent (illustration fills) | `#8FD0F2` |
| Success / 认识 / completed | `#5FB23C` |
| Streak / XP / rewards (mango) | `#FFB22E` |
| 不认识 / 较弱 / error (coral) | `#FF6B5A` |
| 模糊 / 中等 (amber) | `#F5A623` |
| Background | `#F4F8FC` |
| Card surface | `#FFFFFF` |
| Chip / track surface | `#EAF1F9` |
| Text primary | `#1E2A44` |
| Text secondary | `#6B7B95` |
| Text hint | `#9AA8BE` |
| Divider / outline | `#E4ECF5` |

### Color — Dark (derived from the navy cat)

| Role | Hex |
|---|---|
| Background | `#0E1626` |
| Card surface | `#16223A` |
| Raised surface | `#1E2D49` |
| Primary action | `#6FB0F5` |
| Text primary | `#E6EEF8` |
| Text secondary | `#9DB0CC` |

Accent hues (green/mango/coral/amber) keep the same hue, brightened for contrast
on dark surfaces.

### Spacing scale

`2 / 4 / 8 / 12 / 16 / 20 / 24 / 32`. Screen horizontal padding = 16, card
padding = 16, default section gap = 20.

### Radii

card = 20, button = 16, sheet = 24, small = 12, pill = 999.

### Depth

Single soft shadow token: navy at ~6% alpha, blur 16, y-offset 6. Cards are flat
with this shadow rather than Material elevation.

### Typography

Keep `Avenir` (Latin) + system CJK fallback. Soften the current near-uniform
`w900` to: `w800` headers, `w600` emphasis, `w500` body — friendlier, less heavy.
Scale (approx): display 34, headline 24, title 18, body 15, label 13, caption 12.

### Motion

Keep existing page-swipe transition. Add subtle 180–260ms ease on card press,
selection, and progress changes.

## Signature Brand Elements

1. **Cat-mask arc motif** — a reusable `CustomPainter` used as a subtle header
   arc, hero-card top curve, and progress-ring accent.
2. **Mascot companion** — the cat appears in empty states, the AI-tutor avatar,
   and reward/celebration moments. Reuses the existing icon asset / `BrandMark`.
3. **Progress ring** with a mask-eye accent for daily completion / accuracy.

## Architecture

### New / refreshed files

```
lib/core/theme/app_tokens.dart        (NEW: spacing, radii, shadow, semantic colors, durations)
lib/core/theme/app_theme.dart         (refreshed palette + component themes)
lib/core/widgets/quest_card.dart      (NEW)
lib/core/widgets/stat_tile.dart       (NEW)
lib/core/widgets/quest_list_row.dart  (NEW — replaces ~15 inline row copies)
lib/core/widgets/progress_ring.dart   (NEW)
lib/core/widgets/status_badge.dart    (NEW — 较弱/中等/未学/已掌握/新学/复习…)
lib/core/widgets/segmented_tabs.dart  (NEW — formalizes FilterPillButton)
lib/core/widgets/brand_hero_card.dart (NEW — navy gradient + mask motif)
lib/core/widgets/recall_buttons.dart  (NEW — 不认识/模糊/认识)
lib/core/widgets/word_choice_button.dart (NEW — quiz A/B/C/D states)
lib/core/widgets/mask_motif.dart      (NEW — CustomPainter)
lib/core/widgets/empty_state.dart     (refresh: mascot)
lib/core/widgets/section_header.dart  (refresh)
lib/core/widgets/learning_badges.dart (refresh PillLabel / badges to tokens)
```

Existing widgets to extend (not duplicate): `PillLabel`, `IconCueBadge`,
`ImageCueBadge`, `QuestIconButton`, `PronunciationControls`, `BrandMark`,
`AiWordSupportLink`.

### Component contracts (one purpose each)

- **AppTokens** — static spacing/radius/shadow/duration constants + semantic
  color accessors (light/dark aware). Single source of truth.
- **QuestCard** — white rounded-20 surface with the soft shadow token; optional
  leading accent / header. Replaces inline `Card`/`Container` usage.
- **StatTile** — number + label + optional icon (home signals, profile stats,
  review counts).
- **QuestListRow** — leading icon-badge + title/subtitle + trailing
  (chevron/value/switch). Replaces the ~15 inline settings/reward/wordbook rows.
- **ProgressRing** — circular progress with center label and mask-eye accent.
- **StatusBadge** — colored status/strength pill with a semantic color map.
- **SegmentedTabs** — pill segmented control (正式课程/我的课程, 推荐/任务/社区/活动).
- **BrandHeroCard** — navy gradient hero with mask motif (profile header, plan card).
- **RecallButtons** — tri-state recall row (coral/amber/green).
- **WordChoiceButton** — quiz MCQ option with default/selected/correct/wrong states.
- **MaskMotif** — painter for the cat-mask arc.

## Rollout Plan

Tokens-first so global changes propagate, then components, then screens.

- **Phase 1 — Tokens & theme.** Add `app_tokens.dart`; update `app_theme.dart`
  light/dark `ColorScheme` to the new palette and component themes
  (buttons radius 16, cards radius 20 + shadow, nav bar, chips, inputs).
- **Phase 2 — Shared components.** Build the component library above.
- **Phase 3 — Apply per screen group:**
  - (a) `app_shell` (bottom nav) + `home_screen`
  - (b) study flow: `word_detail_screen`, `target_word_detail_screen`,
    `quiz_session_screen`, `learning_path_screen`
  - (c) `wordbook_screen`, `review_center_screen`, `mistake_book_screen`
  - (d) `training_screen` (+ `training_session_screen`),
    `discover_screen`, `xp_tasks_screen`, `community_screen`,
    `lucky_draw_screen`, `ai_learning_screen`
  - (e) `profile_screen`, `settings_screen`, `study_plan_settings_screen`,
    `about_screen`, `help_support_screen`, plus auth/onboarding/notifications
    screens for consistency.
- **Phase 4 — Polish.** Dark-mode pass; migrate hardcoded strings to l10n;
  `flutter analyze` + `flutter test`; screenshot verification.

## Internationalization (i18n)

- **All** user-facing text routes through `AppLocalizations`. Any new strings
  introduced by new components must be added to the ARB sources and regenerated
  for all locales (en, zh, ms).
- Migrate the 5 known hardcoded Chinese strings:
  - `word_detail_screen.dart`: `'没有找到这个词'`, `'复习统计'`, `'标记为记住'`,
    `'安排近期再练'`
  - `lesson_preview_screen.dart`: `'没有找到这节课'`
- Audit all touched screens for any other inline literals during the reskin.

## Error Handling & Edge Cases

- Reskin must not change behavior; empty/loading/error states keep their logic,
  only their appearance (now via the refreshed `EmptyState` + mascot).
- Dark mode must be verified on every screen, not just light.
- Long CJK strings and dynamic counts must not overflow new card/row layouts.

## Testing & Verification

- Existing widget tests must continue to pass; update only assertions that pin
  specific colors/strings that legitimately change.
- `flutter analyze` clean, `flutter test` green.
- Manual screenshot verification of each screen in **light and dark**.
- Confirm no remaining hardcoded user-facing strings in touched files.

## Constraints / Working Agreements

- All work on branch `feat/ui-friendly-quest-reskin`.
- **Atomic commits** — each commit small and logically self-contained
  (e.g. "add app_tokens", "refresh theme palette", "add QuestCard", per-screen).
- **No `Co-Authored-By` trailer** on commits.
- Commit/push only as the user directs.
