import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final currentBook = state.currentWordBook;
    final dueCount = state.reviewQueue.length;
    final dailyGoal = state.dailyNewTarget;
    final reviewTarget = state.isStudyPlanPaused ? 0 : dueCount;
    final todayLessonWords = state.todayLearningWords;
    final todayWork = todayLessonWords + state.todayReviewWordIds.length;
    final totalWork = state.isStudyPlanPaused ? 0 : dailyGoal + reviewTarget;
    final dailyProgress = totalWork <= 0
        ? 0.0
        : (todayWork / totalWork).clamp(0.0, 1.0);
    final currentLesson = state.currentLesson;
    final pathComplete =
        state.formalLessons.isNotEmpty &&
        state.formalLessons.every((lesson) => lesson.status == 'completed');
    final wordOfDay = (currentLesson?.words.isNotEmpty ?? false)
        ? currentLesson!.words.first
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        Row(
          children: [
            Tooltip(
              message: '个人空间',
              child: GestureDetector(
                onTap: () => context.go('/profile'),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    (user?.name == null || user!.name.trim().isEmpty)
                        ? '?'
                        : user.name.trim().characters.first.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
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
            _NotificationBellButton(
              unreadCount: state.unreadNotificationCount,
              onPressed: () => context.push('/notifications'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _DailyFocusHeader(
              streak: user?.streak ?? 0,
              target: currentBook?.title ?? displayTarget(user?.targetExam),
              level: state.isStudyPlanPaused ? '已暂停' : displayLevel(user?.level),
              todayWork: todayWork,
              totalWork: totalWork,
              progress: dailyProgress,
              isPaused: state.isStudyPlanPaused,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: _HomeLearningSignals(
              completedWords: state.completedLearningWords,
              masteredWords: state.masteredReviewWords,
              dueWords: state.dueWords.length,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _DailyTaskPanel(
              currentSection:
                  currentLesson?.section ??
                  currentBook?.title ??
                  displayTarget(user?.targetExam ?? '雅思核心词汇'),
              dailyGoal: dailyGoal,
              dueCount: dueCount,
              isPaused: state.isStudyPlanPaused,
              canStartNew:
                  currentLesson != null &&
                  !pathComplete &&
                  !state.isStudyPlanPaused,
              onOpenPlan: () => context.push('/settings/study-plan'),
              onNewStudy: () => context.push('/study/new'),
              onReview: () => context.push('/study/review'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _HomeShortcutList(
              actions: [
                _HomeShortcutData(
                  icon: Icons.menu_book_outlined,
                  title: '单词本',
                  subtitle: currentBook == null
                      ? '${state.totalLearningWords} 词'
                      : '${currentBook.totalWords} 词',
                  onTap: () => context.push('/wordbook'),
                ),
                _HomeShortcutData(
                  icon: Icons.article_outlined,
                  title: '每日短文',
                  subtitle: '情景填空',
                  onTap: () => context.go('/ai-learning'),
                ),
                _HomeShortcutData(
                  icon: Icons.route_outlined,
                  title: '学习路径',
                  subtitle: currentBook?.title ?? '正式词书',
                  onTap: () => context.push('/learn'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _HomeInfoLink(
              cue: wordOfDay?.imageCue ?? '🌟',
              title: '今日词条',
              body: wordOfDay == null
                  ? '打开单词卡片'
                  : '${wordOfDay.word} · ${wordOfDay.meaning}',
              onTap: () => wordOfDay == null
                  ? context.push('/wordbook')
                  : context.push('/wordbook/${wordOfDay.id}'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: '弱项词',
                  subtitle: state.weakWords.isEmpty ? '当前还没有高频错词。' : '趁它们堆起来前先复习。',
                  trailing: TextButton(
                    onPressed: () => context.push('/study/review'),
                    child: const Text('复习'),
                  ),
                ),
                if (state.weakWords.isEmpty)
                  const _SoftPanel(
                    icon: Icons.check_circle_outline,
                    text: '添加生词或完成复习后，这里会展示需要重点处理的词。',
                  )
                else ...[
                  const SizedBox(height: 8),
                  ...state.weakWords.take(3).map((word) => _WeakWordLink(word: word)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NotificationBellButton extends StatelessWidget {
  const _NotificationBellButton({
    required this.unreadCount,
    required this.onPressed,
  });

  final int unreadCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        QuestIconButton(
          tooltip: '消息通知',
          onPressed: onPressed,
          icon: Icons.notifications_outlined,
          color: AppTheme.coral,
        ),
        if (unreadCount > 0)
          Positioned(
            right: -4,
            top: -5,
            child: Container(
              constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
              padding: const EdgeInsets.symmetric(horizontal: 5),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppTheme.coral,
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              child: Text(
                unreadCount > 9 ? '9+' : '$unreadCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HomeLearningSignals extends StatelessWidget {
  const _HomeLearningSignals({
    required this.completedWords,
    required this.masteredWords,
    required this.dueWords,
  });

  final int completedWords;
  final int masteredWords;
  final int dueWords;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _HomeSignal(
            label: '已学',
            value: '$completedWords',
            icon: Icons.school_outlined,
            color: AppTheme.cyan,
          ),
        ),
        const _HomeSignalDivider(),
        Expanded(
          child: _HomeSignal(
            label: '掌握',
            value: '$masteredWords',
            icon: Icons.verified_outlined,
            color: AppTheme.success,
          ),
        ),
        const _HomeSignalDivider(),
        Expanded(
          child: _HomeSignal(
            label: '复习',
            value: '$dueWords',
            icon: Icons.replay,
            color: AppTheme.mango,
          ),
        ),
      ],
    );
  }
}

class _HomeSignal extends StatelessWidget {
  const _HomeSignal({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeSignalDivider extends StatelessWidget {
  const _HomeSignalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: VerticalDivider(
        width: 16,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
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
    required this.currentSection,
    required this.dailyGoal,
    required this.dueCount,
    required this.isPaused,
    required this.canStartNew,
    required this.onOpenPlan,
    required this.onNewStudy,
    required this.onReview,
  });

  final String currentSection;
  final int dailyGoal;
  final int dueCount;
  final bool isPaused;
  final bool canStartNew;
  final VoidCallback onOpenPlan;
  final VoidCallback onNewStudy;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasReview = dueCount > 0;
    final totalTaskCount = canStartNew ? (dailyGoal + dueCount) : dueCount;
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
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  isPaused
                      ? '当前词书 $currentSection · 计划已暂停'
                      : '当前词书 $currentSection · 新学 $dailyGoal 词${hasReview ? " + 复习 $dueCount 词" : ""}',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              TextButton(onPressed: onOpenPlan, child: const Text('调整计划')),
            ],
          ),
          const SizedBox(height: 14),
          if (isPaused)
            OutlinedButton.icon(
              onPressed: onOpenPlan,
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('恢复计划以继续学习'),
            )
          else
            FilledButton.icon(
              onPressed: canStartNew ? onNewStudy : (hasReview ? onReview : null),
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text('开始今日学习 ($totalTaskCount 词)'),
            ),
          if (!isPaused && hasReview) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onReview,
              icon: const Icon(Icons.replay_rounded),
              label: Text('仅复习 ($dueCount 词)'),
            ),
          ],
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
    required this.isPaused,
  });

  final int streak;
  final String target;
  final String level;
  final int todayWork;
  final int totalWork;
  final double progress;
  final bool isPaused;

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
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                isPaused ? '学习计划已暂停' : '今天完成 $todayWork/$totalWork 词',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.08,
                ),
              ),
            ),
            const SizedBox(width: 14),
            _DailyProgressRing(progress: progress),
          ],
        ),
      ],
    );
  }
}

class _DailyProgressRing extends StatelessWidget {
  const _DailyProgressRing({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return SizedBox.square(
      dimension: 82,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 82,
            child: CircularProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              strokeWidth: 8,
              strokeCap: StrokeCap.round,
              backgroundColor: AppTheme.progressTrack(context),
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.teal),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                '今日',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeShortcutList extends StatelessWidget {
  const _HomeShortcutList({required this.actions});

  final List<_HomeShortcutData> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          _HomeShortcutLink(data: actions[index]),
          if (index != actions.length - 1)
            Divider(
              height: 10,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _HomeShortcutLink extends StatelessWidget {
  const _HomeShortcutLink({required this.data});

  final _HomeShortcutData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: data.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Icon(data.icon, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      data.subtitle,
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
    );
  }
}

class _HomeShortcutData {
  const _HomeShortcutData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
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
