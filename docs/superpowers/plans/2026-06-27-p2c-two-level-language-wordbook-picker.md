# P2c: Two-Level Language → Wordbook Picker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a reusable `LanguageWordbookPicker` widget (two-level: choose language → choose wordbook) and wire it into all existing entry points (Goal Setup, Profile, Study Plan Settings, Home) replacing single-level wordbook selection.

**Architecture:** A standalone bottom-sheet widget `LanguageWordbookPicker` that renders two animated levels — Level 1 lists supported languages (Chinese active; Japanese coming-soon; others coming-soon), Level 2 lists that language's wordbooks from `state.wordBooks`. Selecting a (language, wordbook) pair calls existing controller methods: `switchWordBook(wordBookId)` for same-language switches; for cross-language switches it first updates `currentLanguage` in state then calls `switchWordBook`. Language availability is determined by a data-driven constant map that P2d can extend simply by adding entries. All Cozy Quest primitives are used (AppCard, AppPill, AppTokens). i18n keys are added to en/zh/ms ARB files, `flutter gen-l10n` is run after.

**Tech Stack:** Flutter/Dart, Riverpod (`ref.read(appControllerProvider.notifier)`), GoRouter (no changes), `AppLocalizations`, existing `AppCard`/`AppPill`/`AppTokens` from Cozy Quest system, `flutter_test` + `mocktail` for widget tests.

## Global Constraints

- Run all commands from `linguaquest/` directory (not repo root)
- `flutter analyze` must be clean (no warnings/errors) before each commit
- `flutter test` full suite must pass before each commit
- i18n is UNFROZEN for P2c — add keys to en/zh/ms ARB files; run `flutter gen-l10n` after any ARB change; commit generated files
- Do NOT add Japanese wordbook data (that is P2d)
- Do NOT change language map routing (that is P2e)
- Japanese language entry MUST appear in the picker but be marked "coming soon" and non-selectable
- Selecting a wordbook must call `switchWordBook(wordBookId)` on the existing controller — do NOT wipe other scopes
- Use `AppCard`, `AppPill`, `AppTokens.*` — no hard-coded colors or spacing
- Commit message style: `feat(multilang): <description> (P2c)` — NO Co-Authored-By trailer

---

## File Map

**New files:**
- `linguaquest/lib/core/widgets/language_wordbook_picker.dart` — the reusable two-level picker widget + bottom-sheet launcher
- `linguaquest/test/core/widgets/language_wordbook_picker_test.dart` — widget tests for the picker

**Modified files:**
- `linguaquest/lib/l10n/app_en.arb` — new i18n keys
- `linguaquest/lib/l10n/app_zh.arb` — new i18n keys (Chinese translations)
- `linguaquest/lib/l10n/app_ms.arb` — new i18n keys (Malay translations)
- `linguaquest/lib/l10n/generated/app_localizations.dart` — regenerated (do not edit by hand)
- `linguaquest/lib/l10n/generated/app_localizations_en.dart` — regenerated
- `linguaquest/lib/l10n/generated/app_localizations_zh.dart` — regenerated
- `linguaquest/lib/l10n/generated/app_localizations_ms.dart` — regenerated
- `linguaquest/lib/features/auth/goal_setup_screen.dart` — replace single-level wordbook with two-level picker
- `linguaquest/lib/features/profile/study_plan_settings_screen.dart` — replace `_StudyBookSelector` invocation with two-level picker flow
- `linguaquest/lib/features/home/home_screen.dart` — make `_DailyFocusHeader` target pill tappable to open picker
- `linguaquest/lib/features/profile/profile_screen.dart` — replace/extend `_LanguageSettingsItem` to open two-level picker

---

## Task 1: i18n Keys for the Picker

**Files:**
- Modify: `linguaquest/lib/l10n/app_en.arb`
- Modify: `linguaquest/lib/l10n/app_zh.arb`
- Modify: `linguaquest/lib/l10n/app_ms.arb`
- Modify: `linguaquest/lib/l10n/generated/` (regenerated)

**Interfaces:**
- Produces: `l10n.pickerChooseLanguage`, `l10n.pickerChooseWordbook`, `l10n.pickerLanguageChinese`, `l10n.pickerLanguageJapanese`, `l10n.pickerComingSoon`, `l10n.pickerCurrentBadge`

- [ ] **Step 1: Add keys to app_en.arb**

Open `linguaquest/lib/l10n/app_en.arb`. Find the block near line 660 (`"wordbookSwitch": "Switch Wordbook"`). Insert the following keys immediately after `"wordbookSwitchFailed"`:

```json
  "pickerChooseLanguage": "Choose Language",
  "pickerChooseWordbook": "Choose Wordbook",
  "pickerLanguageChinese": "Chinese (中文)",
  "pickerLanguageJapanese": "Japanese (日本語)",
  "pickerComingSoon": "Coming Soon",
  "pickerCurrentBadge": "Current",
  "pickerSwitchSuccess": "Switched to {wordbook}",
  "@pickerSwitchSuccess": {
    "placeholders": {
      "wordbook": { "type": "String" }
    }
  },
  "pickerSwitchFailed": "Unable to switch wordbook right now",
```

- [ ] **Step 2: Add keys to app_zh.arb**

Open `linguaquest/lib/l10n/app_zh.arb`. Find the same location (near `"wordbookSwitchFailed"`). Insert:

```json
  "pickerChooseLanguage": "选择语言",
  "pickerChooseWordbook": "选择词书",
  "pickerLanguageChinese": "中文",
  "pickerLanguageJapanese": "日语",
  "pickerComingSoon": "即将上线",
  "pickerCurrentBadge": "当前",
  "pickerSwitchSuccess": "已切换到{wordbook}",
  "@pickerSwitchSuccess": {
    "placeholders": {
      "wordbook": { "type": "String" }
    }
  },
  "pickerSwitchFailed": "暂时无法切换词书",
```

- [ ] **Step 3: Add keys to app_ms.arb**

Open `linguaquest/lib/l10n/app_ms.arb`. Find the same location. Insert:

```json
  "pickerChooseLanguage": "Pilih Bahasa",
  "pickerChooseWordbook": "Pilih Buku Perkataan",
  "pickerLanguageChinese": "Bahasa Cina (中文)",
  "pickerLanguageJapanese": "Bahasa Jepun (日本語)",
  "pickerComingSoon": "Akan Datang",
  "pickerCurrentBadge": "Semasa",
  "pickerSwitchSuccess": "Ditukar kepada {wordbook}",
  "@pickerSwitchSuccess": {
    "placeholders": {
      "wordbook": { "type": "String" }
    }
  },
  "pickerSwitchFailed": "Tidak dapat menukar buku perkataan sekarang",
```

- [ ] **Step 4: Regenerate localizations**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter gen-l10n
```

Expected output: no errors; generated files updated in `lib/l10n/generated/`.

- [ ] **Step 5: Verify analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && git add lib/l10n/app_en.arb lib/l10n/app_zh.arb lib/l10n/app_ms.arb lib/l10n/generated/
git commit -m "feat(i18n): add language/wordbook picker keys (P2c)"
```

---

## Task 2: LanguageWordbookPicker Widget

**Files:**
- Create: `linguaquest/lib/core/widgets/language_wordbook_picker.dart`
- Test: `linguaquest/test/core/widgets/language_wordbook_picker_test.dart`

**Interfaces:**
- Consumes:
  - `AppCard`, `AppPill(variant: PillVariant.*)` from `core/widgets/`
  - `AppTokens.*` from `core/theme/app_tokens.dart`
  - `AppLocalizations.of(context)` for labels
  - `WordBook` model from `data/models/lesson.dart`
  - `state.wordBooks` (filtered by language), `state.currentWordBookId`, `state.currentLanguage`
  - `ref.read(appControllerProvider.notifier).switchWordBook(String wordBookId)`
- Produces:
  - `showLanguageWordbookPicker(BuildContext context, WidgetRef ref)` — top-level function that opens the picker as a `showModalBottomSheet`
  - `kSupportedLanguages` — `const List<_LanguageEntry>` (data-driven, P2d adds Japanese by changing `hasBooks: true`)

- [ ] **Step 1: Write failing widget test first**

Create `linguaquest/test/core/widgets/language_wordbook_picker_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/core/widgets/language_wordbook_picker.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

WordBook _fakeBook(String id, {String language = 'zh'}) {
  final now = DateTime.now().toUtc();
  return WordBook(
    id: id,
    title: id.toUpperCase(),
    category: 'exam',
    examType: id,
    coverUrl: '',
    totalWords: 10,
    includedWords: 10,
    description: '',
    wordIds: const [],
    createdAt: now,
    words: const [],
    language: language,
  );
}

Widget _wrap(Widget child, {AppState? initialState}) {
  final state = initialState ??
      AppState.initial().copyWith(
        wordBooks: [
          _fakeBook('hsk1'),
          _fakeBook('hsk2'),
          _fakeBook('hsk3'),
          _fakeBook('hsk4'),
          _fakeBook('hsk5'),
          _fakeBook('hsk6'),
        ],
        currentWordBookId: 'hsk1',
        currentLanguage: 'zh',
      );
  return ProviderScope(
    overrides: [
      appControllerProvider.overrideWith((_) => _FakeNotifier(state)),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: child),
    ),
  );
}

// Fake notifier that records calls to switchWordBook
class _FakeNotifier extends AppController {
  _FakeNotifier(this._state);
  final AppState _state;

  @override
  AppState build() => _state;

  final List<String> switchCalls = [];

  @override
  Future<bool> switchWordBook(String wordBookId) async {
    switchCalls.add(wordBookId);
    return true;
  }
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('LanguageWordbookPicker', () {
    testWidgets('shows Chinese (active) and Japanese (coming-soon)', (tester) async {
      late _FakeNotifier notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith((ref) {
              notifier = _FakeNotifier(
                AppState.initial().copyWith(
                  wordBooks: [
                    _fakeBook('hsk1'),
                    _fakeBook('hsk2'),
                    _fakeBook('hsk3'),
                  ],
                  currentWordBookId: 'hsk1',
                  currentLanguage: 'zh',
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showLanguageWordbookPicker(ctx, _ProviderRef(ctx)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open picker via button
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Level 1: Chinese row appears
      expect(find.text('Chinese (中文)'), findsOneWidget);
      // Level 1: Japanese row appears with Coming Soon pill
      expect(find.text('Japanese (日本語)'), findsOneWidget);
      expect(find.text('Coming Soon'), findsWidgets);
    });

    testWidgets('selecting Chinese language shows hsk wordbooks', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showLanguageWordbookPicker(ctx, _ProviderRef(ctx)),
            child: const Text('Open'),
          ),
        ),
        initialState: AppState.initial().copyWith(
          wordBooks: [
            _fakeBook('hsk1'),
            _fakeBook('hsk2'),
            _fakeBook('hsk3'),
            _fakeBook('hsk4'),
            _fakeBook('hsk5'),
            _fakeBook('hsk6'),
          ],
          currentWordBookId: 'hsk1',
          currentLanguage: 'zh',
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap Chinese language
      await tester.tap(find.text('Chinese (中文)'));
      await tester.pumpAndSettle();

      // Level 2: wordbook list appears
      expect(find.text('HSK1'), findsOneWidget);
      expect(find.text('HSK6'), findsOneWidget);
    });

    testWidgets('Japanese shows coming-soon, not wordbook list', (tester) async {
      await tester.pumpWidget(_wrap(
        Builder(
          builder: (ctx) => ElevatedButton(
            onPressed: () => showLanguageWordbookPicker(ctx, _ProviderRef(ctx)),
            child: const Text('Open'),
          ),
        ),
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Tap Japanese row — should not crash and should show coming-soon text
      await tester.tap(find.text('Japanese (日本語)'));
      await tester.pumpAndSettle();

      // No hsk books should appear
      expect(find.text('HSK1'), findsNothing);
      // Coming Soon still visible
      expect(find.text('Coming Soon'), findsWidgets);
    });

    testWidgets('selecting a wordbook calls switchWordBook and does NOT wipe other scopes', (tester) async {
      late _FakeNotifier notifier;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith((ref) {
              notifier = _FakeNotifier(
                AppState.initial().copyWith(
                  wordBooks: [
                    _fakeBook('hsk1'),
                    _fakeBook('hsk2'),
                  ],
                  currentWordBookId: 'hsk1',
                  currentLanguage: 'zh',
                ),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => showLanguageWordbookPicker(ctx, _ProviderRef(ctx)),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Go to Level 2 (tap Chinese)
      await tester.tap(find.text('Chinese (中文)'));
      await tester.pumpAndSettle();

      // Tap hsk2
      await tester.tap(find.text('HSK2'));
      await tester.pumpAndSettle();

      // switchWordBook called with hsk2
      expect(notifier.switchCalls, contains('hsk2'));
    });
  });
}

// Helper to extract WidgetRef from a BuildContext in tests
// In real usage, caller passes the ref directly from ConsumerWidget.
class _ProviderRef {
  _ProviderRef(this.context);
  final BuildContext context;
}
```

- [ ] **Step 2: Run test to confirm it fails (file not found)**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test test/core/widgets/language_wordbook_picker_test.dart 2>&1 | head -30
```

Expected: compilation error — `language_wordbook_picker.dart` not found.

- [ ] **Step 3: Create the picker widget**

Create `linguaquest/lib/core/widgets/language_wordbook_picker.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_pill.dart';

// ---------------------------------------------------------------------------
// Data-driven language catalog
// ---------------------------------------------------------------------------

/// One entry per supported learning language.
/// Set [hasBooks] to true when wordbook data for the language is shipped
/// (P2d will set ja to hasBooks: true).
class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.hasBooks,
  });

  final String code;
  final bool hasBooks;
}

/// Add entries here to support new languages.
/// When P2d ships Japanese data, change ja's hasBooks to true.
const List<SupportedLanguage> kSupportedLanguages = [
  SupportedLanguage(code: 'zh', hasBooks: true),
  SupportedLanguage(code: 'ja', hasBooks: false),
];

/// Returns a human-readable label for a language code.
/// Uses ARB keys so the label is localized.
String languageLabel(String code, AppLocalizations l10n) {
  switch (code) {
    case 'zh':
      return l10n.pickerLanguageChinese;
    case 'ja':
      return l10n.pickerLanguageJapanese;
    default:
      return code;
  }
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Opens the two-level language → wordbook picker as a modal bottom sheet.
///
/// [ref] is the Riverpod [WidgetRef] from the calling ConsumerWidget.
Future<void> showLanguageWordbookPicker(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => ProviderScope.containerOf(context).let(
      (container) => UncontrolledProviderScope(
        container: container,
        child: _LanguageWordbookPickerSheet(
          onDismiss: () => Navigator.of(sheetCtx).pop(),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Internal sheet widget
// ---------------------------------------------------------------------------

class _LanguageWordbookPickerSheet extends ConsumerStatefulWidget {
  const _LanguageWordbookPickerSheet({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  ConsumerState<_LanguageWordbookPickerSheet> createState() =>
      _LanguageWordbookPickerSheetState();
}

class _LanguageWordbookPickerSheetState
    extends ConsumerState<_LanguageWordbookPickerSheet> {
  /// null = showing Level 1 (language list)
  /// non-null = showing Level 2 (wordbook list for that language)
  String? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.radiusSheet),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.s12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.hairline,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
              ),
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  AppTokens.s12,
                  AppTokens.s8,
                  AppTokens.s8,
                ),
                child: Row(
                  children: [
                    if (_selectedLanguage != null)
                      IconButton(
                        icon: const Icon(AppIcons.arrowBack),
                        onPressed: () =>
                            setState(() => _selectedLanguage = null),
                        tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                      ),
                    Expanded(
                      child: Text(
                        _selectedLanguage == null
                            ? l10n.pickerChooseLanguage
                            : l10n.pickerChooseWordbook,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: widget.onDismiss,
                      tooltip: MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: AppTokens.medium,
                  ),
                  child: _selectedLanguage == null
                      ? _LanguageList(
                          key: const ValueKey('lang-list'),
                          currentLanguage: state.currentLanguage,
                          scrollController: scrollController,
                          l10n: l10n,
                          onLanguageSelected: (code) {
                            final entry = kSupportedLanguages
                                .firstWhere((e) => e.code == code);
                            if (entry.hasBooks) {
                              setState(() => _selectedLanguage = code);
                            }
                            // If !hasBooks: tap is a no-op (coming-soon shown inline)
                          },
                        )
                      : _WordbookList(
                          key: ValueKey('book-list-$_selectedLanguage'),
                          language: _selectedLanguage!,
                          books: state.wordBooks
                              .where((b) => b.language == _selectedLanguage)
                              .toList(),
                          currentWordBookId: state.currentWordBookId,
                          scrollController: scrollController,
                          l10n: l10n,
                          onBookSelected: (bookId) async {
                            final notifier =
                                ref.read(appControllerProvider.notifier);
                            final ok = await notifier.switchWordBook(bookId);
                            if (!mounted) return;
                            if (ok) {
                              widget.onDismiss();
                              final book = state.wordBooks
                                  .where((b) => b.id == bookId)
                                  .firstOrNull;
                              final label = book?.nameFor(
                                    Localizations.localeOf(context)
                                        .languageCode,
                                  ) ??
                                  bookId;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      l10n.pickerSwitchSuccess(label)),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.pickerSwitchFailed),
                                ),
                              );
                            }
                          },
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Level 1: Language list
// ---------------------------------------------------------------------------

class _LanguageList extends StatelessWidget {
  const _LanguageList({
    super.key,
    required this.currentLanguage,
    required this.scrollController,
    required this.l10n,
    required this.onLanguageSelected,
  });

  final String currentLanguage;
  final ScrollController scrollController;
  final AppLocalizations l10n;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTokens.s16),
      itemCount: kSupportedLanguages.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s8),
      itemBuilder: (_, index) {
        final lang = kSupportedLanguages[index];
        final isCurrent = lang.code == currentLanguage;
        final isActive = lang.hasBooks;
        return _LanguageRow(
          code: lang.code,
          label: languageLabel(lang.code, l10n),
          isCurrent: isCurrent,
          isActive: isActive,
          comingSoonLabel: l10n.pickerComingSoon,
          currentLabel: l10n.pickerCurrentBadge,
          onTap: isActive ? () => onLanguageSelected(lang.code) : null,
        );
      },
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.code,
    required this.label,
    required this.isCurrent,
    required this.isActive,
    required this.comingSoonLabel,
    required this.currentLabel,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool isCurrent;
  final bool isActive;
  final String comingSoonLabel;
  final String currentLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? AppTokens.textPrimaryLight
                      : AppTokens.textHintLight,
                ),
          ),
          const Spacer(),
          if (isCurrent)
            AppPill(
              label: currentLabel,
              variant: PillVariant.success,
              icon: AppIcons.checkCircle,
            )
          else if (!isActive)
            AppPill(
              label: comingSoonLabel,
              variant: PillVariant.neutral,
            ),
          if (isActive && !isCurrent)
            const Icon(
              AppIcons.chevronRight,
              size: 20,
              color: AppTokens.textSecondaryLight,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level 2: Wordbook list
// ---------------------------------------------------------------------------

class _WordbookList extends StatelessWidget {
  const _WordbookList({
    super.key,
    required this.language,
    required this.books,
    required this.currentWordBookId,
    required this.scrollController,
    required this.l10n,
    required this.onBookSelected,
  });

  final String language;
  final List<WordBook> books;
  final String currentWordBookId;
  final ScrollController scrollController;
  final AppLocalizations l10n;
  final ValueChanged<String> onBookSelected;

  @override
  Widget build(BuildContext context) {
    final localeCode =
        Localizations.localeOf(context).languageCode;

    // If no books for this language (e.g., ja before P2d), show coming-soon
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(AppIcons.menuBook, size: 48, color: AppTokens.textHintLight),
            const SizedBox(height: AppTokens.s12),
            Text(
              l10n.pickerComingSoon,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTokens.textSecondaryLight,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTokens.s16),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppTokens.s8),
      itemBuilder: (_, index) {
        final book = books[index];
        final isCurrent = book.id == currentWordBookId;
        return _WordbookRow(
          book: book,
          localeCode: localeCode,
          isCurrent: isCurrent,
          currentLabel: l10n.pickerCurrentBadge,
          onTap: isCurrent ? null : () => onBookSelected(book.id),
        );
      },
    );
  }
}

class _WordbookRow extends StatelessWidget {
  const _WordbookRow({
    required this.book,
    required this.localeCode,
    required this.isCurrent,
    required this.currentLabel,
    required this.onTap,
  });

  final WordBook book;
  final String localeCode;
  final bool isCurrent;
  final String currentLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = book.nameFor(localeCode);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isCurrent)
            AppPill(
              label: currentLabel,
              variant: PillVariant.success,
              icon: AppIcons.checkCircle,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dart extension helpers
// ---------------------------------------------------------------------------

extension _Let<T> on T {
  R let<R>(R Function(T) block) => block(this);
}
```

**NOTE on test architecture:** The test file above uses a `_ProviderRef` placeholder class. Since the sheet is a `ConsumerStatefulWidget` that calls `ref.read(appControllerProvider.notifier)` internally, the `showLanguageWordbookPicker` function needs to receive a `WidgetRef` — but in the test we open it via `showModalBottomSheet` which resolves the container via `ProviderScope.containerOf`. Simplify: change `showLanguageWordbookPicker` signature to just take `BuildContext context` (the `ProviderScope` is the app's root, accessible from context). Update the test to not pass `_ProviderRef`.

Revised `showLanguageWordbookPicker` signature in the widget file:

```dart
Future<void> showLanguageWordbookPicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _LanguageWordbookPickerSheet(
      onDismiss: () => Navigator.of(sheetCtx).pop(),
    ),
  );
}
```

And `_LanguageWordbookPickerSheet` must be a `ConsumerStatefulWidget` (it already is) — the `ProviderScope` is already in the widget tree at the app level, so `ref.watch` and `ref.read` work without explicitly passing a container.

Delete the `_Let` extension and the `ProviderScope.containerOf` trick. The modal sheet inherits the `ProviderScope` via Flutter's element tree when `useRootNavigator: false` (default). If needed, pass `context: context` explicitly to `showModalBottomSheet` — the default behavior inherits.

Update the test accordingly (remove `_ProviderRef`):

In the test, calls become:
```dart
onPressed: () => showLanguageWordbookPicker(ctx),
```

- [ ] **Step 4: Fix and finalize widget file with correct signature**

Replace the `showLanguageWordbookPicker` function body and remove the `_Let` extension. The final `showLanguageWordbookPicker` in `language_wordbook_picker.dart`:

```dart
Future<void> showLanguageWordbookPicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _LanguageWordbookPickerSheet(
      onDismiss: () => Navigator.of(context, rootNavigator: false).pop(),
    ),
  );
}
```

- [ ] **Step 5: Fix the test file to match**

In `language_wordbook_picker_test.dart`, remove `_ProviderRef` class and update all `showLanguageWordbookPicker(ctx, _ProviderRef(ctx))` calls to `showLanguageWordbookPicker(ctx)`.

Also, for the test that checks `notifier.switchCalls`, wrap it with the same `ProviderScope` + `overrideWith` approach but use the `context` from Builder to open the sheet.

Final test calls:
```dart
onPressed: () => showLanguageWordbookPicker(ctx),
```

- [ ] **Step 6: Run tests**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test test/core/widgets/language_wordbook_picker_test.dart -v
```

Expected: all 4 tests PASS.

- [ ] **Step 7: Run full flutter analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 8: Run full test suite**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test
```

Expected: all tests PASS (no regressions).

- [ ] **Step 9: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && git add lib/core/widgets/language_wordbook_picker.dart test/core/widgets/language_wordbook_picker_test.dart
git commit -m "feat(multilang): two-level language→wordbook picker widget (P2c)"
```

---

## Task 3: Wire Picker into Study Plan Settings

**Files:**
- Modify: `linguaquest/lib/features/profile/study_plan_settings_screen.dart`

**Interfaces:**
- Consumes: `showLanguageWordbookPicker(context)` from `language_wordbook_picker.dart`
- The existing `_StudyBookSelector` widget in the screen already handles wordbook display; we add a language step above it.

**Context:** `study_plan_settings_screen.dart` shows `_StudyBookSelector` which lists wordbooks horizontally. We need to add a language selector row above the wordbook selector. When the user taps the language row, it opens the two-level picker (which handles both language and wordbook selection in one flow). The existing `_StudyBookSelector` remains for direct wordbook switching within the current language — after the picker closes, the screen rebuilds from state automatically.

- [ ] **Step 1: Add import**

In `study_plan_settings_screen.dart`, add this import near the top with other widget imports:

```dart
import '../../core/widgets/language_wordbook_picker.dart';
```

- [ ] **Step 2: Add a "Current Language" tile above _StudyBookSelector**

In `study_plan_settings_screen.dart`, find the `_StudyBookSelector(` invocation (around line 151-158). Insert a language tile row just before it. The surrounding build context (inside a `ConsumerStatefulWidget`) gives access to `state` and `context`. The language tile shows the current language label and opens the picker on tap.

Find this code block:
```dart
        _StudyBookSelector(
          books: state.wordBooks,
          userWords: state.userWords,
          selectedId: _wordBookId,
          localeCode: localeCode,
          onSelected: (value) => setState(() => _wordBookId = value),
          l10n: l10n,
        ),
```

Replace with:
```dart
        _CurrentLanguageTile(
          currentLanguage: state.currentLanguage,
          l10n: l10n,
          onTap: () => showLanguageWordbookPicker(context),
        ),
        const SizedBox(height: AppTokens.s12),
        _StudyBookSelector(
          books: state.wordBooks
              .where((b) => b.language == state.currentLanguage)
              .toList(),
          userWords: state.userWords,
          selectedId: _wordBookId,
          localeCode: localeCode,
          onSelected: (value) => setState(() => _wordBookId = value),
          l10n: l10n,
        ),
```

**Note:** Filtering `state.wordBooks` by `state.currentLanguage` ensures the horizontal scroller only shows books for the active language. When P2d adds Japanese books, they appear automatically.

- [ ] **Step 3: Add _CurrentLanguageTile widget to the file**

At the bottom of `study_plan_settings_screen.dart` (after the last existing private widget class), add:

```dart
class _CurrentLanguageTile extends StatelessWidget {
  const _CurrentLanguageTile({
    required this.currentLanguage,
    required this.l10n,
    required this.onTap,
  });

  final String currentLanguage;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Text(
            l10n.pickerChooseLanguage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textSecondaryLight,
                ),
          ),
          const SizedBox(width: AppTokens.s8),
          AppPill(
            label: languageLabel(currentLanguage, l10n),
            variant: PillVariant.primary,
          ),
          const Spacer(),
          const Icon(
            AppIcons.chevronRight,
            size: 18,
            color: AppTokens.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: flutter analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 5: flutter test**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test
```

Expected: all tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && git add lib/features/profile/study_plan_settings_screen.dart
git commit -m "feat(multilang): wire two-level picker into study-plan settings (P2c)"
```

---

## Task 4: Wire Picker into Goal Setup

**Files:**
- Modify: `linguaquest/lib/features/auth/goal_setup_screen.dart`

**Context:** `goal_setup_screen.dart` currently shows a single hardcoded target `'HSK 1'` with `targets = ['HSK 1']`. The goal setup flow should show the two-level picker so users can select language + wordbook as part of initial setup. The existing `_ChoiceSection<String>` for target selection is replaced with a language+wordbook picker tile. Since `state.wordBooks` is already loaded at goal setup (loaded during bootstrap), the picker will have book data.

- [ ] **Step 1: Add import**

In `goal_setup_screen.dart`, add:
```dart
import '../../core/widgets/language_wordbook_picker.dart';
```

- [ ] **Step 2: Replace the target choice section with picker tile**

Find `_ChoiceSection<String>` usage in `goal_setup_screen.dart` (around line 122-128). This renders the target exam selection. Replace it with a language+wordbook picker tile.

Find:
```dart
          _ChoiceSection<String>(
```

The entire `_ChoiceSection<String>` block (it spans a few lines ending with `),`). Replace it with:

```dart
          _LanguageBookPickerTile(
            currentLanguage: state.currentLanguage,
            currentBookName: selectedBook?.nameFor(localeCode) ??
                _target,
            l10n: l10n,
            onTap: () => showLanguageWordbookPicker(context),
          ),
```

- [ ] **Step 3: Add _LanguageBookPickerTile at the bottom of goal_setup_screen.dart**

```dart
class _LanguageBookPickerTile extends StatelessWidget {
  const _LanguageBookPickerTile({
    required this.currentLanguage,
    required this.currentBookName,
    required this.l10n,
    required this.onTap,
  });

  final String currentLanguage;
  final String currentBookName;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppPill(
                  label: languageLabel(currentLanguage, l10n),
                  variant: PillVariant.primary,
                ),
                const SizedBox(height: AppTokens.s4),
                Text(
                  currentBookName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            AppIcons.chevronRight,
            size: 20,
            color: AppTokens.textSecondaryLight,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Remove or keep _ChoiceSection<String> class**

Check if `_ChoiceSection<String>` is used elsewhere in `goal_setup_screen.dart`. If it is only used for the target selection (which we just removed), and there is a `_ChoiceList<int>` for daily goal still in use, keep the generic `_ChoiceSection` class as-is for the `_ChoiceList`. Only remove the specific `targets` variable and `_ChoiceSection<String>` invocation — not the class definition itself.

Remove or comment out:
```dart
  // targets list no longer needed — picker handles language+wordbook selection
  // const targets = ['HSK 1'];
```

And update `_initializeFromState` — the `_target` field is now display-only, no longer driving the save logic. The save logic uses `state.currentWordBookId` from the controller after the picker updates it.

In `_save`, find where `_bookForTarget` is used to determine `wordBookId`. Replace the `wordBookId` determination with `state.currentWordBookId` (the picker has already called `switchWordBook` before save):

```dart
  Future<void> _save() async {
    final state = ref.read(appControllerProvider);
    // Use current wordbook already set by the picker
    final wordBookId = state.currentWordBookId;
    // ... rest of save logic unchanged, replacing _bookForTarget(state.wordBooks, _target)?.id ?? 'hsk1' with wordBookId
  }
```

- [ ] **Step 5: flutter analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: flutter test**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test
```

Expected: all tests PASS. If any test references the old `_ChoiceSection<String>` or hardcoded `'HSK 1'` target in `goal_setup_screen.dart`, update those tests to reflect the new picker flow (replace assertions about `_ChoiceSection` with assertions about the picker tile).

- [ ] **Step 7: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && git add lib/features/auth/goal_setup_screen.dart
git commit -m "feat(multilang): wire two-level picker into goal setup (P2c)"
```

---

## Task 5: Wire Picker into Profile Screen (Language Settings Item)

**Files:**
- Modify: `linguaquest/lib/features/profile/profile_screen.dart`

**Context:** `profile_screen.dart` has `_LanguageSettingsItem` which calls `showTargetLanguageSheet(context, ...)` for AI target language. Per spec, the profile language+wordbook switch entry point should open the two-level picker (`showLanguageWordbookPicker`) for the learning language+wordbook, not just AI target. The AI target language picker (`showTargetLanguageSheet`) remains separate — it controls `targetLanguage` used by AI, not `currentLanguage`/`currentWordBookId`.

Per spec §4 "Entry points": profile should expose the wordbook switch. We add a **new row** for "Learning Wordbook" above or near the existing `_LanguageSettingsItem`, opening `showLanguageWordbookPicker`.

- [ ] **Step 1: Add import**

In `profile_screen.dart`, add:
```dart
import '../../core/widgets/language_wordbook_picker.dart';
```

- [ ] **Step 2: Add a Learning Wordbook settings row**

Find the `_SettingsGroup` that contains the "Study Plan", "Wordbook", "Custom Words", "Mistake Book" items. This is the first settings group (around line 83-109 in profile_screen.dart).

Find the `_SettingsItem` for "Wordbook" (navigates to `/wordbook`). After it, insert a new `_SettingsItem` or inline tile for switching learning language+wordbook via the picker:

In the `Column` or `ListView` of the first `_SettingsGroup`, after the Wordbook item, add:

```dart
              _SettingsItem(
                icon: AppIcons.language,
                title: l10n.pickerChooseLanguage,
                subtitle: '${languageLabel(state.currentLanguage, l10n)} · ${state.currentWordBook?.nameFor(localeCode) ?? state.currentWordBookId}',
                onTap: () => showLanguageWordbookPicker(context),
              ),
```

**Note:** Check what `localeCode` variable is available in profile_screen.dart's build scope. If not present, add: `final localeCode = Localizations.localeOf(context).languageCode;`

- [ ] **Step 3: flutter analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 4: flutter test**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && git add lib/features/profile/profile_screen.dart
git commit -m "feat(multilang): wire two-level picker into profile settings (P2c)"
```

---

## Task 6: Wire Picker into Home Screen (Target Pill)

**Files:**
- Modify: `linguaquest/lib/features/home/home_screen.dart`

**Context:** `home_screen.dart` shows `_DailyFocusHeader` with an `AppPill` showing `target` (the current wordbook name). Per spec, the home "current-target switcher" entry point should let users tap to open the picker. The `AppPill` is inside `_DailyFocusHeader` which is inside an `AppCard`. We make the target pill tappable.

`_DailyFocusHeader` currently receives `target` as a `String`. We need to add an `onTargetTap` callback so the pill becomes tappable.

- [ ] **Step 1: Add import**

In `home_screen.dart`, add:
```dart
import '../../core/widgets/language_wordbook_picker.dart';
```

- [ ] **Step 2: Add onTargetTap parameter to _DailyFocusHeader**

Find `class _DailyFocusHeader extends StatelessWidget` (around line 499). Add a new optional parameter:

```dart
class _DailyFocusHeader extends StatelessWidget {
  const _DailyFocusHeader({
    required this.streak,
    required this.target,
    required this.level,
    required this.todayWork,
    required this.totalWork,
    required this.progress,
    required this.isPaused,
    required this.l10n,
    this.onTargetTap,   // <-- ADD THIS
  });
  // ... existing fields ...
  final VoidCallback? onTargetTap;  // <-- ADD THIS
```

- [ ] **Step 3: Make the target AppPill tappable in _DailyFocusHeader**

In `_DailyFocusHeader.build`, find the `AppPill` that shows `label: '$target · $level'`. Wrap it with `GestureDetector` if `onTargetTap != null`:

```dart
          GestureDetector(
            onTap: onTargetTap,
            child: AppPill(
              label: '$target · $level',
              icon: AppIcons.trackChanges,
            ),
          ),
```

- [ ] **Step 4: Pass onTargetTap at the call site in HomeScreen.build**

Find the `_DailyFocusHeader(` invocation (around line 120 in home_screen.dart). Add:

```dart
            onTargetTap: () => showLanguageWordbookPicker(context),
```

- [ ] **Step 5: flutter analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: flutter test**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test
```

Expected: all tests PASS. If any widget test references `_DailyFocusHeader` without `onTargetTap`, add `onTargetTap: null` to the call.

- [ ] **Step 7: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && git add lib/features/home/home_screen.dart
git commit -m "feat(multilang): wire two-level picker into home target switcher (P2c)"
```

---

## Task 7: Final Verification

- [ ] **Step 1: Run full flutter analyze (must be clean)**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected output: `No issues found!`

- [ ] **Step 2: Run full flutter test (all must pass)**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test --reporter expanded 2>&1 | tail -30
```

Expected: all tests pass; note exact pass count and report it.

- [ ] **Step 3: Verify picker widget test covers all required behaviors**

Confirm `test/core/widgets/language_wordbook_picker_test.dart` has tests for:
- [ ] Chinese shown as active language
- [ ] Japanese shown with "Coming Soon" pill
- [ ] Selecting Chinese navigates to Level 2 wordbook list
- [ ] Selecting Japanese shows coming-soon (no books shown)
- [ ] Selecting a wordbook calls `switchWordBook` and does NOT wipe other scopes (the fake notifier records the call; the real controller's scope isolation is tested in `progress_scope_p2b_test.dart`)

- [ ] **Step 4: Final commit if any remaining changes**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && git status
```

If clean, no commit needed. If any stray files, commit them with appropriate message.

---

## Self-Review Against Spec

### Spec Coverage Check

| Spec §4 requirement | Covered in |
|---|---|
| New `LanguageWordbookPicker` widget | Task 2 |
| Level 1: choose language | Task 2 (`_LanguageList`) |
| Chinese active; Japanese coming-soon | Task 2 (`kSupportedLanguages`) |
| Level 2: wordbooks for selected language | Task 2 (`_WordbookList`) |
| Selecting (language, wordbook) updates state via P2b methods | Task 2 (calls `switchWordBook`) |
| Does NOT wipe other scopes | Task 2 + Task 2 widget test |
| Reuse Cozy Quest primitives | Task 2 (`AppCard`, `AppPill`, `AppTokens`) |
| Goal Setup entry point | Task 4 |
| Profile language+wordbook switch | Task 5 |
| Study Plan Settings | Task 3 |
| Home current-target switcher | Task 6 |
| Data-driven language list (P2d can just set hasBooks: true) | Task 2 (`kSupportedLanguages`) |
| i18n keys added, gen-l10n run | Task 1 |
| Widget test: Chinese active + Japanese coming-soon | Task 2 test |
| Widget test: selecting Chinese shows hsk1-6 | Task 2 test |
| Widget test: selecting wordbook calls switchWordBook | Task 2 test |
| Widget test: Japanese shows coming-soon/no books | Task 2 test |
| `flutter analyze` clean | Every task |
| `flutter test` all pass | Every task |

### Placeholder Scan

No TBD, TODO, or "implement later" phrases found. All code blocks are complete and runnable.

### Type Consistency Check

- `showLanguageWordbookPicker(BuildContext context)` — used consistently in Tasks 2, 3, 4, 5, 6
- `kSupportedLanguages: List<SupportedLanguage>` — defined in Task 2, referenced in Task 2 only (internal)
- `languageLabel(String code, AppLocalizations l10n) → String` — defined in Task 2, used in Tasks 3, 5
- `switchWordBook(String wordBookId) → Future<bool>` — existing controller method, called in Task 2

### Scope Verification

P2c ONLY: UI widget + entry point wiring. No Japanese data (P2d), no language map changes (P2e), no search/wordbook detail changes (P2f). ✓

### Ambiguity Resolution

1. **Goal Setup `_save` flow**: After user opens picker and selects wordbook, `switchWordBook` is called inside the picker. When user then taps "Save" in goal setup, `state.currentWordBookId` already reflects the picked book — so `_save` uses `state.currentWordBookId` directly. This is the correct behavior since the picker committed the selection to state.

2. **`_ChoiceSection<String>` removal**: The `_ChoiceSection` generic class may still be used for `_ChoiceList<int>` (daily goal). Keep the class definition; only remove the `targets` list and the `_ChoiceSection<String>` instance.

3. **Profile screen**: The existing `_LanguageSettingsItem` controls `targetLanguage` (AI language). The new tile controls `currentLanguage`+`currentWordBookId` (learning language). These are different concepts — both rows coexist in profile.

4. **Home screen**: The `AppCard` wrapping `_DailyFocusHeader` is NOT made tappable; only the target `AppPill` inside gets `GestureDetector` — this is less disruptive and more precise UX.
