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
  /// **'Short lessons, visual memory cards, and smart review help you steadily build English vocabulary.'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingTagline.
  ///
  /// In en, this message translates to:
  /// **'Level up daily like a game'**
  String get onboardingTagline;

  /// No description provided for @onboardingFeatureImageCards.
  ///
  /// In en, this message translates to:
  /// **'Image Word Cards'**
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

  /// No description provided for @goalSetupReviewLimit.
  ///
  /// In en, this message translates to:
  /// **'Review Cap'**
  String get goalSetupReviewLimit;

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
  /// **'Start Today\'s Learning'**
  String get homeStartLearning;

  /// No description provided for @homeReviewOnly.
  ///
  /// In en, this message translates to:
  /// **'Review Only'**
  String get homeReviewOnly;

  /// No description provided for @homeStreakLabel.
  ///
  /// In en, this message translates to:
  /// **'continuous check-in'**
  String get homeStreakLabel;

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
  /// **'Learner'**
  String get profileLearner;

  /// No description provided for @profileNoEmail.
  ///
  /// In en, this message translates to:
  /// **'No email set'**
  String get profileNoEmail;

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
  /// **'Words Learned'**
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
  /// **'days streak'**
  String get profileStreakDays;

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

  /// No description provided for @profileAboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'LinguaQuest vision & version 1.0.0'**
  String get profileAboutSubtitle;

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
  /// **'Learning check-ins and mistake discussions displayed here.'**
  String get discoverCommunityPostsSubtitle;

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
  /// **'Go +{points} XP'**
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
  /// **'Correct.'**
  String get quizCorrect;

  /// No description provided for @quizWrong.
  ///
  /// In en, this message translates to:
  /// **'Not quite.'**
  String get quizWrong;

  /// No description provided for @quizReinforce.
  ///
  /// In en, this message translates to:
  /// **'Reinforce:'**
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

  /// No description provided for @trainingTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Ground'**
  String get trainingTitle;

  /// No description provided for @trainingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Timed tests, skill drills, and leaderboard all here.'**
  String get trainingSubtitle;

  /// No description provided for @trainingLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get trainingLeaderboard;

  /// No description provided for @trainingTimedTests.
  ///
  /// In en, this message translates to:
  /// **'Timed Tests'**
  String get trainingTimedTests;

  /// No description provided for @trainingTimedTestsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Campus word packs and speed challenges are in the training ground, not the new learning entry.'**
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

  /// No description provided for @trainingSpecialDrills.
  ///
  /// In en, this message translates to:
  /// **'Skill Drills'**
  String get trainingSpecialDrills;

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

  /// No description provided for @trainingDueWords.
  ///
  /// In en, this message translates to:
  /// **'Due Words'**
  String get trainingDueWords;

  /// No description provided for @trainingWeakWords.
  ///
  /// In en, this message translates to:
  /// **'Weak Words'**
  String get trainingWeakWords;

  /// No description provided for @trainingComboTarget.
  ///
  /// In en, this message translates to:
  /// **'Combo Target'**
  String get trainingComboTarget;

  /// No description provided for @trainingEnterCustomWords.
  ///
  /// In en, this message translates to:
  /// **'Go to Custom Words'**
  String get trainingEnterCustomWords;

  /// No description provided for @learningPathTitle.
  ///
  /// In en, this message translates to:
  /// **'Learning Path'**
  String get learningPathTitle;

  /// No description provided for @learningPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shows wordbook progress only. Formal new learning and review use the two separate entries on Home.'**
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

  /// No description provided for @reviewCenterTitle.
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewCenterTitle;

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

  /// No description provided for @labelTargetIELTS.
  ///
  /// In en, this message translates to:
  /// **'IELTS Core'**
  String get labelTargetIELTS;

  /// No description provided for @labelTargetTOEFL.
  ///
  /// In en, this message translates to:
  /// **'TOEFL High-Freq'**
  String get labelTargetTOEFL;

  /// No description provided for @labelTargetGRE.
  ///
  /// In en, this message translates to:
  /// **'GRE High-Freq'**
  String get labelTargetGRE;

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

  /// No description provided for @labelWordTagIELTS.
  ///
  /// In en, this message translates to:
  /// **'IELTS'**
  String get labelWordTagIELTS;

  /// No description provided for @labelWordTagTOEFL.
  ///
  /// In en, this message translates to:
  /// **'TOEFL'**
  String get labelWordTagTOEFL;

  /// No description provided for @labelWordTagGRE.
  ///
  /// In en, this message translates to:
  /// **'GRE'**
  String get labelWordTagGRE;

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

  /// No description provided for @aiLearningTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Learning'**
  String get aiLearningTitle;

  /// No description provided for @aiLearningSubtitle.
  ///
  /// In en, this message translates to:
  /// **'AI-powered reading, writing, and practice exercises.'**
  String get aiLearningSubtitle;

  /// No description provided for @aiLearningComingSoon.
  ///
  /// In en, this message translates to:
  /// **'AI learning features coming soon.'**
  String get aiLearningComingSoon;

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

  /// No description provided for @questAchievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get questAchievements;

  /// No description provided for @questLeaderboard.
  ///
  /// In en, this message translates to:
  /// **'Leaderboard'**
  String get questLeaderboard;

  /// No description provided for @questClassMode.
  ///
  /// In en, this message translates to:
  /// **'Class Mode'**
  String get questClassMode;

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
