import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/daily_reward_task.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final tasks = state.rewardTasks;
    final checkInTask = _taskById(tasks, 'dailyCheckIn');
    final isCheckingIn = state.pendingRewardTaskIds.contains('dailyCheckIn');
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: '发现',
          subtitle: '签到、积分任务、抽奖和学习社区；领取的 XP 会加入个人总积分。',
          trailing: QuestIconButton(
            tooltip: '任务中心',
            onPressed: () => context.push('/quest'),
            icon: Icons.emoji_events_outlined,
            color: AppTheme.mango,
          ),
        ),
        const SizedBox(height: 14),
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
              label: '${user?.streak ?? 0} 天连续打卡',
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _XpUseStatusLine(currentXp: user?.xp ?? 0),
        const SizedBox(height: 16),
        _DailyCheckInPanel(
          task: checkInTask,
          isCheckingIn: isCheckingIn,
          onCheckIn: () => _checkIn(context, ref),
          onClaim: checkInTask == null
              ? null
              : () => _claimReward(context, ref, checkInTask),
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: '积分任务',
          subtitle: '完成条件后点“领取”，XP 会立即加入个人主页和排行榜统计。',
        ),
        const SizedBox(height: 12),
        if (state.isRewardLoading && tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (tasks.isEmpty)
          _RewardEmptyState(
            message: state.errorMessage ?? '今天的积分任务暂时没有加载出来。',
            isLoading: state.isRewardLoading,
            onRetry: () =>
                ref.read(appControllerProvider.notifier).refreshRewardTasks(),
          )
        else
          _RewardTaskList(
            tasks: [
              for (final task in tasks.where(
                (item) => item.id != 'dailyCheckIn',
              ))
                _RewardTaskData(
                  icon: _iconForTask(task.id),
                  task: task,
                  isPending: state.pendingRewardTaskIds.contains(task.id),
                  onTap: () => _openTaskEntry(context, task),
                  onClaim: () => _claimReward(context, ref, task),
                ),
            ],
          ),
        const SizedBox(height: 22),
        const SectionHeader(title: '积分抽奖', subtitle: '奖品只做虚拟装饰，不影响学习公平性。'),
        const SizedBox(height: 12),
        const _LotteryInfoLine(),
        const SizedBox(height: 22),
        const SectionHeader(title: '社区帖子', subtitle: '学习打卡和错题讨论集中展示。'),
        const SizedBox(height: 12),
        _ForumPostList(
          onInteract: () => _recordForumInteraction(context, ref),
          posts: [
            _ForumPostData(
              title: '今日打卡：用 12 分钟复习了 18 个词',
              tag: '今日打卡',
              body: '错词集中在近义辨析，明天准备从训练场的易混词挑战开始。',
            ),
            _ForumPostData(
              title: '雅思阅读里怎么记 abstract?',
              tag: '错题讨论',
              body: 'abstract 在论文和阅读文章里经常不是“抽象”的意思，要结合语境判断。',
            ),
          ],
        ),
      ],
    );
  }

  DailyRewardTask? _taskById(List<DailyRewardTask> tasks, String id) {
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  IconData _iconForTask(String id) {
    switch (id) {
      case 'newLearning':
        return Icons.school_outlined;
      case 'reviewDone':
        return Icons.replay_outlined;
      case 'trainingChallenge':
        return Icons.sports_esports_outlined;
      case 'wrongCleanup':
        return Icons.cleaning_services_outlined;
      case 'forumInteraction':
        return Icons.forum_outlined;
    }
    return Icons.task_alt_outlined;
  }

  void _openTaskEntry(BuildContext context, DailyRewardTask task) {
    if (task.id == 'forumInteraction') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('在下方社区帖子点击“记录互动”，即可完成论坛互动任务。')),
      );
      return;
    }
    if (task.targetRoute.startsWith('/') && task.targetRoute != '/discover') {
      context.push(task.targetRoute);
    }
  }

  Future<void> _checkIn(BuildContext context, WidgetRef ref) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .checkInToday();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(succeeded ? '签到成功，今天的签到积分可以领取了。' : '签到失败，请稍后重试。')),
    );
  }

  Future<void> _claimReward(
    BuildContext context,
    WidgetRef ref,
    DailyRewardTask task,
  ) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .claimReward(task.id);
    if (!context.mounted) return;
    final currentXp = ref.read(appControllerProvider).user?.xp ?? 0;
    final message = succeeded
        ? '${task.title} 已入账 +${task.points} XP，当前总积分 $currentXp XP'
        : ref.read(appControllerProvider).errorMessage ?? '暂时无法领取这个任务';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        action: succeeded
            ? SnackBarAction(
                label: '查看主页',
                onPressed: () => context.go('/profile'),
              )
            : null,
      ),
    );
  }

  Future<void> _recordForumInteraction(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .recordForumInteraction();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(succeeded ? '论坛互动已通过，积分任务可领取。' : '论坛互动记录失败，请稍后重试。'),
      ),
    );
  }
}

class _LotteryInfoLine extends StatelessWidget {
  const _LotteryInfoLine();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ImageCueBadge(cue: '🎁', size: 52),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '头像框、主页背景、学习徽章、训练场称号、卡片皮肤',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                '消耗 30 积分抽一次；稀有概率透明展示，未中奖也给碎片。',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _XpUseStatusLine extends StatelessWidget {
  const _XpUseStatusLine({required this.currentXp});

  final int currentXp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconCueBadge(icon: Icons.bolt_rounded, color: AppTheme.mango),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('XP 用途', style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                '领取后同步到个人主页和排行榜；积分抽奖会消耗当前 XP。当前余额 $currentXp XP。',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DailyCheckInPanel extends StatelessWidget {
  const _DailyCheckInPanel({
    required this.task,
    required this.isCheckingIn,
    required this.onCheckIn,
    required this.onClaim,
  });

  final DailyRewardTask? task;
  final bool isCheckingIn;
  final VoidCallback onCheckIn;
  final VoidCallback? onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentTask = task;
    final checkedIn =
        currentTask?.isClaimable == true || currentTask?.isClaimed == true;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.teal.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.teal.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(
            icon: checkedIn
                ? Icons.check_circle_outline
                : Icons.calendar_month_outlined,
            color: checkedIn ? AppTheme.success : AppTheme.teal,
            size: 50,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('每日签到', style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  currentTask == null
                      ? '任务加载后即可签到。'
                      : currentTask.isClaimed
                      ? '今天已签到，并已领取 +${currentTask.points} XP。'
                      : checkedIn
                      ? '今天已签到，记得领取 +${currentTask.points} XP。'
                      : '点击签到后，签到任务会进入可领取状态。',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed:
                          checkedIn || isCheckingIn || currentTask == null
                          ? null
                          : onCheckIn,
                      icon: isCheckingIn
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.edit_calendar_outlined),
                      label: Text(
                        isCheckingIn
                            ? '签到中'
                            : checkedIn
                            ? '已签到'
                            : '签到',
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed:
                          currentTask?.isClaimable == true && !isCheckingIn
                          ? onClaim
                          : null,
                      icon: const Icon(Icons.bolt),
                      label: Text(
                        currentTask?.isClaimed == true ? '已领取' : '领取签到积分',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardEmptyState extends StatelessWidget {
  const _RewardEmptyState({
    required this.message,
    required this.isLoading,
    required this.onRetry,
  });

  final String message;
  final bool isLoading;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: isLoading ? null : onRetry,
            icon: isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_outlined),
            label: Text(isLoading ? '加载中' : '重新加载任务'),
          ),
        ],
      ),
    );
  }
}

class _RewardTaskList extends StatelessWidget {
  const _RewardTaskList({required this.tasks});

  final List<_RewardTaskData> tasks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < tasks.length; index++) ...[
          _RewardTaskRow(task: tasks[index]),
          if (index != tasks.length - 1)
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

class _RewardTaskRow extends StatelessWidget {
  const _RewardTaskRow({required this.task});

  final _RewardTaskData task;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canClaim = task.task.isClaimable;
    final activeColor = canClaim
        ? AppTheme.teal
        : task.task.isClaimed
        ? AppTheme.success
        : AppTheme.mango;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: task.isPending
            ? null
            : canClaim
            ? task.onClaim
            : task.task.isClaimed
            ? null
            : task.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(task.icon, color: activeColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(task.task.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      task.task.isClaimable
                          ? '已完成条件，点击领取奖励。'
                          : task.task.condition,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: PillLabel(
                    label: task.isPending
                        ? '处理中'
                        : task.task.isClaimed
                        ? '已入账 +${task.task.points} XP'
                        : canClaim
                        ? '可领取 +${task.task.points} XP'
                        : '去完成 +${task.task.points} XP',
                    icon: task.isPending
                        ? Icons.hourglass_empty_rounded
                        : task.task.isClaimed || task.task.isClaimable
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RewardTaskData {
  const _RewardTaskData({
    required this.icon,
    required this.task,
    required this.isPending,
    required this.onTap,
    required this.onClaim,
  });

  final IconData icon;
  final DailyRewardTask task;
  final bool isPending;
  final VoidCallback onTap;
  final VoidCallback onClaim;
}

class _ForumPostList extends StatelessWidget {
  const _ForumPostList({required this.posts, required this.onInteract});

  final List<_ForumPostData> posts;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          _ForumPostRow(post: posts[index], onInteract: onInteract),
          if (index != posts.length - 1)
            Divider(
              height: 16,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _ForumPostRow extends StatelessWidget {
  const _ForumPostRow({required this.post, required this.onInteract});

  final _ForumPostData post;
  final VoidCallback onInteract;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillLabel(
            label: post.tag,
            icon: Icons.tag_outlined,
            color: AppTheme.coral,
          ),
          const SizedBox(height: 10),
          Text(post.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            post.body,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 18),
              const SizedBox(width: 4),
              const Text('24'),
              const SizedBox(width: 16),
              const Icon(Icons.mode_comment_outlined, size: 18),
              const SizedBox(width: 4),
              const Text('6'),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: onInteract,
                icon: const Icon(Icons.task_alt_outlined, size: 18),
                label: const Text('记录互动'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ForumPostData {
  const _ForumPostData({
    required this.title,
    required this.tag,
    required this.body,
  });

  final String title;
  final String tag;
  final String body;
}
