# AI Output Language Policy + Multi-Language Generalization — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make AI explanations come back in English while keeping the taught content in the learner's target language, and drive the target language from `AppState.targetLanguage` instead of a hardcoded "Chinese".

**Architecture:** Server builds each AI system prompt from a target-language name (resolved from a code) with per-field language rules; `AiRequest` carries a `targetLanguage` code (default `'zh'`). The Flutter app threads `AppState.targetLanguage` from the controller through the AI repository into each request body. UI screens and JSON response schemas are unchanged.

**Tech Stack:** Dart `shelf` server (OpenAI-compatible LLM via `package:http`), Flutter + Riverpod + Dio, `package:test` / `flutter_test`.

## Global Constraints

- Do NOT change AI JSON response structure or field names.
- Do NOT change the AI UI screens (no redesign — explicitly deferred).
- Do NOT change provider call logic, temperature, retry, or the daily-limit/safety policy.
- Backward compatible: a request without `targetLanguage` defaults to `'zh'` → "Chinese"; unknown codes fall back to "Chinese".
- `EmailSender`/unrelated code untouched. Work only in the AI path.
- Per-field language policy (verbatim):
  - chat: `answer`,`cautions` → English; `relatedWords` → target language.
  - sentence_analysis: `translation`,`vocabularyNotes` → English; `mainClause`,`clauses`,`modifiers` → target language.
  - cloze: `explanations` → English; `passage`,`blanks[].answer`,`blanks[].options` → target language.
  - writing_review: `mainIssues`,`paragraphSuggestions[].suggestion`,`highScoreExpressions`,`grammarIssues[].rule` → English; `rewrittenSample` + quoted student text → essay's original language.
- Project convention: commits must NOT contain a Co-Authored-By trailer.
- Server commands run from `server/`; Flutter commands from `linguaquest/`.

---

### Task 1: Server — parameterized system prompts + `AiRequest.targetLanguage` + route plumbing

**Files:**
- Modify: `server/lib/src/ai_policy.dart` (AiRequest field, language-name map, `buildSystemPrompt`, `RemoteAiProvider.generate` wiring; remove the static `_systemPrompts` map)
- Modify: `server/lib/src/routes.dart` (read `targetLanguage` in `_handleAiRequest` and the `/ai/writing-review` handler)
- Create: `server/test/ai_system_prompt_test.dart`
- Modify: `server/test/remote_ai_provider_test.dart`

**Interfaces:**
- Consumes: existing `AiProvider`, `AiResponse`, `AiPolicyService`.
- Produces:
  - `AiRequest({required featureType, required userId, required prompt, targetWord, targetLanguage = 'zh'})` with `final String targetLanguage;`.
  - `String languageNameFor(String code)` (top-level in ai_policy.dart) → 'Chinese' for unknown.
  - `String? buildSystemPrompt(String featureType, String language)` (top-level) → null for unknown feature.

- [ ] **Step 1: Write failing unit tests for the prompt builder**

Create `server/test/ai_system_prompt_test.dart`:

```dart
import 'package:test/test.dart';

import '../lib/src/ai_policy.dart';

void main() {
  group('languageNameFor', () {
    test('maps known codes to English names', () {
      expect(languageNameFor('zh'), 'Chinese');
      expect(languageNameFor('ja'), 'Japanese');
      expect(languageNameFor('es'), 'Spanish');
      expect(languageNameFor('fr'), 'French');
      expect(languageNameFor('ms'), 'Malay');
    });
    test('falls back to Chinese for unknown/empty', () {
      expect(languageNameFor('xx'), 'Chinese');
      expect(languageNameFor(''), 'Chinese');
    });
  });

  group('buildSystemPrompt', () {
    test('chat: explanations English, relatedWords target language', () {
      final p = buildSystemPrompt('chat', 'Chinese')!;
      expect(p, contains('Chinese-learning assistant'));
      expect(p, contains('"answer" and "cautions" in English'));
      expect(p, contains('"relatedWords"'));
      expect(p, contains('Chinese'));
    });
    test('sentence_analysis: clause fields stay target language', () {
      final p = buildSystemPrompt('sentence_analysis', 'Japanese')!;
      expect(p, contains('Japanese'));
      expect(p, contains('"translation" and "vocabularyNotes" in English'));
    });
    test('cloze: passage/options target language, explanations English', () {
      final p = buildSystemPrompt('cloze', 'Chinese')!;
      expect(p, contains('"explanations" in English'));
      expect(p, contains('"passage"'));
    });
    test('writing_review: feedback English', () {
      final p = buildSystemPrompt('writing_review', 'Chinese')!;
      expect(p, contains('in English'));
      expect(p, contains('"rewrittenSample"'));
    });
    test('unknown feature returns null', () {
      expect(buildSystemPrompt('nope', 'Chinese'), isNull);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `dart test test/ai_system_prompt_test.dart`
Expected: FAIL — `languageNameFor` and `buildSystemPrompt` are not defined.

- [ ] **Step 3: Add `targetLanguage` to `AiRequest`**

In `server/lib/src/ai_policy.dart`, replace the `AiRequest` class (lines 24-36) with:

```dart
class AiRequest {
  const AiRequest({
    required this.featureType,
    required this.userId,
    required this.prompt,
    this.targetWord,
    this.targetLanguage = 'zh',
  });

  final String featureType;
  final String userId;
  final String prompt;
  final String? targetWord;
  final String targetLanguage;
}
```

- [ ] **Step 4: Add the language-name map and `buildSystemPrompt`; remove the const `_systemPrompts`**

In `server/lib/src/ai_policy.dart`, add these top-level declarations (place them just above the `class RemoteAiProvider` declaration):

```dart
const _languageNames = <String, String>{
  'zh': 'Chinese',
  'ms': 'Malay',
  'es': 'Spanish',
  'fr': 'French',
  'ja': 'Japanese',
};

/// Resolves a target-language code (e.g. 'zh') to its English name. Unknown or
/// empty codes fall back to Chinese (the only language shipping today).
String languageNameFor(String code) => _languageNames[code] ?? 'Chinese';

/// Builds the LLM system prompt for [featureType] in [language] (an English
/// language name). Explanatory fields are English; taught content stays in
/// [language]. Returns null for an unknown feature.
String? buildSystemPrompt(String featureType, String language) {
  switch (featureType) {
    case 'chat':
      return 'You are a $language-learning assistant for English speakers. '
          'Write "answer" and "cautions" in English. Keep "relatedWords" as '
          '$language words. Reply ONLY with strict JSON: '
          '{"answer": string, "cautions": string[], "relatedWords": string[]}. '
          'No markdown, no code fences.';
    case 'sentence_analysis':
      return 'Analyze the $language sentence. Keep "mainClause", "clauses", '
          'and "modifiers" in the original $language; write "translation" and '
          '"vocabularyNotes" in English. Reply ONLY with strict JSON: '
          '{"mainClause": string, "clauses": string[], "modifiers": string[], '
          '"translation": string, "vocabularyNotes": string[]}. '
          'No markdown, no code fences.';
    case 'cloze':
      return 'Create a $language cloze exercise for the target word. Keep the '
          '"passage" and each blank\'s "answer" and "options" in $language; '
          'write "explanations" in English. Reply ONLY with strict JSON: '
          '{"passage": string, "blanks": [{"index": number, "answer": string, '
          '"options": string[]}], "explanations": string[]}. '
          'No markdown, no code fences.';
    case 'writing_review':
      return 'You are a $language writing grader for English speakers. Write '
          'all feedback ("mainIssues", "paragraphSuggestions", '
          '"highScoreExpressions", and each grammar issue\'s "rule") in '
          'English; keep "rewrittenSample" and any quoted student text in the '
          'language of the original essay. Reply ONLY with strict JSON: '
          '{"totalScore": number, "rubricScores": {"content": number, '
          '"language": number, "structure": number, "vocabulary": number, '
          '"accuracy": number}, "mainIssues": string[], "paragraphSuggestions": '
          '[{"paragraph": number, "suggestion": string}], '
          '"highScoreExpressions": string[], "grammarIssues": [{"original": '
          'string, "corrected": string, "rule": string}], "rewrittenSample": '
          'string}. No markdown, no fences.';
  }
  return null;
}
```

Then DELETE the static `_systemPrompts` const map inside `RemoteAiProvider` (lines 204-227, the `static const Map<String, String> _systemPrompts = {...};` block).

- [ ] **Step 5: Wire `RemoteAiProvider.generate` to use the builder**

In `server/lib/src/ai_policy.dart`, in `generate()` (currently lines 230-272), replace the opening lines:

```dart
    final system = _systemPrompts[request.featureType];
    if (system == null) {
```

with:

```dart
    final system = buildSystemPrompt(
      request.featureType,
      languageNameFor(request.targetLanguage),
    );
    if (system == null) {
```

(The rest of `generate()` — userContent, body, `_postWithRetry`, parsing — is unchanged.)

- [ ] **Step 6: Run the prompt-builder test to verify it passes**

Run: `dart test test/ai_system_prompt_test.dart`
Expected: PASS — all tests green.

- [ ] **Step 7: Add request-body assertions to `remote_ai_provider_test.dart`**

In `server/test/remote_ai_provider_test.dart`, add these tests inside the `group('RemoteAiProvider', () {` block (after the existing `'sends bearer key...'` test):

```dart
    test('system prompt names the target language and locks explanations to '
        'English (default zh -> Chinese)', () async {
      String? body;
      final client = MockClient((req) async {
        body = req.body;
        return _chatOk();
      });
      await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hi'),
      );
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      final system =
          (decoded['messages'] as List).first as Map<String, dynamic>;
      expect(system['role'], 'system');
      expect(system['content'], contains('Chinese-learning assistant'));
      expect(system['content'], contains('in English'));
    });

    test('honors a non-default targetLanguage', () async {
      String? body;
      final client = MockClient((req) async {
        body = req.body;
        return _chatOk();
      });
      await _provider(client).generate(
        const AiRequest(
          featureType: 'chat',
          userId: 'u1',
          prompt: 'hi',
          targetLanguage: 'ja',
        ),
      );
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      final system =
          (decoded['messages'] as List).first as Map<String, dynamic>;
      expect(system['content'], contains('Japanese-learning assistant'));
    });

    test('unknown targetLanguage falls back to Chinese', () async {
      String? body;
      final client = MockClient((req) async {
        body = req.body;
        return _chatOk();
      });
      await _provider(client).generate(
        const AiRequest(
          featureType: 'chat',
          userId: 'u1',
          prompt: 'hi',
          targetLanguage: 'xx',
        ),
      );
      final decoded = jsonDecode(body!) as Map<String, dynamic>;
      final system =
          (decoded['messages'] as List).first as Map<String, dynamic>;
      expect(system['content'], contains('Chinese-learning assistant'));
    });
```

- [ ] **Step 8: Plumb `targetLanguage` through the routes**

In `server/lib/src/routes.dart`, in `_handleAiRequest` (lines 982-1022), after `final targetWord = body['targetWord'] as String?;` add:

```dart
    final targetLanguage = body['targetLanguage'] as String? ?? 'zh';
```

and change the `AiRequest(...)` construction to include it:

```dart
    final aiRequest = AiRequest(
      featureType: featureType,
      userId: uid,
      prompt: prompt,
      targetWord: targetWord,
      targetLanguage: targetLanguage,
    );
```

In the `/ai/writing-review` handler (lines 1304-1347), after `final targetScore = body['targetScore'];` add:

```dart
      final targetLanguage = body['targetLanguage'] as String? ?? 'zh';
```

and change its `AiRequest(...)` to include `targetLanguage: targetLanguage,`:

```dart
      final aiRequest = AiRequest(
        featureType: 'writing_review',
        userId: uid,
        prompt: aiPrompt,
        targetLanguage: targetLanguage,
      );
```

- [ ] **Step 9: Run the full server suite + analyze**

Run: `dart test`
Expected: all tests pass (new `ai_system_prompt_test.dart`, updated `remote_ai_provider_test.dart`, and existing `ai_routes_test.dart` which still uses MockAiProvider and is unaffected).

Run: `dart analyze`
Expected: `No issues found!`

- [ ] **Step 10: Commit**

```bash
git add server/lib/src/ai_policy.dart server/lib/src/routes.dart \
  server/test/ai_system_prompt_test.dart server/test/remote_ai_provider_test.dart
git commit -m "feat(ai): build system prompts per target language, lock explanations to English"
```

---

### Task 2: App — thread `targetLanguage` from state into AI requests

**Files:**
- Modify: `linguaquest/lib/data/repositories/ai_repository.dart` (interface)
- Modify: `linguaquest/lib/data/repositories/api_repositories.dart` (send `targetLanguage`)
- Modify: `linguaquest/lib/data/repositories/mock_repositories.dart` (accept param)
- Modify: `linguaquest/lib/core/state/app_controller.dart` (pass `state.targetLanguage`)
- Modify: `linguaquest/test/ai_learning_test.dart` (update mock calls)

**Interfaces:**
- Consumes: server now reads `targetLanguage` from the AI request body (Task 1).
- Produces: `AiRepository` methods `chat`/`analyzeStatement`/`generateCloze`/`reviewWriting` each take `required String targetLanguage`.

- [ ] **Step 1: Update the `AiRepository` interface**

Replace `linguaquest/lib/data/repositories/ai_repository.dart` entirely with:

```dart
import '../models/ai_feature.dart';

abstract class AiRepository {
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  });

  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
    required String targetLanguage,
  });

  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  });

  Future<List<AiHistoryEntry>> listHistory();

  Future<void> deleteHistory(String id);

  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    required String targetLanguage,
    String? examType,
    double? targetScore,
  });
}
```

- [ ] **Step 2: Run analyze to see the implementations fail to compile**

Run (from `linguaquest/`): `flutter analyze lib/data/repositories/`
Expected: errors — `ApiAiRepository` and `MockAiRepository` don't satisfy the new interface (missing `targetLanguage`).

- [ ] **Step 3: Send `targetLanguage` from `ApiAiRepository`**

In `linguaquest/lib/data/repositories/api_repositories.dart`, update the four AI methods to accept and send `targetLanguage` (keep the existing `options: Options(receiveTimeout: _aiTimeout)`):

`chat`:
```dart
  @override
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/chat',
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

`analyzeStatement`:
```dart
  @override
  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
    required String targetLanguage,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/sentence-analysis',
      data: {'prompt': prompt, 'targetLanguage': targetLanguage},
      options: Options(receiveTimeout: _aiTimeout),
    );
    return response.data!['data'] as Map<String, dynamic>;
  }
```

`generateCloze`:
```dart
  @override
  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/cloze',
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

`reviewWriting`:
```dart
  @override
  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    required String targetLanguage,
    String? examType,
    double? targetScore,
  }) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      '/ai/writing-review',
      data: {
        'prompt': essay,
        'examType': ?examType,
        'targetScore': ?targetScore,
        'targetLanguage': targetLanguage,
      },
      options: Options(receiveTimeout: _aiTimeout),
    );
    return (response.data?['data'] as Map<String, dynamic>?) ?? {};
  }
```

- [ ] **Step 4: Accept (ignore) `targetLanguage` in `MockAiRepository`**

In `linguaquest/lib/data/repositories/mock_repositories.dart`, add `required String targetLanguage,` to the parameter list of `MockAiRepository.chat`, `analyzeStatement`, `generateCloze`, and `reviewWriting`. The mock bodies are unchanged (it ignores the value). For example `chat` becomes:

```dart
  @override
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
```

Do the same for `analyzeStatement` (add `required String targetLanguage,`), `generateCloze` (add `required String targetLanguage,`), and `reviewWriting` (add `required String targetLanguage,`). Leave every method body exactly as-is.

- [ ] **Step 5: Pass `state.targetLanguage` from the controller**

In `linguaquest/lib/core/state/app_controller.dart`, in `askAi` (lines 2417-2445), update the three repo calls to pass `targetLanguage: state.targetLanguage`:

```dart
        case 'chat':
          result = await repo.chat(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.targetLanguage,
          );
        case 'sentence_analysis':
          result = await repo.analyzeStatement(
            prompt: prompt,
            targetLanguage: state.targetLanguage,
          );
        case 'cloze':
          result = await repo.generateCloze(
            prompt: prompt,
            targetWord: targetWord,
            targetLanguage: state.targetLanguage,
          );
```

In `reviewWriting` (lines 2447-2465), update the call:

```dart
      final result = await ref.read(aiRepositoryProvider).reviewWriting(
        essay: essay,
        examType: examType,
        targetScore: targetScore,
        targetLanguage: state.targetLanguage,
      );
```

- [ ] **Step 6: Update the mock-repository tests for the new required param**

In `linguaquest/test/ai_learning_test.dart`, add `targetLanguage: 'zh'` to every `repo.chat(...)`, `repo.analyzeStatement(...)`, `repo.generateCloze(...)`, and `repo.reviewWriting(...)` call. For example:

```dart
    test('chat returns structured mock response', () async {
      final result = await repo.chat(
        prompt: 'What does hello mean?',
        targetLanguage: 'zh',
      );
      expect(result['answer'], isA<String>());
      expect(result['cautions'], isA<List>());
      expect(result['relatedWords'], isA<List>());
    });
```

Apply the same `targetLanguage: 'zh'` addition to the `analyzeStatement`, `generateCloze`, the two `chat` calls in the `listHistory`/`deleteHistory` tests, and any `reviewWriting` call. If `linguaquest/test/ai_writing_review_test.dart` calls `reviewWriting(...)` on a mock/fake repo, add `targetLanguage: 'zh'` there too.

- [ ] **Step 7: Run analyze + the AI tests**

Run (from `linguaquest/`):
`flutter analyze lib/data/repositories/ lib/core/state/app_controller.dart`
Expected: `No issues found!`

Run: `flutter test test/ai_learning_test.dart test/ai_writing_review_test.dart`
Expected: all pass.

- [ ] **Step 8: Full app analyze (catch any other caller of the AI repo methods)**

Run (from `linguaquest/`): `flutter analyze`
Expected: `No issues found!` (if any screen calls `repo.chat`/etc. directly, it will surface here — there should be none, since screens go through `AppController.askAi`).

- [ ] **Step 9: Commit**

```bash
git add linguaquest/lib/data/repositories/ai_repository.dart \
  linguaquest/lib/data/repositories/api_repositories.dart \
  linguaquest/lib/data/repositories/mock_repositories.dart \
  linguaquest/lib/core/state/app_controller.dart \
  linguaquest/test/ai_learning_test.dart
git commit -m "feat(ai): send target language with AI requests from the app"
```

---

### Task 3: Deploy + live verification + rebuild APK

This task has no unit tests of its own (it is deployment + end-to-end verification of Tasks 1-2). It produces the acceptance evidence.

**Files:** none (deploy + verify).

- [ ] **Step 1: Sync server code to the VPS and redeploy**

Run (from repo root `/Users/lanyichen/Codes/Mobile/ASM2`):
```bash
rsync -azi --exclude '.env' --exclude '.env.*' --exclude '.dart_tool' \
  --exclude 'build/' --exclude '.git' --exclude '.DS_Store' --exclude '*.bak.*' \
  server/ intro-server:/home/deploy/linguaquest/server/
ssh intro-server 'cd /home/deploy/linguaquest/server && ./deploy/vps_deploy.sh'
```
Expected: image rebuilds, `server_api_1` restarts, db untouched (healthy).

- [ ] **Step 2: Live-verify English explanations + target-language content**

Obtain a token (login or reuse a verified account), then:
```bash
curl -s -X POST https://api.vonlan233.top/ai/chat \
  -H "Authorization: Bearer <TOKEN>" -H 'Content-Type: application/json' \
  -d '{"prompt":"卧槽是什么意思","targetLanguage":"zh"}'
```
Expected: HTTP 200; `data.answer` is in **English** (explaining 卧槽); `data.relatedWords` (if any) are Chinese. Contrast with the old behavior (Chinese answer).

- [ ] **Step 3: Verify a non-default language reaches the prompt**

```bash
curl -s -X POST https://api.vonlan233.top/ai/chat \
  -H "Authorization: Bearer <TOKEN>" -H 'Content-Type: application/json' \
  -d '{"prompt":"What does こんにちは mean?","targetLanguage":"ja"}'
```
Expected: HTTP 200; `answer` in English. (Confirms the language code is plumbed end to end; only `zh` ships in the app UI today, but the server honors others.)

- [ ] **Step 4: Rebuild the APK so the app sends `targetLanguage`**

Run (from `linguaquest/`):
```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.vonlan233.top
```
Expected: `Built build/app/outputs/flutter-apk/app-release.apk`.

- [ ] **Step 5: Record evidence** — paste the `/ai/chat` responses showing the English answer, and confirm the APK built. Hand the APK to the user to install and test the AI chat (the "卧槽" case should now answer in English).
