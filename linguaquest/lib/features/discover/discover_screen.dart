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
    final newLearningDone = state.todayCompletedLessonIds.isNotEmpty;
    final reviewDone = state.todayReviewWordIds.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        GradientHeroCard(
          title: '发现',
          subtitle: '签到、积分任务、抽奖和学习社区都放在这里，避免干扰首页的学习入口。',
          icon: Icons.explore_rounded,
          badge: '${user?.xp ?? 0} 积分 · ${user?.streak ?? 0} 天连续打卡',
          action: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepTeal,
            ),
            onPressed: () => context.push('/quest'),
            icon: const Icon(Icons.emoji_events_outlined),
            label: const Text('任务中心'),
          ),
        ),
        const SizedBox(height: 22),
        const SectionHeader(
          title: '积分任务',
          subtitle: '满足条件后领取积分；未完成时跳转到对应学习入口。',
        ),
        const SizedBox(height: 12),
        _RewardTaskCard(
          icon: Icons.calendar_month_outlined,
          title: '每日签到',
          condition: '当天打开并完成一次学习动作',
          points: 5,
          isDone: (user?.lastStudyDate != null),
          onTap: () => context.go('/home'),
        ),
        _RewardTaskCard(
          icon: Icons.school_outlined,
          title: '完成新学',
          condition: '完成今日新学任务',
          points: 20,
          isDone: newLearningDone,
          onTap: () => context.push('/learn'),
        ),
        _RewardTaskCard(
          icon: Icons.replay_outlined,
          title: '完成复习',
          condition: '完成今日到期复习',
          points: 15,
          isDone: reviewDone,
          onTap: () => context.push('/review'),
        ),
        _RewardTaskCard(
          icon: Icons.sports_esports_outlined,
          title: '训练场挑战',
          condition: '完成任意训练场游戏',
          points: 20,
          isDone: false,
          onTap: () => context.go('/training'),
        ),
        _RewardTaskCard(
          icon: Icons.cleaning_services_outlined,
          title: '错词清理',
          condition: '今日错词再次答对',
          points: 10,
          isDone: state.weakWords.isEmpty && state.customWords.isNotEmpty,
          onTap: () => context.push('/review'),
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
}

class _RewardTaskCard extends StatelessWidget {
  const _RewardTaskCard({
    required this.icon,
    required this.title,
    required this.condition,
    required this.points,
    required this.isDone,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String condition;
  final int points;
  final bool isDone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: isDone ? null : onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isDone ? Colors.green : AppTheme.mango).withValues(
                alpha: 0.14,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: isDone ? Colors.green : AppTheme.mango),
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
            label: isDone ? '已获取' : '+$points',
            icon: isDone
                ? Icons.check_circle_outline
                : Icons.add_circle_outline,
            color: isDone ? Colors.green : AppTheme.mango,
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
