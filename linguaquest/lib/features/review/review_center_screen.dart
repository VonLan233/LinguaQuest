import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';

class ReviewCenterScreen extends ConsumerWidget {
  const ReviewCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final due = state.dueWords;
    final weak = state.weakWords;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
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
        if (weak.isEmpty)
          const Text('No weak words yet.')
        else
          for (final word in weak.take(5))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.auto_fix_high_outlined),
              title: Text(word.word),
              subtitle: Text('${word.wrongCount} wrong · ${word.meaning}'),
              onTap: () => context.go('/custom-words/${word.id}'),
            ),
      ],
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.word});

  final CustomWord word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
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
