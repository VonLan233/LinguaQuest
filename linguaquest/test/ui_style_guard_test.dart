import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UI style guardrails', () {
    test('feature screens avoid heavy card and glass primitives', () {
      final source = _readDartSources(Directory('lib/features'));
      final forbiddenPatterns = [
        (RegExp(r'\bQuestCard\s*\('), 'QuestCard('),
        (RegExp(r'\bCard\s*\('), 'Card('),
        (RegExp(r'\bBoxShadow\b'), 'BoxShadow'),
        (RegExp(r'\bLinearGradient\b'), 'LinearGradient'),
        (RegExp(r'\bRadialGradient\b'), 'RadialGradient'),
        (RegExp(r'\bBackdropFilter\b'), 'BackdropFilter'),
        (RegExp(r'\bImageFilter\b'), 'ImageFilter'),
        (RegExp(r'\bblur\s*\('), 'blur('),
        (RegExp(r'elevation:\s*[1-9]'), 'positive elevation'),
      ];

      for (final (pattern, label) in forbiddenPatterns) {
        expect(
          pattern.hasMatch(source),
          isFalse,
          reason: '$label reintroduces heavy UI treatment.',
        );
      }
    });

    test('legacy quest card abstraction stays removed', () {
      final source = _readDartSources(Directory('lib'));

      expect(File('lib/core/widgets/quest_card.dart').existsSync(), isFalse);
      expect(File('lib/core/widgets/metric_tile.dart').existsSync(), isFalse);
      expect(source, isNot(contains('QuestCard')));
      expect(source, isNot(contains('quest_card.dart')));
      expect(source, isNot(contains('MetricTile')));
      expect(source, isNot(contains('metric_tile.dart')));
    });

    test('brand presence stays icon-led and avoids generic language marks', () {
      final featureSource = _readDartSources(Directory('lib/features'));
      final brandMark = File(
        'lib/core/widgets/brand_mark.dart',
      ).readAsStringSync();
      final brandMarkUses = RegExp(
        r'\bBrandMark\s*\(',
      ).allMatches(featureSource).length;

      expect(brandMark, contains('icon_transparent.png'));
      expect(featureSource, isNot(contains('icon_transparent.png')));
      expect(brandMarkUses, greaterThanOrEqualTo(3));
      expect(brandMarkUses, lessThanOrEqualTo(4));
      expect(featureSource, isNot(contains('Icons.language_outlined')));
      expect(featureSource, isNot(contains('猫')));
      expect(featureSource.toLowerCase(), isNot(contains('whisker')));
      expect(featureSource.toLowerCase(), isNot(contains('paw')));
    });

    test('profile dashboard keeps the top area lightweight', () {
      final profile = File(
        'lib/features/profile/profile_screen.dart',
      ).readAsStringSync();

      expect(profile, contains('BrandMark'));
      expect(profile, contains('学习仪表盘'));
      expect(profile, isNot(contains('MetricTile')));
      expect(profile, isNot(contains('GridView.count')));
    });

    test('home dashboard keeps first viewport lightweight', () {
      final home = File(
        'lib/features/home/home_screen.dart',
      ).readAsStringSync();

      expect(home, contains('_HomeLearningSignals'));
      expect(home, isNot(contains('MetricTile')));
      expect(home, isNot(contains('GridView.count')));
    });

    test('training arena keeps top status lightweight', () {
      final training = File(
        'lib/features/training/training_screen.dart',
      ).readAsStringSync();

      expect(training, contains('_TrainingReadinessLine'));
      expect(training, contains('_TrainingGameList'));
      expect(training, contains('_TrainingGameRow'));
      expect(training, isNot(contains('MetricTile')));
      expect(training, isNot(contains('_TrainingGameCard')));
      expect(training, contains('校园生活 · 限时测试'));
    });

    test('review center keeps queue status lightweight', () {
      final review = File(
        'lib/features/review/review_center_screen.dart',
      ).readAsStringSync();

      expect(review, contains('FallbackBackButton'));
      expect(review, contains('_ReviewQueueSignals'));
      expect(review, isNot(contains('MetricTile')));
      expect(review, contains('没记住'));
      expect(review, contains('记住了'));
    });

    test('progress analytics keeps summary status lightweight', () {
      final progress = File(
        'lib/features/quests/progress_analytics_screen.dart',
      ).readAsStringSync();

      expect(progress, contains('_ProgressSignals'));
      expect(progress, isNot(contains('MetricTile')));
      expect(progress, contains('复习负荷'));
    });

    test('discover rewards and posts stay list based', () {
      final discover = File(
        'lib/features/discover/discover_screen.dart',
      ).readAsStringSync();

      expect(discover, contains('_RewardTaskList'));
      expect(discover, contains('_RewardTaskRow'));
      expect(discover, contains('_ForumPostList'));
      expect(discover, contains('_ForumPostRow'));
      expect(discover, isNot(contains('_RewardTaskCard')));
      expect(discover, isNot(contains('_ForumPostCard')));
      expect(discover, contains('去完成 +'));
    });

    test('onboarding explains features as a light step list', () {
      final onboarding = File(
        'lib/features/onboarding/onboarding_screen.dart',
      ).readAsStringSync();

      expect(onboarding, contains('_OnboardingStepList'));
      expect(onboarding, contains('_OnboardingStepRow'));
      expect(onboarding, isNot(contains('_OnboardingCard')));
      expect(onboarding, isNot(contains('放在一张卡里')));
    });

    test('study support blocks avoid non-core card semantics', () {
      final lessonPreview = File(
        'lib/features/learning/lesson_preview_screen.dart',
      ).readAsStringSync();
      final reviewStudy = File(
        'lib/features/study/review_study_screen.dart',
      ).readAsStringSync();

      expect(lessonPreview, contains('_WordStudyCard'));
      expect(lessonPreview, contains('_ContextSection'));
      expect(lessonPreview, isNot(contains('_ContextCard')));
      expect(reviewStudy, contains('_ReviewWordCard'));
      expect(reviewStudy, contains('_MemoryHintLine'));
      expect(reviewStudy, isNot(contains('_MemoryHintCard')));
    });

    test('new study and review stay separate from campus timed tests', () {
      final home = File(
        'lib/features/home/home_screen.dart',
      ).readAsStringSync();
      final training = File(
        'lib/features/training/training_screen.dart',
      ).readAsStringSync();
      final discover = File(
        'lib/features/discover/discover_screen.dart',
      ).readAsStringSync();
      final newStudy = File(
        'lib/features/study/new_study_screen.dart',
      ).readAsStringSync();
      final router = File(
        'lib/core/routing/app_router.dart',
      ).readAsStringSync();
      final wordbook = File(
        'lib/features/wordbook/wordbook_screen.dart',
      ).readAsStringSync();
      final search = File(
        'lib/features/search/search_screen.dart',
      ).readAsStringSync();
      final targetDetail = File(
        'lib/features/wordbook/target_word_detail_screen.dart',
      ).readAsStringSync();
      final lessonPreview = File(
        'lib/features/learning/lesson_preview_screen.dart',
      ).readAsStringSync();
      final quizSession = File(
        'lib/features/quiz/quiz_session_screen.dart',
      ).readAsStringSync();

      expect(home, contains("context.push('/study/new')"));
      expect(home, contains("context.push('/study/review')"));
      expect(home, contains("context.push('/learn')"));
      expect(home, isNot(contains("context.push('/leaderboard')")));
      expect(discover, contains("context.push('/study/new')"));
      expect(discover, isNot(contains("context.push('/learn')")));
      expect(home, isNot(contains('/timed-test/lesson-campus-1')));
      expect(training, contains("context.push('/timed-test/lesson-campus-1')"));
      expect(training, isNot(contains("context.push('/study/review')")));
      expect(wordbook, contains('state.formalLessons'));
      expect(search, contains('state.formalLessons'));
      expect(targetDetail, contains('state.formalLessons'));
      expect(lessonPreview, contains('formalLessons'));
      expect(
        lessonPreview,
        isNot(contains('ref.watch(appControllerProvider).lessons')),
      );
      expect(quizSession, contains('isTimed ? state.lessons'));
      expect(quizSession, contains(': state.formalLessons'));
      expect(quizSession, contains('_fallbackExitRoute'));
      expect(quizSession, contains("? '/training' : '/learn'"));
      expect(training, contains('限时测试'));
      expect(training, contains('今日可得 60 XP'));
      expect(training, isNot(contains("label: '今日可得 60'")));
      expect(newStudy, contains('不做限时测试'));
      expect(router, contains("path: '/study/new'"));
      expect(router, contains("path: '/study/review'"));
      expect(router, contains("path: '/timed-test/:id'"));
    });

    test('learning path nodes stay line based instead of framed', () {
      final learningPath = File(
        'lib/features/learning/learning_path_screen.dart',
      ).readAsStringSync();

      expect(learningPath, isNot(contains('AppTheme.accentSurface(context)')));
      expect(learningPath, contains('state.formalLessons'));
      expect(learningPath, isNot(contains('state.lessons.length')));
      expect(learningPath, contains('color: Colors.transparent'));
    });

    test('home keeps plan editing to one compact entry', () {
      final home = File(
        'lib/features/home/home_screen.dart',
      ).readAsStringSync();

      expect(home, isNot(contains("title: '当前计划'")));
      expect(
        RegExp(r"context\.push\('/goal-setup'\)").allMatches(home),
        hasLength(1),
      );
    });

    test('goal setup choices stay list based instead of grid cards', () {
      final goalSetup = File(
        'lib/features/auth/goal_setup_screen.dart',
      ).readAsStringSync();

      expect(goalSetup, contains('_ChoiceList'));
      expect(goalSetup, isNot(contains('_ChoiceGrid')));
      expect(goalSetup, isNot(contains('GridView.count')));
      expect(goalSetup, contains('radio_button_unchecked_rounded'));
    });

    test('legacy English UI labels do not reappear', () {
      final source = _readDartSources(Directory('lib'));
      const legacyLabels = [
        'Campus Starter',
        'Goal Setup',
        'WordBook',
        'Remembered',
        'Forgot',
        "name: 'Learner'",
        "user?.name ?? 'Learner'",
        "TextEditingController(text: 'custom')",
        "? 'custom'",
        "? 'mistake'",
      ];

      for (final label in legacyLabels) {
        expect(source, isNot(contains(label)));
      }
    });

    test('custom word tags are localized at display boundaries', () {
      final labels = File('lib/core/utils/ui_labels.dart').readAsStringSync();
      final addEdit = File(
        'lib/features/wordbook/add_edit_custom_word_screen.dart',
      ).readAsStringSync();
      final customList = File(
        'lib/features/wordbook/custom_word_list_screen.dart',
      ).readAsStringSync();
      final wordDetail = File(
        'lib/features/wordbook/word_detail_screen.dart',
      ).readAsStringSync();
      final search = File(
        'lib/features/search/search_screen.dart',
      ).readAsStringSync();
      final reviewStudy = File(
        'lib/features/study/review_study_screen.dart',
      ).readAsStringSync();

      expect(labels, contains('displayCustomTag'));
      expect(labels, contains("case 'custom'"));
      expect(labels, contains("case 'mistake'"));
      expect(labels, contains("case 'character'"));
      expect(labels, contains('return displayWordTag(trimmed)'));
      expect(addEdit, contains("TextEditingController(text: '自定义')"));
      expect(addEdit, contains('displayCustomTag(word.tag)'));
      expect(customList, contains('displayCustomTag(word.tag)'));
      expect(wordDetail, contains('displayCustomTag(word.tag)'));
      expect(search, contains('displayCustomTag(word.tag)'));
      expect(reviewStudy, contains('displayCustomTag(word.tag)'));
    });

    test('target word tags are localized at display boundaries', () {
      final labels = File('lib/core/utils/ui_labels.dart').readAsStringSync();
      final wordbook = File(
        'lib/features/wordbook/wordbook_screen.dart',
      ).readAsStringSync();
      final targetDetail = File(
        'lib/features/wordbook/target_word_detail_screen.dart',
      ).readAsStringSync();
      final search = File(
        'lib/features/search/search_screen.dart',
      ).readAsStringSync();
      final appController = File(
        'lib/core/state/app_controller.dart',
      ).readAsStringSync();

      expect(labels, contains('displayWordTag'));
      expect(labels, contains("case 'academic'"));
      expect(labels, contains("case 'exam'"));
      expect(wordbook, contains('displayWordTag(word.tags.first)'));
      expect(targetDetail, contains('displayWordTag(tag)'));
      expect(targetDetail, contains('displayWordTag(word.tags.first)'));
      expect(search, contains('displayWordTag(tag)'));
      expect(appController, contains('displayWordTag(word.tags.first)'));
    });

    test('AI learning statuses stay user-facing', () {
      final aiLearning = File(
        'lib/features/ai_learning/ai_learning_screen.dart',
      ).readAsStringSync();

      expect(aiLearning, contains('_AiToolList'));
      expect(aiLearning, contains('_AiToolLink'));
      expect(aiLearning, isNot(contains('_AiToolCard')));
      expect(aiLearning, isNot(contains("status: 'P1'")));
      expect(aiLearning, isNot(contains("status: 'P2'")));
      expect(aiLearning, isNot(contains('先用模拟流程')));
      expect(aiLearning, isNot(contains('先用演示流程')));
      expect(aiLearning, isNot(contains('AI学习')));
      expect(aiLearning, contains('AI 学习'));
      expect(aiLearning, contains('错因讲解'));
      expect(aiLearning, contains("status: '规划中'"));
      expect(aiLearning, contains("status: '待开放'"));
      expect(aiLearning, contains("status: '可试用'"));
    });

    test('quest entry labels avoid development stage wording', () {
      final sources = [
        File('lib/features/quests/quest_screen.dart').readAsStringSync(),
        File('lib/features/quests/ai_tutor_screen.dart').readAsStringSync(),
        File('lib/features/quests/class_mode_screen.dart').readAsStringSync(),
        File('lib/features/quests/leaderboard_screen.dart').readAsStringSync(),
        File(
          'lib/features/quests/class_progress_screen.dart',
        ).readAsStringSync(),
      ].join('\n');
      const developmentLabels = ['模拟', '原型', '预览', 'P1', 'P2'];

      for (final label in developmentLabels) {
        expect(sources, isNot(contains(label)));
      }
      expect(sources, contains('即时反馈'));
      expect(sources, contains('可试用'));
    });

    test('XP overview labels stay clear and non-misleading', () {
      final training = File(
        'lib/features/training/training_screen.dart',
      ).readAsStringSync();
      final quest = File(
        'lib/features/quests/quest_screen.dart',
      ).readAsStringSync();
      final lessonResult = File(
        'lib/features/quiz/lesson_result_screen.dart',
      ).readAsStringSync();

      expect(training, contains("label: '本周 \${user?.xp ?? 0} XP'"));
      expect(training, contains('今日可得 60 XP'));
      expect(training, isNot(contains('本周 \${user?.xp ?? 0} 积分')));
      expect(quest, contains("label: '任务 XP'"));
      expect(quest, isNot(contains("label: '今日可领 20 XP'")));
      expect(lessonResult, contains('已入账 +'));
      expect(lessonResult, contains('总积分 \$currentXp XP'));
    });

    test('supporting page copy avoids prototype disclaimers', () {
      final sources = [
        File(
          'lib/features/profile/help_support_screen.dart',
        ).readAsStringSync(),
        File('lib/features/profile/about_screen.dart').readAsStringSync(),
        File('lib/features/profile/settings_screen.dart').readAsStringSync(),
        File('lib/features/discover/discover_screen.dart').readAsStringSync(),
      ].join('\n');
      const prototypePhrases = [
        '当前界面用于验证交互',
        '后续再接入正式 API',
        '学习应用原型',
        '后续接入审核',
        '为后续发音',
        '当前版本暂未启用',
      ];

      for (final phrase in prototypePhrases) {
        expect(sources, isNot(contains(phrase)));
      }
      expect(sources, contains('应用会记住提醒时间'));
      expect(sources, contains('学习打卡和错题讨论集中展示'));
      expect(sources, contains('用于提醒答题结果和练习节奏'));
    });
  });
}

String _readDartSources(Directory root) {
  final buffer = StringBuffer();
  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    buffer
      ..writeln('// ${file.path}')
      ..writeln(file.readAsStringSync());
  }
  return buffer.toString();
}
