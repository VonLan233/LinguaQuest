import 'package:flutter/material.dart';

import '../../core/widgets/section_header.dart';

class QuestScreen extends StatelessWidget {
  const QuestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: const [
        SectionHeader(
          title: 'Quest hub',
          subtitle:
              'Daily quests and social layers are wired as product-ready shells for phase two.',
        ),
        SizedBox(height: 16),
        _QuestCard(
          icon: Icons.flag_outlined,
          title: 'Daily quest',
          body: 'Complete one lesson and review five due words.',
          value: '20 XP',
        ),
        SizedBox(height: 10),
        _QuestCard(
          icon: Icons.workspace_premium_outlined,
          title: 'Badges',
          body: '7-day streak, 100 words learned, first perfect lesson.',
          value: '3 active',
        ),
        SizedBox(height: 10),
        _QuestCard(
          icon: Icons.leaderboard_outlined,
          title: 'Leaderboard',
          body: 'Weekly XP ranking across friends and future classes.',
          value: 'Mock',
        ),
        SizedBox(height: 10),
        _QuestCard(
          icon: Icons.insights_outlined,
          title: 'Progress analytics',
          body: 'Accuracy, vocabulary growth, and review completion trends.',
          value: 'Preview',
        ),
        SizedBox(height: 10),
        _QuestCard(
          icon: Icons.groups_outlined,
          title: 'Class mode',
          body:
              'Join with class code; teacher progress is a server-backed phase three feature.',
          value: 'Shell',
        ),
        SizedBox(height: 10),
        _QuestCard(
          icon: Icons.smart_toy_outlined,
          title: 'AI tutor',
          body:
              'Mock feedback explains mistakes and suggests example sentences.',
          value: 'Mock',
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
  });

  final IconData icon;
  final String title;
  final String body;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.secondary),
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
          Chip(label: Text(value)),
        ],
      ),
    );
  }
}
