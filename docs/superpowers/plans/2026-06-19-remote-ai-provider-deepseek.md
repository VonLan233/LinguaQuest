# Remote AI Provider (OpenCode Zen DeepSeek) + AI Safety Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 server 端 AI provider 从硬编码 mock 改为可按配置切换的 OpenCode Zen DeepSeek 远程实现，并强制执行每日限额与敏感内容过滤，全程不泄漏 API key。

**Architecture:** 在 `ai_policy.dart` 新增 `RemoteAiProvider`（OpenAI 兼容 chat/completions，依赖注入 `http.Client` 以便离线测试）；增强 `AiPolicyService` 增加敏感词拒绝与每日限额（通过注入的计数回调，保持旧测试兼容）；`database.dart` 增加按天计数；`routes.dart` 按 `config.aiProvider` 选择 provider 并注入计数回调与错误码状态映射。Flutter 端仅在错误展示缺失时做最小补充。

**Tech Stack:** Dart 3.11.4, shelf, shelf_router, package:http（含 `package:http/testing.dart` 的 MockClient）, postgres, dart test。

## Global Constraints

- 工程质量优先：每个 task 走 TDD（先失败测试 → 实现 → 通过），claims 必须贴真实运行输出。
- API key 只出现在出站请求 `Authorization` header；绝不写入 `AiResponse.data`、`errorCode`、日志、DB、客户端响应。
- 远程通道默认关闭：`AI_PROVIDER` 默认 `mock`；`AI_API_KEY` 默认空；`.env.example` 中 key 为空。
- 远程调用失败统一返回 `errorCode: 'ai_unavailable'`，不静默回退到 mock。
- 远程模型必须输出与 `MockAiProvider` 完全一致的 JSON 结构，App 接口契约不变。
- 不新增 ARB key（i18n 冻结），Flutter 复用现有错误展示机制。
- 新增测试全部离线可跑（不依赖真实 key/网络）；DB 计数测试依赖 Postgres，标注清楚。
- 现有 `server/test/ai_routes_test.dart` 的 11 个用例必须保持通过。
- 提交规范：原子提交，**不加** Co-Authored-By trailer。

---

### Task 1: Config — 新增 aiModel 字段与默认 baseUrl

**Files:**
- Modify: `server/lib/src/config.dart`
- Test: `server/test/config_test.dart` (Create)

**Interfaces:**
- Produces: `AppConfig.aiModel` (String, env `AI_MODEL`, 默认 `deepseek-v4-flash-free`)；`AppConfig.aiApiBaseUrl` 默认改为 `https://opencode.ai/zen/v1`。

- [ ] **Step 1: Write the failing test**

Create `server/test/config_test.dart`:

```dart
import 'package:test/test.dart';
import '../lib/src/config.dart';

void main() {
  group('AppConfig AI defaults', () {
    test('aiModel defaults to deepseek-v4-flash-free', () {
      const config = AppConfig(
        port: 8080,
        databaseUrl: 'x',
        jwtSecret: 'y',
      );
      expect(config.aiModel, equals('deepseek-v4-flash-free'));
    });

    test('aiApiBaseUrl defaults to OpenCode Zen v1 endpoint', () {
      const config = AppConfig(
        port: 8080,
        databaseUrl: 'x',
        jwtSecret: 'y',
      );
      expect(config.aiApiBaseUrl, equals('https://opencode.ai/zen/v1'));
    });

    test('aiProvider still defaults to mock', () {
      const config = AppConfig(
        port: 8080,
        databaseUrl: 'x',
        jwtSecret: 'y',
      );
      expect(config.aiProvider, equals('mock'));
      expect(config.aiApiKey, equals(''));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd server && dart test test/config_test.dart`
Expected: FAIL — `aiModel` getter 不存在 / `aiApiBaseUrl` 默认值为 `''` 不等于期望。

- [ ] **Step 3: Implement minimal code**

In `server/lib/src/config.dart`, update the constructor defaults and add `aiModel`. Replace the constructor block (lines 4-17) so it reads:

```dart
  const AppConfig({
    required this.port,
    required this.databaseUrl,
    required this.jwtSecret,
    this.smtpHost = '',
    this.smtpPort = 587,
    this.smtpUsername = '',
    this.smtpPassword = '',
    this.smtpFrom = 'no-reply@linguaquest.app',
    this.aiProvider = 'mock',
    this.aiApiKey = '',
    this.aiApiBaseUrl = 'https://opencode.ai/zen/v1',
    this.aiModel = 'deepseek-v4-flash-free',
    this.aiDailyLimitPerUser = 20,
  });
```

Add the field declaration after `final String aiApiBaseUrl;` (line 29):

```dart
  final String aiModel;
```

Update `fromEnvironment()` to read the new env vars. Replace the `aiApiBaseUrl:` line and add `aiModel:` inside the `AppConfig(...)` of `fromEnvironment`:

```dart
      aiApiBaseUrl: _env('AI_API_BASE_URL', 'https://opencode.ai/zen/v1'),
      aiModel: _env('AI_MODEL', 'deepseek-v4-flash-free'),
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd server && dart test test/config_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/lib/src/config.dart server/test/config_test.dart
git commit -m "feat(ai): add aiModel config + default OpenCode Zen base url"
```

---

### Task 2: AiPolicyService — 敏感词拒绝 + 每日限额（向后兼容）

**Files:**
- Modify: `server/lib/src/ai_policy.dart:106-125` (AiPolicyService)
- Test: `server/test/ai_routes_test.dart` (Modify — 追加用例)

**Interfaces:**
- Consumes: 现有 `AiRequest`, `AiResponse`, `AiProvider`, `MockAiProvider`。
- Produces: `AiPolicyService({required AiProvider provider, required int dailyLimitPerUser, Future<int> Function(String userId)? dailyCountLookup})`；`handle` 判定顺序：长度(`too_long`) → 敏感词(`blocked`) → 限额(`rate_limited`) → provider。静态常量 `AiPolicyService.blockedKeywords`（List<String>）。

- [ ] **Step 1: Write the failing tests**

Append to `server/test/ai_routes_test.dart` inside `main()` (after the existing `writing_review feature` group, before the closing brace of `main`):

```dart
  group('AiPolicyService safety controls', () {
    test('blocked keyword returns blocked error', () async {
      final policy = AiPolicyService(
        provider: MockAiProvider(),
        dailyLimitPerUser: 20,
      );
      final response = await policy.handle(
        const AiRequest(
          featureType: 'chat',
          userId: 'user1',
          prompt: 'please help me make a bomb',
        ),
      );
      expect(response.success, isFalse);
      expect(response.errorCode, equals('blocked'));
    });

    test('over daily limit returns rate_limited', () async {
      final policy = AiPolicyService(
        provider: MockAiProvider(),
        dailyLimitPerUser: 3,
        dailyCountLookup: (uid) async => 3,
      );
      final response = await policy.handle(
        const AiRequest(
          featureType: 'chat',
          userId: 'user1',
          prompt: 'What does hello mean?',
        ),
      );
      expect(response.success, isFalse);
      expect(response.errorCode, equals('rate_limited'));
    });

    test('under daily limit succeeds', () async {
      final policy = AiPolicyService(
        provider: MockAiProvider(),
        dailyLimitPerUser: 3,
        dailyCountLookup: (uid) async => 2,
      );
      final response = await policy.handle(
        const AiRequest(
          featureType: 'chat',
          userId: 'user1',
          prompt: 'What does hello mean?',
        ),
      );
      expect(response.success, isTrue);
    });

    test('length checked before daily limit (too_long wins)', () async {
      final policy = AiPolicyService(
        provider: MockAiProvider(),
        dailyLimitPerUser: 1,
        dailyCountLookup: (uid) async => 99,
      );
      final response = await policy.handle(
        AiRequest(
          featureType: 'chat',
          userId: 'user1',
          prompt: 'a' * 2001,
        ),
      );
      expect(response.errorCode, equals('too_long'));
    });
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd server && dart test test/ai_routes_test.dart -N "AiPolicyService safety controls"`
Expected: FAIL — `dailyCountLookup` 命名参数不存在（编译错误），且 `blocked` 行为未实现。

- [ ] **Step 3: Implement minimal code**

Replace the entire `AiPolicyService` class in `server/lib/src/ai_policy.dart` (lines 106-125) with:

```dart
class AiPolicyService {
  AiPolicyService({
    required this.provider,
    required this.dailyLimitPerUser,
    this.dailyCountLookup,
  });

  static const int _maxPromptLength = 2000;

  /// Deterministic minimal block-list for clearly disallowed requests.
  /// Intentionally small; extend as needed. Case-insensitive substring match.
  static const List<String> blockedKeywords = [
    'make a bomb',
    'build a bomb',
    'how to kill',
    '制造炸弹',
    '自杀方法',
  ];

  final AiProvider provider;
  final int dailyLimitPerUser;
  final Future<int> Function(String userId)? dailyCountLookup;

  String? validateRequest(AiRequest request) {
    final maxLength =
        request.featureType == 'writing_review' ? 3000 : _maxPromptLength;
    if (request.prompt.length > maxLength) return 'too_long';
    final lower = request.prompt.toLowerCase();
    for (final kw in blockedKeywords) {
      if (lower.contains(kw.toLowerCase())) return 'blocked';
    }
    return null;
  }

  Future<AiResponse> handle(AiRequest request) async {
    final err = validateRequest(request);
    if (err != null) {
      return AiResponse(success: false, data: {}, errorCode: err);
    }
    final lookup = dailyCountLookup;
    if (lookup != null) {
      final count = await lookup(request.userId);
      if (count >= dailyLimitPerUser) {
        return const AiResponse(
          success: false,
          data: {},
          errorCode: 'rate_limited',
        );
      }
    }
    return provider.generate(request);
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd server && dart test test/ai_routes_test.dart`
Expected: PASS — 全部用例通过（含原有 11 个 + 新增 4 个），`All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/lib/src/ai_policy.dart server/test/ai_routes_test.dart
git commit -m "feat(ai): enforce daily limit + sensitive-content block in AiPolicyService"
```

---

### Task 3: RemoteAiProvider — OpenAI 兼容远程实现（可注入 HTTP）

**Files:**
- Modify: `server/lib/src/ai_policy.dart` (顶部加 imports；文件末尾加 `RemoteAiProvider`)
- Test: `server/test/remote_ai_provider_test.dart` (Create)

**Interfaces:**
- Consumes: `AiRequest`, `AiResponse`, `AiProvider`。
- Produces: `RemoteAiProvider({required http.Client client, required String apiKey, required String baseUrl, required String model, Duration timeout})`，实现 `AiProvider.generate`。成功返回与 `MockAiProvider` 同形 JSON；任何失败返回 `AiResponse(success:false, errorCode:'ai_unavailable')`。

- [ ] **Step 1: Write the failing tests**

Create `server/test/remote_ai_provider_test.dart`:

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

import '../lib/src/ai_policy.dart';

http.Response _chatOk() {
  final content = jsonEncode({
    'answer': 'Hello means a greeting.',
    'cautions': <String>[],
    'relatedWords': ['hi', 'hey'],
  });
  return http.Response(
    jsonEncode({
      'choices': [
        {'message': {'content': content}},
      ],
    }),
    200,
    headers: {'content-type': 'application/json'},
  );
}

RemoteAiProvider _provider(MockClient client) => RemoteAiProvider(
      client: client,
      apiKey: 'test-key',
      baseUrl: 'https://opencode.ai/zen/v1',
      model: 'deepseek-v4-flash-free',
    );

void main() {
  group('RemoteAiProvider', () {
    test('parses valid chat completion into structured data', () async {
      final client = MockClient((req) async => _chatOk());
      final provider = _provider(client);
      final res = await provider.generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(res.success, isTrue);
      expect(res.data['answer'], equals('Hello means a greeting.'));
      expect(res.data['relatedWords'], equals(['hi', 'hey']));
    });

    test('sends bearer key in Authorization header only', () async {
      String? auth;
      Object? bodyContainsKey;
      final client = MockClient((req) async {
        auth = req.headers['Authorization'];
        bodyContainsKey = req.body.contains('test-key');
        return _chatOk();
      });
      await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(auth, equals('Bearer test-key'));
      expect(bodyContainsKey, isFalse);
    });

    test('non-200 returns ai_unavailable without leaking upstream body', () async {
      final client = MockClient(
        (req) async => http.Response('upstream secret error 401', 401),
      );
      final res = await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(res.success, isFalse);
      expect(res.errorCode, equals('ai_unavailable'));
      expect(res.data, isEmpty);
    });

    test('malformed JSON content returns ai_unavailable', () async {
      final client = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': 'not json at all'}},
            ],
          }),
          200,
        ),
      );
      final res = await _provider(client).generate(
        const AiRequest(featureType: 'chat', userId: 'u1', prompt: 'hello?'),
      );
      expect(res.success, isFalse);
      expect(res.errorCode, equals('ai_unavailable'));
    });

    test('cloze parses blanks structure', () async {
      final content = jsonEncode({
        'passage': 'The ___ was nice.',
        'blanks': [
          {'index': 0, 'answer': 'movie', 'options': ['movie', 'car', 'sky', 'pen']},
        ],
        'explanations': <String>[],
      });
      final client = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'choices': [
              {'message': {'content': content}},
            ],
          }),
          200,
        ),
      );
      final res = await _provider(client).generate(
        const AiRequest(
          featureType: 'cloze',
          userId: 'u1',
          prompt: 'cloze',
          targetWord: 'movie',
        ),
      );
      expect(res.success, isTrue);
      final blanks = res.data['blanks'] as List;
      expect(blanks.first['answer'], equals('movie'));
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd server && dart test test/remote_ai_provider_test.dart`
Expected: FAIL — `RemoteAiProvider` 未定义（编译错误）。

- [ ] **Step 3: Implement minimal code**

At the very top of `server/lib/src/ai_policy.dart`, add imports (file currently has none):

```dart
import 'dart:convert';

import 'package:http/http.dart' as http;
```

Append `RemoteAiProvider` at the end of `server/lib/src/ai_policy.dart`:

```dart
/// Talks to an OpenAI-compatible endpoint (OpenCode Zen / DeepSeek).
///
/// Safety: the API key is only ever placed in the Authorization header.
/// Upstream response bodies and the key are never copied into the returned
/// AiResponse, error codes, or logs. Any failure collapses to
/// `errorCode: 'ai_unavailable'`.
class RemoteAiProvider implements AiProvider {
  RemoteAiProvider({
    required this.client,
    required this.apiKey,
    required this.baseUrl,
    required this.model,
    this.timeout = const Duration(seconds: 30),
  });

  final http.Client client;
  final String apiKey;
  final String baseUrl;
  final String model;
  final Duration timeout;

  static const Map<String, String> _systemPrompts = {
    'chat':
        'You are a Chinese-learning assistant. Reply ONLY with strict JSON: '
        '{"answer": string, "cautions": string[], "relatedWords": string[]}. '
        'No markdown, no code fences.',
    'sentence_analysis':
        'Analyze the sentence. Reply ONLY with strict JSON: '
        '{"mainClause": string, "clauses": string[], "modifiers": string[], '
        '"translation": string, "vocabularyNotes": string[]}. '
        'No markdown, no code fences.',
    'cloze':
        'Create a cloze exercise for the target word. Reply ONLY with strict '
        'JSON: {"passage": string, "blanks": [{"index": number, "answer": '
        'string, "options": string[]}], "explanations": string[]}. '
        'No markdown, no code fences.',
    'writing_review':
        'You are an exam writing grader. Reply ONLY with strict JSON: '
        '{"totalScore": number, "rubricScores": {"content": number, '
        '"language": number, "structure": number, "vocabulary": number, '
        '"accuracy": number}, "mainIssues": string[], "paragraphSuggestions": '
        '[{"paragraph": number, "suggestion": string}], "highScoreExpressions": '
        'string[], "grammarIssues": [{"original": string, "corrected": string, '
        '"rule": string}], "rewrittenSample": string}. No markdown, no fences.',
  };

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final system = _systemPrompts[request.featureType];
    if (system == null) {
      return const AiResponse(
        success: false,
        data: {},
        errorCode: 'unknown_feature',
      );
    }
    final userContent = request.targetWord != null
        ? '${request.prompt}\n\nTarget word: ${request.targetWord}'
        : request.prompt;
    final body = jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': userContent},
      ],
      'temperature': 0.3,
    });
    try {
      final res = await _postWithRetry(body);
      if (res.statusCode != 200) {
        return const AiResponse(
          success: false,
          data: {},
          errorCode: 'ai_unavailable',
        );
      }
      final outer = jsonDecode(res.body) as Map<String, dynamic>;
      final choices = outer['choices'] as List;
      final content =
          (choices.first as Map)['message']['content'] as String;
      final data = jsonDecode(content) as Map<String, dynamic>;
      return AiResponse(success: true, data: data);
    } catch (_) {
      return const AiResponse(
        success: false,
        data: {},
        errorCode: 'ai_unavailable',
      );
    }
  }

  Future<http.Response> _postWithRetry(String body) async {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final headers = {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    };
    var res = await client
        .post(uri, headers: headers, body: body)
        .timeout(timeout);
    if (res.statusCode >= 500) {
      res = await client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
    }
    return res;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd server && dart test test/remote_ai_provider_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 5: Run full ai suite to confirm no regression**

Run: `cd server && dart test test/ai_routes_test.dart test/remote_ai_provider_test.dart test/config_test.dart`
Expected: PASS — `All tests passed!`

- [ ] **Step 6: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/lib/src/ai_policy.dart server/test/remote_ai_provider_test.dart
git commit -m "feat(ai): add RemoteAiProvider for OpenCode Zen DeepSeek (OpenAI-compatible)"
```

---

### Task 4: Database — countAiHistoryToday

**Files:**
- Modify: `server/lib/src/database.dart` (在 `softDeleteAiHistory` 之后，Forum 区块之前插入方法)
- Test: `server/test/ai_history_count_test.dart` (Create — 依赖 Postgres，标注)

**Interfaces:**
- Produces: `AppDatabase.countAiHistoryToday(String userId) -> Future<int>`，统计当日未删除记录数。

- [ ] **Step 1: Write the failing test**

Create `server/test/ai_history_count_test.dart`. 该测试依赖 Postgres（`DATABASE_URL`），与现有 `*_db_test.dart` / `routes_test.dart` 同类。若本地无 DB，运行其余无依赖测试即可，此用例在 CI/有 DB 环境执行。

```dart
@Tags(['db'])
import 'package:test/test.dart';

import '../lib/src/config.dart';
import '../lib/src/database.dart';

void main() {
  test('countAiHistoryToday counts only today undeleted rows', () async {
    final config = AppConfig.fromEnvironment();
    final db = AppDatabase(config.databaseUrl);
    await db.open();
    addTearDown(db.close);

    const uid = 'count-test-user';
    final before = await db.countAiHistoryToday(uid);
    await db.insertAiHistory(uid, 'chat', 'p', {'answer': 'a'});
    final after = await db.countAiHistoryToday(uid);
    expect(after, equals(before + 1));
  });
}
```

> 注：`AppDatabase` 的构造/`open`/`close` 签名以现有 `*_db_test.dart` 为准；实现 Step 时若签名不同，按现有 DB 测试的实例化方式对齐（本计划只新增 `countAiHistoryToday`，不改构造）。

- [ ] **Step 2: Run test to verify it fails**

Run: `cd server && dart test test/ai_history_count_test.dart`
Expected: FAIL — `countAiHistoryToday` 未定义（编译错误）。若无 DB，错误为连接失败 — 此时改在有 DB 环境运行；方法缺失的编译错误仍证明红灯。

- [ ] **Step 3: Implement minimal code**

In `server/lib/src/database.dart`, immediately after the `softDeleteAiHistory` method (ends ~line 1858, before the `// Forum` comment block), add:

```dart
  Future<int> countAiHistoryToday(String userId) async {
    final result = await connection.execute(
      Sql.named(
        'SELECT COUNT(*) FROM ai_history '
        'WHERE user_id=@userId '
        'AND is_deleted=FALSE '
        "AND created_at::date = CURRENT_DATE",
      ),
      parameters: {'userId': userId},
    );
    return (result.first[0] as int?) ?? 0;
  }
```

- [ ] **Step 4: Run test to verify it passes (DB env)**

Run: `cd server && dart test test/ai_history_count_test.dart`
Expected (with Postgres up): PASS — `All tests passed!`

- [ ] **Step 5: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/lib/src/database.dart server/test/ai_history_count_test.dart
git commit -m "feat(ai): add countAiHistoryToday for per-user daily limit"
```

---

### Task 5: Routes — provider 选择 + 限额注入 + 错误码状态映射

**Files:**
- Modify: `server/lib/src/routes.dart:961-966` (provider 构造) 和 AI 错误响应映射 (~line 988-994)
- Test: `server/test/routes_test.dart` (Modify — 追加错误码状态映射断言，若该文件有 DB 依赖则在 DB 环境运行；否则新增纯函数断言不可行，改为复用现有 route 测试风格)

**Interfaces:**
- Consumes: `AppConfig.aiProvider/aiApiKey/aiApiBaseUrl/aiModel/aiDailyLimitPerUser`, `RemoteAiProvider`, `AiPolicyService`, `AppDatabase.countAiHistoryToday`, `client`（buildRouter 已有的 http.Client）。
- Produces: 运行时按配置切换 provider；错误码→状态：`too_long`/`blocked`→400，`rate_limited`→429，`ai_unavailable`→503，其余→422。

- [ ] **Step 1: Implement provider selection**

In `server/lib/src/routes.dart`, replace the `effectiveAiPolicy` block (lines 962-966):

```dart
  final effectiveAiPolicy = aiPolicy ??
      AiPolicyService(
        provider: MockAiProvider(),
        dailyLimitPerUser: config.aiDailyLimitPerUser,
      );
```

with:

```dart
  AiProvider _buildAiProvider() {
    if (config.aiProvider == 'remote' && config.aiApiKey.isNotEmpty) {
      return RemoteAiProvider(
        client: client,
        apiKey: config.aiApiKey,
        baseUrl: config.aiApiBaseUrl,
        model: config.aiModel,
      );
    }
    return MockAiProvider();
  }

  final effectiveAiPolicy = aiPolicy ??
      AiPolicyService(
        provider: _buildAiProvider(),
        dailyLimitPerUser: config.aiDailyLimitPerUser,
        dailyCountLookup: database.countAiHistoryToday,
      );
```

- [ ] **Step 2: Implement error-code status mapping**

In the same file, find the AI error response in `_handleAiRequest` (lines ~988-994):

```dart
    if (!response.success) {
      final status = response.errorCode == 'too_long' ? 400 : 422;
      return jsonResponse(
        {'error': response.errorCode ?? 'ai_error'},
        status: status,
      );
    }
```

Replace with:

```dart
    if (!response.success) {
      final code = response.errorCode ?? 'ai_error';
      final status = switch (code) {
        'too_long' || 'blocked' => 400,
        'rate_limited' => 429,
        'ai_unavailable' => 503,
        _ => 422,
      };
      return jsonResponse({'error': code}, status: status);
    }
```

- [ ] **Step 3: Run server analyze + full suite**

Run: `cd server && dart analyze lib/src/routes.dart && dart test test/ai_routes_test.dart test/remote_ai_provider_test.dart test/config_test.dart`
Expected: `No issues found!` 与 `All tests passed!`。

> 说明：`routes_test.dart` 默认用注入的 mock `aiPolicy`，provider 选择分支由 Task 3 的 `RemoteAiProvider` 单测覆盖；错误码映射在有 DB 的 route 测试环境验证。若 `routes_test.dart` 可在本地无 DB 运行则一并跑。

- [ ] **Step 4: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/lib/src/routes.dart
git commit -m "feat(ai): select remote provider by config + map AI error codes to HTTP status"
```

---

### Task 6: `.env.example` — 远程启用说明

**Files:**
- Modify: `server/.env.example:16-19`

- [ ] **Step 1: Implement**

Replace lines 16-19 of `server/.env.example`:

```
AI_PROVIDER=mock
AI_API_KEY=
AI_API_BASE_URL=
AI_DAILY_LIMIT_PER_USER=20
```

with:

```
# AI provider: 'mock' (default, offline deterministic) or 'remote' (OpenCode Zen DeepSeek).
# To enable real AI, set AI_PROVIDER=remote and supply AI_API_KEY.
# The API key is sent only in the Authorization header and is never logged or returned.
AI_PROVIDER=mock
# OpenCode Zen API key — create at https://opencode.ai/zen . Leave empty for mock mode. DO NOT COMMIT a real key.
AI_API_KEY=
AI_API_BASE_URL=https://opencode.ai/zen/v1
AI_MODEL=deepseek-v4-flash-free
AI_DAILY_LIMIT_PER_USER=20
```

- [ ] **Step 2: Verify no real secret present**

Run: `cd server && grep -n "AI_API_KEY" .env.example`
Expected: `AI_API_KEY=`（值为空）。

- [ ] **Step 3: Commit**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add server/.env.example
git commit -m "docs(ai): document remote AI provider env vars in .env.example"
```

---

### Task 7: Flutter — AI 错误展示核查与最小补充（条件任务）

**Files:**
- Inspect: `linguaquest/lib/data/repositories/ai_repository.dart`, `linguaquest/lib/data/repositories/api_repositories.dart`, AI 相关 state/screen
- Modify (仅缺失时): 对应错误展示处

**Interfaces:**
- Consumes: server 返回的 `{'error': code}` 与 HTTP 状态 400/429/503/422。
- Produces: 客户端对 `rate_limited`/`blocked`/`ai_unavailable` 显示可读提示 + 重试入口；不新增 ARB key。

- [ ] **Step 1: Inspect current error handling**

Run:

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
grep -rn "ai_unavailable\|rate_limited\|catch\|DioException\|statusCode\|error" lib/data/repositories/ai_repository.dart lib/data/repositories/api_repositories.dart | grep -i ai
```

Determine whether AI API errors already surface a user-readable message (e.g. a generic try/catch that shows a snackbar/error state).

- [ ] **Step 2: Decide**

- 若现有机制已把任意 API 错误转为可读提示（generic catch + error UI）：**无需改动**，在计划执行记录中说明"现有错误展示已覆盖新错误码"，跳到 Step 4。
- 若 AI 调用对错误无处理（异常直接抛出、UI 无提示）：执行 Step 3 做最小补充。

- [ ] **Step 3 (条件): 最小补充错误提示**

在 AI repository 的远程调用处包裹 try/catch，将失败映射为现有错误展示路径（复用 app 既有的 error state / SnackBar 文案，不新增 ARB key）。具体实现以 Step 1 读到的现有模式为准——按现有 repository 对其他域（如 forum/analytics）的错误处理方式对齐复制，保持一致。

- [ ] **Step 4: Verify Flutter green**

Run:

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze && flutter test
```

Expected: `No issues found!` 与 `All tests passed!`

- [ ] **Step 5: Commit（仅 Step 3 有改动时）**

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2
git add linguaquest/lib
git commit -m "feat(ai): surface readable messages for remote AI error codes"
```

---

## 最终验证（全部 task 完成后）

Run and paste actual output:

```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart analyze
cd /Users/lanyichen/Codes/Mobile/ASM2/server && dart test
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest && flutter analyze && flutter test
```

Expected: `No issues found!` / `All tests passed!`（DB 依赖用例需 Postgres，无 DB 时单独标注跳过原因）。

真实联调（用户提供 key 后，本流程不执行）：

```bash
cd server && AI_PROVIDER=remote AI_API_KEY=*** dart run bin/server.dart
# 另一终端：注册/登录拿 JWT 后
curl -s -X POST localhost:8080/ai/chat -H 'Authorization: Bearer <jwt>' \
  -H 'Content-Type: application/json' -d '{"prompt":"What does 你好 mean?"}'
```

预期返回结构化 `{"data":{"answer":...,"cautions":[],"relatedWords":[...]}}`，服务端日志不含 key。

---

## Self-Review

**Spec coverage:**
- 远程 provider 接入 → Task 3 + Task 5（选择）。✓
- aiModel/baseUrl 配置 → Task 1。✓
- 每日限额强制 → Task 2（policy）+ Task 4（计数）+ Task 5（注入）。✓
- 敏感词过滤 → Task 2。✓
- 失败返回 `ai_unavailable` 不回退 mock → Task 3。✓
- 错误码状态映射 → Task 5。✓
- key 不泄漏 → Task 3（header-only + 测试断言 body 不含 key + 非200不带上游 body）、Task 6（.env.example 空 key）。✓
- Flutter 错误展示 → Task 7（条件）。✓
- 离线可测 → Task 1/2/3 全部 MockClient/无网络；DB 计数 Task 4 标注。✓
- 旧测试兼容 → Task 2 用可选 `dailyCountLookup`，现有 ai_routes_test 不传即不强制。✓

**Placeholder scan:** 无 TBD/TODO；每个代码步骤含完整代码。Task 4/7 的"以现有签名/模式为准"是对齐现有代码的明确指令，非占位符。

**Type consistency:**
- `AiPolicyService({provider, dailyLimitPerUser, dailyCountLookup})` 在 Task 2 定义、Task 5 使用，签名一致。✓
- `RemoteAiProvider({client, apiKey, baseUrl, model, timeout})` 在 Task 3 定义、Task 5 使用，参数一致。✓
- `countAiHistoryToday(String) -> Future<int>` 在 Task 4 定义、Task 5 作为 `dailyCountLookup` 注入，签名匹配 `Future<int> Function(String)`。✓
- 错误码集合 `{too_long, blocked, rate_limited, ai_unavailable, unknown_feature}` 在 Task 2/3 产生、Task 5 映射，一致。✓
