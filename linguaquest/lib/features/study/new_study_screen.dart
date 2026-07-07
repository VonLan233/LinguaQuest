import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

class NewStudyScreen extends ConsumerWidget {
  const NewStudyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final lesson = state.currentLesson;
    final dailyGoal = state.dailyNewTarget;
    final words = lesson?.words.take(dailyGoal).toList() ?? const <Word>[];
    final canStart =
        lesson != null && words.isNotEmpty && !state.isStudyPlanPaused;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.studyNewScreenTitle),
        actions: [
          QuestIconButton(
            tooltip: l10n.studyWordbookPath,
            onPressed: () => context.push('/learn'),
            icon: AppIcons.route,
          ),
          const SizedBox(width: 12),
        ],
      ),
      bottomNavigationBar: canStart
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: FilledButton.icon(
                  onPressed: () => context.push('/lesson/${lesson.id}'),
                  icon: const Icon(AppIcons.playArrow),
                  label: Text(l10n.studyEnterCards),
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 10, 20, canStart ? 100 : 28),
          children: [
            _StudyHeader(
              count: words.length,
              lesson: lesson,
              dailyGoal: dailyGoal,
              isPaused: state.isStudyPlanPaused,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.studyNewPackTitle,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.studyNewPackDesc,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            _FlowSteps(),
            const SizedBox(height: 20),
            if (lesson == null || words.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.studyNoNewWords,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.isStudyPlanPaused
                          ? l10n.studyNewPausedHint
                          : l10n.studyNewEmptyHint,
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => context.push('/learn'),
                      icon: const Icon(AppIcons.route),
                      label: Text(l10n.studyOpenWordbookPath),
                    ),
                  ],
                ),
              )
            else ...[
              for (final word in words) _WordPreviewTile(word: word),
            ],
          ],
        ),
      ),
    );
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.count,
    required this.lesson,
    required this.dailyGoal,
    required this.isPaused,
  });

  final int count;
  final Lesson? lesson;
  final int dailyGoal;
  final bool isPaused;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final section = lesson?.section ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.studyTodayLearnCount(count),
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          lesson == null
              ? l10n.studyNewNoLessonHint
              : isPaused
              ? l10n.studyNewPausedResume(section)
              : '$section · Goal $dailyGoal words · No timed test',
          style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: l10n.studyRecallKnown,
              icon: AppIcons.sentimentSatisfied,
            ),
            PillLabel(
              label: l10n.studyRecallFuzzy,
              icon: AppIcons.visibility,
              color: AppTheme.mango,
            ),
            PillLabel(
              label: l10n.studyRecallUnknown,
              icon: AppIcons.help,
              color: AppTheme.coral,
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowSteps extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      ('1', l10n.studyStepSelfAssess, l10n.studyStepSelfAssessDesc),
      ('2', l10n.studyStepCards, l10n.studyStepCardsDesc),
      ('3', l10n.studyStepContext, l10n.studyStepContextDesc),
    ];
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < steps.length; i++) ...[
            Expanded(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: i == 1
                        ? colorScheme.secondaryContainer
                        : colorScheme.primary,
                    foregroundColor: i == 1
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onPrimary,
                    child: Text(steps[i].$1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    steps[i].$2,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    steps[i].$3,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (i != steps.length - 1)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 17),
                  child: Divider(
                    color: colorScheme.outlineVariant,
                    thickness: 2,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _WordPreviewTile extends StatelessWidget {
  const _WordPreviewTile({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            children: [
              ImageCueBadge(cue: word.imageCue, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.word, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      word.primaryDefinitionFor(
                        Localizations.localeOf(context).languageCode,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 82),
                child: Text(
                  word.phonetic,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
