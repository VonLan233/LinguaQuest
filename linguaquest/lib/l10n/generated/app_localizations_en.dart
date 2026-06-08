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
  String get discoverCommunityPostsSubtitle =>
      'Learning check-ins and mistake discussions displayed here.';

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
  String get trainingTitle => 'Training Ground';

  @override
  String get trainingSubtitle =>
      'Timed tests, skill drills, and leaderboard all here.';

  @override
  String get trainingLeaderboard => 'Leaderboard';

  @override
  String get trainingTimedTests => 'Timed Tests';

  @override
  String get trainingTimedTestsSubtitle =>
      'Campus word packs and speed challenges are in the training ground, not the new learning entry.';

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
  String get trainingSpelling => 'Word Spelling';

  @override
  String get trainingSpellingDesc =>
      'See Chinese, hear pronunciation, or read sentence cloze, then type the English word.';

  @override
  String get trainingPassageCloze => 'Passage Cloze';

  @override
  String get trainingPassageClozeDesc =>
      'Generate passages with today\'s vocabulary, linking memorization and reading comprehension.';

  @override
  String get trainingListening => 'Listening Sprint';

  @override
  String get trainingListeningDesc =>
      'Listen to pronunciation, then select the word or meaning. Response time affects score.';

  @override
  String get trainingDueWords => 'Due Words';

  @override
  String get trainingWeakWords => 'Weak Words';

  @override
  String get trainingComboTarget => 'Combo Target';

  @override
  String get trainingEnterCustomWords => 'Go to Custom Words';

  @override
  String get learningPathTitle => 'Learning Path';

  @override
  String get learningPathSubtitle =>
      'Shows wordbook progress only. Formal new learning and review use the two separate entries on Home.';

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
  String get mistakeBookSubtitle =>
      'Quiz mistakes and weak custom cards are kept here for later review.';

  @override
  String get mistakeBookFixLabel => 'Fix Mistakes';

  @override
  String get mistakeBookCleared => 'Mistake book cleared';

  @override
  String get mistakeBookClearedMsg =>
      'After quiz mistakes or marking custom word cards as forgotten, review items will appear here.';

  @override
  String get mistakeBookLessonMistakes => 'Lesson Mistakes';

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
  String get aiLearningTitle => 'AI Learning';

  @override
  String get aiLearningSubtitle =>
      'AI-powered reading, writing, and practice exercises.';

  @override
  String get aiLearningComingSoon => 'AI learning features coming soon.';

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
