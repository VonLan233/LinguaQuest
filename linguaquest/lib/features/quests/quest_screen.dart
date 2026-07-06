import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:linguaquest/core/theme/app_icons.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class QuestScreen extends ConsumerWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final unlockedCount = state.achievements.where((a) => a.unlocked).length;
    final totalAchievements = state.achievements.length;
    final achievementValue = totalAchievements > 0
        ? '$unlockedCount / $totalAchievements'
        : l10n.questAchievementsValue;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: l10n.questCenterTitle,
          subtitle: l10n.questCenterSubtitle,
        ),
        const SizedBox(height: 12),
        AppPill(
          label: l10n.questTaskXp,
          icon: AppIcons.bolt,
          variant: PillVariant.xp,
        ),
        const SizedBox(height: 16),
        _QuestRow(
          icon: AppIcons.flag,
          title: l10n.questDailyTask,
          body: l10n.questDailyTaskBody,
          value: '20 XP',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: AppIcons.workspacePremium,
          title: l10n.questAchievements,
          body: l10n.questAchievementsBody,
          value: achievementValue,
          route: '/achievements',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: AppIcons.leaderboard,
          title: l10n.questLeaderboard,
          body: l10n.questLeaderboardBody,
          value: l10n.questWeekly,
          route: '/leaderboard',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: AppIcons.insights,
          title: l10n.questAnalytics,
          body: l10n.questAnalyticsBody,
          value: l10n.questTrend,
          route: '/progress',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: AppIcons.smartToy,
          title: l10n.questAiTutor,
          body: l10n.questAiTutorBody,
          value: '暂未开放',
          route: '/ai-tutor',
        ),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  const _QuestRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.value,
    this.route,
  });

  final IconData icon;
  final String title;
  final String body;
  final String value;
  final String? route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      onTap: route == null ? null : () => context.push(route!),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(icon: icon, color: theme.colorScheme.secondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          AppPill(label: value, variant: PillVariant.primary),
        ],
      ),
    );
  }
}
