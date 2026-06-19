import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/achievement.dart';

class AchievementsScreen extends ConsumerStatefulWidget {
  const AchievementsScreen({super.key});

  @override
  ConsumerState<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends ConsumerState<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).refreshAchievements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final achievements = state.achievements;
    final unlockedCount = achievements.where((a) => a.unlocked).length;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: const Text('Achievements'),
      ),
      body: SafeArea(
        child: achievements.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  SectionHeader(
                    title: 'Your Achievements',
                    subtitle: '$unlockedCount / ${achievements.length} unlocked',
                  ),
                  const SizedBox(height: 16),
                  for (final achievement in achievements) ...[
                    _AchievementTile(achievement: achievement),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  const _AchievementTile({required this.achievement});

  final Achievement achievement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unlocked = achievement.unlocked;

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: unlocked
                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest,
            ),
            child: Center(
              child: Text(
                unlocked ? '🏆' : '🔒',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: unlocked ? null : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  achievement.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (unlocked && achievement.unlockedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Unlocked',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (unlocked)
            Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 20)
          else
            Icon(
              Icons.radio_button_unchecked,
              color: theme.colorScheme.outlineVariant,
              size: 20,
            ),
        ],
      ),
    );
  }
}
