# LinguaQuest — 手动测试分工（三人）

- **日期：** 2026-06-29
- **被测包：** `linguaquest/build/app/outputs/flutter-apk/app-release.apk`（release，Cycle 3）
- **后端：** `https://api.vonlan233.top`（APK 已用 `--dart-define=API_BASE_URL=...` 指向；标 *(后端)* 的用例需联网，离线用例用飞行模式）
- **分支：** `feat/P2-roadmap`
- **基准：** 用例编号沿用 [`TEST_PLAN.md`](TEST_PLAN.md) §4；本文件把它的全部用例 + Cycle 2/3 新增用例分给三人。

## 公共准备（三人都做一次）
1. 安装 `app-release.apk` 到 Android 设备/模拟器。
2. 注册新账号（OTP 邮箱验证）或用已有账号登录；部分用例可离线/demo 模式。
3. 每条用例在自己份额表里填 **Pass / Fail** + 备注（截图存 `docs/screenshots/` 并标用例 ID）。
4. 发现 Fail → 记复现步骤 + 期望/实际，汇总给负责人。

## 总览

| Tester | 负责模块 | 用例数 | 覆盖的 rubric 必做项 |
|---|---|---|---|
| **A** | 账号导航 · 学习/Quiz/训练 · AI Learning · 成就/抽奖 | ~21 | — |
| **B** | 深色模式 · 语言/词书选择 · 地图 · 离线/持久化 | ~21 | **Map**、**Persistence** |
| **C** | 词书/词详情 · 阅读 · 多媒体音频 · 学习分析 · 社区 | ~23 | **Multimedia** |

> 划分原则：每人拿到内聚的功能区（减少来回切换），份额均衡，三人合起来无遗漏、无重叠；三个 rubric 必做项分散到 B、C，便于交叉佐证。

---

## Tester A —「动态交互：账号 / 学习训练 / AI / 奖励」

**沿用 TEST_PLAN 用例：** §4.1 NAV-1..4 · §4.5 LRN-1..4 · §4.7 AI-1..4 · §4.11 ACH-1..3 / LOT-1..2

**补充用例（Cycle 2/3 新功能）：**

| ID | 步骤 | 期望 | P/F | 备注 |
|---|---|---|---|---|
| TRN-5 | Training → **Passage Cloze**（篇章完形）*(后端)* | 加载一段 AI 生成的短文 + 若干空；逐空选词作答；加载/失败有重试；完成后计分进训练记录 | | |
| TRN-6 | Training → **Listening Sprint**（听力冲刺） | 仅播放音频（不显示词），从 4 个候选词中选听到的词；答对/错有反馈；完成计分 | | |
| AI-5 | AI Learning → **Confusable Words**（易混词）*(后端)* | 输入一个词 → 返回易混词对 + 区别说明 + 例句；加载态；失败有重试卡片 | | |
| AI-6 | AI Learning → **Sentence Generation & Rewrite**（造句/改写）*(后端)* | 输入词/句 → 返回例句（含翻译）+ 改写建议；加载/失败/重试正常 | | |
| AI-7 | AI Learning 工具列表 | 6 个工具（Q&A / 长句分析 / 今日完形 / 写作批改 / 易混词 / 造句改写）全部显示 **Available**，无 "In Planning" | | |

**A 的 rubric 关注点：** 无（但 LRN/AI 是 §5 AI Learning 与训练广度的核心，务必走 *(后端)* 真实返回）。

---

## Tester B —「系统外观与导航：深色 / 语言词书 / 地图 / 离线」

**沿用 TEST_PLAN 用例：** §4.2 THM-1..4 · §4.3 LANG-1..7 · §4.9 MAP-1..3 · §4.13 OFF-1..4

**补充用例（Cycle 2/3 新功能）：**

| ID | 步骤 | 期望 | P/F | 备注 |
|---|---|---|---|---|
| LANG-8 | 打开"Choose Language"语言列表（地图点 pin 后的列表 / 两级选择器第一级） | 右侧药丸（Current / Coming Soon）**右缘整齐对齐**，不参差 | | |
| LANG-9 | 在"Choose Wordbook"里点选**另一本**词书（如 HSK1→HSK2） | 被选词书**即时高亮 Current**、其余熄灭，**sheet 不立即关闭**；手动关闭后重开仍是新词书；杀进程重启后保持该词书 | | |
| MAP-4 | Profile/Settings → **Choose Language** 打开语言地图 | 真实 OSM 世界地图（"© OpenStreetMap" 可见）；每个国家 marker 带**语言名标签 + 圆形徽章**；可学语言有**呼吸光晕/入场动画**，未开放为灰 + 🔒 | | |
| MAP-5 | 点击**可学** marker（中国/日本） | 弹出**卡片**（语言名 + "开始学习"按钮）→ 进入该语言词书选择 | | |
| MAP-6 | 点击**未开放** marker（如法国） | 弹卡片显示"即将开放"，不进入选择 | | |
| MAP-7 | 深色模式下打开语言地图 | 底图叠深色遮罩、整体协调；标签/卡片/图例文字清晰可读；底图仍是真实 OSM（非插画） | | |

**B 的 rubric 关注点：** **Map**（MAP-1..7、LANG-5..7）、**Persistence**（OFF-1..4、LANG-9 的"重启保持"）。

---

## Tester C —「内容与数据：词书 / 阅读 / 音频 / 分析 / 社区」

**沿用 TEST_PLAN 用例：** §4.4 WB-1..4 · §4.6 RD-1..9 · §4.8 AUD-1..3 · §4.10 AN-1..3 · §4.12 COM-1..3

**补充用例（Cycle 2/3 新功能）：**

| ID | 步骤 | 期望 | P/F | 备注 |
|---|---|---|---|---|
| COM-4 | **浅色(light)模式**下打开"发帖"页（Community → 笔 FAB） | "Tag" 标签 chips 的文字**清晰可见**（深色），不是白底白字；选中的 chip 也看得清 | | |
| COM-5 | **浅色模式**下打开"Community Posts"列表 | 顶部分类筛选 chips（All/Grammar/Vocabulary/…）文字清晰可见，非白底白字 | | |

**C 的 rubric 关注点：** **Multimedia**（AUD-1..3、RD-4 段落音频 —— 普通话 / 日语 / 无网 TTS 兜底都要试）。

---

## 交叉验收建议（可选，提高可信度）
- 三人各自跑完后，互换设备各抽测对方 2-3 条关键用例（尤其三个 rubric 必做项 MAP / OFF / AUD）。
- 任一 Fail 必须有：复现步骤 + 期望 vs 实际 + 截图（标用例 ID）。
- 汇总到 `TEST_PLAN.md` 的 P/F 列或单独结果表。

## 已知限制（不计入 Fail，见 TEST_PLAN §6）
- JFT-Basic 日语词书未做（JLPT N5–N1 已上线）。
- HSK 释义为英文，中文释义/例句未填。
- 阅读的显示开关偏好为单会话（未全局持久化）。
- AI 功能需后端；离线为 demo/mock 返回。
