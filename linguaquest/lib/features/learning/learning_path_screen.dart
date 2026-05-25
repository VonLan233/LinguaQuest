import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SectionHeader(
          title: 'Learning path',
          subtitle: 'Short lessons unlock vocabulary in context.',
          trailing: IconButton(
            tooltip: 'Wordbook',
            onPressed: () => context.go('/wordbook'),
            icon: const Icon(Icons.menu_book_outlined),
          ),
        ),
        const SizedBox(height: 18),
        for (var index = 0; index < state.lessons.length; index++) ...[
          _LessonCard(lesson: state.lessons[index], index: index),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => context.go('/wordbook'),
          icon: const Icon(Icons.style_outlined),
          label: const Text('Open wordbook and custom words'),
        ),
      ],
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.index});

  final Lesson lesson;
  final int index;

  @override
  Widget build(BuildContext context) {
    final locked = lesson.status == 'locked';
    final color = locked
        ? Theme.of(context).colorScheme.outline
        : AppTheme.teal;
    return InkWell(
      onTap: locked ? null : () => context.go('/lesson/${lesson.id}'),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.14),
              foregroundColor: color,
              child: locked
                  ? const Icon(Icons.lock_outline)
                  : Text('${index + 1}'),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.section,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(lesson.description),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text('${lesson.xpReward} XP')),
                      Chip(label: Text('${lesson.estimatedMinutes} min')),
                      Chip(label: Text(lesson.status)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
