import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

const _pathRailWidth = 74.0;
const _pathNodeHorizontalPadding = 8.0;
const _pathConnectorWidth = 6.0;
const _pathConnectorLeft =
    _pathNodeHorizontalPadding + (_pathRailWidth - _pathConnectorWidth) / 2;

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final lessons = state.formalLessons;
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.learningPathTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
          children: [
            if (state.isStudyPlanPaused) ...[
              _PausedBanner(l10n: l10n),
              const SizedBox(height: 16),
            ],
            for (var index = 0; index < lessons.length; index++) ...[
              _PathNode(lesson: lessons[index], index: index, l10n: l10n),
              if (index != lessons.length - 1) const _PathConnector(),
            ],
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push('/wordbook'),
              icon: const Icon(Icons.style_outlined),
              label: Text(l10n.learningPathOpenWordbook),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.push('/settings/study-plan'),
              icon: const Icon(Icons.tune_outlined),
              label: Text(l10n.learningPathAdjustPlan),
            ),
          ],
        ),
      ),
    );
  }
}

class _PausedBanner extends StatelessWidget {
  const _PausedBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.pause_circle_outlined, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(l10n.reviewCenterPlanPaused)),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({required this.lesson, required this.index, required this.l10n});

  final Lesson lesson;
  final int index;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final locked = lesson.status == 'locked';
    final current = lesson.status == 'current';
    final completed = lesson.status == 'completed';
    final theme = Theme.of(context);
    final Color color;
    if (locked) {
      color = theme.colorScheme.onSurfaceVariant;
    } else if (current) {
      color = AppTheme.mango;
    } else if (completed) {
      color = AppTheme.success;
    } else {
      color = AppTheme.cyan;
    }
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: locked ? null : () => _showPreview(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _pathRailWidth,
                child: Center(
                  child: Container(
                    width: current ? _pathRailWidth : 62,
                    height: current ? _pathRailWidth : 62,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.colorScheme.surface,
                        width: 4,
                      ),
                    ),
                    child: Icon(
                      locked
                          ? Icons.lock_rounded
                          : current
                          ? Icons.play_arrow_rounded
                          : completed
                          ? Icons.check_rounded
                          : Icons.star_rounded,
                      color: current ? AppTheme.ink : Colors.white,
                      size: current ? 38 : 30,
                    ),
                  ),
                ),
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
                          label: _statusLabel(lesson.status, l10n),
                          icon: locked ? Icons.lock_outline : Icons.bolt,
                          color: color,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(lesson.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 5),
                    Text(
                      lesson.description,
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PillLabel(
                          label: '${lesson.xpReward} ${l10n.commonXP}',
                          icon: Icons.bolt,
                          color: AppTheme.mango,
                        ),
                        PillLabel(
                          label: '${lesson.estimatedMinutes} min',
                          icon: Icons.timer_outlined,
                        ),
                        PillLabel(
                          label: '${lesson.words.length} ${l10n.commonWords}',
                          icon: Icons.style_outlined,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPreview(BuildContext context) {
    final parentContext = context;
    final l10n = AppLocalizations.of(context);
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
                    label: Text(l10n.commonContinue),
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

String _statusLabel(String status, AppLocalizations l10n) {
  switch (status) {
    case 'completed':
      return l10n.learningPathLessonCompleted;
    case 'current':
      return l10n.learningPathLessonCurrent;
    case 'locked':
      return l10n.learningPathLessonLocked;
    default:
      return status;
  }
}

class _PathConnector extends StatelessWidget {
  const _PathConnector();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: _pathConnectorLeft),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: _pathConnectorWidth,
          height: 28,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.teal.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}
