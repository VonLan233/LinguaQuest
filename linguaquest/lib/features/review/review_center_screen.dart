import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';

class ReviewCenterScreen extends ConsumerWidget {
  const ReviewCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final due = state.dueWords;
    final weak = state.weakWords;
    final lessonMistakes = state.lastResult?.mistakes ?? const [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
      children: [
        GradientHeroCard(
          title: due.isEmpty ? 'Review queue clear' : '${due.length} cards due',
          subtitle:
              'Spaced repetition brings weak cards back before you forget them.',
          icon: Icons.replay_rounded,
          badge: 'Mistake book · Weak words · Due today',
          action: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.deepTeal,
            ),
            onPressed: due.isEmpty
                ? () => context.go('/custom-words/new')
                : null,
            icon: const Icon(Icons.add),
            label: Text(due.isEmpty ? 'Add cards' : 'Queue ready below'),
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(
          title: 'Review center',
          subtitle:
              'Due words, mistake book, and weak cards stay in one queue.',
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: MetricTile(
                label: 'Due today',
                value: '${due.length}',
                icon: Icons.today_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Mistakes',
                value: '${weak.length}',
                icon: Icons.warning_amber_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: MetricTile(
                label: 'Words',
                value: '${state.customWords.length}',
                icon: Icons.style_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          'Due today',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (due.isEmpty)
          EmptyState(
            icon: Icons.check_circle_outline,
            title: 'Review queue is clear',
            message:
                'Add custom words or mark mistakes to create spaced review cards.',
            action: OutlinedButton.icon(
              onPressed: () => context.go('/custom-words/new'),
              icon: const Icon(Icons.add),
              label: const Text('Add custom word'),
            ),
          )
        else
          for (final word in due) _ReviewTile(word: word),
        const SizedBox(height: 22),
        Text(
          'Mistake book',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        if (lessonMistakes.isEmpty && weak.isEmpty)
          const Text('No weak words or lesson mistakes yet.')
        else ...[
          for (final mistake in lessonMistakes.take(5))
            QuestCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ImageCueBadge(cue: mistake.word.imageCue, size: 52),
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
                  PillLabel(
                    label: 'Lesson',
                    icon: Icons.school_outlined,
                    color: AppTheme.coral,
                  ),
                ],
              ),
            ),
          if (lessonMistakes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                onPressed: () => context.go('/mistake-book'),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Open mistake book'),
              ),
            ),
          for (final word in weak.take(5))
            QuestCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              onTap: () => context.go('/custom-words/${word.id}'),
              child: Row(
                children: [
                  ImageCueBadge(
                    cue: word.word.characters.first.toUpperCase(),
                    size: 52,
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
                        Text('${word.wrongCount} wrong · ${word.meaning}'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.word});

  final CustomWord word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageCueBadge(
                cue: word.word.characters.first.toUpperCase(),
                size: 54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(word.word),
                  subtitle: Text(
                    '${word.meaning} · ${formatRelativeDue(word.nextReviewAt, DateTime.now())}',
                  ),
                ),
              ),
              Chip(label: Text('${word.masteryLevel}/5')),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .reviewWord(word.id, false),
                  icon: const Icon(Icons.close),
                  label: const Text('Missed'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => ref
                      .read(appControllerProvider.notifier)
                      .reviewWord(word.id, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Remembered'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
