# LinguaQuest 词境星球产品规划蓝图

## 1. 项目总览

LinguaQuest 词境星球是一款面向移动端的语言学习产品，核心方向是把“百词斩式图像记忆”和“多邻国式游戏化学习路径”结合起来，做成一个更完整、更有持续学习动力的英语学习 App。

我们的目标不是做一个简单的背单词工具，而是规划一个真实可落地的学习产品：用户可以选择学习目标，沿着学习路径完成短课，通过图片、发音、例句、拼写、听力和复习任务掌握单词，并用 XP、streak、成就、排行榜和错题回收机制保持长期学习。

产品采用完整移动应用思维设计，覆盖账号系统、学习路径、词书、单词卡、练习题、复习算法、错题本、学习数据、社交竞争、设置和帮助支持。所有基础页面和推荐页面都纳入整体规划，不再按“最低版本”删减。

## 2. 产品定位

产品名：LinguaQuest 词境星球  
一句话定位：一款结合“百词斩式图像记忆”和“多邻国式游戏化路径”的移动端语言学习 App。

核心理念：

- 不是单纯背单词，而是从单词、例句、听力、拼写、口语到情景表达形成完整学习闭环。
- 不是简单 quiz，而是通过每日任务、学习路径、复习算法、错题回收、成就系统让用户长期坚持。
- 不是简单 demo，而是按真实教育产品规划信息架构、数据模型、用户路径、增长机制和技术架构。

目标用户：

- 大学生：准备 CET-4、CET-6、IELTS、TOEFL、MUET 或日常英语提升。
- 自学者：每天碎片时间学习 5 到 15 分钟。
- 老师或学习小组组织者：可以创建班级、分配词书、查看学习进度。

产品差异化：

- 百词斩强在图像联想、词书、复习模式和考试词库。
- 多邻国强在短课、路径推进、连胜、排行榜、任务和游戏化反馈。
- LinguaQuest 将两者组合，并增加更清楚的学习数据、个性化复习、错题本、自定义词卡和班级模式。

## 3. 竞品与学习机制研究结论

### 3.1 百词斩启发

可借鉴点：

- 图像背单词：用图片强化词义联想，降低记忆门槛。
- 多模式复习：中英互选、拼写、听音、填空等训练方式覆盖不同记忆维度。
- 词书体系：按考试或目标分词书，例如中学、四六级、考研、雅思、托福等。
- 学习计划：用户设置每日目标，系统记录学习行为并通过提醒帮助坚持。
- 社交动力：班级、同桌、打卡、PK 等机制提升持续学习意愿。

应用到我们的 App：

- 每个词条包含 image、pronunciation、meaning、example sentence、word family、tags。
- 用户可以选择目标词书，也可以创建自己的 custom word cards。
- 复习中心根据掌握度自动安排每日复习。

### 3.2 多邻国启发

可借鉴点：

- Bite-sized lesson：每节课短而明确，降低开始学习的心理成本。
- Learning path：让用户知道下一步学什么，不需要自己规划。
- Spaced repetition：在学习路径和 personalized practice 中穿插旧内容复习。
- Leaderboard / League：把学习量转化为可见排名，制造轻量竞争。
- Streak / Quest：把长期坚持变成明确的日常目标。

应用到我们的 App：

- 首页显示今日目标：新学单词、复习单词、完成一个 mini lesson。
- 学习路径用 level/map 形式展示，从基础词汇逐步解锁到场景表达。
- 复习中心不只是随机抽题，而是根据 nextReviewAt、accuracy、mistakes 安排。
- 排行榜只作为辅助，不让刷 XP 破坏真实学习。

### 3.3 学习科学依据

产品应采用三种基础学习机制：

- Spaced repetition：在用户快忘记前复习，提升长期记忆。
- Retrieval practice：让用户主动回忆答案，而不是只看解释。
- Multimodal learning：用图片、声音、例句、拼写和语境共同强化记忆。

这让我们的设计理由更接近真实产品决策，而不是停留在“因为好看所以这样做”。

## 4. 产品愿景与核心用户闭环

用户每天打开 App 后应形成一个完整闭环：

1. 看首页今日任务。
2. 进入 Learning Path 学 5 到 10 个新词或一个场景 mini lesson。
3. 完成图片识别、听音选词、拼写、句子填空等题型。
4. 错题自动进入 Mistake Review。
5. 系统更新 mastery level、next review date、XP、streak。
6. 用户在 Progress 页面看到词汇量、准确率和连续学习天数。
7. 第二天根据遗忘曲线继续复习。

核心体验目标：

- 用户不用思考“今天学什么”，App 直接给出今日学习包。
- 每次学习 3 到 8 分钟也有明确完成感。
- 视觉上要比普通 CRUD app 更完整：卡片、路径、进度条、状态标签、结果页、空状态、加载状态都要有。

## 5. 产品功能总览

### 5.1 账号与用户系统

- 注册
- 登录
- 选择学习目标
- 选择当前英语水平
- 选择每日目标
- 个人资料编辑
- 学习偏好设置

落地规划：

- Firebase Authentication 或本地模拟登录。
- 用户 profile 存入 Firestore。
- 注册时保存 name、email、level、dailyGoal。

### 5.2 Onboarding 与水平定位

真实产品功能：

- 选择学习目标：CET-4、CET-6、IELTS、TOEFL、Daily English、Business English。
- 选择基础水平：Beginner、Elementary、Intermediate、Advanced。
- Placement quiz：用 8 到 12 道题粗略判断词汇水平。
- 自动推荐词书与每日学习量。

落地规划：

- 用 2 到 3 个 onboarding screens 完成目标和每日单词数设置。
- 可先不做真正算法，用表单选择生成 learning plan。

### 5.3 学习路径 Learning Path

真实产品功能：

- Section：基础词汇、校园生活、旅行、工作、考试高频、口语表达。
- Unit：每个 section 下多个 unit。
- Lesson：每个 unit 包含 3 到 6 个短 lesson。
- Review node：路径中穿插复习节点。
- Boss quiz：每个 unit 末尾有综合测试。

落地规划：

- Learning Path 页面展示 6 到 10 个 lesson cards。
- 点击 lesson 进入题目练习。
- 完成后显示 Result 页面，并写入 studySessions。

### 5.4 单词学习模块

词条内容：

- word
- phonetic
- audioUrl
- partOfSpeech
- Chinese meaning
- English definition
- example sentence
- example translation
- imageUrl
- tags
- difficulty
- examCategory

学习方式：

- 图片选词
- 词义选择
- 听音选词
- 拼写输入
- 例句填空
- 单词卡翻转
- 快速斩词：已掌握的词直接跳过并降低复习频率

落地规划：

- Word Detail 页面展示单词卡。
- Quiz 页面实现至少 3 种题型：选择中文释义、图片选词、拼写。

### 5.5 复习与错题系统

真实产品功能：

- Review Center 显示今日需复习数量。
- Mistake Book 显示最近错题。
- Weak Words 根据错误率排序。
- Auto Review Queue 根据 nextReviewAt 和 masteryLevel 生成。

落地规划：

- 实现 userWords 记录 correctCount、wrongCount、masteryLevel、nextReviewAt。
- Review 页面读取 due words。
- 错题自动加入复习列表。

### 5.6 自定义词卡 CRUD

这是产品中最适合作为核心数据管理模块的完整 CRUD。

为什么选它：

- 和语言学习产品核心功能高度相关。
- 容易展示 add、view、edit、delete。
- 比普通 todo list 更有业务意义。
- 数据模型清晰，Firebase 操作路径明确，后续也方便扩展到复习算法和学习数据分析。

用户可以：

- Add：添加自定义单词、释义、例句、标签、难度。
- View：查看自己的词卡列表和详情。
- Edit：修改释义、例句、标签、掌握状态。
- Delete：删除不再需要的词卡。

Firestore collection 建议：

```text
users/{uid}/customWords/{customWordId}
```

字段建议：

```text
id
word
meaning
exampleSentence
note
tag
difficulty
masteryLevel
correctCount
wrongCount
createdAt
updatedAt
nextReviewAt
```

### 5.7 游戏化系统

真实产品功能：

- XP：完成学习和复习获得经验。
- Streak：连续学习天数。
- Daily Quest：每日任务，如完成 1 节课、复习 20 个词、错题正确率超过 80%。
- Badge：7-day streak、100 words learned、first perfect lesson。
- League：按周 XP 排名。
- Friend Quest：好友共同完成学习目标。

设计原则：

- 游戏化服务学习，不让用户为了刷分跳过真实掌握。
- 排行榜只统计有效学习行为，例如正确完成复习、通过 lesson quiz。
- 对连续学习失败提供 streak freeze，避免用户因为中断一天直接放弃。

落地规划：

- 首页显示 XP、streak、today progress。
- 完成 quiz 后更新 XP。
- 可先用本地或 Firestore 保存 achievement 状态。

### 5.8 班级与社交学习

真实产品功能：

- 老师创建班级。
- 学生输入 class code 加入。
- 老师分配词书和每日任务。
- 老师查看班级排行榜、完成率、弱项词汇。
- 学生可以同桌组队打卡。

落地规划：

- 班级创建、邀请码加入和班级进度页纳入完整产品规划。
- 如果开发时间有限，可以先实现加入班级和班级排行榜，再扩展老师端任务分配。

### 5.9 AI Tutor 与智能反馈

真实产品功能：

- 生成个性化例句。
- 解释易混词，例如 affect/effect。
- 口语跟读评估。
- 基于错题生成 mini lesson。
- Chat role-play：模拟餐厅、机场、面试等场景。

落地规划：

- 首版可以先做 mock AI feedback 页面，展示个性化解释、易混词说明和例句生成的交互方式。
- 后续版本再接入真实 AI API，避免早期版本被接口成本和稳定性拖慢。

## 6. 页面架构

### 6.1 完整页面范围

以下页面全部纳入 LinguaQuest 的产品规划，不再分“最低版本”和“推荐版本”。基础账号、主页、学习、复习、词卡、个人中心、设置、帮助、班级和数据分析都要形成完整移动端体验。

1. Splash Screen  
   展示 logo、检查登录状态。

2. Onboarding Screen  
   简短介绍学习模式：图像记忆、游戏化路径、智能复习。

3. Register Screen  
   输入 name、email、password、target、daily goal。

4. Login Screen  
   邮箱密码登录，跳转注册。

5. Goal Setup Screen  
   选择 CET-4、CET-6、IELTS、TOEFL、Daily English 等目标。

6. Home Dashboard  
   今日任务、streak、XP、今日复习数量、继续学习按钮。

7. Learning Path Screen  
   显示章节、关卡、锁定状态、复习节点。

8. Lesson Preview Screen  
   显示本节课将学习的词汇、预计时间、奖励 XP。

9. Quiz Session Screen  
   展示图片选词、听音、选择、拼写、填空题。

10. Lesson Result Screen  
   显示正确率、XP、错题、下一步按钮。

11. Wordbook Screen  
   展示目标词书、自定义词卡入口、搜索和筛选。

12. Custom Word CRUD List Screen  
   显示用户自定义单词列表，支持新增、搜索、删除。

13. Add/Edit Custom Word Screen  
   表单输入 word、meaning、example、note、tag。

14. Word Detail Screen  
   单词详情、例句、发音、掌握度、加入复习。

15. Review Center Screen  
   今日待复习、弱项词、错题本入口。

16. Mistake Book Screen  
   最近错题、错误次数、重新练习。

17. Leaderboard Screen  
   本周 XP 排行、好友排行、班级排行。

18. Quest Screen  
   每日任务和成就徽章。

19. Progress Analytics Screen  
   学习日历、掌握词数、准确率、复习完成率。

20. Profile Screen  
   用户资料、学习目标、总 XP、streak。

21. Settings Screen  
   通知、语言、深色模式、每日提醒时间、退出登录。

22. Help/Support Screen  
   FAQ、使用说明、联系支持。

23. About Screen  
   App 版本、团队成员、产品愿景和隐私说明。

24. Teacher/Class Mode Screen  
   创建班级、加入班级、查看成员。

25. Class Progress Screen  
   班级完成率和弱项统计。

### 6.2 页面优先级

核心闭环页面：

- Splash Screen
- Onboarding Screen
- Register Screen
- Login Screen
- Goal Setup Screen
- Home Dashboard
- Learning Path Screen
- Lesson Preview Screen
- Quiz Session Screen
- Lesson Result Screen
- Wordbook Screen
- Custom Word CRUD List Screen
- Add/Edit Custom Word Screen
- Word Detail Screen
- Review Center Screen
- Mistake Book Screen
- Profile Screen
- Settings Screen
- Help/Support Screen

增强体验页面：

- Leaderboard Screen
- Quest Screen
- Progress Analytics Screen
- About Screen
- Teacher/Class Mode Screen
- Class Progress Screen

## 7. 导航设计

### 7.1 登录前导航

```text
Splash -> Onboarding -> Register/Login -> Goal Setup -> Home
```

### 7.2 登录后底部导航

建议使用 5 个 tabs：

```text
Home | Learn | Review | Quest | Profile
```

每个 tab 职责：

- Home：今日任务和继续学习。
- Learn：学习路径和词书。
- Review：复习中心和错题本。
- Quest：排行榜、任务、成就。
- Profile：个人资料、设置、帮助。

### 7.3 关键用户流程

新用户首次使用：

```text
Register -> Goal Setup -> Home -> Learning Path -> Lesson -> Result -> Review Center
```

每日学习：

```text
Login -> Home -> Continue Lesson -> Quiz -> Result -> Mistake Review -> Home
```

自定义词卡 CRUD：

```text
Wordbook -> My Custom Words -> Add Word -> Word Detail -> Edit Word -> Delete Word
```

复习流程：

```text
Review Center -> Due Words -> Quiz Session -> Result -> Update Mastery -> Next Review Date
```

## 8. UI / UX 设计方向

### 8.1 视觉风格

关键词：明亮、专业、轻游戏化、学习效率、移动端友好。

建议色彩：

- Primary：Teal / Cyan，用于主按钮、学习路径、进度条。
- Secondary：Coral / Orange，用于 streak、warning、重点提醒。
- Success：Green，用于正确、完成、掌握。
- Error：Red，用于错误答案。
- Background：浅灰白，避免过度花哨。
- Dark mode：深灰背景 + 高对比文字。

避免：

- 页面全是同一种蓝色或紫色。
- 只堆卡片没有真实学习流程。
- 过大的 hero section，不像工具型 App。
- 按钮文字过长导致移动端溢出。

### 8.2 组件规范

建议使用 Material Design 3：

- BottomNavigationBar / NavigationBar
- Cards for lessons and words
- LinearProgressIndicator for daily goal
- Chips for tags and difficulty
- Dialog for delete confirmation
- SnackBar for success/error feedback
- TabBar for wordbook/review categories
- FloatingActionButton for adding custom word
- Form validation for input fields

### 8.3 关键页面布局建议

Home Dashboard：

- 顶部：问候语 + streak badge。
- 中部：今日任务卡片，显示 new words、review words、daily goal progress。
- 主 CTA：Continue Learning。
- 下方：weak words preview、daily quest、recent achievement。

Learning Path：

- 使用垂直 path card 或 timeline。
- Lesson card 显示 title、status、XP、estimated time。
- 已完成、当前、锁定三种状态明显区分。

Quiz Session：

- 顶部 progress bar。
- 中部 question area。
- 选项按钮固定高度，避免跳动。
- 底部 Check / Continue button。
- 答错后显示简短解释，不要直接进入下一题。

Review Center：

- 三个入口：Due Today、Mistake Book、Weak Words。
- 每个入口显示数量和优先级。

Custom Word CRUD：

- List 页面支持 search、filter chips。
- Add/Edit 页面使用表单验证。
- Delete 使用 confirmation dialog。

## 9. 技术架构建议

### 9.1 推荐技术栈

前端：

- Flutter
- Dart
- Material Design 3
- Riverpod 或 Provider 做状态管理

后端与数据库：

- Firebase Authentication
- Cloud Firestore
- Firebase Storage，可选，用于图片或音频
- Firebase Cloud Messaging，可选，用于学习提醒

本地缓存：

- SharedPreferences：保存 theme、notification settings、last selected target。
- Hive 或 SQLite：可选，用于离线词库缓存。

为什么推荐 Firebase：

- 与 Flutter 生态集成成熟。
- CRUD 展示清楚。
- 不需要维护服务器。
- 能体现 cloud database，不像纯本地 demo。

### 9.2 Flutter 项目结构建议

```text
lib/
  main.dart
  app.dart
  core/
    constants/
    theme/
    utils/
    widgets/
  features/
    auth/
      screens/
      services/
      models/
    onboarding/
    home/
    learning_path/
    quiz/
    wordbook/
      models/
      screens/
      services/
      widgets/
    review/
    quests/
    profile/
    settings/
    help/
  data/
    firebase/
    repositories/
```

### 9.3 核心数据模型

UserProfile：

```text
uid
name
email
avatarUrl
targetExam
level
dailyGoal
xp
streak
lastStudyDate
createdAt
updatedAt
```

Word：

```text
id
word
phonetic
meaning
definition
partOfSpeech
exampleSentence
exampleTranslation
imageUrl
audioUrl
difficulty
tags
bookId
```

CustomWord：

```text
id
uid
word
meaning
exampleSentence
note
tag
difficulty
masteryLevel
correctCount
wrongCount
nextReviewAt
createdAt
updatedAt
```

StudySession：

```text
id
uid
lessonId
startedAt
endedAt
totalQuestions
correctAnswers
xpEarned
mistakeWordIds
```

ReviewEvent：

```text
id
uid
wordId
isCorrect
answerTimeMs
reviewedAt
masteryBefore
masteryAfter
nextReviewAt
```

Quest：

```text
id
title
description
type
targetValue
xpReward
```

UserQuestProgress：

```text
uid
questId
currentValue
isCompleted
completedAt
```

## 10. Firestore 结构建议

```text
users/{uid}
users/{uid}/customWords/{customWordId}
users/{uid}/studySessions/{sessionId}
users/{uid}/reviewEvents/{eventId}
users/{uid}/questProgress/{questId}

wordBooks/{bookId}
wordBooks/{bookId}/words/{wordId}

lessons/{lessonId}
lessons/{lessonId}/questions/{questionId}

leaderboards/{weekId}/entries/{uid}
classes/{classId}
classes/{classId}/members/{uid}
classes/{classId}/classTasks/{taskId}
```

首版落地集合：

```text
users/{uid}
users/{uid}/customWords/{customWordId}
users/{uid}/studySessions/{sessionId}
```

这样就能支撑登录、Profile、Custom Word CRUD、学习记录和复习数据沉淀。

## 11. 核心 CRUD 设计详解

CRUD 对象：Custom Word Card

### 11.1 Create / Insert

用户在 Add Custom Word 页面输入 word、meaning、example、note、tag。点击 Save 后进行表单验证，然后调用 Firestore add 或 set，把数据写入：

```text
users/{uid}/customWords/{customWordId}
```

设计说明重点：

- 表单如何收集用户输入。
- 为什么要验证空字段。
- Firestore 如何生成 document。
- createdAt 和 updatedAt 如何保存时间。

### 11.2 Retrieve / Read

Custom Word List 页面使用 stream 或 future 从 Firestore 读取当前用户的 customWords。可以按 createdAt 或 masteryLevel 排序。

设计说明重点：

- 只读取当前 uid 下的数据，体现用户数据隔离。
- StreamBuilder 可以实时更新列表。
- 空数据时显示 empty state。

### 11.3 Update / Edit

用户进入 Edit Custom Word 页面，系统把原来的数据填入表单。用户修改后点击 Save，调用 update 修改 meaning、exampleSentence、note、tag、difficulty、updatedAt。

设计说明重点：

- edit screen 如何复用 add screen。
- document id 如何定位要修改的 record。
- 只更新变化字段，避免覆盖整条数据。

### 11.4 Delete

用户在 Word Detail 或 List 页面点击 delete，先弹出 confirmation dialog。确认后调用 delete 删除 Firestore document。

设计说明重点：

- 删除前确认，避免误删。
- delete 后列表自动刷新。
- 删除属于 destructive action，所以 UI 要明显提示。

## 12. 复习算法设计

首版可使用简单可解释的 spaced repetition 规则，不需要复杂机器学习。

字段：

```text
masteryLevel: 0 to 5
correctCount
wrongCount
lastReviewedAt
nextReviewAt
```

间隔建议：

```text
Level 0: same day
Level 1: 1 day later
Level 2: 3 days later
Level 3: 7 days later
Level 4: 14 days later
Level 5: 30 days later
```

规则：

- 答对：masteryLevel + 1，最高 5。
- 答错：masteryLevel - 1，最低 0，并加入 Mistake Book。
- nextReviewAt 根据新的 masteryLevel 计算。

伪代码：

```text
if answerCorrect:
    masteryLevel = min(masteryLevel + 1, 5)
    correctCount += 1
else:
    masteryLevel = max(masteryLevel - 1, 0)
    wrongCount += 1

nextReviewAt = now + intervalFor(masteryLevel)
```

产品逻辑：这个算法让熟悉的单词复习间隔变长，让错误单词更快再次出现，符合 spaced repetition 和 retrieval practice 的学习原则。

## 13. 完整产品落地范围

所有页面和功能都纳入 LinguaQuest 的产品规划。为了保证开发顺序清晰，可以按产品闭环分层推进，但不是删除任何页面。

### 13.1 第一阶段：核心学习闭环

- Flutter Android app
- Splash Screen
- Onboarding Screen
- Register Screen
- Login Screen
- Goal Setup Screen
- Home Dashboard
- Learning Path Screen
- Lesson Preview Screen
- Quiz Session Screen
- Lesson Result Screen
- Wordbook Screen
- Custom Word CRUD List Screen
- Add/Edit Custom Word Screen
- Word Detail Screen
- Profile Screen
- Settings Screen
- Help/Support Screen
- Firebase Authentication
- Firestore 数据保存
- 表单验证
- 删除确认
- 加载状态、空状态、错误提示

### 13.2 第二阶段：复习与激励闭环

- Review Center Screen
- Mistake Book Screen
- XP 和 streak
- Daily Quest
- Badge / achievement
- StudySession 记录
- Search / filter custom words
- Dark mode
- Spaced repetition nextReviewAt
- Weak Words 自动归类

### 13.3 第三阶段：社交、班级和智能化

- Leaderboard Screen
- Quest Screen
- Progress Analytics Screen
- About Screen
- Teacher/Class Mode Screen
- Class Progress Screen
- Audio pronunciation
- Image upload
- Push notification
- AI tutor
- Offline cache
- Class code join
- 老师任务分配和班级学习数据分析

## 14. 开发里程碑

### Phase 1：产品骨架与 UI

- 创建 Flutter project。
- 设置主题、颜色、路由、底部导航。
- 完成登录前流程：Splash、Onboarding、Register、Login、Goal Setup。
- 完成登录后主导航：Home、Learn、Review、Quest、Profile。

输出：能在 Android emulator 跑通完整页面导航。

### Phase 2：账号、数据模型与 Firebase

- 配置 Firebase。
- 实现 Authentication。
- 创建 users profile。
- 定义 UserProfile、Word、CustomWord、StudySession、ReviewEvent 数据模型。
- 封装 Firestore service 和 repository。

输出：用户可以注册、登录、保存个人学习目标。

### Phase 3：词卡 CRUD 与词书

- 实现 Custom Word add/read/edit/delete。
- 实现 Wordbook、Custom Word List、Add/Edit、Word Detail。
- 加入搜索、筛选、表单验证、loading、empty state、delete dialog。

输出：自定义词卡形成完整数据管理闭环。

### Phase 4：学习路径与练习体验

- 实现 Learning Path。
- 实现 Lesson Preview。
- 实现 Quiz Session。
- 实现 Lesson Result。
- 记录 StudySession。
- 更新 XP、streak 和 lesson status。

输出：用户可以从首页进入学习路径，完成一次完整短课。

### Phase 5：复习、错题和成长系统

- 实现 Review Center。
- 实现 Mistake Book。
- 实现 nextReviewAt 复习调度。
- 实现 Quest、Badge、Leaderboard。
- 实现 Progress Analytics。

输出：产品从“能学”升级为“能持续学”。

### Phase 6：班级、通知和智能反馈

- 实现 Teacher/Class Mode。
- 实现 Class Progress。
- 实现 class code join。
- 实现学习提醒和 push notification。
- 接入或模拟 AI tutor。
- 补充音频、图片、离线缓存。

输出：产品具备真实学习平台的扩展能力。

## 15. 团队分工建议

假设 4 人团队：

Member 1：UI / Navigation Lead  
负责 app theme、bottom navigation、Splash、Onboarding、Home、Learning Path、Profile、Settings、Help 页面。

Member 2：Firebase / Data Lead  
负责 Firebase setup、Authentication、Firestore service、UserProfile、CustomWord、StudySession、ReviewEvent model。

Member 3：Learning Feature Lead  
负责 Wordbook、Custom Word CRUD、Word Detail、Quiz Session、Lesson Result、Review Center、Mistake Book。

Member 4：Growth / QA Lead  
负责 Quest、Leaderboard、Progress Analytics、Teacher/Class Mode、Class Progress、全流程测试和视觉一致性检查。

## 16. 产品演示路径

演示时按这个顺序最清楚：

1. 打开 App，展示 Splash 和 Login。
2. 注册新用户，选择学习目标和每日目标。
3. 进入 Home，展示今日任务、XP、streak。
4. 进入 Learning Path，展示 lesson cards。
5. 完成一个 quiz，展示 Result 页面。
6. 进入 Wordbook，展示 Custom Words。
7. 新增一个 custom word。
8. 返回列表查看刚添加的词。
9. 编辑这个词的例句或 tag。
10. 删除这个词，展示 confirmation dialog 和列表刷新。
11. 进入 Review Center 和 Mistake Book，展示复习与错题回收。
12. 展示 Quest、Leaderboard、Progress Analytics。
13. 展示 Profile、Settings、Help、About。
14. 展示 Teacher/Class Mode 和 Class Progress。

这样演示能覆盖 UI、navigation、CRUD、database、learning concept。

## 17. 风险与范围控制

风险 1：功能太多导致核心 CRUD 不稳定  
解决：先完成 Custom Word CRUD，再做 XP、Quiz、Review。

风险 2：Firebase 配置耗时  
解决：一名成员专门负责 Firebase，并尽早做最小读写测试。

风险 3：UI 看起来像普通表单 App  
解决：必须加入 Learning Path、Quiz Result、XP、streak、progress bar，让产品感明显。

风险 4：数据结构复杂导致后期难扩展  
解决：提前定义 UserProfile、CustomWord、StudySession、ReviewEvent 等模型，并把 Firestore 访问封装到 service/repository。

风险 5：AI tutor 成本高、接口不稳定  
解决：首版先做 mock AI feedback，把交互和页面跑通，再考虑接入真实 AI API。

## 18. 最终产品方向

最终建议做成：

LinguaQuest 词境星球：基于 Flutter 和 Firebase 的移动端语言学习 App。

必须突出 5 个卖点：

1. 百词斩式图像词卡：每个词有图片、释义、例句和掌握度。
2. 多邻国式学习路径：用户按关卡学习，不迷路。
3. 个性化复习：根据答题结果安排 nextReviewAt。
4. 游戏化激励：XP、streak、daily quest、result page。
5. 完整云端 CRUD：用户自定义词卡 add、view、edit、delete。

如果时间有限，宁可少做高级功能，也要保证：

- 页面完整。
- 导航顺畅。
- CRUD 真实可用。
- UI 一致。
- 学习流程完整。
- 数据状态稳定。

## 19. 参考资料

- [Duolingo Learn](https://www.duolingo.com/learn)
- [Duolingo Blog: Spaced Repetition](https://blog.duolingo.com/spaced-repetition-for-learning/)
- [Duolingo Blog: Leaderboards and Leagues](https://blog.duolingo.com/duolingo-leagues-leaderboards/)
- [Duolingo English Test: CEFR alignment](https://blog.englishtest.duolingo.com/duolingo-test-aligned-with-cefr/)
- [百词斩 App Store 页面](https://apps.apple.com/cn/app/%E7%99%BE%E8%AF%8D%E6%96%A9-%E5%AD%A6%E8%8B%B1%E8%AF%AD-%E8%83%8C%E5%8D%95%E8%AF%8D%E5%BF%85%E5%A4%87/id557545298?l=en-GB)
- [Council of Europe CEFR descriptors](https://www.coe.int/en/web/common-european-framework-reference-languages/cefr-descriptors-search)
- [Spaced repetition for mobile-assisted word learning](https://scholars.ln.edu.hk/en/publications/spaced-repetition-for-authentic-mobile-assisted-word-learning-nat)
