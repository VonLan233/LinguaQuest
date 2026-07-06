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
      return '四级核心词汇';
    case 'CET-6':
      return '六级核心词汇';
    case '考研':
      return '考研英语核心词汇';
    case 'Beginner':
      return '入门基础词汇';
    case 'MUET':
      return 'MUET 高频词汇';
    case 'Daily English':
      return '日常英语';
    case 'Business English':
      return '商务英语';
    case null:
      return '日常英语';
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
      // 新题型使用硬编码文本（i18n 翻译冻结，不添加新 ARB key）
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
      return '英文选义';
    case QuizQuestionType.chineseChoice:
      return '中文选词';
    case QuizQuestionType.contextChoice:
      return '语境选义';
    case QuizQuestionType.imageChoice:
      return '图片选词';
    case QuizQuestionType.listeningWordChoice:
      return '听音选词';
    case QuizQuestionType.listeningMeaningChoice:
      return '听音选义';
    case QuizQuestionType.spelling:
      return '拼写';
    // 新题型（i18n 翻译冻结，不添加 ARB key，直接硬编码中文显示名）
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
      return '入门';
    case 'Elementary':
      return '基础';
    case 'Intermediate':
      return '中级';
    case 'Advanced':
      return '高级';
    case null:
      return '基础';
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
      return '简单';
    case 'Medium':
      return '中等';
    case 'Hard':
      return '困难';
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
      return '全部';
    case 'Weak':
      return '弱项';
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
      return '未学习';
    case 'Previewed':
      return '已预览';
    case 'Learning':
      return '学习中';
    case 'Review':
      return '复习中';
    case 'Relearning':
      return '需巩固';
    case 'Mastered':
      return '已掌握';
    case 'Ignored':
      return '已忽略';
    default:
      return value;
  }
}

String displayCustomTag(String value, {AppLocalizations? l10n}) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return l10n?.labelCustomTagCustom ?? '自定义';
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
      return '自定义';
    case 'mistake':
      return '错题';
    case 'character':
      return '品格';
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
      return '学术';
    case 'beginner':
      return '入门';
    case 'business':
      return '商务';
    case 'campus':
      return '校园';
    case 'daily':
      return '日常';
    case 'exam':
      return '考试';
    case 'cet4':
    case 'cet-4':
      return '四级';
    case 'cet6':
    case 'cet-6':
      return '六级';
    case 'kaoyan':
    case '考研':
      return '考研';
    case 'food':
      return '饮食';
    case 'health':
      return '健康';
    case 'study':
      return '学习';
    case 'travel':
      return '旅行';
    case 'writing':
      return '写作';
    default:
      return value.trim().isEmpty ? '目标词' : value.trim();
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
      return '头像框';
    case 'profileBackground':
      return '主页背景';
    case 'badge':
      return '学习徽章';
    case 'title':
      return '训练称号';
    case 'cardSkin':
      return '卡片皮肤';
    case 'fragment':
      return '安慰碎片';
    default:
      return '装饰资产';
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
      return '稀有';
    case 'uncommon':
      return '进阶';
    case 'common':
      return '普通';
    default:
      return '安慰';
  }
}
