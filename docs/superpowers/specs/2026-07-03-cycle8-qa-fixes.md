# Cycle 8 设计：外部 QA 报告修复（P1+P2+P3）

- **日期：** 2026-07-03
- **分支：** `feat/P2-roadmap`
- **来源：** 外部黑盒 QA 报告 `Codes/Mobile/testing/LinguaQuest_APK_Functional_Test_Report_2026-07-03.md`（针对 Cycle 7 的 APK）。均为**既有问题**，非 Cycle 7 回归。
- **P0 决策：** 用户确认「Start/Review → 词条详情页」为**设计如此**（词条详情即学习卡片），本轮**不改**，移出范围。
- **范围：** 全修 P1+P2+P3 共 9 项。**全部客户端改动，无服务端、无部署。**

## 全局约束（Global Constraints）
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 每项明确列出的文件（**禁 `git add -A/./-u`**——仓库有无关 untracked）。
- flutter 命令在 `linguaquest/`。改 l10n `.arb` 后必须跑 `flutter gen-l10n` 并把生成文件一并提交；**三个 arb（en/ms/zh）同步加/改键**。
- 现有测试全绿：`flutter test` + `flutter analyze`。改动触发的旧断言据实修。
- 不改词义/词书数据；不动 Cycle 7 的任何修复。

## 项目清单

| # | 优先级 | 问题 | 层 |
|---|---|---|---|
| A | P1 | 抽奖结果文案 cost/remaining 写反 | 客户端调用处 |
| B | P1 | AI Q&A 占位符残留 "English" | 客户端 + l10n |
| C | P1 | 搜索无声调拼音 "ai" 不优先命中 爱 | 客户端搜索逻辑 |
| D | P2 | 首页统计标签 Learned/Mastered/Review 截断 | 客户端布局 |
| E | P2 | AI Learning 工具名截断 | 客户端布局 |
| F | P2 | 语言地图 Japanese 标签出界 | 客户端布局 |
| G | P2 | 抽奖 "Draw now" 按钮位置过深 | 客户端布局 |
| H | P3 | "1 days streak" / "1 items in stock" 单复数 | 客户端 + l10n |
| I | P3 | 词条详情 "Add to custom words" 按钮换行 | 客户端布局 |

---

## A（P1）：抽奖结果 cost/remaining 写反

**根因：** l10n 生成方法按占位符**字母序**排参 → `luckyDrawDeducted(Object balance, Object cost)`；但调用处 `lucky_draw_screen.dart:177` 按位置传 `luckyDrawDeducted(result.cost, result.balanceAfter)` → cost(30) 进了 balance 槽、balanceAfter(13) 进了 cost 槽 → 显示 "Deducted 13 XP, 30 XP remaining."（实际消耗 30、剩余 13）。

**方案：** 修调用处参数顺序匹配生成签名——`Text(l10n.luckyDrawDeducted(result.balanceAfter, result.cost))`。arb 文案不动（`"Deducted {cost} XP, {balance} XP remaining."` 正确）。
- 加单测：断言 `luckyDrawDeducted(balance:13, cost:30)`（即用生成签名 `(13, 30)`）渲染出 "Deducted 30 XP, 13 XP remaining."，锁死顺序防回归。

**验收：** 单测通过；设备/逻辑上抽奖消耗 30、余额 43→13 时显示 "Deducted 30 XP, 13 XP remaining."。

---

## B（P1）：AI Q&A 占位符残留 "English"

**根因：** `ai_chat_screen.dart:119` `hintText: 'Type your question about English...'` **硬编码**（旧版残留；本 App 现学中文）。下方空态用 `l10n.aiEmptyChat`（已是 Chinese 文案）。

**方案：**
- 三个 arb 新增键 `aiQuestionHint`：en `"Type your question about Chinese..."`、ms `"Taip soalan anda tentang bahasa Cina..."`、zh `"输入你关于中文的问题……"`。
- `ai_chat_screen.dart:119` 改用 `hintText: l10n.aiQuestionHint`（`InputDecoration` 去掉 `const`，因运行时取值）。
- 跑 `flutter gen-l10n`。

**验收：** placeholder 与副标题都指向 Chinese；`flutter analyze` 绿。

---

## C（P1）：搜索无声调拼音 "ai" 优先命中 爱

**根因：** `dictionary_search.dart` 的 `_targetWordMatch()`（约 157-179 行）**完全没有拼音字段匹配**。"ai" 命中的是英文释义里 `train`/`car` 的子串（上车/下车），而 爱 的拼音 `ài`（去声调=ai）从未被检查；且英文释义匹配落到 `_matchRank` 最低 rank 5。项目已有 `core/utils/pinyin.dart` 的 `normalizePinyin()`（去声调，已测试）但搜索未用。

**方案（最小、复用现有工具）：**
1. `dictionary_search.dart` 顶部 `import '../core/utils/pinyin.dart';`（按实际相对路径）。
2. 新增 `_matchPinyin(label, value, query)`：`if (normalizePinyin(value.trim()).contains(query)) return _SearchMatch(...)`（对**字段**去声调后子串匹配；query 已是无声调小写）。
3. 在 `_targetWordMatch` 里把拼音匹配插到**英文单词之后、日文/释义之前**：匹配 `word.phonetic`（zh 词的拼音），label 用 `'汉字拼音'`。
4. `_matchRank`（约 245-255）加：`if (matchedBy == '汉字拼音') return 1;`（高于英文单词 rank 2，仅次于 word==query / 前缀）→ 爱 置顶。
5. 保留英文释义匹配现状（上车/下车 仍作为低优先结果出现，可接受）。

**验收：** 加单测：HSK1 集合搜 "ai" → 结果**第一条是 爱**；`normalizePinyin('ài')=='ai'` 已有测试不回归。`flutter test`/`analyze` 绿。
> ponytail: 短 query（≤2 字符）英文释义子串仍会带出噪音结果（train/car），本轮只保证正确项置顶不做释义匹配收紧；若要彻底去噪，后续可加"英文释义匹配要求词边界或 query≥3"。

---

## D（P2）：首页统计标签截断

**根因：** `home_screen.dart:347-377` 三个 `Expanded(StatTile(...))` 均分宽度；`stat_tile.dart:56-62` 内是 `Row(icon + Column(value,label))`，icon(约36)+padding 挤占，label `maxLines:1 + ellipsis` → "Mastered" 等被截断。

**方案：** 改 `StatTile` 为**纵向布局**（icon 在上、value、label 在下），让 label 获得整列宽度。先 grep `StatTile` 所有使用处，确认纵向布局对其它调用不破坏（若别处依赖横向，则改为仅在此卡片用的变体或给 label 加 `FittedBox(fit: BoxFit.scaleDown)` 兜底）。**默认方案：** StatTile 纵向 + label `maxLines:1` 居中；若某调用因此变形，退回给 label 包 `FittedBox`。

**验收：** 首页三标签 "Learned"/"Mastered"/"Review" 完整显示不截断；StatTile 其它使用处不回归（`flutter analyze` + 相关 widget 测试绿）。

---

## E（P2）：AI Learning 工具名截断

**根因：** 共享组件 `compact_entry_card.dart:62-70` 标题 `Text` 硬限 `maxLines: 1 + ellipsis`；"AI Long Sentence Analysis" / "AI Writing Correction" 超一行被省略。

**方案：** `CompactEntryCard` 标题 `maxLines: 2`（`overflow: ellipsis` 保留）。此组件被 Discover 多入口共用（含 Cycle 7 的 My Favorites）——两行对短标题无副作用（仍单行显示）。

**验收：** AI Learning 两个长工具名完整显示；Discover 其它入口卡片外观不变；`flutter analyze` 绿。

---

## F（P2）：语言地图 Japanese 标签出界

**根因：** `language_map_screen.dart` marker `width:140`、`alignment: topCenter`；`_LangMarker` 标签 `Text('Japanese (日本語)')` 单行约 146px > 140，且 Japan 点(lng 138.2)靠右，单行标签在屏幕右缘被裁切。

**方案：** 标签 `Text` 允许**换行至 2 行**并约束到 marker 宽度内——`maxLines: 2`、`softWrap: true`、`textAlign: TextAlign.center`，Container 宽度 ≤ marker 宽度（140）。"Japanese (日本語)" 换行后每行 < 140，横向不再溢出，右缘不裁切。必要时把 marker `height` 略增以容 2 行。

**验收：** 地图上 Japanese 标签完整可读不裁切；其它 marker（较短）仍单行正常；`flutter analyze` 绿。

---

## G（P2）：抽奖 "Draw now" 按钮位置过深

**根因：** `lucky_draw_screen.dart:30` 整页是 `ListView(children:[_LotteryPanel()])`，主按钮 `luckyDrawNow`（约 112-127 行的 Stack）作为 Panel 里 `_ProbabilityList`（可变高度奖池列表）**之后**的普通 child → 需滚到底才见。

**方案：** 重构页面为**可滚动内容 + 固定底部操作区**：`Scaffold.body` = 上部可滚动（说明卡 + 奖池概率列表），底部用 `bottomNavigationBar`（或 `Column` + `Expanded(ListView)` + 固定 footer）放 "Draw now" 主按钮 +（不足提示）+ "View my assets"。进页即见主按钮。

**验收：** 进抽奖页第一屏即见 "Draw now"，无需滚动；抽奖/余额不足/查看资产逻辑不变；`flutter analyze` + 现有 lottery 测试绿。

---

## H（P3）：单复数（streak / stock）

**根因：**
- `profileStreakDays` arb = `"days streak"`（无参数），`profile_screen.dart:256` 用 `'$streak ${l10n.profileStreakDays}'` 拼接 → streak=1 显示 "1 days streak"。
- `luckyDrawInventoryCount` arb = `"{count} items in stock"`（无 plural）→ count=1 显示 "1 items in stock"。
- 同文件已有正确先例：`homeStreakDays`、`reviewCenterCardsDue` 用 `{count, plural, ...}`。

**方案：**
- 三 arb 改 `profileStreakDays` 为带参 plural：en `"{count, plural, =1{1 day streak} other{{count} days streak}}"`（ms/zh 对应，zh 无单复数：`"连续 {count} 天"`）；`profile_screen.dart:256` 改 `label: l10n.profileStreakDays(streak)`。
- 三 arb 改 `luckyDrawInventoryCount` 为 plural：en `"{count, plural, =1{1 item in stock} other{{count} items in stock}}"`（ms/zh 对应）；调用处 `lucky_draw_screen.dart:95` 已传 count，签名不变。
- 跑 `flutter gen-l10n`。

**验收：** count=1 显示 "1 day streak" / "1 item in stock"；count>1 显示复数；`flutter analyze` 绿。

---

## I（P3）：词条详情 "Add to custom words" 按钮换行

**根因：** `target_word_detail_screen.dart:96-100` 底部 Favorite / Add 两按钮并排（各约半屏宽），"Add to custom words"（19 字符）+ icon 在半宽内换行成 3 行。

**方案：** 把底部两个操作按钮从**并排 Row 改为纵向堆叠**（各占整行宽度）——full-width 下 "Add to custom words" 单行显示。若已有布局强依赖 Row，则退回：给按钮标签更短的 l10n（不推荐，优先改布局）。

**验收：** "Add to custom words" 按钮单行完整显示不换行；Favorite 按钮正常；`flutter analyze` 绿。

---

## 任务分解预览（writing-plans 细化）
按文件聚合，尽量各自独立、可并行：
1. **A + G + H(stock)**：`lucky_draw_screen.dart` 一处集中（参数顺序 + 按钮固定底部 + 库存 plural arb）+ 测试。
2. **B + E**：AI（`ai_chat_screen` placeholder l10n + `compact_entry_card` maxLines）。
3. **C**：搜索拼音匹配（`dictionary_search.dart` + 测试）。
4. **D**：`stat_tile.dart` 纵向布局（+核查使用处）。
5. **F**：`language_map_screen.dart` 标签换行约束。
6. **H(streak)**：`profile_screen.dart` + arb plural。
7. **I**：`target_word_detail_screen.dart` 按钮纵向堆叠。
8. **验证 + 构建 APK**：全量 `flutter test`/`analyze` + `flutter build apk --release`。

> 全部客户端，无服务端/无部署。l10n 改动集中在 B/H，需 gen-l10n。
