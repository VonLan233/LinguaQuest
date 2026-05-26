import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        GradientHeroCard(
          title: user?.name ?? 'Learner',
          subtitle:
              '${user?.email ?? 'No email'}\n${user?.targetExam ?? 'Daily English'} · ${user?.level ?? 'Elementary'}',
          icon: Icons.person_rounded,
          badge: 'Profile and progress',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Goal',
                value: '${user?.dailyGoal ?? 10}',
                icon: Icons.track_changes,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'XP',
                value: '${user?.xp ?? 0}',
                icon: Icons.bolt,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Streak',
                value: '${user?.streak ?? 0}',
                icon: Icons.local_fire_department,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        const SectionHeader(title: 'Settings and support'),
        const SizedBox(height: 10),
        _ProfileAction(
          icon: Icons.flag_outlined,
          title: 'Learning target',
          subtitle: user?.targetExam ?? 'Daily English',
          route: '/goal-setup',
        ),
        const _ProfileAction(
          icon: Icons.notifications_outlined,
          title: 'Daily reminder',
          subtitle: '20:00, local notification placeholder',
          route: '/settings',
        ),
        const _ProfileAction(
          icon: Icons.dark_mode_outlined,
          title: 'Dark mode',
          subtitle: 'Available through system theme',
          route: '/settings',
        ),
        const _ProfileAction(
          icon: Icons.help_outline,
          title: 'Help / Support',
          subtitle: 'FAQ and support shell',
          route: '/help',
        ),
        const _ProfileAction(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'LinguaQuest product vision and version 1.0.0',
          route: '/about',
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            await ref.read(appControllerProvider.notifier).logout();
            if (context.mounted) context.go('/onboarding');
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
      ],
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(route),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.iconBadgeSurface(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
