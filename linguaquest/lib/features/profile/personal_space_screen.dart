import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/achievement.dart';
import '../../data/models/forum_post.dart';

class PersonalSpaceScreen extends ConsumerWidget {
  const PersonalSpaceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final achievements = ref.watch(achievementsProvider);
    final posts = ref.watch(forumPostsProvider);
    final currentUid = user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('个人空间'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(achievementsProvider);
            ref.invalidate(forumPostsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const IconCueBadge(
                    icon: Icons.account_circle_outlined,
                    color: AppTheme.cyan,
                    size: 64,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? '学习者',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${displayTarget(user?.targetExam)} · ${displayLevel(user?.level)}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            PillLabel(
                              label: '${user?.points ?? user?.xp ?? 0} XP',
                              icon: Icons.bolt,
                              color: AppTheme.mango,
                            ),
                            PillLabel(
                              label: '${user?.streak ?? 0} 天连续',
                              icon: Icons.local_fire_department,
                              color: AppTheme.coral,
                            ),
                            PillLabel(
                              label: state.currentWordBook?.title ?? '当前词书',
                              icon: Icons.menu_book_outlined,
                              color: AppTheme.cyan,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _PublicStats(
                completedWords: state.completedLearningWords,
                totalStudyDays: user?.totalStudyDays ?? 0,
                totalStudyMinutes: user?.totalStudyMinutes ?? 0,
                forumPosts:
                    posts.value
                        ?.where((post) => post.authorId == currentUid)
                        .length ??
                    0,
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: '成就徽章', subtitle: '由后端根据学习和社区数据计算。'),
              const SizedBox(height: 10),
              achievements.when(
                data: (items) => _AchievementList(achievements: items),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) =>
                    _ErrorLine(text: '暂时无法同步成就，请稍后重试。'),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: '社区发布',
                subtitle: '展示当前账号发布过的论坛帖子。',
                trailing: TextButton.icon(
                  onPressed: () => context.push('/forum/new'),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('发帖'),
                ),
              ),
              const SizedBox(height: 10),
              posts.when(
                data: (items) {
                  final ownPosts = items
                      .where((post) => post.authorId == currentUid)
                      .toList();
                  return _PersonalPostList(posts: ownPosts);
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) =>
                    _ErrorLine(text: '暂时无法同步社区发布，请稍后重试。'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PublicStats extends StatelessWidget {
  const _PublicStats({
    required this.completedWords,
    required this.totalStudyDays,
    required this.totalStudyMinutes,
    required this.forumPosts,
  });

  final int completedWords;
  final int totalStudyDays;
  final int totalStudyMinutes;
  final int forumPosts;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SpaceStat(
            label: '已学词',
            value: '$completedWords',
            icon: Icons.school_outlined,
            color: AppTheme.teal,
          ),
        ),
        const _SpaceDivider(),
        Expanded(
          child: _SpaceStat(
            label: '学习天',
            value: '$totalStudyDays',
            icon: Icons.calendar_month_outlined,
            color: AppTheme.coral,
          ),
        ),
        const _SpaceDivider(),
        Expanded(
          child: _SpaceStat(
            label: '分钟',
            value: '$totalStudyMinutes',
            icon: Icons.timer_outlined,
            color: AppTheme.mango,
          ),
        ),
        const _SpaceDivider(),
        Expanded(
          child: _SpaceStat(
            label: '帖子',
            value: '$forumPosts',
            icon: Icons.forum_outlined,
            color: AppTheme.cyan,
          ),
        ),
      ],
    );
  }
}

class _SpaceStat extends StatelessWidget {
  const _SpaceStat({
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
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(value, style: theme.textTheme.titleMedium),
        const SizedBox(height: 2),
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
    );
  }
}

class _SpaceDivider extends StatelessWidget {
  const _SpaceDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: VerticalDivider(
        width: 16,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

class _AchievementList extends StatelessWidget {
  const _AchievementList({required this.achievements});

  final List<Achievement> achievements;

  @override
  Widget build(BuildContext context) {
    if (achievements.isEmpty) {
      return const _EmptyLine(text: '完成学习和社区动作后，成就会自动出现在这里。');
    }
    return Column(
      children: [
        for (var index = 0; index < achievements.length; index++) ...[
          _AchievementRow(achievement: achievements[index]),
          if (index != achievements.length - 1)
            Divider(
              height: 14,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(
            icon: achievement.unlocked
                ? Icons.workspace_premium_outlined
                : Icons.lock_outline,
            color: achievement.unlocked ? AppTheme.mango : AppTheme.cyan,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  achievement.description,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PillLabel(
            label: achievement.unlocked ? '已解锁' : '进行中',
            color: achievement.unlocked ? AppTheme.success : AppTheme.cyan,
          ),
        ],
      ),
    );
  }
}

class _PersonalPostList extends StatelessWidget {
  const _PersonalPostList({required this.posts});

  final List<ForumPost> posts;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return const _EmptyLine(text: '还没有发布过帖子。完成打卡复盘或错题讨论后会展示在这里。');
    }
    return Column(
      children: [
        for (var index = 0; index < posts.length; index++) ...[
          _PersonalPostRow(post: posts[index]),
          if (index != posts.length - 1)
            Divider(
              height: 14,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _PersonalPostRow extends StatelessWidget {
  const _PersonalPostRow({required this.post});

  final ForumPost post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/forum/posts/${post.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconCueBadge(icon: Icons.article_outlined, color: AppTheme.cyan),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PillLabel(
                label: '${post.likeCount} 赞',
                icon: Icons.thumb_up_alt_outlined,
                color: AppTheme.coral,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
