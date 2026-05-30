import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/brand_mark.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final dueCount = state.dueWords.length;
    final dailyGoal = state.learningPlan?.dailyWords ?? user?.dailyGoal ?? 10;
    final reviewTarget = state.learningPlan == null
        ? dueCount
        : dueCount.clamp(0, state.learningPlan!.dailyWords * 2).toInt();
    final todayLessonWords = state.lessons
        .where((lesson) => state.todayCompletedLessonIds.contains(lesson.id))
        .fold(0, (total, lesson) => total + lesson.words.length);
    final todayWork = todayLessonWords + state.todayReviewWordIds.length;
    final dailyProgress = dailyGoal <= 0
        ? 0.0
        : (todayWork / dailyGoal).clamp(0.0, 1.0);
    final currentLesson = state.currentLesson;
    final pathComplete =
        state.lessons.isNotEmpty &&
        state.lessons.every((lesson) => lesson.status == 'completed');
    final wordOfDay = (currentLesson?.words.isNotEmpty ?? false)
        ? currentLesson!.words.first
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        Row(
          children: [
            BrandMark(
              size: 48,
              tooltip: '个人空间',
              onTap: () => context.go('/profile'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => context.push('/search'),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    isDense: true,
                    prefixIcon: Icon(Icons.search),
                    hintText: '搜索单词、短语或例句',
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filledTonal(
              tooltip: '消息通知',
              onPressed: () => context.go('/discover'),
              icon: const Icon(Icons.notifications_outlined),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DailyFocusHeader(
          streak: user?.streak ?? 0,
          target: displayTarget(user?.targetExam),
          level: displayLevel(user?.level),
          todayWork: todayWork,
          totalWork: dailyGoal + reviewTarget,
          progress: dailyProgress,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: '已学',
                value: '${state.completedLearningWords}',
                icon: Icons.school_outlined,
                color: AppTheme.cyan,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: '掌握',
                value:
                    '${state.customWords.where((word) => word.masteryLevel >= 4).length}',
                icon: Icons.verified_outlined,
                color: AppTheme.success,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: '复习',
                value: '${state.dueWords.length}',
                icon: Icons.replay,
                color: AppTheme.mango,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _DailyTaskPanel(
          todayWork: todayWork,
          totalWork: dailyGoal + reviewTarget,
          currentSection:
              currentLesson?.section ??
              displayTarget(state.learningPlan?.target ?? '雅思核心词汇'),
          progress: dailyProgress,
          dailyGoal: dailyGoal,
          dueCount: dueCount,
          canStartNew: currentLesson != null && !pathComplete,
          onNewStudy: () => context.push('/study/new'),
          onReview: () => context.push('/study/review'),
        ),
        const SizedBox(height: 18),
        _HomeInfoLink(
          cue: '📘',
          title: '当前计划',
          body:
              '${displayTarget(state.learningPlan?.target ?? user?.targetExam ?? '雅思核心词汇')} · 每日新学 $dailyGoal · 复习上限 ${reviewTarget == 0 ? '按到期词' : reviewTarget}',
          onTap: () => context.push('/goal-setup'),
        ),
        const SizedBox(height: 18),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.4,
          children: [
            _QuickAction(
              icon: Icons.flag_outlined,
              title: '学习模式',
              subtitle: displayTarget(user?.targetExam),
              onTap: () => context.push('/goal-setup'),
            ),
            _QuickAction(
              icon: Icons.menu_book_outlined,
              title: '单词本',
              subtitle: '${state.totalLearningWords} 词',
              onTap: () => context.push('/wordbook'),
            ),
            _QuickAction(
              icon: Icons.article_outlined,
              title: '每日短文',
              subtitle: '情景填空',
              onTap: () => context.go('/ai-learning'),
            ),
            _QuickAction(
              icon: Icons.leaderboard_outlined,
              title: '排行榜',
              subtitle: '训练场积分',
              onTap: () => context.push('/leaderboard'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _HomeInfoLink(
          cue: wordOfDay?.imageCue ?? '🌟',
          title: '今日词条',
          body: wordOfDay == null
              ? '打开单词卡片'
              : '${wordOfDay.word} · ${wordOfDay.meaning}',
          onTap: () => context.push('/wordbook'),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: '弱项词',
          subtitle: state.weakWords.isEmpty ? '当前还没有高频错词。' : '趁它们堆起来前先复习。',
          trailing: TextButton(
            onPressed: () => context.push('/study/review'),
            child: const Text('复习'),
          ),
        ),
        const SizedBox(height: 12),
        if (state.weakWords.isEmpty)
          const _SoftPanel(
            icon: Icons.check_circle_outline,
            text: '添加生词或完成复习后，这里会展示需要重点处理的词。',
          )
        else
          ...state.weakWords.take(3).map((word) => _WeakWordLink(word: word)),
      ],
    );
  }
}

class _HomeInfoLink extends StatelessWidget {
  const _HomeInfoLink({
    required this.cue,
    required this.title,
    required this.body,
    required this.onTap,
  });

  final String cue;
  final String title;
  final String body;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              ImageCueBadge(cue: cue, size: 52),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      body,
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
    );
  }
}

class _DailyTaskPanel extends StatelessWidget {
  const _DailyTaskPanel({
    required this.todayWork,
    required this.totalWork,
    required this.currentSection,
    required this.progress,
    required this.dailyGoal,
    required this.dueCount,
    required this.canStartNew,
    required this.onNewStudy,
    required this.onReview,
  });

  final int todayWork;
  final int totalWork;
  final String currentSection;
  final double progress;
  final int dailyGoal;
  final int dueCount;
  final bool canStartNew;
  final VoidCallback onNewStudy;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '今日任务控制台',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
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
            '今日 $todayWork/$totalWork 词 · 当前词书 $currentSection',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: canStartNew ? onNewStudy : null,
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text('新学 $dailyGoal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onReview,
                  icon: const Icon(Icons.replay_rounded),
                  label: Text('复习 $dueCount'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DailyFocusHeader extends StatelessWidget {
  const _DailyFocusHeader({
    required this.streak,
    required this.target,
    required this.level,
    required this.todayWork,
    required this.totalWork,
    required this.progress,
  });

  final int streak;
  final String target;
  final String level;
  final int todayWork;
  final int totalWork;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: '$target · $level',
              icon: Icons.track_changes_outlined,
              color: theme.colorScheme.secondary,
            ),
            PillLabel(
              label: '已连续打卡 $streak 天',
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.mango,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '今天完成 $todayWork/$totalWork 词',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.08,
          ),
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: AppTheme.progressTrack(context),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.titleMedium),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeakWordLink extends StatelessWidget {
  const _WeakWordLink({required this.word});

  final CustomWord word;

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
          onTap: () => context.push('/custom-words/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ImageCueBadge(cue: wordInitialCue(word.word), size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '${word.meaning} · 掌握 ${word.masteryLevel}/5',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
