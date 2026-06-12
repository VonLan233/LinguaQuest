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
      'Short lessons, visual memory cards, and smart review help you steadily build English vocabulary.';

  @override
  String get onboardingTagline => 'Level up daily like a game';

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
  String get homeStartLearning => 'Start Today\'s Learning';

  @override
  String get homeReviewOnly => 'Review Only';

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
  String get profileLearner => 'Learner';

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
  String get profileStreakDays => 'days streak';

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
  String get trainingTimedTests => 'Timed Tests';

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
  String get trainingSpecialDrills => 'Skill Drills';

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
  String get trainingDueWords => 'Due Words';

  @override
  String get trainingWeakWords => 'Weak Words';

  @override
  String get trainingComboTarget => 'Combo Target';

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
    return 'Choose the Chinese meaning of \"$word\" quickly';
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
    return 'Choose the Chinese meaning of \"$word\"';
  }

  @override
  String trainingExplanationMeaningChoice(Object meaning, Object word) {
    return 'This question checks $word: $meaning.';
  }

  @override
  String trainingPromptChineseSpelling(Object meaning) {
    return 'Spell the English word from Chinese: $meaning';
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
  String get labelTargetIELTS => 'IELTS Core';

  @override
  String get labelTargetTOEFL => 'TOEFL High-Freq';

  @override
  String get labelTargetGRE => 'GRE High-Freq';

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
  String get labelWordTagIELTS => 'IELTS';

  @override
  String get labelWordTagTOEFL => 'TOEFL';

  @override
  String get labelWordTagGRE => 'GRE';

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
  String get wordbookNameIELTS => 'IELTS Core Words';

  @override
  String get wordbookDescIELTS =>
      'High-frequency academic words for IELTS reading, listening, and writing.';

  @override
  String get wordbookNameTOEFL => 'TOEFL High-Frequency Words';

  @override
  String get wordbookDescTOEFL =>
      'Academic vocabulary and campus expressions for TOEFL.';

  @override
  String get wordbookNameGRE => 'GRE High-Frequency Words';

  @override
  String get wordbookDescGRE =>
      'Advanced words commonly seen in GRE reading and fill-in-the-blank.';

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
  String get studyPlanDailyReview => 'Daily Review Limit';

  @override
  String get studyPlanDailyReviewHint =>
      'Review queue beyond limit will be kept for later dates.';

  @override
  String get studyPlanTargetDate => 'Exam/Target Completion Date';

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
  String get studyPlanInvalidDate =>
      'Target completion date cannot be earlier than today.';

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
  String get questAchievements => 'Achievements';

  @override
  String get questLeaderboard => 'Leaderboard';

  @override
  String get questClassMode => 'Class Mode';

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
      'How to remember \"abstract\" in IELTS reading?';

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
  String get languageChinese => '中文';

  @override
  String get languageMalay => 'Bahasa Melayu';

  @override
  String get languageEnglish => 'English';
}
