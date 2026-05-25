import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              child: Text(
                (user?.name ?? 'L').characters.first.toUpperCase(),
                style: const TextStyle(fontSize: 28),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? 'Learner',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(user?.email ?? 'No email'),
                ],
              ),
            ),
          ],
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
        ),
        const _ProfileAction(
          icon: Icons.notifications_outlined,
          title: 'Daily reminder',
          subtitle: '20:00, local notification placeholder',
        ),
        const _ProfileAction(
          icon: Icons.dark_mode_outlined,
          title: 'Dark mode',
          subtitle: 'Available through system theme',
        ),
        const _ProfileAction(
          icon: Icons.help_outline,
          title: 'Help / Support',
          subtitle: 'FAQ and support shell',
        ),
        const _ProfileAction(
          icon: Icons.info_outline,
          title: 'About',
          subtitle: 'LinguaQuest product vision and version 1.0.0',
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
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
