import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class DiscoverScreen extends ConsumerWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final claimed = state.todayClaimedRewardIds;
    final newLearningDone = state.todayCompletedLessonIds.isNotEmpty;
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
          title: '发现',
          subtitle: '签到、积分任务、抽奖和学习社区；领取的 XP 会加入个人总积分。',
          trailing: IconButton.filledTonal(
            tooltip: '任务中心',
            onPressed: () => context.push('/quest'),
            icon: const Icon(Icons.emoji_events_outlined),
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
        QuestCard(
          padding: const EdgeInsets.all(16),
          color: AppTheme.warmSurface(context),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ImageCueBadge(cue: '⚡', size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP 用途',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '领取后立即同步到个人主页和排行榜；积分抽奖会消耗当前 XP。当前余额 ${user?.xp ?? 0} XP。',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: '积分任务',
          subtitle: '完成条件后点“领取”，XP 会立即加入个人主页和排行榜统计。',
        ),
        const SizedBox(height: 12),
        _RewardTaskCard(
          icon: Icons.calendar_month_outlined,
          title: '每日签到',
          condition: '当天打开并完成一次学习动作',
          points: 5,
          isDone: checkedInToday,
          isClaimed: claimed.contains('daily-checkin'),
          onTap: () => context.go('/home'),
          onClaim: () => _claimReward(
            context,
            ref,
            id: 'daily-checkin',
            title: '每日签到',
            points: 5,
            isAvailable: checkedInToday,
          ),
        ),
        _RewardTaskCard(
          icon: Icons.school_outlined,
          title: '完成新学',
          condition: '完成今日新学任务',
          points: 20,
          isDone: newLearningDone,
          isClaimed: claimed.contains('new-learning'),
          onTap: () => context.push('/learn'),
          onClaim: () => _claimReward(
            context,
            ref,
            id: 'new-learning',
            title: '完成新学',
            points: 20,
            isAvailable: newLearningDone,
          ),
        ),
        _RewardTaskCard(
          icon: Icons.replay_outlined,
          title: '完成复习',
          condition: '完成今日到期复习',
          points: 15,
          isDone: reviewDone,
          isClaimed: claimed.contains('review-done'),
          onTap: () => context.push('/study/review'),
          onClaim: () => _claimReward(
            context,
            ref,
            id: 'review-done',
            title: '完成复习',
            points: 15,
            isAvailable: reviewDone,
          ),
        ),
        _RewardTaskCard(
          icon: Icons.sports_esports_outlined,
          title: '训练场挑战',
          condition: '完成任意训练场游戏',
          points: 20,
          isDone: false,
          isClaimed: claimed.contains('training-challenge'),
          onTap: () => context.go('/training'),
          onClaim: () {},
        ),
        _RewardTaskCard(
          icon: Icons.cleaning_services_outlined,
          title: '错词清理',
          condition: '今日错词再次答对',
          points: 10,
          isDone: weakCleanupDone,
          isClaimed: claimed.contains('weak-cleanup'),
          onTap: () => context.push('/review'),
          onClaim: () => _claimReward(
            context,
            ref,
            id: 'weak-cleanup',
            title: '错词清理',
            points: 10,
            isAvailable: weakCleanupDone,
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: '积分抽奖', subtitle: '奖品只做虚拟装饰，不影响学习公平性。'),
        const SizedBox(height: 12),
        QuestCard(
          padding: const EdgeInsets.all(16),
          color: AppTheme.accentSurface(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const ImageCueBadge(cue: '🎁', size: 58),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '头像框、主页背景、学习徽章、训练场称号、卡片皮肤',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('消耗 30 积分抽一次；稀有概率透明展示，未中奖也给碎片。'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: '社区帖子', subtitle: '首版为列表/详情/评论壳，后续接入审核和举报。'),
        const SizedBox(height: 12),
        const _ForumPostCard(
          title: '今日打卡：用 12 分钟复习了 18 个词',
          tag: '今日打卡',
          body: '错词集中在近义辨析，明天准备从训练场的易混词挑战开始。',
        ),
        const _ForumPostCard(
          title: '雅思阅读里怎么记 abstract?',
          tag: '错题讨论',
          body: 'abstract 在论文和阅读文章里经常不是“抽象”的意思，要结合语境判断。',
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
}

class _RewardTaskCard extends StatelessWidget {
  const _RewardTaskCard({
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

  @override
  Widget build(BuildContext context) {
    final canClaim = isDone && !isClaimed;
    final activeColor = canClaim
        ? AppTheme.teal
        : isDone
        ? AppTheme.success
        : AppTheme.mango;
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: canClaim
          ? onClaim
          : isDone
          ? null
          : onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: activeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(condition),
              ],
            ),
          ),
          PillLabel(
            label: isClaimed
                ? '已入账 +$points XP'
                : canClaim
                ? '领取 +$points XP'
                : '去完成 +$points XP',
            icon: isDone
                ? Icons.check_circle_outline
                : Icons.add_circle_outline,
            color: activeColor,
          ),
        ],
      ),
    );
  }
}

class _ForumPostCard extends StatelessWidget {
  const _ForumPostCard({
    required this.title,
    required this.tag,
    required this.body,
  });

  final String title;
  final String tag;
  final String body;

  @override
  Widget build(BuildContext context) {
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PillLabel(
            label: tag,
            icon: Icons.tag_outlined,
            color: AppTheme.coral,
          ),
          const SizedBox(height: 10),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(body),
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
