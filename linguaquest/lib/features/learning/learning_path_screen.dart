import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Learning Path')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
          children: [
            SectionHeader(
              title: 'Learning Path',
              subtitle:
                  'Follow the path. No planning, just one small win at a time.',
              trailing: IconButton(
                tooltip: 'Wordbook',
                onPressed: () => context.push('/wordbook'),
                icon: const Icon(Icons.menu_book_outlined),
              ),
            ),
            const SizedBox(height: 18),
            const GradientHeroCard(
              title: 'Campus Life Unit',
              subtitle:
                  'Duolingo-style short nodes with Baicizhan-style visual words inside every lesson.',
              icon: Icons.route_rounded,
              badge: 'Section 1 · 33% unlocked',
            ),
            const SizedBox(height: 22),
            for (var index = 0; index < state.lessons.length; index++) ...[
              _PathNode(lesson: state.lessons[index], index: index),
              if (index != state.lessons.length - 1) const _PathConnector(),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/wordbook'),
              icon: const Icon(Icons.style_outlined),
              label: const Text('Open wordbook and custom words'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({required this.lesson, required this.index});

  final Lesson lesson;
  final int index;

  @override
  Widget build(BuildContext context) {
    final locked = lesson.status == 'locked';
    final current = lesson.status == 'current';
    final completed = lesson.status == 'completed';
    final Color color;
    if (locked) {
      color = Colors.blueGrey;
    } else if (current) {
      color = AppTheme.coral;
    } else if (completed) {
      color = Colors.green;
    } else {
      color = AppTheme.teal;
    }
    final theme = Theme.of(context);
    final lockedCardColor = theme.colorScheme.surfaceContainerLow;
    final cardColor = locked ? lockedCardColor : theme.colorScheme.surface;

    return QuestCard(
      onTap: locked ? null : () => _showPreview(context),
      padding: const EdgeInsets.all(16),
      color: cardColor,
      borderColor: current ? AppTheme.coral.withValues(alpha: 0.55) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: current ? 74 : 62,
                height: current ? 74 : 62,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: current
                      ? [
                          BoxShadow(
                            color: AppTheme.coral.withValues(alpha: 0.35),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  locked
                      ? Icons.lock_rounded
                      : current
                      ? Icons.play_arrow_rounded
                      : Icons.check_rounded,
                  color: Colors.white,
                  size: current ? 38 : 30,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        lesson.section,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    PillLabel(
                      label: _statusLabel(lesson.status),
                      icon: locked ? Icons.lock_outline : Icons.bolt,
                      color: color,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(lesson.title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 5),
                Text(lesson.description),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    PillLabel(
                      label: '${lesson.xpReward} XP',
                      icon: Icons.bolt,
                      color: AppTheme.mango,
                    ),
                    PillLabel(
                      label: '${lesson.estimatedMinutes} min',
                      icon: Icons.timer_outlined,
                    ),
                    PillLabel(
                      label: '${lesson.words.length} words',
                      icon: Icons.style_outlined,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPreview(BuildContext context) {
    final parentContext = context;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageCueBadge(
              cue: lesson.words.isEmpty ? '?' : lesson.words.first.imageCue,
              size: 78,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: Theme.of(sheetContext).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(lesson.description),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      parentContext.push('/lesson/${lesson.id}');
                    },
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Start lesson'),
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

String _statusLabel(String status) {
  switch (status) {
    case 'completed':
      return 'Completed';
    case 'current':
      return 'Current';
    case 'locked':
      return 'Locked';
    default:
      return status;
  }
}

class _PathConnector extends StatelessWidget {
  const _PathConnector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 6,
        height: 28,
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.teal.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}
