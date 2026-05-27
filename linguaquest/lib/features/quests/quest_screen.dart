import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        const GradientHeroCard(
          title: 'Quest hub',
          subtitle:
              'Daily missions, badges, leaderboard, class mode, and AI feedback live here.',
          icon: Icons.emoji_events_outlined,
          badge: '20 XP available today',
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Quest hub',
          subtitle:
              'Daily quests and social layers are wired as product-ready shells for phase two.',
        ),
        const SizedBox(height: 16),
        const _QuestCard(
          icon: Icons.flag_outlined,
          title: 'Daily quest',
          body: 'Complete one lesson and review five due words.',
          value: '20 XP',
        ),
        const SizedBox(height: 10),
        const _QuestCard(
          icon: Icons.workspace_premium_outlined,
          title: 'Badges',
          body: '7-day streak, 100 words learned, first perfect lesson.',
          value: '3 active',
        ),
        const SizedBox(height: 10),
        _QuestCard(
          icon: Icons.leaderboard_outlined,
          title: 'Leaderboard',
          body: 'Weekly XP ranking across friends and future classes.',
          value: 'Mock',
          route: '/leaderboard',
        ),
        const SizedBox(height: 10),
        _QuestCard(
          icon: Icons.insights_outlined,
          title: 'Progress analytics',
          body: 'Accuracy, vocabulary growth, and review completion trends.',
          value: 'Preview',
          route: '/progress',
        ),
        const SizedBox(height: 10),
        _QuestCard(
          icon: Icons.groups_outlined,
          title: 'Class mode',
          body:
              'Join with class code; teacher progress is a server-backed phase three feature.',
          value: 'Shell',
          route: '/class-mode',
        ),
        const SizedBox(height: 10),
        _QuestCard(
          icon: Icons.smart_toy_outlined,
          title: 'AI tutor',
          body:
              'Mock feedback explains mistakes and suggests example sentences.',
          value: 'Mock',
          route: '/ai-tutor',
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
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
    return QuestCard(
      onTap: route == null ? null : () => context.push(route!),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.coral.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.secondary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PillLabel(label: value, color: AppTheme.coral),
        ],
      ),
    );
  }
}
