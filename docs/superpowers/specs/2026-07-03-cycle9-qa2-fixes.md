# Cycle 9 设计：第二轮 QA + 设备复测修复（8 项）

- **日期：** 2026-07-03
- **分支：** `feat/P2-roadmap`
- **来源：** ①我对 Cycle 8 的设备复测发现 2 项未达标（C 搜索、F 地图）；②外部第二份 QA 报告 `Codes/Mobile/testing2/`（聚焦 Discover）发现 6 项。合计 8 项，用户决定全部合入 Cycle 9。
- **范围：** 8 项。**需部署：2.1（server 代码）、2.2（server env 配置，无代码）。** 其余客户端。

## 全局约束（Global Constraints）
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 每项明确列出的文件（**禁 `git add -A/./-u`**）。
- flutter 命令在 `linguaquest/`，server 在 `server/`。改 `.arb` 跑 `flutter gen-l10n` 并提交生成文件；三 arb（en/ms/zh）同步。
- 现有测试全绿：`flutter test`/`analyze`；`dart test`/`analyze`（server）。
- 需部署项用户已预授权（rsync + `deploy/vps_deploy.sh`，保留远程 `.env/.env.prod` + db 卷）。
- 不动 Cycle 7/8 已通过的修复。

## 项目清单

| # | 简称 | 层 | 部署 |
|---|---|---|---|
| C | 搜索精确拼音置顶 | client | 否 |
| F | 地图 Japanese 标签出界（真修） | client | 否 |
| 2.1 | 社区评论计数不一致 | server | ✅ |
| 2.2 | 阅读段落 AI 显示 Mock | server env（无代码） | ✅ |
| 2.3 | 阅读筛选后标题仍 All articles | client | 否 |
| 2.4 | Point Tasks "Go +5 XP" 误导 | client l10n | 否 |
| 2.5 | 发帖校验提示位置偏弱 | client | 否 |
| 2.6 | Me 页统计标签截断 | client l10n | 否 |

---

## C：搜索精确拼音置顶

**根因：** `dictionary_search.dart` 的 `_matchPinyin`（:247-253）只做**子串**匹配（`normalizePinyin(field).contains(query)`）；`_matchRank`（:255-266）对所有 `matchedBy=='汉字拼音'` 统一返回 rank 1。故 爱(ài→ai，**精确**)与 太(tài)/奶(nǎi)/孩子(hái zi)（**子串**含 ai）同 rank，rank 内按汉字码点排序，爱(码点高)排后面，未置顶。

**方案：** 区分精确 vs 子串拼音，精确置顶。
1. `_matchPinyin`：算 `final normalized = normalizePinyin(trimmed);` 若 `normalized == query` 用 label `'汉字拼音精确'`，否则 `'汉字拼音'`。
2. `_matchRank`：在 `if (matchedBy=='汉字拼音') return 1;` 之前加 `if (matchedBy=='汉字拼音精确') return 1;`，并把**子串**那行降级为 `return 2;`（精确 rank 1 置顶于子串 rank 2）。

**验收：** 单测：HSK1 集合含 爱(phonetic 'ài')+太(phonetic 'tài')，搜 "ai" → 首条 id=='爱' 且 matchedBy=='汉字拼音精确'；太 排在其后（子串）。`flutter test`/`analyze` 绿。设备复测：搜 "ai" 爱置顶。

---

## F：地图 Japanese 标签出界（真修）

**根因（设备复测确认）：** Cycle 8 给标签加 ConstrainedBox+maxLines2 **无效**——真因是 `language_map_screen.dart:94-96` `initialCenter: LatLng(20, 80)` + `initialZoom: 2.2` 下，Japan(lng 138.2)贴近视口右缘；`Marker.alignment: topCenter` 使标签从锚点居中向两边展开，右半必然溢出屏幕，与标签宽度无关。

**方案：** 调整地图初始视野让 Asia 各 pin（zh 116 / ja 138 / ms 102）离屏幕边缘有余量。
- `language_map_screen.dart:95-96`：`initialCenter` 东移 + `initialZoom` 略降，使 Japan 标签完整可见。**起始值** `initialCenter: LatLng(20, 100)`、`initialZoom: 2.0`；由控制者在模拟器上截图复验并微调（Japanese 标签完整、zh/ms 仍可见）。
- 保留 Cycle 8 的 ConstrainedBox(maxWidth 124)+maxLines2（belt-and-suspenders，减小单个标签横向占用）。

**验收：** 设备复测：Choose Language 初始视野下 "Japanese (日本語)" 标签**完整不裁切**，Chinese/Malay 标签仍可见。`flutter analyze` 绿。
> ponytail: 初始视野是折中——西方语言(en/es/fr)可能移出初屏，但地图可平移；本轮只保证 Asia 三个 enabled 目标语标签在初屏完整。

---

## 2.1：社区评论计数不一致

**根因：** `database.dart` forum_posts 表有 `comment_count` 列（`insertForumComment` 手动 +1）；`listForumPosts`（约 :2088-2099）直接 `SELECT fp.*` 返回该列。种子/历史帖 `comment_count=6` 但 `forum_comments` 无对应行 → 列表卡片显 6、详情页 `listComments` 返回真实 0。

**方案（用户已选：计数改真实评论数）：** 改 `listForumPosts` 查询，`comment_count` 用子查询实时 COUNT。
- `database.dart` `listForumPosts` 的 SELECT：把返回的 `comment_count` 改为 `(SELECT COUNT(*) FROM forum_comments WHERE post_id = fp.id) AS comment_count`（覆盖表列）。
- **先核实** `forum_comments` 是否有 `status` 列：有则 `AND status='approved'`（与详情页 listComments 的可见性口径一致）；无则不加该条件。以 listComments 的实际口径为准，保证列表计数 == 详情可见评论数。
- `getForumPost`（单帖详情，若也返回 commentCount）同口径处理，避免详情页头部计数与评论列表不一致。

**验收：** server 单测：某 post 有 N 条 forum_comments → `listForumPosts` 返回该 post commentCount==N（含 0）；与 listComments 数量一致。`dart test`/`analyze` 绿。部署后设备：列表卡片评论数 == 详情页 `Comments (n)`。

---

## 2.2：阅读段落 AI 显示 Mock（server env）

**根因：** 客户端段落 AI **已完整接线**（`ApiAiRepository.explainParagraph` → `POST /ai/reading-explain`，服务端 `routes.dart` 端点 + `ai_policy.dart` reading_explain system prompt 均已实现）。显示 "Mock gist…" 是因为**服务端 AI provider 当前为 mock**（`.env.prod` 未启用 remote / 无 key）→ `MockAiProvider` 返回字面 Mock 文本。**无代码改动。**

**方案（用户已选：接服务端真 AI）：** 部署时在 VPS `.env.prod` 配置远程 AI：
- `AI_PROVIDER=remote`
- `AI_API_KEY=<deepseek / OpenCode Zen key>`（用户提供或 VPS 已有；控制者不读取/不入库该密钥）
- `AI_API_BASE_URL=https://opencode.ai/zen/v1`（默认）、`AI_MODEL=deepseek-v4-flash`（默认）
- 重启服务（`deploy/vps_deploy.sh` 或 compose restart，读取新 env）。

**验收：** 部署后设备：阅读段落 sparkle → AI explanation 返回**与段落相关的真实内容**（无 "Mock" 字样）；AI Q&A 同样返回真实回答。若 key 缺失/无效则回退 mock（不崩），控制者在部署步骤确认 env 生效。
> 无代码/无测试改动；纯部署配置。若用户暂不提供 key，本项标记 pending 不阻塞其余 7 项。

---

## 2.3：阅读筛选后标题仍 "All articles"

**根因：** `reading_list_screen.dart:102` `SectionHeader(title: l10n.readingAllArticles)` 硬编码；筛选逻辑（`_themeFilter`/`_levelFilter`，:72-76）生效但标题不跟随。

**方案：** 标题按筛选状态动态化。
- 无 theme 筛选 → `l10n.readingAllArticles`。
- 选了 theme（如 travel）→ 用 `readingThemeLabel(l10n, _themeFilter)`（`reading_labels.dart` 已有映射）拼成 "{Theme} articles"，新增 l10n 键 `readingArticlesForTheme` = `"{theme} articles"`（三 arb；zh `"{theme}文章"`）。
- level 筛选本轮不改标题（level 已由顶部筛选芯片体现；只处理 theme 以最小化）。

**验收：** widget：选 theme=travel → 标题含该主题名（非 "All articles"）；无筛选 → "All articles"。`flutter test`/`analyze` 绿。

---

## 2.4：Point Tasks "Go +5 XP" 误导（l10n）

**根因：** `shared_widgets.dart:60` 未完成任务显示 `l10n.discoverGoComplete("5")` = en `"Go +{points} XP"`，"+5 XP" 让人以为点击即领。三态逻辑（isDone/isClaimed → Go/Claim/Claimed）已存在且正确；zh 文案已好（"去完成 +{points} XP"）。

**方案（纯 l10n）：** 改 en `discoverGoComplete`：`"Go +{points} XP"` → `"Complete for +{points} XP"`（明确"去完成才得分"）。ms 同义调整；zh 已好不改（如需微调保持 "去完成 +{points} XP"）。

**验收：** en 未完成任务按钮显示 "Complete for +5 XP"（非 "Go +5 XP"）；Claim/Claimed 态不变。`flutter analyze` 绿。

---

## 2.5：发帖校验提示位置偏弱

**根因：** `forum_compose_screen.dart` 标题用普通 `TextField`（:109-117），空表单校验把错误塞进页面中部 `_errorMessage` Text（:168-176），点 Publish 后不自动滚动，提示易被忽略。

**方案：** 改 Form + TextFormField，字段级 inline 校验。
- 加 `final _formKey = GlobalKey<FormState>();`，外层包 `Form(key: _formKey, child: ...)`。
- 标题/正文 `TextField` → `TextFormField` 带 `validator`（空→返回错误串，显示在输入框下方红字）。
- `_submit()` 改 `if (!_formKey.currentState!.validate()) return;`，删除原 `_errorMessage` 底部渲染（:168-176）与相关 state。
- 校验文案用 l10n：新增 `communityTitleRequired`="Please enter a title."、`communityBodyRequired`="Please enter some content."（三 arb；复用现有若有）。

**验收：** widget：空标题点 Publish → 标题输入框下方显示错误、不提交；填写后可提交。`flutter test`/`analyze` 绿。

---

## 2.6：Me 页统计标签截断

**根因：** `profile_screen.dart:291` 用 `l10n.profileLearnedWords`（en "Words Learned" / zh "已学单词"），比 Home 的 `homeLearned`（"Learned"/"已学"）长；窄屏(360dp)三列均分下即使纵向 StatTile 仍截断成 "Words Learn..."。

**方案（缩短标签，与 Home 一致）：**
- 三 arb `profileLearnedWords`：en "Words Learned"→"Learned"、zh "已学单词"→"已学"、ms 对应缩短。
- （`profileMasteredWords` en 已是 "Mastered"，zh "已掌握" 短，无需改；streak 用 `onboardingTagPillStreak`="Streak" 短，无需改。）
- 可选兜底：`stat_tile.dart` label 包 `FittedBox(fit: BoxFit.scaleDown)`，保所有 label 永不截断——本轮**只做缩短**（最小），FittedBox 留待 review 决定。

**验收：** widget/设备：Me 页三统计标签在窄屏完整显示不截断。`flutter test`/`analyze` 绿。

---

## 任务分解预览（writing-plans 细化）
客户端独立小改：C、F、2.3、2.4、2.6。较大：2.5（表单重构）。服务端+部署：2.1（SQL+测试+部署）、2.2（仅 env 配置+部署）。
1. C 搜索精确拼音（+测试）。
2. F 地图视野（+控制者设备复验微调）。
3. 2.3 阅读标题动态（+arb）。
4. 2.4 Go 文案（arb）。
5. 2.6 Me 标签缩短（arb）。
6. 2.5 发帖 Form 校验（+arb）。
7. 2.1 评论计数 SQL（server+测试）。
8. 验证 + 部署（server 2.1 + env 2.2）+ 构建 APK + 设备复验（C/F + 部署项）。

> 2.2 无代码，随部署设 env。key 由用户提供；控制者不读取/记录密钥。
