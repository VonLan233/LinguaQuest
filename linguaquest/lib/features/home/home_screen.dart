import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final dueCount = state.dueWords.length;
    final dailyGoal = state.learningPlan?.dailyWords ?? user?.dailyGoal ?? 10;
    final todayLessonWords = state.lessons
        .where((lesson) => state.todayCompletedLessonIds.contains(lesson.id))
        .fold(0, (total, lesson) => total + lesson.words.length);
    final todayWork = todayLessonWords + state.todayReviewWordIds.length;
    final dailyProgress = dailyGoal <= 0
        ? 0.0
        : (todayWork / dailyGoal).clamp(0.0, 1.0);
    final currentLesson = state.currentLesson;
    final pathComplete =
        state.lessons.isNotEmpty &&
        state.lessons.every((lesson) => lesson.status == 'completed');
    final wordOfDay = (currentLesson?.words.isNotEmpty ?? false)
        ? currentLesson!.words.first
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${user?.name ?? 'Learner'} 👋',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user?.targetExam ?? 'Daily English'} · ${user?.level ?? 'Elementary'}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            PillLabel(
              label: '${user?.streak ?? 0} day',
              icon: Icons.local_fire_department,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 18),
        GradientHeroCard(
          title: currentLesson == null
              ? 'Build your first learning path'
              : pathComplete
              ? 'Learning path complete'
              : 'Ready for ${currentLesson.title}?',
          subtitle: state.learningPlan == null
              ? 'Complete one bite-sized lesson, then clear review cards before they turn weak.'
              : '${state.learningPlan!.dailyWords} words/day until your ${state.learningPlan!.target} plan ends.',
          icon: Icons.rocket_launch_outlined,
          badge: 'Today’s learning pack',
          action: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepTeal,
            ),
            onPressed: currentLesson == null || pathComplete
                ? null
                : () => context.push('/lesson/${currentLesson.id}'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              currentLesson == null || pathComplete
                  ? 'No lesson available'
                  : 'Continue lesson',
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'XP',
                value: '${user?.xp ?? 0}',
                icon: Icons.bolt,
                color: AppTheme.mango,
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
                color: AppTheme.cyan,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        QuestCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Today’s quest',
                subtitle: 'Learn one lesson and clear due review cards.',
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: dailyProgress,
                  minHeight: 12,
                  backgroundColor: AppTheme.progressTrack(context),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '$todayWork/$dailyGoal words today · $dueCount review cards due',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/review'),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Review'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/wordbook'),
                      icon: const Icon(Icons.style_outlined),
                      label: const Text('Wordbook'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        QuestCard(
          padding: const EdgeInsets.all(16),
          onTap: () => context.push('/wordbook'),
          color: AppTheme.accentSurface(context),
          child: Row(
            children: [
              ImageCueBadge(cue: wordOfDay?.imageCue ?? '🌟', size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Word of the day',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      wordOfDay == null
                          ? 'Open word cards'
                          : '${wordOfDay.word} · ${wordOfDay.meaning}',
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
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
                (word) => QuestCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  onTap: () => context.push('/custom-words/${word.id}'),
                  child: Row(
                    children: [
                      ImageCueBadge(
                        cue: word.word.characters.first.toUpperCase(),
                        size: 50,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.word,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${word.meaning} · mastery ${word.masteryLevel}/5',
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
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
