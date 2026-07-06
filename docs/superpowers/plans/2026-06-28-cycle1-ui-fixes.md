# Cycle 1 UI Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix four reported defects — dark-mode white background, the language picker (map entry, faint text, Japanese wordbooks, lost coming-soon languages), the duplicate community post button, and Chinese Lucky Draw prize names.

**Architecture:** Pure fixes to an existing Flutter app (`linguaquest/`) + Dart `shelf` server (`server/`). No new packages, no new abstractions. Dark mode infra already exists and works; the fixes route hardcoded light colors through the theme, repoint a navigation entry to an existing screen, add already-existing JLPT data to the server, delete a redundant widget, and translate two prize tables.

**Tech Stack:** Flutter 3.41.6, Riverpod, go_router, flutter_map; Dart shelf server, PostgreSQL.

## Global Constraints

- App UI locale is hard-locked to English (`en`). Prize names are plain English strings — no ARB keys.
- No new dependencies. Reuse stdlib / existing packages only.
- Light-mode appearance must not regress. The token swaps in Task 2 are deliberately no-ops in light mode (light theme defines `onSurface == AppTokens.textPrimaryLight` and `onSurfaceVariant == AppTokens.textSecondaryLight` in `lib/core/theme/app_theme.dart`).
- Run `flutter analyze` (from `linguaquest/`) and `dart analyze` (from `server/`) clean before every commit in the relevant project.
- Flutter commands run from `/Users/lanyichen/Codes/Mobile/ASM2/linguaquest`. Server commands run from `/Users/lanyichen/Codes/Mobile/ASM2/server`.
- Prize ids, categories, rarities, probabilities, and fragment values must NOT change — only `name` and `description`. The server lottery seed must keep `length == 15` and `probability` total `== 100` (locked by `server/test/lottery_policy_test.dart`).

---

### Task 1: Dark-mode shell + splash background

**Files:**
- Modify: `linguaquest/lib/features/shell/app_shell.dart:55,66`
- Modify: `linguaquest/lib/features/onboarding/splash_screen.dart:67`
- Test: `linguaquest/test/dark_mode_test.dart`

**Interfaces:**
- Consumes: `Theme.of(context).scaffoldBackgroundColor` (Flutter); `AppTheme.dark()` / `AppTheme.light()` (existing).
- Produces: nothing new; behavioural fix only.

- [ ] **Step 1: Write the failing test**

Add this test as a new group at the end of `linguaquest/test/dark_mode_test.dart` (before the final `}` of `main`). It pumps `AppShell` directly under a forced dark theme — deterministic, no bootstrap needed:

```dart
  group('Dark Mode — app shell', () {
    testWidgets('shell background follows the dark theme', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: ThemeMode.dark,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const AppShell(selectedIndex: 0, child: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pump();

      final shellScaffold = tester
          .widgetList<Scaffold>(find.byType(Scaffold))
          .firstWhere((s) => s.bottomNavigationBar != null);
      expect(shellScaffold.backgroundColor, isNot(AppTheme.paper));
      expect(
        shellScaffold.backgroundColor,
        AppTheme.dark().scaffoldBackgroundColor,
      );
    });
  });
```

Add the import at the top of the file:

```dart
import 'package:linguaquest/features/shell/app_shell.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/dark_mode_test.dart -n "shell background follows the dark theme"`
Expected: FAIL — `backgroundColor` is `AppTheme.paper` (the constant light color), so both assertions fail.

- [ ] **Step 3: Apply the fix**

In `linguaquest/lib/features/shell/app_shell.dart`, change line 55 from:

```dart
      backgroundColor: AppTheme.paper,
```

to:

```dart
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
```

and change line 66 from:

```dart
            color: AppTheme.paper,
```

to:

```dart
            color: Theme.of(context).scaffoldBackgroundColor,
```

In `linguaquest/lib/features/onboarding/splash_screen.dart`, change line 67 from:

```dart
      backgroundColor: AppTheme.paper,
```

to:

```dart
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
```

If `AppTheme` becomes an unused import in `splash_screen.dart` after this change, remove the import line; otherwise leave it. (`app_shell.dart` still uses `AppTheme` elsewhere? It imports it — verify with analyze; remove the import only if analyze reports it unused.)

- [ ] **Step 4: Run the test + analyze**

Run: `flutter test test/dark_mode_test.dart -n "app shell background follows the dark theme"`
Expected: PASS
Run: `flutter analyze lib/features/shell/app_shell.dart lib/features/onboarding/splash_screen.dart`
Expected: No issues (no unused-import warnings).

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/features/shell/app_shell.dart linguaquest/lib/features/onboarding/splash_screen.dart linguaquest/test/dark_mode_test.dart
git commit -m "fix(theme): app shell + splash backgrounds follow theme (dark mode white bg)"
```

---

### Task 2: Dark-mode text-color audit sweep

**Files (modify — replace hardcoded light text tokens with theme equivalents):**
- `linguaquest/lib/features/auth/goal_setup_screen.dart:347`
- `linguaquest/lib/features/auth/login_screen.dart:75,125`
- `linguaquest/lib/features/auth/register_screen.dart:68,138`
- `linguaquest/lib/features/onboarding/onboarding_screen.dart:67`
- `linguaquest/lib/features/profile/public_profile_screen.dart:193`
- `linguaquest/lib/features/profile/study_plan_settings_screen.dart:954,966`
- `linguaquest/lib/features/quests/progress_analytics_screen.dart:330`
- `linguaquest/lib/features/reading/article_reader_screen.dart:197,214,259,372,506`
- `linguaquest/lib/features/reading/reading_list_screen.dart:156,219,247,253,292,299`
- `linguaquest/lib/features/wordbook/wordbook_screen.dart:498,555`
- Test: `linguaquest/test/dark_mode_test.dart`

**Interfaces:**
- Consumes: `Theme.of(context).colorScheme.onSurface` / `.onSurfaceVariant`.
- Produces: nothing new.

**The transformation (uniform, light-mode-safe):**

| Hardcoded token | Replace with |
|---|---|
| `AppTokens.textPrimaryLight` | `Theme.of(context).colorScheme.onSurface` |
| `AppTokens.textSecondaryLight` | `Theme.of(context).colorScheme.onSurfaceVariant` |
| `AppTokens.textHintLight` | `Theme.of(context).colorScheme.onSurfaceVariant` |

These are no-ops in light mode (the light `ColorScheme` defines `onSurface == textPrimaryLight`, `onSurfaceVariant == textSecondaryLight`; `textHintLight` becomes very slightly higher-contrast, which is acceptable). If a build method already has `final theme = Theme.of(context);`, use `theme.colorScheme.onSurfaceVariant`. If `context` is not in scope at a site, thread it in or read the color from an in-scope `theme`/`ColorScheme`.

**DO NOT change (these are white/brand text on fixed colored surfaces — correct in both modes):**
`app_button.dart:34`, `app_pill.dart:36`, `brand_hero_card.dart:38,44`, `recall_buttons.dart:90`, `wordbook_cover_card.dart:88,101,107,153`, `home_screen.dart:295`, `profile_screen.dart:228,235,240`, `about_screen.dart:70,77`, `target_word_detail_screen.dart:76`, and `wordbook_screen.dart:581` (a `(bg, fg)` chip tuple — leave it; only the standalone text color at 498 and the `: AppTokens.textHintLight` branch at 555 change).

- [ ] **Step 1: Write the failing test**

Add a new group at the end of `linguaquest/test/dark_mode_test.dart` (before the final closing `}` of `main`):

```dart
  group('Dark Mode — reading screens smoke', () {
    testWidgets('ReadingListScreen renders without exception in dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: const ReadingListScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
```

Add the import at the top of the file:

```dart
import 'package:linguaquest/features/reading/reading_list_screen.dart';
```

- [ ] **Step 2: Run test to verify it compiles + state of sweep**

Run: `flutter test test/dark_mode_test.dart -n "ReadingListScreen renders without exception in dark"`
Expected: PASS already (this is a smoke regression guard; the sweep is a visual contrast fix the smoke test guards against crashes, not the exact colors). If it fails to compile, fix the import. This test guards the sweep doesn't crash these screens.

> This task's substance is visual contrast, which a unit test can't meaningfully assert across 20 sites without brittleness. The smoke test guards against regressions; correctness is confirmed by `grep` (Step 4) + manual dark-mode review (Step 6).

- [ ] **Step 3: Apply the transformation at every FIX site**

Apply the mapping table above to each listed file:line. Canonical example — in `reading_list_screen.dart`, a line like:

```dart
                color: AppTokens.textSecondaryLight,
```

becomes:

```dart
                color: Theme.of(context).colorScheme.onSurfaceVariant,
```

For `wordbook_screen.dart:555`:

```dart
                  color: favorite ? AppTokens.amber : AppTokens.textHintLight,
```

becomes:

```dart
                  color: favorite
                      ? AppTokens.amber
                      : Theme.of(context).colorScheme.onSurfaceVariant,
```

Work through each file:line in the Files list. Leave every DO-NOT-change site untouched.

- [ ] **Step 4: Verify no FIX-site light tokens remain**

Run:
```bash
grep -rn "textPrimaryLight\|textSecondaryLight\|textHintLight" lib/features/auth lib/features/onboarding/onboarding_screen.dart lib/features/profile/public_profile_screen.dart lib/features/profile/study_plan_settings_screen.dart lib/features/quests/progress_analytics_screen.dart lib/features/reading lib/features/wordbook/wordbook_screen.dart
```
Expected: only `wordbook_screen.dart:581` (the kept chip tuple) may still appear; no other matches.

- [ ] **Step 5: Run tests + analyze**

Run: `flutter test test/dark_mode_test.dart`
Expected: PASS (all groups)
Run: `flutter analyze lib/features`
Expected: No new issues.

- [ ] **Step 6: Manual dark-mode review (note in commit)**

Confirm by running the app in dark mode (or reading the diffs) that login, register, onboarding, reading list, article reader, wordbook, public profile, study-plan settings, and analytics screens show legible secondary text. Record "manually reviewed in dark" in the commit body.

- [ ] **Step 7: Commit**

```bash
git add linguaquest/lib/features linguaquest/test/dark_mode_test.dart
git commit -m "fix(theme): route hardcoded light text colors through theme for dark legibility"
```

---

### Task 3: Language picker — readable text + restore coming-soon languages

**Files:**
- Modify: `linguaquest/lib/core/widgets/language_wordbook_picker.dart` (lines 35-50, 338-339, 361, 403, 409)
- Test: `linguaquest/test/core/widgets/language_wordbook_picker_test.dart`

**Interfaces:**
- Consumes: `Theme.of(context).colorScheme.onSurface` / `.onSurfaceVariant`.
- Produces: extended `kSupportedLanguages` (now 6 entries) and a `languageLabel` that resolves `en`/`es`/`fr`/`ms`. Other code already calls `languageLabel(code, l10n)` and iterates `kSupportedLanguages` — both keep working.

- [ ] **Step 1: Write the failing test**

The file `linguaquest/test/core/widgets/language_wordbook_picker_test.dart` has a `_harness({required AppState state})` that pumps an "Open" button which calls `showLanguageWordbookPicker`, plus a `_bothLangState()` builder. Reuse them. Add inside `group('LanguageWordbookPicker', ...)`:

```dart
    testWidgets('level-1 list shows coming-soon languages', (tester) async {
      await tester.pumpWidget(_harness(state: _bothLangState()));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('English'), findsOneWidget);
      expect(find.text('Spanish (Español)'), findsOneWidget);
      expect(find.text('French (Français)'), findsOneWidget);
      expect(find.text('Malay (Bahasa Melayu)'), findsOneWidget);
      // The four locked languages each render a "Coming Soon" pill.
      expect(find.text('Coming Soon'), findsNWidgets(4));
    });

    test('languageLabelRaw resolves coming-soon language codes', () {
      expect(languageLabelRaw('en'), 'English');
      expect(languageLabelRaw('es'), 'Spanish (Español)');
      expect(languageLabelRaw('fr'), 'French (Français)');
      expect(languageLabelRaw('ms'), 'Malay (Bahasa Melayu)');
    });
```

**Also update the existing test** in the same file titled `'shows Chinese (active) and Japanese (active) in language list'`: it currently asserts `expect(find.text('Coming Soon'), findsNothing);`. After adding the four locked languages that assertion is wrong — change it to:

```dart
      // zh + ja are active (no pill); the 4 future languages show Coming Soon.
      expect(find.text('Coming Soon'), findsNWidgets(4));
```

`languageLabelRaw` is a new top-level function added in Step 3 (no l10n needed, so the unit test can call it directly). It is already exported from the picker file the test imports.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/core/widgets/language_wordbook_picker_test.dart`
Expected: FAIL — coming-soon language rows don't exist yet; `languageLabelRaw` undefined.

- [ ] **Step 3: Implement**

In `linguaquest/lib/core/widgets/language_wordbook_picker.dart`, replace the `kSupportedLanguages` list (lines 35-38) with:

```dart
const List<SupportedLanguage> kSupportedLanguages = [
  SupportedLanguage(code: 'zh', hasBooks: true),
  SupportedLanguage(code: 'ja', hasBooks: true), // P2d: JLPT books shipped
  SupportedLanguage(code: 'en', hasBooks: false),
  SupportedLanguage(code: 'es', hasBooks: false),
  SupportedLanguage(code: 'fr', hasBooks: false),
  SupportedLanguage(code: 'ms', hasBooks: false),
];

/// English display label for coming-soon languages that have no l10n key yet.
/// Mirrors the labels used on the language map (`language_map_screen.dart`).
String languageLabelRaw(String code) {
  switch (code) {
    case 'en':
      return 'English';
    case 'es':
      return 'Spanish (Español)';
    case 'fr':
      return 'French (Français)';
    case 'ms':
      return 'Malay (Bahasa Melayu)';
    default:
      return code;
  }
}
```

Then update `languageLabel` (lines 41-50) so the default branch falls back to `languageLabelRaw`:

```dart
String languageLabel(String code, AppLocalizations l10n) {
  switch (code) {
    case 'zh':
      return l10n.pickerLanguageChinese;
    case 'ja':
      return l10n.pickerLanguageJapanese;
    default:
      return languageLabelRaw(code);
  }
}
```

Fix the `_LanguageRow` text color (lines 337-340). Replace:

```dart
                    color: isActive
                        ? AppTokens.textPrimaryLight
                        : AppTokens.textHintLight,
```

with:

```dart
                    color: isActive
                        ? Theme.of(context).colorScheme.onSurface
                        : Theme.of(context).colorScheme.onSurfaceVariant,
```

Fix the chevron color (line 361). Because the `Padding` is `const`, change it to non-const and use the theme. Replace lines 355-363:

```dart
          if (isActive && !isCurrent)
            const Padding(
              padding: EdgeInsets.only(left: AppTokens.s8),
              child: Icon(
                AppIcons.chevronRight,
                size: 20,
                color: AppTokens.textSecondaryLight,
              ),
            ),
```

with:

```dart
          if (isActive && !isCurrent)
            Padding(
              padding: const EdgeInsets.only(left: AppTokens.s8),
              child: Icon(
                AppIcons.chevronRight,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
```

Fix the empty-state colors in `_WordbookList` (lines 400-410). Replace the `Icon` color `AppTokens.textHintLight` (line 403) with `Theme.of(context).colorScheme.onSurfaceVariant`, and the `Text` style color `AppTokens.textSecondaryLight` (line 409) with `Theme.of(context).colorScheme.onSurfaceVariant`. The `const` on the `Icon` (line 400) must be dropped since the color is now non-const:

```dart
            Icon(
              AppIcons.menuBook,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              l10n.pickerComingSoon,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
```

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test test/core/widgets/language_wordbook_picker_test.dart`
Expected: PASS
Run: `flutter analyze lib/core/widgets/language_wordbook_picker.dart`
Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/core/widgets/language_wordbook_picker.dart linguaquest/test/core/widgets/language_wordbook_picker_test.dart
git commit -m "fix(picker): readable text in dark mode + restore coming-soon languages (en/es/fr/ms)"
```

---

### Task 4: Route "Choose Language" to the world map

**Files:**
- Modify: `linguaquest/lib/features/profile/profile_screen.dart:103`
- Modify: `linguaquest/lib/features/profile/settings_screen.dart:183`
- Test: `linguaquest/test/features/profile/` (add a small widget test, or extend an existing profile test)

**Interfaces:**
- Consumes: route `/language-map` (already registered in `app_router.dart:222`) via `context.push`.
- Produces: behavioural change — the two language rows open the map instead of the bottom-sheet picker. The map then opens the wordbook step via `showLanguageWordbookPicker(context, initialLanguage: code)`.

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/features/profile/choose_language_routes_to_map_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards that the Profile + Settings "Choose Language" rows navigate to the
/// language map route, not the bottom-sheet picker.
void main() {
  test('profile_screen Choose Language pushes /language-map', () {
    final src = File(
      'lib/features/profile/profile_screen.dart',
    ).readAsStringSync();
    // The language row's onTap must reference the map route.
    expect(src.contains("context.push('/language-map')"), isTrue);
  });

  test('settings_screen Learning Language pushes /language-map', () {
    final src = File(
      'lib/features/profile/settings_screen.dart',
    ).readAsStringSync();
    expect(src.contains("context.push('/language-map')"), isTrue);
  });
}
```

Add `import 'dart:io';` at the top.

> This is a source-level guard (cheap, deterministic) because a full nav test would need a bootstrapped app + flutter_map tiles. It directly encodes the requirement.

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/profile/choose_language_routes_to_map_test.dart`
Expected: FAIL — both rows currently call `showLanguageWordbookPicker(context)`.

- [ ] **Step 3: Implement**

In `linguaquest/lib/features/profile/profile_screen.dart`, change line 103 from:

```dart
              onTap: () => showLanguageWordbookPicker(context),
```

to:

```dart
              onTap: () => context.push('/language-map'),
```

In `linguaquest/lib/features/profile/settings_screen.dart`, change line 183 (the `AppCard(onTap: ...)` in `_LearningLanguageSetting`) from:

```dart
      onTap: () => showLanguageWordbookPicker(context),
```

to:

```dart
      onTap: () => context.push('/language-map'),
```

Ensure `go_router` is imported in both files (profile_screen already uses `context.push` elsewhere; settings_screen — add `import 'package:go_router/go_router.dart';` if analyze reports `push` undefined). Remove the now-unused `showLanguageWordbookPicker` import from a file ONLY if analyze flags it as unused (other rows in that file may still use it).

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test test/features/profile/choose_language_routes_to_map_test.dart`
Expected: PASS
Run: `flutter analyze lib/features/profile/profile_screen.dart lib/features/profile/settings_screen.dart`
Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/features/profile/profile_screen.dart linguaquest/lib/features/profile/settings_screen.dart linguaquest/test/features/profile/choose_language_routes_to_map_test.dart
git commit -m "fix(language): Choose Language opens the world map (restores map + locked languages)"
```

---

### Task 5: Server serves JLPT wordbooks

**Files:**
- Create: `server/data/wordbooks_jlpt.json` (generated from client JLPT assets)
- Modify: `server/lib/src/routes.dart:1530-1547` (`_readWordBooks` + `_wordBookDataFile`)
- Test: `server/test/wordbook_data_test.dart` (new)

**Interfaces:**
- Consumes: `server/data/wordbooks_p0.json` (existing, 6 HSK books), `server/data/wordbooks_jlpt.json` (new, 5 JLPT books).
- Produces: `_readWordBooks()` now returns 11 books; `/wordbooks`, `/wordbooks/<id>`, `/words` include JLPT. `study_plan_policy.allowedWordBookIds` already lists `jlpt_n1..n5`. Client `WordBook.fromJson` defaults missing `language` to `zh` (lesson.dart:407); JLPT books carry `language: 'ja'`.

- [ ] **Step 1: Generate the JLPT server data file**

From `/Users/lanyichen/Codes/Mobile/ASM2`, run:

```bash
python3 -c "
import json
books=[]
for lvl in ['n5','n4','n3','n2','n1']:
    books.append(json.load(open(f'linguaquest/lib/assets/data/wordbook_jlpt_{lvl}.json')))
json.dump(books, open('server/data/wordbooks_jlpt.json','w'), ensure_ascii=False)
print('wrote', len(books), 'books;', sum(len(b['words']) for b in books), 'words')
"
```
Expected output: `wrote 5 books; <N> words` (N in the low thousands).

- [ ] **Step 2: Write the failing test**

Create `server/test/wordbook_data_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('JLPT server data file exists and holds 5 ja books', () {
    final file = File('data/wordbooks_jlpt.json');
    expect(file.existsSync(), isTrue,
        reason: 'run the generator step from the repo root');
    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());
    final books = (decoded as List).cast<Map<String, dynamic>>();
    expect(books.length, 5);
    expect(books.map((b) => b['id']).toSet(),
        {'jlpt_n5', 'jlpt_n4', 'jlpt_n3', 'jlpt_n2', 'jlpt_n1'});
    for (final b in books) {
      expect(b['language'], 'ja');
      expect(b['words'], isA<List>());
    }
  });
}
```

- [ ] **Step 3: Run test to verify current state**

Run (from `server/`): `dart test test/wordbook_data_test.dart`
Expected: PASS for the data-file existence test (Step 1 created it). This test guards the data file; the loader wiring is covered by Step 5. If the file is missing it FAILS — re-run Step 1.

- [ ] **Step 4: Implement the loader change**

In `server/lib/src/routes.dart`, replace `_readWordBooks` and `_wordBookDataFile` (lines 1530-1547) with:

```dart
Future<List<Map<String, dynamic>>> _readWordBooks() async {
  final books = <Map<String, dynamic>>[];
  for (final file in _wordBookDataFiles()) {
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! List) {
      throw FormatException('${file.path} must be a list');
    }
    for (final item in decoded.whereType<Map>()) {
      books.add(Map<String, dynamic>.from(item));
    }
  }
  return books;
}

// ponytail: JLPT data is duplicated from the client assets into server/data/.
// If this duplication ever drifts, regenerate wordbooks_jlpt.json from
// linguaquest/lib/assets/data/wordbook_jlpt_*.json.
List<File> _wordBookDataFiles() {
  final files = <File>[];
  for (final name in const ['wordbooks_p0.json', 'wordbooks_jlpt.json']) {
    final serverRelative = File('data/$name');
    final repoRelative = File('server/data/$name');
    if (serverRelative.existsSync()) {
      files.add(serverRelative);
    } else if (repoRelative.existsSync()) {
      files.add(repoRelative);
    }
  }
  if (files.isEmpty) {
    files.add(File('data/wordbooks_p0.json'));
  }
  return files;
}
```

- [ ] **Step 5: Write + run a loader integration test**

Append to `server/test/wordbook_data_test.dart` a test that boots the router and hits `/wordbooks`. Model it on the existing `server/test/routes_test.dart` harness (reuse its imports and `createHandler`/test-server setup verbatim — read that file and copy its boot pattern). The assertion:

```dart
  test('GET /wordbooks includes HSK and JLPT books', () async {
    // ... boot the handler exactly as routes_test.dart does ...
    final response = await _get(handler, '/wordbooks');
    expect(response.statusCode, 200);
    final ids = (jsonDecode(response.body) as List)
        .map((b) => (b as Map)['id'])
        .toSet();
    expect(ids, containsAll(<String>['hsk1', 'jlpt_n5', 'jlpt_n1']));
  });
```

If booting the full handler in a unit test is heavy (needs a DB), instead unit-test `_readWordBooks` indirectly: since it's a top-level private function, add the integration test only if `routes_test.dart` already boots without a live DB; otherwise rely on the data-file test (Step 2) plus a manual curl in Step 6. Pick the form that runs green in this repo.

Run (from `server/`): `dart test test/wordbook_data_test.dart`
Expected: PASS.

- [ ] **Step 6: Manual server verification**

Start the server (from `server/`, the project's usual run command) and run:
```bash
curl -s localhost:8080/wordbooks | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d), 'books'); print(sorted(b['id'] for b in d))"
curl -s "localhost:8080/words?wordBookId=jlpt_n5" | python3 -c "import sys,json; print(len(json.load(sys.stdin)), 'ja words')"
```
Expected: 11 books incl. `jlpt_n5..n1`; non-zero Japanese words. Paste the output into the commit body.

- [ ] **Step 7: Analyze + commit**

Run (from `server/`): `dart analyze lib/src/routes.dart`
Expected: No issues.

```bash
git add server/data/wordbooks_jlpt.json server/lib/src/routes.dart server/test/wordbook_data_test.dart
git commit -m "feat(server): serve JLPT N5-N1 wordbooks so Japanese is selectable in server mode"
```

---

### Task 6: Remove duplicate community post button

**Files:**
- Modify: `linguaquest/lib/features/discover/community_screen.dart:132-147`
- Test: `linguaquest/test/features/discover/` (existing community test, or new guard)

**Interfaces:**
- Consumes: nothing new.
- Produces: the screen keeps only the FAB (`community_screen.dart:122-126`) for composing a post.

- [ ] **Step 1: Write the failing test**

Create `linguaquest/test/features/discover/community_single_compose_test.dart`:

```dart
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Guards that the community screen exposes exactly one compose entry (the FAB),
/// not the redundant top "Share an update" outlined button.
void main() {
  test('community screen has no top Share-an-update button', () {
    final src = File(
      'lib/features/discover/community_screen.dart',
    ).readAsStringSync();
    expect(src.contains('communityShareUpdate'), isFalse);
    // FAB compose entry remains.
    expect(src.contains("context.push('/forum/compose')"), isTrue);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/discover/community_single_compose_test.dart`
Expected: FAIL — `communityShareUpdate` still referenced at line ~145.

- [ ] **Step 3: Implement**

In `linguaquest/lib/features/discover/community_screen.dart`, delete the "Share an update" quick entry block (the comment line, the `Padding` wrapping the `OutlinedButton.icon`, and the trailing `SizedBox`). Concretely remove lines 132-147:

```dart
            // ── "Share an update" quick entry ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTokens.s20,
                AppTokens.s12,
                AppTokens.s20,
                0,
              ),
              child: OutlinedButton.icon(
                onPressed: () => context.push('/forum/compose'),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(l10n.communityShareUpdate),
              ),
            ),
            const SizedBox(height: AppTokens.s12),
```

The next child after deletion is the `// ── Filter chip row ──` `SizedBox`. Verify the `Column`'s `children:` list is still well-formed (the element before was `crossAxisAlignment`/start of children).

- [ ] **Step 4: Run tests + analyze**

Run: `flutter test test/features/discover/community_single_compose_test.dart`
Expected: PASS
Run: `flutter analyze lib/features/discover/community_screen.dart`
Expected: No issues (no unused-import for `OutlinedButton`; `AppTokens`/`context`/`l10n` still used elsewhere in the file).

If a pre-existing community widget test referenced the removed button, update it to assert the FAB instead. Run the discover test directory to confirm:
Run: `flutter test test/features/discover/`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/features/discover/community_screen.dart linguaquest/test/features/discover/community_single_compose_test.dart
git commit -m "fix(community): remove redundant top Share-an-update button (keep FAB)"
```

---

### Task 7: Translate Lucky Draw prize names to English

**Files:**
- Modify: `server/lib/src/lottery_policy.dart:5-141` (`lotteryPrizeSeed` — `name` + `description`)
- Modify: `linguaquest/lib/data/repositories/mock_repositories.dart:710-846` (`_mockPrizePool` — `name` + `description`)
- Test: `server/test/lottery_policy_test.dart`

**Interfaces:**
- Consumes: nothing new.
- Produces: English prize names; ids/categories/rarities/probabilities/fragmentValues unchanged. Server upserts the new names on startup (`_seedLotteryPrizes`, `ON CONFLICT DO UPDATE`).

**Canonical translation table (apply identically to both files):**

| id | name (EN) | description (EN) |
|---|---|---|
| avatar-frame-starry | Star Trail Avatar Frame | A star-trail decoration around your avatar. Cosmetic only — no learning-score boost. |
| avatar-frame-ember | Ember Flame Avatar Frame | A burning-ember style avatar frame. Decorative only — does not affect learning fairness. |
| profile-bg-aurora | Aurora Home Background | An aurora backdrop for your profile space. Decorative only — does not affect learning fairness. |
| profile-bg-dawn-harbor | Dawn Harbor Background | A dawn harbor scene background. Display decoration only. |
| badge-focus-sprinter | Focus Sprint Badge | A badge shown on your study page. Honorary decoration only. |
| badge-night-owl | Night Owl Badge | A badge for late-night learners. Does not raise quiz scores. |
| badge-anniversary-lantern | Anniversary Lantern Badge | A limited event badge. Honorary keepsake only. |
| title-arena-scout | Training Ground Scout Title | A training-ground title. Does not raise quiz scores. |
| title-lexicon-keeper | Vocabulary Guardian Title | A title for dedicated vocabulary learners. Does not affect learning fairness. |
| title-dawn-voyager | Dawn Voyager Title | A rare explorer title. Decorative only. |
| card-skin-mint | Mint Card Skin | A word-card visual skin. Does not change the memory algorithm. |
| card-skin-sakura | Sakura Card Skin | A sakura-style card skin. Does not change the memory algorithm. |
| card-skin-midnight | Midnight Card Skin | A dark midnight-style card skin. Does not affect learning results. |
| card-skin-citrus | Citrus Card Skin | A fresh citrus-toned card skin. Visual decoration only. |
| comfort-star-fragments | Stardust Fragment | A consolation reward you can accumulate to redeem decorative assets. |

- [ ] **Step 1: Write the failing test**

Add to `server/test/lottery_policy_test.dart` (inside `main`, new `test(...)`):

```dart
  test('lottery prize seed names and descriptions are English (no CJK)', () {
    final cjk = RegExp(r'[一-鿿]');
    for (final prize in lotteryPrizeSeed) {
      expect(cjk.hasMatch(prize['name'].toString()), isFalse,
          reason: 'name still has CJK: ${prize['name']}');
      expect(cjk.hasMatch(prize['description'].toString()), isFalse,
          reason: 'description still has CJK: ${prize['id']}');
    }
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run (from `server/`): `dart test test/lottery_policy_test.dart -N "lottery prize seed names and descriptions are English"`
Expected: FAIL — names are still Chinese.

- [ ] **Step 3: Implement — server seed**

In `server/lib/src/lottery_policy.dart`, replace each `'name'` and `'description'` value in `lotteryPrizeSeed` (lines 5-141) with the English from the table above, matching by `id`. Leave `id`/`category`/`rarity`/`probability`/`fragmentValue` untouched.

- [ ] **Step 4: Implement — client mock**

In `linguaquest/lib/data/repositories/mock_repositories.dart`, replace each `name:` and `description:` value in `_mockPrizePool` (lines 710-846) with the SAME English strings from the table, matching by `id`.

- [ ] **Step 5: Run tests + analyze**

Run (from `server/`): `dart test test/lottery_policy_test.dart`
Expected: PASS (the new test + the existing seed-integrity test).
Run: `grep -n '[一-鿿]' server/lib/src/lottery_policy.dart linguaquest/lib/data/repositories/mock_repositories.dart`
Expected: no matches in the prize blocks (the only remaining CJK, if any, is unrelated to prizes — confirm none are in `lotteryPrizeSeed`/`_mockPrizePool`).
Run (from `linguaquest/`): `flutter analyze lib/data/repositories/mock_repositories.dart`
Expected: No issues.

- [ ] **Step 6: Manual server verification**

Restart the server and run:
```bash
curl -s localhost:8080/lottery/prizes | python3 -c "import sys,json; d=json.load(sys.stdin); print([p['name'] for p in d['prizes']])"
```
Expected: all 15 names in English. Paste into the commit body.

- [ ] **Step 7: Commit**

```bash
git add server/lib/src/lottery_policy.dart server/test/lottery_policy_test.dart linguaquest/lib/data/repositories/mock_repositories.dart
git commit -m "fix(lottery): translate prize names + descriptions to English (server seed + mock)"
```

---

## Final verification (after all tasks)

- [ ] From `linguaquest/`: `flutter analyze` → no issues; `flutter test` → all green.
- [ ] From `server/`: `dart analyze` → no issues; `dart test` → all green.
- [ ] **Launch on the connected Android device/emulator** (the running adb device — confirm with `flutter devices`, then `flutter run -d <device>` from `linguaquest/`, pointing at the backend via `--dart-define=API_BASE_URL=<url>` so server-backed fixes (JLPT books, English prizes) are exercised).
- [ ] Manual smoke on device in dark mode: shell + all tabs dark and legible; Profile → Choose Language opens the world map; tap Japan → N5–N1 listed; Community shows one compose entry (FAB); Lucky Draw prize names in English.

## Self-review notes
- Spec §1 (dark mode): Tasks 1 + 2 (toggle/persistence already shipped).
- Spec §2a (map): Task 4. §2b (readability + coming-soon langs): Task 3. §2c (JLPT server): Task 5.
- Spec §4 (community dup button): Task 6.
- Spec §5 (lottery EN): Task 7.
- Deferred (Cycle 2): Passage Cloze, Listening Sprint, Confusable Words, Sentence Generation.
