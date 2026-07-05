import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ms.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ms'),
    Locale('zh'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest'**
  String get appTitle;

  /// No description provided for @appSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Build vocabulary with short lessons and smart review.'**
  String get appSubtitle;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get tabTraining;

  /// No description provided for @tabAiLearning.
  ///
  /// In en, this message translates to:
  /// **'AI Learn'**
  String get tabAiLearning;

  /// No description provided for @tabDiscover.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get tabDiscover;

  /// No description provided for @tabProfile.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get tabProfile;

  /// No description provided for @commonRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get commonRegister;

  /// No description provided for @commonLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get commonLogin;

  /// No description provided for @commonSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get commonSettings;

  /// No description provided for @commonTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get commonTheme;

  /// No description provided for @commonDailyReminder.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get commonDailyReminder;

  /// No description provided for @commonStudyPlan.
  ///
  /// In en, this message translates to:
  /// **'Study Plan'**
  String get commonStudyPlan;

  /// No description provided for @commonWordbook.
  ///
  /// In en, this message translates to:
  /// **'Wordbook'**
  String get commonWordbook;

  /// No description provided for @commonCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Custom Words'**
  String get commonCustomWords;

  /// No description provided for @commonMistakeBook.
  ///
  /// In en, this message translates to:
  /// **'Mistake Book'**
  String get commonMistakeBook;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonReview.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get commonReview;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get commonCheck;

  /// No description provided for @commonLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get commonLeave;

  /// No description provided for @commonExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get commonExit;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @commonSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get commonSubmit;

  /// No description provided for @commonProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get commonProfile;

  /// No description provided for @commonLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get commonLogout;

  /// No description provided for @commonXP.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get commonXP;

  /// No description provided for @commonDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get commonDay;

  /// No description provided for @commonDaysLabel.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get commonDaysLabel;

  /// No description provided for @commonWords.
  ///
  /// In en, this message translates to:
  /// **'words'**
  String get commonWords;

  /// No description provided for @commonLessons.
  ///
  /// In en, this message translates to:
  /// **'lessons'**
  String get commonLessons;

  /// No description provided for @commonNew.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get commonNew;

  /// No description provided for @commonDue.
  ///
  /// In en, this message translates to:
  /// **'due'**
  String get commonDue;

  /// No description provided for @commonMinutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get commonMinutes;

  /// No description provided for @commonLesson.
  ///
  /// In en, this message translates to:
  /// **'lesson'**
  String get commonLesson;

  /// No description provided for @commonMastery.
  ///
  /// In en, this message translates to:
  /// **'mastery'**
  String get commonMastery;

  /// No description provided for @commonMasteryOutOf.
  ///
  /// In en, this message translates to:
  /// **'/5'**
  String get commonMasteryOutOf;

  /// No description provided for @commonAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'Already added'**
  String get commonAlreadyAdded;

  /// No description provided for @commonWrongPrefix.
  ///
  /// In en, this message translates to:
  /// **'Wrong '**
  String get commonWrongPrefix;

  /// No description provided for @commonTimesSuffix.
  ///
  /// In en, this message translates to:
  /// **' times'**
  String get commonTimesSuffix;

  /// No description provided for @commonViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get commonViewAll;

  /// No description provided for @commonView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get commonView;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterTitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginTitle;

  /// No description provided for @authCreateProfile.
  ///
  /// In en, this message translates to:
  /// **'Create Learning Profile'**
  String get authCreateProfile;

  /// No description provided for @authCreateProfileSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set up your account, then choose your goals and daily pace.'**
  String get authCreateProfileSubtitle;

  /// No description provided for @authStep1of2.
  ///
  /// In en, this message translates to:
  /// **'Step 1 / 2'**
  String get authStep1of2;

  /// No description provided for @authStep2of2.
  ///
  /// In en, this message translates to:
  /// **'Step 2 / 2'**
  String get authStep2of2;

  /// No description provided for @authNickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get authNickname;

  /// No description provided for @authNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter nickname'**
  String get authNicknameHint;

  /// No description provided for @authEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'name@example.com'**
  String get authEmailHint;

  /// No description provided for @authPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPassword;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Set password'**
  String get authPasswordHint;

  /// No description provided for @authNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get authNameRequired;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get authPasswordRequired;

  /// No description provided for @authContinueToGoal.
  ///
  /// In en, this message translates to:
  /// **'Continue to Goal Setup'**
  String get authContinueToGoal;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get authHaveAccount;

  /// No description provided for @authAccountCreated.
  ///
  /// In en, this message translates to:
  /// **'Account created. Please continue to set up your learning plan.'**
  String get authAccountCreated;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get authWelcomeBack;

  /// No description provided for @authWelcomeBackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Continue today\'s learning path and clear your due review cards.'**
  String get authWelcomeBackSubtitle;

  /// No description provided for @authRegisterNew.
  ///
  /// In en, this message translates to:
  /// **'Register new account'**
  String get authRegisterNew;

  /// No description provided for @onboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Short lessons, visual memory cards, and smart review help you build vocabulary steadily.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Level up daily like a game'**
  String get onboardingTagline;

  /// No description provided for @onboardingTagWorld.
  ///
  /// In en, this message translates to:
  /// **'Word Quest World'**
  String get onboardingTagWorld;

  /// No description provided for @onboardingTagStreak.
  ///
  /// In en, this message translates to:
  /// **'Daily streak'**
  String get onboardingTagStreak;

  /// No description provided for @splashTagline.
  ///
  /// In en, this message translates to:
  /// **'Word cards, clear paths, smart review.'**
  String get splashTagline;

  /// No description provided for @studyNewScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'New words'**
  String get studyNewScreenTitle;

  /// No description provided for @studyWordbookPath.
  ///
  /// In en, this message translates to:
  /// **'Wordbook path'**
  String get studyWordbookPath;

  /// No description provided for @studyEnterCards.
  ///
  /// In en, this message translates to:
  /// **'Start word cards'**
  String get studyEnterCards;

  /// No description provided for @studyNewPackTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s new word pack'**
  String get studyNewPackTitle;

  /// No description provided for @studyNewPackDesc.
  ///
  /// In en, this message translates to:
  /// **'Self-assess first, then view cards, then context questions. Formal review is queued separately.'**
  String get studyNewPackDesc;

  /// No description provided for @studyNoNewWords.
  ///
  /// In en, this message translates to:
  /// **'No new words'**
  String get studyNoNewWords;

  /// No description provided for @studyNewPausedHint.
  ///
  /// In en, this message translates to:
  /// **'Study plan paused. Resume to continue today\'s new words.'**
  String get studyNewPausedHint;

  /// No description provided for @studyNewEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'The current wordbook is finished, or the plan isn\'t generated yet. Check the wordbook path for the next set.'**
  String get studyNewEmptyHint;

  /// No description provided for @studyOpenWordbookPath.
  ///
  /// In en, this message translates to:
  /// **'Open wordbook path'**
  String get studyOpenWordbookPath;

  /// No description provided for @studyTodayLearnCount.
  ///
  /// In en, this message translates to:
  /// **'Learn {count} new words today'**
  String studyTodayLearnCount(Object count);

  /// No description provided for @studyNewNoLessonHint.
  ///
  /// In en, this message translates to:
  /// **'Finish review before adding new words; keeping a rhythm beats piling on tasks.'**
  String get studyNewNoLessonHint;

  /// No description provided for @studyNewPausedResume.
  ///
  /// In en, this message translates to:
  /// **'Study plan paused; resume to continue from {section}.'**
  String studyNewPausedResume(Object section);

  /// No description provided for @studyRecallKnown.
  ///
  /// In en, this message translates to:
  /// **'Know it'**
  String get studyRecallKnown;

  /// No description provided for @studyRecallFuzzy.
  ///
  /// In en, this message translates to:
  /// **'Unsure'**
  String get studyRecallFuzzy;

  /// No description provided for @studyRecallUnknown.
  ///
  /// In en, this message translates to:
  /// **'Don\'t know'**
  String get studyRecallUnknown;

  /// No description provided for @studyStepSelfAssess.
  ///
  /// In en, this message translates to:
  /// **'Self-assess'**
  String get studyStepSelfAssess;

  /// No description provided for @studyStepSelfAssessDesc.
  ///
  /// In en, this message translates to:
  /// **'Reduce wasted repetition'**
  String get studyStepSelfAssessDesc;

  /// No description provided for @studyStepCards.
  ///
  /// In en, this message translates to:
  /// **'Word cards'**
  String get studyStepCards;

  /// No description provided for @studyStepCardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Fill in meaning and examples'**
  String get studyStepCardsDesc;

  /// No description provided for @studyStepContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get studyStepContext;

  /// No description provided for @studyStepContextDesc.
  ///
  /// In en, this message translates to:
  /// **'Active recall'**
  String get studyStepContextDesc;

  /// No description provided for @mixedManageReviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Manage review queue'**
  String get mixedManageReviewQueue;

  /// No description provided for @mixedReviewRatio.
  ///
  /// In en, this message translates to:
  /// **'Review {percent}%'**
  String mixedReviewRatio(Object percent);

  /// No description provided for @mixedTitleNew.
  ///
  /// In en, this message translates to:
  /// **'Today\'s new word pack'**
  String get mixedTitleNew;

  /// No description provided for @mixedTitleReview.
  ///
  /// In en, this message translates to:
  /// **'Quick review'**
  String get mixedTitleReview;

  /// No description provided for @mixedTitleMixed.
  ///
  /// In en, this message translates to:
  /// **'Today\'s mixed pack'**
  String get mixedTitleMixed;

  /// No description provided for @mixedSaveReviewFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save the review record for now'**
  String get mixedSaveReviewFailed;

  /// No description provided for @mixedUnsureOption.
  ///
  /// In en, this message translates to:
  /// **'Unsure {index}'**
  String mixedUnsureOption(Object index);

  /// No description provided for @mixedSaveProgressTitle.
  ///
  /// In en, this message translates to:
  /// **'Save this progress?'**
  String get mixedSaveProgressTitle;

  /// No description provided for @mixedSaveProgressBody.
  ///
  /// In en, this message translates to:
  /// **'Saved review records are kept; saving records the questions completed this time, and unfinished words return to the pack next time.'**
  String get mixedSaveProgressBody;

  /// No description provided for @mixedContinueStudy.
  ///
  /// In en, this message translates to:
  /// **'Keep studying'**
  String get mixedContinueStudy;

  /// No description provided for @mixedLeaveWithoutSaving.
  ///
  /// In en, this message translates to:
  /// **'Leave without saving'**
  String get mixedLeaveWithoutSaving;

  /// No description provided for @mixedSaveAndLeave.
  ///
  /// In en, this message translates to:
  /// **'Save and leave'**
  String get mixedSaveAndLeave;

  /// No description provided for @mixedSaveStudyFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save study progress for now'**
  String get mixedSaveStudyFailed;

  /// No description provided for @mixedSelfAssessHint.
  ///
  /// In en, this message translates to:
  /// **'Self-assess first; the app adjusts today\'s repetitions'**
  String get mixedSelfAssessHint;

  /// No description provided for @mixedEnterRecognition.
  ///
  /// In en, this message translates to:
  /// **'Start recognition'**
  String get mixedEnterRecognition;

  /// No description provided for @mixedAddLaterRecall.
  ///
  /// In en, this message translates to:
  /// **'Add to later recall'**
  String get mixedAddLaterRecall;

  /// No description provided for @mixedReviewQuickAnswer.
  ///
  /// In en, this message translates to:
  /// **'Review quick answer'**
  String get mixedReviewQuickAnswer;

  /// No description provided for @mixedFeedbackCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct, on to the next one.'**
  String get mixedFeedbackCorrect;

  /// No description provided for @mixedFeedbackWrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong; check the knowledge card, it will appear again later.'**
  String get mixedFeedbackWrong;

  /// No description provided for @mixedFeedbackRetry.
  ///
  /// In en, this message translates to:
  /// **'Not yet. Pick the correct answer before continuing.'**
  String get mixedFeedbackRetry;

  /// No description provided for @mixedShortRecallPrompt.
  ///
  /// In en, this message translates to:
  /// **'Short recall: what does {word} mean?'**
  String mixedShortRecallPrompt(Object word);

  /// No description provided for @mixedMeaningPrompt.
  ///
  /// In en, this message translates to:
  /// **'What is the meaning of {word}?'**
  String mixedMeaningPrompt(Object word);

  /// No description provided for @mixedStepRecognition.
  ///
  /// In en, this message translates to:
  /// **'Recognition'**
  String get mixedStepRecognition;

  /// No description provided for @mixedStepShortRecall.
  ///
  /// In en, this message translates to:
  /// **'Short recall'**
  String get mixedStepShortRecall;

  /// No description provided for @mixedStepDueReview.
  ///
  /// In en, this message translates to:
  /// **'Due review'**
  String get mixedStepDueReview;

  /// No description provided for @mixedStepKnowledge.
  ///
  /// In en, this message translates to:
  /// **'Knowledge card'**
  String get mixedStepKnowledge;

  /// No description provided for @mixedCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s pack complete'**
  String get mixedCompleteTitle;

  /// No description provided for @mixedNoContentTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to study today'**
  String get mixedNoContentTitle;

  /// No description provided for @mixedCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'Mistakes have been recycled this round; your answers and time are saved to the study log.'**
  String get mixedCompleteBody;

  /// No description provided for @mixedNoContentBody.
  ///
  /// In en, this message translates to:
  /// **'No new words or due reviews right now.'**
  String get mixedNoContentBody;

  /// No description provided for @mixedSaveAndHome.
  ///
  /// In en, this message translates to:
  /// **'Save and go home'**
  String get mixedSaveAndHome;

  /// No description provided for @questCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Task center'**
  String get questCenterTitle;

  /// No description provided for @questCenterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Earn points after study actions; also view rankings, analytics, and class learning.'**
  String get questCenterSubtitle;

  /// No description provided for @questDailyTask.
  ///
  /// In en, this message translates to:
  /// **'Daily tasks'**
  String get questDailyTask;

  /// No description provided for @questDailyTaskBody.
  ///
  /// In en, this message translates to:
  /// **'Finish a lesson and review 5 due words.'**
  String get questDailyTaskBody;

  /// No description provided for @questAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get questAchievements;

  /// No description provided for @questAchievementsBody.
  ///
  /// In en, this message translates to:
  /// **'Streaks, 100 words learned, first perfect lesson, and more.'**
  String get questAchievementsBody;

  /// No description provided for @questAchievementsValue.
  ///
  /// In en, this message translates to:
  /// **'3'**
  String get questAchievementsValue;

  /// No description provided for @questLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get questLeaderboard;

  /// No description provided for @questLeaderboardBody.
  ///
  /// In en, this message translates to:
  /// **'Weekly XP ranking for friends and future classes.'**
  String get questLeaderboardBody;

  /// No description provided for @questWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get questWeekly;

  /// No description provided for @questAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Learning analytics'**
  String get questAnalytics;

  /// No description provided for @questAnalyticsBody.
  ///
  /// In en, this message translates to:
  /// **'Accuracy, vocabulary growth, and review completion trends.'**
  String get questAnalyticsBody;

  /// No description provided for @questTrend.
  ///
  /// In en, this message translates to:
  /// **'Trends'**
  String get questTrend;

  /// No description provided for @questAiTutor.
  ///
  /// In en, this message translates to:
  /// **'AI tutor'**
  String get questAiTutor;

  /// No description provided for @questAiTutorBody.
  ///
  /// In en, this message translates to:
  /// **'Explain mistakes and suggest example sentences.'**
  String get questAiTutorBody;

  /// No description provided for @aiTutorSamplePrompt.
  ///
  /// In en, this message translates to:
  /// **'Explain the difference between affect and effect'**
  String get aiTutorSamplePrompt;

  /// No description provided for @aiTutorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a word, grammar point, or mistake to get a structured explanation and practice sentences.'**
  String get aiTutorSubtitle;

  /// No description provided for @aiTutorInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Ask about a word, grammar, or mistake'**
  String get aiTutorInputLabel;

  /// No description provided for @aiTutorSampleAnswer.
  ///
  /// In en, this message translates to:
  /// **'Affect is usually a verb: \"The weather affects my mood.\" Effect is usually a noun: \"The effect was immediate.\" Try writing a sentence with each word.'**
  String get aiTutorSampleAnswer;

  /// No description provided for @leaderboardDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get leaderboardDefaultName;

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Training leaderboard'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Counts only real completed training XP; no static demo board.'**
  String get leaderboardSubtitle;

  /// No description provided for @leaderboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No training results yet'**
  String get leaderboardEmptyTitle;

  /// No description provided for @leaderboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'After finishing Word Rush, Survival, or Spelling, real training XP generates the ranking.'**
  String get leaderboardEmptyBody;

  /// No description provided for @leaderboardOnlyValidXp.
  ///
  /// In en, this message translates to:
  /// **'Counts valid learning XP only'**
  String get leaderboardOnlyValidXp;

  /// No description provided for @analyticsDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning data'**
  String get analyticsDataTitle;

  /// No description provided for @analyticsDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A first analytics view based on word cards and review records.'**
  String get analyticsDataSubtitle;

  /// No description provided for @analyticsAssetsDue.
  ///
  /// In en, this message translates to:
  /// **'{due} of {total} learning assets are due'**
  String analyticsAssetsDue(Object due, Object total);

  /// No description provided for @analyticsCards.
  ///
  /// In en, this message translates to:
  /// **'Word cards'**
  String get analyticsCards;

  /// No description provided for @analyticsTrainingXp.
  ///
  /// In en, this message translates to:
  /// **'Training XP'**
  String get analyticsTrainingXp;

  /// No description provided for @analyticsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get analyticsAccuracy;

  /// No description provided for @onboardingFeatureImageCards.
  ///
  /// In en, this message translates to:
  /// **'Word Cards'**
  String get onboardingFeatureImageCards;

  /// No description provided for @onboardingFeatureImageCardsDesc.
  ///
  /// In en, this message translates to:
  /// **'Words, meanings, and examples connected in one learning flow.'**
  String get onboardingFeatureImageCardsDesc;

  /// No description provided for @onboardingFeaturePath.
  ///
  /// In en, this message translates to:
  /// **'Clear Path'**
  String get onboardingFeaturePath;

  /// No description provided for @onboardingFeaturePathDesc.
  ///
  /// In en, this message translates to:
  /// **'Short lessons guide your daily learning path.'**
  String get onboardingFeaturePathDesc;

  /// No description provided for @onboardingFeatureReview.
  ///
  /// In en, this message translates to:
  /// **'Timely Review'**
  String get onboardingFeatureReview;

  /// No description provided for @onboardingFeatureReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Weak words return to queue faster; mastered words get longer review intervals.'**
  String get onboardingFeatureReviewDesc;

  /// No description provided for @onboardingTagPillXp.
  ///
  /// In en, this message translates to:
  /// **'XP'**
  String get onboardingTagPillXp;

  /// No description provided for @onboardingTagPillStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get onboardingTagPillStreak;

  /// No description provided for @onboardingTagPillPlanet.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest Planet'**
  String get onboardingTagPillPlanet;

  /// No description provided for @onboardingRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get onboardingRegisterButton;

  /// No description provided for @goalSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Goal Setup'**
  String get goalSetupTitle;

  /// No description provided for @goalSetupSelectPlan.
  ///
  /// In en, this message translates to:
  /// **'Select Learning Plan'**
  String get goalSetupSelectPlan;

  /// No description provided for @goalSetupSelectPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'The system breaks your goal into daily new words, due reviews, and point tasks.'**
  String get goalSetupSelectPlanSubtitle;

  /// No description provided for @goalSetupTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get goalSetupTarget;

  /// No description provided for @goalSetupPlanBy.
  ///
  /// In en, this message translates to:
  /// **'Plan by'**
  String get goalSetupPlanBy;

  /// No description provided for @goalSetupDailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get goalSetupDailyGoal;

  /// No description provided for @goalSetupDeadlinePlan.
  ///
  /// In en, this message translates to:
  /// **'Plan by Deadline'**
  String get goalSetupDeadlinePlan;

  /// No description provided for @goalSetupDeadlineHint.
  ///
  /// In en, this message translates to:
  /// **'Select a target date, and the system will calculate daily word count automatically.'**
  String get goalSetupDeadlineHint;

  /// No description provided for @goalSetupPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick Date'**
  String get goalSetupPickDate;

  /// No description provided for @goalSetupChangeDate.
  ///
  /// In en, this message translates to:
  /// **'Change Date'**
  String get goalSetupChangeDate;

  /// No description provided for @goalSetupClearDate.
  ///
  /// In en, this message translates to:
  /// **'Clear Date Plan'**
  String get goalSetupClearDate;

  /// No description provided for @goalSetupEnterApp.
  ///
  /// In en, this message translates to:
  /// **'Enter LinguaQuest'**
  String get goalSetupEnterApp;

  /// No description provided for @goalSetupCurrentBook.
  ///
  /// In en, this message translates to:
  /// **'Current Wordbook'**
  String get goalSetupCurrentBook;

  /// No description provided for @goalSetupLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get goalSetupLearned;

  /// No description provided for @goalSetupNewWords.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get goalSetupNewWords;

  /// No description provided for @goalSetupNewWordsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} new words'**
  String goalSetupNewWordsCount(Object count);

  /// No description provided for @goalSetupReviewLimit.
  ///
  /// In en, this message translates to:
  /// **'Review Cap'**
  String get goalSetupReviewLimit;

  /// No description provided for @goalSetupReviewLimitCount.
  ///
  /// In en, this message translates to:
  /// **'Review cap: {count} words'**
  String goalSetupReviewLimitCount(Object count);

  /// No description provided for @goalSetupViewWordbook.
  ///
  /// In en, this message translates to:
  /// **'View Full Wordbook'**
  String get goalSetupViewWordbook;

  /// No description provided for @homePersonalSpace.
  ///
  /// In en, this message translates to:
  /// **'Personal Space'**
  String get homePersonalSpace;

  /// No description provided for @homeSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words, phrases, or examples'**
  String get homeSearchHint;

  /// No description provided for @homeNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get homeNotifications;

  /// No description provided for @homeLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get homeLearned;

  /// No description provided for @homeMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get homeMastered;

  /// No description provided for @homeReviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get homeReviewLabel;

  /// No description provided for @homeTaskConsole.
  ///
  /// In en, this message translates to:
  /// **'Daily Task Console'**
  String get homeTaskConsole;

  /// No description provided for @homeAdjustPlan.
  ///
  /// In en, this message translates to:
  /// **'Adjust Plan'**
  String get homeAdjustPlan;

  /// No description provided for @homeResumePlan.
  ///
  /// In en, this message translates to:
  /// **'Resume plan to continue learning'**
  String get homeResumePlan;

  /// No description provided for @homeStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get homeStartLearning;

  /// No description provided for @homeReviewOnly.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get homeReviewOnly;

  /// No description provided for @homeStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'continuous check-in'**
  String get homeStreakLabel;

  /// No description provided for @homeStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} days check-in}}'**
  String homeStreakDays(num count);

  /// No description provided for @homeTodayProgress.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get homeTodayProgress;

  /// No description provided for @homeWordbookShortcut.
  ///
  /// In en, this message translates to:
  /// **'Wordbook'**
  String get homeWordbookShortcut;

  /// No description provided for @homeDailyArticle.
  ///
  /// In en, this message translates to:
  /// **'Daily Article'**
  String get homeDailyArticle;

  /// No description provided for @homeDailyArticleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cloze Reading'**
  String get homeDailyArticleSubtitle;

  /// No description provided for @homeLearningPath.
  ///
  /// In en, this message translates to:
  /// **'Learning Path'**
  String get homeLearningPath;

  /// No description provided for @homeLearningPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Official Wordbook'**
  String get homeLearningPathSubtitle;

  /// No description provided for @homeWordOfDay.
  ///
  /// In en, this message translates to:
  /// **'Word of the Day'**
  String get homeWordOfDay;

  /// No description provided for @homeOpenWordCard.
  ///
  /// In en, this message translates to:
  /// **'Open Word Card'**
  String get homeOpenWordCard;

  /// No description provided for @homeWeakWords.
  ///
  /// In en, this message translates to:
  /// **'Weak Words'**
  String get homeWeakWords;

  /// No description provided for @homeNoWeakWords.
  ///
  /// In en, this message translates to:
  /// **'No high-frequency mistake words yet.'**
  String get homeNoWeakWords;

  /// No description provided for @homeWeakWordsReview.
  ///
  /// In en, this message translates to:
  /// **'Review them before they pile up.'**
  String get homeWeakWordsReview;

  /// No description provided for @homeWeakWordsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Add new words or complete reviews, and words needing focus will appear here.'**
  String get homeWeakWordsEmptyHint;

  /// No description provided for @homePlanPaused.
  ///
  /// In en, this message translates to:
  /// **'Plan Paused'**
  String get homePlanPaused;

  /// No description provided for @homeTodayCompleted.
  ///
  /// In en, this message translates to:
  /// **'Today completed'**
  String get homeTodayCompleted;

  /// No description provided for @profileLearner.
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get profileLearner;

  /// No description provided for @profileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email set'**
  String get profileNoEmail;

  /// No description provided for @publicProfileNotFoundTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile unavailable'**
  String get publicProfileNotFoundTitle;

  /// No description provided for @publicProfileNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This user doesn\'t exist or their profile is private.'**
  String get publicProfileNotFoundMessage;

  /// No description provided for @publicProfileLoadFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load profile'**
  String get publicProfileLoadFailedTitle;

  /// No description provided for @publicProfileLoadFailedMessage.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get publicProfileLoadFailedMessage;

  /// No description provided for @profileDashboard.
  ///
  /// In en, this message translates to:
  /// **'Learning Dashboard'**
  String get profileDashboard;

  /// No description provided for @profileDashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Key progress at a glance, with settings at the bottom.'**
  String get profileDashboardSubtitle;

  /// No description provided for @profileLearnedWords.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get profileLearnedWords;

  /// No description provided for @profileMasteredWords.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get profileMasteredWords;

  /// No description provided for @profileCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Custom Words'**
  String get profileCustomWords;

  /// No description provided for @profileAverageAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Avg. Accuracy'**
  String get profileAverageAccuracy;

  /// No description provided for @profilePlansCompleted.
  ///
  /// In en, this message translates to:
  /// **'Plans Done'**
  String get profilePlansCompleted;

  /// No description provided for @profileStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day streak} other{{count} days streak}}'**
  String profileStreakDays(num count);

  /// No description provided for @profileCurrentBookProgress.
  ///
  /// In en, this message translates to:
  /// **'Current Wordbook Progress'**
  String get profileCurrentBookProgress;

  /// No description provided for @profileWordbookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Current wordbook and target vocabulary'**
  String get profileWordbookSubtitle;

  /// No description provided for @profileCustomWordsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved words and personal vocabulary cards'**
  String get profileCustomWordsSubtitle;

  /// No description provided for @profileMistakeBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson mistakes and weak words'**
  String get profileMistakeBookSubtitle;

  /// No description provided for @profileReminderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Set reminder time and toggle'**
  String get profileReminderSubtitle;

  /// No description provided for @profileDarkModeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follow system, light, or dark theme'**
  String get profileDarkModeSubtitle;

  /// No description provided for @profileHelpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FAQ and support'**
  String get profileHelpSubtitle;

  /// No description provided for @profileHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & Feedback'**
  String get profileHelpTitle;

  /// No description provided for @profileAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest vision & version 1.0.0'**
  String get profileAboutSubtitle;

  /// No description provided for @profileAboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About Us'**
  String get profileAboutTitle;

  /// No description provided for @profileLogout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get profileLogout;

  /// No description provided for @profileSettingsSupport.
  ///
  /// In en, this message translates to:
  /// **'Settings & Support'**
  String get profileSettingsSupport;

  /// No description provided for @profilePlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Study Plan'**
  String get profilePlanLabel;

  /// No description provided for @profilePlanRunning.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get profilePlanRunning;

  /// No description provided for @profilePlanPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get profilePlanPaused;

  /// No description provided for @profileWeaknessAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Weakness Analysis'**
  String get profileWeaknessAnalysis;

  /// No description provided for @profileNoWeakness.
  ///
  /// In en, this message translates to:
  /// **'No frequent mistakes yet. Complete learning and reviews to generate analysis.'**
  String get profileNoWeakness;

  /// No description provided for @profileMostWrongWord.
  ///
  /// In en, this message translates to:
  /// **'Most Wrong Word'**
  String get profileMostWrongWord;

  /// No description provided for @settingsAppBar.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsAppBar;

  /// No description provided for @settingsSoundFeedback.
  ///
  /// In en, this message translates to:
  /// **'Answer Sound Feedback'**
  String get settingsSoundFeedback;

  /// No description provided for @settingsSoundFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Provides audio feedback for quiz results and practice rhythm'**
  String get settingsSoundFeedbackSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsThemeSystemSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically switch based on device light/dark preference'**
  String get settingsThemeSystemSubtitle;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeLightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Keep a bright and clean learning interface'**
  String get settingsThemeLightSubtitle;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeDarkSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use dark learning interface'**
  String get settingsThemeDarkSubtitle;

  /// No description provided for @settingsReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily Reminder'**
  String get settingsReminderTitle;

  /// No description provided for @settingsReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get settingsReminderTime;

  /// No description provided for @settingsReminderDisplay.
  ///
  /// In en, this message translates to:
  /// **'Daily · {time}'**
  String settingsReminderDisplay(String time);

  /// No description provided for @settingsReminderOff.
  ///
  /// In en, this message translates to:
  /// **'Reminder Off'**
  String get settingsReminderOff;

  /// No description provided for @settingsReminderDisabled.
  ///
  /// In en, this message translates to:
  /// **'No local reminders scheduled'**
  String get settingsReminderDisabled;

  /// No description provided for @settingsReminderDescription.
  ///
  /// In en, this message translates to:
  /// **'The app remembers your reminder time and schedules local system reminders to prompt daily learning and check-ins.'**
  String get settingsReminderDescription;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Check-in, point tasks, lucky draw, and learning community; earned XP adds to your total score.'**
  String get discoverSubtitle;

  /// No description provided for @discoverTaskCenter.
  ///
  /// In en, this message translates to:
  /// **'Task Center'**
  String get discoverTaskCenter;

  /// No description provided for @discoverXpTasks.
  ///
  /// In en, this message translates to:
  /// **'Point Tasks'**
  String get discoverXpTasks;

  /// No description provided for @discoverXpTasksSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete conditions then tap \"Claim\" — XP instantly adds to your profile and leaderboard.'**
  String get discoverXpTasksSubtitle;

  /// No description provided for @discoverDailyCheckin.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get discoverDailyCheckin;

  /// No description provided for @discoverDailyCheckinCondition.
  ///
  /// In en, this message translates to:
  /// **'Open the app and complete one learning action today'**
  String get discoverDailyCheckinCondition;

  /// No description provided for @discoverNewLearning.
  ///
  /// In en, this message translates to:
  /// **'Complete New Learning'**
  String get discoverNewLearning;

  /// No description provided for @discoverNewLearningCondition.
  ///
  /// In en, this message translates to:
  /// **'Finish today\'s new learning task'**
  String get discoverNewLearningCondition;

  /// No description provided for @discoverReviewDone.
  ///
  /// In en, this message translates to:
  /// **'Complete Review'**
  String get discoverReviewDone;

  /// No description provided for @discoverReviewDoneCondition.
  ///
  /// In en, this message translates to:
  /// **'Finish today\'s due review'**
  String get discoverReviewDoneCondition;

  /// No description provided for @discoverTrainingChallenge.
  ///
  /// In en, this message translates to:
  /// **'Training Challenge'**
  String get discoverTrainingChallenge;

  /// No description provided for @discoverTrainingChallengeCondition.
  ///
  /// In en, this message translates to:
  /// **'Complete any training game'**
  String get discoverTrainingChallengeCondition;

  /// No description provided for @discoverWeakCleanup.
  ///
  /// In en, this message translates to:
  /// **'Weak Word Cleanup'**
  String get discoverWeakCleanup;

  /// No description provided for @discoverWeakCleanupCondition.
  ///
  /// In en, this message translates to:
  /// **'Re-answer today\'s mistake words correctly'**
  String get discoverWeakCleanupCondition;

  /// No description provided for @discoverLuckyDraw.
  ///
  /// In en, this message translates to:
  /// **'Lucky Draw'**
  String get discoverLuckyDraw;

  /// No description provided for @discoverLuckyDrawSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Prizes are virtual decorations only and do not affect learning fairness.'**
  String get discoverLuckyDrawSubtitle;

  /// No description provided for @discoverLuckyDrawItems.
  ///
  /// In en, this message translates to:
  /// **'Avatar frames, profile backgrounds, learning badges, training titles, card skins'**
  String get discoverLuckyDrawItems;

  /// No description provided for @discoverLuckyDrawCost.
  ///
  /// In en, this message translates to:
  /// **'30 XP per draw; rare probability displayed transparently, fragments given even without a prize.'**
  String get discoverLuckyDrawCost;

  /// No description provided for @discoverCommunityPosts.
  ///
  /// In en, this message translates to:
  /// **'Community Posts'**
  String get discoverCommunityPosts;

  /// No description provided for @discoverCommunityPostsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get discoverCommunityPostsSubtitle;

  /// No description provided for @discoverMyFavorites.
  ///
  /// In en, this message translates to:
  /// **'My Favorites'**
  String get discoverMyFavorites;

  /// No description provided for @favoritesEmpty.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t favorited any posts yet.'**
  String get favoritesEmpty;

  /// No description provided for @communityFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get communityFilterAll;

  /// No description provided for @communityTagGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar'**
  String get communityTagGrammar;

  /// No description provided for @communityTagVocabulary.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get communityTagVocabulary;

  /// No description provided for @communityTagCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get communityTagCulture;

  /// No description provided for @communityTagGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get communityTagGeneral;

  /// No description provided for @communityTagProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get communityTagProgress;

  /// No description provided for @communityShareUpdate.
  ///
  /// In en, this message translates to:
  /// **'Share an update'**
  String get communityShareUpdate;

  /// No description provided for @communityNewPost.
  ///
  /// In en, this message translates to:
  /// **'New Post'**
  String get communityNewPost;

  /// No description provided for @communityNoPostsInFilter.
  ///
  /// In en, this message translates to:
  /// **'No posts in this category yet'**
  String get communityNoPostsInFilter;

  /// No description provided for @communityTimeJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get communityTimeJustNow;

  /// No description provided for @communityTimeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String communityTimeMinutesAgo(int count);

  /// No description provided for @communityTimeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String communityTimeHoursAgo(int count);

  /// No description provided for @communityTimeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String communityTimeDaysAgo(int count);

  /// No description provided for @discoverXpUsage.
  ///
  /// In en, this message translates to:
  /// **'XP Usage'**
  String get discoverXpUsage;

  /// No description provided for @discoverXpUsageDesc.
  ///
  /// In en, this message translates to:
  /// **'Claimed XP syncs to profile and leaderboard; lucky draw consumes current XP. Current balance'**
  String get discoverXpUsageDesc;

  /// No description provided for @discoverGoComplete.
  ///
  /// In en, this message translates to:
  /// **'Complete for +{points} XP'**
  String discoverGoComplete(Object points);

  /// No description provided for @discoverClaim.
  ///
  /// In en, this message translates to:
  /// **'Claim +{points} XP'**
  String discoverClaim(Object points);

  /// No description provided for @discoverClaimed.
  ///
  /// In en, this message translates to:
  /// **'Earned +{points} XP'**
  String discoverClaimed(Object points);

  /// No description provided for @discoverClaimedMessage.
  ///
  /// In en, this message translates to:
  /// **'{title} claimed +{points} XP, current total {total} XP'**
  String discoverClaimedMessage(Object points, Object title, Object total);

  /// No description provided for @discoverCannotClaim.
  ///
  /// In en, this message translates to:
  /// **'Can\'t claim this task right now'**
  String get discoverCannotClaim;

  /// No description provided for @discoverViewProfile.
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get discoverViewProfile;

  /// No description provided for @errorStartupFailed.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest failed to start: {detail}'**
  String errorStartupFailed(Object detail);

  /// No description provided for @errorPlanPausedNewLearning.
  ///
  /// In en, this message translates to:
  /// **'Your study plan is paused. Resume it to start new learning.'**
  String get errorPlanPausedNewLearning;

  /// No description provided for @errorPlanPausedReview.
  ///
  /// In en, this message translates to:
  /// **'Your study plan is paused. Resume it to review.'**
  String get errorPlanPausedReview;

  /// No description provided for @errorCardReviewedToday.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reviewed this card today.'**
  String get errorCardReviewedToday;

  /// No description provided for @errorTaskClaimedToday.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already claimed this task today.'**
  String get errorTaskClaimedToday;

  /// No description provided for @errorTargetReviewedToday.
  ///
  /// In en, this message translates to:
  /// **'You\'ve already reviewed this target word today.'**
  String get errorTargetReviewedToday;

  /// No description provided for @errorInsufficientXp.
  ///
  /// In en, this message translates to:
  /// **'Balance {balance} XP is below {cost} XP. Finish point tasks before the draw.'**
  String errorInsufficientXp(Object balance, Object cost);

  /// No description provided for @aiTutorInstantFeedback.
  ///
  /// In en, this message translates to:
  /// **'Instant Feedback'**
  String get aiTutorInstantFeedback;

  /// No description provided for @questTaskXp.
  ///
  /// In en, this message translates to:
  /// **'Task XP'**
  String get questTaskXp;

  /// No description provided for @discoverTasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'Today\'s point tasks haven\'t loaded yet.'**
  String get discoverTasksEmpty;

  /// No description provided for @discoverForumCheckinTag.
  ///
  /// In en, this message translates to:
  /// **'Check-in'**
  String get discoverForumCheckinTag;

  /// No description provided for @discoverForumMistakeTag.
  ///
  /// In en, this message translates to:
  /// **'Mistake Talk'**
  String get discoverForumMistakeTag;

  /// No description provided for @discoverForumPost1Title.
  ///
  /// In en, this message translates to:
  /// **'Check-in: reviewed 18 words in 12 minutes'**
  String get discoverForumPost1Title;

  /// No description provided for @discoverForumPost1Body.
  ///
  /// In en, this message translates to:
  /// **'Mistakes cluster around near-synonyms; tomorrow I\'ll start with the confusable-word challenge in training.'**
  String get discoverForumPost1Body;

  /// No description provided for @discoverForumPost2Title.
  ///
  /// In en, this message translates to:
  /// **'How do you memorize the word \'abstract\'?'**
  String get discoverForumPost2Title;

  /// No description provided for @discoverForumPost2Body.
  ///
  /// In en, this message translates to:
  /// **'In papers and reading passages \'abstract\' often doesn\'t mean \'抽象\'; judge it by context.'**
  String get discoverForumPost2Body;

  /// No description provided for @discoverForumHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Record interaction\" on a community post below to finish the forum interaction task.'**
  String get discoverForumHint;

  /// No description provided for @discoverCheckinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked in! Today\'s check-in points are ready to claim.'**
  String get discoverCheckinSuccess;

  /// No description provided for @discoverCheckinFailed.
  ///
  /// In en, this message translates to:
  /// **'Check-in failed, please try again later.'**
  String get discoverCheckinFailed;

  /// No description provided for @discoverForumSuccess.
  ///
  /// In en, this message translates to:
  /// **'Forum interaction approved; the point task is ready to claim.'**
  String get discoverForumSuccess;

  /// No description provided for @discoverForumFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record forum interaction, please try again later.'**
  String get discoverForumFailed;

  /// No description provided for @discoverCheckinLoadingHint.
  ///
  /// In en, this message translates to:
  /// **'You can check in once tasks finish loading.'**
  String get discoverCheckinLoadingHint;

  /// No description provided for @discoverCheckinClaimedDesc.
  ///
  /// In en, this message translates to:
  /// **'Checked in today and claimed +{points} XP.'**
  String discoverCheckinClaimedDesc(int points);

  /// No description provided for @discoverCheckinClaimableDesc.
  ///
  /// In en, this message translates to:
  /// **'Checked in today; remember to claim +{points} XP.'**
  String discoverCheckinClaimableDesc(int points);

  /// No description provided for @discoverCheckinPrompt.
  ///
  /// In en, this message translates to:
  /// **'After checking in, the check-in task becomes claimable.'**
  String get discoverCheckinPrompt;

  /// No description provided for @discoverCheckingIn.
  ///
  /// In en, this message translates to:
  /// **'Checking in'**
  String get discoverCheckingIn;

  /// No description provided for @discoverCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get discoverCheckedIn;

  /// No description provided for @discoverCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check in'**
  String get discoverCheckIn;

  /// No description provided for @discoverAlreadyClaimed.
  ///
  /// In en, this message translates to:
  /// **'Claimed'**
  String get discoverAlreadyClaimed;

  /// No description provided for @discoverClaimCheckin.
  ///
  /// In en, this message translates to:
  /// **'Claim check-in XP'**
  String get discoverClaimCheckin;

  /// No description provided for @discoverLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get discoverLoading;

  /// No description provided for @discoverReloadTasks.
  ///
  /// In en, this message translates to:
  /// **'Reload tasks'**
  String get discoverReloadTasks;

  /// No description provided for @discoverConditionMet.
  ///
  /// In en, this message translates to:
  /// **'Conditions met — tap to claim your reward.'**
  String get discoverConditionMet;

  /// No description provided for @discoverProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing'**
  String get discoverProcessing;

  /// No description provided for @discoverRecordInteraction.
  ///
  /// In en, this message translates to:
  /// **'Record interaction'**
  String get discoverRecordInteraction;

  /// No description provided for @quizNoLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson not found'**
  String get quizNoLesson;

  /// No description provided for @quizNoQuestions.
  ///
  /// In en, this message translates to:
  /// **'This lesson has no quiz yet.'**
  String get quizNoQuestions;

  /// No description provided for @quizTimedTest.
  ///
  /// In en, this message translates to:
  /// **'Timed Test'**
  String get quizTimedTest;

  /// No description provided for @quizCampusSpeed.
  ///
  /// In en, this message translates to:
  /// **'Campus Sprint'**
  String get quizCampusSpeed;

  /// No description provided for @quizLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Quiz?'**
  String get quizLeaveTitle;

  /// No description provided for @quizLeaveContent.
  ///
  /// In en, this message translates to:
  /// **'Current quiz progress will be discarded.'**
  String get quizLeaveContent;

  /// No description provided for @quizKeepAnswering.
  ///
  /// In en, this message translates to:
  /// **'Keep Answering'**
  String get quizKeepAnswering;

  /// No description provided for @quizInputWord.
  ///
  /// In en, this message translates to:
  /// **'Enter word'**
  String get quizInputWord;

  /// No description provided for @quizCorrect.
  ///
  /// In en, this message translates to:
  /// **'Correct. '**
  String get quizCorrect;

  /// No description provided for @quizWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite. '**
  String get quizWrong;

  /// No description provided for @quizReinforce.
  ///
  /// In en, this message translates to:
  /// **'Reinforce: '**
  String get quizReinforce;

  /// No description provided for @quizContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get quizContinue;

  /// No description provided for @quizRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get quizRetry;

  /// No description provided for @quizCheck.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get quizCheck;

  /// No description provided for @quizResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Lesson Result'**
  String get quizResultTitle;

  /// No description provided for @quizTimedResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Timed Test Result'**
  String get quizTimedResultTitle;

  /// No description provided for @quizGreatJob.
  ///
  /// In en, this message translates to:
  /// **'Great job!'**
  String get quizGreatJob;

  /// No description provided for @quizChallengeDone.
  ///
  /// In en, this message translates to:
  /// **'Challenge Done'**
  String get quizChallengeDone;

  /// No description provided for @quizLessonDone.
  ///
  /// In en, this message translates to:
  /// **'Lesson Done'**
  String get quizLessonDone;

  /// No description provided for @quizChallengeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Challenge Success!'**
  String get quizChallengeSuccess;

  /// No description provided for @quizAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get quizAccuracy;

  /// No description provided for @quizMistakes.
  ///
  /// In en, this message translates to:
  /// **'Mistakes'**
  String get quizMistakes;

  /// No description provided for @quizNoResult.
  ///
  /// In en, this message translates to:
  /// **'No lesson result yet'**
  String get quizNoResult;

  /// No description provided for @quizAllCorrect.
  ///
  /// In en, this message translates to:
  /// **'All correct!'**
  String get quizAllCorrect;

  /// No description provided for @quizMistakeReview.
  ///
  /// In en, this message translates to:
  /// **'Mistakes saved to review.'**
  String get quizMistakeReview;

  /// No description provided for @quizMistakeTimed.
  ///
  /// In en, this message translates to:
  /// **'Mistakes can be reviewed in the review center.'**
  String get quizMistakeTimed;

  /// No description provided for @quizRetryMistakes.
  ///
  /// In en, this message translates to:
  /// **'Practice mistakes again'**
  String get quizRetryMistakes;

  /// No description provided for @quizGoReviewCenter.
  ///
  /// In en, this message translates to:
  /// **'Go to review center'**
  String get quizGoReviewCenter;

  /// No description provided for @quizBackTraining.
  ///
  /// In en, this message translates to:
  /// **'Back to training'**
  String get quizBackTraining;

  /// No description provided for @quizBackLearningPath.
  ///
  /// In en, this message translates to:
  /// **'Back to learning path'**
  String get quizBackLearningPath;

  /// No description provided for @quizXpBalanceUpdated.
  ///
  /// In en, this message translates to:
  /// **'Total XP updated'**
  String get quizXpBalanceUpdated;

  /// No description provided for @quizCurrentXp.
  ///
  /// In en, this message translates to:
  /// **'Current total {xp} XP'**
  String quizCurrentXp(Object xp);

  /// No description provided for @quizXpCredited.
  ///
  /// In en, this message translates to:
  /// **'+{xp} XP credited'**
  String quizXpCredited(Object xp);

  /// No description provided for @quizXpImpactBody.
  ///
  /// In en, this message translates to:
  /// **'{balance}. XP syncs to your profile, leaderboard, and lucky-draw balance.'**
  String quizXpImpactBody(Object balance);

  /// No description provided for @quizTimedReward.
  ///
  /// In en, this message translates to:
  /// **'Timed test reward'**
  String get quizTimedReward;

  /// No description provided for @quizLessonReward.
  ///
  /// In en, this message translates to:
  /// **'Lesson reward'**
  String get quizLessonReward;

  /// No description provided for @quizViewXpUses.
  ///
  /// In en, this message translates to:
  /// **'View XP uses'**
  String get quizViewXpUses;

  /// No description provided for @quizXpEarned.
  ///
  /// In en, this message translates to:
  /// **'Credited +{xp} XP'**
  String quizXpEarned(Object xp);

  /// No description provided for @quizTotalXp.
  ///
  /// In en, this message translates to:
  /// **'Total {xp} XP'**
  String quizTotalXp(Object xp);

  /// No description provided for @quizMistakeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} mistakes'**
  String quizMistakeCount(Object count);

  /// No description provided for @trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Ground'**
  String get trainingTitle;

  /// No description provided for @trainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timed tests, drills, leaderboard'**
  String get trainingSubtitle;

  /// No description provided for @trainingPageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timed tests, special drills, and the leaderboard live here.'**
  String get trainingPageSubtitle;

  /// No description provided for @trainingWeeklyXpPrefix.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get trainingWeeklyXpPrefix;

  /// No description provided for @trainingDailyXpAvailable.
  ///
  /// In en, this message translates to:
  /// **'Up to 60 XP today'**
  String get trainingDailyXpAvailable;

  /// No description provided for @trainingLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get trainingLeaderboard;

  /// No description provided for @trainingTimedTestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Campus packs & speed challenges'**
  String get trainingTimedTestsSubtitle;

  /// No description provided for @trainingCampusSpeed.
  ///
  /// In en, this message translates to:
  /// **'Campus Sprint'**
  String get trainingCampusSpeed;

  /// No description provided for @trainingCampusSpeedDesc.
  ///
  /// In en, this message translates to:
  /// **'Draws from current wordbook. Good for post-class quick checks without affecting formal review rhythm.'**
  String get trainingCampusSpeedDesc;

  /// No description provided for @trainingSpeedGame.
  ///
  /// In en, this message translates to:
  /// **'Speed Game'**
  String get trainingSpeedGame;

  /// No description provided for @trainingSpeedGameDesc.
  ///
  /// In en, this message translates to:
  /// **'Answer meaning-choice questions within 60 seconds. Score based on accuracy, combos, and speed.'**
  String get trainingSpeedGameDesc;

  /// No description provided for @trainingSpeedGameSource.
  ///
  /// In en, this message translates to:
  /// **'Learned + due words'**
  String get trainingSpeedGameSource;

  /// No description provided for @trainingNoWordbook.
  ///
  /// In en, this message translates to:
  /// **'No wordbook'**
  String get trainingNoWordbook;

  /// No description provided for @trainingStartTest.
  ///
  /// In en, this message translates to:
  /// **'Start Test'**
  String get trainingStartTest;

  /// No description provided for @trainingComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get trainingComingSoon;

  /// No description provided for @trainingSpecialDrillsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Practice spelling, listening, collocation, and passage cloze to strengthen weak areas.'**
  String get trainingSpecialDrillsSubtitle;

  /// No description provided for @trainingSurvivor.
  ///
  /// In en, this message translates to:
  /// **'Last One Standing'**
  String get trainingSurvivor;

  /// No description provided for @trainingSurvivorDesc.
  ///
  /// In en, this message translates to:
  /// **'Answer questions from easy to hard. Wrong answers go to weak words and mistake book.'**
  String get trainingSurvivorDesc;

  /// No description provided for @trainingSurvivorSource.
  ///
  /// In en, this message translates to:
  /// **'Current wordbook + weak words'**
  String get trainingSurvivorSource;

  /// No description provided for @trainingSpelling.
  ///
  /// In en, this message translates to:
  /// **'Word Spelling'**
  String get trainingSpelling;

  /// No description provided for @trainingSpellingDesc.
  ///
  /// In en, this message translates to:
  /// **'See Chinese, hear pronunciation, or read sentence cloze, then type the English word.'**
  String get trainingSpellingDesc;

  /// No description provided for @trainingSpellingSource.
  ///
  /// In en, this message translates to:
  /// **'Spelling weak words'**
  String get trainingSpellingSource;

  /// No description provided for @trainingPassageCloze.
  ///
  /// In en, this message translates to:
  /// **'Passage Cloze'**
  String get trainingPassageCloze;

  /// No description provided for @trainingPassageClozeDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate passages with today\'s vocabulary, linking memorization and reading comprehension.'**
  String get trainingPassageClozeDesc;

  /// No description provided for @trainingPassageClozeSource.
  ///
  /// In en, this message translates to:
  /// **'Today\'s words + AI passage'**
  String get trainingPassageClozeSource;

  /// No description provided for @trainingListening.
  ///
  /// In en, this message translates to:
  /// **'Listening Sprint'**
  String get trainingListening;

  /// No description provided for @trainingListeningDesc.
  ///
  /// In en, this message translates to:
  /// **'Listen to pronunciation, then select the word or meaning. Response time affects score.'**
  String get trainingListeningDesc;

  /// No description provided for @trainingListeningSource.
  ///
  /// In en, this message translates to:
  /// **'Listening weak words'**
  String get trainingListeningSource;

  /// No description provided for @trainingDueWords.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get trainingDueWords;

  /// No description provided for @trainingWeakWords.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get trainingWeakWords;

  /// No description provided for @trainingComboTarget.
  ///
  /// In en, this message translates to:
  /// **'Combo'**
  String get trainingComboTarget;

  /// No description provided for @trainingEnterCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Go to Custom Words'**
  String get trainingEnterCustomWords;

  /// No description provided for @trainingEntryMissingTitle.
  ///
  /// In en, this message translates to:
  /// **'Training entry unavailable'**
  String get trainingEntryMissingTitle;

  /// No description provided for @trainingEntryMissingHeader.
  ///
  /// In en, this message translates to:
  /// **'Training not found'**
  String get trainingEntryMissingHeader;

  /// No description provided for @trainingEntryMissingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go back to training and start from Speed Game, Last One Standing, or Word Spelling.'**
  String get trainingEntryMissingSubtitle;

  /// No description provided for @trainingSourceInsufficientTitle.
  ///
  /// In en, this message translates to:
  /// **'Not enough training questions'**
  String get trainingSourceInsufficientTitle;

  /// No description provided for @trainingSourceInsufficientSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Finish a new lesson, add custom words, or build weak words in the mistake book before challenging again.'**
  String get trainingSourceInsufficientSubtitle;

  /// No description provided for @trainingBack.
  ///
  /// In en, this message translates to:
  /// **'Back to training'**
  String get trainingBack;

  /// No description provided for @trainingMistakesOnly.
  ///
  /// In en, this message translates to:
  /// **'Practice mistakes again'**
  String get trainingMistakesOnly;

  /// No description provided for @trainingNextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next question'**
  String get trainingNextQuestion;

  /// No description provided for @trainingSubmitSpelling.
  ///
  /// In en, this message translates to:
  /// **'Submit spelling'**
  String get trainingSubmitSpelling;

  /// No description provided for @trainingExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave training?'**
  String get trainingExitTitle;

  /// No description provided for @trainingExitContent.
  ///
  /// In en, this message translates to:
  /// **'Current training progress will not be settled.'**
  String get trainingExitContent;

  /// No description provided for @trainingContinue.
  ///
  /// In en, this message translates to:
  /// **'Keep training'**
  String get trainingContinue;

  /// No description provided for @trainingExit.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get trainingExit;

  /// No description provided for @trainingPromptWordRush.
  ///
  /// In en, this message translates to:
  /// **'Choose the meaning of \"{word}\" quickly'**
  String trainingPromptWordRush(Object word);

  /// No description provided for @trainingExplanationWordRush.
  ///
  /// In en, this message translates to:
  /// **'\"{word}\" means {meaning}. {example}'**
  String trainingExplanationWordRush(
    Object example,
    Object meaning,
    Object word,
  );

  /// No description provided for @trainingPromptChineseChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose the English word for: {meaning}'**
  String trainingPromptChineseChoice(Object meaning);

  /// No description provided for @trainingExplanationChineseChoice.
  ///
  /// In en, this message translates to:
  /// **'{meaning} matches \"{word}\".'**
  String trainingExplanationChineseChoice(Object meaning, Object word);

  /// No description provided for @trainingPromptContextChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose the meaning from the example: {example}'**
  String trainingPromptContextChoice(Object example);

  /// No description provided for @trainingPromptMeaningChoice.
  ///
  /// In en, this message translates to:
  /// **'Choose the meaning of \"{word}\"'**
  String trainingPromptMeaningChoice(Object word);

  /// No description provided for @trainingExplanationMeaningChoice.
  ///
  /// In en, this message translates to:
  /// **'This question checks {word}: {meaning}.'**
  String trainingExplanationMeaningChoice(Object meaning, Object word);

  /// No description provided for @trainingPromptChineseSpelling.
  ///
  /// In en, this message translates to:
  /// **'Spell the word from its meaning: {meaning}'**
  String trainingPromptChineseSpelling(Object meaning);

  /// No description provided for @trainingPromptAudioSpelling.
  ///
  /// In en, this message translates to:
  /// **'Spell the word after listening: {cue}'**
  String trainingPromptAudioSpelling(Object cue);

  /// No description provided for @trainingPromptContextSpelling.
  ///
  /// In en, this message translates to:
  /// **'Spell the blank in the example: {example}'**
  String trainingPromptContextSpelling(Object example);

  /// No description provided for @trainingExplanationSpelling.
  ///
  /// In en, this message translates to:
  /// **'The correct spelling is \"{word}\". {example}'**
  String trainingExplanationSpelling(Object example, Object word);

  /// No description provided for @trainingNoEffectiveAnswers.
  ///
  /// In en, this message translates to:
  /// **'No valid answer this round, so no training record was saved.'**
  String get trainingNoEffectiveAnswers;

  /// No description provided for @trainingResultMistakesSuffix.
  ///
  /// In en, this message translates to:
  /// **'{title} · mistake practice'**
  String trainingResultMistakesSuffix(Object title);

  /// No description provided for @trainingCorrectAttempts.
  ///
  /// In en, this message translates to:
  /// **'Correct {correct}/{attempts}'**
  String trainingCorrectAttempts(Object attempts, Object correct);

  /// No description provided for @trainingStreak.
  ///
  /// In en, this message translates to:
  /// **'Streak {streak}'**
  String trainingStreak(Object streak);

  /// No description provided for @trainingAccuracyValue.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {accuracy}%'**
  String trainingAccuracyValue(Object accuracy);

  /// No description provided for @trainingSurvivalResources.
  ///
  /// In en, this message translates to:
  /// **'Revives {revives} · Nodes {nodes}'**
  String trainingSurvivalResources(Object nodes, Object revives);

  /// No description provided for @trainingBestStreak.
  ///
  /// In en, this message translates to:
  /// **'Best {streak}'**
  String trainingBestStreak(Object streak);

  /// No description provided for @trainingRealSource.
  ///
  /// In en, this message translates to:
  /// **'Real question source'**
  String get trainingRealSource;

  /// No description provided for @trainingSpellingInputLabel.
  ///
  /// In en, this message translates to:
  /// **'Type the word'**
  String get trainingSpellingInputLabel;

  /// No description provided for @trainingReviveConsumed.
  ///
  /// In en, this message translates to:
  /// **'One revive was consumed. Keep going.'**
  String get trainingReviveConsumed;

  /// No description provided for @trainingReviveExhausted.
  ///
  /// In en, this message translates to:
  /// **'No revives left. This round ends.'**
  String get trainingReviveExhausted;

  /// No description provided for @trainingCorrectFeedback.
  ///
  /// In en, this message translates to:
  /// **'Correct. Streak continues!'**
  String get trainingCorrectFeedback;

  /// No description provided for @trainingPromptListening.
  ///
  /// In en, this message translates to:
  /// **'Listen and choose the word you heard'**
  String get trainingPromptListening;

  /// No description provided for @trainingListeningRevealHint.
  ///
  /// In en, this message translates to:
  /// **'Play the audio first, then the options appear.'**
  String get trainingListeningRevealHint;

  /// No description provided for @learningPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Path'**
  String get learningPathTitle;

  /// No description provided for @learningPathBackToHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get learningPathBackToHome;

  /// No description provided for @learningPathBookPath.
  ///
  /// In en, this message translates to:
  /// **'Wordbook path'**
  String get learningPathBookPath;

  /// No description provided for @learningPathPathSuffix.
  ///
  /// In en, this message translates to:
  /// **'path'**
  String get learningPathPathSuffix;

  /// No description provided for @learningPathPausedHint.
  ///
  /// In en, this message translates to:
  /// **'The study plan is paused, and path progress will be kept.'**
  String get learningPathPausedHint;

  /// No description provided for @learningPathDescription.
  ///
  /// In en, this message translates to:
  /// **'This view shows only wordbook progress; formal new learning and review stay at the two separate entrances on Home.'**
  String get learningPathDescription;

  /// No description provided for @learningPathPlanLabel.
  ///
  /// In en, this message translates to:
  /// **'Learning plan'**
  String get learningPathPlanLabel;

  /// No description provided for @learningPathStartLearning.
  ///
  /// In en, this message translates to:
  /// **'Start Learning'**
  String get learningPathStartLearning;

  /// No description provided for @learningPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wordbook progress'**
  String get learningPathSubtitle;

  /// No description provided for @learningPathOpenWordbook.
  ///
  /// In en, this message translates to:
  /// **'Open Wordbook & Custom Words'**
  String get learningPathOpenWordbook;

  /// No description provided for @learningPathAdjustPlan.
  ///
  /// In en, this message translates to:
  /// **'Adjust Current Study Plan'**
  String get learningPathAdjustPlan;

  /// No description provided for @learningPathLessonLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get learningPathLessonLocked;

  /// No description provided for @learningPathLessonCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get learningPathLessonCurrent;

  /// No description provided for @learningPathLessonCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get learningPathLessonCompleted;

  /// No description provided for @learningPathLessonPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get learningPathLessonPreview;

  /// No description provided for @learningPathLessonQuiz.
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get learningPathLessonQuiz;

  /// No description provided for @lessonPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Word Cards'**
  String get lessonPreviewTitle;

  /// No description provided for @lessonPreviewNoLesson.
  ///
  /// In en, this message translates to:
  /// **'Lesson not found'**
  String get lessonPreviewNoLesson;

  /// No description provided for @lessonPreviewPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get lessonPreviewPrevious;

  /// No description provided for @lessonPreviewNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get lessonPreviewNext;

  /// No description provided for @lessonPreviewStartQuiz.
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get lessonPreviewStartQuiz;

  /// No description provided for @lessonPreviewConfidence.
  ///
  /// In en, this message translates to:
  /// **'How well do you know this word?'**
  String get lessonPreviewConfidence;

  /// No description provided for @lessonPreviewNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not Yet'**
  String get lessonPreviewNotYet;

  /// No description provided for @lessonPreviewVaguely.
  ///
  /// In en, this message translates to:
  /// **'Vaguely'**
  String get lessonPreviewVaguely;

  /// No description provided for @lessonPreviewGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got It'**
  String get lessonPreviewGotIt;

  /// No description provided for @lessonPreviewLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave Preview?'**
  String get lessonPreviewLeaveTitle;

  /// No description provided for @lessonPreviewLeaveContent.
  ///
  /// In en, this message translates to:
  /// **'Current preview progress will be discarded.'**
  String get lessonPreviewLeaveContent;

  /// No description provided for @lessonPreviewBuildUnderstanding.
  ///
  /// In en, this message translates to:
  /// **'Build understanding first, then context questions'**
  String get lessonPreviewBuildUnderstanding;

  /// No description provided for @lessonPreviewProgressMeta.
  ///
  /// In en, this message translates to:
  /// **'{section} · {minutes} min · {current}/{total}'**
  String lessonPreviewProgressMeta(
    Object current,
    Object minutes,
    Object section,
    Object total,
  );

  /// No description provided for @lessonPreviewLessonCards.
  ///
  /// In en, this message translates to:
  /// **'Lesson cards'**
  String get lessonPreviewLessonCards;

  /// No description provided for @lessonPreviewCardMeta.
  ///
  /// In en, this message translates to:
  /// **'{xp} XP · {count} context questions'**
  String lessonPreviewCardMeta(Object count, Object xp);

  /// No description provided for @lessonPreviewEnterContext.
  ///
  /// In en, this message translates to:
  /// **'Start context practice'**
  String get lessonPreviewEnterContext;

  /// No description provided for @lessonPreviewNextCard.
  ///
  /// In en, this message translates to:
  /// **'Next card'**
  String get lessonPreviewNextCard;

  /// No description provided for @lessonPreviewNoCards.
  ///
  /// In en, this message translates to:
  /// **'No cards'**
  String get lessonPreviewNoCards;

  /// No description provided for @lessonPreviewNoCardsBody.
  ///
  /// In en, this message translates to:
  /// **'This lesson has no words to study yet.'**
  String get lessonPreviewNoCardsBody;

  /// No description provided for @lessonPreviewLeaveCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave cards?'**
  String get lessonPreviewLeaveCardTitle;

  /// No description provided for @lessonPreviewLeaveCardContent.
  ///
  /// In en, this message translates to:
  /// **'Your current new-word card progress will be discarded.'**
  String get lessonPreviewLeaveCardContent;

  /// No description provided for @lessonPreviewLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get lessonPreviewLeave;

  /// No description provided for @lessonPreviewAssessFirst.
  ///
  /// In en, this message translates to:
  /// **'Judge your familiarity first'**
  String get lessonPreviewAssessFirst;

  /// No description provided for @lessonPreviewContextExample.
  ///
  /// In en, this message translates to:
  /// **'Context example'**
  String get lessonPreviewContextExample;

  /// No description provided for @reviewCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewCenterTitle;

  /// No description provided for @reviewCenterCardsDuePrefix.
  ///
  /// In en, this message translates to:
  /// **'{count} cards due'**
  String reviewCenterCardsDuePrefix(Object count);

  /// No description provided for @reviewCenterDailyCapPrefix.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review cap '**
  String get reviewCenterDailyCapPrefix;

  /// No description provided for @reviewCenterDailyCapMiddle.
  ///
  /// In en, this message translates to:
  /// **' words, '**
  String get reviewCenterDailyCapMiddle;

  /// No description provided for @reviewCenterDailyCapSuffix.
  ///
  /// In en, this message translates to:
  /// **' words will be scheduled later.'**
  String get reviewCenterDailyCapSuffix;

  /// No description provided for @reviewCenterCurrentBook.
  ///
  /// In en, this message translates to:
  /// **'Current wordbook'**
  String get reviewCenterCurrentBook;

  /// No description provided for @reviewCenterAutoQueueHint.
  ///
  /// In en, this message translates to:
  /// **'Wrong answers are added to the review queue automatically.'**
  String get reviewCenterAutoQueueHint;

  /// No description provided for @reviewCenterEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Review queue cleared'**
  String get reviewCenterEmptyTitle;

  /// No description provided for @reviewCenterEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add custom word cards, or add mistake cards from wrong answers, and a review queue will be generated here.'**
  String get reviewCenterEmptyMessage;

  /// No description provided for @reviewCenterAddCustomWord.
  ///
  /// In en, this message translates to:
  /// **'Add custom word'**
  String get reviewCenterAddCustomWord;

  /// No description provided for @reviewCenterNoMistakes.
  ///
  /// In en, this message translates to:
  /// **'No weak words or lesson mistakes yet.'**
  String get reviewCenterNoMistakes;

  /// No description provided for @reviewCenterOpenMistakeBook.
  ///
  /// In en, this message translates to:
  /// **'Open mistake book'**
  String get reviewCenterOpenMistakeBook;

  /// No description provided for @reviewCenterLimitPrefix.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review is capped at '**
  String get reviewCenterLimitPrefix;

  /// No description provided for @reviewCenterLimitMiddle.
  ///
  /// In en, this message translates to:
  /// **' words; '**
  String get reviewCenterLimitMiddle;

  /// No description provided for @reviewCenterLimitSuffix.
  ///
  /// In en, this message translates to:
  /// **' words won\'t be lost and will stay in the review queue.'**
  String get reviewCenterLimitSuffix;

  /// No description provided for @reviewCenterTargetWord.
  ///
  /// In en, this message translates to:
  /// **'Target word'**
  String get reviewCenterTargetWord;

  /// No description provided for @reviewCenterCustomCard.
  ///
  /// In en, this message translates to:
  /// **'Custom word card'**
  String get reviewCenterCustomCard;

  /// No description provided for @reviewCenterForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot'**
  String get reviewCenterForgot;

  /// No description provided for @reviewCenterRemembered.
  ///
  /// In en, this message translates to:
  /// **'Remembered'**
  String get reviewCenterRemembered;

  /// No description provided for @wordDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Word not found'**
  String get wordDetailNotFound;

  /// No description provided for @wordDetailReviewStats.
  ///
  /// In en, this message translates to:
  /// **'Review stats'**
  String get wordDetailReviewStats;

  /// No description provided for @wordDetailMarkRemembered.
  ///
  /// In en, this message translates to:
  /// **'Mark as remembered'**
  String get wordDetailMarkRemembered;

  /// No description provided for @wordDetailScheduleSoon.
  ///
  /// In en, this message translates to:
  /// **'Practice again soon'**
  String get wordDetailScheduleSoon;

  /// No description provided for @wordDetailMarkedRemembered.
  ///
  /// In en, this message translates to:
  /// **'Marked as remembered'**
  String get wordDetailMarkedRemembered;

  /// No description provided for @wordDetailScheduledSoon.
  ///
  /// In en, this message translates to:
  /// **'Scheduled to practice again soon'**
  String get wordDetailScheduledSoon;

  /// No description provided for @wordDetailStatRemembered.
  ///
  /// In en, this message translates to:
  /// **'Remembered'**
  String get wordDetailStatRemembered;

  /// No description provided for @wordDetailStatForgot.
  ///
  /// In en, this message translates to:
  /// **'Forgot'**
  String get wordDetailStatForgot;

  /// No description provided for @wordDetailStatMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get wordDetailStatMastery;

  /// No description provided for @wordDetailUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update this card for now'**
  String get wordDetailUpdateFailed;

  /// No description provided for @wordDetailMasteryLabel.
  ///
  /// In en, this message translates to:
  /// **'Mastery {level}/5'**
  String wordDetailMasteryLabel(Object level);

  /// No description provided for @wordDetailNextReview.
  ///
  /// In en, this message translates to:
  /// **'Next {when}'**
  String wordDetailNextReview(Object when);

  /// No description provided for @reviewCenterPostponedMessage.
  ///
  /// In en, this message translates to:
  /// **'Marked as remembered; the next review will be delayed'**
  String get reviewCenterPostponedMessage;

  /// No description provided for @reviewCenterCloserReviewMessage.
  ///
  /// In en, this message translates to:
  /// **'Added to a closer review schedule'**
  String get reviewCenterCloserReviewMessage;

  /// No description provided for @reviewCenterUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update this card right now'**
  String get reviewCenterUpdateFailed;

  /// No description provided for @reviewCenterAddMistakeCards.
  ///
  /// In en, this message translates to:
  /// **'Add mistake cards'**
  String get reviewCenterAddMistakeCards;

  /// No description provided for @reviewCenterAllMistakesAdded.
  ///
  /// In en, this message translates to:
  /// **'All recent mistakes are already in the wordbook.'**
  String get reviewCenterAllMistakesAdded;

  /// No description provided for @reviewCenterSelectMistakesHint.
  ///
  /// In en, this message translates to:
  /// **'After selecting mistakes, you can add them directly to review cards.'**
  String get reviewCenterSelectMistakesHint;

  /// No description provided for @reviewCenterAddSelected.
  ///
  /// In en, this message translates to:
  /// **'Add selected'**
  String get reviewCenterAddSelected;

  /// No description provided for @reviewCenterMistakeCardsSuffix.
  ///
  /// In en, this message translates to:
  /// **' mistake cards'**
  String get reviewCenterMistakeCardsSuffix;

  /// No description provided for @reviewCenterPlanPaused.
  ///
  /// In en, this message translates to:
  /// **'Study plan paused'**
  String get reviewCenterPlanPaused;

  /// No description provided for @reviewCenterTodayDone.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review completed'**
  String get reviewCenterTodayDone;

  /// No description provided for @reviewCenterCardsDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No cards due} =1{1 card due} other{{count} cards due}}'**
  String reviewCenterCardsDue(num count);

  /// No description provided for @reviewCenterPlanPausedHint.
  ///
  /// In en, this message translates to:
  /// **'Resume your study plan to continue receiving review cards.'**
  String get reviewCenterPlanPausedHint;

  /// No description provided for @reviewCenterDailyCap.
  ///
  /// In en, this message translates to:
  /// **'Daily review cap {limit} words. {hidden} more scheduled for later.'**
  String reviewCenterDailyCap(Object hidden, Object limit);

  /// No description provided for @reviewCenterTodayDue.
  ///
  /// In en, this message translates to:
  /// **'Due Today'**
  String get reviewCenterTodayDue;

  /// No description provided for @reviewCenterReviewQueue.
  ///
  /// In en, this message translates to:
  /// **'Review Queue'**
  String get reviewCenterReviewQueue;

  /// No description provided for @reviewCenterStartReview.
  ///
  /// In en, this message translates to:
  /// **'Start Review'**
  String get reviewCenterStartReview;

  /// No description provided for @reviewCenterEmpty.
  ///
  /// In en, this message translates to:
  /// **'All review done for now!'**
  String get reviewCenterEmpty;

  /// No description provided for @mistakeBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Mistake Book'**
  String get mistakeBookTitle;

  /// No description provided for @mistakeBookNoMistakes.
  ///
  /// In en, this message translates to:
  /// **'No lesson mistakes yet'**
  String get mistakeBookNoMistakes;

  /// No description provided for @mistakeBookMistakes.
  ///
  /// In en, this message translates to:
  /// **'{count} lesson mistakes'**
  String mistakeBookMistakes(Object count);

  /// No description provided for @mistakeBookMistakesPrefix.
  ///
  /// In en, this message translates to:
  /// **'{count} lesson mistakes'**
  String mistakeBookMistakesPrefix(Object count);

  /// No description provided for @mistakeBookSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quiz mistakes and weak custom cards are kept here for later review.'**
  String get mistakeBookSubtitle;

  /// No description provided for @mistakeBookFixLabel.
  ///
  /// In en, this message translates to:
  /// **'Fix Mistakes'**
  String get mistakeBookFixLabel;

  /// No description provided for @mistakeBookGoPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice a lesson'**
  String get mistakeBookGoPractice;

  /// No description provided for @mistakeBookCleared.
  ///
  /// In en, this message translates to:
  /// **'Mistake book cleared'**
  String get mistakeBookCleared;

  /// No description provided for @mistakeBookClearedMsg.
  ///
  /// In en, this message translates to:
  /// **'After quiz mistakes or marking custom word cards as forgotten, review items will appear here.'**
  String get mistakeBookClearedMsg;

  /// No description provided for @mistakeBookLessonMistakes.
  ///
  /// In en, this message translates to:
  /// **'Lesson Mistakes'**
  String get mistakeBookLessonMistakes;

  /// No description provided for @mistakeBookStartLesson.
  ///
  /// In en, this message translates to:
  /// **'Start a lesson'**
  String get mistakeBookStartLesson;

  /// No description provided for @mistakeBookWeakWords.
  ///
  /// In en, this message translates to:
  /// **'Weak Custom Words'**
  String get mistakeBookWeakWords;

  /// No description provided for @mistakeBookNoLessonMistakes.
  ///
  /// In en, this message translates to:
  /// **'No mistakes in the last lesson.'**
  String get mistakeBookNoLessonMistakes;

  /// No description provided for @mistakeBookNoWeakWords.
  ///
  /// In en, this message translates to:
  /// **'No weak custom words yet.'**
  String get mistakeBookNoWeakWords;

  /// No description provided for @labelTargetCET4.
  ///
  /// In en, this message translates to:
  /// **'CET-4 Core'**
  String get labelTargetCET4;

  /// No description provided for @labelTargetCET6.
  ///
  /// In en, this message translates to:
  /// **'CET-6 Core'**
  String get labelTargetCET6;

  /// No description provided for @labelTargetKaoyan.
  ///
  /// In en, this message translates to:
  /// **'Postgrad Core'**
  String get labelTargetKaoyan;

  /// No description provided for @labelTargetBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner Basic'**
  String get labelTargetBeginner;

  /// No description provided for @labelTargetMUET.
  ///
  /// In en, this message translates to:
  /// **'MUET High-Freq'**
  String get labelTargetMUET;

  /// No description provided for @labelTargetDailyEnglish.
  ///
  /// In en, this message translates to:
  /// **'Daily English'**
  String get labelTargetDailyEnglish;

  /// No description provided for @labelTargetBusinessEnglish.
  ///
  /// In en, this message translates to:
  /// **'Business English'**
  String get labelTargetBusinessEnglish;

  /// No description provided for @labelLevelBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get labelLevelBeginner;

  /// No description provided for @labelLevelElementary.
  ///
  /// In en, this message translates to:
  /// **'Elementary'**
  String get labelLevelElementary;

  /// No description provided for @labelLevelIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get labelLevelIntermediate;

  /// No description provided for @labelLevelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get labelLevelAdvanced;

  /// No description provided for @labelDifficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get labelDifficultyEasy;

  /// No description provided for @labelDifficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get labelDifficultyMedium;

  /// No description provided for @labelDifficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get labelDifficultyHard;

  /// No description provided for @labelStatusNew.
  ///
  /// In en, this message translates to:
  /// **'Not Learned'**
  String get labelStatusNew;

  /// No description provided for @labelStatusPreviewed.
  ///
  /// In en, this message translates to:
  /// **'Previewed'**
  String get labelStatusPreviewed;

  /// No description provided for @labelStatusLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get labelStatusLearning;

  /// No description provided for @labelStatusReview.
  ///
  /// In en, this message translates to:
  /// **'Reviewing'**
  String get labelStatusReview;

  /// No description provided for @labelStatusRelearning.
  ///
  /// In en, this message translates to:
  /// **'Relearning'**
  String get labelStatusRelearning;

  /// No description provided for @labelStatusMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get labelStatusMastered;

  /// No description provided for @labelStatusIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored'**
  String get labelStatusIgnored;

  /// No description provided for @labelQuestionTypeMeaningChoice.
  ///
  /// In en, this message translates to:
  /// **'EN→ZH'**
  String get labelQuestionTypeMeaningChoice;

  /// No description provided for @labelQuestionTypeChineseChoice.
  ///
  /// In en, this message translates to:
  /// **'ZH→EN'**
  String get labelQuestionTypeChineseChoice;

  /// No description provided for @labelQuestionTypeContextChoice.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get labelQuestionTypeContextChoice;

  /// No description provided for @labelQuestionTypeImageChoice.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get labelQuestionTypeImageChoice;

  /// No description provided for @labelQuestionTypeListeningWordChoice.
  ///
  /// In en, this message translates to:
  /// **'Listen→Word'**
  String get labelQuestionTypeListeningWordChoice;

  /// No description provided for @labelQuestionTypeListeningMeaningChoice.
  ///
  /// In en, this message translates to:
  /// **'Listen→Meaning'**
  String get labelQuestionTypeListeningMeaningChoice;

  /// No description provided for @labelQuestionTypeSpelling.
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get labelQuestionTypeSpelling;

  /// No description provided for @labelCustomTagCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get labelCustomTagCustom;

  /// No description provided for @labelCustomTagMistake.
  ///
  /// In en, this message translates to:
  /// **'Mistake'**
  String get labelCustomTagMistake;

  /// No description provided for @labelCustomTagCharacter.
  ///
  /// In en, this message translates to:
  /// **'Character'**
  String get labelCustomTagCharacter;

  /// No description provided for @labelWordTagAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get labelWordTagAcademic;

  /// No description provided for @labelWordTagBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get labelWordTagBeginner;

  /// No description provided for @labelWordTagBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get labelWordTagBusiness;

  /// No description provided for @labelWordTagCampus.
  ///
  /// In en, this message translates to:
  /// **'Campus'**
  String get labelWordTagCampus;

  /// No description provided for @labelWordTagDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get labelWordTagDaily;

  /// No description provided for @labelWordTagExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get labelWordTagExam;

  /// No description provided for @labelWordTagCET4.
  ///
  /// In en, this message translates to:
  /// **'CET-4'**
  String get labelWordTagCET4;

  /// No description provided for @labelWordTagCET6.
  ///
  /// In en, this message translates to:
  /// **'CET-6'**
  String get labelWordTagCET6;

  /// No description provided for @labelWordTagKaoyan.
  ///
  /// In en, this message translates to:
  /// **'Postgrad'**
  String get labelWordTagKaoyan;

  /// No description provided for @labelWordTagFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get labelWordTagFood;

  /// No description provided for @labelWordTagHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get labelWordTagHealth;

  /// No description provided for @labelWordTagStudy.
  ///
  /// In en, this message translates to:
  /// **'Study'**
  String get labelWordTagStudy;

  /// No description provided for @labelWordTagTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get labelWordTagTravel;

  /// No description provided for @labelWordTagWriting.
  ///
  /// In en, this message translates to:
  /// **'Writing'**
  String get labelWordTagWriting;

  /// No description provided for @labelWordTagDefault.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get labelWordTagDefault;

  /// No description provided for @wordbookTitle.
  ///
  /// In en, this message translates to:
  /// **'Wordbook'**
  String get wordbookTitle;

  /// No description provided for @wordbookSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words...'**
  String get wordbookSearchHint;

  /// No description provided for @wordbookNoResults.
  ///
  /// In en, this message translates to:
  /// **'No matching words found.'**
  String get wordbookNoResults;

  /// No description provided for @wordbookAllDifficulty.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get wordbookAllDifficulty;

  /// No description provided for @wordbookWeakDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get wordbookWeakDifficulty;

  /// No description provided for @wordbookCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Custom Words'**
  String get wordbookCustomWords;

  /// No description provided for @wordbookAddCustom.
  ///
  /// In en, this message translates to:
  /// **'Add Custom'**
  String get wordbookAddCustom;

  /// No description provided for @wordbookEditCustom.
  ///
  /// In en, this message translates to:
  /// **'Edit Custom Word'**
  String get wordbookEditCustom;

  /// No description provided for @wordbookWordDetail.
  ///
  /// In en, this message translates to:
  /// **'Word Detail'**
  String get wordbookWordDetail;

  /// No description provided for @wordbookMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get wordbookMeaning;

  /// No description provided for @wordbookExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get wordbookExample;

  /// No description provided for @wordbookPartOfSpeech.
  ///
  /// In en, this message translates to:
  /// **'Part of Speech'**
  String get wordbookPartOfSpeech;

  /// No description provided for @wordbookDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get wordbookDifficulty;

  /// No description provided for @wordbookMastery.
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get wordbookMastery;

  /// No description provided for @wordbookDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this word?'**
  String get wordbookDeleteConfirm;

  /// No description provided for @wordbookDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get wordbookDeleteMessage;

  /// No description provided for @wordbookImageBook.
  ///
  /// In en, this message translates to:
  /// **'Image Wordbook'**
  String get wordbookImageBook;

  /// No description provided for @wordbookCustomTooltip.
  ///
  /// In en, this message translates to:
  /// **'Custom Words'**
  String get wordbookCustomTooltip;

  /// No description provided for @wordbookWordsLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned {completed}/{total} words'**
  String wordbookWordsLearned(Object completed, Object total);

  /// No description provided for @wordbookTargetWords.
  ///
  /// In en, this message translates to:
  /// **'{count} target words'**
  String wordbookTargetWords(Object count);

  /// No description provided for @wordbookTotalWords.
  ///
  /// In en, this message translates to:
  /// **'{count} words'**
  String wordbookTotalWords(Object count);

  /// No description provided for @wordbookBookCount.
  ///
  /// In en, this message translates to:
  /// **'{count} wordbooks'**
  String wordbookBookCount(Object count);

  /// No description provided for @wordbookCompletion.
  ///
  /// In en, this message translates to:
  /// **'Completion {percent}%'**
  String wordbookCompletion(Object percent);

  /// No description provided for @wordbookSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch Wordbook'**
  String get wordbookSwitch;

  /// No description provided for @wordbookSwitchDesc.
  ///
  /// In en, this message translates to:
  /// **'Current wordbook drives home, learning path, search, training, and review entries.'**
  String get wordbookSwitchDesc;

  /// No description provided for @wordbookSwitched.
  ///
  /// In en, this message translates to:
  /// **'Wordbook switched'**
  String get wordbookSwitched;

  /// No description provided for @wordbookSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to switch wordbook'**
  String get wordbookSwitchFailed;

  /// No description provided for @pickerChooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get pickerChooseLanguage;

  /// No description provided for @pickerChooseWordbook.
  ///
  /// In en, this message translates to:
  /// **'Choose Wordbook'**
  String get pickerChooseWordbook;

  /// No description provided for @pickerLanguageChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese (中文)'**
  String get pickerLanguageChinese;

  /// No description provided for @pickerLanguageJapanese.
  ///
  /// In en, this message translates to:
  /// **'Japanese (日本語)'**
  String get pickerLanguageJapanese;

  /// No description provided for @pickerComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get pickerComingSoon;

  /// No description provided for @pickerCurrentBadge.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get pickerCurrentBadge;

  /// No description provided for @pickerSwitchSuccess.
  ///
  /// In en, this message translates to:
  /// **'Switched to {wordbook}'**
  String pickerSwitchSuccess(String wordbook);

  /// No description provided for @pickerSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to switch wordbook right now'**
  String get pickerSwitchFailed;

  /// No description provided for @wordbookTargetSection.
  ///
  /// In en, this message translates to:
  /// **'Target Words'**
  String get wordbookTargetSection;

  /// No description provided for @wordbookTargetDesc.
  ///
  /// In en, this message translates to:
  /// **'{count} words · Learning path {percent}% complete'**
  String wordbookTargetDesc(Object count, Object percent);

  /// No description provided for @wordbookNameBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner Basic Words'**
  String get wordbookNameBeginner;

  /// No description provided for @wordbookDescBeginner.
  ///
  /// In en, this message translates to:
  /// **'High-frequency words for beginners and daily expression.'**
  String get wordbookDescBeginner;

  /// No description provided for @wordbookNameCET4.
  ///
  /// In en, this message translates to:
  /// **'CET-4 Core Words'**
  String get wordbookNameCET4;

  /// No description provided for @wordbookDescCET4.
  ///
  /// In en, this message translates to:
  /// **'Core vocabulary for College English Test Band 4.'**
  String get wordbookDescCET4;

  /// No description provided for @wordbookNameCET6.
  ///
  /// In en, this message translates to:
  /// **'CET-6 Core Words'**
  String get wordbookNameCET6;

  /// No description provided for @wordbookDescCET6.
  ///
  /// In en, this message translates to:
  /// **'Core vocabulary for College English Test Band 6.'**
  String get wordbookDescCET6;

  /// No description provided for @wordbookNameKaoyan.
  ///
  /// In en, this message translates to:
  /// **'Postgrad Core Words'**
  String get wordbookNameKaoyan;

  /// No description provided for @wordbookDescKaoyan.
  ///
  /// In en, this message translates to:
  /// **'Core vocabulary for postgraduate entrance exams.'**
  String get wordbookDescKaoyan;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationTitle;

  /// No description provided for @dataAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Data & Account'**
  String get dataAccountTitle;

  /// No description provided for @notificationMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark All Read'**
  String get notificationMarkAllRead;

  /// No description provided for @notificationCenter.
  ///
  /// In en, this message translates to:
  /// **'Message Center'**
  String get notificationCenter;

  /// No description provided for @notificationCenterDesc.
  ///
  /// In en, this message translates to:
  /// **'Learning reminders, review due, check-in, and activity messages are gathered here.'**
  String get notificationCenterDesc;

  /// No description provided for @notificationUnreadCount.
  ///
  /// In en, this message translates to:
  /// **'{count} unread messages'**
  String notificationUnreadCount(Object count);

  /// No description provided for @notificationFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationFilterAll;

  /// No description provided for @notificationFilterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationFilterUnread;

  /// No description provided for @notificationFilterLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get notificationFilterLearning;

  /// No description provided for @notificationFilterActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get notificationFilterActivity;

  /// No description provided for @notificationEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching messages'**
  String get notificationEmptyTitle;

  /// No description provided for @notificationEmptyUnread.
  ///
  /// In en, this message translates to:
  /// **'No unread messages right now.'**
  String get notificationEmptyUnread;

  /// No description provided for @notificationEmptyAll.
  ///
  /// In en, this message translates to:
  /// **'After completing learning and review, learning reminders and activity messages will continue to be gathered here.'**
  String get notificationEmptyAll;

  /// No description provided for @notificationBackHome.
  ///
  /// In en, this message translates to:
  /// **'Back to Home'**
  String get notificationBackHome;

  /// No description provided for @notificationTypeLearningReminder.
  ///
  /// In en, this message translates to:
  /// **'Learning Reminder'**
  String get notificationTypeLearningReminder;

  /// No description provided for @notificationTypeReviewDue.
  ///
  /// In en, this message translates to:
  /// **'Review Due'**
  String get notificationTypeReviewDue;

  /// No description provided for @notificationTypeCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Check-in Reminder'**
  String get notificationTypeCheckIn;

  /// No description provided for @notificationTypeActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity Message'**
  String get notificationTypeActivity;

  /// No description provided for @notificationLearningReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s study plan is waiting'**
  String get notificationLearningReminderTitle;

  /// No description provided for @notificationLearningReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Today\'s goal: {dailyGoal} new words. Start with your current wordbook.'**
  String notificationLearningReminderBody(int dailyGoal);

  /// No description provided for @notificationReviewDueTitle.
  ///
  /// In en, this message translates to:
  /// **'{dueCount} words due for review'**
  String notificationReviewDueTitle(int dueCount);

  /// No description provided for @notificationReviewDueBody.
  ///
  /// In en, this message translates to:
  /// **'Clear your review queue first — missed words move to the reinforcement stage.'**
  String get notificationReviewDueBody;

  /// No description provided for @notificationCheckInTitle.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t checked in today'**
  String get notificationCheckInTitle;

  /// No description provided for @notificationCheckInBody.
  ///
  /// In en, this message translates to:
  /// **'Tap check-in on the Discover page to unlock the claimable task.'**
  String get notificationCheckInBody;

  /// No description provided for @notificationActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover point tasks refreshed'**
  String get notificationActivityTitle;

  /// No description provided for @notificationActivityBody.
  ///
  /// In en, this message translates to:
  /// **'Earn XP after finishing new words, reviews, and clearing missed words.'**
  String get notificationActivityBody;

  /// No description provided for @notificationLotteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Lottery result'**
  String get notificationLotteryTitle;

  /// No description provided for @notificationLotteryBody.
  ///
  /// In en, this message translates to:
  /// **'You won \"{prizeName}\" — added to your assets.'**
  String notificationLotteryBody(String prizeName);

  /// No description provided for @osNotificationStudyReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your study tasks are ready'**
  String get osNotificationStudyReminderTitle;

  /// No description provided for @osNotificationStudyReminderBody.
  ///
  /// In en, this message translates to:
  /// **'Finish new words, reviews and check-in to keep your streak going.'**
  String get osNotificationStudyReminderBody;

  /// No description provided for @osNotificationReviewDueBody.
  ///
  /// In en, this message translates to:
  /// **'Clear your review queue, then start today\'s new words.'**
  String get osNotificationReviewDueBody;

  /// No description provided for @osNotificationChannelName.
  ///
  /// In en, this message translates to:
  /// **'Study reminders'**
  String get osNotificationChannelName;

  /// No description provided for @osNotificationChannelDescription.
  ///
  /// In en, this message translates to:
  /// **'Study reminders, review-due and check-in alerts'**
  String get osNotificationChannelDescription;

  /// No description provided for @studyNewStudy.
  ///
  /// In en, this message translates to:
  /// **'New Study'**
  String get studyNewStudy;

  /// No description provided for @studyReviewOnly.
  ///
  /// In en, this message translates to:
  /// **'Review Only'**
  String get studyReviewOnly;

  /// No description provided for @studyStartSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get studyStartSession;

  /// No description provided for @studySessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Session Complete'**
  String get studySessionComplete;

  /// No description provided for @studyWordsLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} words left'**
  String studyWordsLeft(Object count);

  /// No description provided for @studyPlanLoginRequired.
  ///
  /// In en, this message translates to:
  /// **'Please log in before setting up a study plan.'**
  String get studyPlanLoginRequired;

  /// No description provided for @studyPlanSave.
  ///
  /// In en, this message translates to:
  /// **'Save Study Plan'**
  String get studyPlanSave;

  /// No description provided for @studyPlanSettings.
  ///
  /// In en, this message translates to:
  /// **'Study Plan Settings'**
  String get studyPlanSettings;

  /// No description provided for @studyPlanSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage current wordbook, daily tasks, review rhythm, and reminder time.'**
  String get studyPlanSettingsDesc;

  /// No description provided for @studyPlanViewWords.
  ///
  /// In en, this message translates to:
  /// **'View Full Wordbook'**
  String get studyPlanViewWords;

  /// No description provided for @studyPlanDailyNew.
  ///
  /// In en, this message translates to:
  /// **'Daily New Words'**
  String get studyPlanDailyNew;

  /// No description provided for @studyPlanDailyNewHint.
  ///
  /// In en, this message translates to:
  /// **'Recommended 5-30 words, max 200.'**
  String get studyPlanDailyNewHint;

  /// No description provided for @studyPlanReminderTime.
  ///
  /// In en, this message translates to:
  /// **'Study Reminder Time'**
  String get studyPlanReminderTime;

  /// No description provided for @studyPlanResume.
  ///
  /// In en, this message translates to:
  /// **'Resume Plan'**
  String get studyPlanResume;

  /// No description provided for @studyPlanPause.
  ///
  /// In en, this message translates to:
  /// **'Pause Plan'**
  String get studyPlanPause;

  /// No description provided for @studyPlanReset.
  ///
  /// In en, this message translates to:
  /// **'Reset Plan'**
  String get studyPlanReset;

  /// No description provided for @studyPlanResetConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm reset study plan?'**
  String get studyPlanResetConfirm;

  /// No description provided for @studyPlanResetDesc.
  ///
  /// In en, this message translates to:
  /// **'Reset will clear current wordbook learning path progress, and reset custom word mastery, correct/wrong counts, and review times; review queue will be regenerated. This affects learning progress and review schedule.'**
  String get studyPlanResetDesc;

  /// No description provided for @studyPlanCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get studyPlanCancel;

  /// No description provided for @studyPlanConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm Reset'**
  String get studyPlanConfirm;

  /// No description provided for @studyPlanSaved.
  ///
  /// In en, this message translates to:
  /// **'Study plan saved.'**
  String get studyPlanSaved;

  /// No description provided for @studyPlanSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save plan.'**
  String get studyPlanSaveFailed;

  /// No description provided for @studyPlanResumed.
  ///
  /// In en, this message translates to:
  /// **'Study plan resumed.'**
  String get studyPlanResumed;

  /// No description provided for @studyPlanPaused.
  ///
  /// In en, this message translates to:
  /// **'Study plan paused. Today\'s reminders and task entries will be temporarily closed.'**
  String get studyPlanPaused;

  /// No description provided for @studyPlanPauseFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update plan status.'**
  String get studyPlanPauseFailed;

  /// No description provided for @studyPlanResetDone.
  ///
  /// In en, this message translates to:
  /// **'Study plan reset.'**
  String get studyPlanResetDone;

  /// No description provided for @studyPlanResetFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to reset plan.'**
  String get studyPlanResetFailed;

  /// No description provided for @studyPlanEnterNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a number'**
  String get studyPlanEnterNumber;

  /// No description provided for @studyPlanNumberRange.
  ///
  /// In en, this message translates to:
  /// **'Range must be {min}-{max}'**
  String studyPlanNumberRange(Object max, Object min);

  /// No description provided for @studyPlanDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String studyPlanDaysLeft(Object count);

  /// No description provided for @studyPlanActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get studyPlanActive;

  /// No description provided for @studyPlanPausedLabel.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get studyPlanPausedLabel;

  /// No description provided for @aiLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Learning'**
  String get aiLearningTitle;

  /// No description provided for @aiLearningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Reading, writing, and practice'**
  String get aiLearningSubtitle;

  /// No description provided for @aiLearningComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI learning features coming soon.'**
  String get aiLearningComingSoon;

  /// No description provided for @aiLearningDesc.
  ///
  /// In en, this message translates to:
  /// **'Explain grammar, distinguish word meanings, generate context; formal learning records are still updated by quiz results.'**
  String get aiLearningDesc;

  /// No description provided for @aiLearningTooltip.
  ///
  /// In en, this message translates to:
  /// **'Q&A'**
  String get aiLearningTooltip;

  /// No description provided for @aiLearningPillError.
  ///
  /// In en, this message translates to:
  /// **'Error Explanation'**
  String get aiLearningPillError;

  /// No description provided for @aiLearningPillNoKey.
  ///
  /// In en, this message translates to:
  /// **'No Client Key Required'**
  String get aiLearningPillNoKey;

  /// No description provided for @aiLearningCurrentWord.
  ///
  /// In en, this message translates to:
  /// **'Current Word'**
  String get aiLearningCurrentWord;

  /// No description provided for @aiLearningToolsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tool List'**
  String get aiLearningToolsTitle;

  /// No description provided for @aiLearningToolsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'First version focuses on long sentence analysis and Q&A; writing correction comes later.'**
  String get aiLearningToolsSubtitle;

  /// No description provided for @aiLearningToolAiQA.
  ///
  /// In en, this message translates to:
  /// **'AI Q&A'**
  String get aiLearningToolAiQA;

  /// No description provided for @aiLearningToolAiQADesc.
  ///
  /// In en, this message translates to:
  /// **'Answer questions about word meaning, grammar, and expression naturalness based on current words, examples, and learning goals.'**
  String get aiLearningToolAiQADesc;

  /// No description provided for @aiLearningToolAiAnalysis.
  ///
  /// In en, this message translates to:
  /// **'AI Long Sentence Analysis'**
  String get aiLearningToolAiAnalysis;

  /// No description provided for @aiLearningToolAiAnalysisDesc.
  ///
  /// In en, this message translates to:
  /// **'Extract main clauses, divide subordinate clauses, explain modifiers and key words, and provide natural Chinese translation.'**
  String get aiLearningToolAiAnalysisDesc;

  /// No description provided for @aiLearningToolAiWriting.
  ///
  /// In en, this message translates to:
  /// **'AI Writing Correction'**
  String get aiLearningToolAiWriting;

  /// No description provided for @aiLearningToolAiWritingDesc.
  ///
  /// In en, this message translates to:
  /// **'Select exam type, enter topic and body text, output total score, itemized scores, and paragraph-by-paragraph revision suggestions.'**
  String get aiLearningToolAiWritingDesc;

  /// No description provided for @aiLearningToolCloze.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Word Cloze'**
  String get aiLearningToolCloze;

  /// No description provided for @aiLearningToolClozeDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate short passages based on today\'s new words, mistake words, or this week\'s weak words, with 5 to 10 target words blanked out.'**
  String get aiLearningToolClozeDesc;

  /// No description provided for @aiLearningToolConfusion.
  ///
  /// In en, this message translates to:
  /// **'Confusable Words'**
  String get aiLearningToolConfusion;

  /// No description provided for @aiLearningToolConfusionDesc.
  ///
  /// In en, this message translates to:
  /// **'Explain usage scenarios of near-synonyms or confusable words like affect/effect based on mistake records.'**
  String get aiLearningToolConfusionDesc;

  /// No description provided for @aiLearningToolSentence.
  ///
  /// In en, this message translates to:
  /// **'Sentence Generation & Rewrite'**
  String get aiLearningToolSentence;

  /// No description provided for @aiLearningToolSentenceDesc.
  ///
  /// In en, this message translates to:
  /// **'Generate more natural example sentences based on exam goals, with one-click add to notes or wordbook.'**
  String get aiLearningToolSentenceDesc;

  /// No description provided for @aiLearningStatusSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get aiLearningStatusSoon;

  /// No description provided for @aiLearningStatusLater.
  ///
  /// In en, this message translates to:
  /// **'Coming Later'**
  String get aiLearningStatusLater;

  /// No description provided for @aiLearningStatusPlanning.
  ///
  /// In en, this message translates to:
  /// **'In Planning'**
  String get aiLearningStatusPlanning;

  /// No description provided for @questTitle.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get questTitle;

  /// No description provided for @questDailyQuests.
  ///
  /// In en, this message translates to:
  /// **'Daily Quests'**
  String get questDailyQuests;

  /// No description provided for @questProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get questProgress;

  /// No description provided for @searchTitle.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search words, phrases, examples...'**
  String get searchHint;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found.'**
  String get searchNoResults;

  /// No description provided for @searchRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get searchRecent;

  /// No description provided for @searchStartTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter a keyword to start searching'**
  String get searchStartTitle;

  /// No description provided for @searchStartMessage.
  ///
  /// In en, this message translates to:
  /// **'Search English words, phrases, Chinese meanings, example snippets, and custom words.'**
  String get searchStartMessage;

  /// No description provided for @searchNoResultsTitle.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get searchNoResultsTitle;

  /// No description provided for @searchNoResultsMessage.
  ///
  /// In en, this message translates to:
  /// **'Try the full word library, or add a personal word card.'**
  String get searchNoResultsMessage;

  /// No description provided for @searchFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Search words, phrases, Chinese meanings, or example snippets'**
  String get searchFieldLabel;

  /// No description provided for @searchScopeSummary.
  ///
  /// In en, this message translates to:
  /// **'Scope: {currentBookTitle} / {allWordBooksLabel}'**
  String searchScopeSummary(Object allWordBooksLabel, Object currentBookTitle);

  /// No description provided for @searchCurrentWordbookScope.
  ///
  /// In en, this message translates to:
  /// **'Current wordbook'**
  String get searchCurrentWordbookScope;

  /// No description provided for @searchAllWordbooksScope.
  ///
  /// In en, this message translates to:
  /// **'Full library'**
  String get searchAllWordbooksScope;

  /// No description provided for @searchCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'Current plan'**
  String get searchCurrentPlan;

  /// No description provided for @customWordsMyCards.
  ///
  /// In en, this message translates to:
  /// **'My word cards'**
  String get customWordsMyCards;

  /// No description provided for @customWordsMyCardsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create, search, filter, edit, and review your personal word library.'**
  String get customWordsMyCardsSubtitle;

  /// No description provided for @customWordsCardCount.
  ///
  /// In en, this message translates to:
  /// **'{count} cards'**
  String customWordsCardCount(Object count);

  /// No description provided for @customWordsSearchLabel.
  ///
  /// In en, this message translates to:
  /// **'Search words, meanings, or tags'**
  String get customWordsSearchLabel;

  /// No description provided for @customWordsNoMatchTitle.
  ///
  /// In en, this message translates to:
  /// **'No matching word cards'**
  String get customWordsNoMatchTitle;

  /// No description provided for @customWordsNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Add a personal word card, or adjust the search filters.'**
  String get customWordsNoMatchMessage;

  /// No description provided for @customWordsAddCard.
  ///
  /// In en, this message translates to:
  /// **'Add custom word card'**
  String get customWordsAddCard;

  /// No description provided for @customWordsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{word}\"?'**
  String customWordsDeleteTitle(Object word);

  /// No description provided for @customWordsDeleteContent.
  ///
  /// In en, this message translates to:
  /// **'This also deletes this personal word card and its review plan.'**
  String get customWordsDeleteContent;

  /// No description provided for @customWordsEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit word'**
  String get customWordsEditTitle;

  /// No description provided for @customWordsAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add word'**
  String get customWordsAddTitle;

  /// No description provided for @customWordsFieldWord.
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get customWordsFieldWord;

  /// No description provided for @customWordsFieldMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get customWordsFieldMeaning;

  /// No description provided for @customWordsFieldExample.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get customWordsFieldExample;

  /// No description provided for @customWordsFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get customWordsFieldNote;

  /// No description provided for @customWordsFieldTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get customWordsFieldTag;

  /// No description provided for @customWordsSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get customWordsSaveEdit;

  /// No description provided for @customWordsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create word'**
  String get customWordsCreate;

  /// No description provided for @customWordsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save this word for now'**
  String get customWordsSaveFailed;

  /// No description provided for @customWordsSaved.
  ///
  /// In en, this message translates to:
  /// **'Word saved'**
  String get customWordsSaved;

  /// No description provided for @customWordsAlreadyInWordbook.
  ///
  /// In en, this message translates to:
  /// **'This word is already in your wordbook'**
  String get customWordsAlreadyInWordbook;

  /// No description provided for @customWordsDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get customWordsDifficulty;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @customWordsDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to delete {word} right now'**
  String customWordsDeleteFailed(Object word);

  /// No description provided for @customWordsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {word}'**
  String customWordsDeleted(Object word);

  /// No description provided for @wordbookWordNotFound.
  ///
  /// In en, this message translates to:
  /// **'Word not found'**
  String get wordbookWordNotFound;

  /// No description provided for @wordbookFavorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get wordbookFavorite;

  /// No description provided for @wordbookFavorited.
  ///
  /// In en, this message translates to:
  /// **'Favorited'**
  String get wordbookFavorited;

  /// No description provided for @wordbookFavoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get wordbookFavoriteRemoved;

  /// No description provided for @wordbookAddToCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Add to custom words'**
  String get wordbookAddToCustomWords;

  /// No description provided for @wordbookRemoveCustomWord.
  ///
  /// In en, this message translates to:
  /// **'Remove from custom words'**
  String get wordbookRemoveCustomWord;

  /// No description provided for @wordbookAddedToCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Added to custom words'**
  String get wordbookAddedToCustomWords;

  /// No description provided for @wordbookRemovedFromCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Removed from custom words'**
  String get wordbookRemovedFromCustomWords;

  /// No description provided for @wordbookResumeLearning.
  ///
  /// In en, this message translates to:
  /// **'Resume learning'**
  String get wordbookResumeLearning;

  /// No description provided for @wordbookIgnoreEasy.
  ///
  /// In en, this message translates to:
  /// **'Ignore as too easy'**
  String get wordbookIgnoreEasy;

  /// No description provided for @wordbookLearningResumed.
  ///
  /// In en, this message translates to:
  /// **'Learning resumed'**
  String get wordbookLearningResumed;

  /// No description provided for @wordbookIgnored.
  ///
  /// In en, this message translates to:
  /// **'Ignored and excluded from future review queues'**
  String get wordbookIgnored;

  /// No description provided for @wordbookUpdateTargetFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to update target word right now'**
  String get wordbookUpdateTargetFailed;

  /// No description provided for @wordbookCurrentPlan.
  ///
  /// In en, this message translates to:
  /// **'In current plan'**
  String get wordbookCurrentPlan;

  /// No description provided for @wordbookHighFrequencyDefinition.
  ///
  /// In en, this message translates to:
  /// **'High-frequency exam meaning'**
  String get wordbookHighFrequencyDefinition;

  /// No description provided for @wordbookUkPhonetic.
  ///
  /// In en, this message translates to:
  /// **'UK /{phonetic}/'**
  String wordbookUkPhonetic(Object phonetic);

  /// No description provided for @wordbookUsPhonetic.
  ///
  /// In en, this message translates to:
  /// **'US /{phonetic}/'**
  String wordbookUsPhonetic(Object phonetic);

  /// No description provided for @wordbookBilingualDefinitions.
  ///
  /// In en, this message translates to:
  /// **'Chinese and English definitions'**
  String get wordbookBilingualDefinitions;

  /// No description provided for @wordbookChineseDefinitions.
  ///
  /// In en, this message translates to:
  /// **'Chinese definitions'**
  String get wordbookChineseDefinitions;

  /// No description provided for @wordbookEnglishDefinitions.
  ///
  /// In en, this message translates to:
  /// **'English definitions'**
  String get wordbookEnglishDefinitions;

  /// No description provided for @wordbookMalayDefinitions.
  ///
  /// In en, this message translates to:
  /// **'Malay definitions'**
  String get wordbookMalayDefinitions;

  /// No description provided for @wordbookHighFrequency.
  ///
  /// In en, this message translates to:
  /// **'High frequency'**
  String get wordbookHighFrequency;

  /// No description provided for @wordbookContextExamples.
  ///
  /// In en, this message translates to:
  /// **'Context examples'**
  String get wordbookContextExamples;

  /// No description provided for @wordbookMasteryLevel.
  ///
  /// In en, this message translates to:
  /// **'Mastery {level}/5'**
  String wordbookMasteryLevel(Object level);

  /// No description provided for @reviewStudyManageQueue.
  ///
  /// In en, this message translates to:
  /// **'Manage review queue'**
  String get reviewStudyManageQueue;

  /// No description provided for @reviewStudyTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review'**
  String get reviewStudyTodayTitle;

  /// No description provided for @reviewStudyTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recall first, then reveal the answer; missed cards return later in this round for reinforcement.'**
  String get reviewStudyTodaySubtitle;

  /// No description provided for @reviewStudyLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave review?'**
  String get reviewStudyLeaveTitle;

  /// No description provided for @reviewStudyLeaveContent.
  ///
  /// In en, this message translates to:
  /// **'Completed cards have been saved; unfinished cards will stay in the review queue.'**
  String get reviewStudyLeaveContent;

  /// No description provided for @reviewStudyKeepReviewing.
  ///
  /// In en, this message translates to:
  /// **'Keep reviewing'**
  String get reviewStudyKeepReviewing;

  /// No description provided for @reviewStudyReinforced.
  ///
  /// In en, this message translates to:
  /// **'This reinforcement round is complete'**
  String get reviewStudyReinforced;

  /// No description provided for @reviewStudyRememberedMessage.
  ///
  /// In en, this message translates to:
  /// **'Remembered. The review interval has been extended.'**
  String get reviewStudyRememberedMessage;

  /// No description provided for @reviewStudyNeedsReinforcementMessage.
  ///
  /// In en, this message translates to:
  /// **'Marked for reinforcement. Practice it again later.'**
  String get reviewStudyNeedsReinforcementMessage;

  /// No description provided for @reviewStudyReinforce.
  ///
  /// In en, this message translates to:
  /// **'Add to reinforcement queue'**
  String get reviewStudyReinforce;

  /// No description provided for @reviewStudyCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s review complete'**
  String get reviewStudyCompleteTitle;

  /// No description provided for @reviewStudyCompleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Next review times have been updated for this round.'**
  String get reviewStudyCompleteMessage;

  /// No description provided for @reviewStudyRecallHint.
  ///
  /// In en, this message translates to:
  /// **'Recall the Chinese meaning from the English word first. If you remember it, move on; if not, reveal the knowledge card.'**
  String get reviewStudyRecallHint;

  /// No description provided for @reviewStudyNextReview.
  ///
  /// In en, this message translates to:
  /// **'Next review: {due}'**
  String reviewStudyNextReview(Object due);

  /// No description provided for @reviewStudyHiddenHint.
  ///
  /// In en, this message translates to:
  /// **'Correct answers continue smoothly; wrong answers reveal the knowledge card and return later in this round.'**
  String get reviewStudyHiddenHint;

  /// No description provided for @aiWordSupportDesc.
  ///
  /// In en, this message translates to:
  /// **'Ask about {word} usage, grammar, synonym differences, and example breakdowns.'**
  String aiWordSupportDesc(Object word);

  /// No description provided for @aiWordSupportWithExampleDesc.
  ///
  /// In en, this message translates to:
  /// **'Send {word} and the current example to ask about usage, grammar, synonym differences, and example breakdowns.'**
  String aiWordSupportWithExampleDesc(Object word);

  /// No description provided for @helpFaqReviewScheduleQ.
  ///
  /// In en, this message translates to:
  /// **'How is review time scheduled?'**
  String get helpFaqReviewScheduleQ;

  /// No description provided for @helpFaqReviewScheduleA.
  ///
  /// In en, this message translates to:
  /// **'Each word moves between mastery levels 0-5. Higher mastery means a longer interval before the next review.'**
  String get helpFaqReviewScheduleA;

  /// No description provided for @helpFaqCustomWordsQ.
  ///
  /// In en, this message translates to:
  /// **'Can I add my own words?'**
  String get helpFaqCustomWordsQ;

  /// No description provided for @helpFaqCustomWordsA.
  ///
  /// In en, this message translates to:
  /// **'Yes. Open the wordbook or custom words page, then tap add to create a personal word card.'**
  String get helpFaqCustomWordsA;

  /// No description provided for @helpFaqAiTutorQ.
  ///
  /// In en, this message translates to:
  /// **'What can the AI tutor do?'**
  String get helpFaqAiTutorQ;

  /// No description provided for @helpFaqAiTutorA.
  ///
  /// In en, this message translates to:
  /// **'It can explain words, grammar, and mistakes, and suggest examples for further practice.'**
  String get helpFaqAiTutorA;

  /// No description provided for @helpContactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get helpContactSupport;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest · Version {version}'**
  String aboutVersion(String version);

  /// No description provided for @aboutIntro.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest brings word cards, learning paths, spaced review, XP, streaks, and personal word cards into a mobile-first English learning app.'**
  String get aboutIntro;

  /// No description provided for @aboutGoalTitle.
  ///
  /// In en, this message translates to:
  /// **'Project goal'**
  String get aboutGoalTitle;

  /// No description provided for @aboutGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Help learners build a daily English study habit through short lessons, mistake repair, and visible progress.'**
  String get aboutGoalSubtitle;

  /// No description provided for @aboutTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Development team'**
  String get aboutTeamTitle;

  /// No description provided for @aboutTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'ASM2 Mobile team. Focused on a mobile-first English learning experience.'**
  String get aboutTeamSubtitle;

  /// No description provided for @aboutCoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Core experience'**
  String get aboutCoreTitle;

  /// No description provided for @aboutCoreSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Goal planning, vocabulary building, quiz practice, review scheduling, and personal word cards.'**
  String get aboutCoreSubtitle;

  /// No description provided for @aboutPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get aboutPrivacyTitle;

  /// No description provided for @aboutPrivacySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom words and learning records belong only to the signed-in user.'**
  String get aboutPrivacySubtitle;

  /// No description provided for @communityPostCheckinTitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s check-in: Reviewed 18 words in 12 minutes'**
  String get communityPostCheckinTitle;

  /// No description provided for @communityPostCheckinTag.
  ///
  /// In en, this message translates to:
  /// **'Daily Check-in'**
  String get communityPostCheckinTag;

  /// No description provided for @communityPostCheckinBody.
  ///
  /// In en, this message translates to:
  /// **'Mistakes were mostly synonyms. Tomorrow I\'ll start with the confusing words challenge in training.'**
  String get communityPostCheckinBody;

  /// No description provided for @communityPostAbstractTitle.
  ///
  /// In en, this message translates to:
  /// **'How to remember the word \'abstract\'?'**
  String get communityPostAbstractTitle;

  /// No description provided for @communityPostMistakeTag.
  ///
  /// In en, this message translates to:
  /// **'Mistake Discussion'**
  String get communityPostMistakeTag;

  /// No description provided for @communityPostAbstractBody.
  ///
  /// In en, this message translates to:
  /// **'\"abstract\" in academic contexts often does not mean \"not concrete\"; context matters.'**
  String get communityPostAbstractBody;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// No description provided for @languageSetting.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSetting;

  /// No description provided for @luckyDrawCostLine.
  ///
  /// In en, this message translates to:
  /// **'Spend {cost} XP per draw'**
  String luckyDrawCostLine(Object cost);

  /// No description provided for @luckyDrawBalanceHint.
  ///
  /// In en, this message translates to:
  /// **'Current balance {xp} XP; prizes include avatar frames, profile backgrounds, badges, titles, card skins, and consolation fragments.'**
  String luckyDrawBalanceHint(Object xp);

  /// No description provided for @luckyDrawInventoryCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item in stock} other{{count} items in stock}}'**
  String luckyDrawInventoryCount(num count);

  /// No description provided for @luckyDrawNoBoost.
  ///
  /// In en, this message translates to:
  /// **'No learning boost'**
  String get luckyDrawNoBoost;

  /// No description provided for @luckyDrawNow.
  ///
  /// In en, this message translates to:
  /// **'Draw now'**
  String get luckyDrawNow;

  /// No description provided for @luckyDrawInsufficient.
  ///
  /// In en, this message translates to:
  /// **'Not enough XP — finish tasks first'**
  String get luckyDrawInsufficient;

  /// No description provided for @luckyDrawShortfall.
  ///
  /// In en, this message translates to:
  /// **'{shortfall} XP to go. Finish new study, review, or mistake cleanup to earn points.'**
  String luckyDrawShortfall(Object shortfall);

  /// No description provided for @luckyDrawFailed.
  ///
  /// In en, this message translates to:
  /// **'Draw failed, please try again later'**
  String get luckyDrawFailed;

  /// No description provided for @luckyDrawSuccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Draw successful'**
  String get luckyDrawSuccessTitle;

  /// No description provided for @luckyDrawReward.
  ///
  /// In en, this message translates to:
  /// **'You got: {name}'**
  String luckyDrawReward(Object name);

  /// No description provided for @luckyDrawDeducted.
  ///
  /// In en, this message translates to:
  /// **'Deducted {cost} XP, {balance} XP remaining.'**
  String luckyDrawDeducted(Object balance, Object cost);

  /// No description provided for @luckyDrawKeepLooking.
  ///
  /// In en, this message translates to:
  /// **'Keep looking'**
  String get luckyDrawKeepLooking;

  /// No description provided for @luckyDrawViewAssets.
  ///
  /// In en, this message translates to:
  /// **'View my assets'**
  String get luckyDrawViewAssets;

  /// No description provided for @luckyDrawPoolLoading.
  ///
  /// In en, this message translates to:
  /// **'Prize pool loading: avatar frames, profile backgrounds, learning badges, training titles, card skins, consolation fragments.'**
  String get luckyDrawPoolLoading;

  /// No description provided for @profileAssetsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Assets'**
  String get profileAssetsTitle;

  /// No description provided for @profileAssetsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Decorative assets won from draws are for display only and don\'t affect learning scores.'**
  String get profileAssetsSubtitle;

  /// No description provided for @profileAssetsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No Assets Yet'**
  String get profileAssetsEmpty;

  /// No description provided for @profileAssetMeta.
  ///
  /// In en, this message translates to:
  /// **'{category} · Qty {quantity} · Fragments {fragments}'**
  String profileAssetMeta(Object category, Object fragments, Object quantity);

  /// No description provided for @lotteryCategoryAvatarFrame.
  ///
  /// In en, this message translates to:
  /// **'Avatar Frame'**
  String get lotteryCategoryAvatarFrame;

  /// No description provided for @lotteryCategoryProfileBackground.
  ///
  /// In en, this message translates to:
  /// **'Profile Background'**
  String get lotteryCategoryProfileBackground;

  /// No description provided for @lotteryCategoryBadge.
  ///
  /// In en, this message translates to:
  /// **'Learning Badge'**
  String get lotteryCategoryBadge;

  /// No description provided for @lotteryCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Title'**
  String get lotteryCategoryTitle;

  /// No description provided for @lotteryCategoryCardSkin.
  ///
  /// In en, this message translates to:
  /// **'Card Skin'**
  String get lotteryCategoryCardSkin;

  /// No description provided for @lotteryCategoryFragment.
  ///
  /// In en, this message translates to:
  /// **'Consolation Fragment'**
  String get lotteryCategoryFragment;

  /// No description provided for @lotteryCategoryDefault.
  ///
  /// In en, this message translates to:
  /// **'Decorative Asset'**
  String get lotteryCategoryDefault;

  /// No description provided for @lotteryRarityRare.
  ///
  /// In en, this message translates to:
  /// **'Rare'**
  String get lotteryRarityRare;

  /// No description provided for @lotteryRarityUncommon.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get lotteryRarityUncommon;

  /// No description provided for @lotteryRarityCommon.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get lotteryRarityCommon;

  /// No description provided for @lotteryRarityComfort.
  ///
  /// In en, this message translates to:
  /// **'Comfort'**
  String get lotteryRarityComfort;

  /// No description provided for @languageChinese.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get languageChinese;

  /// No description provided for @languageMalay.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Melayu'**
  String get languageMalay;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @wordKnowledgeTitle.
  ///
  /// In en, this message translates to:
  /// **'Word breakdown'**
  String get wordKnowledgeTitle;

  /// No description provided for @wordKnowledgeCollocations.
  ///
  /// In en, this message translates to:
  /// **'Collocations'**
  String get wordKnowledgeCollocations;

  /// No description provided for @wordKnowledgeSynAnt.
  ///
  /// In en, this message translates to:
  /// **'Synonyms / Antonyms'**
  String get wordKnowledgeSynAnt;

  /// No description provided for @wordKnowledgeFamily.
  ///
  /// In en, this message translates to:
  /// **'Word family'**
  String get wordKnowledgeFamily;

  /// No description provided for @wordKnowledgeRoots.
  ///
  /// In en, this message translates to:
  /// **'Roots & affixes'**
  String get wordKnowledgeRoots;

  /// No description provided for @pronunciationAccentUk.
  ///
  /// In en, this message translates to:
  /// **'UK'**
  String get pronunciationAccentUk;

  /// No description provided for @pronunciationAccentUs.
  ///
  /// In en, this message translates to:
  /// **'US'**
  String get pronunciationAccentUs;

  /// No description provided for @pronunciationAnnounce.
  ///
  /// In en, this message translates to:
  /// **'{accent} {word}'**
  String pronunciationAnnounce(String accent, String word);

  /// No description provided for @pronunciationPlaying.
  ///
  /// In en, this message translates to:
  /// **'{accent}: {word}'**
  String pronunciationPlaying(String accent, String word);

  /// No description provided for @pronunciationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'{accent} audio unavailable'**
  String pronunciationUnavailable(String accent);

  /// No description provided for @pronunciationFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'{accent} playback failed, tap to retry'**
  String pronunciationFailedRetry(String accent);

  /// No description provided for @pronunciationLoading.
  ///
  /// In en, this message translates to:
  /// **'{accent} loading'**
  String pronunciationLoading(String accent);

  /// No description provided for @pronunciationRetry.
  ///
  /// In en, this message translates to:
  /// **'{accent} retry'**
  String pronunciationRetry(String accent);

  /// No description provided for @dueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get dueNow;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'In {count} days'**
  String dueInDays(int count);

  /// No description provided for @dueInHours.
  ///
  /// In en, this message translates to:
  /// **'In {count} hours'**
  String dueInHours(int count);

  /// No description provided for @dueInMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {count} minutes'**
  String dueInMinutes(int count);

  /// No description provided for @languageMapTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get languageMapTitle;

  /// No description provided for @languageMapSelectPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap a country to choose the language you want to learn.'**
  String get languageMapSelectPrompt;

  /// No description provided for @languageMapChinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese (中文)'**
  String get languageMapChinese;

  /// No description provided for @languageMapConfirm.
  ///
  /// In en, this message translates to:
  /// **'Learn {language}'**
  String languageMapConfirm(String language);

  /// No description provided for @languageMapSelected.
  ///
  /// In en, this message translates to:
  /// **'Now learning {language}'**
  String languageMapSelected(String language);

  /// No description provided for @languageMapComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{language} — coming soon'**
  String languageMapComingSoon(String language);

  /// No description provided for @aboutCompanyName.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest'**
  String get aboutCompanyName;

  /// No description provided for @aboutCompanyAddress.
  ///
  /// In en, this message translates to:
  /// **'Xiamen University Malaysia, Bandar Sunsuria, 43900 Sepang, Selangor, Malaysia (virtual)'**
  String get aboutCompanyAddress;

  /// No description provided for @aboutCompanyDescription.
  ///
  /// In en, this message translates to:
  /// **'Our virtual campus where LinguaQuest is built.'**
  String get aboutCompanyDescription;

  /// No description provided for @aiLearningStatusAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get aiLearningStatusAvailable;

  /// No description provided for @aiExplainWithAi.
  ///
  /// In en, this message translates to:
  /// **'Explain with AI'**
  String get aiExplainWithAi;

  /// No description provided for @aiErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get aiErrorGeneric;

  /// No description provided for @aiEmptyChat.
  ///
  /// In en, this message translates to:
  /// **'Ask anything about {language} — meanings, grammar, or usage.'**
  String aiEmptyChat(Object language);

  /// No description provided for @aiQuestionHint.
  ///
  /// In en, this message translates to:
  /// **'Type your question about {language}...'**
  String aiQuestionHint(Object language);

  /// No description provided for @aiEmptyAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Paste a {language} sentence to see its structure broken down.'**
  String aiEmptyAnalysis(Object language);

  /// No description provided for @aiEmptyCloze.
  ///
  /// In en, this message translates to:
  /// **'Enter a word to generate a fill-in-the-blank exercise.'**
  String get aiEmptyCloze;

  /// No description provided for @aiEmptyWriting.
  ///
  /// In en, this message translates to:
  /// **'Paste your essay and pick an exam type to get scored feedback.'**
  String get aiEmptyWriting;

  /// No description provided for @achievementsScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievementsScreenTitle;

  /// No description provided for @achievementsHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Achievements'**
  String get achievementsHeaderTitle;

  /// No description provided for @achievementsUnlockedCount.
  ///
  /// In en, this message translates to:
  /// **'{unlocked} / {total} unlocked'**
  String achievementsUnlockedCount(int unlocked, int total);

  /// No description provided for @achievementUnlockedLabel.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get achievementUnlockedLabel;

  /// No description provided for @achievementLearn100Title.
  ///
  /// In en, this message translates to:
  /// **'Century Scholar'**
  String get achievementLearn100Title;

  /// No description provided for @achievementLearn100Desc.
  ///
  /// In en, this message translates to:
  /// **'Master 100 words'**
  String get achievementLearn100Desc;

  /// No description provided for @achievementQuizPerfectTitle.
  ///
  /// In en, this message translates to:
  /// **'Flawless Run'**
  String get achievementQuizPerfectTitle;

  /// No description provided for @achievementQuizPerfectDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete a quiz session with 100% accuracy (4+ questions)'**
  String get achievementQuizPerfectDesc;

  /// No description provided for @achievementFirstListeningTitle.
  ///
  /// In en, this message translates to:
  /// **'First Echo'**
  String get achievementFirstListeningTitle;

  /// No description provided for @achievementFirstListeningDesc.
  ///
  /// In en, this message translates to:
  /// **'Complete your first listening exercise'**
  String get achievementFirstListeningDesc;

  /// No description provided for @achievementFirstMapLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Cartographer'**
  String get achievementFirstMapLanguageTitle;

  /// No description provided for @achievementFirstMapLanguageDesc.
  ///
  /// In en, this message translates to:
  /// **'Pick a language from the language map'**
  String get achievementFirstMapLanguageDesc;

  /// No description provided for @assetInventoryTitle.
  ///
  /// In en, this message translates to:
  /// **'My Assets'**
  String get assetInventoryTitle;

  /// No description provided for @assetInventoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No assets yet. Try your luck in the Lucky Draw!'**
  String get assetInventoryEmpty;

  /// No description provided for @assetInventoryTotalOwned.
  ///
  /// In en, this message translates to:
  /// **'{count} items owned'**
  String assetInventoryTotalOwned(int count);

  /// No description provided for @assetInventoryTotalFragments.
  ///
  /// In en, this message translates to:
  /// **'{count} fragments'**
  String assetInventoryTotalFragments(int count);

  /// No description provided for @assetInventoryQuantityBadge.
  ///
  /// In en, this message translates to:
  /// **'×{count}'**
  String assetInventoryQuantityBadge(int count);

  /// No description provided for @luckyDrawViewMyAssets.
  ///
  /// In en, this message translates to:
  /// **'View my assets'**
  String get luckyDrawViewMyAssets;

  /// No description provided for @analyticsReportTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning report'**
  String get analyticsReportTitle;

  /// No description provided for @analyticsReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your progress, charts, and focus areas'**
  String get analyticsReportSubtitle;

  /// No description provided for @analyticsScopeLabel.
  ///
  /// In en, this message translates to:
  /// **'Scope: {scope}'**
  String analyticsScopeLabel(Object scope);

  /// No description provided for @analyticsXpTrendTitle.
  ///
  /// In en, this message translates to:
  /// **'XP trend'**
  String get analyticsXpTrendTitle;

  /// No description provided for @analyticsAbilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Ability dimensions'**
  String get analyticsAbilityTitle;

  /// No description provided for @analyticsModalityTitle.
  ///
  /// In en, this message translates to:
  /// **'Accuracy by type'**
  String get analyticsModalityTitle;

  /// No description provided for @analyticsMasteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Word mastery'**
  String get analyticsMasteryTitle;

  /// No description provided for @analyticsDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Detailed stats'**
  String get analyticsDetailTitle;

  /// No description provided for @analyticsFocusTitle.
  ///
  /// In en, this message translates to:
  /// **'Recommended practice'**
  String get analyticsFocusTitle;

  /// No description provided for @analyticsReviewLoad.
  ///
  /// In en, this message translates to:
  /// **'Review load'**
  String get analyticsReviewLoad;

  /// No description provided for @analyticsWeekXp.
  ///
  /// In en, this message translates to:
  /// **'This week XP'**
  String get analyticsWeekXp;

  /// No description provided for @analyticsTodayXp.
  ///
  /// In en, this message translates to:
  /// **'Today XP'**
  String get analyticsTodayXp;

  /// No description provided for @analyticsWeakWords.
  ///
  /// In en, this message translates to:
  /// **'Weak words'**
  String get analyticsWeakWords;

  /// No description provided for @analyticsDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due now'**
  String get analyticsDueNow;

  /// No description provided for @analyticsMasteryNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get analyticsMasteryNew;

  /// No description provided for @analyticsMasteryLearning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get analyticsMasteryLearning;

  /// No description provided for @analyticsMasteryMastered.
  ///
  /// In en, this message translates to:
  /// **'Mastered'**
  String get analyticsMasteryMastered;

  /// No description provided for @analyticsDimMeaningRecognition.
  ///
  /// In en, this message translates to:
  /// **'Recognition'**
  String get analyticsDimMeaningRecognition;

  /// No description provided for @analyticsDimMeaningRecall.
  ///
  /// In en, this message translates to:
  /// **'Recall'**
  String get analyticsDimMeaningRecall;

  /// No description provided for @analyticsDimContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get analyticsDimContext;

  /// No description provided for @analyticsDimListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get analyticsDimListening;

  /// No description provided for @analyticsDimSpelling.
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get analyticsDimSpelling;

  /// No description provided for @analyticsModalityMeaning.
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get analyticsModalityMeaning;

  /// No description provided for @analyticsModalityListening.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get analyticsModalityListening;

  /// No description provided for @analyticsModalitySpelling.
  ///
  /// In en, this message translates to:
  /// **'Spelling'**
  String get analyticsModalitySpelling;

  /// No description provided for @analyticsModalityContext.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get analyticsModalityContext;

  /// No description provided for @analyticsTopErrors.
  ///
  /// In en, this message translates to:
  /// **'Top error types'**
  String get analyticsTopErrors;

  /// No description provided for @readingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingTitle;

  /// No description provided for @readingDiscoverEntry.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingDiscoverEntry;

  /// No description provided for @readingRecommended.
  ///
  /// In en, this message translates to:
  /// **'Recommended for you'**
  String get readingRecommended;

  /// No description provided for @readingAllArticles.
  ///
  /// In en, this message translates to:
  /// **'All articles'**
  String get readingAllArticles;

  /// No description provided for @readingArticlesForTheme.
  ///
  /// In en, this message translates to:
  /// **'{theme} articles'**
  String readingArticlesForTheme(Object theme);

  /// No description provided for @readingFilterLevel.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get readingFilterLevel;

  /// No description provided for @readingFilterTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get readingFilterTheme;

  /// No description provided for @readingFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get readingFilterAll;

  /// No description provided for @readingMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String readingMinutes(int count);

  /// No description provided for @readingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No articles for this filter yet.'**
  String get readingEmpty;

  /// No description provided for @readingProgressInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get readingProgressInProgress;

  /// No description provided for @readingProgressDone.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get readingProgressDone;

  /// No description provided for @readingToggleTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get readingToggleTranslation;

  /// No description provided for @readingToggleReading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingToggleReading;

  /// No description provided for @readingParagraphAudio.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get readingParagraphAudio;

  /// No description provided for @readingTapWordHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a highlighted word for its meaning.'**
  String get readingTapWordHint;

  /// No description provided for @readingWordAddToVocab.
  ///
  /// In en, this message translates to:
  /// **'Add to vocab notebook'**
  String get readingWordAddToVocab;

  /// No description provided for @readingWordAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to vocab notebook'**
  String get readingWordAdded;

  /// No description provided for @readingComprehensionCta.
  ///
  /// In en, this message translates to:
  /// **'Start comprehension'**
  String get readingComprehensionCta;

  /// No description provided for @readingComprehensionSoon.
  ///
  /// In en, this message translates to:
  /// **'Comprehension questions arrive in the next phase.'**
  String get readingComprehensionSoon;

  /// No description provided for @readingThemeCampus.
  ///
  /// In en, this message translates to:
  /// **'Campus'**
  String get readingThemeCampus;

  /// No description provided for @readingThemeLife.
  ///
  /// In en, this message translates to:
  /// **'Life'**
  String get readingThemeLife;

  /// No description provided for @readingThemeTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get readingThemeTravel;

  /// No description provided for @readingThemeTech.
  ///
  /// In en, this message translates to:
  /// **'Tech'**
  String get readingThemeTech;

  /// No description provided for @readingThemeCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get readingThemeCulture;

  /// No description provided for @readingThemeNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get readingThemeNews;

  /// No description provided for @readingThemeBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get readingThemeBusiness;

  /// No description provided for @readingThemeExam.
  ///
  /// In en, this message translates to:
  /// **'Exam'**
  String get readingThemeExam;

  /// No description provided for @readingToggleHighlight.
  ///
  /// In en, this message translates to:
  /// **'Highlight'**
  String get readingToggleHighlight;

  /// No description provided for @readingLegendTitle.
  ///
  /// In en, this message translates to:
  /// **'Word highlights'**
  String get readingLegendTitle;

  /// No description provided for @readingClassKey.
  ///
  /// In en, this message translates to:
  /// **'Key word'**
  String get readingClassKey;

  /// No description provided for @readingClassUnknown.
  ///
  /// In en, this message translates to:
  /// **'Needs review'**
  String get readingClassUnknown;

  /// No description provided for @readingClassNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get readingClassNew;

  /// No description provided for @readingClassKnown.
  ///
  /// In en, this message translates to:
  /// **'Known'**
  String get readingClassKnown;

  /// No description provided for @readingComprehensionStart.
  ///
  /// In en, this message translates to:
  /// **'Start comprehension'**
  String get readingComprehensionStart;

  /// No description provided for @readingComprehensionTitle.
  ///
  /// In en, this message translates to:
  /// **'Comprehension'**
  String get readingComprehensionTitle;

  /// No description provided for @readingComprehensionQuestion.
  ///
  /// In en, this message translates to:
  /// **'Question {current} of {total}'**
  String readingComprehensionQuestion(int current, int total);

  /// No description provided for @readingComprehensionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get readingComprehensionNext;

  /// No description provided for @readingComprehensionFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get readingComprehensionFinish;

  /// No description provided for @readingComprehensionResultTitle.
  ///
  /// In en, this message translates to:
  /// **'Comprehension complete'**
  String get readingComprehensionResultTitle;

  /// No description provided for @readingComprehensionScore.
  ///
  /// In en, this message translates to:
  /// **'{correct} / {total} correct'**
  String readingComprehensionScore(int correct, int total);

  /// No description provided for @readingComprehensionAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy {pct}%'**
  String readingComprehensionAccuracy(int pct);

  /// No description provided for @readingComprehensionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get readingComprehensionDone;

  /// No description provided for @readingComprehensionEmpty.
  ///
  /// In en, this message translates to:
  /// **'No comprehension questions for this article yet.'**
  String get readingComprehensionEmpty;

  /// No description provided for @readingAnalyticsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingAnalyticsTitle;

  /// No description provided for @readingAnalyticsArticlesRead.
  ///
  /// In en, this message translates to:
  /// **'Articles read'**
  String get readingAnalyticsArticlesRead;

  /// No description provided for @readingAnalyticsAccuracy.
  ///
  /// In en, this message translates to:
  /// **'Comprehension accuracy'**
  String get readingAnalyticsAccuracy;

  /// No description provided for @readingAnalyticsThemes.
  ///
  /// In en, this message translates to:
  /// **'By theme'**
  String get readingAnalyticsThemes;

  /// No description provided for @readingAnalyticsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Complete a reading comprehension to see stats here.'**
  String get readingAnalyticsEmpty;

  /// No description provided for @readingExplainTooltip.
  ///
  /// In en, this message translates to:
  /// **'Explain with AI'**
  String get readingExplainTooltip;

  /// No description provided for @readingExplainTitle.
  ///
  /// In en, this message translates to:
  /// **'AI explanation'**
  String get readingExplainTitle;

  /// No description provided for @readingExplainLoading.
  ///
  /// In en, this message translates to:
  /// **'Explaining this paragraph...'**
  String get readingExplainLoading;

  /// No description provided for @readingExplainGist.
  ///
  /// In en, this message translates to:
  /// **'Gist'**
  String get readingExplainGist;

  /// No description provided for @readingExplainKeyWords.
  ///
  /// In en, this message translates to:
  /// **'Key words'**
  String get readingExplainKeyWords;

  /// No description provided for @readingExplainGrammar.
  ///
  /// In en, this message translates to:
  /// **'Grammar points'**
  String get readingExplainGrammar;

  /// No description provided for @readingExplainStructure.
  ///
  /// In en, this message translates to:
  /// **'Sentence structure'**
  String get readingExplainStructure;

  /// No description provided for @readingExplainTranslation.
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get readingExplainTranslation;

  /// No description provided for @readingExplainPractice.
  ///
  /// In en, this message translates to:
  /// **'Practice'**
  String get readingExplainPractice;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ms', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ms':
      return AppLocalizationsMs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
