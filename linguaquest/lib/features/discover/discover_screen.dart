import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/forum_post.dart';
import '../../data/models/reward_task.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final forumPosts = ref.watch(forumPostsProvider);
    final user = state.user;
    final claimed = state.todayClaimedRewardIds;
    final newLearningDone = state.todayCompletedFormalLessonIds.isNotEmpty;
    final reviewDone = state.todayReviewWordIds.isNotEmpty;
    final reviewedMistakeToday = state.customWords.any(
      (word) =>
          state.todayReviewWordIds.contains(word.id) && word.wrongCount > 0,
    );
    final weakCleanupDone = reviewedMistakeToday && state.weakWords.isEmpty;
    final checkedInToday = DateUtils.isSameDay(
      user?.lastStudyDate?.toLocal(),
      DateTime.now(),
    );
    final serverTasks = <String, RewardTask>{
      for (final task in state.rewardTasks) task.id: task,
    };
    _RewardTaskData taskData({
      required String id,
      required IconData icon,
      required String title,
      required String condition,
      required int points,
      required bool fallbackDone,
      required VoidCallback onTap,
    }) {
      final task = serverTasks[id];
      final resolvedPoints = task?.points ?? points;
      final resolvedTitle = task?.title ?? title;
      final isAvailable = task?.isAvailable ?? fallbackDone;
      return _RewardTaskData(
        icon: icon,
        title: resolvedTitle,
        condition: task?.condition ?? condition,
        points: resolvedPoints,
        isDone: isAvailable,
        isClaimed: task?.isClaimed ?? claimed.contains(id),
        onTap: onTap,
        onClaim: () => _claimReward(
          context,
          ref,
          id: id,
          title: resolvedTitle,
          points: resolvedPoints,
          isAvailable: isAvailable,
        ),
      );
    }

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
        const SizedBox(height: 22),
        const SectionHeader(
          title: '积分任务',
          subtitle: '完成条件后点“领取”，XP 会立即加入个人主页和排行榜统计。',
        ),
        const SizedBox(height: 12),
        _RewardTaskList(
          tasks: [
            taskData(
              id: 'daily-checkin',
              icon: Icons.calendar_month_outlined,
              title: '每日签到',
              condition: '当天完成一次学习或复习动作',
              points: 5,
              fallbackDone: checkedInToday,
              onTap: () => context.go('/home'),
            ),
            taskData(
              id: 'complete-new',
              icon: Icons.school_outlined,
              title: '完成新学',
              condition: '完成今日新学任务',
              points: 12,
              fallbackDone: newLearningDone,
              onTap: () => context.push('/study/new'),
            ),
            taskData(
              id: 'complete-review',
              icon: Icons.replay_outlined,
              title: '完成复习',
              condition: '完成今日到期复习',
              points: 10,
              fallbackDone: reviewDone,
              onTap: () => context.push('/study/review'),
            ),
            taskData(
              id: 'training-challenge',
              icon: Icons.sports_esports_outlined,
              title: '训练场挑战',
              condition: '完成任意训练场游戏',
              points: 10,
              fallbackDone: false,
              onTap: () => context.go('/training'),
            ),
            taskData(
              id: 'mistake-cleanup',
              icon: Icons.cleaning_services_outlined,
              title: '错词清理',
              condition: '今日错词再次答对',
              points: 8,
              fallbackDone: weakCleanupDone,
              onTap: () => context.push('/review'),
            ),
            taskData(
              id: 'forum-interaction',
              icon: Icons.forum_outlined,
              title: '论坛互动',
              condition: '发帖或评论通过审核',
              points: 3,
              fallbackDone: false,
              onTap: () => context.push('/forum/new'),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: '积分抽奖', subtitle: '奖品只做虚拟装饰，不影响学习公平性。'),
        const SizedBox(height: 12),
        _LotteryInfoLine(
          isBusy: state.isLoading,
          onDraw: () => _drawLottery(context, ref),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: '社区帖子',
          subtitle: '学习打卡和错题讨论集中展示。',
          trailing: QuestIconButton(
            tooltip: '发布帖子',
            onPressed: () => context.push('/forum/new'),
            icon: Icons.edit_outlined,
            color: AppTheme.coral,
          ),
        ),
        const SizedBox(height: 12),
        forumPosts.when(
          data: (posts) => _ForumPostList(posts: posts),
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => const _ForumPostError(),
        ),
      ],
    );
  }

  Future<void> _claimReward(
    BuildContext context,
    WidgetRef ref, {
    required String id,
    required String title,
    required int points,
    required bool isAvailable,
  }) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .claimReward(id: id, points: points, isAvailable: isAvailable);
    if (!context.mounted) return;
    final currentXp = ref.read(appControllerProvider).user?.xp ?? 0;
    final message = succeeded
        ? '$title 已入账 +$points XP，当前总积分 $currentXp XP'
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

  Future<void> _drawLottery(BuildContext context, WidgetRef ref) async {
    final draw = await ref.read(appControllerProvider.notifier).drawLottery();
    if (!context.mounted) return;
    final errorMessage = ref.read(appControllerProvider).errorMessage;
    final message = draw == null
        ? errorMessage ?? '暂时无法抽奖'
        : '抽奖完成：${draw.prize}，消耗 ${draw.pointsCost} XP';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LotteryInfoLine extends StatelessWidget {
  const _LotteryInfoLine({required this.isBusy, required this.onDraw});

  final bool isBusy;
  final VoidCallback onDraw;

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
                '消耗 20 积分抽一次；稀有概率透明展示，未中奖也给碎片。',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: isBusy ? null : onDraw,
                  icon: const Icon(Icons.casino_outlined),
                  label: Text(isBusy ? '处理中' : '抽一次'),
                ),
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
    final canClaim = task.isDone && !task.isClaimed;
    final activeColor = canClaim
        ? AppTheme.teal
        : task.isDone
        ? AppTheme.success
        : AppTheme.mango;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: canClaim
            ? task.onClaim
            : task.isDone
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
                    Text(task.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      task.condition,
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
                    label: task.isClaimed
                        ? '已入账 +${task.points} XP'
                        : canClaim
                        ? '领取 +${task.points} XP'
                        : '去完成 +${task.points} XP',
                    icon: task.isDone
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
    required this.title,
    required this.condition,
    required this.points,
    required this.isDone,
    required this.isClaimed,
    required this.onTap,
    required this.onClaim,
  });

  final IconData icon;
  final String title;
  final String condition;
  final int points;
  final bool isDone;
  final bool isClaimed;
  final VoidCallback onTap;
  final VoidCallback onClaim;
}

class _ForumPostList extends StatelessWidget {
  const _ForumPostList({required this.posts});

  final List<ForumPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return Text(
        '暂无社区帖子，发布学习打卡后会在这里展示。',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          _ForumPostRow(post: posts[index]),
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
  const _ForumPostRow({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tag = post.tags.isEmpty ? '学习讨论' : post.tags.first;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/forum/posts/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 18, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PillLabel(
                label: tag,
                icon: Icons.tag_outlined,
                color: AppTheme.coral,
              ),
              const SizedBox(height: 10),
              Text(post.title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                post.content,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.thumb_up_alt_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text('${post.likeCount}'),
                  const SizedBox(width: 16),
                  const Icon(Icons.mode_comment_outlined, size: 18),
                  const SizedBox(width: 4),
                  Text('${post.commentCount}'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ForumPostError extends StatelessWidget {
  const _ForumPostError();

  @override
  Widget build(BuildContext context) {
    return Text(
      '暂时无法同步社区帖子，请稍后重试。',
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
