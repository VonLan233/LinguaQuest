import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/quest_card.dart';

class MistakeBookScreen extends ConsumerWidget {
  const MistakeBookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final lessonMistakes = state.lastResult?.mistakes ?? const [];
    final weakWords = state.weakWords;

    return Scaffold(
      appBar: AppBar(title: const Text('Mistake book')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            GradientHeroCard(
              title: lessonMistakes.isEmpty
                  ? 'No lesson mistakes yet'
                  : '${lessonMistakes.length} lesson mistakes',
              subtitle:
                  'Wrong quiz answers and weak custom cards stay visible for follow-up review.',
              icon: Icons.auto_fix_high_outlined,
              badge: 'Mistake recovery',
              action: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.deepTeal,
                ),
                onPressed: () => context.go('/learn'),
                icon: const Icon(Icons.route_outlined),
                label: const Text('Practice lesson'),
              ),
            ),
            const SizedBox(height: 20),
            if (lessonMistakes.isEmpty && weakWords.isEmpty)
              EmptyState(
                icon: Icons.check_circle_outline,
                title: 'Mistake book is clear',
                message:
                    'Miss a quiz question or mark custom words as missed to build this list.',
                action: OutlinedButton.icon(
                  onPressed: () => context.go('/learn'),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start a lesson'),
                ),
              )
            else ...[
              Text(
                'Lesson mistakes',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (lessonMistakes.isEmpty)
                const Text('No wrong quiz answers from the latest lesson.')
              else
                for (final mistake in lessonMistakes)
                  QuestCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ImageCueBadge(cue: mistake.word.imageCue, size: 56),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                mistake.word.word,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(mistake.explanation),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(height: 18),
              Text(
                'Weak custom words',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              if (weakWords.isEmpty)
                const Text('No weak custom words yet.')
              else
                for (final word in weakWords)
                  QuestCard(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    onTap: () => context.go('/custom-words/${word.id}'),
                    child: Row(
                      children: [
                        ImageCueBadge(
                          cue: word.word.characters.first.toUpperCase(),
                          size: 56,
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
                                '${word.wrongCount} wrong · ${word.meaning}',
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
