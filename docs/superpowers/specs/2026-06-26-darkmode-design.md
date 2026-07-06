# Design Spec — Dark Mode (DEVELOPMENT_PLAN §1)

- **Date:** 2026-06-26
- **Source:** DEVELOPMENT_PLAN.md §1 (Light/Dark/Follow-system theme switch)
- **Status:** Design only.

## 1. Overview

The app currently renders light-only, but **most of the infrastructure already exists**:
- `AppTheme.dark()` builds a full Material 3 dark theme (`lib/core/theme/app_theme.dart:59`).
- `AppState.themeMode` (`ThemeMode`, default `ThemeMode.system`) is in state (`app_state.dart:157`).
- `AppController.updateThemeMode(ThemeMode)` persists to SharedPreferences (`_themeModeKey`) and reloads on bootstrap (`app_controller.dart:324`).

The app is light-only for ONE reason: `lib/app.dart:34` hardcodes `theme: AppTheme.light()` and sets **no** `darkTheme:` / `themeMode:`. So the persisted `themeMode` is ignored. (Memory "dark-mode-light-only" said the toggle/route/state-UI were removed but theming infra intentionally kept — confirmed.)

This spec: (a) wire the app to honor `themeMode`, (b) add a Settings theme switcher (System / Light / Dark), (c) audit dark-theme polish on the screens added since dark mode was disabled (maps, charts, AI screens, community, asset inventory) so dark mode looks intentional, not inverted.

## 2. Scope
### In scope
- `app.dart`: watch `themeMode` from the controller; set `theme`, `darkTheme`, `themeMode`.
- Settings UI: a theme selector (System / Light / Dark) calling `updateThemeMode`, reflecting current value. Persisted (already handled by the controller). Takes effect immediately (Riverpod rebuild — no restart).
- Dark-theme polish audit + fixes for: the new map screens (`study_map_screen`, `language_map_screen`, About company map — flutter_map tiles are fine but the chrome/cards must adapt), the analytics charts (fl_chart colors must use theme-aware colors, not hardcoded), AI screens (`AiErrorCard`, result cards), community cards, asset inventory, lucky draw. Fix any hardcoded `Colors.white`/black or light-only token usage that breaks in dark.
### Out of scope
- No new palette design beyond what `AppTheme.dark()` already defines (it exists; refine tokens only where a screen is unreadable).
- No per-widget dark variants beyond fixing contrast bugs.

## 3. Implementation

### 3.1 Wire `app.dart`
`lib/app.dart` is currently (likely) a `ConsumerWidget` or `StatelessWidget`. Make it read `themeMode`:
```
final themeMode = ref.watch(appControllerProvider.select((s) => s.themeMode));
return MaterialApp.router(
  ...
  theme: AppTheme.light(),
  darkTheme: AppTheme.dark(),
  themeMode: themeMode,
  ...
);
```
If `app.dart` is not already a `ConsumerWidget`, convert it (it's under a `ProviderScope`). Confirm `appControllerProvider` is in scope.

### 3.2 Settings theme switcher
In the Settings screen (find `lib/features/profile/settings_screen.dart` or equivalent — grep for the settings route `/settings`), add a theme section: three options (System / Light / Dark) via a `SegmentedButton<ThemeMode>` or three `RadioListTile`s / `AppCard` rows. On change: `ref.read(appControllerProvider.notifier).updateThemeMode(mode)`. Reflect `ref.watch(...themeMode)` as the selected value. l10n keys for the labels (en/zh/ms, UNFROZEN).

### 3.3 Dark polish audit
Grep the screens listed in §2 for hardcoded light-only colors:
- `Colors.white` / `Colors.black` used as backgrounds/foregrounds (should be `theme.colorScheme.surface/onSurface` or `AppTokens` theme-aware).
- fl_chart series/labels using fixed colors that vanish on dark — pass `Theme.of(context).colorScheme`-derived colors.
- OSM map: tiles stay light (third-party raster) — that is acceptable; ensure surrounding cards/sheets/AppBar adapt (they will via theme). Add a subtle scrim/border so the light map sits well on a dark scaffold.
Fix each so text/icons/dividers/selected/error/success states stay readable in dark (the plan's explicit requirement).

## 4. l10n keys (en/zh/ms)
| key | en | zh | ms |
|---|---|---|---|
| `settingsTheme` | Theme | 主题 | Tema |
| `settingsThemeSystem` | Follow system | 跟随系统 | Ikut sistem |
| `settingsThemeLight` | Light | 浅色 | Cerah |
| `settingsThemeDark` | Dark | 深色 | Gelap |

## 5. Testing
- Widget test: pump `App`/Settings with `themeMode` overridden to `ThemeMode.dark`; assert `MaterialApp.router.themeMode == ThemeMode.dark` and the resolved `Theme.of(context).brightness == Brightness.dark`. Toggling the Settings selector calls `updateThemeMode` and updates state.
- Widget test: a couple of the audited screens pump under a dark `MaterialApp` (`theme: AppTheme.dark()`) and `tester.takeException()` is null (no crash; smoke).
- The existing `app_theme_test.dart` chip/luminance tests must still pass.
- `flutter analyze` clean; full `flutter test` green.

## 6. Open decisions
1. Settings control: `SegmentedButton` vs radio rows — default `SegmentedButton` (compact, modern).
2. How deep the polish audit goes — default: fix only genuine contrast/hardcoded-color bugs on the listed screens; do not redesign.

## 7. Risks
- Hidden hardcoded `Colors.white` across many screens could make a full audit large; mitigate by scoping the audit to screens added/changed since dark mode was disabled + any screen that visibly breaks.
- fl_chart hardcoded colors are the most likely dark breakage — prioritize the analytics screen.
