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
