# 接入 OpenCode Zen DeepSeek V4 Flash + 补齐 AI 安全控制 — 设计文档

> 日期：2026-06-19 · 分支：feat/P2-roadmap · 状态：已确认，进入 writing-plans

## 背景

P2 路线图 Batch 3 (#19) / Batch 10 (#32) 已实现 AI 学习与作文批改功能，但 server 端只实现了 `MockAiProvider`。`config.dart` 预留了 `AI_PROVIDER` / `AI_API_KEY` / `AI_API_BASE_URL` 字段，但 `routes.dart:964-965` 把 provider 硬编码为 `MockAiProvider()`，这些配置字段从未被消费（死配置）。同时 `dailyLimitPerUser` 传入 `AiPolicyService` 但未强制执行；roadmap #19/#35 要求的每日限额、敏感内容拒绝尚未落地。

本次目标：

1. 接入 OpenCode Zen 提供的免费 `deepseek-v4-flash-free` 模型（OpenAI 兼容接口）作为真实 AI provider。
2. 补齐 AI 安全控制：每用户每日请求限额强制执行、基础敏感内容拒绝、API key 不泄漏。
3. 保持现有自动化测试全绿，且新增测试全部离线可跑（不依赖真实 key/网络）。

参考项目 AstrBot（`/Users/lanyichen/Codes/AstrBot`）的 `opencode_go_source.py` / `openai_source.py` 确认了 OpenCode Zen 的接口形态：OpenAI 兼容 `chat/completions`，Bearer key，`messages:[{role,content}]`，取 `choices[0].message.content`。AstrBot 为 Python，对本 Dart server 仅作概念参考。

### OpenCode Zen 接口事实

- Base URL（免费版）：`https://opencode.ai/zen/v1`
- 模型 ID：`deepseek-v4-flash-free`
- 鉴权：`Authorization: Bearer <API_KEY>`
- 协议：OpenAI 兼容 `POST {base}/chat/completions`，响应 `choices[0].message.content`
- 即使免费也需创建 API Key。

## 范围

- **改动集中在 server**。Flutter app 始终调用 `/ai/chat|sentence-analysis|cloze`、`/ai/writing-review`、`/ai/history`，不感知 provider 切换。
- Flutter 端仅在错误展示缺失时做最小新增（不新增 ARB key，遵循 i18n 冻结）。

## 决策（已与用户确认）

- **API Key 来源**：运行时环境变量 `AI_API_KEY`，绝不提交进仓库。代码级验证不接触 key。
- **失败回退**：远程调用失败（超时 / 非 200 / JSON 解析失败 / 缺字段）统一返回可读错误 `ai_unavailable`，客户端显示"AI 服务暂时不可用，请重试"。**不静默回退到 mock**（避免掩盖真实故障）。
- **安全控制**：本次连同每日限额强制执行 + 基础敏感词过滤一起实现。
- **敏感词表**：先用小型内置中英文敏感词黑名单，可后续扩展。

## 设计

### 1. 总体架构

仅 server 端改动 provider 选择 + 远程实现 + 策略增强。App 接口契约不变，远程模型必须输出与 `MockAiProvider` **完全相同的 JSON 结构**，保证前端无需改动。

### 2. `RemoteAiProvider`（`server/lib/src/ai_policy.dart`）

```
class RemoteAiProvider implements AiProvider
  字段：http.Client client（依赖注入，默认真实，测试注入 MockClient）
        String apiKey / String baseUrl / String model / Duration timeout
  generate(request):
    1. 按 featureType 选 system prompt（内嵌目标 JSON schema，强制严格 JSON 输出）
    2. POST {baseUrl}/chat/completions
       headers: Authorization: Bearer <apiKey>, Content-Type: application/json
       body: { model, messages:[{role:system,...},{role:user,...}], temperature }
    3. 解析 choices[0].message.content → jsonDecode → 校验字段形状
    4. 任意失败(超时/非200/解析失败/缺字段) → AiResponse(success:false, errorCode:'ai_unavailable')
  安全：key 只进 Authorization header；errorCode 不含上游响应原文；不打印 key/响应原文
  韧性：timeout 30s；5xx/超时重试 1 次
```

四个 featureType（chat / sentence_analysis / cloze / writing_review）各有专属 system prompt，要求模型输出与 mock 一致的 JSON 结构：

- chat：`{answer, cautions[], relatedWords[]}`
- sentence_analysis：`{mainClause, clauses[], modifiers[], translation, vocabularyNotes[]}`
- cloze：`{passage, blanks:[{index, answer, options[]}], explanations[]}`
- writing_review：`{totalScore, rubricScores{content,language,structure,vocabulary,accuracy}, mainIssues[], paragraphSuggestions[], highScoreExpressions[], grammarIssues[], rewrittenSample}`

### 3. `AiPolicyService` 增强（向后兼容）

- **每日限额**：构造函数新增可选 `Future<int> Function(String userId)? dailyCountLookup`。`handle()` 中若提供且 `count >= dailyLimitPerUser` → `errorCode:'rate_limited'`。现有单元测试不传 lookup → 不强制 → 保持绿色。
- **敏感词过滤**：`validateRequest`（或 handle 前置）增加确定性关键词黑名单检查 → `errorCode:'blocked'`，在 provider 调用之前。
- 保留现有长度校验（chat 2000 / writing_review 3000 → `too_long`）。

判定顺序：长度 → 敏感词 → 限额 → provider 调用。

### 4. DB & 路由

- `database.dart` 新增 `Future<int> countAiHistoryToday(String userId)`：`SELECT COUNT(*) FROM ai_history WHERE user_id=$1 AND created_at::date = CURRENT_DATE AND is_deleted = FALSE`。
- `routes.dart`：
  - provider 选择：`config.aiProvider == 'remote' && config.aiApiKey 非空` → `RemoteAiProvider(apiKey, baseUrl, model)`，否则 `MockAiProvider()`。
  - 注入 `dailyCountLookup: database.countAiHistoryToday`。
  - 错误码→HTTP 状态：`too_long`/`blocked`→400，`rate_limited`→429，`ai_unavailable`→503，其余→422。

### 5. 配置

- `config.dart` 新增 `aiModel`（`AI_MODEL`，默认 `deepseek-v4-flash-free`）。
- `aiApiBaseUrl` 默认改为 `https://opencode.ai/zen/v1`。
- `.env.example`：注释说明设 `AI_PROVIDER=remote` + `AI_API_KEY=<你的key>` 即启用；key 不入库。

### 6. Flutter 端（最小改动）

App 已能调 `/ai/*`。先核查 `ai_repository` / state 的错误处理；仅在缺失时为新错误码（`rate_limited` / `blocked` / `ai_unavailable`）补充可读提示 + 重试入口，复用现有错误展示机制，不新增 ARB key。

### 7. 测试策略（TDD，离线可跑）

- `RemoteAiProvider`：用 `package:http/testing.dart` 的 `MockClient` 注入，测：正常解析、非 200、超时、坏 JSON → 各自返回值。
- `AiPolicyService`：新增 `rate_limited`（注入 lookup 返回 ≥ 限额）、`blocked`（敏感词）用例；现有 7 个用例保持通过。
- route 测试继续用 mock provider。
- 真实联调由用户设 `AI_API_KEY` 后执行；本流程做代码级验证，不接触 key。

## 受影响文件

- 修改：`server/lib/src/ai_policy.dart`（RemoteAiProvider + AiPolicyService 增强）
- 修改：`server/lib/src/config.dart`（aiModel + baseUrl 默认值）
- 修改：`server/lib/src/database.dart`（countAiHistoryToday）
- 修改：`server/lib/src/routes.dart`（provider 选择 + lookup 注入 + 状态映射）
- 修改：`server/.env.example`（远程启用说明）
- 修改：`server/test/ai_routes_test.dart`（新增 rate_limited/blocked/remote 解析用例）
- 新增（如需）：`server/test/remote_ai_provider_test.dart`
- 条件修改：Flutter `ai_repository`/state 错误展示（仅缺失时）

## 安全不变量

1. API key 只出现在出站请求的 `Authorization` header。
2. key、上游响应原文绝不写入：`AiResponse.data`、`errorCode`、日志、DB、客户端响应。
3. `.env.example` 中 `AI_API_KEY=` 为空。
4. 远程通道默认关闭（`AI_PROVIDER` 默认 `mock`）。

## 验证

```bash
cd server && dart test test/ai_routes_test.dart
cd server && dart test
cd linguaquest && flutter analyze && flutter test
```

预期全部 `All tests passed!` / `No issues found!`。真实联调（用户提供 key 后）：

```bash
AI_PROVIDER=remote AI_API_KEY=*** dart run bin/server.dart
curl -s -X POST localhost:8080/ai/chat -H 'Authorization: Bearer <jwt>' \
  -H 'Content-Type: application/json' -d '{"prompt":"What does 你好 mean?"}'
```
