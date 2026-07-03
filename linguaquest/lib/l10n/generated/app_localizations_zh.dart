// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'LinguaQuest';

  @override
  String get appSubtitle => '用短课节和智能复习积累词汇';

  @override
  String get tabHome => '首页';

  @override
  String get tabTraining => '训练场';

  @override
  String get tabAiLearning => 'AI 学习';

  @override
  String get tabDiscover => '发现';

  @override
  String get tabProfile => '我的';

  @override
  String get commonRegister => '注册';

  @override
  String get commonLogin => '登录';

  @override
  String get commonSettings => '设置';

  @override
  String get commonTheme => '主题';

  @override
  String get commonDailyReminder => '每日提醒';

  @override
  String get commonStudyPlan => '学习计划';

  @override
  String get commonWordbook => '单词本';

  @override
  String get commonCustomWords => '生词本';

  @override
  String get commonMistakeBook => '错题本';

  @override
  String get commonSearch => '搜索';

  @override
  String get commonReview => '复习';

  @override
  String get commonSave => '保存';

  @override
  String get commonCancel => '取消';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonAdd => '添加';

  @override
  String get commonClose => '关闭';

  @override
  String get commonBack => '返回';

  @override
  String get commonContinue => '继续';

  @override
  String get commonRetry => '再试一次';

  @override
  String get commonCheck => '检查';

  @override
  String get commonLeave => '离开';

  @override
  String get commonExit => '退出';

  @override
  String get commonDone => '完成';

  @override
  String get commonSubmit => '提交';

  @override
  String get commonProfile => '个人空间';

  @override
  String get commonLogout => '退出登录';

  @override
  String get commonXP => 'XP';

  @override
  String get commonDay => '天';

  @override
  String get commonDaysLabel => '天';

  @override
  String get commonWords => '词';

  @override
  String get commonLessons => '课';

  @override
  String get commonNew => '新学';

  @override
  String get commonDue => '待复习';

  @override
  String get commonMinutes => '分钟';

  @override
  String get commonLesson => '课程';

  @override
  String get commonMastery => '掌握';

  @override
  String get commonMasteryOutOf => '/5';

  @override
  String get commonAlreadyAdded => '已加入';

  @override
  String get commonWrongPrefix => '错 ';

  @override
  String get commonTimesSuffix => ' 次';

  @override
  String get commonViewAll => '查看全部';

  @override
  String get commonView => '查看';

  @override
  String get authRegisterTitle => '注册';

  @override
  String get authLoginTitle => '登录';

  @override
  String get authCreateProfile => '创建学习档案';

  @override
  String get authCreateProfileSubtitle => '先建立账号，再选择目标和每日节奏。';

  @override
  String get authStep1of2 => '第 1 步 / 共 2 步';

  @override
  String get authStep2of2 => '第 2 步 / 共 2 步';

  @override
  String get authNickname => '昵称';

  @override
  String get authNicknameHint => '输入昵称';

  @override
  String get authEmail => '邮箱';

  @override
  String get authEmailHint => 'name@example.com';

  @override
  String get authPassword => '密码';

  @override
  String get authPasswordHint => '设置密码';

  @override
  String get authNameRequired => '请输入昵称';

  @override
  String get authEmailRequired => '请输入邮箱';

  @override
  String get authEmailInvalid => '请输入有效邮箱';

  @override
  String get authPasswordRequired => '密码至少 6 位';

  @override
  String get authContinueToGoal => '继续设置目标';

  @override
  String get authHaveAccount => '已有账号，去登录';

  @override
  String get authAccountCreated => '账号已创建，请继续选择学习计划。';

  @override
  String get authWelcomeBack => '欢迎回来';

  @override
  String get authWelcomeBackSubtitle => '继续今天的学习路径，顺手清空到期复习卡。';

  @override
  String get authRegisterNew => '注册新账号';

  @override
  String get onboardingTitle => 'LinguaQuest';

  @override
  String get onboardingSubtitle => '短课节、视觉记忆卡和智能复习，帮你稳定积累英语词汇。';

  @override
  String get onboardingTagline => '像游戏闯关一样完成每日学习';

  @override
  String get onboardingTagWorld => '词境星球';

  @override
  String get onboardingTagStreak => '连续打卡';

  @override
  String get splashTagline => '图像词卡、清晰路径、智能复习。';

  @override
  String get studyNewScreenTitle => '新学';

  @override
  String get studyWordbookPath => '词书路径';

  @override
  String get studyEnterCards => '进入词卡学习';

  @override
  String get studyNewPackTitle => '今日新词包';

  @override
  String get studyNewPackDesc => '先自评，再看词卡，最后进入语境题。正式复习会单独排队。';

  @override
  String get studyNoNewWords => '暂无新学词';

  @override
  String get studyNewPausedHint => '学习计划已暂停。恢复计划后，系统会继续安排今日新词。';

  @override
  String get studyNewEmptyHint => '当前词书已经学完，或学习计划还没有生成。可以去词书路径检查下一组内容。';

  @override
  String get studyOpenWordbookPath => '打开词书路径';

  @override
  String studyTodayLearnCount(Object count) {
    return '今天先学 $count 个新词';
  }

  @override
  String get studyNewNoLessonHint => '完成复习后再补新词，保持节奏比堆任务更重要。';

  @override
  String studyNewPausedResume(Object section) {
    return '学习计划已暂停，恢复后继续从 $section 开始。';
  }

  @override
  String get studyRecallKnown => '认识';

  @override
  String get studyRecallFuzzy => '模糊';

  @override
  String get studyRecallUnknown => '不认识';

  @override
  String get studyStepSelfAssess => '自评';

  @override
  String get studyStepSelfAssessDesc => '降低无效重复';

  @override
  String get studyStepCards => '词卡';

  @override
  String get studyStepCardsDesc => '补全释义和例句';

  @override
  String get studyStepContext => '语境题';

  @override
  String get studyStepContextDesc => '主动回忆';

  @override
  String get mixedManageReviewQueue => '管理复习队列';

  @override
  String mixedReviewRatio(Object percent) {
    return '复习 $percent%';
  }

  @override
  String get mixedTitleNew => '今日新学包';

  @override
  String get mixedTitleReview => '快速复习';

  @override
  String get mixedTitleMixed => '今日混排学习包';

  @override
  String get mixedSaveReviewFailed => '暂时无法保存复习记录';

  @override
  String mixedUnsureOption(Object index) {
    return '还不确定 $index';
  }

  @override
  String get mixedSaveProgressTitle => '保存本次进度？';

  @override
  String get mixedSaveProgressBody =>
      '已保存的复习记录会保留；保存后会记录本次已完成题目，未完成词下次仍会进入学习包。';

  @override
  String get mixedContinueStudy => '继续学习';

  @override
  String get mixedLeaveWithoutSaving => '不保存离开';

  @override
  String get mixedSaveAndLeave => '保存并离开';

  @override
  String get mixedSaveStudyFailed => '暂时无法保存学习进度';

  @override
  String get mixedSelfAssessHint => '先自评，系统会调整今天的重复次数';

  @override
  String get mixedEnterRecognition => '进入识别题';

  @override
  String get mixedAddLaterRecall => '加入稍后复现';

  @override
  String get mixedReviewQuickAnswer => '复习快答';

  @override
  String get mixedFeedbackCorrect => '答对了，继续下一题。';

  @override
  String get mixedFeedbackWrong => '答错了，先看知识卡，稍后会再次出现。';

  @override
  String get mixedFeedbackRetry => '还不对。请选择到正确答案后再进入下一题。';

  @override
  String mixedShortRecallPrompt(Object word) {
    return '短间隔回忆：$word 的意思是？';
  }

  @override
  String mixedMeaningPrompt(Object word) {
    return '$word 的中文释义是？';
  }

  @override
  String get mixedStepRecognition => '识别';

  @override
  String get mixedStepShortRecall => '短间隔回忆';

  @override
  String get mixedStepDueReview => '到期复习';

  @override
  String get mixedStepKnowledge => '知识卡';

  @override
  String get mixedCompleteTitle => '今日学习包完成';

  @override
  String get mixedNoContentTitle => '今日没有待学习内容';

  @override
  String get mixedCompleteBody => '错题已经在本轮回收，答题记录和用时会保存到学习日志。';

  @override
  String get mixedNoContentBody => '当前没有新词或到期复习词。';

  @override
  String get mixedSaveAndHome => '保存并回首页';

  @override
  String get questCenterTitle => '任务中心';

  @override
  String get questCenterSubtitle => '完成学习动作后领取积分，也可以查看排名、分析和班级学习。';

  @override
  String get questDailyTask => '每日任务';

  @override
  String get questDailyTaskBody => '完成一节课程，并复习 5 个到期词。';

  @override
  String get questAchievements => '成就';

  @override
  String get questAchievementsBody => '连续 7 天、已学 100 词、首次满分课程等成就。';

  @override
  String get questAchievementsValue => '3 个';

  @override
  String get questLeaderboard => '排行榜';

  @override
  String get questLeaderboardBody => '好友和未来班级的每周 XP 排名。';

  @override
  String get questWeekly => '每周';

  @override
  String get questAnalytics => '学习分析';

  @override
  String get questAnalyticsBody => '正确率、词汇增长和复习完成趋势。';

  @override
  String get questTrend => '趋势';

  @override
  String get questAiTutor => 'AI 助教';

  @override
  String get questAiTutorBody => '解释错因，并给出例句建议。';

  @override
  String get aiTutorSamplePrompt => '解释 affect 和 effect 的区别';

  @override
  String get aiTutorSubtitle => '输入单词、语法或错题，获得结构化解释和可练习的例句。';

  @override
  String get aiTutorInputLabel => '询问单词、语法或错题';

  @override
  String get aiTutorSampleAnswer =>
      'Affect is usually a verb: \"The weather affects my mood.\" Effect is usually a noun: \"The effect was immediate.\" 你可以分别用两个词各造一个句子。';

  @override
  String get leaderboardDefaultName => '探索者';

  @override
  String get leaderboardTitle => '训练场排行榜';

  @override
  String get leaderboardSubtitle => '仅统计真实完成的训练 XP，不再展示静态演示榜单。';

  @override
  String get leaderboardEmptyTitle => '暂无训练成绩';

  @override
  String get leaderboardEmptyBody => '完成抢词、一站到底或单词拼写后，会用真实训练 XP 生成排名。';

  @override
  String get leaderboardOnlyValidXp => '仅统计有效学习 XP';

  @override
  String get analyticsDataTitle => '学习数据';

  @override
  String get analyticsDataSubtitle => '根据生词卡和复习记录生成的首版分析视图。';

  @override
  String analyticsAssetsDue(Object due, Object total) {
    return '$total 个学习资产中有 $due 个到期';
  }

  @override
  String get analyticsCards => '生词卡';

  @override
  String get analyticsTrainingXp => '训练 XP';

  @override
  String get analyticsAccuracy => '正确率';

  @override
  String get onboardingFeatureImageCards => '图像词卡';

  @override
  String get onboardingFeatureImageCardsDesc => '单词、释义、例句串联学习';

  @override
  String get onboardingFeaturePath => '清晰路径';

  @override
  String get onboardingFeaturePathDesc => '短课节引导每日学习路径';

  @override
  String get onboardingFeatureReview => '准时复习';

  @override
  String get onboardingFeatureReviewDesc => '弱项词优先复习，已掌握词间隔拉长';

  @override
  String get onboardingTagPillXp => 'XP';

  @override
  String get onboardingTagPillStreak => '连续打卡';

  @override
  String get onboardingTagPillPlanet => '词境星球';

  @override
  String get onboardingRegisterButton => '注册账号';

  @override
  String get goalSetupTitle => '目标设置';

  @override
  String get goalSetupSelectPlan => '选择学习计划';

  @override
  String get goalSetupSelectPlanSubtitle => '系统自动规划每日新学和复习任务';

  @override
  String get goalSetupTarget => '目标';

  @override
  String get goalSetupDailyGoal => '每日目标';

  @override
  String get goalSetupDeadlinePlan => '按截止日期规划';

  @override
  String get goalSetupDeadlineHint => '选择目标日期后，系统会自动计算每天需要学习的词数。';

  @override
  String get goalSetupPickDate => '选择日期';

  @override
  String get goalSetupChangeDate => '更改日期';

  @override
  String get goalSetupClearDate => '清除日期规划';

  @override
  String get goalSetupEnterApp => '进入 LinguaQuest';

  @override
  String get goalSetupCurrentBook => '当前词书';

  @override
  String get goalSetupLearned => '已学';

  @override
  String get goalSetupNewWords => '新学';

  @override
  String goalSetupNewWordsCount(Object count) {
    return '新学 $count 词';
  }

  @override
  String get goalSetupReviewLimit => '复习上限';

  @override
  String goalSetupReviewLimitCount(Object count) {
    return '复习上限 $count 词';
  }

  @override
  String get goalSetupViewWordbook => '查看完整词汇表';

  @override
  String get homePersonalSpace => '个人空间';

  @override
  String get homeSearchHint => '搜索单词、短语或例句';

  @override
  String get homeNotifications => '消息通知';

  @override
  String get homeLearned => '已学';

  @override
  String get homeMastered => '掌握';

  @override
  String get homeReviewLabel => '复习';

  @override
  String get homeTaskConsole => '今日任务控制台';

  @override
  String get homeAdjustPlan => '调整计划';

  @override
  String get homeResumePlan => '恢复计划以继续学习';

  @override
  String get homeStartLearning => '开始';

  @override
  String get homeReviewOnly => '复习';

  @override
  String get homeStreakLabel => '连续打卡';

  @override
  String homeStreakDays(num count) {
    return '已连续打卡 $count 天';
  }

  @override
  String get homeTodayProgress => '今日';

  @override
  String get homeWordbookShortcut => '单词本';

  @override
  String get homeDailyArticle => '每日短文';

  @override
  String get homeDailyArticleSubtitle => '情景填空';

  @override
  String get homeLearningPath => '学习路径';

  @override
  String get homeLearningPathSubtitle => '正式词书';

  @override
  String get homeWordOfDay => '今日词条';

  @override
  String get homeOpenWordCard => '打开单词卡片';

  @override
  String get homeWeakWords => '弱项词';

  @override
  String get homeNoWeakWords => '当前还没有高频错词。';

  @override
  String get homeWeakWordsReview => '趁它们堆起来前先复习。';

  @override
  String get homeWeakWordsEmptyHint => '完成学习后这里显示重点词';

  @override
  String get homePlanPaused => '计划已暂停';

  @override
  String get homeTodayCompleted => '今天完成';

  @override
  String get profileLearner => '探索者';

  @override
  String get profileNoEmail => '未设置邮箱';

  @override
  String get profileDashboard => '学习仪表盘';

  @override
  String get profileDashboardSubtitle => '学习数据一览';

  @override
  String get profileLearnedWords => '已学单词';

  @override
  String get profileMasteredWords => '已掌握';

  @override
  String get profileCustomWords => '生词本';

  @override
  String get profileAverageAccuracy => '平均正确率';

  @override
  String get profilePlansCompleted => '完成计划';

  @override
  String profileStreakDays(num count) {
    return '连续 $count 天';
  }

  @override
  String get profileCurrentBookProgress => '当前词书进度';

  @override
  String get profileWordbookSubtitle => '当前词书与目标词汇';

  @override
  String get profileCustomWordsSubtitle => '收藏的单词与个人词汇卡片';

  @override
  String get profileMistakeBookSubtitle => '课程错词与弱项词';

  @override
  String get profileReminderSubtitle => '选择提醒时间和开启状态';

  @override
  String get profileDarkModeSubtitle => '跟随系统、浅色或深色主题';

  @override
  String get profileHelpSubtitle => '常见问题和支持入口';

  @override
  String get profileHelpTitle => '帮助与反馈';

  @override
  String get profileAboutSubtitle => 'LinguaQuest 产品愿景与版本 1.0.0';

  @override
  String get profileAboutTitle => '关于我们';

  @override
  String get profileLogout => '退出登录';

  @override
  String get profileSettingsSupport => '设置与支持';

  @override
  String get profilePlanLabel => '学习计划';

  @override
  String get profilePlanRunning => '进行中';

  @override
  String get profilePlanPaused => '已暂停';

  @override
  String get profileWeaknessAnalysis => '弱项分析';

  @override
  String get profileNoWeakness => '暂无弱项，继续学习即可';

  @override
  String get profileMostWrongWord => '最常错词';

  @override
  String get settingsAppBar => '设置';

  @override
  String get settingsSoundFeedback => '答题音效反馈';

  @override
  String get settingsSoundFeedbackSubtitle => '用于提醒答题结果和练习节奏';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeSystemSubtitle => '根据设备浅色或深色偏好自动切换';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeLightSubtitle => '保持明亮清爽的学习界面';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsThemeDarkSubtitle => '使用深色学习界面';

  @override
  String get settingsReminderTitle => '每日提醒';

  @override
  String get settingsReminderTime => '提醒时间';

  @override
  String get settingsReminderOff => '提醒已关闭';

  @override
  String get settingsReminderDisabled => '不会安排本地提醒';

  @override
  String get settingsReminderDescription => '按时提醒你开始每日学习和打卡';

  @override
  String get discoverTitle => '发现';

  @override
  String get discoverSubtitle => '签到、积分任务和社区';

  @override
  String get discoverTaskCenter => '任务中心';

  @override
  String get discoverXpTasks => '积分任务';

  @override
  String get discoverXpTasksSubtitle => '完成任务领取 XP';

  @override
  String get discoverDailyCheckin => '每日签到';

  @override
  String get discoverDailyCheckinCondition => '当天打开并完成一次学习动作';

  @override
  String get discoverNewLearning => '完成新学';

  @override
  String get discoverNewLearningCondition => '完成今日新学任务';

  @override
  String get discoverReviewDone => '完成复习';

  @override
  String get discoverReviewDoneCondition => '完成今日到期复习';

  @override
  String get discoverTrainingChallenge => '训练场挑战';

  @override
  String get discoverTrainingChallengeCondition => '完成任意训练场游戏';

  @override
  String get discoverWeakCleanup => '错词清理';

  @override
  String get discoverWeakCleanupCondition => '今日错词再次答对';

  @override
  String get discoverLuckyDraw => '积分抽奖';

  @override
  String get discoverLuckyDrawSubtitle => '奖品只做虚拟装饰，不影响学习公平性。';

  @override
  String get discoverLuckyDrawItems => '头像框、主页背景、学习徽章、训练场称号、卡片皮肤';

  @override
  String get discoverLuckyDrawCost => '消耗 30 积分抽一次；稀有概率透明展示，未中奖也给碎片。';

  @override
  String get discoverCommunityPosts => '社区帖子';

  @override
  String get discoverCommunityPostsSubtitle => '社区动态';

  @override
  String get discoverMyFavorites => '我的收藏';

  @override
  String get favoritesEmpty => '你还没有收藏任何帖子。';

  @override
  String get communityFilterAll => '全部';

  @override
  String get communityTagGrammar => '语法';

  @override
  String get communityTagVocabulary => '词汇';

  @override
  String get communityTagCulture => '文化';

  @override
  String get communityTagGeneral => '综合';

  @override
  String get communityTagProgress => '学习进展';

  @override
  String get communityShareUpdate => '分享学习进展';

  @override
  String get communityNewPost => '发帖';

  @override
  String get communityNoPostsInFilter => '该分类还没有帖子';

  @override
  String get communityTimeJustNow => '刚刚';

  @override
  String communityTimeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String communityTimeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String communityTimeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String get discoverXpUsage => 'XP 用途';

  @override
  String get discoverXpUsageDesc => '领取后同步到个人主页和排行榜；积分抽奖会消耗当前 XP。当前余额';

  @override
  String discoverGoComplete(Object points) {
    return '去完成 +$points XP';
  }

  @override
  String discoverClaim(Object points) {
    return '领取 +$points XP';
  }

  @override
  String discoverClaimed(Object points) {
    return '已入账 +$points XP';
  }

  @override
  String discoverClaimedMessage(Object points, Object title, Object total) {
    return '$title 已入账 +$points XP，当前总积分 $total XP';
  }

  @override
  String get discoverCannotClaim => '暂时无法领取这个任务';

  @override
  String get discoverViewProfile => '查看主页';

  @override
  String errorStartupFailed(Object detail) {
    return 'LinguaQuest 启动失败：$detail';
  }

  @override
  String get errorPlanPausedNewLearning => '学习计划已暂停，恢复后才能完成新学。';

  @override
  String get errorPlanPausedReview => '学习计划已暂停，恢复后才能复习。';

  @override
  String get errorCardReviewedToday => '这张词卡今天已经完成复习。';

  @override
  String get errorTaskClaimedToday => '这个任务今天已经领取过。';

  @override
  String get errorTargetReviewedToday => '这个目标词今天已经完成复习。';

  @override
  String errorInsufficientXp(Object balance, Object cost) {
    return '当前余额 $balance XP，不足 $cost XP。先完成积分任务再抽奖。';
  }

  @override
  String get aiTutorInstantFeedback => '即时反馈';

  @override
  String get questTaskXp => '任务 XP';

  @override
  String get discoverTasksEmpty => '今天的积分任务暂时没有加载出来。';

  @override
  String get discoverForumCheckinTag => '今日打卡';

  @override
  String get discoverForumMistakeTag => '错题讨论';

  @override
  String get discoverForumPost1Title => '今日打卡：用 12 分钟复习了 18 个词';

  @override
  String get discoverForumPost1Body => '错词集中在近义辨析，明天准备从训练场的易混词挑战开始。';

  @override
  String get discoverForumPost2Title => '怎么记住 abstract 这个词？';

  @override
  String get discoverForumPost2Body => 'abstract 在论文和阅读文章里经常不是“抽象”的意思，要结合语境判断。';

  @override
  String get discoverForumHint => '在下方社区帖子点击“记录互动”，即可完成论坛互动任务。';

  @override
  String get discoverCheckinSuccess => '签到成功，今天的签到积分可以领取了。';

  @override
  String get discoverCheckinFailed => '签到失败，请稍后重试。';

  @override
  String get discoverForumSuccess => '论坛互动已通过，积分任务可领取。';

  @override
  String get discoverForumFailed => '论坛互动记录失败，请稍后重试。';

  @override
  String get discoverCheckinLoadingHint => '任务加载后即可签到。';

  @override
  String discoverCheckinClaimedDesc(int points) {
    return '今天已签到，并已领取 +$points XP。';
  }

  @override
  String discoverCheckinClaimableDesc(int points) {
    return '今天已签到，记得领取 +$points XP。';
  }

  @override
  String get discoverCheckinPrompt => '点击签到后，签到任务会进入可领取状态。';

  @override
  String get discoverCheckingIn => '签到中';

  @override
  String get discoverCheckedIn => '已签到';

  @override
  String get discoverCheckIn => '签到';

  @override
  String get discoverAlreadyClaimed => '已领取';

  @override
  String get discoverClaimCheckin => '领取签到积分';

  @override
  String get discoverLoading => '加载中';

  @override
  String get discoverReloadTasks => '重新加载任务';

  @override
  String get discoverConditionMet => '已完成条件，点击领取奖励。';

  @override
  String get discoverProcessing => '处理中';

  @override
  String get discoverRecordInteraction => '记录互动';

  @override
  String get quizNoLesson => '没有找到这节课';

  @override
  String get quizNoQuestions => '这节课还没有测验。';

  @override
  String get quizTimedTest => '限时测试';

  @override
  String get quizCampusSpeed => '校园速测';

  @override
  String get quizLeaveTitle => '离开测验？';

  @override
  String get quizLeaveContent => '当前测验进度将被放弃。';

  @override
  String get quizKeepAnswering => '继续答题';

  @override
  String get quizInputWord => '输入单词';

  @override
  String get quizCorrect => '答对了。';

  @override
  String get quizWrong => '还不对。';

  @override
  String get quizReinforce => '强化记忆：';

  @override
  String get quizContinue => '继续';

  @override
  String get quizRetry => '再试一次';

  @override
  String get quizCheck => '检查';

  @override
  String get quizResultTitle => '课程结果';

  @override
  String get quizTimedResultTitle => '限时测试结果';

  @override
  String get quizGreatJob => '表现很棒！';

  @override
  String get quizChallengeDone => '挑战完成';

  @override
  String get quizLessonDone => '课程完成';

  @override
  String get quizChallengeSuccess => '挑战成功！';

  @override
  String get quizAccuracy => '正确率';

  @override
  String get quizMistakes => '错题';

  @override
  String get quizNoResult => '还没有课程结果';

  @override
  String get quizAllCorrect => '全对！';

  @override
  String get quizMistakeReview => '错题已进入复习。';

  @override
  String get quizMistakeTimed => '错题可去复习中心整理。';

  @override
  String get quizRetryMistakes => '错词再练';

  @override
  String get quizGoReviewCenter => '去复习中心';

  @override
  String get quizBackTraining => '返回训练场';

  @override
  String get quizBackLearningPath => '返回学习路径';

  @override
  String get quizXpBalanceUpdated => '总积分已更新';

  @override
  String quizCurrentXp(Object xp) {
    return '当前总积分 $xp XP';
  }

  @override
  String quizXpCredited(Object xp) {
    return '刚刚到账 +$xp XP';
  }

  @override
  String quizXpImpactBody(Object balance) {
    return '$balance。XP 会同步到个人主页、排行榜和发现页抽奖余额。';
  }

  @override
  String get quizTimedReward => '限时测试奖励';

  @override
  String get quizLessonReward => '课程奖励';

  @override
  String get quizViewXpUses => '查看 XP 用途';

  @override
  String quizXpEarned(Object xp) {
    return '已入账 +$xp XP';
  }

  @override
  String quizTotalXp(Object xp) {
    return '总积分 $xp XP';
  }

  @override
  String quizMistakeCount(Object count) {
    return '$count 个错题';
  }

  @override
  String get trainingTitle => '训练场';

  @override
  String get trainingSubtitle => '限时测试、专项训练、排行榜';

  @override
  String get trainingPageSubtitle => '限时测试、专项训练和排行榜放在这里。';

  @override
  String get trainingWeeklyXpPrefix => '本周';

  @override
  String get trainingDailyXpAvailable => '今日可得 60 XP';

  @override
  String get trainingLeaderboard => '排行榜';

  @override
  String get trainingTimedTestsSubtitle => '校园词包与抢词挑战';

  @override
  String get trainingCampusSpeed => '校园速测';

  @override
  String get trainingCampusSpeedDesc => '从当前词书抽题，适合课后快速检测，不影响正式复习节奏。';

  @override
  String get trainingSpeedGame => '抢词';

  @override
  String get trainingSpeedGameDesc => '60 秒内尽可能答对英文选义题，按正确数、连击和准确率给积分。';

  @override
  String get trainingSpeedGameSource => '已学词 + 到期词';

  @override
  String get trainingNoWordbook => '暂无词书';

  @override
  String get trainingStartTest => '开始测试';

  @override
  String get trainingComingSoon => '即将开放';

  @override
  String get trainingSpecialDrillsSubtitle => '围绕拼写、听音、搭配和短文挖词补弱项。';

  @override
  String get trainingSurvivor => '一站到底';

  @override
  String get trainingSurvivorDesc => '从简单到困难连续答题，错词会进入弱项词和错词本。';

  @override
  String get trainingSurvivorSource => '当前词书 + 弱项词';

  @override
  String get trainingSpelling => '单词拼写';

  @override
  String get trainingSpellingDesc => '看中文、听发音或看例句空格后输入英文，强化可产出能力。';

  @override
  String get trainingSpellingSource => '拼写弱项词';

  @override
  String get trainingPassageCloze => '文章挖词';

  @override
  String get trainingPassageClozeDesc => '用今日词汇生成短文并挖空，连接背词和阅读理解。';

  @override
  String get trainingPassageClozeSource => '今日学习词 + AI 短文';

  @override
  String get trainingListening => '听音速答';

  @override
  String get trainingListeningDesc => '播放发音后选择单词或释义，反应时间影响得分。';

  @override
  String get trainingListeningSource => '听力弱项词';

  @override
  String get trainingDueWords => '复习';

  @override
  String get trainingWeakWords => '弱项';

  @override
  String get trainingComboTarget => '连击';

  @override
  String get trainingEnterCustomWords => '进入生词本';

  @override
  String get trainingEntryMissingTitle => '训练入口不存在';

  @override
  String get trainingEntryMissingHeader => '没有找到这个训练';

  @override
  String get trainingEntryMissingSubtitle => '请回到训练场，从抢词、一站到底或单词拼写入口开始。';

  @override
  String get trainingSourceInsufficientTitle => '训练题源不足';

  @override
  String get trainingSourceInsufficientSubtitle =>
      '先完成一节新学、添加生词，或在错词本里积累弱项词后再来挑战。';

  @override
  String get trainingBack => '返回训练场';

  @override
  String get trainingMistakesOnly => '错词再练';

  @override
  String get trainingNextQuestion => '下一题';

  @override
  String get trainingSubmitSpelling => '提交拼写';

  @override
  String get trainingExitTitle => '离开训练？';

  @override
  String get trainingExitContent => '当前训练进度不会结算。';

  @override
  String get trainingContinue => '继续训练';

  @override
  String get trainingExit => '离开';

  @override
  String trainingPromptWordRush(Object word) {
    return '抢答“$word”的中文释义';
  }

  @override
  String trainingExplanationWordRush(
    Object example,
    Object meaning,
    Object word,
  ) {
    return '“$word”表示$meaning。$example';
  }

  @override
  String trainingPromptChineseChoice(Object meaning) {
    return '根据中文释义选择英文：$meaning';
  }

  @override
  String trainingExplanationChineseChoice(Object meaning, Object word) {
    return '$meaning 对应 “$word”。';
  }

  @override
  String trainingPromptContextChoice(Object example) {
    return '结合例句选择释义：$example';
  }

  @override
  String trainingPromptMeaningChoice(Object word) {
    return '选择“$word”的中文释义';
  }

  @override
  String trainingExplanationMeaningChoice(Object meaning, Object word) {
    return '这题考察 $word：$meaning。';
  }

  @override
  String trainingPromptChineseSpelling(Object meaning) {
    return '看中文拼写英文：$meaning';
  }

  @override
  String trainingPromptAudioSpelling(Object cue) {
    return '听音后拼写英文：$cue';
  }

  @override
  String trainingPromptContextSpelling(Object example) {
    return '根据例句空格拼写：$example';
  }

  @override
  String trainingExplanationSpelling(Object example, Object word) {
    return '正确拼写是 “$word”。$example';
  }

  @override
  String get trainingNoEffectiveAnswers => '本轮还没有有效答题，不计入训练记录。';

  @override
  String trainingResultMistakesSuffix(Object title) {
    return '$title · 错词再练';
  }

  @override
  String trainingCorrectAttempts(Object attempts, Object correct) {
    return '正确 $correct/$attempts';
  }

  @override
  String trainingStreak(Object streak) {
    return '连击 $streak';
  }

  @override
  String trainingAccuracyValue(Object accuracy) {
    return '准确率 $accuracy%';
  }

  @override
  String trainingSurvivalResources(Object nodes, Object revives) {
    return '复活 $revives · 节点 $nodes';
  }

  @override
  String trainingBestStreak(Object streak) {
    return '最佳 $streak';
  }

  @override
  String get trainingRealSource => '真实题源';

  @override
  String get trainingSpellingInputLabel => '输入英文拼写';

  @override
  String get trainingReviveConsumed => '已消耗一次复活机会，继续闯关。';

  @override
  String get trainingReviveExhausted => '复活机会已用完，本轮结束。';

  @override
  String get trainingCorrectFeedback => '回答正确，连击继续！';

  @override
  String get trainingPromptListening => '听音频，选择你听到的词';

  @override
  String get learningPathTitle => '学习路径';

  @override
  String get learningPathBackToHome => '回到首页';

  @override
  String get learningPathBookPath => '词书路径';

  @override
  String get learningPathPathSuffix => '路径';

  @override
  String get learningPathPausedHint => '学习计划已暂停，路径进度会保留。';

  @override
  String get learningPathDescription => '这里只展示词书进度；正式新学和复习回到首页的两个独立入口。';

  @override
  String get learningPathPlanLabel => '学习计划';

  @override
  String get learningPathStartLearning => '开始学习';

  @override
  String get learningPathSubtitle => '词书学习进度';

  @override
  String get learningPathOpenWordbook => '打开单词本和生词本';

  @override
  String get learningPathAdjustPlan => '调整当前学习计划';

  @override
  String get learningPathLessonLocked => '未解锁';

  @override
  String get learningPathLessonCurrent => '进行中';

  @override
  String get learningPathLessonCompleted => '已完成';

  @override
  String get learningPathLessonPreview => '预览';

  @override
  String get learningPathLessonQuiz => '测验';

  @override
  String get lessonPreviewTitle => '新学词卡';

  @override
  String get lessonPreviewNoLesson => '没有找到这节课';

  @override
  String get lessonPreviewPrevious => '上一张';

  @override
  String get lessonPreviewNext => '下一张';

  @override
  String get lessonPreviewStartQuiz => '进入测验';

  @override
  String get lessonPreviewConfidence => '你对这个单词熟悉吗？';

  @override
  String get lessonPreviewNotYet => '不熟悉';

  @override
  String get lessonPreviewVaguely => '有点印象';

  @override
  String get lessonPreviewGotIt => '已掌握';

  @override
  String get lessonPreviewLeaveTitle => '离开预览？';

  @override
  String get lessonPreviewLeaveContent => '当前预览进度将被放弃。';

  @override
  String get lessonPreviewBuildUnderstanding => '先建立理解，再做语境题';

  @override
  String lessonPreviewProgressMeta(
    Object current,
    Object minutes,
    Object section,
    Object total,
  ) {
    return '$section · $minutes 分钟 · 第 $current/$total 张';
  }

  @override
  String get lessonPreviewLessonCards => '本课词卡';

  @override
  String lessonPreviewCardMeta(Object count, Object xp) {
    return '$xp XP · $count 道语境题';
  }

  @override
  String get lessonPreviewEnterContext => '进入语境练习';

  @override
  String get lessonPreviewNextCard => '下一张词卡';

  @override
  String get lessonPreviewNoCards => '暂无词卡';

  @override
  String get lessonPreviewNoCardsBody => '这节课还没有可学习的词。';

  @override
  String get lessonPreviewLeaveCardTitle => '离开词卡？';

  @override
  String get lessonPreviewLeaveCardContent => '当前新学词卡进度将被放弃。';

  @override
  String get lessonPreviewLeave => '离开';

  @override
  String get lessonPreviewAssessFirst => '先判断熟悉度';

  @override
  String get lessonPreviewContextExample => '语境例句';

  @override
  String get reviewCenterTitle => '复习';

  @override
  String reviewCenterCardsDuePrefix(Object count) {
    return '$count 张卡片待复习';
  }

  @override
  String get reviewCenterDailyCapPrefix => '今日复习上限 ';

  @override
  String get reviewCenterDailyCapMiddle => ' 词，另有 ';

  @override
  String get reviewCenterDailyCapSuffix => ' 词会排到后续。';

  @override
  String get reviewCenterCurrentBook => '当前词书';

  @override
  String get reviewCenterAutoQueueHint => '答错词会自动进入复习队列。';

  @override
  String get reviewCenterEmptyTitle => '复习队列已清空';

  @override
  String get reviewCenterEmptyMessage => '添加生词本词卡，或把错题加入错词本后，这里会生成复习队列。';

  @override
  String get reviewCenterAddCustomWord => '添加生词';

  @override
  String get reviewCenterNoMistakes => '还没有弱项词或课程错题。';

  @override
  String get reviewCenterOpenMistakeBook => '打开错词本';

  @override
  String get reviewCenterLimitPrefix => '已按学习计划限制今日复习 ';

  @override
  String get reviewCenterLimitMiddle => ' 词；剩余 ';

  @override
  String get reviewCenterLimitSuffix => ' 词不会丢失，会继续留在复习队列。';

  @override
  String get reviewCenterTargetWord => '目标词';

  @override
  String get reviewCenterCustomCard => '生词卡';

  @override
  String get reviewCenterForgot => '没记住';

  @override
  String get reviewCenterRemembered => '记住了';

  @override
  String get wordDetailNotFound => '没有找到这个词';

  @override
  String get wordDetailReviewStats => '复习统计';

  @override
  String get wordDetailMarkRemembered => '标记为记住';

  @override
  String get wordDetailScheduleSoon => '安排近期再练';

  @override
  String get wordDetailMarkedRemembered => '已标记为记住';

  @override
  String get wordDetailScheduledSoon => '已安排近期再练';

  @override
  String get wordDetailStatRemembered => '记住';

  @override
  String get wordDetailStatForgot => '没记住';

  @override
  String get wordDetailStatMastery => '掌握度';

  @override
  String get wordDetailUpdateFailed => '暂时无法更新这张卡片';

  @override
  String wordDetailMasteryLabel(Object level) {
    return '掌握 $level/5';
  }

  @override
  String wordDetailNextReview(Object when) {
    return '下次 $when';
  }

  @override
  String get reviewCenterPostponedMessage => '已标记为记住，下次复习会延后';

  @override
  String get reviewCenterCloserReviewMessage => '已加入更近的复习计划';

  @override
  String get reviewCenterUpdateFailed => '暂时无法更新这张卡片';

  @override
  String get reviewCenterAddMistakeCards => '加入错词卡';

  @override
  String get reviewCenterAllMistakesAdded => '最近错题已经全部在生词本里。';

  @override
  String get reviewCenterSelectMistakesHint => '选择错词后，可以直接加入复习卡片。';

  @override
  String get reviewCenterAddSelected => '加入已选';

  @override
  String get reviewCenterMistakeCardsSuffix => '张错词卡';

  @override
  String get reviewCenterPlanPaused => '学习计划已暂停';

  @override
  String get reviewCenterTodayDone => '今日复习已清空';

  @override
  String reviewCenterCardsDue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 张卡片待复习',
      one: '1 张卡片待复习',
      zero: '暂无待复习卡片',
    );
    return '$_temp0';
  }

  @override
  String get reviewCenterPlanPausedHint => '恢复学习计划后，复习队列会按每日上限继续开放。';

  @override
  String reviewCenterDailyCap(Object hidden, Object limit) {
    return '今日复习上限 $limit 词，另有 $hidden 词会排到后续。';
  }

  @override
  String get reviewCenterTodayDue => '今日到期';

  @override
  String get reviewCenterReviewQueue => '复习队列';

  @override
  String get reviewCenterStartReview => '开始复习';

  @override
  String get reviewCenterEmpty => '今日复习已完成！';

  @override
  String get mistakeBookTitle => '错词本';

  @override
  String get mistakeBookNoMistakes => '暂时没有课程错题';

  @override
  String mistakeBookMistakes(Object count) {
    return '$count 个课程错题';
  }

  @override
  String mistakeBookMistakesPrefix(Object count) {
    return '$count 个课程错题';
  }

  @override
  String get mistakeBookSubtitle => '测验错题和弱项自定义卡会保留在这里，方便后续复习。';

  @override
  String get mistakeBookFixLabel => '错题修复';

  @override
  String get mistakeBookGoPractice => '去练一课';

  @override
  String get mistakeBookCleared => '错词本已清空';

  @override
  String get mistakeBookClearedMsg => '测验答错，或把生词本词卡标记为没记住后，这里会出现复习项。';

  @override
  String get mistakeBookLessonMistakes => '课程错题';

  @override
  String get mistakeBookStartLesson => '开始一课';

  @override
  String get mistakeBookWeakWords => '弱项生词';

  @override
  String get mistakeBookNoLessonMistakes => '最近一课没有答错的题。';

  @override
  String get mistakeBookNoWeakWords => '还没有弱项生词。';

  @override
  String get labelTargetCET4 => '四级核心词汇';

  @override
  String get labelTargetCET6 => '六级核心词汇';

  @override
  String get labelTargetKaoyan => '考研英语核心词汇';

  @override
  String get labelTargetBeginner => '入门基础词汇';

  @override
  String get labelTargetMUET => 'MUET 高频词汇';

  @override
  String get labelTargetDailyEnglish => '日常英语';

  @override
  String get labelTargetBusinessEnglish => '商务英语';

  @override
  String get labelLevelBeginner => '入门';

  @override
  String get labelLevelElementary => '基础';

  @override
  String get labelLevelIntermediate => '中级';

  @override
  String get labelLevelAdvanced => '高级';

  @override
  String get labelDifficultyEasy => '简单';

  @override
  String get labelDifficultyMedium => '中等';

  @override
  String get labelDifficultyHard => '困难';

  @override
  String get labelStatusNew => '未学习';

  @override
  String get labelStatusPreviewed => '已预览';

  @override
  String get labelStatusLearning => '学习中';

  @override
  String get labelStatusReview => '复习中';

  @override
  String get labelStatusRelearning => '需巩固';

  @override
  String get labelStatusMastered => '已掌握';

  @override
  String get labelStatusIgnored => '已忽略';

  @override
  String get labelQuestionTypeMeaningChoice => '英文选义';

  @override
  String get labelQuestionTypeChineseChoice => '中文选词';

  @override
  String get labelQuestionTypeContextChoice => '语境选义';

  @override
  String get labelQuestionTypeImageChoice => '图片选词';

  @override
  String get labelQuestionTypeListeningWordChoice => '听音选词';

  @override
  String get labelQuestionTypeListeningMeaningChoice => '听音选义';

  @override
  String get labelQuestionTypeSpelling => '拼写';

  @override
  String get labelCustomTagCustom => '自定义';

  @override
  String get labelCustomTagMistake => '错题';

  @override
  String get labelCustomTagCharacter => '品格';

  @override
  String get labelWordTagAcademic => '学术';

  @override
  String get labelWordTagBeginner => '入门';

  @override
  String get labelWordTagBusiness => '商务';

  @override
  String get labelWordTagCampus => '校园';

  @override
  String get labelWordTagDaily => '日常';

  @override
  String get labelWordTagExam => '考试';

  @override
  String get labelWordTagCET4 => '四级';

  @override
  String get labelWordTagCET6 => '六级';

  @override
  String get labelWordTagKaoyan => '考研';

  @override
  String get labelWordTagFood => '饮食';

  @override
  String get labelWordTagHealth => '健康';

  @override
  String get labelWordTagStudy => '学习';

  @override
  String get labelWordTagTravel => '旅行';

  @override
  String get labelWordTagWriting => '写作';

  @override
  String get labelWordTagDefault => '目标词';

  @override
  String get wordbookTitle => '单词本';

  @override
  String get wordbookSearchHint => '搜索单词...';

  @override
  String get wordbookNoResults => '没有匹配的单词。';

  @override
  String get wordbookAllDifficulty => '全部';

  @override
  String get wordbookWeakDifficulty => '弱项';

  @override
  String get wordbookCustomWords => '自定义单词';

  @override
  String get wordbookAddCustom => '添加生词';

  @override
  String get wordbookEditCustom => '编辑生词';

  @override
  String get wordbookWordDetail => '单词详情';

  @override
  String get wordbookMeaning => '释义';

  @override
  String get wordbookExample => '例句';

  @override
  String get wordbookPartOfSpeech => '词性';

  @override
  String get wordbookDifficulty => '难度';

  @override
  String get wordbookMastery => '掌握度';

  @override
  String get wordbookDeleteConfirm => '删除这个词？';

  @override
  String get wordbookDeleteMessage => '此操作不可撤销。';

  @override
  String get wordbookImageBook => '图片单词本';

  @override
  String get wordbookCustomTooltip => '生词本';

  @override
  String wordbookWordsLearned(Object completed, Object total) {
    return '已学 $completed/$total 词';
  }

  @override
  String wordbookTargetWords(Object count) {
    return '$count 个目标词';
  }

  @override
  String wordbookTotalWords(Object count) {
    return '共 $count 词';
  }

  @override
  String wordbookBookCount(Object count) {
    return '$count 本词书';
  }

  @override
  String wordbookCompletion(Object percent) {
    return '完成 $percent%';
  }

  @override
  String get wordbookSwitch => '切换词书';

  @override
  String get wordbookSwitchDesc => '当前词书会驱动首页、学习路径、搜索、训练场和复习入口。';

  @override
  String get wordbookSwitched => '已切换当前词书';

  @override
  String get wordbookSwitchFailed => '暂时无法切换词书';

  @override
  String get pickerChooseLanguage => '选择语言';

  @override
  String get pickerChooseWordbook => '选择词书';

  @override
  String get pickerLanguageChinese => '中文';

  @override
  String get pickerLanguageJapanese => '日语';

  @override
  String get pickerComingSoon => '即将上线';

  @override
  String get pickerCurrentBadge => '当前';

  @override
  String pickerSwitchSuccess(String wordbook) {
    return '已切换到$wordbook';
  }

  @override
  String get pickerSwitchFailed => '暂时无法切换词书';

  @override
  String get wordbookTargetSection => '目标词';

  @override
  String wordbookTargetDesc(Object count, Object percent) {
    return '$count 词 · 学习路径完成 $percent%';
  }

  @override
  String get wordbookNameBeginner => '入门基础词汇';

  @override
  String get wordbookDescBeginner => '适合初级英语和日常表达入门的基础高频词。';

  @override
  String get wordbookNameCET4 => '四级核心词汇';

  @override
  String get wordbookDescCET4 => '大学英语四级核心词汇。';

  @override
  String get wordbookNameCET6 => '六级核心词汇';

  @override
  String get wordbookDescCET6 => '大学英语六级核心词汇。';

  @override
  String get wordbookNameKaoyan => '考研核心词汇';

  @override
  String get wordbookDescKaoyan => '考研英语核心词汇。';

  @override
  String get notificationTitle => '消息通知';

  @override
  String get notificationMarkAllRead => '全部已读';

  @override
  String get notificationCenter => '消息中心';

  @override
  String get notificationCenterDesc => '学习提醒、复习到期、打卡和活动消息都会集中在这里。';

  @override
  String notificationUnreadCount(Object count) {
    return '$count 条未读消息';
  }

  @override
  String get notificationFilterAll => '全部';

  @override
  String get notificationFilterUnread => '未读';

  @override
  String get notificationFilterLearning => '学习';

  @override
  String get notificationFilterActivity => '活动';

  @override
  String get notificationEmptyTitle => '没有符合条件的消息';

  @override
  String get notificationEmptyUnread => '当前没有未读消息。';

  @override
  String get notificationEmptyAll => '完成学习和复习后，这里会继续沉淀学习提醒和活动消息。';

  @override
  String get notificationBackHome => '回到首页';

  @override
  String get notificationTypeLearningReminder => '学习提醒';

  @override
  String get notificationTypeReviewDue => '复习到期';

  @override
  String get notificationTypeCheckIn => '打卡提醒';

  @override
  String get notificationTypeActivity => '活动消息';

  @override
  String get notificationLearningReminderTitle => '今日学习计划待完成';

  @override
  String notificationLearningReminderBody(int dailyGoal) {
    return '今天目标新学 $dailyGoal 词，先从当前词书开始。';
  }

  @override
  String notificationReviewDueTitle(int dueCount) {
    return '$dueCount 个词到期复习';
  }

  @override
  String get notificationReviewDueBody => '先清理复习队列，答错词会自动进入强化阶段。';

  @override
  String get notificationCheckInTitle => '今天还没有打卡';

  @override
  String get notificationCheckInBody => '去发现页点击签到，签到任务会进入可领取状态。';

  @override
  String get notificationActivityTitle => '发现页积分任务已刷新';

  @override
  String get notificationActivityBody => '完成新学、复习和错词清理后可领取 XP。';

  @override
  String get notificationLotteryTitle => '积分抽奖结果';

  @override
  String notificationLotteryBody(String prizeName) {
    return '获得「$prizeName」，已放入个人资产。';
  }

  @override
  String get osNotificationStudyReminderTitle => '今天的学习任务等你开始';

  @override
  String get osNotificationStudyReminderBody => '完成新学、复习和打卡，保持你的连续学习节奏。';

  @override
  String get osNotificationReviewDueBody => '先清掉复习队列，再开始今天的新词。';

  @override
  String get osNotificationChannelName => '学习提醒';

  @override
  String get osNotificationChannelDescription => '学习提醒、复习到期和打卡提醒';

  @override
  String get studyNewStudy => '新学';

  @override
  String get studyReviewOnly => '复习';

  @override
  String get studyStartSession => '开始学习';

  @override
  String get studySessionComplete => '学习完成';

  @override
  String studyWordsLeft(Object count) {
    return '还剩 $count 词';
  }

  @override
  String get studyPlanLoginRequired => '请先登录后再设置学习计划。';

  @override
  String get studyPlanSave => '保存学习计划';

  @override
  String get studyPlanSettings => '学习计划设置';

  @override
  String get studyPlanSettingsDesc => '管理当前词书、每日任务、复习节奏和提醒时间。';

  @override
  String get studyPlanViewWords => '查看完整词汇表';

  @override
  String get studyPlanDailyNew => '每日新学词数';

  @override
  String get studyPlanDailyNewHint => '建议 5-30 词，最多 200 词。';

  @override
  String get studyPlanReminderTime => '学习提醒时间';

  @override
  String get studyPlanResume => '恢复计划';

  @override
  String get studyPlanPause => '暂停计划';

  @override
  String get studyPlanReset => '重置计划';

  @override
  String get studyPlanResetConfirm => '确认重置学习计划？';

  @override
  String get studyPlanResetDesc =>
      '重置后会清空当前词书的学习路径进度，并把生词本掌握度、正确/错误次数和复习时间重置；复习队列会重新生成。这个操作会影响学习进度和复习安排。';

  @override
  String get studyPlanCancel => '取消';

  @override
  String get studyPlanConfirm => '确认重置';

  @override
  String get studyPlanSaved => '学习计划已保存。';

  @override
  String get studyPlanSaveFailed => '暂时无法保存计划。';

  @override
  String get studyPlanResumed => '学习计划已恢复。';

  @override
  String get studyPlanPaused => '学习计划已暂停，今日提醒和任务入口会暂时关闭。';

  @override
  String get studyPlanPauseFailed => '暂时无法更新计划状态。';

  @override
  String get studyPlanResetDone => '学习计划已重置。';

  @override
  String get studyPlanResetFailed => '暂时无法重置计划。';

  @override
  String get studyPlanEnterNumber => '请输入数字';

  @override
  String studyPlanNumberRange(Object max, Object min) {
    return '范围必须是 $min-$max';
  }

  @override
  String studyPlanDaysLeft(Object count) {
    return '剩余 $count 天';
  }

  @override
  String get studyPlanActive => '进行中';

  @override
  String get studyPlanPausedLabel => '已暂停';

  @override
  String get aiLearningTitle => 'AI 学习';

  @override
  String get aiLearningSubtitle => '阅读、写作和练习';

  @override
  String get aiLearningComingSoon => 'AI 学习功能即将上线。';

  @override
  String get aiLearningDesc => '解释语法、辨析词义、生成语境；正式学习记录仍由答题结果更新。';

  @override
  String get aiLearningTooltip => '知识问答';

  @override
  String get aiLearningPillError => '错因讲解';

  @override
  String get aiLearningPillNoKey => '无需客户端密钥';

  @override
  String get aiLearningCurrentWord => '当前词';

  @override
  String get aiLearningToolsTitle => '工具列表';

  @override
  String get aiLearningToolsSubtitle => '首版优先落地长难句分析和知识问答，作文批改后置。';

  @override
  String get aiLearningToolAiQA => 'AI 知识问答';

  @override
  String get aiLearningToolAiQADesc => '结合当前单词、例句和学习目标回答词义、语法和表达自然度问题。';

  @override
  String get aiLearningToolAiAnalysis => 'AI 长难句分析';

  @override
  String get aiLearningToolAiAnalysisDesc => '提取主干、划分从句、解释修饰成分和关键词，并给出自然中文翻译。';

  @override
  String get aiLearningToolAiWriting => 'AI 作文批改';

  @override
  String get aiLearningToolAiWritingDesc => '选择考试类型、输入题目和正文，输出总评分、分项评分和逐段修改建议。';

  @override
  String get aiLearningToolCloze => '今日单词情景填空';

  @override
  String get aiLearningToolClozeDesc => '基于今日新词、错词或本周弱词生成短文，挖空 5 到 10 个目标词。';

  @override
  String get aiLearningToolConfusion => '易混词辨析';

  @override
  String get aiLearningToolConfusionDesc =>
      '根据错题混淆记录，解释 affect/effect 这类近义或易混词的使用场景。';

  @override
  String get aiLearningToolSentence => '例句生成与改写';

  @override
  String get aiLearningToolSentenceDesc => '按考试目标生成更自然的例句，并支持一键加入笔记或生词本。';

  @override
  String get aiLearningStatusSoon => '暂未开放';

  @override
  String get aiLearningStatusLater => '待开放';

  @override
  String get aiLearningStatusPlanning => '规划中';

  @override
  String get questTitle => '任务';

  @override
  String get questDailyQuests => '每日任务';

  @override
  String get questProgress => '进度';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchHint => '搜索单词、短语、例句...';

  @override
  String get searchNoResults => '没有找到结果。';

  @override
  String get searchRecent => '最近搜索';

  @override
  String get searchStartTitle => '输入关键词开始搜索';

  @override
  String get searchStartMessage => '可以搜索英文单词、词组、中文释义、例句片段和生词本。';

  @override
  String get searchNoResultsTitle => '没有找到结果';

  @override
  String get searchNoResultsMessage => '切到全词库再试，或添加一张个人词卡。';

  @override
  String get searchFieldLabel => '搜索单词、短语、中文释义或例句片段';

  @override
  String searchScopeSummary(Object allWordBooksLabel, Object currentBookTitle) {
    return '搜索范围：$currentBookTitle / $allWordBooksLabel';
  }

  @override
  String get searchCurrentWordbookScope => '当前词书';

  @override
  String get searchAllWordbooksScope => '全词库';

  @override
  String get searchCurrentPlan => '当前计划';

  @override
  String get customWordsMyCards => '我的词卡';

  @override
  String get customWordsMyCardsSubtitle => '创建、搜索、筛选、编辑并复习你的个人词库。';

  @override
  String customWordsCardCount(Object count) {
    return '$count 张';
  }

  @override
  String get customWordsSearchLabel => '搜索单词、释义或标签';

  @override
  String get customWordsNoMatchTitle => '没有匹配的词卡';

  @override
  String get customWordsNoMatchMessage => '可以添加一张个人词卡，或调整搜索条件。';

  @override
  String get customWordsAddCard => '添加生词本词卡';

  @override
  String customWordsDeleteTitle(Object word) {
    return '删除“$word”？';
  }

  @override
  String get customWordsDeleteContent => '这会同时删除这张个人词卡和它的复习计划。';

  @override
  String get customWordsEditTitle => '编辑单词';

  @override
  String get customWordsAddTitle => '添加单词';

  @override
  String get customWordsFieldWord => '单词';

  @override
  String get customWordsFieldMeaning => '释义';

  @override
  String get customWordsFieldExample => '例句';

  @override
  String get customWordsFieldNote => '笔记';

  @override
  String get customWordsFieldTag => '标签';

  @override
  String get customWordsSaveEdit => '保存修改';

  @override
  String get customWordsCreate => '创建单词';

  @override
  String get customWordsSaveFailed => '暂时无法保存这个单词';

  @override
  String get customWordsSaved => '单词已保存';

  @override
  String get customWordsDifficulty => '难度';

  @override
  String get commonRequired => '必填';

  @override
  String customWordsDeleteFailed(Object word) {
    return '暂时无法删除 $word';
  }

  @override
  String customWordsDeleted(Object word) {
    return '已删除 $word';
  }

  @override
  String get wordbookWordNotFound => '没有找到这个词';

  @override
  String get wordbookFavorite => '收藏';

  @override
  String get wordbookFavorited => '已收藏';

  @override
  String get wordbookFavoriteRemoved => '已取消收藏';

  @override
  String get wordbookAddToCustomWords => '加入生词本';

  @override
  String get wordbookRemoveCustomWord => '移出生词本';

  @override
  String get wordbookAddedToCustomWords => '已加入生词本';

  @override
  String get wordbookRemovedFromCustomWords => '已移出生词本';

  @override
  String get wordbookResumeLearning => '恢复学习';

  @override
  String get wordbookIgnoreEasy => '忽略太简单';

  @override
  String get wordbookLearningResumed => '已恢复学习';

  @override
  String get wordbookIgnored => '已忽略，后续不进入复习队列';

  @override
  String get wordbookUpdateTargetFailed => '暂时无法更新目标词';

  @override
  String get wordbookCurrentPlan => '当前计划中';

  @override
  String get wordbookHighFrequencyDefinition => '考试高频释义';

  @override
  String wordbookUkPhonetic(Object phonetic) {
    return '英 /$phonetic/';
  }

  @override
  String wordbookUsPhonetic(Object phonetic) {
    return '美 /$phonetic/';
  }

  @override
  String get wordbookBilingualDefinitions => '中英释义';

  @override
  String get wordbookChineseDefinitions => '中文释义';

  @override
  String get wordbookEnglishDefinitions => '英文释义';

  @override
  String get wordbookMalayDefinitions => '马来语释义';

  @override
  String get wordbookHighFrequency => '高频';

  @override
  String get wordbookContextExamples => '语境例句';

  @override
  String wordbookMasteryLevel(Object level) {
    return '掌握 $level/5';
  }

  @override
  String get reviewStudyManageQueue => '管理复习队列';

  @override
  String get reviewStudyTodayTitle => '今日复习';

  @override
  String get reviewStudyTodaySubtitle => '先回想，再翻开答案；答错会回到本轮稍后巩固。';

  @override
  String get reviewStudyLeaveTitle => '离开复习？';

  @override
  String get reviewStudyLeaveContent => '已完成的词卡已经保存；未完成的词仍会保留在复习队列。';

  @override
  String get reviewStudyKeepReviewing => '继续复习';

  @override
  String get reviewStudyReinforced => '已完成本轮巩固';

  @override
  String get reviewStudyRememberedMessage => '已记住，复习间隔已延后';

  @override
  String get reviewStudyNeedsReinforcementMessage => '已标记为需巩固，稍后再练';

  @override
  String get reviewStudyReinforce => '加入巩固队列';

  @override
  String get reviewStudyCompleteTitle => '今日复习完成';

  @override
  String get reviewStudyCompleteMessage => '已更新本轮词卡的下次复习时间。';

  @override
  String get reviewStudyRecallHint => '看英文先回想中文释义。记得就直接进入下一张，忘了再展开知识卡。';

  @override
  String reviewStudyNextReview(Object due) {
    return '下次复习：$due';
  }

  @override
  String get reviewStudyHiddenHint => '答对不打断；答错才展示知识卡，并在本轮稍后再出现。';

  @override
  String aiWordSupportDesc(Object word) {
    return '围绕 $word 提问用法、语法、近义词区别和例句拆解。';
  }

  @override
  String aiWordSupportWithExampleDesc(Object word) {
    return '携带 $word 和当前例句，提问用法、语法、近义词区别和例句拆解。';
  }

  @override
  String get helpFaqReviewScheduleQ => '复习时间如何安排？';

  @override
  String get helpFaqReviewScheduleA => '每个词会在 0-5 的掌握度之间变化，掌握度越高，下次复习间隔越长。';

  @override
  String get helpFaqCustomWordsQ => '可以添加自己的单词吗？';

  @override
  String get helpFaqCustomWordsA => '可以。进入单词本或生词本，点击添加即可创建个人词卡。';

  @override
  String get helpFaqAiTutorQ => 'AI 助教可以做什么？';

  @override
  String get helpFaqAiTutorA => '可以解释单词、语法和错题，并给出适合继续练习的例句。';

  @override
  String get helpContactSupport => '联系支持';

  @override
  String get aboutVersion => '词境星球 · 版本 1.0.0';

  @override
  String get aboutIntro =>
      'LinguaQuest 将图像词卡、学习路径、间隔复习、XP、连续打卡和个人生词卡整合到一个移动优先的英语学习应用中。';

  @override
  String get aboutGoalTitle => '项目目标';

  @override
  String get aboutGoalSubtitle => '通过短课节、错题修复和可见进度，帮助学习者建立每日英语学习习惯。';

  @override
  String get aboutTeamTitle => '开发团队';

  @override
  String get aboutTeamSubtitle => 'ASM2 Mobile 团队。专注移动优先的英语学习体验。';

  @override
  String get aboutCoreTitle => '核心体验';

  @override
  String get aboutCoreSubtitle => '目标规划、视觉词汇、测验练习、复习排程和个人词卡。';

  @override
  String get aboutPrivacyTitle => '隐私';

  @override
  String get aboutPrivacySubtitle => '生词本和学习记录仅归属于当前登录用户。';

  @override
  String get communityPostCheckinTitle => '今日打卡：用 12 分钟复习了 18 个词';

  @override
  String get communityPostCheckinTag => '今日打卡';

  @override
  String get communityPostCheckinBody => '错词集中在近义辨析，明天准备从训练场的易混词挑战开始。';

  @override
  String get communityPostAbstractTitle => '怎么记住 abstract 这个词？';

  @override
  String get communityPostMistakeTag => '错题讨论';

  @override
  String get communityPostAbstractBody =>
      'abstract 在论文和阅读文章里经常不是“抽象”的意思，要结合语境判断。';

  @override
  String get notificationsTitle => '消息通知';

  @override
  String get notificationsEmpty => '暂无通知。';

  @override
  String get languageSetting => '语言';

  @override
  String luckyDrawCostLine(Object cost) {
    return '消耗 $cost XP 抽一次';
  }

  @override
  String luckyDrawBalanceHint(Object xp) {
    return '当前余额 $xp XP；奖品包含头像框、主页背景、徽章、称号、卡片皮肤和安慰碎片。';
  }

  @override
  String luckyDrawInventoryCount(num count) {
    return '库存 $count 件';
  }

  @override
  String get luckyDrawNoBoost => '无学习加成';

  @override
  String get luckyDrawNow => '立即抽奖';

  @override
  String get luckyDrawInsufficient => '余额不足，先完成任务';

  @override
  String luckyDrawShortfall(Object shortfall) {
    return '还差 $shortfall XP。完成新学、复习或错词清理即可领取积分。';
  }

  @override
  String get luckyDrawFailed => '抽奖失败，请稍后重试';

  @override
  String get luckyDrawSuccessTitle => '抽奖成功';

  @override
  String luckyDrawReward(Object name) {
    return '获得：$name';
  }

  @override
  String luckyDrawDeducted(Object balance, Object cost) {
    return '已扣除 $cost XP，剩余 $balance XP。';
  }

  @override
  String get luckyDrawKeepLooking => '继续看看';

  @override
  String get luckyDrawViewAssets => '查看个人资产';

  @override
  String get luckyDrawPoolLoading => '奖池加载中：头像框、主页背景、学习徽章、训练场称号、卡片皮肤、安慰碎片。';

  @override
  String get profileAssetsTitle => '个人资产';

  @override
  String get profileAssetsSubtitle => '抽奖获得的装饰资产只用于展示，不影响学习分数。';

  @override
  String get profileAssetsEmpty => '暂无资产';

  @override
  String profileAssetMeta(Object category, Object fragments, Object quantity) {
    return '$category · 数量 $quantity · 碎片值 $fragments';
  }

  @override
  String get lotteryCategoryAvatarFrame => '头像框';

  @override
  String get lotteryCategoryProfileBackground => '主页背景';

  @override
  String get lotteryCategoryBadge => '学习徽章';

  @override
  String get lotteryCategoryTitle => '训练称号';

  @override
  String get lotteryCategoryCardSkin => '卡片皮肤';

  @override
  String get lotteryCategoryFragment => '安慰碎片';

  @override
  String get lotteryCategoryDefault => '装饰资产';

  @override
  String get lotteryRarityRare => '稀有';

  @override
  String get lotteryRarityUncommon => '进阶';

  @override
  String get lotteryRarityCommon => '普通';

  @override
  String get lotteryRarityComfort => '安慰';

  @override
  String get languageChinese => '中文';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get languageEnglish => 'English';

  @override
  String get wordKnowledgeTitle => '词汇全解';

  @override
  String get wordKnowledgeCollocations => '词组搭配';

  @override
  String get wordKnowledgeSynAnt => '近义 / 反义';

  @override
  String get wordKnowledgeFamily => '派生词族';

  @override
  String get wordKnowledgeRoots => '词根拆词';

  @override
  String get pronunciationAccentUk => '英音';

  @override
  String get pronunciationAccentUs => '美音';

  @override
  String pronunciationAnnounce(String accent, String word) {
    return '$accent $word';
  }

  @override
  String pronunciationPlaying(String accent, String word) {
    return '$accent发音：$word';
  }

  @override
  String pronunciationUnavailable(String accent) {
    return '$accent发音暂不可用';
  }

  @override
  String pronunciationFailedRetry(String accent) {
    return '$accent发音失败，请重试';
  }

  @override
  String pronunciationLoading(String accent) {
    return '$accent加载';
  }

  @override
  String pronunciationRetry(String accent) {
    return '$accent重试';
  }

  @override
  String get dueNow => '现在到期';

  @override
  String dueInDays(int count) {
    return '$count 天后';
  }

  @override
  String dueInHours(int count) {
    return '$count 小时后';
  }

  @override
  String dueInMinutes(int count) {
    return '$count 分钟后';
  }

  @override
  String get languageMapTitle => '选择学习语言';

  @override
  String get languageMapSelectPrompt => '点击国家选择你想学习的语言。';

  @override
  String get languageMapChinese => '中文';

  @override
  String languageMapConfirm(String language) {
    return '学习$language';
  }

  @override
  String languageMapSelected(String language) {
    return '已切换到$language';
  }

  @override
  String languageMapComingSoon(String language) {
    return '$language：暂未开放';
  }

  @override
  String get aboutCompanyName => 'LinguaQuest';

  @override
  String get aboutCompanyAddress => '厦门大学马来西亚分校，雪兰莪州雪邦 43900（虚拟地址）';

  @override
  String get aboutCompanyDescription => '我们打造 LinguaQuest 的虚拟园区。';

  @override
  String get aiLearningStatusAvailable => '可用';

  @override
  String get aiExplainWithAi => '用 AI 讲解';

  @override
  String get aiErrorGeneric => '出错了，请重试。';

  @override
  String get aiEmptyChat => '关于中文的任何问题都可以问——词义、语法或用法。';

  @override
  String get aiQuestionHint => '输入你关于中文的问题……';

  @override
  String get aiEmptyAnalysis => '粘贴一个中文句子，查看它的结构拆解。';

  @override
  String get aiEmptyCloze => '输入一个词，生成填空练习。';

  @override
  String get aiEmptyWriting => '粘贴你的作文并选择考试类型，获取评分反馈。';

  @override
  String get achievementsScreenTitle => '成就';

  @override
  String get achievementsHeaderTitle => '我的成就';

  @override
  String achievementsUnlockedCount(int unlocked, int total) {
    return '$unlocked / $total 已解锁';
  }

  @override
  String get achievementUnlockedLabel => '已解锁';

  @override
  String get achievementLearn100Title => '词汇百人斩';

  @override
  String get achievementLearn100Desc => '掌握 100 个单词';

  @override
  String get achievementQuizPerfectTitle => '完美发挥';

  @override
  String get achievementQuizPerfectDesc => '完成一次 100% 正确率的测验（4 题以上）';

  @override
  String get achievementFirstListeningTitle => '初次聆听';

  @override
  String get achievementFirstListeningDesc => '完成第一次听力练习';

  @override
  String get achievementFirstMapLanguageTitle => '探图者';

  @override
  String get achievementFirstMapLanguageDesc => '在语言地图中选择一门语言';

  @override
  String get assetInventoryTitle => '我的资产';

  @override
  String get assetInventoryEmpty => '暂无资产，快去幸运抽奖试试手气！';

  @override
  String assetInventoryTotalOwned(int count) {
    return '拥有 $count 件';
  }

  @override
  String assetInventoryTotalFragments(int count) {
    return '$count 碎片';
  }

  @override
  String assetInventoryQuantityBadge(int count) {
    return '×$count';
  }

  @override
  String get luckyDrawViewMyAssets => '查看我的资产';

  @override
  String get analyticsReportTitle => '学习报告';

  @override
  String get analyticsReportSubtitle => '你的进度、图表与重点';

  @override
  String analyticsScopeLabel(Object scope) {
    return '范围：$scope';
  }

  @override
  String get analyticsXpTrendTitle => '经验值趋势';

  @override
  String get analyticsAbilityTitle => '能力维度';

  @override
  String get analyticsModalityTitle => '各题型正确率';

  @override
  String get analyticsMasteryTitle => '单词掌握度';

  @override
  String get analyticsDetailTitle => '详细数据';

  @override
  String get analyticsFocusTitle => '推荐练习';

  @override
  String get analyticsReviewLoad => '复习负荷';

  @override
  String get analyticsWeekXp => '本周经验';

  @override
  String get analyticsTodayXp => '今日经验';

  @override
  String get analyticsWeakWords => '薄弱单词';

  @override
  String get analyticsDueNow => '待复习';

  @override
  String get analyticsMasteryNew => '新词';

  @override
  String get analyticsMasteryLearning => '学习中';

  @override
  String get analyticsMasteryMastered => '已掌握';

  @override
  String get analyticsDimMeaningRecognition => '认词';

  @override
  String get analyticsDimMeaningRecall => '回忆';

  @override
  String get analyticsDimContext => '语境';

  @override
  String get analyticsDimListening => '听力';

  @override
  String get analyticsDimSpelling => '拼写';

  @override
  String get analyticsModalityMeaning => '词义';

  @override
  String get analyticsModalityListening => '听力';

  @override
  String get analyticsModalitySpelling => '拼写';

  @override
  String get analyticsModalityContext => '语境';

  @override
  String get analyticsTopErrors => '主要错误类型';

  @override
  String get readingTitle => '时文阅读';

  @override
  String get readingDiscoverEntry => '时文阅读';

  @override
  String get readingRecommended => '为你推荐';

  @override
  String get readingAllArticles => '全部文章';

  @override
  String get readingFilterLevel => '级别';

  @override
  String get readingFilterTheme => '主题';

  @override
  String get readingFilterAll => '全部';

  @override
  String readingMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get readingEmpty => '该筛选下暂无文章。';

  @override
  String get readingProgressInProgress => '阅读中';

  @override
  String get readingProgressDone => '已读';

  @override
  String get readingToggleTranslation => '翻译';

  @override
  String get readingToggleReading => '注音';

  @override
  String get readingParagraphAudio => '播放';

  @override
  String get readingTapWordHint => '点击高亮词查看释义。';

  @override
  String get readingWordAddToVocab => '加入生词本';

  @override
  String get readingWordAdded => '已加入生词本';

  @override
  String get readingComprehensionCta => '开始练习';

  @override
  String get readingComprehensionSoon => '阅读理解题将在下个阶段上线。';

  @override
  String get readingThemeCampus => '校园';

  @override
  String get readingThemeLife => '生活';

  @override
  String get readingThemeTravel => '旅行';

  @override
  String get readingThemeTech => '科技';

  @override
  String get readingThemeCulture => '文化';

  @override
  String get readingThemeNews => '新闻';

  @override
  String get readingThemeBusiness => '商务';

  @override
  String get readingThemeExam => '考试';

  @override
  String get readingToggleHighlight => '高亮';

  @override
  String get readingLegendTitle => '词汇高亮';

  @override
  String get readingClassKey => '重点词';

  @override
  String get readingClassUnknown => '需复习';

  @override
  String get readingClassNew => '生词';

  @override
  String get readingClassKnown => '已掌握';

  @override
  String get readingComprehensionStart => '开始做题';

  @override
  String get readingComprehensionTitle => '阅读理解';

  @override
  String readingComprehensionQuestion(int current, int total) {
    return '第 $current / $total 题';
  }

  @override
  String get readingComprehensionNext => '下一题';

  @override
  String get readingComprehensionFinish => '完成';

  @override
  String get readingComprehensionResultTitle => '阅读理解完成';

  @override
  String readingComprehensionScore(int correct, int total) {
    return '答对 $correct / $total';
  }

  @override
  String readingComprehensionAccuracy(int pct) {
    return '正确率 $pct%';
  }

  @override
  String get readingComprehensionDone => '完成';

  @override
  String get readingComprehensionEmpty => '本篇暂无理解题。';

  @override
  String get readingAnalyticsTitle => '阅读';

  @override
  String get readingAnalyticsArticlesRead => '已读文章';

  @override
  String get readingAnalyticsAccuracy => '理解正确率';

  @override
  String get readingAnalyticsThemes => '按主题';

  @override
  String get readingAnalyticsEmpty => '完成一次阅读理解后这里会显示数据。';

  @override
  String get readingExplainTooltip => 'AI 讲解';

  @override
  String get readingExplainTitle => 'AI 讲解';

  @override
  String get readingExplainLoading => '正在讲解这一段...';

  @override
  String get readingExplainGist => '大意';

  @override
  String get readingExplainKeyWords => '重点词';

  @override
  String get readingExplainGrammar => '语法点';

  @override
  String get readingExplainStructure => '句子结构';

  @override
  String get readingExplainTranslation => '翻译';

  @override
  String get readingExplainPractice => '练习';
}
