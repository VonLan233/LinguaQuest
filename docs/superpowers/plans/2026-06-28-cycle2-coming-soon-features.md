# Cycle 2 — Coming-Soon Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the four placeholder features — two AI Learn tools (Confusable Words, Sentence Generation & Rewrite) and two Training drills (Listening Sprint, Passage Cloze).

**Architecture:** The two AI tools slot into the existing `/ai/<feature>` pipeline (server `buildSystemPrompt` + `MockAiProvider` + route → client `askAi` → repo → screen modeled on `ai_cloze_screen.dart`). Listening Sprint extends the existing `TrainingGameType` drill engine. Passage Cloze is a dedicated screen that fetches an AI cloze (existing `/ai/cloze`) and runs it as a scored drill via `completeTraining`.

**Tech Stack:** Flutter 3.41.6, Riverpod, go_router; Dart shelf server.

## Global Constraints

- No new dependencies. Reuse existing packages/services only.
- AI features reuse the existing pipeline verbatim (request body `{prompt, targetWord, targetLanguage}`; response read from `response.data!['data']`; strict-JSON system prompts ending "No markdown, no code fences."; taught content in target language, explanatory fields in English).
- Server system prompts: explanatory fields English, taught content in `$language` (matches existing cases in `ai_policy.dart`).
- App UI runtime locale is English; ARB keys still added to all three files (`app_en.arb`, `app_zh.arb`, `app_ms.arb`) so generation stays clean. New AI screens may hardcode English UI strings (consistent with `ai_cloze_screen.dart`); Training drill prompts use `l10n.trainingPrompt*` keys (consistent with the other drills).
- Listening Sprint audio uses `PronunciationService`/`PronunciationControls` (already in `training_session_screen.dart`).
- Passage Cloze passage comes from the existing `/ai/cloze` endpoint; never crash on AI failure/malformed data — show a retryable error.
- Flutter commands run from `/Users/lanyichen/Codes/Mobile/ASM2/linguaquest`; server commands from `/Users/lanyichen/Codes/Mobile/ASM2/server`.
- `flutter analyze` + `flutter test` and `dart analyze` + `dart test` must be clean before each commit in the touched project.
- Feature type strings: Confusable Words = `'confusion'` (route `/ai/confusion`, client `/ai-confusion`); Sentence Gen = `'sentence_gen'` (route `/ai/sentence`, client `/ai-sentence`).

---

### Task 1: Server — `confusion` + `sentence_gen` AI feature types

**Files:**
- Modify: `server/lib/src/ai_policy.dart` (`MockAiProvider.generate` switch ~line 58; `buildSystemPrompt` switch ~line 224)
- Modify: `server/lib/src/routes.dart` (add two routes after the `/ai/cloze` block ~line 1295)
- Test: `server/test/ai_system_prompt_test.dart`, `server/test/ai_routes_test.dart`

**Interfaces:**
- Produces: server accepts `POST /ai/confusion` and `POST /ai/sentence`; `buildSystemPrompt('confusion'|'sentence_gen', lang)` returns non-null prompts; `MockAiProvider` returns the documented shapes.

- [ ] **Step 1: Write the failing tests**

In `server/test/ai_system_prompt_test.dart`, add (inside the existing `main`):

```dart
  test('buildSystemPrompt covers confusion and sentence_gen', () {
    final confusion = buildSystemPrompt('confusion', 'Chinese');
    expect(confusion, isNotNull);
    expect(confusion, contains('"pairs"'));
    expect(confusion, contains('No markdown'));

    final sentence = buildSystemPrompt('sentence_gen', 'Chinese');
    expect(sentence, isNotNull);
    expect(sentence, contains('"sentences"'));
    expect(sentence, contains('"rewrites"'));
  });
```

In `server/test/ai_routes_test.dart`, add a test that the mock provider returns the new shapes (model it on the existing cloze/chat assertions in that file — reuse its `MockAiProvider`/`AiPolicyService` setup):

```dart
  test('MockAiProvider returns confusion and sentence_gen shapes', () async {
    final provider = MockAiProvider();
    final confusion = await provider.generate(const AiRequest(
        featureType: 'confusion', userId: 'u', prompt: 'p', targetWord: '近'));
    expect(confusion.success, isTrue);
    expect(confusion.data['pairs'], isA<List>());

    final sentence = await provider.generate(const AiRequest(
        featureType: 'sentence_gen', userId: 'u', prompt: 'p', targetWord: '学'));
    expect(sentence.success, isTrue);
    expect(sentence.data['sentences'], isA<List>());
    expect(sentence.data['rewrites'], isA<List>());
  });
```

- [ ] **Step 2: Run tests to verify they fail**

Run (from `server/`): `dart test test/ai_system_prompt_test.dart test/ai_routes_test.dart`
Expected: FAIL — `buildSystemPrompt` returns null for the new types; mock returns `unknown_feature`.

- [ ] **Step 3: Add the mock cases**

In `server/lib/src/ai_policy.dart`, inside `MockAiProvider.generate`'s `switch`, add before `default:` (after the `writing_review` case, ~line 144):

```dart
      case 'confusion':
        final word = request.targetWord ?? 'word';
        return AiResponse(
          success: true,
          data: {
            'pairs': [
              {
                'word': word,
                'confusedWith': 'similar',
                'distinction': 'Mock distinction for $word.',
                'examples': <String>[],
              },
            ],
          },
        );
      case 'sentence_gen':
        final word = request.targetWord ?? 'word';
        return AiResponse(
          success: true,
          data: {
            'sentences': [
              {'sentence': 'Mock sentence with $word.', 'translation': 'Mock translation.'},
            ],
            'rewrites': [
              {'original': word, 'rewritten': 'Mock rewrite.', 'note': 'Mock note.'},
            ],
          },
        );
```

- [ ] **Step 4: Add the system prompts**

In `buildSystemPrompt`'s `switch`, add before the closing `}` / `return null` (after the `writing_review` case, ~line 270):

```dart
    case 'confusion':
      return 'Identify words commonly confused with the target word in '
          '$language. Keep each pair\'s "word", "confusedWith", and "examples" '
          'in $language; write "distinction" in English. Reply ONLY with strict '
          'JSON: {"pairs": [{"word": string, "confusedWith": string, '
          '"distinction": string, "examples": string[]}]}. '
          'No markdown, no code fences.';
    case 'sentence_gen':
      return 'For the target word or sentence, write natural example sentences '
          'and improved rewrites in $language. Keep "sentence" and "rewritten" '
          'in $language; write "translation" and "note" in English. Reply ONLY '
          'with strict JSON: {"sentences": [{"sentence": string, "translation": '
          'string}], "rewrites": [{"original": string, "rewritten": string, '
          '"note": string}]}. No markdown, no code fences.';
```

- [ ] **Step 5: Add the routes**

In `server/lib/src/routes.dart`, after the `/ai/cloze` route block (ends ~line 1295), add:

```dart
  router.post('/ai/confusion', (Request request) async {
    return _protected(
      config,
      request,
      (uid) => _handleAiRequest(request, 'confusion', uid),
    );
  });

  router.post('/ai/sentence', (Request request) async {
    return _protected(
      config,
      request,
      (uid) => _handleAiRequest(request, 'sentence_gen', uid),
    );
  });
```

- [ ] **Step 6: Run tests + analyze**

Run (from `server/`): `dart test test/ai_system_prompt_test.dart test/ai_routes_test.dart`
Expected: PASS
Run: `dart analyze lib/src/ai_policy.dart lib/src/routes.dart`
Expected: No issues.

- [ ] **Step 7: Commit**

```bash
git add server/lib/src/ai_policy.dart server/lib/src/routes.dart server/test/ai_system_prompt_test.dart server/test/ai_routes_test.dart
git commit -m "feat(server): add confusion + sentence_gen AI feature types"
```

---

### Task 2: Client — AI repo + controller plumbing for the two features

**Files:**
- Modify: `linguaquest/lib/data/repositories/ai_repository.dart` (interface)
- Modify: `linguaquest/lib/data/repositories/api_repositories.dart` (`ApiAiRepository`)
- Modify: `linguaquest/lib/data/repositories/mock_repositories.dart` (`MockAiRepository`, ~line 1104)
- Modify: `linguaquest/lib/core/state/app_controller.dart` (`askAi` switch ~line 2653)
- Test: `linguaquest/test/ai_learning_test.dart`

**Interfaces:**
- Produces:
  - `AiRepository.generateConfusion({required String prompt, required String targetLanguage, String? targetWord}) → Future<Map<String,dynamic>>`
  - `AiRepository.generateSentences({required String prompt, required String targetLanguage, String? targetWord}) → Future<Map<String,dynamic>>`
  - `askAi(featureType:'confusion'|'sentence_gen', prompt, targetWord)` routes to these and refreshes history (same as `'cloze'`).

- [ ] **Step 1: Write the failing test**

In `linguaquest/test/ai_learning_test.dart`, add (using the existing `MockAiRepository`):

```dart
  test('MockAiRepository.generateConfusion returns pairs', () async {
    final repo = MockAiRepository();
    final result = await repo.generateConfusion(
        prompt: 'p', targetLanguage: 'zh', targetWord: '近');
    expect(result['pairs'], isA<List>());
  });

  test('MockAiRepository.generateSentences returns sentences + rewrites', () async {
    final repo = MockAiRepository();
    final result = await repo.generateSentences(
        prompt: 'p', targetLanguage: 'zh', targetWord: '学');
    expect(result['sentences'], isA<List>());
    expect(result['rewrites'], isA<List>());
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/ai_learning_test.dart`
Expected: FAIL — methods undefined.

- [ ] **Step 3: Add interface methods**

In `linguaquest/lib/data/repositories/ai_repository.dart`, add inside `abstract class AiRepository` (after `generateCloze`):

```dart
  Future<Map<String, dynamic>> generateConfusion({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  });

  Future<Map<String, dynamic>> generateSentences({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  });
```

- [ ] **Step 4: Add Api implementation**

In `linguaquest/lib/data/repositories/api_repositories.dart`, inside `ApiAiRepository` (after `generateCloze`):

```dart
  @override
  Future<Map<String, dynamic>> generateConfusion({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/confusion',
      data: {
        'prompt': prompt,
        'targetWord': targetWord,
        'targetLanguage': targetLanguage,
      },
      options: Options(receiveTimeout: _aiTimeout),
    );
    return response.data!['data'] as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> generateSentences({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/sentence',
      data: {
        'prompt': prompt,
        'targetWord': targetWord,
        'targetLanguage': targetLanguage,
      },
      options: Options(receiveTimeout: _aiTimeout),
    );
    return response.data!['data'] as Map<String, dynamic>;
  }
```

- [ ] **Step 5: Add Mock implementation**

In `linguaquest/lib/data/repositories/mock_repositories.dart`, inside `MockAiRepository` (after `generateCloze`):

```dart
  @override
  Future<Map<String, dynamic>> generateConfusion({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final word = targetWord ?? 'word';
    final result = <String, dynamic>{
      'pairs': [
        {
          'word': word,
          'confusedWith': 'similar',
          'distinction': 'Mock distinction for $word.',
          'examples': <String>[],
        },
      ],
    };
    _history.insert(
      0,
      AiHistoryEntry(
        id: 'mock-${_idCounter++}',
        featureType: 'confusion',
        prompt: prompt,
        response: result,
        createdAt: DateTime.now(),
      ),
    );
    return result;
  }

  @override
  Future<Map<String, dynamic>> generateSentences({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final word = targetWord ?? 'word';
    final result = <String, dynamic>{
      'sentences': [
        {'sentence': 'Mock sentence with $word.', 'translation': 'Mock translation.'},
      ],
      'rewrites': [
        {'original': word, 'rewritten': 'Mock rewrite.', 'note': 'Mock note.'},
      ],
    };
    _history.insert(
      0,
      AiHistoryEntry(
        id: 'mock-${_idCounter++}',
        featureType: 'sentence_gen',
        prompt: prompt,
        response: result,
        createdAt: DateTime.now(),
      ),
    );
    return result;
  }
```

- [ ] **Step 6: Wire `askAi`**

In `linguaquest/lib/core/state/app_controller.dart`, in the `askAi` `switch` (after the `'cloze'` case, before `default:`):

```dart
        case 'confusion':
          result = await repo.generateConfusion(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.currentLanguage,
          );
        case 'sentence_gen':
          result = await repo.generateSentences(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.currentLanguage,
          );
```

- [ ] **Step 7: Run tests + analyze**

Run: `flutter test test/ai_learning_test.dart`
Expected: PASS
Run: `flutter analyze lib/data/repositories lib/core/state/app_controller.dart`
Expected: No issues.

- [ ] **Step 8: Commit**

```bash
git add linguaquest/lib/data/repositories/ai_repository.dart linguaquest/lib/data/repositories/api_repositories.dart linguaquest/lib/data/repositories/mock_repositories.dart linguaquest/lib/core/state/app_controller.dart linguaquest/test/ai_learning_test.dart
git commit -m "feat(ai): client repo + askAi plumbing for confusion + sentence_gen"
```

---

### Task 3: Confusable Words screen

**Files:**
- Create: `linguaquest/lib/features/ai_learning/ai_confusable_words_screen.dart`
- Modify: `linguaquest/lib/core/routing/app_router.dart` (import + route, near `/ai-cloze` ~line 182)
- Modify: `linguaquest/lib/features/ai_learning/ai_learning_screen.dart` (enable the Confusable Words row ~line 117)

**Interfaces:**
- Consumes: `askAi(featureType:'confusion', ...)` (Task 2); `AiErrorCard`, `AppCard`, `AppPrimaryButton`.
- Produces: route `/ai-confusion` → `AiConfusableWordsScreen`.

- [ ] **Step 1: Create the screen**

Create `linguaquest/lib/features/ai_learning/ai_confusable_words_screen.dart` (modeled on `ai_cloze_screen.dart` structure: input card → states):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/generated/app_localizations.dart';

class AiConfusableWordsScreen extends ConsumerStatefulWidget {
  const AiConfusableWordsScreen({super.key});

  @override
  ConsumerState<AiConfusableWordsScreen> createState() =>
      _AiConfusableWordsScreenState();
}

class _AiConfusableWordsScreenState
    extends ConsumerState<AiConfusableWordsScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = _controller.text.trim();
    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });
    final result = await ref.read(appControllerProvider.notifier).askAi(
          featureType: 'confusion',
          prompt: 'Distinguish words confusable with: $input',
          targetWord: input,
        );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isEmpty) {
        _errorMessage = ref.read(appControllerProvider).errorMessage ??
            AppLocalizations.of(context).aiErrorGeneric;
      } else {
        _result = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Confusable Words'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s20, AppTokens.s20, AppTokens.s20, 88),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter a word to compare with its look-alikes',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: _controller,
                    maxLength: 100,
                    decoration: const InputDecoration(
                      hintText: 'e.g. 在 / 再, affect / effect...',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a word'
                        : null,
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: _isLoading ? 'Analyzing...' : 'Analyze',
                      onPressed: _isLoading ? null : _analyze,
                    ),
                  ),
                ],
              ),
            ),
            if (_result == null && _errorMessage == null && !_isLoading) ...[
              const SizedBox(height: AppTokens.s20),
              AppCard(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Text(
                  'Enter a word to see commonly confused look-alikes and how to tell them apart.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTokens.s20),
              AiErrorCard(message: _errorMessage!, onRetry: _analyze),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppTokens.s20),
              _ConfusionResult(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfusionResult extends StatelessWidget {
  const _ConfusionResult({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pairs = (result['pairs'] as List<dynamic>?) ?? const [];
    if (pairs.isEmpty) {
      return AppCard(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Text('No confusable words found.',
            style: theme.textTheme.bodyMedium),
      );
    }
    return Column(
      children: [
        for (final raw in pairs)
          if (raw is Map)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTokens.s12),
              child: AppCard(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${raw['word'] ?? ''}  vs  ${raw['confusedWith'] ?? ''}',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppTokens.s8),
                    Text('${raw['distinction'] ?? ''}',
                        style: theme.textTheme.bodyMedium),
                    if ((raw['examples'] as List<dynamic>?)?.isNotEmpty ??
                        false) ...[
                      const SizedBox(height: AppTokens.s8),
                      for (final ex in (raw['examples'] as List))
                        Padding(
                          padding: const EdgeInsets.only(top: AppTokens.s4),
                          child: Text('• $ex',
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant)),
                        ),
                    ],
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
```

- [ ] **Step 2: Register the route**

In `linguaquest/lib/core/routing/app_router.dart`, add the import near the other `ai_learning` imports (~line 9-13):

```dart
import '../../features/ai_learning/ai_confusable_words_screen.dart';
```

Add the route after the `/ai-cloze` `GoRoute` (~line 186):

```dart
      GoRoute(
        path: '/ai-confusion',
        builder: (context, state) => const AiConfusableWordsScreen(),
      ),
```

- [ ] **Step 3: Enable the AI Learn row**

In `linguaquest/lib/features/ai_learning/ai_learning_screen.dart`, the Confusable Words `_AiToolRow` (~line 117) currently passes `status: l10n.aiLearningStatusPlanning`. Replace that `status:` argument with an `onTap:` (matching how the working rows wire it — verify the exact param name `onTap` on `_AiToolRow`):

```dart
            _AiToolRow(
              icon: AppIcons.compareArrows,
              title: l10n.aiLearningToolConfusion,
              color: AppTheme.cyan,
              onTap: () => context.push('/ai-confusion'),
            ),
```

(Ensure `context`/`go_router` are in scope — the file already uses `context.push` for the working rows.)

- [ ] **Step 4: Analyze + smoke test**

Run: `flutter analyze lib/features/ai_learning/ai_confusable_words_screen.dart lib/core/routing/app_router.dart lib/features/ai_learning/ai_learning_screen.dart`
Expected: No issues.
Run: `flutter test test/ai_learning_test.dart`
Expected: PASS (no regressions).

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/features/ai_learning/ai_confusable_words_screen.dart linguaquest/lib/core/routing/app_router.dart linguaquest/lib/features/ai_learning/ai_learning_screen.dart
git commit -m "feat(ai): Confusable Words screen wired to /ai-confusion"
```

---

### Task 4: Sentence Generation & Rewrite screen

**Files:**
- Create: `linguaquest/lib/features/ai_learning/ai_sentence_gen_screen.dart`
- Modify: `linguaquest/lib/core/routing/app_router.dart` (import + route)
- Modify: `linguaquest/lib/features/ai_learning/ai_learning_screen.dart` (enable the Sentence row ~line 124)

**Interfaces:**
- Consumes: `askAi(featureType:'sentence_gen', ...)` (Task 2).
- Produces: route `/ai-sentence` → `AiSentenceGenScreen`.

- [ ] **Step 1: Create the screen**

Create `linguaquest/lib/features/ai_learning/ai_sentence_gen_screen.dart` (same structure as Task 3; result renders two sections):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../l10n/generated/app_localizations.dart';

class AiSentenceGenScreen extends ConsumerStatefulWidget {
  const AiSentenceGenScreen({super.key});

  @override
  ConsumerState<AiSentenceGenScreen> createState() =>
      _AiSentenceGenScreenState();
}

class _AiSentenceGenScreenState extends ConsumerState<AiSentenceGenScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? _result;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final input = _controller.text.trim();
    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });
    final result = await ref.read(appControllerProvider.notifier).askAi(
          featureType: 'sentence_gen',
          prompt: 'Generate example sentences and rewrites for: $input',
          targetWord: input,
        );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isEmpty) {
        _errorMessage = ref.read(appControllerProvider).errorMessage ??
            AppLocalizations.of(context).aiErrorGeneric;
      } else {
        _result = result;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sentence Generation'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppTokens.s20, AppTokens.s20, AppTokens.s20, 88),
          children: [
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enter a word or a sentence',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppTokens.s12),
                  TextFormField(
                    controller: _controller,
                    maxLength: 200,
                    decoration: const InputDecoration(
                      hintText: 'A word to build sentences for, or a sentence to rewrite',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter a word or sentence'
                        : null,
                  ),
                  const SizedBox(height: AppTokens.s12),
                  SizedBox(
                    width: double.infinity,
                    child: AppPrimaryButton(
                      label: _isLoading ? 'Generating...' : 'Generate',
                      onPressed: _isLoading ? null : _generate,
                    ),
                  ),
                ],
              ),
            ),
            if (_result == null && _errorMessage == null && !_isLoading) ...[
              const SizedBox(height: AppTokens.s20),
              AppCard(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: Text(
                  'Enter a word to generate example sentences, or a sentence to get rewrite suggestions.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
            if (_errorMessage != null) ...[
              const SizedBox(height: AppTokens.s20),
              AiErrorCard(message: _errorMessage!, onRetry: _generate),
            ],
            if (_result != null) ...[
              const SizedBox(height: AppTokens.s20),
              _SentenceResult(result: _result!),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentenceResult extends StatelessWidget {
  const _SentenceResult({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sentences = (result['sentences'] as List<dynamic>?) ?? const [];
    final rewrites = (result['rewrites'] as List<dynamic>?) ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sentences.isNotEmpty) ...[
          Text('Example Sentences',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTokens.s8),
          for (final raw in sentences)
            if (raw is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: AppCard(
                  padding: const EdgeInsets.all(AppTokens.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${raw['sentence'] ?? ''}',
                          style: theme.textTheme.bodyLarge),
                      const SizedBox(height: AppTokens.s4),
                      Text('${raw['translation'] ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
        ],
        if (rewrites.isNotEmpty) ...[
          const SizedBox(height: AppTokens.s12),
          Text('Rewrites',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: AppTokens.s8),
          for (final raw in rewrites)
            if (raw is Map)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: AppCard(
                  padding: const EdgeInsets.all(AppTokens.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${raw['original'] ?? ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough)),
                      const SizedBox(height: AppTokens.s4),
                      Text('${raw['rewritten'] ?? ''}',
                          style: theme.textTheme.bodyLarge),
                      if ('${raw['note'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: AppTokens.s4),
                        Text('${raw['note']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 2: Register the route**

In `app_router.dart`, add import:

```dart
import '../../features/ai_learning/ai_sentence_gen_screen.dart';
```

Add route after `/ai-confusion`:

```dart
      GoRoute(
        path: '/ai-sentence',
        builder: (context, state) => const AiSentenceGenScreen(),
      ),
```

- [ ] **Step 3: Enable the AI Learn row**

In `ai_learning_screen.dart`, the Sentence `_AiToolRow` (~line 124) — replace `status:` with `onTap`:

```dart
            _AiToolRow(
              icon: AppIcons.tipsAndUpdates,
              title: l10n.aiLearningToolSentence,
              color: AppTokens.azure,
              onTap: () => context.push('/ai-sentence'),
            ),
```

- [ ] **Step 4: Analyze**

Run: `flutter analyze lib/features/ai_learning/ai_sentence_gen_screen.dart lib/core/routing/app_router.dart lib/features/ai_learning/ai_learning_screen.dart`
Expected: No issues.

- [ ] **Step 5: Commit**

```bash
git add linguaquest/lib/features/ai_learning/ai_sentence_gen_screen.dart linguaquest/lib/core/routing/app_router.dart linguaquest/lib/features/ai_learning/ai_learning_screen.dart
git commit -m "feat(ai): Sentence Generation & Rewrite screen wired to /ai-sentence"
```

---

### Task 5: Listening Sprint training drill

**Files:**
- Modify: `linguaquest/lib/features/training/training_session_screen.dart` (enum + all exhaustive switches + prompt panel)
- Modify: `linguaquest/lib/features/training/training_screen.dart` (the Listening row onTap ~line 88)
- Modify: `linguaquest/lib/l10n/app_en.arb`, `app_zh.arb`, `app_ms.arb` (one new prompt key)
- Test: `linguaquest/test/features/training/listening_sprint_test.dart` (new)

**Interfaces:**
- Consumes: `PronunciationControls`, `QuizQuestionType.listeningWordChoice`, `ReviewDimension.listening`.
- Produces: `TrainingGameType.listeningSprint('listening-sprint', ...)` runnable via `/training/listening-sprint`.

**Note on Dart exhaustiveness:** `TrainingGameType` is matched by exhaustive `switch` in `title()`, `_sourceWordsForGame`, `_buildQuestions`, `_questionFor`, `_advanceAfterFeedback`, `_progressFor`, `_xpFor`. Adding the enum value REQUIRES a branch in every one or the analyzer errors. All are covered below.

- [ ] **Step 1: Add the l10n prompt key**

In `linguaquest/lib/l10n/app_en.arb`, add:

```json
  "trainingPromptListening": "Listen and choose the word you heard",
  "@trainingPromptListening": {}
```

In `app_zh.arb`:

```json
  "trainingPromptListening": "听音频，选择你听到的词"
```

In `app_ms.arb`:

```json
  "trainingPromptListening": "Dengar dan pilih perkataan yang anda dengar"
```

Run `flutter gen-l10n` (or rely on the build to regenerate) so `l10n.trainingPromptListening` exists.

- [ ] **Step 2: Write the failing test**

Create `linguaquest/test/features/training/listening_sprint_test.dart`. Test the question builder via a public helper added in Step 3 (`buildListeningQuestion`), keeping it pure/unit-testable:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/training/training_session_screen.dart';

Word _w(String word) => Word(
      id: word,
      word: word,
      phonetic: '',
      meaning: 'meaning of $word',
      definition: 'meaning of $word',
      partOfSpeech: '',
      exampleSentence: '',
      exampleTranslation: '',
      imageCue: '',
      difficulty: 'A1',
      tags: const [],
    );

void main() {
  test('listening question hides the word in options and answers with it', () {
    final words = [_w('apple'), _w('banana'), _w('cherry'), _w('date')];
    final q = buildListeningQuestion(words[0], words, 0, 'listening prompt');
    expect(q.type, QuizQuestionType.listeningWordChoice);
    expect(q.answer, 'apple');
    expect(q.options, contains('apple'));
    expect(q.options.length, greaterThanOrEqualTo(2));
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `flutter test test/features/training/listening_sprint_test.dart`
Expected: FAIL — `buildListeningQuestion` undefined / `listeningSprint` missing.

- [ ] **Step 4: Extend the enum + switches**

In `training_session_screen.dart`:

(a) Enum (~line 27-30) — add the value:

```dart
enum TrainingGameType {
  wordRush('word-rush', AppIcons.timer),
  survival('survival', AppIcons.stairs),
  spelling('spelling', AppIcons.editNote),
  listeningSprint('listening-sprint', AppIcons.hearing);
```

(b) `title()` switch — add:

```dart
    TrainingGameType.listeningSprint => l10n.trainingListening,
```

(c) `_sourceWordsForGame` `source` switch — add (same source as survival):

```dart
      TrainingGameType.listeningSprint => [...currentBookWords, ...weakWords],
```

(d) `_buildQuestions` `count` switch — add:

```dart
      TrainingGameType.listeningSprint => _survivalQuestionCount,
```

(e) `_questionFor` switch — add a case that delegates to the public helper:

```dart
      case TrainingGameType.listeningSprint:
        return buildListeningQuestion(
          word,
          words,
          index,
          l10n.trainingPromptListening,
        );
```

(f) Add the public top-level (or static) helper. Place it as a top-level function at the END of the file (so the test can import it). It needs the same `_options` logic — extract a small standalone version:

```dart
/// Builds a listening-choice question: the prompt is an instruction (the word
/// is spoken, not shown); options are candidate words incl. the answer.
QuizQuestion buildListeningQuestion(
  Word word,
  List<Word> words,
  int index,
  String prompt,
) {
  final values = words.map((w) => w.word).toList();
  final options = <String>[];
  final seen = <String>{};
  void add(String v) {
    final key = v.trim().toLowerCase();
    if (v.trim().isNotEmpty && seen.add(key)) options.add(v.trim());
  }
  add(word.word);
  for (var step = 0; step < values.length && options.length < 4; step++) {
    add(values[(index + step + 1) % values.length]);
  }
  return QuizQuestion(
    id: 'listening-sprint-${word.id}-$index',
    type: QuizQuestionType.listeningWordChoice,
    prompt: prompt,
    answer: word.word,
    options: List.unmodifiable(options),
    explanation: word.exampleSentence,
    word: word,
  );
}
```

(g) `_advanceAfterFeedback` `shouldFinish` switch — add:

```dart
      TrainingGameType.listeningSprint => _index >= _questions.length - 1,
```

(h) `_submitAnswer` auto-advance branch (~line 577) — include listeningSprint with the choice-style auto-advance:

```dart
    if (game == TrainingGameType.wordRush ||
        game == TrainingGameType.survival ||
        game == TrainingGameType.listeningSprint) {
```

(i) `_progressFor` switch — add listeningSprint to the index-based case:

```dart
      case TrainingGameType.survival:
      case TrainingGameType.spelling:
      case TrainingGameType.listeningSprint:
        return ((_index + 1) / _questions.length).clamp(0.0, 1.0);
```

(j) `_dimensionFor` — listeningSprint always listening. At the top of `_dimensionFor`, add:

```dart
    if (game == TrainingGameType.listeningSprint) {
      return ReviewDimension.listening;
    }
```

(k) `_xpFor` switch — add:

```dart
      TrainingGameType.listeningSprint =>
        (_correct * 4 + accuracyBonus).clamp(0, 80).toInt(),
```

- [ ] **Step 5: Render the audio prompt**

In the prompt panel `build` (the `_PromptPanel`-style widget, ~line 815), add an audio control for listening questions after the prompt `Text`. Add (alongside the `if (isAudioSpelling)` block):

```dart
          if (game == TrainingGameType.listeningSprint) ...[
            const SizedBox(height: 10),
            Center(
              child: PronunciationControls(
                word: question.word.word,
                audioUKUrl: question.word.audioUKUrl,
                audioUSUrl: question.word.audioUSUrl,
                compact: true,
                language: language,
              ),
            ),
          ],
```

(Confirm the `PronunciationControls` parameter names by reading `pronunciation_controls.dart` — pass `audioUKUrl`/`audioUSUrl` if supported so it plays the word's audio URL before TTS fallback; if those params don't exist, pass just `word` + `language`.)

- [ ] **Step 6: Enable the Training row**

In `training_screen.dart` (~line 88), change the Listening row's `onTap: null` to:

```dart
            _TrainingGameRow(
              icon: AppIcons.hearing,
              title: l10n.trainingListening,
              color: AppTokens.mangoColor(context),
              onTap: () => context.push('/training/listening-sprint'),
            ),
```

- [ ] **Step 7: Run tests + analyze**

Run: `flutter test test/features/training/listening_sprint_test.dart`
Expected: PASS
Run: `flutter analyze lib/features/training`
Expected: No issues (all switches exhaustive).
Run: `flutter test`
Expected: all green (no regressions from the enum change).

- [ ] **Step 8: Commit**

```bash
git add linguaquest/lib/features/training linguaquest/lib/l10n/app_en.arb linguaquest/lib/l10n/app_zh.arb linguaquest/lib/l10n/app_ms.arb linguaquest/test/features/training/listening_sprint_test.dart
git commit -m "feat(training): Listening Sprint drill (audio -> pick the word)"
```

---

### Task 6: Passage Cloze training drill

**Files:**
- Create: `linguaquest/lib/features/training/passage_cloze_screen.dart`
- Create: `linguaquest/lib/features/training/passage_cloze_questions.dart` (pure helper)
- Modify: `linguaquest/lib/core/routing/app_router.dart` (literal route BEFORE `/training/:game`)
- Modify: `linguaquest/lib/features/training/training_screen.dart` (the Passage Cloze row onTap ~line 82)
- Test: `linguaquest/test/features/training/passage_cloze_questions_test.dart` (new)

**Interfaces:**
- Consumes: `askAi(featureType:'cloze', ...)`; `completeTraining(...)`; `QuizQuestion`, `ExerciseRecord`, `LessonResult`, `WordChoiceButton`, `AiErrorCard`.
- Produces: `passageClozeQuestions(Map<String,dynamic> aiResult, List<Word> wordbook) → List<QuizQuestion>`; route `/training/passage-cloze` → `PassageClozeScreen`.

**Design:** Passage Cloze is a self-contained screen (does NOT extend `TrainingGameType`, avoiding the engine's sync-only assumptions). It fetches one AI cloze, converts blanks to `contextChoice` `QuizQuestion`s, lets the user answer each, then records a training result for XP via `completeTraining`.

- [ ] **Step 1: Write the failing test (pure helper)**

Create `linguaquest/test/features/training/passage_cloze_questions_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/features/training/passage_cloze_questions.dart';

void main() {
  test('converts AI blanks into contextChoice questions', () {
    final ai = {
      'passage': 'I ___ to school and ___ a book.',
      'blanks': [
        {'index': 0, 'answer': 'walk', 'options': ['walk', 'run', 'fly', 'swim']},
        {'index': 1, 'answer': 'read', 'options': ['read', 'eat', 'cut', 'see']},
      ],
    };
    final qs = passageClozeQuestions(ai, const <Word>[]);
    expect(qs.length, 2);
    expect(qs[0].type, QuizQuestionType.contextChoice);
    expect(qs[0].answer, 'walk');
    expect(qs[0].options, containsAll(<String>['walk', 'run']));
    // The active blank is shown; the prompt references the passage.
    expect(qs[0].prompt, contains('school'));
  });

  test('returns empty when blanks are missing or malformed', () {
    expect(passageClozeQuestions(const {}, const <Word>[]), isEmpty);
    expect(passageClozeQuestions({'blanks': 'nope'}, const <Word>[]), isEmpty);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `flutter test test/features/training/passage_cloze_questions_test.dart`
Expected: FAIL — file/function undefined.

- [ ] **Step 3: Implement the pure helper**

Create `linguaquest/lib/features/training/passage_cloze_questions.dart`:

```dart
import '../../data/models/lesson.dart';

/// Converts an AI `/ai/cloze` result `{passage, blanks:[{index,answer,options}]}`
/// into one [QuizQuestion] per blank (type [QuizQuestionType.contextChoice]).
///
/// Each question's prompt is the passage with the active blank shown as `____`
/// and the other blanks filled with their answers (for readability). Returns an
/// empty list when the result is malformed or has no usable blanks.
List<QuizQuestion> passageClozeQuestions(
  Map<String, dynamic> aiResult,
  List<Word> wordbook,
) {
  final passage = aiResult['passage'] as String? ?? '';
  final rawBlanks = aiResult['blanks'];
  if (passage.isEmpty || rawBlanks is! List) return const [];

  final blanks = <Map<String, dynamic>>[];
  for (final b in rawBlanks) {
    if (b is Map) blanks.add(Map<String, dynamic>.from(b));
  }
  if (blanks.isEmpty) return const [];

  final byWord = {for (final w in wordbook) w.word.trim().toLowerCase(): w};

  String renderForActive(int activeIdx) {
    // Replace the i-th "___" run: active -> "____", others -> their answer.
    var result = passage;
    final marker = RegExp('_+');
    var seen = 0;
    result = result.replaceAllMapped(marker, (m) {
      final i = seen++;
      if (i == activeIdx) return '____';
      final ans = (i < blanks.length ? blanks[i]['answer'] : null) as String?;
      return ans ?? '____';
    });
    // If the passage has no underscores, append the active blank cue.
    if (seen == 0) return '$passage\n\n(Blank ${activeIdx + 1})';
    return result;
  }

  final questions = <QuizQuestion>[];
  for (var i = 0; i < blanks.length; i++) {
    final answer = (blanks[i]['answer'] as String? ?? '').trim();
    if (answer.isEmpty) continue;
    final options =
        (blanks[i]['options'] as List<dynamic>?)?.whereType<String>().toList() ??
            <String>[answer];
    if (!options.contains(answer)) options.insert(0, answer);
    final word = byWord[answer.toLowerCase()] ??
        Word(
          id: 'cloze-$i-$answer',
          word: answer,
          phonetic: '',
          meaning: '',
          definition: '',
          partOfSpeech: '',
          exampleSentence: passage,
          exampleTranslation: '',
          imageCue: '',
          difficulty: 'A1',
          tags: const [],
        );
    questions.add(
      QuizQuestion(
        id: 'passage-cloze-$i',
        type: QuizQuestionType.contextChoice,
        prompt: renderForActive(i),
        answer: answer,
        options: List.unmodifiable(options),
        explanation: passage,
        word: word,
      ),
    );
  }
  return questions;
}
```

> The `Word(...)` constructor above matches `lib/data/models/lesson.dart` (required: id, word, phonetic, meaning, definition, partOfSpeech, exampleSentence, exampleTranslation, imageCue, difficulty, tags). `QuizQuestion` required fields: id, type, prompt, answer, options, explanation, word — all supplied.

- [ ] **Step 4: Run the helper test**

Run: `flutter test test/features/training/passage_cloze_questions_test.dart`
Expected: PASS

- [ ] **Step 5: Create the screen**

Create `linguaquest/lib/features/training/passage_cloze_screen.dart`. It: fetches `/ai/cloze` from the current wordbook words on init; shows loading/error/retry; renders the passage + per-blank choices; on finishing all blanks, records a training result via `completeTraining` and navigates to the shared result screen.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/word_choice_button.dart';
import '../../data/models/exercise_record.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../l10n/generated/app_localizations.dart';
import '../quiz/lesson_result_screen.dart';
import 'passage_cloze_questions.dart';

class PassageClozeScreen extends ConsumerStatefulWidget {
  const PassageClozeScreen({super.key});

  @override
  ConsumerState<PassageClozeScreen> createState() => _PassageClozeScreenState();
}

class _PassageClozeScreenState extends ConsumerState<PassageClozeScreen> {
  static const _gameId = 'passage-cloze';
  late final DateTime _startedAt;
  List<QuizQuestion> _questions = const [];
  final Map<int, String> _selected = {};
  bool _isLoading = true;
  String? _error;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _selected.clear();
    });
    final state = ref.read(appControllerProvider);
    final words = state.trainingWords;
    final seed = words.isNotEmpty ? words.first.word : 'study';
    final result = await ref.read(appControllerProvider.notifier).askAi(
          featureType: 'cloze',
          prompt: 'Write a short passage with several blanks using these words: '
              '${words.take(6).map((w) => w.word).join(', ')}',
          targetWord: seed,
        );
    if (!mounted) return;
    final qs = passageClozeQuestions(result, words);
    setState(() {
      _isLoading = false;
      if (result.isEmpty) {
        _error = ref.read(appControllerProvider).errorMessage ??
            AppLocalizations.of(context).aiErrorGeneric;
      } else if (qs.isEmpty) {
        _error = AppLocalizations.of(context).aiErrorGeneric;
      } else {
        _questions = qs;
      }
    });
  }

  bool get _allAnswered => _selected.length >= _questions.length;

  Future<void> _finish() async {
    if (_submitting || !_allAnswered) return;
    setState(() => _submitting = true);
    final notifier = ref.read(appControllerProvider.notifier);
    final uid = ref.read(appControllerProvider).user?.uid ?? '';
    final now = DateTime.now();
    var correct = 0;
    final records = <ExerciseRecord>[];
    final mistakes = <QuizQuestion>[];
    for (var i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      final ans = _selected[i] ?? '';
      final ok = ans.trim().toLowerCase() == q.answer.trim().toLowerCase();
      if (ok) correct++; else mistakes.add(q);
      records.add(ExerciseRecord(
        id: 'exercise-${now.microsecondsSinceEpoch}-$i',
        uid: uid,
        sessionId: 'pending',
        gameId: _gameId,
        wordId: q.word.id,
        promptType: q.type.name,
        isCorrect: ok,
        answer: ans.trim(),
        correctAnswer: q.answer,
        answerTimeMs: 0,
        dimension: ReviewDimension.context,
        createdAt: now,
      ));
    }
    final accuracy = _questions.isEmpty ? 0.0 : correct / _questions.length;
    final xp = (correct * 5 + (accuracy * 10).round()).clamp(0, 80).toInt();
    final result = LessonResult(
      lessonId: _gameId,
      lessonTitle: AppLocalizations.of(context).trainingPassageCloze,
      totalQuestions: _questions.length,
      correctAnswers: correct,
      xpEarned: xp,
      mistakes: List.unmodifiable(mistakes),
      completedAt: now,
    );
    final ok = await notifier.completeTraining(
      result: result,
      gameId: _gameId,
      startedAt: _startedAt,
      exerciseRecords: List.unmodifiable(records),
    );
    if (!mounted) return;
    if (!ok) {
      setState(() => _submitting = false);
      return;
    }
    context.go('/lesson/$_gameId/result',
        extra: LessonResultViewArgs(
            result: result, source: LessonResultSource.training));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trainingPassageCloze),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/training')),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(padding: const EdgeInsets.all(20), children: [
                    AiErrorCard(message: _error!, onRetry: _load),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                    children: [
                      for (var i = 0; i < _questions.length; i++)
                        _BlankCard(
                          index: i,
                          question: _questions[i],
                          selected: _selected[i],
                          onSelect: (opt) =>
                              setState(() => _selected[i] = opt),
                        ),
                    ],
                  ),
      ),
      bottomNavigationBar: (_isLoading || _error != null)
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.s16),
                child: AppPrimaryButton(
                  label: _submitting
                      ? 'Submitting...'
                      : _allAnswered
                          ? 'Finish'
                          : 'Answer all blanks',
                  onPressed: (_allAnswered && !_submitting) ? _finish : null,
                ),
              ),
            ),
    );
  }
}

class _BlankCard extends StatelessWidget {
  const _BlankCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  final int index;
  final QuizQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  static const _letters = ['A', 'B', 'C', 'D', 'E', 'F'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s16),
      child: AppCard(
        padding: const EdgeInsets.all(AppTokens.s16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question.prompt, style: theme.textTheme.bodyLarge),
            const SizedBox(height: AppTokens.s12),
            for (var o = 0; o < question.options.length; o++)
              Padding(
                padding: const EdgeInsets.only(bottom: AppTokens.s8),
                child: WordChoiceButton(
                  letter: o < _letters.length ? _letters[o] : '${o + 1}',
                  text: question.options[o],
                  state: selected == null
                      ? ChoiceState.idle
                      : question.options[o] == selected
                          ? (selected == question.answer
                              ? ChoiceState.correct
                              : ChoiceState.wrong)
                          : (question.options[o] == question.answer
                              ? ChoiceState.correct
                              : ChoiceState.idle),
                  onTap: selected == null
                      ? () => onSelect(question.options[o])
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

> Field names above are verified against the engine: `ExerciseRecord` (id, uid, sessionId, gameId, wordId, promptType, isCorrect, answer, correctAnswer, answerTimeMs, dimension, createdAt), `LessonResult` (lessonId, lessonTitle, totalQuestions, correctAnswers, xpEarned, mistakes, completedAt), `context.go('/lesson/<id>/result', extra: LessonResultViewArgs(result:, source: LessonResultSource.training))`, `WordChoiceButton(letter, text, state, onTap)` with `ChoiceState{idle,selected,correct,wrong}`. `completeTraining({result, gameId, startedAt, exerciseRecords})` returns `Future<bool>`.

- [ ] **Step 6: Register the route BEFORE `/training/:game`**

In `app_router.dart`, add import:

```dart
import '../../features/training/passage_cloze_screen.dart';
```

Add this route **immediately before** the `path: '/training/:game'` route (so the literal wins):

```dart
      GoRoute(
        path: '/training/passage-cloze',
        builder: (context, state) => const PassageClozeScreen(),
      ),
```

- [ ] **Step 7: Enable the Training row**

In `training_screen.dart` (~line 82), change the Passage Cloze row's `onTap: null` to:

```dart
            _TrainingGameRow(
              icon: AppIcons.article,
              title: l10n.trainingPassageCloze,
              color: AppTokens.successColor(context),
              onTap: () => context.push('/training/passage-cloze'),
            ),
```

- [ ] **Step 8: Run tests + analyze**

Run: `flutter test test/features/training/passage_cloze_questions_test.dart`
Expected: PASS
Run: `flutter analyze lib/features/training lib/core/routing/app_router.dart`
Expected: No issues.
Run: `flutter test`
Expected: all green.

- [ ] **Step 9: Commit**

```bash
git add linguaquest/lib/features/training/passage_cloze_screen.dart linguaquest/lib/features/training/passage_cloze_questions.dart linguaquest/lib/core/routing/app_router.dart linguaquest/lib/features/training/training_screen.dart linguaquest/test/features/training/passage_cloze_questions_test.dart
git commit -m "feat(training): Passage Cloze drill (AI-generated passage, scored)"
```

---

## Final verification (after all tasks)

- [ ] From `linguaquest/`: `flutter analyze` → no issues; `flutter test` → all green.
- [ ] From `server/`: `dart analyze` → no issues; `dart test` → all green.
- [ ] **Deploy** the new server `/ai/confusion` + `/ai/sentence` routes to the live host (same flow as Cycle 1: rsync server code excl. secrets → `vps_deploy.sh`), gated on explicit user approval. The two training drills + the two AI screens are client-side and ship in the APK.
- [ ] **On-device (AVD)**: rebuild + install the APK; verify AI Learn → Confusable Words and Sentence Generation now show "Available" and return results; Training → Listening Sprint plays audio and scores; Training → Passage Cloze loads a passage and scores.

## Self-review notes
- Spec Feature A → Task 1 (server) + Task 2 (plumbing) + Task 3 (screen).
- Spec Feature B → Task 1 + Task 2 + Task 4.
- Spec Feature C (Passage Cloze) → Task 6 (dedicated screen + pure helper; uses existing `/ai/cloze` and `completeTraining`).
- Spec Feature D (Listening Sprint) → Task 5 (engine extension).
- Testing + error-handling requirements covered per task; deploy + AVD in final verification.
