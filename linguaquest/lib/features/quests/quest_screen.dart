import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        SectionHeader(
          title: l10n.questCenterTitle,
          subtitle: l10n.questCenterSubtitle,
        ),
        const SizedBox(height: 12),
        const PillLabel(
          label: '任务 XP',
          icon: Icons.bolt,
          color: AppTheme.mango,
        ),
        const SizedBox(height: 16),
        _QuestRow(
          icon: Icons.flag_outlined,
          title: l10n.questDailyTask,
          body: l10n.questDailyTaskBody,
          value: '20 XP',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.workspace_premium_outlined,
          title: l10n.questAchievements,
          body: l10n.questAchievementsBody,
          value: l10n.questAchievementsValue,
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.leaderboard_outlined,
          title: l10n.questLeaderboard,
          body: l10n.questLeaderboardBody,
          value: l10n.questWeekly,
          route: '/leaderboard',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.insights_outlined,
          title: l10n.questAnalytics,
          body: l10n.questAnalyticsBody,
          value: l10n.questTrend,
          route: '/progress',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.groups_outlined,
          title: l10n.questClassMode,
          body: l10n.questClassModeBody,
          value: l10n.questClassCode,
          route: '/class-mode',
        ),
        const SizedBox(height: 10),
        _QuestRow(
          icon: Icons.smart_toy_outlined,
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
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
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
          PillLabel(label: value, color: AppTheme.coral),
        ],
      ),
    );

    if (route == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(route!),
        child: content,
      ),
    );
  }
}
