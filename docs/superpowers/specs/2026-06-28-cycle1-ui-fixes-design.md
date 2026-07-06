# Cycle 1 UI Fixes — Design

Date: 2026-06-28
Branch: feat/P2-roadmap
Scope: Four focused fixes reported from device testing, aligned to `DEVELOPMENT_PLAN`
sections §1.1 (dark mode), §2.1/§3.1 (language switching), §8 (community), §10 (lottery).

The fifth reported item — fully implementing the four "Coming Soon / In Planning"
features (Passage Cloze, Listening Sprint, Confusable Words, Sentence Generation &
Rewrite) — is **deferred to Cycle 2** with its own spec + plan.

Run-mode note: the test build is **server-backed** (lottery prizes come from the
server DB seed, wordbooks come from `/wordbooks`). Fixes that have a server-side
source are applied to **both** the server and the offline mock so the app is correct
in either mode.

---

## Issue 1 — Dark mode renders a white background (plan §1.1)

### Current state
Dark-mode infrastructure already exists and works:
- `lib/app.dart:37-39` wires `theme: AppTheme.light()`, `darkTheme: AppTheme.dark()`,
  `themeMode: themeMode`.
- `AppTheme.light()` / `AppTheme.dark()` are fully designed ColorSchemes (not inverted)
  — `lib/core/theme/app_theme.dart`.
- Settings has a System/Light/Dark `SegmentedButton` (`_ThemeSettingCard`,
  `lib/features/profile/settings_screen.dart:55,248-300`) calling `updateThemeMode`.
- `AppController.updateThemeMode` persists to SharedPreferences
  (`lib/core/state/app_controller.dart:371-374`); switching is reactive (instant).

### Root cause
The app shell hardcodes the light background regardless of theme:
- `lib/features/shell/app_shell.dart:55` — `Scaffold(backgroundColor: AppTheme.paper)`
- `lib/features/shell/app_shell.dart:66` — `ColoredBox(color: AppTheme.paper)`

`AppTheme.paper` is `AppTokens.bgLight` (a constant light color). In dark mode the
ColorScheme makes cards/text dark, but the shell behind every tab stays white. The
earlier dark-contrast audit (commit 90242d4) only fixed `language_map_screen.dart`
and missed the shell.

### Fix
1. In `app_shell.dart`, replace both hardcoded `AppTheme.paper` background usages with
   the theme-driven value `Theme.of(context).scaffoldBackgroundColor`.
2. **Thorough audit.** Grep all feature screens/widgets/dialogs for hardcoded light
   values used as backgrounds/text/borders:
   - `AppTheme.paper`, `AppTheme.surface` (constant variants)
   - `AppTokens.bgLight`, `AppTokens.surfaceLight`, `AppTokens.textPrimaryLight`,
     `AppTokens.textSecondaryLight`, `AppTokens.textHintLight`, and other `*Light`
     tokens used directly in widgets (these are the light palette and must not be used
     as literals where the theme should drive the value)
   - `Colors.white`, `Colors.black`, `Colors.grey*` used as backgrounds/text
   Replace each occurrence that breaks dark legibility with the theme equivalent
   (`scaffoldBackgroundColor`, `colorScheme.surface`, `colorScheme.onSurface`,
   `colorScheme.onSurfaceVariant`, `colorScheme.outline`, etc.). Brand/semantic colors
   that are intentionally constant in both themes (e.g. success/error accents already
   routed through brightness-aware helpers) are left as-is.

### Verification
- `flutter analyze` clean.
- Extend the existing dark-mode widget tests (`test/.../*dark*`) with a shell
  assertion: when `themeMode: ThemeMode.dark`, the shell's background equals the dark
  theme's `scaffoldBackgroundColor` (not the light `paper`).
- Manual: device in dark mode → all five tabs show a dark shell with legible text.

---

## Issue 2 — Language switching: no map, faint text, Japanese unselectable, lost coming-soon languages (plan §2.1, §3.1)

### Current state
- A full language map already exists: `lib/features/map/language_map_screen.dart`,
  route `/language-map` (`lib/core/routing/app_router.dart:222`). It shows 6 pins
  (`zh`, `en`, `es`, `fr`, `ja`, `ms`); `zh`/`ja` enabled, the rest "coming soon"
  (gray, snackbar on tap). Tapping an enabled pin calls `updateTargetLanguage(code)`
  then opens the wordbook picker at the wordbook step (`initialLanguage: code`).
- The Profile and Settings "Choose Language" rows instead open the bottom-sheet
  two-level picker directly:
  - `lib/features/profile/profile_screen.dart:103` → `showLanguageWordbookPicker(context)`
  - `lib/features/profile/settings_screen.dart:183` → `showLanguageWordbookPicker(context)`
- The picker's language list (`kSupportedLanguages`,
  `lib/core/widgets/language_wordbook_picker.dart:35-38`) contains only `zh` and `ja` —
  the coming-soon languages are absent.
- Picker rows hardcode light color tokens
  (`language_wordbook_picker.dart:336-339`): `AppTokens.textPrimaryLight` (active) /
  `AppTokens.textHintLight` (inactive) — unreadable on the dark sheet surface.
- Server `/wordbooks` is sourced from `server/data/wordbooks_p0.json` (6 HSK books,
  no `language` field). No JLPT books → in server mode the `ja` wordbook step is empty
  ("Coming Soon"). JLPT N5–N1 exist only as client assets
  (`lib/assets/data/wordbook_jlpt_n*.json`), so offline mode already works.

### Fix
- **2a (map entry).** Repoint the "Choose Language" rows in `profile_screen.dart:103`
  and `settings_screen.dart:183` to `context.push('/language-map')`. This restores the
  map as the language-selection entry (plan §3.1), shows the locked coming-soon
  languages, and makes Japanese selectable — the map already routes pin → wordbook
  step.
- **2b (readability + locked languages in picker).**
  - In `language_wordbook_picker.dart`, replace the hardcoded row colors with
    theme-aware colors: active → `Theme.of(context).colorScheme.onSurface`,
    inactive/coming-soon → `colorScheme.onSurfaceVariant` (muted but legible in both
    themes).
  - Add the coming-soon languages back to `kSupportedLanguages` as
    `SupportedLanguage(code: 'en'|'es'|'fr'|'ms', hasBooks: false)` so the picker's own
    level-1 list matches the map. Display names mirror the map's labels
    (English, Spanish (Español), French (Français), Malay (Bahasa Melayu)). These rows
    are non-selectable and show the "coming soon" pill (existing behaviour for
    `hasBooks: false`).
- **2c (Japanese wordbooks in server mode).** Make the server serve JLPT N5–N1.
  The client JLPT asset JSON is shape-compatible with the server's HSK book maps
  (same `id`/`title`/`words[...]` structure; JLPT adds `language`, `kana`, `romaji`
  fields the server passes through untouched). Approach:
  - Add the 5 JLPT books to the server's wordbook data source so `/wordbooks`,
    `/wordbooks/<id>`, and `/words` include them. `/words` and lesson derivation read
    from the same `_loadWordBooks()`, so Japanese words and lessons follow
    automatically. `study_plan_policy.allowedWordBookIds` already includes
    `jlpt_n1..n5`.
  - HSK books with no `language` field continue to default to `zh` on the client
    (current behaviour, unchanged).

### Verification
- Picker widget test: row text uses theme colors; coming-soon languages render as
  non-selectable rows with the coming-soon pill.
- Server test / manual: `GET /wordbooks` returns 11 books (6 HSK + 5 JLPT);
  `GET /words?wordBookId=jlpt_n5` returns Japanese words.
- Manual: Profile → Choose Language → map → tap Japan → wordbook step lists N5–N1 →
  select one.

---

## Issue 4 — Duplicate "new post" buttons (plan §8)

### Root cause
`lib/features/discover/community_screen.dart` renders two controls that both call
`context.push('/forum/compose')`:
- Top outlined "Share an update" button + spacing — lines 133-146.
- Bottom-right FAB — lines 123-127.

### Fix
Delete lines 133-146 (the `Padding` wrapping the `OutlinedButton.icon` plus the
following `SizedBox`). Keep the FAB.

### Verification
- `flutter analyze` clean; community widget test stays green (it should reference the
  FAB or compose route, not the removed button).

---

## Issue 5 — Lucky Draw prize names still in Chinese (plan §10)

### Root cause
Prize `name` and `description` are Chinese in two sources:
- Server seed: `server/lib/src/lottery_policy.dart` (e.g. `'name': '星轨头像框'`,
  `'description': '围绕头像的星轨装饰…'`). Seeded into `lottery_prizes` via
  `_seedLotteryPrizes` (`server/lib/src/database.dart:670`), which runs on startup and
  **upserts** (`ON CONFLICT (id) DO UPDATE SET name=…, description=…`). In server mode
  the Lucky Draw reads these (`GET /lottery/prizes`).
- Offline mock: `lib/data/repositories/mock_repositories.dart:710-846`
  (`_mockPrizePool`, 15 `LotteryPrize` entries).

Category headers and rarity labels are already localized; only the per-prize
`name`/`description` are Chinese. The app UI is English-only (locale hard-locked to
`en`), so plain English strings are correct — no ARB keys needed.

### Fix
Translate the 15 prizes' `name` and `description` to English in **both** files,
keeping ids, categories, rarities, probabilities, and fragment values unchanged. On
the next server start the upsert pushes the English names to existing DB rows.

English names (consistent across both files):
1. 星轨头像框 → Star Trail Avatar Frame
2. 烬焰头像框 → Ember Flame Avatar Frame
3. 极光主页背景 → Aurora Home Background
4. 黎明港湾背景 → Dawn Harbor Background
5. 专注冲刺徽章 → Focus Sprint Badge
6. 夜枭徽章 → Night Owl Badge
7. 周年灯笼徽章 → Anniversary Lantern Badge
8. 训练场侦察员称号 → Training Ground Scout Title
9. 词汇守护者称号 → Vocabulary Guardian Title
10. 黎明航行者称号 → Dawn Voyager Title
11. 薄荷卡片皮肤 → Mint Card Skin
12. 樱花卡片皮肤 → Sakura Card Skin
13. 午夜卡片皮肤 → Midnight Card Skin
14. 柑橘卡片皮肤 → Citrus Card Skin
15. 星尘碎片 → Stardust Fragment

Descriptions translated to short faithful English equivalents (no learning-score boost
wording preserved where present).

### Verification
- `grep` for CJK characters in `lottery_policy.dart` and the `_mockPrizePool` block
  returns nothing.
- Server test / manual: restart server → `GET /lottery/prizes` returns English names;
  Lucky Draw screen shows English prize names.

---

## Out of scope (Cycle 2)
Passage Cloze, Listening Sprint, Confusable Words, Sentence Generation & Rewrite —
separate spec + plan.
