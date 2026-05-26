# AGENT.md

## 项目概览

本仓库是 `LinguaQuest`（词境星球）移动端语言学习 App 的项目工作区。产品目标是用 Flutter 构建一个结合图像记忆、游戏化学习路径、复习算法、自定义词卡 CRUD 和学习数据沉淀的英语学习应用。

当前仓库包含两部分：

- `LinguaQuest_Product_Blueprint.md`：完整产品规划蓝图，是理解需求、页面范围、数据模型、里程碑和演示路径的主要依据。
- `linguaquest/`：Flutter 工程。目前仍基本是 Flutter 默认 counter 模板，业务功能尚未开始系统实现。

后续开发时不要把当前 counter demo 当成产品形态。应以产品蓝图为需求源，逐步替换默认模板代码。

## 当前实现状态

- Flutter 工程位于 `linguaquest/`。
- 入口文件是 `linguaquest/lib/main.dart`。
- 当前依赖很少：`flutter`、`cupertino_icons`，开发依赖包含 `flutter_test` 和 `flutter_lints`。
- 当前测试文件 `linguaquest/test/widget_test.dart` 仍是默认 counter smoke test。
- 当前 README 仍是 Flutter 默认 README，尚未描述 LinguaQuest 的业务。
- 根目录 `.gitignore` 目前只忽略 `.DS_Store`。
- Git 工作区在本次阅读时存在 `.DS_Store` 的未提交修改，和业务代码无关；不要无故改动或回滚用户已有修改。

## 产品需求摘要

LinguaQuest 的核心定位：

- 面向移动端的英语学习 App。
- 结合“百词斩式图像词卡”和“多邻国式学习路径”。
- 通过 XP、streak、daily quest、成就、排行榜、错题回收和 spaced repetition 提升持续学习动力。
- 使用自定义词卡作为核心 CRUD 模块，展示真实数据管理能力。

必须突出的核心卖点：

- 图像词卡：单词包含图片、释义、例句、发音、掌握度等信息。
- 学习路径：用户按 section、unit、lesson 推进，不需要自己规划学习内容。
- 个性化复习：根据 `masteryLevel`、答题结果和 `nextReviewAt` 安排复习。
- 游戏化激励：XP、streak、daily quest、result page。
- 云端 CRUD：用户可以 add、view、edit、delete 自定义词卡。

## 页面范围

蓝图将以下页面纳入产品规划：

- 登录前流程：Splash、Onboarding、Register、Login、Goal Setup。
- 登录后主流程：Home Dashboard、Learning Path、Lesson Preview、Quiz Session、Lesson Result。
- 词卡与词书：Wordbook、Custom Word CRUD List、Add/Edit Custom Word、Word Detail。
- 复习系统：Review Center、Mistake Book、Weak Words。
- 激励系统：Quest、Badge、Leaderboard、Progress Analytics。
- 用户与设置：Profile、Settings、Help/Support、About。
- 扩展功能：Teacher/Class Mode、Class Progress、AI Tutor/mock AI feedback。

建议底部导航：

```text
Home | Learn | Review | Quest | Profile
```

关键演示路径：

```text
Register -> Goal Setup -> Home -> Learning Path -> Lesson -> Result -> Wordbook -> Custom Word CRUD -> Review Center
```

## 推荐技术架构

蓝图建议的主要技术栈：

- Flutter + Dart。
- Material Design 3。
- Riverpod 或 Provider 作为状态管理方案。
- Firebase Authentication。
- Cloud Firestore。
- Firebase Storage 可选，用于图片或音频。
- Firebase Cloud Messaging 可选，用于学习提醒。
- SharedPreferences 用于主题、提醒时间、最近目标等本地偏好。
- Hive 或 SQLite 可选，用于离线词库缓存。

推荐 Flutter 目录结构：

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

实现新功能时优先保持 feature-first 结构，避免继续堆在 `main.dart`。

## 核心数据模型

后续实现时至少应考虑以下模型：

- `UserProfile`：`uid`、`name`、`email`、`targetExam`、`level`、`dailyGoal`、`xp`、`streak`、`lastStudyDate`。
- `Word`：`word`、`phonetic`、`meaning`、`definition`、`partOfSpeech`、`exampleSentence`、`imageUrl`、`audioUrl`、`difficulty`、`tags`。
- `CustomWord`：`uid`、`word`、`meaning`、`exampleSentence`、`note`、`tag`、`difficulty`、`masteryLevel`、`correctCount`、`wrongCount`、`nextReviewAt`。
- `StudySession`：`uid`、`lessonId`、`startedAt`、`endedAt`、`totalQuestions`、`correctAnswers`、`xpEarned`、`mistakeWordIds`。
- `ReviewEvent`：`uid`、`wordId`、`isCorrect`、`answerTimeMs`、`masteryBefore`、`masteryAfter`、`nextReviewAt`。

Firestore 建议结构：

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

首版可先落地：

```text
users/{uid}
users/{uid}/customWords/{customWordId}
users/{uid}/studySessions/{sessionId}
```

## 开发优先级

优先级应围绕“先跑通核心闭环，再补游戏化和扩展能力”。

1. 产品骨架与导航：主题、路由、登录前流程、底部导航、主要页面壳。
2. 账号与数据模型：Firebase 初始化、Auth、UserProfile、Repository/Service 封装。
3. 自定义词卡 CRUD：Add、Read、Edit、Delete、搜索、筛选、表单验证、加载/空/错误状态、删除确认。
4. 学习路径与 Quiz：Learning Path、Lesson Preview、Quiz Session、Lesson Result、StudySession。
5. 复习与激励：Review Center、Mistake Book、`nextReviewAt`、XP、streak、Quest、Badge、Leaderboard。
6. 扩展：班级、通知、图片/音频、AI Tutor mock 或真实接入、离线缓存。

如果时间有限，优先保证：

- 页面导航完整。
- Custom Word CRUD 真实可用。
- 学习流程能从 Home 进入 Lesson 并产生 Result。
- UI 状态齐全：loading、empty、error、success、delete confirmation。
- 数据模型和 Firestore 路径清晰。

## UI 与交互约定

- 使用 Material Design 3。
- 主色建议 Teal/Cyan，辅助色建议 Coral/Orange；不要让界面只剩单一蓝紫色调。
- 移动端优先，按钮与文字要避免溢出。
- 学习产品应像工具型 App：清晰、高效、轻游戏化，避免纯营销式 hero 页面。
- 使用 progress bar、lesson status、chips、cards、SnackBar、Dialog、bottom navigation 等常见移动端组件。
- 删除自定义词卡必须有确认弹窗。
- Quiz 答错后应展示简短解释，而不是直接跳到下一题。
- 页面应包含真实状态：加载中、空状态、错误状态、成功反馈。

## 复习算法首版规则

首版 spaced repetition 可以使用简单可解释规则：

```text
Level 0: same day
Level 1: 1 day later
Level 2: 3 days later
Level 3: 7 days later
Level 4: 14 days later
Level 5: 30 days later
```

答题更新逻辑：

```text
if answerCorrect:
    masteryLevel = min(masteryLevel + 1, 5)
    correctCount += 1
else:
    masteryLevel = max(masteryLevel - 1, 0)
    wrongCount += 1

nextReviewAt = now + intervalFor(masteryLevel)
```

## 常用命令

在 Flutter 工程目录执行：

```bash
cd linguaquest
flutter pub get
flutter analyze
flutter test
flutter run
```

Web 调试可按本机设备情况使用：

```bash
cd linguaquest
flutter run -d chrome
```

注意：本工作区沙箱中执行 `flutter --version` 时，Flutter SDK 尝试写入 `/Users/lanyichen/Codes/Mobile/flutter/bin/cache/engine.stamp`，因为权限限制失败。这不是项目代码错误；需要在允许 SDK 写缓存的环境中运行 Flutter 命令。

## 协作注意事项

- 先阅读 `LinguaQuest_Product_Blueprint.md`，再改代码。
- 不要无故改动平台生成文件，除非正在配置 Android、iOS、macOS、Windows、Linux 或 Web 平台能力。
- 不要把默认 counter 示例继续扩展成业务功能；应拆出 `app.dart`、feature 目录和共享 theme/widgets。
- Firebase 接入前，先明确是否使用真实 Firebase 项目或 mock/local repository。
- 对新增业务逻辑补充聚焦测试；默认 counter 测试在业务替换后也应同步改掉。
- 保持改动范围小而完整。优先交付可运行的核心闭环，再逐步扩展。
