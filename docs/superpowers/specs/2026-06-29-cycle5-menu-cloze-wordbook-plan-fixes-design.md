# Cycle 5 修复设计：汉堡图标 / Cloze 超时 / 词书切换 / 学习计划 / 训练分组 / 考试词残留

- **日期：** 2026-06-29
- **分支：** `feat/P2-roadmap`
- **范围：** 6 项独立修复（用户截图反馈），合为一个 plan（多 task group）。
- **被测包：** release APK，后端 `https://api.vonlan233.top`（测试账号已实测）。

---

## 全局约束（Global Constraints）

- 全程中文回复（用户偏好）。
- App 当前 **light-only**（dark mode 基础设施保留但不暴露 UI，见 memory）。"暗色模式白色"按"主题色 token"实现，不重新引入暗色模式开关。
- 学习语言/词书：线上 `/wordbooks` 已有全部 15 本（`hsk1-6`、`jlpt_n5-n1`、`en_basic`/`es_basic`/`fr_basic`/`ms_basic`）；服务端 `allowedWordBookIds` 已接受全部 id。客户端缺失的 `language` 字段默认 `'zh'`（lesson.dart:407）。
- 服务端改动**不自动部署**；部署到 `api.vonlan233.top` 前必须单独获用户授权。
- 不重新引入"中文释义改写层"（HSK flip 已移除，见 memory `hsk-target-language-flip`）。
- 现有测试必须保持绿色：`flutter test` / `flutter analyze`（client）、`dart test` / `dart analyze`（server）。

---

## 修复项 1：home 顶栏汉堡图标颜色不跟随主题

**现象（截图 #12）：** 猫咪头像左边的"三条杠"（菜单图标）颜色不对，应"浅色主题深黑、暗色主题白"。

**根因（已核实）：**
- `linguaquest/lib/features/home/home_screen.dart:66` 是裸 `Icon(AppIcons.menu, size: 24)`，**未在 AppBar 内**，吃不到 `appBarTheme.iconTheme`（app_theme.dart:162 那条只对 AppBar 生效）。
- 全局 `iconTheme`（`app_theme.dart:136`）是 `IconThemeData(weight:400, grade:0, opticalSize:24, fill:0)`——**没有设 color**，于是该图标颜色落到 Flutter 默认值，不随主题 token 走。

**方案：** 给该图标显式着色 `Theme.of(context).colorScheme.onSurface`。light 主题下即深色（截图问题修复）；若未来恢复暗色主题，`onSurface` 自动变浅色，天然满足"暗色白/浅色黑"。一行改动，不动全局 theme（避免波及其它图标）。

**验收：** home 顶栏汉堡图标在浅色背景上为清晰深色；`flutter analyze` 干净；home/widget 测试仍绿。设备复测可见。

---

## 修复项 2：Passage Cloze "网络请求失败" —— 服务端 30s 超时卡边

**现象（截图 #13）：** Passage Cloze 报"网络请求失败，请稍后重试。"+ Retry。

**根因（实测证据）：**
- 测试账号实测 `POST /ai/cloze` **HTTP 200、耗时 28.5s**（返回正好 3 空、2-3 句，说明 Cycle 4 收紧的 prompt 已在线上）。
- 客户端 `receiveTimeout = 60s`（api_repositories.dart:671）；但服务端 `ai_policy.dart:334` 模型调用超时**只有 30s**。免费模型 ~22–30s，稍慢即破 30s → 服务端中断 → 客户端报"网络请求失败"。
- 线上 `AI_CLOZE_MODEL` 为空 → 仍走慢的免费模型 `deepseek-v4-flash-free`。

**方案（用户已选：超时提到 50s + 配更快模型）：**
- **代码改动（唯一）：** `server/lib/src/ai_policy.dart` 的请求超时默认 `30s → 50s`（仍 < 客户端 60s，留 10s 余量）。
- **部署期改动（无需改码，Cycle 4 已铺好 `modelOverride` 管线）：** 部署时设环境变量 `AI_CLOZE_MODEL=<更快模型>`。具体模型名在部署时与用户确认（OpenCode Zen 目录）；留空则回退默认模型，行为不退化。
- 客户端无需改动（60s 已足够）。

**验收：** server 单测/analyze 绿；超时常量改为 50s 有断言覆盖；部署后用 token 实测 `/ai/cloze` 在 50s 内稳定返回（部署阶段单独验证，需授权）。

---

## 修复项 3：词书切换后学习计划仍显示 HSK1（+ 偶发 "Unable to switch"）

**现象（截图 #16）：** 弹"Unable to switch wordbook right now"；切换后学习计划仍是 HSK1。

**根因（铁证，HSK-flip 遗留死代码）：** `linguaquest/lib/data/models/study_plan.dart`
- `normalizedStudyBookId(String?) => 'hsk1'`（第161行）—— 永远返回 hsk1。
- `studyBookIdForTarget(String?) => 'hsk1'`（第163行）。
- `studyBooks` 常量只含 `hsk1` 一本（第144-151行）；`studyBookInfoForId()` 经 `normalizedStudyBookId` 永远解析到 hsk1。
- `StudyPlan.fromJson`（第92行）：`wordBookId: normalizedStudyBookId(json['wordBookId'])` —— 即使服务端正确保存并返回 `en_basic`，客户端解析回来也强制变 `hsk1`。
- `app_state.dart` 的 `currentStudyBook` 读 `studyPlan?.wordBookId ?? studyBookIdForTarget(...)` → 永远 hsk1。

> 这套硬编码是"当时只有一本书"的简化，现已有 15 本，必须解除。

**方案：** 让学习计划的词书"解除归一、改为反映真实所选词书"，数据源为 `state.wordBooks`（15 本）。
- `StudyPlan.fromJson` 不再强制 hsk1：直接读 `json['wordBookId']`，仅做空值兜底（保留 server 端 `normalizeStudyPlanWordBookId` 的 legacy 映射，不在客户端二次归一）。
- `studyBookInfoForId(id)`：当 id 不在静态 `studyBooks` 时，从 `state.wordBooks` 解析展示信息（名称/封面/描述）。考虑到 `studyBookInfoForId` 是顶层函数拿不到 state，将"计划词书展示"改为在需要处直接用 `state.currentWordBookId` + `state.wordBooks` 解析（study_plan_settings_screen、wordbook_screen、home 等显示点），并让 `currentStudyBook` 优先用 `currentWordBookId` 命中 `wordBooks`。
- `normalizedStudyBookId` / `studyBookIdForTarget` 改为恒等/合理实现（不再硬钉 hsk1）；`studyBooks` 静态列表退化为兜底（仅当 wordBooks 未加载时使用）。
- `targetForStudyBookId` 同步改为读真实词书 examType（而非恒返 'HSK 1'）。

**"Unable to switch" snackbar：** 纯静态分析下，已登录健康会话各路径都通过（服务端接受全部 id，`_hasWordBook` 查全 15 本，study-plan/profile 写入合法），未发现确定性抛点 —— 最可能是设备瞬时网络异常或特定状态。**处理：** 在 AVD 抓 logcat 实测复现（验证阶段），若确为瞬时网络，确认上面"显示层"修复后切换能正确反映；若发现确定性抛点再补针对性修复。不臆造修复。

**验收：** 单测覆盖"切到 en_basic / hsk2 后 `currentStudyBook` / 计划显示反映该词书，不再恒为 hsk1"；`StudyPlan.fromJson` 保留所选 id 的单测；现有 study_plan 相关测试调整后全绿；设备复测切换 HSK1→HSK2 与 中文→English 计划正确更新。

---

## 修复项 4：移除手动"目标完成日期"，改为按每日词数自动推算

**现象（截图 #17）：** 用户认为"目标完成日期"应与每日词数捆绑，希望去掉手动项。

**根因/约束：** `targetFinishDate` 被 `daysLeft()`（study_plan.dart:30）使用、且**服务端 `validateStudyPlanPayload` 必填**（study_plan_policy.dart:82）。不能裸删字段。

**方案（用户已选：自动推算）：**
- `study_plan_settings_screen.dart`：删除 `_PlanActionRow`（`AppIcons.event` / `l10n.studyPlanTargetDate`）那一行手动日期选择器及其 `_pickTargetFinishDate` / `_targetFinishDate` 手填逻辑。
- 保存时自动推算：`targetFinishDate = today + ceil(wordBookTotalWords / dailyNewTarget)` 天（至少 1 天）。词书总词数取自 `state.wordBooks` 中当前词书的 `totalWords`/`includedWords`；取不到时退化为 `today + 30d`（保持原默认，避免破坏）。
- 保留 `daysLeft` 显示（剩余天数），现在它随每日词数自动变 —— 真正"捆绑"。
- 移除 `rejectChangedExpiredTargetFinishDate` 相关的手填校验路径（不再有手填）。

**验收：** 单测：给定词书总词数 + 每日新词，推算天数正确（含 ceil、下限 1、缺词数退化 30d）；保存的 plan 通过服务端校验（startDate/targetFinishDate 齐全且 finish≥start）；设置页不再有日期选择项；`flutter analyze` 干净；现有 study_plan 测试调整后绿。

---

## 修复项 5：Campus Sprint 移到 "Timed Tests" 分组上方（保留限时）

**现象（截图 #18）：** Campus Sprint 在 "Timed Tests" 分组内；用户希望移到该分组上方。

**事实澄清：** Campus Sprint 代码上**确实是限时**（路由 `/timed-test/${speedLesson.id}` → `QuizSessionMode.timed`）。用户已确认：**只移动位置，保留限时玩法**。

**根因：** `training_screen.dart:45-64` 分组是写死的：`SectionHeader(trainingTimedTests)` 下挂 Campus Sprint + Speed Game。

**方案：** 把 Campus Sprint 这张 `_TrainingGameRow` 从 "Timed Tests" 列表中移出，放到 `SectionHeader(trainingTimedTests)` **之前**，作为独立区块（新增一个 section header，文案复用现有合适 l10n 或新增一条中性标题，如 "Campus Sprint" / 课程内既有键）。"Timed Tests" 分组内只剩 Speed Game。Campus Sprint 的路由/限时逻辑**不变**。

**验收：** widget 测试断言 Campus Sprint 渲染在 Timed Tests header 之前；点击仍进 `/timed-test/...`；`flutter analyze` 干净；training 相关测试绿。

---

## 修复项 6：清理 IELTS / TOEFL / GRE 残留

**现象：** 多处仍有雅思/托福/GRE 字样（截图反馈 #6）。

**根因（已核实）：** 大部分是死文案（normalize 已全归 hsk1，UI 不显示），少量真用户可见。

**方案（最小、不破坏编译）：**
- **死文案删除（成对删，避免引用悬空）：** `l10n/app_en.arb` + `app_zh.arb` 中的 `labelTargetIELTS/TOEFL/GRE`、`labelWordTagIELTS/TOEFL/GRE`、`wordbookName*/wordbookDesc*` (IELTS/TOEFL/GRE) 共 12 条，连同 `core/utils/ui_labels.dart` 里对应的 `case 'IELTS'/'TOEFL'/'GRE'` 分支（`displayTarget`/`displayWordTag`/`displayWordbookTitle`/`displayWordbookDescription` + 无 l10n 版本）一并删除；重新生成 l10n。
- **用户可见 #1：** AI 写作批改页 `ai_writing_review_screen.dart:33` 的 `_examTypes = ['General','IELTS','CET-4','CET-6','TOEFL']` → 改为中性写作风格选项（不含考试名），如 `['General','Academic','Business','Casual']`；对应传给后端的语义保持"风格提示"。
- **用户可见 #2：** 论坛示例 `discoverForumPost2Title`（"雅思阅读里怎么记 abstract?" / EN 版）→ 改为不含考试名的等义文案（如 "How do you memorize the word 'abstract'?" / "怎么记住 abstract 这个词？"）。
- 注释类残留（wordbook_cover_card.dart:8、app_theme.dart 设计注释）可顺手清理，不强制。

**验收：** `grep -ri "ielts\|toefl\|gre\|雅思\|托福"` 在 `lib`（排除 build/）无用户可见命中；`flutter analyze` 干净（无悬空 l10n 引用）；写作批改页下拉显示新中性选项；相关 widget 测试绿。

---

## 任务分解预览（writing-plans 阶段细化）

1. **Task 1（#1）** home 汉堡图标主题着色 —— 1 文件，含 widget 测试。
2. **Task 2（#2）** server cloze 超时 30→50s —— 1 文件 + server 单测；部署 env 列入部署清单。
3. **Task 3（#3）** 解除 study_plan hsk1 硬编码 + 计划显示反映真实词书 —— study_plan.dart / app_state.dart / 显示点；含单测。
4. **Task 4（#4）** 移除手动完成日期 + 自动推算 —— study_plan_settings_screen.dart + 推算工具/测试。
5. **Task 5（#5）** Campus Sprint 移出 Timed Tests 上方 —— training_screen.dart + widget 测试。
6. **Task 6（#6）** 清理 IELTS/TOEFL/GRE 文案 + 写作批改风格选项 + 论坛示例 —— l10n/arb + ui_labels + 2 screen；重生成 l10n。
7. **Task 7（验证）** 全量 `flutter test`/`analyze` + `dart test`/`analyze`；AVD 抓 logcat 复现 #3 snackbar + 复测 #1/#3/#4/#5/#6。
8. **部署（需单独授权）** server 改动 + `AI_CLOZE_MODEL` 部署到 api.vonlan233.top，实测 cloze。

**任务相互独立**（#3 与 #4 同改 study_plan 域，需注意顺序/合并），适合 subagent-driven-development。
