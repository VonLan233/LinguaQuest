import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final completedPlans = state.learningPathProgress >= 1 ? 1 : 0;
    final masteredWords = state.customWords
        .where((word) => word.masteryLevel >= 4 || word.status == 'Mastered')
        .length;
    final totalAttempts = state.customWords.fold<int>(
      0,
      (total, word) => total + word.correctCount + word.wrongCount,
    );
    final correctAttempts = state.customWords.fold<int>(
      0,
      (total, word) => total + word.correctCount,
    );
    final averageAccuracy = totalAttempts == 0
        ? 0
        : (correctAttempts / totalAttempts * 100).round();
    final weakestWord = state.weakWords.isEmpty ? null : state.weakWords.first;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: user?.name ?? '学习者',
          subtitle:
              '${user?.email ?? '未设置邮箱'} · ${displayTarget(user?.targetExam)} · ${displayLevel(user?.level)}',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: '${user?.xp ?? 0} XP',
              icon: Icons.bolt,
              color: AppTheme.mango,
            ),
            PillLabel(
              label: '${user?.streak ?? 0} 天连续',
              icon: Icons.local_fire_department,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.28,
          children: [
            MetricTile(
              label: '连续打卡',
              value: '${user?.streak ?? 0} 天',
              icon: Icons.local_fire_department,
              color: AppTheme.coral,
            ),
            MetricTile(
              label: '已学单词',
              value: '${state.completedLearningWords}',
              icon: Icons.school_outlined,
            ),
            MetricTile(
              label: '已掌握',
              value: '$masteredWords',
              icon: Icons.verified_outlined,
              color: AppTheme.success,
            ),
            MetricTile(
              label: '生词本',
              value: '${state.customWords.length}',
              icon: Icons.style_outlined,
              color: AppTheme.cyan,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: '平均正确率',
                value: '$averageAccuracy%',
                icon: Icons.percent_outlined,
                color: AppTheme.mango,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: '完成计划',
                value: '$completedPlans',
                icon: Icons.flag_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _ProfileProgressSummary(
          progress: state.learningPathProgress,
          completedWords: state.completedLearningWords,
          totalWords: state.totalLearningWords,
          todayLessons: state.todayCompletedLessonIds.length,
          todayReviews: state.todayReviewWordIds.length,
        ),
        const SizedBox(height: 22),
        _WeaknessStatusLine(
          text: weakestWord == null
              ? '弱项分析：暂无常错词，继续完成学习和复习后会生成。'
              : '最常错词：${weakestWord.word} · ${weakestWord.wrongCount} 次错误 · ${displayWordStatus(weakestWord.status)}',
        ),
        const SizedBox(height: 22),
        if (state.learningPlan != null) ...[
          _LearningPlanLine(
            dailyWords: state.learningPlan!.dailyWords,
            remainingWords: state.learningPlan!.remainingWords,
          ),
          const SizedBox(height: 22),
        ],
        const SectionHeader(title: '设置与支持'),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.flag_outlined,
          title: '学习目标',
          subtitle: displayTarget(user?.targetExam),
          route: '/goal-setup',
        ),
        const _ProfileAction(
          icon: Icons.menu_book_outlined,
          title: '单词本',
          subtitle: '当前词书与目标词汇',
          route: '/wordbook',
        ),
        const _ProfileAction(
          icon: Icons.style_outlined,
          title: '生词本',
          subtitle: '收藏的单词与个人词汇卡片',
          route: '/custom-words',
        ),
        const _ProfileAction(
          icon: Icons.warning_amber_outlined,
          title: '错题本',
          subtitle: '课程错词与弱项词',
          route: '/mistake-book',
        ),
        const _ProfileAction(
          icon: Icons.notifications_outlined,
          title: '每日提醒',
          subtitle: '选择提醒时间和开启状态',
          route: '/settings/reminder',
        ),
        const _ProfileAction(
          icon: Icons.dark_mode_outlined,
          title: '深色模式',
          subtitle: '跟随系统、浅色或深色主题',
          route: '/settings/theme',
        ),
        const _ProfileAction(
          icon: Icons.help_outline,
          title: '帮助与反馈',
          subtitle: '常见问题和支持入口',
          route: '/help',
        ),
        const _ProfileAction(
          icon: Icons.info_outline,
          title: '关于我们',
          subtitle: 'LinguaQuest 产品愿景与版本 1.0.0',
          route: '/about',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(appControllerProvider.notifier).logout();
            if (context.mounted) context.go('/onboarding');
          },
          icon: const Icon(Icons.logout),
          label: const Text('退出登录'),
        ),
      ],
    );
  }
}

class _ProfileProgressSummary extends StatelessWidget {
  const _ProfileProgressSummary({
    required this.progress,
    required this.completedWords,
    required this.totalWords,
    required this.todayLessons,
    required this.todayReviews,
  });

  final double progress;
  final int completedWords;
  final int totalWords;
  final int todayLessons;
  final int todayReviews;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('当前词书进度', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: AppTheme.progressTrack(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$completedWords/$totalWords 词 · 今日学习 $todayLessons 课 · 今日复习 $todayReviews 词',
        ),
      ],
    );
  }
}

class _WeaknessStatusLine extends StatelessWidget {
  const _WeaknessStatusLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.iconBadgeSurface(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.analytics_outlined,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.42,
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningPlanLine extends StatelessWidget {
  const _LearningPlanLine({
    required this.dailyWords,
    required this.remainingWords,
  });

  final int dailyWords;
  final int remainingWords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.event_available_outlined, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('学习计划', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                '每日 $dailyWords 词 · 计划剩余 $remainingWords 词',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.iconBadgeSurface(context),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
