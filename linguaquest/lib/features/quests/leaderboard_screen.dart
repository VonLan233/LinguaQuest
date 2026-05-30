import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appControllerProvider).user;
    final entries = [
      _Entry(name: user?.name ?? 'Learner', xp: user?.xp ?? 0, rank: 1),
      const _Entry(name: 'Maya', xp: 860, rank: 2),
      const _Entry(name: 'Chen', xp: 790, rank: 3),
      const _Entry(name: 'Aisha', xp: 650, rank: 4),
    ]..sort((a, b) => b.xp.compareTo(a.xp));

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: const Text('排行榜'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(title: '本周 XP', subtitle: '好友和未来班级小组的轻量排名原型。'),
            const SizedBox(height: 16),
            for (var index = 0; index < entries.length; index++)
              _LeaderboardTile(entry: entries[index], rank: index + 1),
          ],
        ),
      ),
    );
  }
}

class _Entry {
  const _Entry({required this.name, required this.xp, required this.rank});

  final String name;
  final int xp;
  final int rank;
}

class _LeaderboardTile extends StatelessWidget {
  const _LeaderboardTile({required this.entry, required this.rank});

  final _Entry entry;
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
                  '仅统计有效学习 XP',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PillLabel(label: '${entry.xp} XP', color: AppTheme.mango),
        ],
      ),
    );
  }
}
