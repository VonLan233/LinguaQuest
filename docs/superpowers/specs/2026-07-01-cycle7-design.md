# Cycle 7 设计：注册引导选词书 + HSK 英文释义/拼音修正

- **日期：** 2026-07-01
- **分支：** `feat/P2-roadmap`
- **来源：** 用户反馈 2 项：(1) 注册验证后没让选词书直接进主页；(2) 词书英文释义/拼音取错（百=surname Bai、白=surname Bai、班=surname Ban，且拼音后拖 POS 代码）。

## 全局约束（Global Constraints）
- 全程中文回复；commit **不带 Co-Authored-By**；只 `git add` 改动文件（禁 `git add -A/.`）。
- flutter 命令在 `linguaquest/`，dart/python 生成器在仓库根 `tools/`。
- 现有测试保持绿：`flutter test`/`flutter analyze`、`dart test`/`dart analyze`（server）。
- 服务端改动用户已预授权部署（rsync + `deploy/vps_deploy.sh`，保留远程 `.env/.env.prod` + db 卷）。
- 词书数据源：`drkameleon/complete-hsk-vocabulary`（生成器联网下载 `complete.json` 缓存到 `/tmp`）。释义**照搬源库**，本 spec 只改"选哪个 form/义项"，不自造释义。

---

## Part A：注册验证后引导用户选词书（Issue 1）

**根因：** `verify_email_screen.dart:50` 验证成功后硬编码 `context.go('/home')`，跳过了完整存在的 `/goal-setup`。且 `_applyAuthenticatedUser`→`_ensureStudyPlan`→`_loadOrCreateStudyPlan` 会**自动伪造默认计划**（targetExam='Daily English'）→ `studyPlan!=null`，使 `studyPlan==null` 无法区分"未选词书的新用户"。

**方案（用户已选：去掉自动默认计划，用 `studyPlan==null` 判断）：**
1. **停止伪造默认计划**：改 `_loadOrCreateStudyPlan`（app_controller）——服务端**没有**该用户的计划时**返回 null**（不再构造默认 plan）。`_ensureStudyPlan` 用 null 更新 state（studyPlan 保持 null）。这样"新用户/未做 goal-setup"= `studyPlan==null`，"已选词书"= 非 null。
2. **路由按 `studyPlan==null` 分流**：
   - `verify_email_screen.dart:50`：`context.go(ref.read(appControllerProvider).studyPlan == null ? '/goal-setup' : '/home')`。
   - `splash_screen.dart:56`：`if (isAuthenticated) context.go(studyPlan==null ? '/goal-setup' : '/home'); else context.go('/onboarding');`。
   - `login_screen.dart`（authenticated 分支）：同样 `studyPlan==null ? '/goal-setup' : '/home'`（老用户有计划→主页；极少数无计划→goal-setup）。
3. **goal_setup 完成建计划**：`completeGoalSetup` 已创建并保存 plan（现状），保存后 `context.go('/home')`（现状）。新用户走 goal-setup→选词书→建计划→主页。
4. **容错核查**：home 及各屏对 `studyPlan==null` 已有兜底（`studyPlan?.x ?? default`，Cycle5/6 已确认）；本改动需回归 `flutter test`，修正任何断言"验证后 studyPlan 非 null"的旧用例（若有）。

**验收：** 单测/widget：验证成功且无 plan → 路由到 `/goal-setup`；有 plan → `/home`。设备：注册新账号→输验证码→进入选词书页（而非主页）；老账号登录仍直达主页。`_loadOrCreateStudyPlan` 无 plan 时返回 null 的单测。

---

## Part B：HSK 英文释义/拼音取错 + POS 代码泄漏（Issue 2）

**根因：** 源库每字有多个 `form`，**姓氏/专有名词读音（拼音首字母大写，如 `Bǎi`）常排在 `forms[0]`**；生成器取 `forms.first` 的拼音+义项 → 取到 "surname Bai"（且拼音成大写 `Bǎi`）。另 `partOfSpeech = pos.join('/')` → "a/nr/d/b/v/g" 被客户端拼进拼音显示。
- 证据：源 `百` forms[0]=`Bǎi`/surname Bai，forms[1]=`bǎi`/hundred；`白` forms[0]=`Bái`/surname，forms[1]=`bái`/white；`班` 同理。
- 影响：HSK1-6，义项错误 ~119 词；POS 泄漏 ~2000+ 词（所有含多 POS 的）。

**方案（用户已选：2a 显示只显拼音去 POS；2b 重生成 HSK1-6 修义项）：**

### B1：客户端显示去掉 POS（2a，立即修所有词书）
- `wordbook_screen.dart:476-479`：把 `phonetic · partOfSpeech` 改为**只显 `word.phonetic`**（不拼 `partOfSpeech`）。
- 核查词详情页是否也拼了 POS，一并去掉（若有）。
- 此改动对所有词书（含 JLPT/en）即时生效，无需等重生成。

### B2：修生成器"选常用 form"（2b）
两个生成器都加"挑主 form"逻辑：
- **选 form 规则**：在 `forms` 中，**优先选拼音首字母为小写的 form**（常用词）而非大写（姓氏/专有名词）；若存在多个小写 form，取第一个小写 form；若全大写则退回 forms[0]。用所选 form 的**拼音**（修正 `百`→`bǎi`）和**义项**。
- **义项过滤**：聚合义项时**跳过以 "surname " 开头**（及等价的纯专有名词/地名 gloss）的义项；保留其余英文义项；仍过滤 CJK。
- `convert_hsk.dart`（HSK1，Dart，约 42/46-49/64 行）与 `generate_hsk_wordbooks.py`（HSK2-6，Python，约 82-94 行）**各自实现同一规则**。
- POS 字段：既然显示已去 POS（B1），数据里 `partOfSpeech` 可保留原样（不展示）；无需改 POS 生成逻辑。

### B3：重生成数据 + 服务端 + 部署
- 运行 `convert_hsk.dart` 重生成 `wordbook_hsk1.json`；运行 `generate_hsk_wordbooks.py` 重生成 `wordbook_hsk2..6.json`。
- 运行 `tools/sync_p0_from_assets.py`（或等价）把客户端 HSK 资产同步进服务端 `server/data/wordbooks_p0.json`。
- 抽样校验：`百`→"hundred"(bǎi)、`白`→"white"(bái)、`班`→"team; class; grade"(bān)、姓氏义项消失。
- 部署服务端 `wordbooks_p0.json`。

**验收：** 生成器加最小校验（`百/白/班` 主义非 surname、拼音小写）；重生成后 grep 断言这几个词修正；客户端词书列表拼音行无 POS 代码；`flutter test`/`flutter analyze` 绿；服务端部署后 `curl /wordbooks/hsk1` 抽样确认。

---

## 任务分解预览（writing-plans 细化）
1. **Part A**：`_loadOrCreateStudyPlan` 无 plan 返回 null（+单测）→ verify/splash/login 路由按 `studyPlan==null` → 修回归用例 → 设备验证。
2. **Part B1**：`wordbook_screen`（+词详情）去 POS 显示（+widget 测试断言拼音行无 `/` POS）。
3. **Part B2**：改两个生成器"选常用 form + 跳 surname"（+生成器最小自检）。
4. **Part B3**：重生成 HSK1-6 客户端资产 + 服务端 wordbooks_p0 + 抽样校验 + 部署。
5. **验证 + 部署**：全量测试 + 设备复测（注册引导、释义修正）+ 服务端部署。

> Part A 与 Part B 相互独立。B1 立即修 POS 显示；B2/B3 修义项需联网重生成 + 部署。JLPT/其它语言不在本轮义项修正范围（源不同、无 surname 问题）。
