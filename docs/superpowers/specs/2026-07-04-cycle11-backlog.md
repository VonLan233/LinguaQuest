# Cycle 11 Backlog（第三轮 QA 真 bug 清单）

- **日期：** 2026-07-04
- **状态：** 待 Cycle 10 完成后 brainstorm（用户决定先实现 Cycle 10）。
- **来源：** ①`Codes/Mobile/testing3/SVV.docx`（He Bolin，54 用例，13 Fail+13 Partial，**在 localhost web 的 mock 模式跑**）；②微信 `测试任务.md`（中文，~15 项）。

## 重测结论（连后端 APK，2026-07-04）
用连后端 APK（`--dart-define=API_BASE_URL=https://api.vonlan233.top`）+ 账号 2862597783@qq.com 重测：
- **AI Q&A 连后端返回真实 AI**（问 "explain thanks in Chinese" → 真实 谢谢/感谢 解释 + Cautions + Related Words + History，无 Mock）。
- AI Learn 页**无** "demo responses" banner（连后端）。
- ⇒ **证实 SVV 的整批 AI Fail 是"没连后端"的 mock 假象。**

## ❌ mock 假象（连后端已消失，不作为 bug）
- D-05 Passage Cloze 英文单空、D-08 日文 AI mock（内容部分）、AI-04/05/07/08 mock、RD-08/LINK-01 demo AI。

## ✅ Cycle 11 真 bug 清单（~20，与数据源无关）

### 已在其他轮覆盖
- **单词音频不播 / "Audio unavailable"**（D-13、AUD-03/04、测试任务 5.2 中/马来/西报错）→ 本地 TTS 短板，**已由 Cycle 10 TTS 覆盖**，Cycle 11 不重复。

### 🔴 高危（测试任务.md）
1. Profile 点进直接 **404**（7.2）——看不到个人资料。
2. 学习课程**只学两三个就退出**，无论计划设多少（6.1）。
3. 做题**不论对错全部录入错题本**（6.2）。

### 🟡 训练（SVV）
4. Word Rush 计分冲突：live 计数与结算不一致（D-01）。
5. Word Spelling：提示要英文却期望中文拼写（D-03）。
6. Listening Sprint：听力前显示目标词，泄露答案（D-04）。
7. Survival：revive/node 标签反转 + 长提示裁切（D-02）。
8. Campus Sprint：错误重试可无限猜 + 结果标签混语言（D-06）。

### 🟡 阅读/词典
9. 日文词典 は 映射成 'tooth'，忽略上下文（D-07）。

### 🟡 AI 入口 / l10n
10. Mistake Book 的 Explain-with-AI 入口不可见/不可点（D-09）。
11. AI helper text **写死语言名**：日文 scope 仍显示 "Chinese"（AI-03/04、测试任务 7.5）——真 l10n bug，应随 targetLanguage 动态。
12. AI Writing Review：延迟 snackbar 挡住提交按钮，需重试（D-11）。

### 🟡 数据/成就
13. Analytics 训练 XP 与实际活动不一致；下方明细不清（D-10）。
14. 成就 3-Day Streak 单日测试即解锁（demo/static 嫌疑，D-12）。

### 🟡 UI/其他（测试任务.md）
15. 地图选语言：**中文、西班牙语无法点选**，其余四种可以（4）。
16. 单词卡片有多余中文释义，且内容还是英文——应删中文释义（5.4）。
17. 单词详情音频按钮太多（uk/us/0.5 倍速），建议留一个（5.1）。
18. Profile 入口命名不统一（"个人资料"/"数据存储"/"数据和帐户"），需统一（7.3）。
19. Dark Mode 下 "Choose Language" 按钮异常换行（7.4）。
20. 开屏界面两处提到 "word image" 但无图像，应去掉；about/info 同类文案一并去掉（7.1）。
21. Onboarding：每日学习词数 与 deadline 两种设置同页共存 + 共用保存按钮，混淆；建议单选/互斥收起（2.1）。
22. 语言切换：延迟/偶发失败/学习语言与词书不符（2.2）——**关联 Cycle 10 F（首页/个人页词书不一致）**，Cycle 11 处理切换稳定性部分。

### 待查（可能非 bug）
- 重复加自定义词第二次无反馈（5.3）——可能是 `fe0747c` 同词幂等设计，需确认是否要给"已在词书"提示。
- 提示语言随系统（测试任务 1）——若确按系统语言则非 bug。
- 是否确定同时提供 5-6 种可学语言（测试任务 7.5 前半）——产品决策，影响 helper text/AI 文案范围。

## 备注
- SVV 用日文 scope（JLPT N5）+ 中文 scope 测；部分真 bug（Word Spelling 语言、日文词典）与"学中文/学日文"scope 有关，Cycle 11 brainstorm 时需明确当前多语言 scope 策略（关联 [[hsk-target-language-flip]]）。

## 已探索根因（2026-07-05 Cycle10 会话，opus 波动致 agent 挂，探索未尽）
- **Profile 404（高危3.1）**：客户端 `getPublicProfile`→`/users/{userId}/profile`（api_repositories.dart:973），server 有 `GET /users/<userId>/profile`（routes.dart:1051）——**路径匹配，非端点缺失**。需查为何 404：该 userId 是否在 users 表存在（社区种子帖 authorId 可能无对应用户行）/隐私全关是否返回 404 / getPublicProfile 异常→public_profile_screen 显示 404。**Cycle 10 C 接了作者头像跳转，若目标 profile 端点对某些 authorId 404 就复现。**
- **错题本全录（高危3.3）**：`passage_cloze_screen.dart:88` `if(ok){correct++}else{mistakes.add(q)}` 判断正确（错才加）。lesson quiz 流程（`app_controller.dart:1083 bool isCorrect` + `:1029 mistakeWordIds: result.mistakes`）待查——需确认 lesson 场景 result.mistakes 来源是否漏判 isCorrect 把全部录入。
- **课程只学2-3个退出（高危3.2）**：session 词数来源未定位（learning_repository 无 take/daily 关键词命中）。待查 lesson 生成/dailyPlan 的 session 词数逻辑（app_controller.dart:2063 remainingWords 附近）。
- **训练类（Word Rush/Word Spelling/Listening/Survival/Campus）+ 地图中文/西语无法点选 + Mistake Book AI 入口**：未探索（探索 agent 因 opus 波动挂）。language_map_screen marker enabled/locked 逻辑、training_session_screen + 各 game screen 待新会话探索。

> **新会话续 Cycle 11**：读本 backlog + `.superpowers/sdd/progress.md`；先坐实上述未尽根因（用 Bash/Read 或稳定后派 agent）→ brainstorm 定范围/优先级 → spec → plan → SDD。Cycle 10 已完整交付（三 Part 部署+设备验证），勿重做。

## 根因坐实（2026-07-05 Cycle11 会话，用户决策：全部 22 项一次清）
> 4 个并行 Explore agent + 自查坐实。注意：agent 有过一次编造代码（错题本"flashcard 阶段"纯属虚构），以下均已本人 Read/grep 核对真实行号。

- **课程只学2-3词（高危6.1）✅确凿**：`lesson_factory.dart:5` `wordsPerLesson=3` 硬编码；`api_repositories.dart:300` `lessonsFromWordBook(book)` 调用**没传 dailyNewTarget**。每日计划 `dailyNewTarget`（app_state.dart:215 读取正常）从未接进 lesson 生成。修法：`lessonsFromWordBook(book, wordsPerLesson: <每日计划值>)`，需把 dailyGoal 传到 api_repositories 调用点（注意该处是否能拿到 state.dailyNewTarget）。
- **Profile 404（高危7.2）✅路径确定**：帖子作者头像跳 `/profile/{authorId}`（community_screen.dart:211，Cycle10 C 接线）→ `getPublicProfile`→ GET `/users/<id>/profile` → 后端 `routes.dart:1056` 当 `userById(userId)==null` 返 404。forum_posts.author_id **无 FK 约束**（database.dart:526-538），可指向不存在用户。自己 profile 入口用有效 uid 不 404。客户端 `public_profile_screen.dart:66-73` 把异常直接当文案显示。修法：后端 404 时客户端友好空态（"用户不存在/资料不可见"），并考虑帖子作者不可点或后端 join 校验。
- **错题本"全录"（高危6.2）⚠️代码逻辑正确，非明确代码 bug**：真机课程走 `mixed_study_session_screen.dart`（/study/mixed），非 quiz_session。判分 `_judgeQuestion:312` `answer==item.meaningFor(locale)`，选项由 `_buildOptionsFor:458` 用同一 `meaningFor`+distractor 构建 → **选对必判 true**；`_wrongItemIds` 只在首答错时 add；`completeMixedStudySession`（app_controller.dart:1354）**不写 lastResult**，只喂 `_recordLessonUserWords`（:2099 仅对真错词 `hadMistake:true`）；错题本 weakWords 段=`reviewWords.where(isWeak)`。→ **代码层面查不到"答对却全录"**。最可能：HSK 学中文，新词首次接触真答错→自然塞满；或用户复现路径特殊。修法方向：**新词首次曝光的错答不计入错题本/弱词**（仅 review 项或重复错才算），需先写复现测试坐实。⚠️实现前可能需向用户要精确复现步骤。
- **地图 zh/es 点不了（UI 4）✅确凿（非 enabled 门控）**：`language_map_screen.dart:28-35` 六 pin 全 `enabled:true` 无门控。真因是 **marker 命中框 140×110（:116-117）远大于视觉 badge ~56px**，zoom=2 下 zh(北京116°E)/ja(日本138°E) 约 60px 间距、es(马德里-3.7°)/fr(巴黎2.3°) 约 17px → 两两重叠；后绘 marker（ja=index4 盖 zh、fr=index3 盖 es）抢走点击。恰好 zh、es 被覆盖，en/ms/ja/fr 孤立或在顶层可点。修法：命中框缩到贴合 badge（只让 badge 区可点）/ 拉开坐标 / 缩小 Marker width。
- **5 训练游戏（SVV D-01/03/04/02/06）✅确凿**，均在 `lib/features/training/training_session_screen.dart`（Campus 在 `lib/features/quiz/quiz_session_screen.dart`）：
  - D-01 Word Rush 计分冲突：倒计时结算 `_finishTraining` 时末题 feedback 延迟未完成，attempt 漏计（:558-560 vs :319/:709-710）。
  - D-03 Word Spelling 语言错配：`:401` 用 app locale(en) 取释义喂给"拼中文"prompt（`trainingPromptChineseSpelling`），期望中文却给英文。
  - D-04 Listening 泄题：选项在音频播放前无条件渲染（:1067 add(word.word)，:934-943 选项在 PronunciationControls 之前）。
  - D-02 Survival 标签反转：`:803` 传 `(revives,nodeRewards)`，l10n `trainingSurvivalResources` 定义 `(nodes,revives)` 顺序颠倒（app_localizations_en.dart:1515-1516）。
  - D-06 Campus 无限重试：`quiz_session_screen.dart:276-298/504-506` 无 maxAttempts，答错可逐个试；结果标签 l10n 前缀+explanation 中英拼接（:570/:577）。

### UI / l10n 簇（agent grep 坐实，实现前需 Read 复核真实行号——agent 有编造前科）
- **11 AI helper 写死"Chinese"**：❓未找到硬编码。AI 屏幕语言文案都走 l10n key。可能已修或在后端 prompt。**实现前需真机/再查确认是否仍是 bug**，否则移出。
- **16 词卡多余中文释义**：`target_word_detail_screen.dart:512-580` `_DefinitionSections`。非 CJK 词渲染三段（Bilingual 头+中文定义 558-563+英文定义 565-569），CJK 词只显英文。修：删非 CJK 的中文定义段，统一只显英文。
- **17 音频按钮过多**：`pronunciation_controls.dart:143-187` 非 CJK 词渲染 UK/US/0.5× 三钮；CJK 只 Audio+0.5×。修：非 CJK 也收敛为 Audio+0.5×（去 UK/US 区分）。
- **18 Profile 命名不统一**：三处硬编码 `profile_screen.dart:145 'Data & storage'`、`settings_screen.dart:74 'Data & Account'`、`data_settings_screen.dart:24 'Data & Account'`。修：统一 l10n key。
- **19 DarkMode "Choose Language" 换行**：`app_drawer.dart:32` 硬编码 `'Choose Language'`。修：换 `l10n.pickerChooseLanguage`（已存在）。⚠️换行真因存疑，需真机复核是否单纯文案长度。
- **20 开屏 "word image" 无图**：`onboarding_screen.dart:24 onboardingFeatureImageCards`、`splash_screen.dart:91 splashTagline`。无真实图像。修：产品决策——去掉"Image"措辞或改文案。
- **21 Onboarding 双设置共存**：`goal_setup_screen.dart:138-197`（每日词数 138-152 + deadline 155-191 + 共用保存 194）；deadline 设了会 auto 覆盖 dailyGoal（77-79）。修：改互斥（单选/tab）。产品决策。
- **12 AI Writing snackbar 挡提交按钮**：`ai_writing_review_screen.dart:253-268 提交按钮 + 487-493 snackbar 无 duration`。修：snackbar 加短 duration / floating behavior。

### 数据 / 词典 / 成就 簇
- **9 日文词典 は→tooth**：`word_segmenter.dart:116-117` `buildHighlightVocab` 把词条 kana 字段也纳入可匹配 surface；"歯"(ha=tooth) 的 kana="は" 与助词 は 撞车，最长匹配命中。修：日语跳过纯假名虚词匹配/只匹配 word 字段/加 POS 过滤。
- **13 Analytics 训练 XP 不一致**：`progress_analytics_screen.dart:113,139` 用本地 `state.todayTrainingXp`（SharedPreferences），重启/多设备与后端不同步；无活动明细。修：改用后端 dailyXp 或加明细。⚠️需确认口径。
- **14 3-Day Streak 单日解锁**：疑 demo 硬编码——`user_profile.dart:42 demo() streak:3`、`analytics.dart:164 mock() streakDays:5`。⚠️连后端时非 demo，此根因可能不对；需确认真机连后端下 streak 来源与成就判定。
- **10 Mistake Book AI 入口不可见**：`mistake_book_screen.dart:97-127` `_MistakeWordRow` 的 Row 5 元素无宽度约束，AppPill 过宽挤出 IconButton(autoAwesome)。修：给 IconButton/AppPill 固定宽度或 Flexible。
- **22 语言切换不同步**：`app_controller.dart:387-398` `updateTargetLanguage()` 只改 `targetLanguage`，不切 `currentLanguage`/词书 → 显示新语言但课程/词书/进度仍旧。⚠️但地图入口 `_startLearning` 之后接了 `showLanguageWordbookPicker`，需核实是否已覆盖；关联 Cycle10 F。修：切语言时完整切 scope+默认词书。
- **待查5.3 重复加词无反馈**：`app_controller.dart:878` 重复时 `return true`（幂等），`_save()` 显示"已保存"，用户看不到"已存在"。修：区分反馈文案（返回已存在标志/errorMessage 提示）。

## Cycle 11 全 22 项分批（SDD）建议
按风险与相邻代码分组，逐 Part 走 SDD（每 task: failing test → 实现 → spec review → quality review → verify）：
- **Part 1 高危（3）**：6.1 课程词数接每日计划 · 7.2 Profile404 友好态 · 6.2 错题本（先写复现测试坐实，判分补 trim + 新词首曝不计错题）
- **Part 2 训练游戏（5）**：D-01/03/04/02/06，集中在 training_session_screen + quiz_session_screen
- **Part 3 UI/l10n（8）**：4 地图命中框 · 16 词卡中文释义 · 17 音频钮 · 18 命名统一 · 19 DarkMode 换行 · 10 AI 入口布局 · 12 snackbar · 11 AI 写死语言（若确认是 bug）
- **Part 4 数据/词典/产品决策（6）**：9 日文 は · 13 Analytics XP · 14 streak · 22 语言切换 · 5.3 重复词反馈 · 20/21 产品决策项（开屏文案/Onboarding 互斥）
