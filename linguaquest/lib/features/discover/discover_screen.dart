import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
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
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: l10n.discoverTitle,
          subtitle: l10n.discoverSubtitle,
          trailing: QuestIconButton(
            tooltip: l10n.discoverTaskCenter,
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
              label: '${user?.xp ?? 0} ${l10n.commonXP}',
              icon: Icons.bolt,
              color: AppTheme.mango,
            ),
            PillLabel(
              label: '${user?.streak ?? 0} ${l10n.homeStreakLabel}',
              icon: Icons.local_fire_department_outlined,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _XpUseStatusLine(currentXp: user?.xp ?? 0, l10n: l10n),
        const SizedBox(height: 22),
        SectionHeader(
          title: l10n.discoverXpTasks,
          subtitle: l10n.discoverXpTasksSubtitle,
        ),
        const SizedBox(height: 12),
        _RewardTaskList(
          tasks: [
            _RewardTaskData(
              icon: Icons.calendar_month_outlined,
              title: l10n.discoverDailyCheckin,
              condition: l10n.discoverDailyCheckinCondition,
              points: 5,
              isDone: checkedInToday,
              isClaimed: claimed.contains('daily-checkin'),
              onTap: () => context.go('/home'),
              onClaim: () => _claimReward(
                context,
                ref,
                id: 'daily-checkin',
                title: l10n.discoverDailyCheckin,
                points: 5,
                isAvailable: checkedInToday,
              ),
            ),
            _RewardTaskData(
              icon: Icons.school_outlined,
              title: l10n.discoverNewLearning,
              condition: l10n.discoverNewLearningCondition,
              points: 20,
              isDone: newLearningDone,
              isClaimed: claimed.contains('new-learning'),
              onTap: () => context.push('/study/new'),
              onClaim: () => _claimReward(
                context,
                ref,
                id: 'new-learning',
                title: l10n.discoverNewLearning,
                points: 20,
                isAvailable: newLearningDone,
              ),
            ),
            _RewardTaskData(
              icon: Icons.replay_outlined,
              title: l10n.discoverReviewDone,
              condition: l10n.discoverReviewDoneCondition,
              points: 15,
              isDone: reviewDone,
              isClaimed: claimed.contains('review-done'),
              onTap: () => context.push('/study/review'),
              onClaim: () => _claimReward(
                context,
                ref,
                id: 'review-done',
                title: l10n.discoverReviewDone,
                points: 15,
                isAvailable: reviewDone,
              ),
            ),
            _RewardTaskData(
              icon: Icons.sports_esports_outlined,
              title: l10n.discoverTrainingChallenge,
              condition: l10n.discoverTrainingChallengeCondition,
              points: 20,
              isDone: false,
              isClaimed: claimed.contains('training-challenge'),
              onTap: () => context.go('/training'),
              onClaim: () {},
            ),
            _RewardTaskData(
              icon: Icons.cleaning_services_outlined,
              title: l10n.discoverWeakCleanup,
              condition: l10n.discoverWeakCleanupCondition,
              points: 10,
              isDone: weakCleanupDone,
              isClaimed: claimed.contains('weak-cleanup'),
              onTap: () => context.push('/review'),
              onClaim: () => _claimReward(
                context,
                ref,
                id: 'weak-cleanup',
                title: l10n.discoverWeakCleanup,
                points: 10,
                isAvailable: weakCleanupDone,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        SectionHeader(title: l10n.discoverLuckyDraw, subtitle: l10n.discoverLuckyDrawSubtitle),
        const SizedBox(height: 12),
        const _LotteryInfoLine(),
        const SizedBox(height: 22),
        SectionHeader(title: l10n.discoverCommunityPosts, subtitle: l10n.discoverCommunityPostsSubtitle),
        const SizedBox(height: 12),
        const _ForumPostList(
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
        duration: const Duration(seconds: 2),
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
}

class _LotteryInfoLine extends StatelessWidget {
  const _LotteryInfoLine();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                l10n.discoverLuckyDrawItems,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.discoverLuckyDrawCost,
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
  const _XpUseStatusLine({required this.currentXp, required this.l10n});

  final int currentXp;
  final AppLocalizations l10n;

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
              Text(l10n.discoverXpUsage, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                '${l10n.discoverXpUsageDesc} $currentXp ${l10n.commonXP}${l10n.localeName == 'zh' ? '。' : '.'}',
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

  final List<_ForumPostData> posts;

  @override
  Widget build(BuildContext context) {
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

  final _ForumPostData post;

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
          const Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 18),
              SizedBox(width: 4),
              Text('24'),
              SizedBox(width: 16),
              Icon(Icons.mode_comment_outlined, size: 18),
              SizedBox(width: 4),
              Text('6'),
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
