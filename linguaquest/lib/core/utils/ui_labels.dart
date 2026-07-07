import '../../data/models/lesson.dart';
import '../../data/models/user_profile.dart';
import '../../l10n/generated/app_localizations.dart';

String displayUserName(UserProfile? user, {required AppLocalizations l10n}) {
  final name = user?.name.trim() ?? '';
  const localizableDefaults = {'', '学习者', 'Learner', 'Explorer', 'Pelajar'};
  if (localizableDefaults.contains(name)) return l10n.profileLearner;
  return name;
}

String displayTarget(String? value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value) {
      case 'CET-4':
        return l10n.labelTargetCET4;
      case 'CET-6':
        return l10n.labelTargetCET6;
      case '考研':
        return l10n.labelTargetKaoyan;
      case 'Beginner':
        return l10n.labelTargetBeginner;
      case 'MUET':
        return l10n.labelTargetMUET;
      case 'Daily English':
        return l10n.labelTargetDailyEnglish;
      case 'Business English':
        return l10n.labelTargetBusinessEnglish;
      case null:
        return l10n.labelTargetDailyEnglish;
      default:
        return value;
    }
  }
  switch (value) {
    case 'CET-4':
      return 'CET-4 Core Vocabulary';
    case 'CET-6':
      return 'CET-6 Core Vocabulary';
    case '考研':
      return 'Kaoyan English Core Vocabulary';
    case 'Beginner':
      return 'Beginner Vocabulary';
    case 'MUET':
      return 'MUET High-Frequency Vocabulary';
    case 'Daily English':
      return 'Daily English';
    case 'Business English':
      return 'Business English';
    case null:
      return 'Daily English';
    default:
      return value;
  }
}

String displayQuestionType(QuizQuestionType type, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (type) {
      case QuizQuestionType.meaningChoice:
        return l10n.labelQuestionTypeMeaningChoice;
      case QuizQuestionType.chineseChoice:
        return l10n.labelQuestionTypeChineseChoice;
      case QuizQuestionType.contextChoice:
        return l10n.labelQuestionTypeContextChoice;
      case QuizQuestionType.imageChoice:
        return l10n.labelQuestionTypeImageChoice;
      case QuizQuestionType.listeningWordChoice:
        return l10n.labelQuestionTypeListeningWordChoice;
      case QuizQuestionType.listeningMeaningChoice:
        return l10n.labelQuestionTypeListeningMeaningChoice;
      case QuizQuestionType.spelling:
        return l10n.labelQuestionTypeSpelling;
      // Newer question types do not have ARB keys yet, so use English labels.
      case QuizQuestionType.sentenceCloze:
        return 'Cloze';
      case QuizQuestionType.confusableChoice:
        return 'Confusable';
      case QuizQuestionType.collocationChoice:
        return 'Collocation';
      case QuizQuestionType.derivativeChoice:
        return 'Word form';
    }
  }
  switch (type) {
    case QuizQuestionType.meaningChoice:
      return 'Meaning choice';
    case QuizQuestionType.chineseChoice:
      return 'Chinese choice';
    case QuizQuestionType.contextChoice:
      return 'Context choice';
    case QuizQuestionType.imageChoice:
      return 'Image choice';
    case QuizQuestionType.listeningWordChoice:
      return 'Listening word choice';
    case QuizQuestionType.listeningMeaningChoice:
      return 'Listening meaning choice';
    case QuizQuestionType.spelling:
      return 'Spelling';
    // Newer question types do not have ARB keys yet, so use English labels.
    case QuizQuestionType.sentenceCloze:
      return 'Cloze';
    case QuizQuestionType.confusableChoice:
      return 'Confusable';
    case QuizQuestionType.collocationChoice:
      return 'Collocation';
    case QuizQuestionType.derivativeChoice:
      return 'Word form';
  }
}

String displayLevel(String? value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value) {
      case 'Beginner':
        return l10n.labelLevelBeginner;
      case 'Elementary':
        return l10n.labelLevelElementary;
      case 'Intermediate':
        return l10n.labelLevelIntermediate;
      case 'Advanced':
        return l10n.labelLevelAdvanced;
      case null:
        return l10n.labelLevelElementary;
      default:
        return value;
    }
  }
  switch (value) {
    case 'Beginner':
      return 'Beginner';
    case 'Elementary':
      return 'Elementary';
    case 'Intermediate':
      return 'Intermediate';
    case 'Advanced':
      return 'Advanced';
    case null:
      return 'Elementary';
    default:
      return value;
  }
}

String displayDifficulty(String value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value) {
      case 'Easy':
        return l10n.labelDifficultyEasy;
      case 'Medium':
        return l10n.labelDifficultyMedium;
      case 'Hard':
        return l10n.labelDifficultyHard;
      default:
        return value;
    }
  }
  switch (value) {
    case 'Easy':
      return 'Easy';
    case 'Medium':
      return 'Medium';
    case 'Hard':
      return 'Hard';
    default:
      return value;
  }
}

String displayDifficultyFilter(String value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value) {
      case 'All':
        return l10n.wordbookAllDifficulty;
      case 'Weak':
        return l10n.wordbookWeakDifficulty;
      default:
        return displayDifficulty(value, l10n: l10n);
    }
  }
  switch (value) {
    case 'All':
      return 'All';
    case 'Weak':
      return 'Weak';
    default:
      return displayDifficulty(value);
  }
}

String displayWordStatus(String value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value) {
      case 'New':
        return l10n.labelStatusNew;
      case 'Previewed':
        return l10n.labelStatusPreviewed;
      case 'Learning':
        return l10n.labelStatusLearning;
      case 'Review':
        return l10n.labelStatusReview;
      case 'Relearning':
        return l10n.labelStatusRelearning;
      case 'Mastered':
        return l10n.labelStatusMastered;
      case 'Ignored':
        return l10n.labelStatusIgnored;
      default:
        return value;
    }
  }
  switch (value) {
    case 'New':
      return 'New';
    case 'Previewed':
      return 'Previewed';
    case 'Learning':
      return 'Learning';
    case 'Review':
      return 'Review';
    case 'Relearning':
      return 'Relearning';
    case 'Mastered':
      return 'Mastered';
    case 'Ignored':
      return 'Ignored';
    default:
      return value;
  }
}

String displayCustomTag(String value, {AppLocalizations? l10n}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return l10n?.labelCustomTagCustom ?? 'Custom';
  }

  if (l10n != null) {
    switch (trimmed.toLowerCase()) {
      case 'custom':
        return l10n.labelCustomTagCustom;
      case 'mistake':
        return l10n.labelCustomTagMistake;
      case 'character':
        return l10n.labelCustomTagCharacter;
      default:
        return displayWordTag(trimmed, l10n: l10n);
    }
  }
  switch (trimmed.toLowerCase()) {
    case 'custom':
      return 'Custom';
    case 'mistake':
      return 'Mistake';
    case 'character':
      return 'Character';
    default:
      return displayWordTag(trimmed);
  }
}

String displayWordTag(String value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value.trim().toLowerCase()) {
      case 'academic':
        return l10n.labelWordTagAcademic;
      case 'beginner':
        return l10n.labelWordTagBeginner;
      case 'business':
        return l10n.labelWordTagBusiness;
      case 'campus':
        return l10n.labelWordTagCampus;
      case 'daily':
        return l10n.labelWordTagDaily;
      case 'exam':
        return l10n.labelWordTagExam;
      case 'cet4':
      case 'cet-4':
        return l10n.labelWordTagCET4;
      case 'cet6':
      case 'cet-6':
        return l10n.labelWordTagCET6;
      case 'kaoyan':
      case '考研':
        return l10n.labelWordTagKaoyan;
      case 'food':
        return l10n.labelWordTagFood;
      case 'health':
        return l10n.labelWordTagHealth;
      case 'study':
        return l10n.labelWordTagStudy;
      case 'travel':
        return l10n.labelWordTagTravel;
      case 'writing':
        return l10n.labelWordTagWriting;
      default:
        return value.trim().isEmpty ? l10n.labelWordTagDefault : value.trim();
    }
  }
  switch (value.trim().toLowerCase()) {
    case 'academic':
      return 'Academic';
    case 'beginner':
      return 'Beginner';
    case 'business':
      return 'Business';
    case 'campus':
      return 'Campus';
    case 'daily':
      return 'Daily';
    case 'exam':
      return 'Exam';
    case 'cet4':
    case 'cet-4':
      return 'CET-4';
    case 'cet6':
    case 'cet-6':
      return 'CET-6';
    case 'kaoyan':
    case '考研':
      return 'Kaoyan';
    case 'food':
      return 'Food';
    case 'health':
      return 'Health';
    case 'study':
      return 'Study';
    case 'travel':
      return 'Travel';
    case 'writing':
      return 'Writing';
    default:
      return value.trim().isEmpty ? 'Target word' : value.trim();
  }
}

String displayWordbookTitle(String id, {AppLocalizations? l10n}) {
  final lower = id.toLowerCase();
  // HSK 1-6 and JLPT N5-N1 derive their display name from the id directly.
  final hsk = RegExp(r'^hsk(\d)$').firstMatch(lower);
  if (hsk != null) return 'HSK ${hsk.group(1)}';
  final jlpt = RegExp(r'^jlpt[_-]?n([1-5])$').firstMatch(lower);
  if (jlpt != null) return 'JLPT N${jlpt.group(1)}';
  if (l10n == null) return id;
  switch (id.toLowerCase()) {
    case 'beginner':
      return l10n.wordbookNameBeginner;
    case 'cet4':
      return l10n.wordbookNameCET4;
    case 'cet6':
      return l10n.wordbookNameCET6;
    case 'kaoyan':
      return l10n.wordbookNameKaoyan;
    default:
      return id;
  }
}

String displayWordbookDescription(String id, {AppLocalizations? l10n}) {
  final lower = id.toLowerCase();
  final hsk = RegExp(r'^hsk(\d)$').firstMatch(lower);
  if (hsk != null) return 'Core vocabulary for HSK Level ${hsk.group(1)}.';
  final jlpt = RegExp(r'^jlpt[_-]?n([1-5])$').firstMatch(lower);
  if (jlpt != null) {
    return 'Core Japanese vocabulary for JLPT N${jlpt.group(1)}.';
  }
  if (l10n == null) return '';
  switch (id.toLowerCase()) {
    case 'beginner':
      return l10n.wordbookDescBeginner;
    case 'cet4':
      return l10n.wordbookDescCET4;
    case 'cet6':
      return l10n.wordbookDescCET6;
    case 'kaoyan':
      return l10n.wordbookDescKaoyan;
    default:
      return '';
  }
}

String displayLotteryCategory(String value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value) {
      case 'avatarFrame':
        return l10n.lotteryCategoryAvatarFrame;
      case 'profileBackground':
        return l10n.lotteryCategoryProfileBackground;
      case 'badge':
        return l10n.lotteryCategoryBadge;
      case 'title':
        return l10n.lotteryCategoryTitle;
      case 'cardSkin':
        return l10n.lotteryCategoryCardSkin;
      case 'fragment':
        return l10n.lotteryCategoryFragment;
      default:
        return l10n.lotteryCategoryDefault;
    }
  }
  switch (value) {
    case 'avatarFrame':
      return 'Avatar frame';
    case 'profileBackground':
      return 'Profile background';
    case 'badge':
      return 'Learning badge';
    case 'title':
      return 'Training title';
    case 'cardSkin':
      return 'Card skin';
    case 'fragment':
      return 'Comfort fragment';
    default:
      return 'Decorative asset';
  }
}

String displayLotteryRarity(String value, {AppLocalizations? l10n}) {
  if (l10n != null) {
    switch (value) {
      case 'rare':
        return l10n.lotteryRarityRare;
      case 'uncommon':
        return l10n.lotteryRarityUncommon;
      case 'common':
        return l10n.lotteryRarityCommon;
      default:
        return l10n.lotteryRarityComfort;
    }
  }
  switch (value) {
    case 'rare':
      return 'Rare';
    case 'uncommon':
      return 'Uncommon';
    case 'common':
      return 'Common';
    default:
      return 'Comfort';
  }
}
