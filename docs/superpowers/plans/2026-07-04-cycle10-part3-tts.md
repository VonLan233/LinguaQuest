# Cycle 10 Part 3：服务端 TTS（edge-tts）Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development. Steps use checkbox (`- [ ]`) syntax.

**Goal:** 修复本地 flutter_tts 在缺中文语音包设备/模拟器上无声——服务端提供 TTS 音频，客户端中文单词/阅读句子改播 URL，本地 flutter_tts 降级为兜底。

**Architecture:** docker-compose 加独立 python edge-tts 微服务（Dart 保持纯 Dart，只做 `/tts` 转发 + 文件缓存）；客户端复用现成 audioplayers URL 播放通道。

**Tech Stack:** python edge-tts（微软 Edge 免费 neural TTS，无需 key）+ aiohttp；Dart shelf；Flutter audioplayers（已在）。

## Global Constraints
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 每 task 明确列出的文件（**禁 `git add -A/./-u`**）。
- flutter 命令在 `linguaquest/`，server 在 `server/`。现有测试全绿。
- 正式 APK 用 `--dart-define=API_BASE_URL=https://api.vonlan233.top` 构建。
- 需部署（tts 微服务 + Dart /tts 端点）——用户已预授权（rsync + `deploy/vps_deploy.sh`）；edge-tts 走微软公共 endpoint，VPS 需能出网访问 `speech.platform.bing.com`（部署时验证）。
- 源：`docs/superpowers/specs/2026-07-04-cycle10-studymap-restore-qa3-fixes.md`（TTS 节）。
- **有利前提（已核实）：** 客户端 `pronunciation_service.dart` audio sink 已能播 `UrlSource`（audioplayers）；中文当前被 `chineseTtsOnly`（:26）主动跳过 URL。只要 server 给 URL，中文改走 URL 即可，改动小。

## 已核实的客户端现状
- `lib/core/services/pronunciation_service.dart`: `play({word, audioUrl, slow, language})`——`_resolveTtsLocale` 映射 language→locale（zh→zh-CN、ja→ja-JP、其它按 CJK 检测）；`chineseTtsOnly = ttsLocale=='zh-CN'` 时跳过 audioUrl 直接走 `tts` sink。
- `lib/core/widgets/pronunciation_controls.dart`: 构造 `PronunciationService(audio: 播 UrlSource, tts: flutter_tts speak)`。
- `lib/features/reading/article_reader_screen.dart`: 同款 PronunciationService（阅读句子）。
- `AppConstants.apiBaseUrl`（`lib/core/constants/app_constants.dart`）——非空即连后端。

---

### Task 1: python edge-tts 微服务 + docker-compose

**Files:**
- Create: `server/tts/server.py`、`server/tts/Dockerfile`
- Modify: `server/docker-compose.prod.yml`（加 `tts` service）

**实现要求：**
1. `server/tts/server.py`——aiohttp HTTP 服务，`GET /synthesize?text=&voice=&rate=` → edge-tts 生成 mp3 → 返回 `audio/mpeg`：
```python
import edge_tts
from aiohttp import web

async def synthesize(request):
    text = (request.query.get('text') or '').strip()
    voice = request.query.get('voice') or 'zh-CN-XiaoxiaoNeural'
    rate = request.query.get('rate') or '+0%'
    if not text:
        return web.Response(status=400, text='missing text')
    if len(text) > 500:
        return web.Response(status=400, text='text too long')
    try:
        communicate = edge_tts.Communicate(text, voice, rate=rate)
        buf = bytearray()
        async for chunk in communicate.stream():
            if chunk['type'] == 'audio':
                buf.extend(chunk['data'])
        if not buf:
            return web.Response(status=502, text='empty audio')
        return web.Response(body=bytes(buf), content_type='audio/mpeg')
    except Exception as e:
        return web.Response(status=502, text=f'tts failed: {e}')

app = web.Application()
app.router.add_get('/synthesize', synthesize)
app.router.add_get('/health', lambda r: web.Response(text='ok'))
if __name__ == '__main__':
    web.run_app(app, host='0.0.0.0', port=5002)
```
2. `server/tts/Dockerfile`:
```dockerfile
FROM python:3.12-slim
RUN pip install --no-cache-dir edge-tts aiohttp
COPY server.py /app/server.py
WORKDIR /app
EXPOSE 5002
CMD ["python", "server.py"]
```
3. `docker-compose.prod.yml`：先 Read 确认现有 service（api/db）结构，加 `tts` service（**内部网络，不对外暴露端口**，api 通过 `http://tts:5002` 访问）：
```yaml
  tts:
    build: ./tts
    restart: unless-stopped
    expose:
      - "5002"
```

**验证：** 本地若有 docker：`cd server && docker build -t lq-tts ./tts` 应成功；`docker run -d -p 5002:5002 lq-tts && sleep 3 && curl -s -o /tmp/t.mp3 -w "%{http_code} %{content_type}\n" "http://localhost:5002/synthesize?text=你好&voice=zh-CN-XiaoxiaoNeural"` 应 200 audio/mpeg 且 mp3 非空。**若本地无 docker/无出网**，则靠部署验证——在报告里说明未本地验证的部分。**不写占位测试。**

- [ ] Step 1: 创建 server.py + Dockerfile + docker-compose service
- [ ] Step 2: 本地 docker build + curl 验证（若可）；否则说明留部署验证
- [ ] Step 3: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server
git add tts/server.py tts/Dockerfile docker-compose.prod.yml
git commit -m "feat(tts): python edge-tts 微服务 + docker-compose service"
```

---

### Task 2: Dart /tts 端点（校验 + voice 映射 + 缓存 + 转发）

**Files:**
- Modify: `server/lib/src/routes.dart`（加 `GET /tts`）
- Modify: `server/lib/src/config.dart`（加 tts 微服务地址 + 缓存目录 env）

**实现要求：**
1. `config.dart`：加 `ttsServiceUrl`（env `TTS_SERVICE_URL`，默认 `http://tts:5002`）+ `ttsCacheDir`（env `TTS_CACHE_DIR`，默认 `/tmp/tts-cache`）——照 config.dart 现有 `_env(name, default)` 风格（非密钥，给默认值）。
2. `routes.dart` 加 `GET /tts?text=&lang=&slow=`（**免鉴权**，音频非敏感，与词库公开性一致；照现有公开端点如 `/health`/`/lessons` 的写法，不包 `_protected`）：
   - **输入校验**（信任边界）：`text` 非空且 `≤500` 字，否则 400；`lang` 白名单 `{zh,en,ja}`，否则 400。
   - **voice 映射**：zh→`zh-CN-XiaoxiaoNeural`、en→`en-US-AriaNeural`、ja→`ja-JP-NanamiNeural`；`slow=='true'`→`rate=-25%` 否则 `+0%`。
   - **缓存**：key=`sha256(text|voice|rate)`（用 `package:crypto`，已在 server 依赖？否则用 dart:convert+现有），mp3 存 `ttsCacheDir/<key>.mp3`；命中直接返回文件字节（`audio/mpeg`）；未命中则 `http` GET `ttsServiceUrl/synthesize?text=&voice=&rate=`（`Uri` 编码），成功（200 且非空）落盘再返回，微服务失败则返回 502。
   - 返回 `Content-Type: audio/mpeg` + `Cache-Control: public, max-age=86400`。
3. 先确认 server 是否已依赖 `crypto` 和 `http`（`pubspec.yaml`）——若无 crypto 用 dart 内置无 sha256，则改用 `text|voice|rate` 的 hashCode 或 base64url 编码为文件名（避免加依赖）；http 若无则用 dart:io HttpClient。**优先复用已有依赖，不新增。**

**验证：** `cd server && dart analyze`（No issues）。端点行为靠部署后 curl 验证（`curl /tts?text=你好&lang=zh` → audio/mpeg）——server 无 HTTP 集成测试框架，不写占位测试。**若** voice 映射/校验逻辑可抽成纯函数（如 `_ttsVoiceFor(lang)`/`_ttsRateFor(slow)`），**则抽出并加纯函数单测**（lang 白名单、voice 映射、slow→rate）放 `server/test/`。

- [ ] Step 1: config 加 env；routes 加 /tts（校验/voice/缓存/转发）；voice/rate 抽纯函数
- [ ] Step 2: 纯函数单测（voice 映射 + lang 白名单 + slow→rate）；Run `cd server && dart test && dart analyze` — Expected: 全绿 + No issues
- [ ] Step 3: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/server
git add lib/src/routes.dart lib/src/config.dart test/  # 仅新增的 tts 相关测试
git commit -m "feat(tts): Dart /tts 端点(校验+voice映射+sha256缓存+转发微服务)"
```

---

### Task 3: 客户端优先 server TTS URL + fallback

**Files:**
- Modify: `linguaquest/lib/core/services/pronunciation_service.dart`
- Modify: `linguaquest/lib/core/widgets/pronunciation_controls.dart`、`linguaquest/lib/features/reading/article_reader_screen.dart`
- Test: `linguaquest/test/core/services/pronunciation_service_test.dart`（若存在则扩展，否则新建）

**实现要求：**
1. `pronunciation_service.dart`：中文（及 en/ja）不再无条件 `chineseTtsOnly` 跳过 URL。改逻辑：若 `AppConstants.apiBaseUrl` 非空，**优先构造 server TTS URL** `{apiBaseUrl}/tts?text={Uri.encodeComponent(word)}&lang={zh/en/ja}&slow={slow}` 走 audio sink；audio 成功→`playedUrl`；audio 失败或 apiBaseUrl 空→**fallback 本地 flutter_tts**（`tts` sink）。保留原有真实 audioUrl（外部音频）优先级逻辑不破坏（若已有非空 audioUrl 且非中文场景，仍先播它——按现有语义微调，核心是"中文/无外链时走 server TTS 而非直接本地 tts"）。lang 映射复用现有 `_resolveTtsLocale`→取 zh/en/ja（把 locale 反推 lang，或直接用传入 language）。
2. `pronunciation_controls.dart` / `article_reader_screen.dart`：`PronunciationService` 的 audio sink 保持播 UrlSource；**无需大改**（service 内部构造 URL）——除非 service 需要 apiBaseUrl/language 参数，则在构造处传入。保留 flutter_tts 实例作 fallback。
3. 测试：`PronunciationService` 单测——注入 fake audio/tts sink，验证：apiBaseUrl 非空 + 中文 → 调 audio(含 `/tts?...&lang=zh`)；audio 返回 false → fallback 调 tts；apiBaseUrl 空 → 直接 tts。**先读现有 pronunciation_service_test.dart 学既有测试风格。**

- [ ] Step 1: 写/扩展失败测试（中文优先 URL + fallback）→ 确认 RED
- [ ] Step 2: 改 pronunciation_service 优先 URL + fallback；接线处按需传 apiBaseUrl/language
- [ ] Step 3: Run `cd linguaquest && flutter test test/core/services/pronunciation_service_test.dart && flutter analyze` — Expected: PASS + No issues
- [ ] Step 4: Commit
```bash
cd /Users/lanyichen/Codes/Mobile/ASM2/linguaquest
git add lib/core/services/pronunciation_service.dart lib/core/widgets/pronunciation_controls.dart lib/features/reading/article_reader_screen.dart test/core/services/pronunciation_service_test.dart
git commit -m "feat(tts): 客户端中文/句子优先 server TTS URL，失败 fallback 本地 flutter_tts"
```

---

## 全量验证（所有 task 后）
`cd linguaquest && flutter analyze && flutter test`；`cd server && dart analyze && dart test` — 全绿。

## 部署（Task 1+2 server）+ 设备验证
- 部署：`rsync` + `deploy/vps_deploy.sh`（docker-compose build tts + api 重启）；curl `/tts?text=你好&lang=zh` → audio/mpeg 非空；确认 VPS 能访问微软 edge endpoint。
- 连后端 APK 设备验证（**关键**）：模拟器（无中文语音包）下点单词/阅读句子 Play → **能发中文读音**（经 server），非静默；断开 server → fallback 本地不崩。

## 说明
- `/tts` 免鉴权（音频非敏感，简化客户端；与词库公开性一致）。
- edge-tts 免费无 key；缓存降开销（词/句重复率高）。
- 若 VPS 无法访问微软 endpoint（部署验证失败），fallback：本地 flutter_tts 仍工作（apiBaseUrl 非空但 /tts 失败 → audio 失败 → fallback tts），不崩；届时向用户报告 TTS 需换方案（如预生成/云 TTS）。
