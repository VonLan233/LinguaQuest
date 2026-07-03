// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LinguaQuest';

  @override
  String get appSubtitle =>
      'Build vocabulary with short lessons and smart review.';

  @override
  String get tabHome => 'Home';

  @override
  String get tabTraining => 'Training';

  @override
  String get tabAiLearning => 'AI Learn';

  @override
  String get tabDiscover => 'Discover';

  @override
  String get tabProfile => 'Me';

  @override
  String get commonRegister => 'Register';

  @override
  String get commonLogin => 'Login';

  @override
  String get commonSettings => 'Settings';

  @override
  String get commonTheme => 'Theme';

  @override
  String get commonDailyReminder => 'Daily Reminder';

  @override
  String get commonStudyPlan => 'Study Plan';

  @override
  String get commonWordbook => 'Wordbook';

  @override
  String get commonCustomWords => 'Custom Words';

  @override
  String get commonMistakeBook => 'Mistake Book';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonReview => 'Review';

  @override
  String get commonSave => 'Save';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonAdd => 'Add';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonCheck => 'Check';

  @override
  String get commonLeave => 'Leave';

  @override
  String get commonExit => 'Exit';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonProfile => 'Profile';

  @override
  String get commonLogout => 'Logout';

  @override
  String get commonXP => 'XP';

  @override
  String get commonDay => 'day';

  @override
  String get commonDaysLabel => 'days';

  @override
  String get commonWords => 'words';

  @override
  String get commonLessons => 'lessons';

  @override
  String get commonNew => 'new';

  @override
  String get commonDue => 'due';

  @override
  String get commonMinutes => 'minutes';

  @override
  String get commonLesson => 'lesson';

  @override
  String get commonMastery => 'mastery';

  @override
  String get commonMasteryOutOf => '/5';

  @override
  String get commonAlreadyAdded => 'Already added';

  @override
  String get commonWrongPrefix => 'Wrong ';

  @override
  String get commonTimesSuffix => ' times';

  @override
  String get commonViewAll => 'View all';

  @override
  String get commonView => 'View';

  @override
  String get authRegisterTitle => 'Register';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get authCreateProfile => 'Create Learning Profile';

  @override
  String get authCreateProfileSubtitle =>
      'Set up your account, then choose your goals and daily pace.';

  @override
  String get authStep1of2 => 'Step 1 / 2';

  @override
  String get authStep2of2 => 'Step 2 / 2';

  @override
  String get authNickname => 'Nickname';

  @override
  String get authNicknameHint => 'Enter nickname';

  @override
  String get authEmail => 'Email';

  @override
  String get authEmailHint => 'name@example.com';

  @override
  String get authPassword => 'Password';

  @override
  String get authPasswordHint => 'Set password';

  @override
  String get authNameRequired => 'Please enter a nickname';

  @override
  String get authEmailRequired => 'Please enter an email';

  @override
  String get authEmailInvalid => 'Please enter a valid email';

  @override
  String get authPasswordRequired => 'Password must be at least 6 characters';

  @override
  String get authContinueToGoal => 'Continue to Goal Setup';

  @override
  String get authHaveAccount => 'Already have an account? Log in';

  @override
  String get authAccountCreated =>
      'Account created. Please continue to set up your learning plan.';

  @override
  String get authWelcomeBack => 'Welcome back';

  @override
  String get authWelcomeBackSubtitle =>
      'Continue today\'s learning path and clear your due review cards.';

  @override
  String get authRegisterNew => 'Register new account';

  @override
  String get onboardingTitle => 'LinguaQuest';

  @override
  String get onboardingSubtitle =>
      'Short lessons, visual memory cards, and smart review help you build vocabulary steadily.';

  @override
  String get onboardingTagline => 'Level up daily like a game';

  @override
  String get onboardingTagWorld => 'Word Quest World';

  @override
  String get onboardingTagStreak => 'Daily streak';

  @override
  String get splashTagline => 'Image word cards, clear paths, smart review.';

  @override
  String get studyNewScreenTitle => 'New words';

  @override
  String get studyWordbookPath => 'Wordbook path';

  @override
  String get studyEnterCards => 'Start word cards';

  @override
  String get studyNewPackTitle => 'Today\'s new word pack';

  @override
  String get studyNewPackDesc =>
      'Self-assess first, then view cards, then context questions. Formal review is queued separately.';

  @override
  String get studyNoNewWords => 'No new words';

  @override
  String get studyNewPausedHint =>
      'Study plan paused. Resume to continue today\'s new words.';

  @override
  String get studyNewEmptyHint =>
      'The current wordbook is finished, or the plan isn\'t generated yet. Check the wordbook path for the next set.';

  @override
  String get studyOpenWordbookPath => 'Open wordbook path';

  @override
  String studyTodayLearnCount(Object count) {
    return 'Learn $count new words today';
  }

  @override
  String get studyNewNoLessonHint =>
      'Finish review before adding new words; keeping a rhythm beats piling on tasks.';

  @override
  String studyNewPausedResume(Object section) {
    return 'Study plan paused; resume to continue from $section.';
  }

  @override
  String get studyRecallKnown => 'Know it';

  @override
  String get studyRecallFuzzy => 'Unsure';

  @override
  String get studyRecallUnknown => 'Don\'t know';

  @override
  String get studyStepSelfAssess => 'Self-assess';

  @override
  String get studyStepSelfAssessDesc => 'Reduce wasted repetition';

  @override
  String get studyStepCards => 'Word cards';

  @override
  String get studyStepCardsDesc => 'Fill in meaning and examples';

  @override
  String get studyStepContext => 'Context';

  @override
  String get studyStepContextDesc => 'Active recall';

  @override
  String get mixedManageReviewQueue => 'Manage review queue';

  @override
  String mixedReviewRatio(Object percent) {
    return 'Review $percent%';
  }

  @override
  String get mixedTitleNew => 'Today\'s new word pack';

  @override
  String get mixedTitleReview => 'Quick review';

  @override
  String get mixedTitleMixed => 'Today\'s mixed pack';

  @override
  String get mixedSaveReviewFailed =>
      'Unable to save the review record for now';

  @override
  String mixedUnsureOption(Object index) {
    return 'Unsure $index';
  }

  @override
  String get mixedSaveProgressTitle => 'Save this progress?';

  @override
  String get mixedSaveProgressBody =>
      'Saved review records are kept; saving records the questions completed this time, and unfinished words return to the pack next time.';

  @override
  String get mixedContinueStudy => 'Keep studying';

  @override
  String get mixedLeaveWithoutSaving => 'Leave without saving';

  @override
  String get mixedSaveAndLeave => 'Save and leave';

  @override
  String get mixedSaveStudyFailed => 'Unable to save study progress for now';

  @override
  String get mixedSelfAssessHint =>
      'Self-assess first; the app adjusts today\'s repetitions';

  @override
  String get mixedEnterRecognition => 'Start recognition';

  @override
  String get mixedAddLaterRecall => 'Add to later recall';

  @override
  String get mixedReviewQuickAnswer => 'Review quick answer';

  @override
  String get mixedFeedbackCorrect => 'Correct, on to the next one.';

  @override
  String get mixedFeedbackWrong =>
      'Wrong; check the knowledge card, it will appear again later.';

  @override
  String get mixedFeedbackRetry =>
      'Not yet. Pick the correct answer before continuing.';

  @override
  String mixedShortRecallPrompt(Object word) {
    return 'Short recall: what does $word mean?';
  }

  @override
  String mixedMeaningPrompt(Object word) {
    return 'What is the meaning of $word?';
  }

  @override
  String get mixedStepRecognition => 'Recognition';

  @override
  String get mixedStepShortRecall => 'Short recall';

  @override
  String get mixedStepDueReview => 'Due review';

  @override
  String get mixedStepKnowledge => 'Knowledge card';

  @override
  String get mixedCompleteTitle => 'Today\'s pack complete';

  @override
  String get mixedNoContentTitle => 'Nothing to study today';

  @override
  String get mixedCompleteBody =>
      'Mistakes have been recycled this round; your answers and time are saved to the study log.';

  @override
  String get mixedNoContentBody => 'No new words or due reviews right now.';

  @override
  String get mixedSaveAndHome => 'Save and go home';

  @override
  String get questCenterTitle => 'Task center';

  @override
  String get questCenterSubtitle =>
      'Earn points after study actions; also view rankings, analytics, and class learning.';

  @override
  String get questDailyTask => 'Daily tasks';

  @override
  String get questDailyTaskBody => 'Finish a lesson and review 5 due words.';

  @override
  String get questAchievements => 'Achievements';

  @override
  String get questAchievementsBody =>
      'Streaks, 100 words learned, first perfect lesson, and more.';

  @override
  String get questAchievementsValue => '3';

  @override
  String get questLeaderboard => 'Leaderboard';

  @override
  String get questLeaderboardBody =>
      'Weekly XP ranking for friends and future classes.';

  @override
  String get questWeekly => 'Weekly';

  @override
  String get questAnalytics => 'Learning analytics';

  @override
  String get questAnalyticsBody =>
      'Accuracy, vocabulary growth, and review completion trends.';

  @override
  String get questTrend => 'Trends';

  @override
  String get questAiTutor => 'AI tutor';

  @override
  String get questAiTutorBody =>
      'Explain mistakes and suggest example sentences.';

  @override
  String get aiTutorSamplePrompt =>
      'Explain the difference between affect and effect';

  @override
  String get aiTutorSubtitle =>
      'Enter a word, grammar point, or mistake to get a structured explanation and practice sentences.';

  @override
  String get aiTutorInputLabel => 'Ask about a word, grammar, or mistake';

  @override
  String get aiTutorSampleAnswer =>
      'Affect is usually a verb: \"The weather affects my mood.\" Effect is usually a noun: \"The effect was immediate.\" Try writing a sentence with each word.';

  @override
  String get leaderboardDefaultName => 'Explorer';

  @override
  String get leaderboardTitle => 'Training leaderboard';

  @override
  String get leaderboardSubtitle =>
      'Counts only real completed training XP; no static demo board.';

  @override
  String get leaderboardEmptyTitle => 'No training results yet';

  @override
  String get leaderboardEmptyBody =>
      'After finishing Word Rush, Survival, or Spelling, real training XP generates the ranking.';

  @override
  String get leaderboardOnlyValidXp => 'Counts valid learning XP only';

  @override
  String get analyticsDataTitle => 'Learning data';

  @override
  String get analyticsDataSubtitle =>
      'A first analytics view based on word cards and review records.';

  @override
  String analyticsAssetsDue(Object due, Object total) {
    return '$due of $total learning assets are due';
  }

  @override
  String get analyticsCards => 'Word cards';

  @override
  String get analyticsTrainingXp => 'Training XP';

  @override
  String get analyticsAccuracy => 'Accuracy';

  @override
  String get onboardingFeatureImageCards => 'Image Word Cards';

  @override
  String get onboardingFeatureImageCardsDesc =>
      'Words, meanings, and examples connected in one learning flow.';

  @override
  String get onboardingFeaturePath => 'Clear Path';

  @override
  String get onboardingFeaturePathDesc =>
      'Short lessons guide your daily learning path.';

  @override
  String get onboardingFeatureReview => 'Timely Review';

  @override
  String get onboardingFeatureReviewDesc =>
      'Weak words return to queue faster; mastered words get longer review intervals.';

  @override
  String get onboardingTagPillXp => 'XP';

  @override
  String get onboardingTagPillStreak => 'Streak';

  @override
  String get onboardingTagPillPlanet => 'LinguaQuest Planet';

  @override
  String get onboardingRegisterButton => 'Register';

  @override
  String get goalSetupTitle => 'Goal Setup';

  @override
  String get goalSetupSelectPlan => 'Select Learning Plan';

  @override
  String get goalSetupSelectPlanSubtitle =>
      'The system breaks your goal into daily new words, due reviews, and point tasks.';

  @override
  String get goalSetupTarget => 'Target';

  @override
  String get goalSetupDailyGoal => 'Daily Goal';

  @override
  String get goalSetupDeadlinePlan => 'Plan by Deadline';

  @override
  String get goalSetupDeadlineHint =>
      'Select a target date, and the system will calculate daily word count automatically.';

  @override
  String get goalSetupPickDate => 'Pick Date';

  @override
  String get goalSetupChangeDate => 'Change Date';

  @override
  String get goalSetupClearDate => 'Clear Date Plan';

  @override
  String get goalSetupEnterApp => 'Enter LinguaQuest';

  @override
  String get goalSetupCurrentBook => 'Current Wordbook';

  @override
  String get goalSetupLearned => 'Learned';

  @override
  String get goalSetupNewWords => 'New';

  @override
  String goalSetupNewWordsCount(Object count) {
    return '$count new words';
  }

  @override
  String get goalSetupReviewLimit => 'Review Cap';

  @override
  String goalSetupReviewLimitCount(Object count) {
    return 'Review cap: $count words';
  }

  @override
  String get goalSetupViewWordbook => 'View Full Wordbook';

  @override
  String get homePersonalSpace => 'Personal Space';

  @override
  String get homeSearchHint => 'Search words, phrases, or examples';

  @override
  String get homeNotifications => 'Notifications';

  @override
  String get homeLearned => 'Learned';

  @override
  String get homeMastered => 'Mastered';

  @override
  String get homeReviewLabel => 'Review';

  @override
  String get homeTaskConsole => 'Daily Task Console';

  @override
  String get homeAdjustPlan => 'Adjust Plan';

  @override
  String get homeResumePlan => 'Resume plan to continue learning';

  @override
  String get homeStartLearning => 'Start';

  @override
  String get homeReviewOnly => 'Review';

  @override
  String get homeStreakLabel => 'continuous check-in';

  @override
  String homeStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days check-in',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get homeTodayProgress => 'Today';

  @override
  String get homeWordbookShortcut => 'Wordbook';

  @override
  String get homeDailyArticle => 'Daily Article';

  @override
  String get homeDailyArticleSubtitle => 'Cloze Reading';

  @override
  String get homeLearningPath => 'Learning Path';

  @override
  String get homeLearningPathSubtitle => 'Official Wordbook';

  @override
  String get homeWordOfDay => 'Word of the Day';

  @override
  String get homeOpenWordCard => 'Open Word Card';

  @override
  String get homeWeakWords => 'Weak Words';

  @override
  String get homeNoWeakWords => 'No high-frequency mistake words yet.';

  @override
  String get homeWeakWordsReview => 'Review them before they pile up.';

  @override
  String get homeWeakWordsEmptyHint =>
      'Add new words or complete reviews, and words needing focus will appear here.';

  @override
  String get homePlanPaused => 'Plan Paused';

  @override
  String get homeTodayCompleted => 'Today completed';

  @override
  String get profileLearner => 'Explorer';

  @override
  String get profileNoEmail => 'No email set';

  @override
  String get profileDashboard => 'Learning Dashboard';

  @override
  String get profileDashboardSubtitle =>
      'Key progress at a glance, with settings at the bottom.';

  @override
  String get profileLearnedWords => 'Words Learned';

  @override
  String get profileMasteredWords => 'Mastered';

  @override
  String get profileCustomWords => 'Custom Words';

  @override
  String get profileAverageAccuracy => 'Avg. Accuracy';

  @override
  String get profilePlansCompleted => 'Plans Done';

  @override
  String profileStreakDays(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days streak',
      one: '1 day streak',
    );
    return '$_temp0';
  }

  @override
  String get profileCurrentBookProgress => 'Current Wordbook Progress';

  @override
  String get profileWordbookSubtitle =>
      'Current wordbook and target vocabulary';

  @override
  String get profileCustomWordsSubtitle =>
      'Saved words and personal vocabulary cards';

  @override
  String get profileMistakeBookSubtitle => 'Lesson mistakes and weak words';

  @override
  String get profileReminderSubtitle => 'Set reminder time and toggle';

  @override
  String get profileDarkModeSubtitle => 'Follow system, light, or dark theme';

  @override
  String get profileHelpSubtitle => 'FAQ and support';

  @override
  String get profileHelpTitle => 'Help & Feedback';

  @override
  String get profileAboutSubtitle => 'LinguaQuest vision & version 1.0.0';

  @override
  String get profileAboutTitle => 'About Us';

  @override
  String get profileLogout => 'Logout';

  @override
  String get profileSettingsSupport => 'Settings & Support';

  @override
  String get profilePlanLabel => 'Study Plan';

  @override
  String get profilePlanRunning => 'Active';

  @override
  String get profilePlanPaused => 'Paused';

  @override
  String get profileWeaknessAnalysis => 'Weakness Analysis';

  @override
  String get profileNoWeakness =>
      'No frequent mistakes yet. Complete learning and reviews to generate analysis.';

  @override
  String get profileMostWrongWord => 'Most Wrong Word';

  @override
  String get settingsAppBar => 'Settings';

  @override
  String get settingsSoundFeedback => 'Answer Sound Feedback';

  @override
  String get settingsSoundFeedbackSubtitle =>
      'Provides audio feedback for quiz results and practice rhythm';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeSystem => 'Follow System';

  @override
  String get settingsThemeSystemSubtitle =>
      'Automatically switch based on device light/dark preference';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeLightSubtitle =>
      'Keep a bright and clean learning interface';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeDarkSubtitle => 'Use dark learning interface';

  @override
  String get settingsReminderTitle => 'Daily Reminder';

  @override
  String get settingsReminderTime => 'Reminder Time';

  @override
  String get settingsReminderOff => 'Reminder Off';

  @override
  String get settingsReminderDisabled => 'No local reminders scheduled';

  @override
  String get settingsReminderDescription =>
      'The app remembers your reminder time and schedules local system reminders to prompt daily learning and check-ins.';

  @override
  String get discoverTitle => 'Discover';

  @override
  String get discoverSubtitle =>
      'Check-in, point tasks, lucky draw, and learning community; earned XP adds to your total score.';

  @override
  String get discoverTaskCenter => 'Task Center';

  @override
  String get discoverXpTasks => 'Point Tasks';

  @override
  String get discoverXpTasksSubtitle =>
      'Complete conditions then tap \"Claim\" — XP instantly adds to your profile and leaderboard.';

  @override
  String get discoverDailyCheckin => 'Daily Check-in';

  @override
  String get discoverDailyCheckinCondition =>
      'Open the app and complete one learning action today';

  @override
  String get discoverNewLearning => 'Complete New Learning';

  @override
  String get discoverNewLearningCondition =>
      'Finish today\'s new learning task';

  @override
  String get discoverReviewDone => 'Complete Review';

  @override
  String get discoverReviewDoneCondition => 'Finish today\'s due review';

  @override
  String get discoverTrainingChallenge => 'Training Challenge';

  @override
  String get discoverTrainingChallengeCondition => 'Complete any training game';

  @override
  String get discoverWeakCleanup => 'Weak Word Cleanup';

  @override
  String get discoverWeakCleanupCondition =>
      'Re-answer today\'s mistake words correctly';

  @override
  String get discoverLuckyDraw => 'Lucky Draw';

  @override
  String get discoverLuckyDrawSubtitle =>
      'Prizes are virtual decorations only and do not affect learning fairness.';

  @override
  String get discoverLuckyDrawItems =>
      'Avatar frames, profile backgrounds, learning badges, training titles, card skins';

  @override
  String get discoverLuckyDrawCost =>
      '30 XP per draw; rare probability displayed transparently, fragments given even without a prize.';

  @override
  String get discoverCommunityPosts => 'Community Posts';

  @override
  String get discoverCommunityPostsSubtitle => 'Community';

  @override
  String get discoverMyFavorites => 'My Favorites';

  @override
  String get favoritesEmpty => 'You haven\'t favorited any posts yet.';

  @override
  String get communityFilterAll => 'All';

  @override
  String get communityTagGrammar => 'Grammar';

  @override
  String get communityTagVocabulary => 'Vocabulary';

  @override
  String get communityTagCulture => 'Culture';

  @override
  String get communityTagGeneral => 'General';

  @override
  String get communityTagProgress => 'Progress';

  @override
  String get communityShareUpdate => 'Share an update';

  @override
  String get communityNewPost => 'New Post';

  @override
  String get communityNoPostsInFilter => 'No posts in this category yet';

  @override
  String get communityTimeJustNow => 'Just now';

  @override
  String communityTimeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String communityTimeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String communityTimeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get discoverXpUsage => 'XP Usage';

  @override
  String get discoverXpUsageDesc =>
      'Claimed XP syncs to profile and leaderboard; lucky draw consumes current XP. Current balance';

  @override
  String discoverGoComplete(Object points) {
    return 'Go +$points XP';
  }

  @override
  String discoverClaim(Object points) {
    return 'Claim +$points XP';
  }

  @override
  String discoverClaimed(Object points) {
    return 'Earned +$points XP';
  }

  @override
  String discoverClaimedMessage(Object points, Object title, Object total) {
    return '$title claimed +$points XP, current total $total XP';
  }

  @override
  String get discoverCannotClaim => 'Can\'t claim this task right now';

  @override
  String get discoverViewProfile => 'View Profile';

  @override
  String errorStartupFailed(Object detail) {
    return 'LinguaQuest failed to start: $detail';
  }

  @override
  String get errorPlanPausedNewLearning =>
      'Your study plan is paused. Resume it to start new learning.';

  @override
  String get errorPlanPausedReview =>
      'Your study plan is paused. Resume it to review.';

  @override
  String get errorCardReviewedToday =>
      'You\'ve already reviewed this card today.';

  @override
  String get errorTaskClaimedToday =>
      'You\'ve already claimed this task today.';

  @override
  String get errorTargetReviewedToday =>
      'You\'ve already reviewed this target word today.';

  @override
  String errorInsufficientXp(Object balance, Object cost) {
    return 'Balance $balance XP is below $cost XP. Finish point tasks before the draw.';
  }

  @override
  String get aiTutorInstantFeedback => 'Instant Feedback';

  @override
  String get questTaskXp => 'Task XP';

  @override
  String get discoverTasksEmpty => 'Today\'s point tasks haven\'t loaded yet.';

  @override
  String get discoverForumCheckinTag => 'Check-in';

  @override
  String get discoverForumMistakeTag => 'Mistake Talk';

  @override
  String get discoverForumPost1Title =>
      'Check-in: reviewed 18 words in 12 minutes';

  @override
  String get discoverForumPost1Body =>
      'Mistakes cluster around near-synonyms; tomorrow I\'ll start with the confusable-word challenge in training.';

  @override
  String get discoverForumPost2Title =>
      'How do you memorize the word \'abstract\'?';

  @override
  String get discoverForumPost2Body =>
      'In papers and reading passages \'abstract\' often doesn\'t mean \'抽象\'; judge it by context.';

  @override
  String get discoverForumHint =>
      'Tap \"Record interaction\" on a community post below to finish the forum interaction task.';

  @override
  String get discoverCheckinSuccess =>
      'Checked in! Today\'s check-in points are ready to claim.';

  @override
  String get discoverCheckinFailed =>
      'Check-in failed, please try again later.';

  @override
  String get discoverForumSuccess =>
      'Forum interaction approved; the point task is ready to claim.';

  @override
  String get discoverForumFailed =>
      'Failed to record forum interaction, please try again later.';

  @override
  String get discoverCheckinLoadingHint =>
      'You can check in once tasks finish loading.';

  @override
  String discoverCheckinClaimedDesc(int points) {
    return 'Checked in today and claimed +$points XP.';
  }

  @override
  String discoverCheckinClaimableDesc(int points) {
    return 'Checked in today; remember to claim +$points XP.';
  }

  @override
  String get discoverCheckinPrompt =>
      'After checking in, the check-in task becomes claimable.';

  @override
  String get discoverCheckingIn => 'Checking in';

  @override
  String get discoverCheckedIn => 'Checked in';

  @override
  String get discoverCheckIn => 'Check in';

  @override
  String get discoverAlreadyClaimed => 'Claimed';

  @override
  String get discoverClaimCheckin => 'Claim check-in XP';

  @override
  String get discoverLoading => 'Loading';

  @override
  String get discoverReloadTasks => 'Reload tasks';

  @override
  String get discoverConditionMet =>
      'Conditions met — tap to claim your reward.';

  @override
  String get discoverProcessing => 'Processing';

  @override
  String get discoverRecordInteraction => 'Record interaction';

  @override
  String get quizNoLesson => 'Lesson not found';

  @override
  String get quizNoQuestions => 'This lesson has no quiz yet.';

  @override
  String get quizTimedTest => 'Timed Test';

  @override
  String get quizCampusSpeed => 'Campus Sprint';

  @override
  String get quizLeaveTitle => 'Leave Quiz?';

  @override
  String get quizLeaveContent => 'Current quiz progress will be discarded.';

  @override
  String get quizKeepAnswering => 'Keep Answering';

  @override
  String get quizInputWord => 'Enter word';

  @override
  String get quizCorrect => 'Correct. ';

  @override
  String get quizWrong => 'Not quite. ';

  @override
  String get quizReinforce => 'Reinforce: ';

  @override
  String get quizContinue => 'Continue';

  @override
  String get quizRetry => 'Retry';

  @override
  String get quizCheck => 'Check';

  @override
  String get quizResultTitle => 'Lesson Result';

  @override
  String get quizTimedResultTitle => 'Timed Test Result';

  @override
  String get quizGreatJob => 'Great job!';

  @override
  String get quizChallengeDone => 'Challenge Done';

  @override
  String get quizLessonDone => 'Lesson Done';

  @override
  String get quizChallengeSuccess => 'Challenge Success!';

  @override
  String get quizAccuracy => 'Accuracy';

  @override
  String get quizMistakes => 'Mistakes';

  @override
  String get quizNoResult => 'No lesson result yet';

  @override
  String get quizAllCorrect => 'All correct!';

  @override
  String get quizMistakeReview => 'Mistakes saved to review.';

  @override
  String get quizMistakeTimed =>
      'Mistakes can be reviewed in the review center.';

  @override
  String get quizRetryMistakes => 'Practice mistakes again';

  @override
  String get quizGoReviewCenter => 'Go to review center';

  @override
  String get quizBackTraining => 'Back to training';

  @override
  String get quizBackLearningPath => 'Back to learning path';

  @override
  String get quizXpBalanceUpdated => 'Total XP updated';

  @override
  String quizCurrentXp(Object xp) {
    return 'Current total $xp XP';
  }

  @override
  String quizXpCredited(Object xp) {
    return '+$xp XP credited';
  }

  @override
  String quizXpImpactBody(Object balance) {
    return '$balance. XP syncs to your profile, leaderboard, and lucky-draw balance.';
  }

  @override
  String get quizTimedReward => 'Timed test reward';

  @override
  String get quizLessonReward => 'Lesson reward';

  @override
  String get quizViewXpUses => 'View XP uses';

  @override
  String quizXpEarned(Object xp) {
    return 'Credited +$xp XP';
  }

  @override
  String quizTotalXp(Object xp) {
    return 'Total $xp XP';
  }

  @override
  String quizMistakeCount(Object count) {
    return '$count mistakes';
  }

  @override
  String get trainingTitle => 'Training Ground';

  @override
  String get trainingSubtitle => 'Timed tests, drills, leaderboard';

  @override
  String get trainingPageSubtitle =>
      'Timed tests, special drills, and the leaderboard live here.';

  @override
  String get trainingWeeklyXpPrefix => 'This week';

  @override
  String get trainingDailyXpAvailable => 'Up to 60 XP today';

  @override
  String get trainingLeaderboard => 'Leaderboard';

  @override
  String get trainingTimedTestsSubtitle => 'Campus packs & speed challenges';

  @override
  String get trainingCampusSpeed => 'Campus Sprint';

  @override
  String get trainingCampusSpeedDesc =>
      'Draws from current wordbook. Good for post-class quick checks without affecting formal review rhythm.';

  @override
  String get trainingSpeedGame => 'Speed Game';

  @override
  String get trainingSpeedGameDesc =>
      'Answer meaning-choice questions within 60 seconds. Score based on accuracy, combos, and speed.';

  @override
  String get trainingSpeedGameSource => 'Learned + due words';

  @override
  String get trainingNoWordbook => 'No wordbook';

  @override
  String get trainingStartTest => 'Start Test';

  @override
  String get trainingComingSoon => 'Coming Soon';

  @override
  String get trainingSpecialDrillsSubtitle =>
      'Practice spelling, listening, collocation, and passage cloze to strengthen weak areas.';

  @override
  String get trainingSurvivor => 'Last One Standing';

  @override
  String get trainingSurvivorDesc =>
      'Answer questions from easy to hard. Wrong answers go to weak words and mistake book.';

  @override
  String get trainingSurvivorSource => 'Current wordbook + weak words';

  @override
  String get trainingSpelling => 'Word Spelling';

  @override
  String get trainingSpellingDesc =>
      'See Chinese, hear pronunciation, or read sentence cloze, then type the English word.';

  @override
  String get trainingSpellingSource => 'Spelling weak words';

  @override
  String get trainingPassageCloze => 'Passage Cloze';

  @override
  String get trainingPassageClozeDesc =>
      'Generate passages with today\'s vocabulary, linking memorization and reading comprehension.';

  @override
  String get trainingPassageClozeSource => 'Today\'s words + AI passage';

  @override
  String get trainingListening => 'Listening Sprint';

  @override
  String get trainingListeningDesc =>
      'Listen to pronunciation, then select the word or meaning. Response time affects score.';

  @override
  String get trainingListeningSource => 'Listening weak words';

  @override
  String get trainingDueWords => 'Review';

  @override
  String get trainingWeakWords => 'Weak';

  @override
  String get trainingComboTarget => 'Combo';

  @override
  String get trainingEnterCustomWords => 'Go to Custom Words';

  @override
  String get trainingEntryMissingTitle => 'Training entry unavailable';

  @override
  String get trainingEntryMissingHeader => 'Training not found';

  @override
  String get trainingEntryMissingSubtitle =>
      'Go back to training and start from Speed Game, Last One Standing, or Word Spelling.';

  @override
  String get trainingSourceInsufficientTitle => 'Not enough training questions';

  @override
  String get trainingSourceInsufficientSubtitle =>
      'Finish a new lesson, add custom words, or build weak words in the mistake book before challenging again.';

  @override
  String get trainingBack => 'Back to training';

  @override
  String get trainingMistakesOnly => 'Practice mistakes again';

  @override
  String get trainingNextQuestion => 'Next question';

  @override
  String get trainingSubmitSpelling => 'Submit spelling';

  @override
  String get trainingExitTitle => 'Leave training?';

  @override
  String get trainingExitContent =>
      'Current training progress will not be settled.';

  @override
  String get trainingContinue => 'Keep training';

  @override
  String get trainingExit => 'Leave';

  @override
  String trainingPromptWordRush(Object word) {
    return 'Choose the meaning of \"$word\" quickly';
  }

  @override
  String trainingExplanationWordRush(
    Object example,
    Object meaning,
    Object word,
  ) {
    return '\"$word\" means $meaning. $example';
  }

  @override
  String trainingPromptChineseChoice(Object meaning) {
    return 'Choose the English word for: $meaning';
  }

  @override
  String trainingExplanationChineseChoice(Object meaning, Object word) {
    return '$meaning matches \"$word\".';
  }

  @override
  String trainingPromptContextChoice(Object example) {
    return 'Choose the meaning from the example: $example';
  }

  @override
  String trainingPromptMeaningChoice(Object word) {
    return 'Choose the meaning of \"$word\"';
  }

  @override
  String trainingExplanationMeaningChoice(Object meaning, Object word) {
    return 'This question checks $word: $meaning.';
  }

  @override
  String trainingPromptChineseSpelling(Object meaning) {
    return 'Spell the English word from the meaning: $meaning';
  }

  @override
  String trainingPromptAudioSpelling(Object cue) {
    return 'Spell the English word after listening: $cue';
  }

  @override
  String trainingPromptContextSpelling(Object example) {
    return 'Spell the blank in the example: $example';
  }

  @override
  String trainingExplanationSpelling(Object example, Object word) {
    return 'The correct spelling is \"$word\". $example';
  }

  @override
  String get trainingNoEffectiveAnswers =>
      'No valid answer this round, so no training record was saved.';

  @override
  String trainingResultMistakesSuffix(Object title) {
    return '$title · mistake practice';
  }

  @override
  String trainingCorrectAttempts(Object attempts, Object correct) {
    return 'Correct $correct/$attempts';
  }

  @override
  String trainingStreak(Object streak) {
    return 'Streak $streak';
  }

  @override
  String trainingAccuracyValue(Object accuracy) {
    return 'Accuracy $accuracy%';
  }

  @override
  String trainingSurvivalResources(Object nodes, Object revives) {
    return 'Revives $revives · Nodes $nodes';
  }

  @override
  String trainingBestStreak(Object streak) {
    return 'Best $streak';
  }

  @override
  String get trainingRealSource => 'Real question source';

  @override
  String get trainingSpellingInputLabel => 'Enter English spelling';

  @override
  String get trainingReviveConsumed => 'One revive was consumed. Keep going.';

  @override
  String get trainingReviveExhausted => 'No revives left. This round ends.';

  @override
  String get trainingCorrectFeedback => 'Correct. Streak continues!';

  @override
  String get trainingPromptListening => 'Listen and choose the word you heard';

  @override
  String get learningPathTitle => 'Learning Path';

  @override
  String get learningPathBackToHome => 'Back to Home';

  @override
  String get learningPathBookPath => 'Wordbook path';

  @override
  String get learningPathPathSuffix => 'path';

  @override
  String get learningPathPausedHint =>
      'The study plan is paused, and path progress will be kept.';

  @override
  String get learningPathDescription =>
      'This view shows only wordbook progress; formal new learning and review stay at the two separate entrances on Home.';

  @override
  String get learningPathPlanLabel => 'Learning plan';

  @override
  String get learningPathStartLearning => 'Start Learning';

  @override
  String get learningPathSubtitle => 'Wordbook progress';

  @override
  String get learningPathOpenWordbook => 'Open Wordbook & Custom Words';

  @override
  String get learningPathAdjustPlan => 'Adjust Current Study Plan';

  @override
  String get learningPathLessonLocked => 'Locked';

  @override
  String get learningPathLessonCurrent => 'Current';

  @override
  String get learningPathLessonCompleted => 'Completed';

  @override
  String get learningPathLessonPreview => 'Preview';

  @override
  String get learningPathLessonQuiz => 'Quiz';

  @override
  String get lessonPreviewTitle => 'New Word Cards';

  @override
  String get lessonPreviewNoLesson => 'Lesson not found';

  @override
  String get lessonPreviewPrevious => 'Previous';

  @override
  String get lessonPreviewNext => 'Next';

  @override
  String get lessonPreviewStartQuiz => 'Start Quiz';

  @override
  String get lessonPreviewConfidence => 'How well do you know this word?';

  @override
  String get lessonPreviewNotYet => 'Not Yet';

  @override
  String get lessonPreviewVaguely => 'Vaguely';

  @override
  String get lessonPreviewGotIt => 'Got It';

  @override
  String get lessonPreviewLeaveTitle => 'Leave Preview?';

  @override
  String get lessonPreviewLeaveContent =>
      'Current preview progress will be discarded.';

  @override
  String get lessonPreviewBuildUnderstanding =>
      'Build understanding first, then context questions';

  @override
  String lessonPreviewProgressMeta(
    Object current,
    Object minutes,
    Object section,
    Object total,
  ) {
    return '$section · $minutes min · $current/$total';
  }

  @override
  String get lessonPreviewLessonCards => 'Lesson cards';

  @override
  String lessonPreviewCardMeta(Object count, Object xp) {
    return '$xp XP · $count context questions';
  }

  @override
  String get lessonPreviewEnterContext => 'Start context practice';

  @override
  String get lessonPreviewNextCard => 'Next card';

  @override
  String get lessonPreviewNoCards => 'No cards';

  @override
  String get lessonPreviewNoCardsBody =>
      'This lesson has no words to study yet.';

  @override
  String get lessonPreviewLeaveCardTitle => 'Leave cards?';

  @override
  String get lessonPreviewLeaveCardContent =>
      'Your current new-word card progress will be discarded.';

  @override
  String get lessonPreviewLeave => 'Leave';

  @override
  String get lessonPreviewAssessFirst => 'Judge your familiarity first';

  @override
  String get lessonPreviewContextExample => 'Context example';

  @override
  String get reviewCenterTitle => 'Review';

  @override
  String reviewCenterCardsDuePrefix(Object count) {
    return '$count cards due';
  }

  @override
  String get reviewCenterDailyCapPrefix => 'Today\'s review cap ';

  @override
  String get reviewCenterDailyCapMiddle => ' words, ';

  @override
  String get reviewCenterDailyCapSuffix => ' words will be scheduled later.';

  @override
  String get reviewCenterCurrentBook => 'Current wordbook';

  @override
  String get reviewCenterAutoQueueHint =>
      'Wrong answers are added to the review queue automatically.';

  @override
  String get reviewCenterEmptyTitle => 'Review queue cleared';

  @override
  String get reviewCenterEmptyMessage =>
      'Add custom word cards, or add mistake cards from wrong answers, and a review queue will be generated here.';

  @override
  String get reviewCenterAddCustomWord => 'Add custom word';

  @override
  String get reviewCenterNoMistakes => 'No weak words or lesson mistakes yet.';

  @override
  String get reviewCenterOpenMistakeBook => 'Open mistake book';

  @override
  String get reviewCenterLimitPrefix => 'Today\'s review is capped at ';

  @override
  String get reviewCenterLimitMiddle => ' words; ';

  @override
  String get reviewCenterLimitSuffix =>
      ' words won\'t be lost and will stay in the review queue.';

  @override
  String get reviewCenterTargetWord => 'Target word';

  @override
  String get reviewCenterCustomCard => 'Custom word card';

  @override
  String get reviewCenterForgot => 'Forgot';

  @override
  String get reviewCenterRemembered => 'Remembered';

  @override
  String get wordDetailNotFound => 'Word not found';

  @override
  String get wordDetailReviewStats => 'Review stats';

  @override
  String get wordDetailMarkRemembered => 'Mark as remembered';

  @override
  String get wordDetailScheduleSoon => 'Practice again soon';

  @override
  String get wordDetailMarkedRemembered => 'Marked as remembered';

  @override
  String get wordDetailScheduledSoon => 'Scheduled to practice again soon';

  @override
  String get wordDetailStatRemembered => 'Remembered';

  @override
  String get wordDetailStatForgot => 'Forgot';

  @override
  String get wordDetailStatMastery => 'Mastery';

  @override
  String get wordDetailUpdateFailed => 'Unable to update this card for now';

  @override
  String wordDetailMasteryLabel(Object level) {
    return 'Mastery $level/5';
  }

  @override
  String wordDetailNextReview(Object when) {
    return 'Next $when';
  }

  @override
  String get reviewCenterPostponedMessage =>
      'Marked as remembered; the next review will be delayed';

  @override
  String get reviewCenterCloserReviewMessage =>
      'Added to a closer review schedule';

  @override
  String get reviewCenterUpdateFailed => 'Unable to update this card right now';

  @override
  String get reviewCenterAddMistakeCards => 'Add mistake cards';

  @override
  String get reviewCenterAllMistakesAdded =>
      'All recent mistakes are already in the wordbook.';

  @override
  String get reviewCenterSelectMistakesHint =>
      'After selecting mistakes, you can add them directly to review cards.';

  @override
  String get reviewCenterAddSelected => 'Add selected';

  @override
  String get reviewCenterMistakeCardsSuffix => ' mistake cards';

  @override
  String get reviewCenterPlanPaused => 'Study plan paused';

  @override
  String get reviewCenterTodayDone => 'Today\'s review completed';

  @override
  String reviewCenterCardsDue(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count cards due',
      one: '1 card due',
      zero: 'No cards due',
    );
    return '$_temp0';
  }

  @override
  String get reviewCenterPlanPausedHint =>
      'Resume your study plan to continue receiving review cards.';

  @override
  String reviewCenterDailyCap(Object hidden, Object limit) {
    return 'Daily review cap $limit words. $hidden more scheduled for later.';
  }

  @override
  String get reviewCenterTodayDue => 'Due Today';

  @override
  String get reviewCenterReviewQueue => 'Review Queue';

  @override
  String get reviewCenterStartReview => 'Start Review';

  @override
  String get reviewCenterEmpty => 'All review done for now!';

  @override
  String get mistakeBookTitle => 'Mistake Book';

  @override
  String get mistakeBookNoMistakes => 'No lesson mistakes yet';

  @override
  String mistakeBookMistakes(Object count) {
    return '$count lesson mistakes';
  }

  @override
  String mistakeBookMistakesPrefix(Object count) {
    return '$count lesson mistakes';
  }

  @override
  String get mistakeBookSubtitle =>
      'Quiz mistakes and weak custom cards are kept here for later review.';

  @override
  String get mistakeBookFixLabel => 'Fix Mistakes';

  @override
  String get mistakeBookGoPractice => 'Practice a lesson';

  @override
  String get mistakeBookCleared => 'Mistake book cleared';

  @override
  String get mistakeBookClearedMsg =>
      'After quiz mistakes or marking custom word cards as forgotten, review items will appear here.';

  @override
  String get mistakeBookLessonMistakes => 'Lesson Mistakes';

  @override
  String get mistakeBookStartLesson => 'Start a lesson';

  @override
  String get mistakeBookWeakWords => 'Weak Custom Words';

  @override
  String get mistakeBookNoLessonMistakes => 'No mistakes in the last lesson.';

  @override
  String get mistakeBookNoWeakWords => 'No weak custom words yet.';

  @override
  String get labelTargetCET4 => 'CET-4 Core';

  @override
  String get labelTargetCET6 => 'CET-6 Core';

  @override
  String get labelTargetKaoyan => 'Postgrad Core';

  @override
  String get labelTargetBeginner => 'Beginner Basic';

  @override
  String get labelTargetMUET => 'MUET High-Freq';

  @override
  String get labelTargetDailyEnglish => 'Daily English';

  @override
  String get labelTargetBusinessEnglish => 'Business English';

  @override
  String get labelLevelBeginner => 'Beginner';

  @override
  String get labelLevelElementary => 'Elementary';

  @override
  String get labelLevelIntermediate => 'Intermediate';

  @override
  String get labelLevelAdvanced => 'Advanced';

  @override
  String get labelDifficultyEasy => 'Easy';

  @override
  String get labelDifficultyMedium => 'Medium';

  @override
  String get labelDifficultyHard => 'Hard';

  @override
  String get labelStatusNew => 'Not Learned';

  @override
  String get labelStatusPreviewed => 'Previewed';

  @override
  String get labelStatusLearning => 'Learning';

  @override
  String get labelStatusReview => 'Reviewing';

  @override
  String get labelStatusRelearning => 'Relearning';

  @override
  String get labelStatusMastered => 'Mastered';

  @override
  String get labelStatusIgnored => 'Ignored';

  @override
  String get labelQuestionTypeMeaningChoice => 'EN→ZH';

  @override
  String get labelQuestionTypeChineseChoice => 'ZH→EN';

  @override
  String get labelQuestionTypeContextChoice => 'Context';

  @override
  String get labelQuestionTypeImageChoice => 'Image';

  @override
  String get labelQuestionTypeListeningWordChoice => 'Listen→Word';

  @override
  String get labelQuestionTypeListeningMeaningChoice => 'Listen→Meaning';

  @override
  String get labelQuestionTypeSpelling => 'Spelling';

  @override
  String get labelCustomTagCustom => 'Custom';

  @override
  String get labelCustomTagMistake => 'Mistake';

  @override
  String get labelCustomTagCharacter => 'Character';

  @override
  String get labelWordTagAcademic => 'Academic';

  @override
  String get labelWordTagBeginner => 'Beginner';

  @override
  String get labelWordTagBusiness => 'Business';

  @override
  String get labelWordTagCampus => 'Campus';

  @override
  String get labelWordTagDaily => 'Daily';

  @override
  String get labelWordTagExam => 'Exam';

  @override
  String get labelWordTagCET4 => 'CET-4';

  @override
  String get labelWordTagCET6 => 'CET-6';

  @override
  String get labelWordTagKaoyan => 'Postgrad';

  @override
  String get labelWordTagFood => 'Food';

  @override
  String get labelWordTagHealth => 'Health';

  @override
  String get labelWordTagStudy => 'Study';

  @override
  String get labelWordTagTravel => 'Travel';

  @override
  String get labelWordTagWriting => 'Writing';

  @override
  String get labelWordTagDefault => 'Target';

  @override
  String get wordbookTitle => 'Wordbook';

  @override
  String get wordbookSearchHint => 'Search words...';

  @override
  String get wordbookNoResults => 'No matching words found.';

  @override
  String get wordbookAllDifficulty => 'All';

  @override
  String get wordbookWeakDifficulty => 'Weak';

  @override
  String get wordbookCustomWords => 'Custom Words';

  @override
  String get wordbookAddCustom => 'Add Custom';

  @override
  String get wordbookEditCustom => 'Edit Custom Word';

  @override
  String get wordbookWordDetail => 'Word Detail';

  @override
  String get wordbookMeaning => 'Meaning';

  @override
  String get wordbookExample => 'Example';

  @override
  String get wordbookPartOfSpeech => 'Part of Speech';

  @override
  String get wordbookDifficulty => 'Difficulty';

  @override
  String get wordbookMastery => 'Mastery';

  @override
  String get wordbookDeleteConfirm => 'Delete this word?';

  @override
  String get wordbookDeleteMessage => 'This action cannot be undone.';

  @override
  String get wordbookImageBook => 'Image Wordbook';

  @override
  String get wordbookCustomTooltip => 'Custom Words';

  @override
  String wordbookWordsLearned(Object completed, Object total) {
    return 'Learned $completed/$total words';
  }

  @override
  String wordbookTargetWords(Object count) {
    return '$count target words';
  }

  @override
  String wordbookTotalWords(Object count) {
    return '$count words';
  }

  @override
  String wordbookBookCount(Object count) {
    return '$count wordbooks';
  }

  @override
  String wordbookCompletion(Object percent) {
    return 'Completion $percent%';
  }

  @override
  String get wordbookSwitch => 'Switch Wordbook';

  @override
  String get wordbookSwitchDesc =>
      'Current wordbook drives home, learning path, search, training, and review entries.';

  @override
  String get wordbookSwitched => 'Wordbook switched';

  @override
  String get wordbookSwitchFailed => 'Unable to switch wordbook';

  @override
  String get pickerChooseLanguage => 'Choose Language';

  @override
  String get pickerChooseWordbook => 'Choose Wordbook';

  @override
  String get pickerLanguageChinese => 'Chinese (中文)';

  @override
  String get pickerLanguageJapanese => 'Japanese (日本語)';

  @override
  String get pickerComingSoon => 'Coming Soon';

  @override
  String get pickerCurrentBadge => 'Current';

  @override
  String pickerSwitchSuccess(String wordbook) {
    return 'Switched to $wordbook';
  }

  @override
  String get pickerSwitchFailed => 'Unable to switch wordbook right now';

  @override
  String get wordbookTargetSection => 'Target Words';

  @override
  String wordbookTargetDesc(Object count, Object percent) {
    return '$count words · Learning path $percent% complete';
  }

  @override
  String get wordbookNameBeginner => 'Beginner Basic Words';

  @override
  String get wordbookDescBeginner =>
      'High-frequency words for beginners and daily expression.';

  @override
  String get wordbookNameCET4 => 'CET-4 Core Words';

  @override
  String get wordbookDescCET4 =>
      'Core vocabulary for College English Test Band 4.';

  @override
  String get wordbookNameCET6 => 'CET-6 Core Words';

  @override
  String get wordbookDescCET6 =>
      'Core vocabulary for College English Test Band 6.';

  @override
  String get wordbookNameKaoyan => 'Postgrad Core Words';

  @override
  String get wordbookDescKaoyan =>
      'Core vocabulary for postgraduate entrance exams.';

  @override
  String get notificationTitle => 'Notifications';

  @override
  String get notificationMarkAllRead => 'Mark All Read';

  @override
  String get notificationCenter => 'Message Center';

  @override
  String get notificationCenterDesc =>
      'Learning reminders, review due, check-in, and activity messages are gathered here.';

  @override
  String notificationUnreadCount(Object count) {
    return '$count unread messages';
  }

  @override
  String get notificationFilterAll => 'All';

  @override
  String get notificationFilterUnread => 'Unread';

  @override
  String get notificationFilterLearning => 'Learning';

  @override
  String get notificationFilterActivity => 'Activity';

  @override
  String get notificationEmptyTitle => 'No matching messages';

  @override
  String get notificationEmptyUnread => 'No unread messages right now.';

  @override
  String get notificationEmptyAll =>
      'After completing learning and review, learning reminders and activity messages will continue to be gathered here.';

  @override
  String get notificationBackHome => 'Back to Home';

  @override
  String get notificationTypeLearningReminder => 'Learning Reminder';

  @override
  String get notificationTypeReviewDue => 'Review Due';

  @override
  String get notificationTypeCheckIn => 'Check-in Reminder';

  @override
  String get notificationTypeActivity => 'Activity Message';

  @override
  String get notificationLearningReminderTitle =>
      'Today\'s study plan is waiting';

  @override
  String notificationLearningReminderBody(int dailyGoal) {
    return 'Today\'s goal: $dailyGoal new words. Start with your current wordbook.';
  }

  @override
  String notificationReviewDueTitle(int dueCount) {
    return '$dueCount words due for review';
  }

  @override
  String get notificationReviewDueBody =>
      'Clear your review queue first — missed words move to the reinforcement stage.';

  @override
  String get notificationCheckInTitle => 'You haven\'t checked in today';

  @override
  String get notificationCheckInBody =>
      'Tap check-in on the Discover page to unlock the claimable task.';

  @override
  String get notificationActivityTitle => 'Discover point tasks refreshed';

  @override
  String get notificationActivityBody =>
      'Earn XP after finishing new words, reviews, and clearing missed words.';

  @override
  String get notificationLotteryTitle => 'Lottery result';

  @override
  String notificationLotteryBody(String prizeName) {
    return 'You won \"$prizeName\" — added to your assets.';
  }

  @override
  String get osNotificationStudyReminderTitle => 'Your study tasks are ready';

  @override
  String get osNotificationStudyReminderBody =>
      'Finish new words, reviews and check-in to keep your streak going.';

  @override
  String get osNotificationReviewDueBody =>
      'Clear your review queue, then start today\'s new words.';

  @override
  String get osNotificationChannelName => 'Study reminders';

  @override
  String get osNotificationChannelDescription =>
      'Study reminders, review-due and check-in alerts';

  @override
  String get studyNewStudy => 'New Study';

  @override
  String get studyReviewOnly => 'Review Only';

  @override
  String get studyStartSession => 'Start Session';

  @override
  String get studySessionComplete => 'Session Complete';

  @override
  String studyWordsLeft(Object count) {
    return '$count words left';
  }

  @override
  String get studyPlanLoginRequired =>
      'Please log in before setting up a study plan.';

  @override
  String get studyPlanSave => 'Save Study Plan';

  @override
  String get studyPlanSettings => 'Study Plan Settings';

  @override
  String get studyPlanSettingsDesc =>
      'Manage current wordbook, daily tasks, review rhythm, and reminder time.';

  @override
  String get studyPlanViewWords => 'View Full Wordbook';

  @override
  String get studyPlanDailyNew => 'Daily New Words';

  @override
  String get studyPlanDailyNewHint => 'Recommended 5-30 words, max 200.';

  @override
  String get studyPlanReminderTime => 'Study Reminder Time';

  @override
  String get studyPlanResume => 'Resume Plan';

  @override
  String get studyPlanPause => 'Pause Plan';

  @override
  String get studyPlanReset => 'Reset Plan';

  @override
  String get studyPlanResetConfirm => 'Confirm reset study plan?';

  @override
  String get studyPlanResetDesc =>
      'Reset will clear current wordbook learning path progress, and reset custom word mastery, correct/wrong counts, and review times; review queue will be regenerated. This affects learning progress and review schedule.';

  @override
  String get studyPlanCancel => 'Cancel';

  @override
  String get studyPlanConfirm => 'Confirm Reset';

  @override
  String get studyPlanSaved => 'Study plan saved.';

  @override
  String get studyPlanSaveFailed => 'Unable to save plan.';

  @override
  String get studyPlanResumed => 'Study plan resumed.';

  @override
  String get studyPlanPaused =>
      'Study plan paused. Today\'s reminders and task entries will be temporarily closed.';

  @override
  String get studyPlanPauseFailed => 'Unable to update plan status.';

  @override
  String get studyPlanResetDone => 'Study plan reset.';

  @override
  String get studyPlanResetFailed => 'Unable to reset plan.';

  @override
  String get studyPlanEnterNumber => 'Please enter a number';

  @override
  String studyPlanNumberRange(Object max, Object min) {
    return 'Range must be $min-$max';
  }

  @override
  String studyPlanDaysLeft(Object count) {
    return '$count days left';
  }

  @override
  String get studyPlanActive => 'Active';

  @override
  String get studyPlanPausedLabel => 'Paused';

  @override
  String get aiLearningTitle => 'AI Learning';

  @override
  String get aiLearningSubtitle => 'Reading, writing, and practice';

  @override
  String get aiLearningComingSoon => 'AI learning features coming soon.';

  @override
  String get aiLearningDesc =>
      'Explain grammar, distinguish word meanings, generate context; formal learning records are still updated by quiz results.';

  @override
  String get aiLearningTooltip => 'Q&A';

  @override
  String get aiLearningPillError => 'Error Explanation';

  @override
  String get aiLearningPillNoKey => 'No Client Key Required';

  @override
  String get aiLearningCurrentWord => 'Current Word';

  @override
  String get aiLearningToolsTitle => 'Tool List';

  @override
  String get aiLearningToolsSubtitle =>
      'First version focuses on long sentence analysis and Q&A; writing correction comes later.';

  @override
  String get aiLearningToolAiQA => 'AI Q&A';

  @override
  String get aiLearningToolAiQADesc =>
      'Answer questions about word meaning, grammar, and expression naturalness based on current words, examples, and learning goals.';

  @override
  String get aiLearningToolAiAnalysis => 'AI Long Sentence Analysis';

  @override
  String get aiLearningToolAiAnalysisDesc =>
      'Extract main clauses, divide subordinate clauses, explain modifiers and key words, and provide natural Chinese translation.';

  @override
  String get aiLearningToolAiWriting => 'AI Writing Correction';

  @override
  String get aiLearningToolAiWritingDesc =>
      'Select exam type, enter topic and body text, output total score, itemized scores, and paragraph-by-paragraph revision suggestions.';

  @override
  String get aiLearningToolCloze => 'Today\'s Word Cloze';

  @override
  String get aiLearningToolClozeDesc =>
      'Generate short passages based on today\'s new words, mistake words, or this week\'s weak words, with 5 to 10 target words blanked out.';

  @override
  String get aiLearningToolConfusion => 'Confusable Words';

  @override
  String get aiLearningToolConfusionDesc =>
      'Explain usage scenarios of near-synonyms or confusable words like affect/effect based on mistake records.';

  @override
  String get aiLearningToolSentence => 'Sentence Generation & Rewrite';

  @override
  String get aiLearningToolSentenceDesc =>
      'Generate more natural example sentences based on exam goals, with one-click add to notes or wordbook.';

  @override
  String get aiLearningStatusSoon => 'Coming Soon';

  @override
  String get aiLearningStatusLater => 'Coming Later';

  @override
  String get aiLearningStatusPlanning => 'In Planning';

  @override
  String get questTitle => 'Quests';

  @override
  String get questDailyQuests => 'Daily Quests';

  @override
  String get questProgress => 'Progress';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search words, phrases, examples...';

  @override
  String get searchNoResults => 'No results found.';

  @override
  String get searchRecent => 'Recent';

  @override
  String get searchStartTitle => 'Enter a keyword to start searching';

  @override
  String get searchStartMessage =>
      'Search English words, phrases, Chinese meanings, example snippets, and custom words.';

  @override
  String get searchNoResultsTitle => 'No results found';

  @override
  String get searchNoResultsMessage =>
      'Try the full word library, or add a personal word card.';

  @override
  String get searchFieldLabel =>
      'Search words, phrases, Chinese meanings, or example snippets';

  @override
  String searchScopeSummary(Object allWordBooksLabel, Object currentBookTitle) {
    return 'Scope: $currentBookTitle / $allWordBooksLabel';
  }

  @override
  String get searchCurrentWordbookScope => 'Current wordbook';

  @override
  String get searchAllWordbooksScope => 'Full library';

  @override
  String get searchCurrentPlan => 'Current plan';

  @override
  String get customWordsMyCards => 'My word cards';

  @override
  String get customWordsMyCardsSubtitle =>
      'Create, search, filter, edit, and review your personal word library.';

  @override
  String customWordsCardCount(Object count) {
    return '$count cards';
  }

  @override
  String get customWordsSearchLabel => 'Search words, meanings, or tags';

  @override
  String get customWordsNoMatchTitle => 'No matching word cards';

  @override
  String get customWordsNoMatchMessage =>
      'Add a personal word card, or adjust the search filters.';

  @override
  String get customWordsAddCard => 'Add custom word card';

  @override
  String customWordsDeleteTitle(Object word) {
    return 'Delete \"$word\"?';
  }

  @override
  String get customWordsDeleteContent =>
      'This also deletes this personal word card and its review plan.';

  @override
  String get customWordsEditTitle => 'Edit word';

  @override
  String get customWordsAddTitle => 'Add word';

  @override
  String get customWordsFieldWord => 'Word';

  @override
  String get customWordsFieldMeaning => 'Meaning';

  @override
  String get customWordsFieldExample => 'Example';

  @override
  String get customWordsFieldNote => 'Note';

  @override
  String get customWordsFieldTag => 'Tag';

  @override
  String get customWordsSaveEdit => 'Save changes';

  @override
  String get customWordsCreate => 'Create word';

  @override
  String get customWordsSaveFailed => 'Unable to save this word for now';

  @override
  String get customWordsSaved => 'Word saved';

  @override
  String get customWordsDifficulty => 'Difficulty';

  @override
  String get commonRequired => 'Required';

  @override
  String customWordsDeleteFailed(Object word) {
    return 'Unable to delete $word right now';
  }

  @override
  String customWordsDeleted(Object word) {
    return 'Deleted $word';
  }

  @override
  String get wordbookWordNotFound => 'Word not found';

  @override
  String get wordbookFavorite => 'Favorite';

  @override
  String get wordbookFavorited => 'Favorited';

  @override
  String get wordbookFavoriteRemoved => 'Removed from favorites';

  @override
  String get wordbookAddToCustomWords => 'Add to custom words';

  @override
  String get wordbookRemoveCustomWord => 'Remove from custom words';

  @override
  String get wordbookAddedToCustomWords => 'Added to custom words';

  @override
  String get wordbookRemovedFromCustomWords => 'Removed from custom words';

  @override
  String get wordbookResumeLearning => 'Resume learning';

  @override
  String get wordbookIgnoreEasy => 'Ignore as too easy';

  @override
  String get wordbookLearningResumed => 'Learning resumed';

  @override
  String get wordbookIgnored =>
      'Ignored and excluded from future review queues';

  @override
  String get wordbookUpdateTargetFailed =>
      'Unable to update target word right now';

  @override
  String get wordbookCurrentPlan => 'In current plan';

  @override
  String get wordbookHighFrequencyDefinition => 'High-frequency exam meaning';

  @override
  String wordbookUkPhonetic(Object phonetic) {
    return 'UK /$phonetic/';
  }

  @override
  String wordbookUsPhonetic(Object phonetic) {
    return 'US /$phonetic/';
  }

  @override
  String get wordbookBilingualDefinitions => 'Chinese and English definitions';

  @override
  String get wordbookChineseDefinitions => 'Chinese definitions';

  @override
  String get wordbookEnglishDefinitions => 'English definitions';

  @override
  String get wordbookMalayDefinitions => 'Malay definitions';

  @override
  String get wordbookHighFrequency => 'High frequency';

  @override
  String get wordbookContextExamples => 'Context examples';

  @override
  String wordbookMasteryLevel(Object level) {
    return 'Mastery $level/5';
  }

  @override
  String get reviewStudyManageQueue => 'Manage review queue';

  @override
  String get reviewStudyTodayTitle => 'Today\'s review';

  @override
  String get reviewStudyTodaySubtitle =>
      'Recall first, then reveal the answer; missed cards return later in this round for reinforcement.';

  @override
  String get reviewStudyLeaveTitle => 'Leave review?';

  @override
  String get reviewStudyLeaveContent =>
      'Completed cards have been saved; unfinished cards will stay in the review queue.';

  @override
  String get reviewStudyKeepReviewing => 'Keep reviewing';

  @override
  String get reviewStudyReinforced => 'This reinforcement round is complete';

  @override
  String get reviewStudyRememberedMessage =>
      'Remembered. The review interval has been extended.';

  @override
  String get reviewStudyNeedsReinforcementMessage =>
      'Marked for reinforcement. Practice it again later.';

  @override
  String get reviewStudyReinforce => 'Add to reinforcement queue';

  @override
  String get reviewStudyCompleteTitle => 'Today\'s review complete';

  @override
  String get reviewStudyCompleteMessage =>
      'Next review times have been updated for this round.';

  @override
  String get reviewStudyRecallHint =>
      'Recall the Chinese meaning from the English word first. If you remember it, move on; if not, reveal the knowledge card.';

  @override
  String reviewStudyNextReview(Object due) {
    return 'Next review: $due';
  }

  @override
  String get reviewStudyHiddenHint =>
      'Correct answers continue smoothly; wrong answers reveal the knowledge card and return later in this round.';

  @override
  String aiWordSupportDesc(Object word) {
    return 'Ask about $word usage, grammar, synonym differences, and example breakdowns.';
  }

  @override
  String aiWordSupportWithExampleDesc(Object word) {
    return 'Send $word and the current example to ask about usage, grammar, synonym differences, and example breakdowns.';
  }

  @override
  String get helpFaqReviewScheduleQ => 'How is review time scheduled?';

  @override
  String get helpFaqReviewScheduleA =>
      'Each word moves between mastery levels 0-5. Higher mastery means a longer interval before the next review.';

  @override
  String get helpFaqCustomWordsQ => 'Can I add my own words?';

  @override
  String get helpFaqCustomWordsA =>
      'Yes. Open the wordbook or custom words page, then tap add to create a personal word card.';

  @override
  String get helpFaqAiTutorQ => 'What can the AI tutor do?';

  @override
  String get helpFaqAiTutorA =>
      'It can explain words, grammar, and mistakes, and suggest examples for further practice.';

  @override
  String get helpContactSupport => 'Contact support';

  @override
  String get aboutVersion => 'LinguaQuest · Version 1.0.0';

  @override
  String get aboutIntro =>
      'LinguaQuest brings visual word cards, learning paths, spaced review, XP, streaks, and personal word cards into a mobile-first English learning app.';

  @override
  String get aboutGoalTitle => 'Project goal';

  @override
  String get aboutGoalSubtitle =>
      'Help learners build a daily English study habit through short lessons, mistake repair, and visible progress.';

  @override
  String get aboutTeamTitle => 'Development team';

  @override
  String get aboutTeamSubtitle =>
      'ASM2 Mobile team. Focused on a mobile-first English learning experience.';

  @override
  String get aboutCoreTitle => 'Core experience';

  @override
  String get aboutCoreSubtitle =>
      'Goal planning, visual vocabulary, quiz practice, review scheduling, and personal word cards.';

  @override
  String get aboutPrivacyTitle => 'Privacy';

  @override
  String get aboutPrivacySubtitle =>
      'Custom words and learning records belong only to the signed-in user.';

  @override
  String get communityPostCheckinTitle =>
      'Today\'s check-in: Reviewed 18 words in 12 minutes';

  @override
  String get communityPostCheckinTag => 'Daily Check-in';

  @override
  String get communityPostCheckinBody =>
      'Mistakes were mostly synonyms. Tomorrow I\'ll start with the confusing words challenge in training.';

  @override
  String get communityPostAbstractTitle =>
      'How to remember the word \'abstract\'?';

  @override
  String get communityPostMistakeTag => 'Mistake Discussion';

  @override
  String get communityPostAbstractBody =>
      '\"abstract\" in academic contexts often does not mean \"not concrete\"; context matters.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get languageSetting => 'Language';

  @override
  String luckyDrawCostLine(Object cost) {
    return 'Spend $cost XP per draw';
  }

  @override
  String luckyDrawBalanceHint(Object xp) {
    return 'Current balance $xp XP; prizes include avatar frames, profile backgrounds, badges, titles, card skins, and consolation fragments.';
  }

  @override
  String luckyDrawInventoryCount(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items in stock',
      one: '1 item in stock',
    );
    return '$_temp0';
  }

  @override
  String get luckyDrawNoBoost => 'No learning boost';

  @override
  String get luckyDrawNow => 'Draw now';

  @override
  String get luckyDrawInsufficient => 'Not enough XP — finish tasks first';

  @override
  String luckyDrawShortfall(Object shortfall) {
    return '$shortfall XP to go. Finish new study, review, or mistake cleanup to earn points.';
  }

  @override
  String get luckyDrawFailed => 'Draw failed, please try again later';

  @override
  String get luckyDrawSuccessTitle => 'Draw successful';

  @override
  String luckyDrawReward(Object name) {
    return 'You got: $name';
  }

  @override
  String luckyDrawDeducted(Object balance, Object cost) {
    return 'Deducted $cost XP, $balance XP remaining.';
  }

  @override
  String get luckyDrawKeepLooking => 'Keep looking';

  @override
  String get luckyDrawViewAssets => 'View my assets';

  @override
  String get luckyDrawPoolLoading =>
      'Prize pool loading: avatar frames, profile backgrounds, learning badges, training titles, card skins, consolation fragments.';

  @override
  String get profileAssetsTitle => 'My Assets';

  @override
  String get profileAssetsSubtitle =>
      'Decorative assets won from draws are for display only and don\'t affect learning scores.';

  @override
  String get profileAssetsEmpty => 'No Assets Yet';

  @override
  String profileAssetMeta(Object category, Object fragments, Object quantity) {
    return '$category · Qty $quantity · Fragments $fragments';
  }

  @override
  String get lotteryCategoryAvatarFrame => 'Avatar Frame';

  @override
  String get lotteryCategoryProfileBackground => 'Profile Background';

  @override
  String get lotteryCategoryBadge => 'Learning Badge';

  @override
  String get lotteryCategoryTitle => 'Training Title';

  @override
  String get lotteryCategoryCardSkin => 'Card Skin';

  @override
  String get lotteryCategoryFragment => 'Consolation Fragment';

  @override
  String get lotteryCategoryDefault => 'Decorative Asset';

  @override
  String get lotteryRarityRare => 'Rare';

  @override
  String get lotteryRarityUncommon => 'Advanced';

  @override
  String get lotteryRarityCommon => 'Common';

  @override
  String get lotteryRarityComfort => 'Comfort';

  @override
  String get languageChinese => '中文';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get languageEnglish => 'English';

  @override
  String get wordKnowledgeTitle => 'Word breakdown';

  @override
  String get wordKnowledgeCollocations => 'Collocations';

  @override
  String get wordKnowledgeSynAnt => 'Synonyms / Antonyms';

  @override
  String get wordKnowledgeFamily => 'Word family';

  @override
  String get wordKnowledgeRoots => 'Roots & affixes';

  @override
  String get pronunciationAccentUk => 'UK';

  @override
  String get pronunciationAccentUs => 'US';

  @override
  String pronunciationAnnounce(String accent, String word) {
    return '$accent $word';
  }

  @override
  String pronunciationPlaying(String accent, String word) {
    return '$accent: $word';
  }

  @override
  String pronunciationUnavailable(String accent) {
    return '$accent audio unavailable';
  }

  @override
  String pronunciationFailedRetry(String accent) {
    return '$accent playback failed, tap to retry';
  }

  @override
  String pronunciationLoading(String accent) {
    return '$accent loading';
  }

  @override
  String pronunciationRetry(String accent) {
    return '$accent retry';
  }

  @override
  String get dueNow => 'Due now';

  @override
  String dueInDays(int count) {
    return 'In $count days';
  }

  @override
  String dueInHours(int count) {
    return 'In $count hours';
  }

  @override
  String dueInMinutes(int count) {
    return 'In $count minutes';
  }

  @override
  String get languageMapTitle => 'Choose Language';

  @override
  String get languageMapSelectPrompt =>
      'Tap a country to choose the language you want to learn.';

  @override
  String get languageMapChinese => 'Chinese (中文)';

  @override
  String languageMapConfirm(String language) {
    return 'Learn $language';
  }

  @override
  String languageMapSelected(String language) {
    return 'Now learning $language';
  }

  @override
  String languageMapComingSoon(String language) {
    return '$language — coming soon';
  }

  @override
  String get aboutCompanyName => 'LinguaQuest';

  @override
  String get aboutCompanyAddress =>
      'Xiamen University Malaysia, Bandar Sunsuria, 43900 Sepang, Selangor, Malaysia (virtual)';

  @override
  String get aboutCompanyDescription =>
      'Our virtual campus where LinguaQuest is built.';

  @override
  String get aiLearningStatusAvailable => 'Available';

  @override
  String get aiExplainWithAi => 'Explain with AI';

  @override
  String get aiErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get aiEmptyChat =>
      'Ask anything about Chinese — meanings, grammar, or usage.';

  @override
  String get aiQuestionHint => 'Type your question about Chinese...';

  @override
  String get aiEmptyAnalysis =>
      'Paste a Chinese sentence to see its structure broken down.';

  @override
  String get aiEmptyCloze =>
      'Enter a word to generate a fill-in-the-blank exercise.';

  @override
  String get aiEmptyWriting =>
      'Paste your essay and pick an exam type to get scored feedback.';

  @override
  String get achievementsScreenTitle => 'Achievements';

  @override
  String get achievementsHeaderTitle => 'Your Achievements';

  @override
  String achievementsUnlockedCount(int unlocked, int total) {
    return '$unlocked / $total unlocked';
  }

  @override
  String get achievementUnlockedLabel => 'Unlocked';

  @override
  String get achievementLearn100Title => 'Century Scholar';

  @override
  String get achievementLearn100Desc => 'Master 100 words';

  @override
  String get achievementQuizPerfectTitle => 'Flawless Run';

  @override
  String get achievementQuizPerfectDesc =>
      'Complete a quiz session with 100% accuracy (4+ questions)';

  @override
  String get achievementFirstListeningTitle => 'First Echo';

  @override
  String get achievementFirstListeningDesc =>
      'Complete your first listening exercise';

  @override
  String get achievementFirstMapLanguageTitle => 'Cartographer';

  @override
  String get achievementFirstMapLanguageDesc =>
      'Pick a language from the language map';

  @override
  String get assetInventoryTitle => 'My Assets';

  @override
  String get assetInventoryEmpty =>
      'No assets yet. Try your luck in the Lucky Draw!';

  @override
  String assetInventoryTotalOwned(int count) {
    return '$count items owned';
  }

  @override
  String assetInventoryTotalFragments(int count) {
    return '$count fragments';
  }

  @override
  String assetInventoryQuantityBadge(int count) {
    return '×$count';
  }

  @override
  String get luckyDrawViewMyAssets => 'View my assets';

  @override
  String get analyticsReportTitle => 'Learning report';

  @override
  String get analyticsReportSubtitle =>
      'Your progress, charts, and focus areas';

  @override
  String analyticsScopeLabel(Object scope) {
    return 'Scope: $scope';
  }

  @override
  String get analyticsXpTrendTitle => 'XP trend';

  @override
  String get analyticsAbilityTitle => 'Ability dimensions';

  @override
  String get analyticsModalityTitle => 'Accuracy by type';

  @override
  String get analyticsMasteryTitle => 'Word mastery';

  @override
  String get analyticsDetailTitle => 'Detailed stats';

  @override
  String get analyticsFocusTitle => 'Recommended practice';

  @override
  String get analyticsReviewLoad => 'Review load';

  @override
  String get analyticsWeekXp => 'This week XP';

  @override
  String get analyticsTodayXp => 'Today XP';

  @override
  String get analyticsWeakWords => 'Weak words';

  @override
  String get analyticsDueNow => 'Due now';

  @override
  String get analyticsMasteryNew => 'New';

  @override
  String get analyticsMasteryLearning => 'Learning';

  @override
  String get analyticsMasteryMastered => 'Mastered';

  @override
  String get analyticsDimMeaningRecognition => 'Recognition';

  @override
  String get analyticsDimMeaningRecall => 'Recall';

  @override
  String get analyticsDimContext => 'Context';

  @override
  String get analyticsDimListening => 'Listening';

  @override
  String get analyticsDimSpelling => 'Spelling';

  @override
  String get analyticsModalityMeaning => 'Meaning';

  @override
  String get analyticsModalityListening => 'Listening';

  @override
  String get analyticsModalitySpelling => 'Spelling';

  @override
  String get analyticsModalityContext => 'Context';

  @override
  String get analyticsTopErrors => 'Top error types';

  @override
  String get readingTitle => 'Reading';

  @override
  String get readingDiscoverEntry => 'Reading';

  @override
  String get readingRecommended => 'Recommended for you';

  @override
  String get readingAllArticles => 'All articles';

  @override
  String readingArticlesForTheme(Object theme) {
    return '$theme articles';
  }

  @override
  String get readingFilterLevel => 'Level';

  @override
  String get readingFilterTheme => 'Theme';

  @override
  String get readingFilterAll => 'All';

  @override
  String readingMinutes(int count) {
    return '$count min';
  }

  @override
  String get readingEmpty => 'No articles for this filter yet.';

  @override
  String get readingProgressInProgress => 'In progress';

  @override
  String get readingProgressDone => 'Read';

  @override
  String get readingToggleTranslation => 'Translation';

  @override
  String get readingToggleReading => 'Reading';

  @override
  String get readingParagraphAudio => 'Play';

  @override
  String get readingTapWordHint => 'Tap a highlighted word for its meaning.';

  @override
  String get readingWordAddToVocab => 'Add to vocab notebook';

  @override
  String get readingWordAdded => 'Added to vocab notebook';

  @override
  String get readingComprehensionCta => 'Start comprehension';

  @override
  String get readingComprehensionSoon =>
      'Comprehension questions arrive in the next phase.';

  @override
  String get readingThemeCampus => 'Campus';

  @override
  String get readingThemeLife => 'Life';

  @override
  String get readingThemeTravel => 'Travel';

  @override
  String get readingThemeTech => 'Tech';

  @override
  String get readingThemeCulture => 'Culture';

  @override
  String get readingThemeNews => 'News';

  @override
  String get readingThemeBusiness => 'Business';

  @override
  String get readingThemeExam => 'Exam';

  @override
  String get readingToggleHighlight => 'Highlight';

  @override
  String get readingLegendTitle => 'Word highlights';

  @override
  String get readingClassKey => 'Key word';

  @override
  String get readingClassUnknown => 'Needs review';

  @override
  String get readingClassNew => 'New';

  @override
  String get readingClassKnown => 'Known';

  @override
  String get readingComprehensionStart => 'Start comprehension';

  @override
  String get readingComprehensionTitle => 'Comprehension';

  @override
  String readingComprehensionQuestion(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String get readingComprehensionNext => 'Next';

  @override
  String get readingComprehensionFinish => 'Finish';

  @override
  String get readingComprehensionResultTitle => 'Comprehension complete';

  @override
  String readingComprehensionScore(int correct, int total) {
    return '$correct / $total correct';
  }

  @override
  String readingComprehensionAccuracy(int pct) {
    return 'Accuracy $pct%';
  }

  @override
  String get readingComprehensionDone => 'Done';

  @override
  String get readingComprehensionEmpty =>
      'No comprehension questions for this article yet.';

  @override
  String get readingAnalyticsTitle => 'Reading';

  @override
  String get readingAnalyticsArticlesRead => 'Articles read';

  @override
  String get readingAnalyticsAccuracy => 'Comprehension accuracy';

  @override
  String get readingAnalyticsThemes => 'By theme';

  @override
  String get readingAnalyticsEmpty =>
      'Complete a reading comprehension to see stats here.';

  @override
  String get readingExplainTooltip => 'Explain with AI';

  @override
  String get readingExplainTitle => 'AI explanation';

  @override
  String get readingExplainLoading => 'Explaining this paragraph...';

  @override
  String get readingExplainGist => 'Gist';

  @override
  String get readingExplainKeyWords => 'Key words';

  @override
  String get readingExplainGrammar => 'Grammar points';

  @override
  String get readingExplainStructure => 'Sentence structure';

  @override
  String get readingExplainTranslation => 'Translation';

  @override
  String get readingExplainPractice => 'Practice';
}
