import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/leaderboard_entry.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaderboard = ref.watch(leaderboardProvider);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: const Text('排行榜'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(title: '本周 XP', subtitle: '好友和班级小组的轻量排名。'),
            const SizedBox(height: 16),
            leaderboard.when(
              data: (entries) {
                if (entries.isEmpty) {
                  return const _LeaderboardEmpty();
                }
                return Column(
                  children: [
                    for (var index = 0; index < entries.length; index++)
                      _LeaderboardTile(entry: entries[index], rank: index + 1),
                  ],
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (error, stackTrace) => const _LeaderboardError(),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.rank});

  final LeaderboardEntry entry;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.iconBadgeSurface(context),
            foregroundColor: theme.colorScheme.primary,
            child: Text('$rank'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.name, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${entry.streak} 天连续学习 · ${entry.totalStudyDays} 天有效记录',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PillLabel(label: '${entry.score} XP', color: AppTheme.mango),
        ],
      ),
    );
  }
}

class _LeaderboardEmpty extends StatelessWidget {
  const _LeaderboardEmpty();

  @override
  Widget build(BuildContext context) {
    return Text(
      '暂无排名数据，完成学习后会自动进入排行榜。',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _LeaderboardError extends StatelessWidget {
  const _LeaderboardError();

  @override
  Widget build(BuildContext context) {
    return Text(
      '暂时无法同步排行榜，请稍后重试。',
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}
