# P2d: Wire JLPT Japanese Wordbooks Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Register and load 5 JLPT wordbook JSON assets, enable Japanese in the two-level language picker, and allow JLPT book IDs in the server study-plan policy — completing sub-phase P2d.

**Architecture:** All data files already exist (`wordbook_jlpt_n5.json` … `wordbook_jlpt_n1.json` under `linguaquest/lib/assets/data/`). The changes are purely wiring: declare the assets in `pubspec.yaml`, extend `WordBookAssetLoader._bookIds`, flip `kSupportedLanguages` for `ja`, and extend `allowedWordBookIds` in the server policy. No schema or data-model changes are needed (P2a already added `kana`/`romaji`/`examLevel` to `Word` and `language` to `WordBook`; `WordBook.fromJson` already parses `language:'ja'`).

**Tech Stack:** Flutter 3.x / Dart 3.x, Riverpod, flutter_test, Dart `test` package.

## Global Constraints

- Run all Flutter commands from `linguaquest/` directory; run server commands from `server/`.
- `flutter analyze` must exit 0, `flutter test` must pass, `dart test` (server) must pass.
- Chinese/HSK flow must be entirely unaffected; every existing test must continue to pass.
- No new ARB keys (translation freeze in effect) — the picker already has `pickerLanguageJapanese`, `pickerComingSoon`, `pickerChooseWordbook`, etc.
- Commit messages follow the convention: `feat(scope): description (P2d)`.
- Do NOT add `Co-Authored-By` trailers to commits.
- JLPT books are identified as `jlpt_n5`, `jlpt_n4`, `jlpt_n3`, `jlpt_n2`, `jlpt_n1` (N5 = easiest, N1 = hardest).

---

## File Map

| File | Change |
|---|---|
| `linguaquest/pubspec.yaml` | Add 5 JLPT asset entries after HSK6 |
| `linguaquest/lib/data/wordbook_asset_loader.dart` | Add `jlpt_n5`…`jlpt_n1` to `_bookIds` |
| `linguaquest/lib/core/widgets/language_wordbook_picker.dart` | Flip `ja` entry to `hasBooks: true` |
| `server/lib/src/study_plan_policy.dart` | Add `jlpt_n5`…`jlpt_n1` to `allowedWordBookIds` |
| `linguaquest/test/data/jlpt_wordbooks_test.dart` | New: JLPT asset load tests |
| `linguaquest/test/core/widgets/language_wordbook_picker_test.dart` | Extend: add Japanese-selectable tests |
| `server/test/study_plan_policy_test.dart` | Extend: add JLPT acceptance test |

---

### Task 1: Register JLPT assets + extend loader (TDD first)

**Files:**
- Modify: `linguaquest/test/data/jlpt_wordbooks_test.dart` (create new)
- Modify: `linguaquest/pubspec.yaml` lines 80-85
- Modify: `linguaquest/lib/data/wordbook_asset_loader.dart` lines 11-18

**Interfaces:**
- Produces: `WordBookAssetLoader._bookIds` now includes `jlpt_n5`…`jlpt_n1` (total 11 ids).
- Produces: `loadWordBooks()` returns 11 books; the 5 JLPT ones have `language == 'ja'`.

- [ ] **Step 1: Write the failing JLPT asset test**

Create `linguaquest/test/data/jlpt_wordbooks_test.dart`:

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  const expectedMinWords = {
    'jlpt_n5': 600,
    'jlpt_n4': 500,
    'jlpt_n3': 500,
    'jlpt_n2': 800,
    'jlpt_n1': 1000,
  };

  for (final entry in expectedMinWords.entries) {
    final bookId = entry.key;
    final minWords = entry.value;

    test('$bookId parses as a valid Japanese wordbook with kana+romaji', () {
      final file = File('lib/assets/data/wordbook_$bookId.json');
      expect(file.existsSync(), isTrue, reason: '$bookId asset must exist');

      final book = WordBook.fromJson(
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
      );

      expect(book.id, bookId);
      expect(book.language, 'ja',
          reason: '$bookId must have language == ja');
      expect(book.words.length, greaterThanOrEqualTo(minWords),
          reason: '$bookId must have at least $minWords words');
      expect(book.words.length, book.wordIds.length,
          reason: 'wordIds count must match words count');

      final ids = <String>{};
      for (final word in book.words) {
        expect(word.word.trim(), isNotEmpty,
            reason: 'every word must have characters: ${word.id}');
        expect(word.kana.trim(), isNotEmpty,
            reason: 'every ja word must have kana: ${word.word}');
        expect(word.romaji.trim(), isNotEmpty,
            reason: 'every ja word must have romaji: ${word.word}');
        expect(word.examLevel, isNotNull,
            reason: 'every ja word must have examLevel: ${word.word}');
        expect(word.audioUrl.trim(), isNotEmpty,
            reason: 'every ja word must have an audioUrl: ${word.word}');
        expect(ids.add(word.id), isTrue,
            reason: 'word ids must be unique, dup: ${word.id}');

        // English definitions must be present and non-empty.
        final enDefs = word.definitionsFor('en');
        expect(enDefs, isNotEmpty,
            reason: 'every ja word must have English definitions: ${word.word}');
      }
    });
  }

  test('all 11 wordbooks (6 HSK + 5 JLPT) are parseable side-by-side', () {
    const allIds = [
      'hsk1', 'hsk2', 'hsk3', 'hsk4', 'hsk5', 'hsk6',
      'jlpt_n5', 'jlpt_n4', 'jlpt_n3', 'jlpt_n2', 'jlpt_n1',
    ];
    for (final id in allIds) {
      final file = File('lib/assets/data/wordbook_$id.json');
      expect(file.existsSync(), isTrue, reason: '$id must exist');
      final book = WordBook.fromJson(
        Map<String, dynamic>.from(jsonDecode(file.readAsStringSync()) as Map),
      );
      expect(book.id, id);
      expect(book.words, isNotEmpty, reason: '$id must have words');
    }
  });
}
```

- [ ] **Step 2: Run the test to confirm it fails**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test test/data/jlpt_wordbooks_test.dart --reporter compact
```

Expected: FAIL — files exist on disk but NOT yet registered in pubspec.yaml, so the `File()` checks pass on disk but the asset loader test cannot find them via `rootBundle` (the asset tests here use `File` directly so they will pass the existence check; the main failure expected is in the side-by-side test if any JSON file has issues, or we just confirm all pass after implementation). The test should pass after Step 4 once we verify the data. **Note:** these tests use `dart:io File` directly (same as the HSK tests), so they CAN run before pubspec changes.

- [ ] **Step 3: Add JLPT entries to pubspec.yaml**

In `linguaquest/pubspec.yaml`, after line 85 (`- lib/assets/data/wordbook_hsk6.json`), add:

```yaml
    - lib/assets/data/wordbook_jlpt_n5.json
    - lib/assets/data/wordbook_jlpt_n4.json
    - lib/assets/data/wordbook_jlpt_n3.json
    - lib/assets/data/wordbook_jlpt_n2.json
    - lib/assets/data/wordbook_jlpt_n1.json
```

The full `assets:` block becomes:
```yaml
  assets:
    - lib/assets/image/
    - lib/assets/data/wordbook_hsk1.json
    - lib/assets/data/wordbook_hsk2.json
    - lib/assets/data/wordbook_hsk3.json
    - lib/assets/data/wordbook_hsk4.json
    - lib/assets/data/wordbook_hsk5.json
    - lib/assets/data/wordbook_hsk6.json
    - lib/assets/data/wordbook_jlpt_n5.json
    - lib/assets/data/wordbook_jlpt_n4.json
    - lib/assets/data/wordbook_jlpt_n3.json
    - lib/assets/data/wordbook_jlpt_n2.json
    - lib/assets/data/wordbook_jlpt_n1.json
```

- [ ] **Step 4: Extend `_bookIds` in `WordBookAssetLoader`**

Replace the `_bookIds` list in `linguaquest/lib/data/wordbook_asset_loader.dart`:

```dart
  static const _bookIds = [
    'hsk1',
    'hsk2',
    'hsk3',
    'hsk4',
    'hsk5',
    'hsk6',
    'jlpt_n5',
    'jlpt_n4',
    'jlpt_n3',
    'jlpt_n2',
    'jlpt_n1',
  ];
```

- [ ] **Step 5: Run the JLPT test to confirm it passes**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test test/data/jlpt_wordbooks_test.dart --reporter compact
```

Expected: all tests PASS with output similar to:
```
00:XX +6: All tests passed!
```

- [ ] **Step 6: Run the full flutter test suite to confirm no regressions**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test --reporter compact
```

Expected: all existing tests pass plus the new 6 JLPT tests.

- [ ] **Step 7: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2 && git add linguaquest/pubspec.yaml linguaquest/lib/data/wordbook_asset_loader.dart linguaquest/test/data/jlpt_wordbooks_test.dart && git commit -m "feat(wordbook): register + load JLPT assets (P2d)"
```

---

### Task 2: Enable Japanese in the language picker

**Files:**
- Modify: `linguaquest/lib/core/widgets/language_wordbook_picker.dart` line 37
- Modify: `linguaquest/test/core/widgets/language_wordbook_picker_test.dart`

**Interfaces:**
- Consumes: `kSupportedLanguages` list from `language_wordbook_picker.dart`.
- Produces: `kSupportedLanguages` entry for `ja` has `hasBooks: true`; existing picker widget tests must be updated to reflect Japanese is now selectable.

- [ ] **Step 1: Update the picker test to expect Japanese to be selectable**

In `linguaquest/test/core/widgets/language_wordbook_picker_test.dart`, make the following changes:

**Add a helper to build a state with both zh + ja books:**

After the existing `_zhState` function (around line 77), add:

```dart
AppState _bothLangState() {
  return AppState.initial().copyWith(
    wordBooks: [
      for (var i = 1; i <= 6; i++) _fakeBook('hsk$i', language: 'zh'),
      for (var n in [5, 4, 3, 2, 1]) _fakeBook('jlpt_n$n', language: 'ja'),
    ],
    currentWordBookId: 'hsk1',
    currentLanguage: 'zh',
  );
}
```

**Update the test `'shows Chinese (active) and Japanese (coming-soon)'`** — rename it and change its assertions since Japanese is no longer coming-soon:

Replace the test body:
```dart
    testWidgets('shows Chinese (active) and Japanese (active) in language list',
        (tester) async {
      await tester.pumpWidget(_harness(state: _bothLangState()));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('Chinese (中文)'), findsOneWidget);
      expect(find.text('Japanese (日本語)'), findsOneWidget);
      // Neither language is coming-soon any more.
      expect(find.text('Coming Soon'), findsNothing);
    });
```

**Update the test `'Japanese shows coming-soon, not a wordbook list'`** — replace it with a test that Japanese IS now navigable and shows JLPT books:

```dart
    testWidgets('selecting Japanese shows jlpt wordbooks', (tester) async {
      await tester.pumpWidget(_harness(state: _bothLangState()));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Japanese (日本語)'));
      await tester.pumpAndSettle();

      // Should now show the JLPT book list.
      expect(find.text('JLPT_N5'), findsOneWidget);
    });
```

- [ ] **Step 2: Run the picker tests to confirm they fail as expected**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test test/core/widgets/language_wordbook_picker_test.dart --reporter compact
```

Expected: the two updated tests FAIL because `ja` still has `hasBooks: false`.

- [ ] **Step 3: Flip `ja` to `hasBooks: true` in the picker**

In `linguaquest/lib/core/widgets/language_wordbook_picker.dart`, change line 37:

```dart
const List<SupportedLanguage> kSupportedLanguages = [
  SupportedLanguage(code: 'zh', hasBooks: true),
  SupportedLanguage(code: 'ja', hasBooks: true),  // P2d: JLPT books are now shipped
];
```

- [ ] **Step 4: Run picker tests to confirm they pass**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test test/core/widgets/language_wordbook_picker_test.dart --reporter compact
```

Expected: all 4 tests PASS.

- [ ] **Step 5: Run full flutter suite to confirm no regressions**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test --reporter compact
```

Expected: all tests PASS.

- [ ] **Step 6: Run flutter analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 7: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2 && git add linguaquest/lib/core/widgets/language_wordbook_picker.dart linguaquest/test/core/widgets/language_wordbook_picker_test.dart && git commit -m "feat(multilang): enable Japanese in language picker (P2d)"
```

---

### Task 3: Allow JLPT wordbook IDs in server study plan policy

**Files:**
- Modify: `server/lib/src/study_plan_policy.dart` lines 3-10
- Modify: `server/test/study_plan_policy_test.dart`

**Interfaces:**
- Consumes: `allowedWordBookIds` set from `study_plan_policy.dart`.
- Produces: `allowedWordBookIds` includes `jlpt_n5`, `jlpt_n4`, `jlpt_n3`, `jlpt_n2`, `jlpt_n1`; `validateStudyPlanPayload` accepts these IDs and returns them verbatim (no normalization needed).

- [ ] **Step 1: Write the failing server test**

In `server/test/study_plan_policy_test.dart`, add a new test after the `'accepts every HSK wordbook id'` test:

```dart
  test('accepts every JLPT wordbook id', () {
    for (final id in ['jlpt_n5', 'jlpt_n4', 'jlpt_n3', 'jlpt_n2', 'jlpt_n1']) {
      final result = validateStudyPlanPayload({
        'wordBookId': id,
        'dailyNewTarget': 10,
        'dailyReviewLimit': 20,
        'startDate': '2026-06-04',
        'targetFinishDate': '2026-08-04',
        'reminderTime': '08:00',
      });
      expect(result.isValid, isTrue, reason: '$id should be accepted');
      expect(result.data!['wordBookId'], id,
          reason: '$id should not be normalized to anything else');
    }
  });

  test('still rejects unknown wordbook ids after JLPT addition', () {
    for (final bad in ['jlpt_n6', 'jlpt_n0', 'jlpt', 'n5', 'totally-unknown']) {
      final result = validateStudyPlanPayload({
        'wordBookId': bad,
        'dailyNewTarget': 10,
        'dailyReviewLimit': 20,
        'startDate': '2026-06-04',
        'targetFinishDate': '2026-08-04',
        'reminderTime': '08:00',
      });
      expect(result.error, 'invalid wordBookId',
          reason: '$bad must be rejected');
    }
  });
```

- [ ] **Step 2: Run server tests to confirm failure**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart test test/study_plan_policy_test.dart --reporter compact
```

Expected: the two new tests FAIL because `jlpt_n5` etc. are not yet in `allowedWordBookIds`.

- [ ] **Step 3: Add JLPT IDs to `allowedWordBookIds` in `study_plan_policy.dart`**

Replace the `allowedWordBookIds` constant in `server/lib/src/study_plan_policy.dart`:

```dart
const allowedWordBookIds = {
  'hsk1',
  'hsk2',
  'hsk3',
  'hsk4',
  'hsk5',
  'hsk6',
  'jlpt_n5',
  'jlpt_n4',
  'jlpt_n3',
  'jlpt_n2',
  'jlpt_n1',
};
```

No other changes are needed — `normalizeStudyPlanWordBookId` already returns the value verbatim when it's in `allowedWordBookIds`, so JLPT IDs pass through unchanged.

- [ ] **Step 4: Run server tests to confirm they pass**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart test test/study_plan_policy_test.dart --reporter compact
```

Expected: all tests PASS including the two new JLPT tests.

- [ ] **Step 5: Run full server test suite**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart test --reporter compact
```

Expected: all server tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2 && git add server/lib/src/study_plan_policy.dart server/test/study_plan_policy_test.dart && git commit -m "feat(server): allow JLPT wordbook ids in study plan (P2d)"
```

---

### Task 4: Final verification pass

- [ ] **Step 1: Run full Flutter test suite**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter test --reporter compact
```

Expected: all tests PASS. Record exact count.

- [ ] **Step 2: Run flutter analyze**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: Run full server test suite**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart test --reporter compact
```

Expected: all tests PASS. Record exact count.

- [ ] **Step 4: Confirm git log shows three clean commits**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2 && git log --oneline -5
```

Expected: top 3 commits are the P2d commits in reverse order:
```
<hash> feat(server): allow JLPT wordbook ids in study plan (P2d)
<hash> feat(multilang): enable Japanese in language picker (P2d)
<hash> feat(wordbook): register + load JLPT assets (P2d)
```

---

## What P2d defers

- **P2e** (map routing): enabling the Japan map pin and routing to JLPT wordbook selection — `language_map_screen.dart` is not touched in this plan.
- **P2f** (per-language word-detail/search display): `search_screen.dart`, `wordbook_screen.dart` phonetic/level column wiring for `ja` — kana/romaji are in the model but the UI still shows whatever it showed for zh (mostly blanks for Japanese words). This is intentional scope deferral.
- **JFT-Basic** (`jft_basic`): the spec mentions a JFT-Basic book but that data file does not exist yet; it is deferred to whenever the data is generated.
