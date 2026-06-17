import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

const _pathRailWidth = 74.0;
const _pathConnectorWidth = 6.0;
// Align the connector under the rail circle: the node content sits inside the
// card's s12 horizontal padding, so add it to the rail-centering offset.
const _pathConnectorLeft =
    AppTokens.s12 + (_pathRailWidth - _pathConnectorWidth) / 2;

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
            AppSecondaryButton(
              label: l10n.learningPathOpenWordbook,
              onPressed: () => context.push('/wordbook'),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => context.push('/settings/study-plan'),
              icon: const Icon(AppIcons.tune),
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
    return AppCard(
      child: Row(
        children: [
          Icon(
            AppIcons.pauseCircle,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: AppTokens.s12),
          Expanded(child: Text(l10n.reviewCenterPlanPaused)),
        ],
      ),
    );
  }
}

class _PathNode extends StatelessWidget {
  const _PathNode({
    required this.lesson,
    required this.index,
    required this.l10n,
  });

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
    return AppCard(
      padding: EdgeInsets.zero,
      onTap: locked ? null : () => _showPreview(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.s12,
          vertical: AppTokens.s16,
        ),
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
                        ? AppIcons.lock
                        : current
                        ? AppIcons.playArrow
                        : completed
                        ? AppIcons.check
                        : AppIcons.star,
                    color: current ? AppTheme.ink : theme.colorScheme.onPrimary,
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
                      AppPill(
                        label: _statusLabel(lesson.status, l10n),
                        variant: _statusVariant(lesson.status),
                        icon: locked ? AppIcons.lock : AppIcons.bolt,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    lesson.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s4),
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
                      AppPill(
                        label: '${lesson.xpReward} ${l10n.commonXP}',
                        variant: PillVariant.xp,
                        icon: AppIcons.bolt,
                      ),
                      AppPill(
                        label: '${lesson.estimatedMinutes} min',
                        variant: PillVariant.primary,
                        icon: AppIcons.timer,
                      ),
                      AppPill(
                        label: '${lesson.words.length} ${l10n.commonWords}',
                        variant: PillVariant.primary,
                        icon: AppIcons.style,
                      ),
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
                  AppPrimaryButton(
                    label: l10n.learningPathStartLearning,
                    icon: AppIcons.playArrow,
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      parentContext.push('/lesson/${lesson.id}');
                    },
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

PillVariant _statusVariant(String status) {
  switch (status) {
    case 'completed':
      return PillVariant.success;
    case 'current':
      return PillVariant.primary;
    case 'locked':
      return PillVariant.primary;
    default:
      return PillVariant.primary;
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
            color: AppTokens.hairline,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}
