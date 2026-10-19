# Swiss UI and language / wordbook adaptation implementation plan

**Goal:** Apply a Swiss typographic direction to the Flutter app and make Chinese, Japanese and English learning scopes display consistently across books and locales.

**Architecture:** Keep Flutter, Riverpod and the existing offline repositories. Change shared visual tokens and controls, then compose flatter, left-aligned screens. Resolve display metadata from the active book and explanation locale; keep stable IDs for storage and switching.

**Tech Stack:** Flutter 3.41.6, Dart 3.11.4, Material, Riverpod, generated ARB localization, existing SharedPreferences stores.

## Global constraints

- Blue and the centered-smile cat remain the brand accents.
- Light, dark and system modes; no network font dependency.
- Chinese, Japanese and English explanation languages remain independent of learning language.
- Preserve downloaded content, learning records, session resume, account isolation and offline queue behavior.
- Preserve unrelated local files; atomic commits on `codex/swiss-ui-language-books`, pushed to GitHub.

### Task 1: Consistent multilingual book metadata

Files: `linguaquest/lib/core/widgets/language_wordbook_picker.dart`, profile/settings/plan screens, wordbook screens, ARBs, focused widget tests.

- [x] Test localized language names, starter-book labels in profile/settings, and per-book progress at narrow widths.
- [x] Resolve book labels via `book.nameFor(localeCode)`; never use raw IDs for loaded books. Use localized language names throughout the picker.
- [x] Display the actual available explanation languages and a clear fallback notice for legacy books. Keep downloaded books accessible across learning languages.
- [x] Verify all nine explanation/learning combinations and scope switching without resetting progress.
- [x] Commit: `fix(i18n): align language and wordbook metadata across learning flows`.

### Task 2: Swiss visual foundations

Files: `core/theme/app_tokens.dart`, `app_theme.dart`, shared buttons/cards/progress/nav, theme/widget tests.

- [x] Use near-neutral page/surface colors, high-contrast type, restrained blue, 4 px corners, no decorative elevation or simulated 3D edges.
- [x] Use the platform sans-serif and explicit type scale; preserve touch targets and focus/disabled semantics through native Material buttons.
- [x] Apply the same palette and hierarchy in dark mode; use semantic borders and flat progress indicators.
- [x] Run relevant theme, button, accessibility and dark-mode tests.
- [x] Commit: `feat(ui): establish Swiss typography and flat controls`.

### Task 3: Recompose learning screens

Files: home, training, AI, profile, mixed study, wordbook, settings and matching layout tests.

- [ ] Home: compact brand header, one-line encouragement, active book and language pair, large daily progress, clear CTA and quiet secondary rows.
- [ ] Practice: prominent left-aligned word and meaning; retain explicit confirm/feedback/next, retry and saved-draft behavior.
- [ ] AI: clear heading, small cat accent, current-word context, six flat tool rows and truthful network/login notice.
- [ ] Profile and wordbooks: compact identity, accurate scoped progress, readable long localized names, consistent navigation and downloadable book selection.
- [ ] Test en/zh/ja in light/dark at 360 px and enlarged text; run the complete Flutter suite and analyzer.
- [ ] Build actual Flutter web release and inspect screenshots of home, practice, AI, profile and multilingual book selection.
- [ ] Commit: `feat(ui): recompose learning screens in Swiss style`.

### Task 4: Deliver and verify

Files: release notes and build metadata if needed.

- [ ] Push all atomic commits; build Android through the existing workflow once stable.
- [ ] Keep the real app preview available locally; verify device installation if a compatible signed package can be produced without removing existing app data.
- [ ] Record screenshots, commands, results and remaining legacy-content language limits in release notes.
- [ ] Commit: `docs: record Swiss UI validation and delivery`.
