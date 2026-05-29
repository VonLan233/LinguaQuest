import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
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
        GradientHeroCard(
          title: user?.name ?? 'Learner',
          subtitle:
              '${user?.email ?? 'No email'}\n${user?.targetExam ?? 'Daily English'} · ${user?.level ?? 'Elementary'}',
          icon: Icons.person_rounded,
          badge: 'Profile and progress',
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
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
              color: Colors.green,
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
        QuestCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('当前词书进度', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: state.learningPathProgress,
                  minHeight: 12,
                  backgroundColor: AppTheme.progressTrack(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${state.completedLearningWords}/${state.totalLearningWords} 词 · 今日学习 ${state.todayCompletedLessonIds.length} 课 · 今日复习 ${state.todayReviewWordIds.length} 词',
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        QuestCard(
          padding: const EdgeInsets.all(16),
          color: AppTheme.accentSurface(context),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  weakestWord == null
                      ? '弱项分析：暂无常错词，继续完成学习和复习后会生成。'
                      : '最常错词：${weakestWord.word} · ${weakestWord.wrongCount} 次错误 · ${weakestWord.status}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        if (state.learningPlan != null) ...[
          QuestCard(
            padding: const EdgeInsets.all(14),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_available_outlined),
              title: const Text('Learning Plan'),
              subtitle: Text(
                '${state.learningPlan!.dailyWords} words/day · ${state.learningPlan!.remainingWords} words planned',
              ),
            ),
          ),
          const SizedBox(height: 22),
        ],
        const SectionHeader(title: 'Settings and Support'),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.flag_outlined,
          title: 'Learning Target',
          subtitle: user?.targetExam ?? 'Daily English',
          route: '/goal-setup',
        ),
        const _ProfileAction(
          icon: Icons.menu_book_outlined,
          title: 'Wordbook',
          subtitle: 'Current book and target vocabulary',
          route: '/wordbook',
        ),
        const _ProfileAction(
          icon: Icons.style_outlined,
          title: 'New Word Book',
          subtitle: 'Favorite words and personal vocabulary cards',
          route: '/custom-words',
        ),
        const _ProfileAction(
          icon: Icons.warning_amber_outlined,
          title: 'Mistake Book',
          subtitle: 'Lesson mistakes and weak words',
          route: '/mistake-book',
        ),
        const _ProfileAction(
          icon: Icons.notifications_outlined,
          title: 'Daily Reminder',
          subtitle: 'Choose reminder time and status',
          route: '/settings/reminder',
        ),
        const _ProfileAction(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          subtitle: 'System, light, or dark theme',
          route: '/settings/theme',
        ),
        const _ProfileAction(
          icon: Icons.help_outline,
          title: 'Help / Support',
          subtitle: 'FAQ and support shell',
          route: '/help',
        ),
        const _ProfileAction(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'LinguaQuest product vision and version 1.0.0',
          route: '/about',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(appControllerProvider.notifier).logout();
            if (context.mounted) context.go('/onboarding');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
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
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.iconBadgeSurface(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
