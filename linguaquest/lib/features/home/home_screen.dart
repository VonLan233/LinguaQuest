import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final dailyProgress = user == null
        ? 0.0
        : (state.dueWords.length / user.dailyGoal).clamp(0.0, 1.0);
    final currentLesson = state.lessons.isEmpty ? null : state.lessons.first;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Hi, ${user?.name ?? 'Learner'}',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          '${user?.targetExam ?? 'Daily English'} · ${user?.level ?? 'Elementary'}',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'XP',
                value: '${user?.xp ?? 0}',
                icon: Icons.bolt,
                color: AppTheme.coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Streak',
                value: '${user?.streak ?? 0} days',
                icon: Icons.local_fire_department,
                color: AppTheme.coral,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Due',
                value: '${state.dueWords.length}',
                icon: Icons.replay,
                color: AppTheme.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Today’s quest',
                subtitle: 'Learn one lesson and clear due review cards.',
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: dailyProgress),
              const SizedBox(height: 10),
              Text(
                '${state.dueWords.length}/${user?.dailyGoal ?? 10} review words ready',
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: currentLesson == null
                    ? null
                    : () => context.go('/lesson/${currentLesson.id}'),
                icon: const Icon(Icons.play_arrow),
                label: Text(
                  currentLesson == null
                      ? 'No lesson available'
                      : 'Continue ${currentLesson.title}',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionHeader(
          title: 'Weak words',
          subtitle: state.weakWords.isEmpty
              ? 'No weak custom words yet.'
              : 'Review these before they pile up.',
          trailing: TextButton(
            onPressed: () => context.go('/review'),
            child: const Text('Review'),
          ),
        ),
        const SizedBox(height: 12),
        if (state.weakWords.isEmpty)
          const _SoftPanel(
            icon: Icons.check_circle_outline,
            text: 'Add custom words or answer review cards to build this list.',
          )
        else
          ...state.weakWords
              .take(3)
              .map(
                (word) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Text(word.word.characters.first.toUpperCase()),
                  ),
                  title: Text(word.word),
                  subtitle: Text(
                    '${word.meaning} · mastery ${word.masteryLevel}/5',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/custom-words/${word.id}'),
                ),
              ),
      ],
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
