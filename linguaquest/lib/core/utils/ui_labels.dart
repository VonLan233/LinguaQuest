import '../../data/models/lesson.dart';

String displayTarget(String? value) {
  switch (value) {
    case 'CET-4':
      return '四级核心词汇';
    case 'CET-6':
      return '六级核心词汇';
    case 'IELTS':
    case '雅思核心词汇':
      return '雅思核心词汇';
    case 'TOEFL':
      return '托福高频词汇';
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

String displayQuestionType(QuizQuestionType type) {
  switch (type) {
    case QuizQuestionType.meaningChoice:
      return '英文选义';
    case QuizQuestionType.chineseChoice:
      return '中文选词';
    case QuizQuestionType.contextChoice:
      return '语境选义';
    case QuizQuestionType.imageChoice:
      return '图片选词';
    case QuizQuestionType.spelling:
      return '拼写';
  }
}

String displayLevel(String? value) {
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

String displayDifficulty(String value) {
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

String displayDifficultyFilter(String value) {
  switch (value) {
    case 'All':
      return '全部';
    case 'Weak':
      return '弱项';
    default:
      return displayDifficulty(value);
  }
}

String displayWordStatus(String value) {
  switch (value) {
    case 'Learning':
      return '学习中';
    case 'Review':
      return '复习中';
    case 'Relearning':
      return '需巩固';
    case 'Mastered':
      return '已掌握';
    default:
      return value;
  }
}

String displayCustomTag(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '自定义';

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

String displayWordTag(String value) {
  switch (value.trim().toLowerCase()) {
    case 'academic':
      return '学术';
    case 'business':
      return '商务';
    case 'campus':
      return '校园';
    case 'daily':
      return '日常';
    case 'exam':
      return '考试';
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
