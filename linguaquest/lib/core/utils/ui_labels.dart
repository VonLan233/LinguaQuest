String displayTarget(String? value) {
  switch (value) {
    case 'Daily English':
      return '日常英语';
    case 'Business English':
      return '商务英语';
    case '雅思核心词汇':
      return '雅思核心词汇';
    case null:
      return '日常英语';
    default:
      return value;
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
  switch (value.trim().toLowerCase()) {
    case 'custom':
      return '自定义';
    case 'mistake':
      return '错题';
    default:
      return value.trim().isEmpty ? '自定义' : value.trim();
  }
}
