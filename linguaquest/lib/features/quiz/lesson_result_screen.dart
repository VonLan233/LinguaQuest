import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';
import '../../l10n/generated/app_localizations.dart';

enum LessonResultSource { lesson, timed, training }

class LessonResultViewArgs {
  const LessonResultViewArgs({
    required this.result,
    this.source = LessonResultSource.lesson,
  });

  final LessonResult result;
  final LessonResultSource source;
}

class LessonResultScreen extends ConsumerWidget {
  const LessonResultScreen({
    this.result,
    this.source = LessonResultSource.lesson,
    this.expectedLessonId,
    super.key,
  });

  final LessonResult? result;
  final LessonResultSource source;
  final String? expectedLessonId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final lastResult = state.lastResult;
    final resolved =
        result ??
        ((expectedLessonId == null || lastResult?.lessonId == expectedLessonId)
            ? lastResult
            : null);
    if (resolved == null) {
      return Scaffold(body: Center(child: Text(l10n.quizNoResult)));
    }

    final accuracy = (resolved.accuracy * 100).round();
    final currentXp = state.user?.xp;
    final isTimed = source == LessonResultSource.timed;
    final isTraining = source == LessonResultSource.training;
    return Scaffold(
      appBar: AppBar(
        leading: FallbackBackButton(
          fallbackLocation: isTimed || isTraining ? '/training' : '/learn',
        ),
        title: Text(
          isTimed || isTraining
              ? l10n.quizTimedResultTitle
              : l10n.quizResultTitle,
        ),
      ),
      bottomNavigationBar: _ResultActions(
        source: source,
        hasMistakes: resolved.mistakes.isNotEmpty,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 150),
          children: [
            SectionHeader(
              title: isTimed || isTraining
                  ? (accuracy >= 80
                        ? l10n.quizChallengeSuccess
                        : l10n.quizChallengeDone)
                  : (accuracy >= 80 ? l10n.quizGreatJob : l10n.quizLessonDone),
              subtitle: isTimed || isTraining
                  ? '${resolved.correctAnswers}/${resolved.totalQuestions} · +${resolved.xpEarned} ${l10n.commonXP} · ${l10n.quizMistakeTimed}'
                  : '${resolved.correctAnswers}/${resolved.totalQuestions} · +${resolved.xpEarned} ${l10n.commonXP} · ${l10n.quizMistakeReview}',
            ),
            const SizedBox(height: 12),
            PillLabel(
              label: resolved.lessonTitle,
              icon: isTimed
                  ? Icons.timer_outlined
                  : isTraining
                  ? Icons.sports_esports_outlined
                  : Icons.workspace_premium_outlined,
              color: isTimed || isTraining ? AppTheme.coral : AppTheme.cyan,
            ),
            const SizedBox(height: 12),
            _ResultScoreSummary(
              result: resolved,
              accuracy: accuracy,
              currentXp: currentXp,
            ),
            const SizedBox(height: 16),
            _XpImpactNotice(
              xpEarned: resolved.xpEarned,
              currentXp: currentXp,
              isTimed: isTimed || isTraining,
            ),
            const SizedBox(height: 20),
            Text(
              l10n.quizMistakes,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (resolved.mistakes.isEmpty)
              const _PerfectResultRow()
            else
              for (final mistake in resolved.mistakes)
                _MistakeResultRow(mistake: mistake),
          ],
        ),
      ),
    );
  }
}

class _ResultActions extends StatelessWidget {
  const _ResultActions({required this.source, required this.hasMistakes});

  final LessonResultSource source;
  final bool hasMistakes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isTraining = source != LessonResultSource.lesson;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isTraining && hasMistakes) ...[
              FilledButton.icon(
                onPressed: () =>
                    context.go('/training/spelling?source=mistakes'),
                icon: const Icon(Icons.replay_circle_filled_outlined),
                label: Text(l10n.quizRetryMistakes),
              ),
              const SizedBox(height: 8),
            ],
            FilledButton.icon(
              onPressed: () => context.go('/review'),
              icon: const Icon(Icons.replay),
              label: Text(l10n.quizGoReviewCenter),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.go(isTraining ? '/training' : '/learn'),
              icon: Icon(
                isTraining
                    ? Icons.sports_esports_outlined
                    : Icons.route_outlined,
              ),
              label: Text(
                isTraining ? l10n.quizBackTraining : l10n.quizBackLearningPath,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _XpImpactNotice extends StatelessWidget {
  const _XpImpactNotice({
    required this.xpEarned,
    required this.currentXp,
    required this.isTimed,
  });

  final int xpEarned;
  final int? currentXp;
  final bool isTimed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final balanceText = currentXp == null
        ? l10n.quizXpBalanceUpdated
        : l10n.quizCurrentXp(currentXp!);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.mango.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.mango.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconCueBadge(icon: Icons.bolt, color: AppTheme.mango, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.quizXpCredited(xpEarned),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.quizXpImpactBody(balanceText),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PillLabel(
                      label: isTimed
                          ? l10n.quizTimedReward
                          : l10n.quizLessonReward,
                      icon: isTimed
                          ? Icons.timer_outlined
                          : Icons.workspace_premium_outlined,
                      color: isTimed ? AppTheme.coral : AppTheme.cyan,
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/discover'),
                      icon: const Icon(Icons.help_outline_rounded),
                      label: Text(l10n.quizViewXpUses),
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
}

class _PerfectResultRow extends StatelessWidget {
  const _PerfectResultRow();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const ImageCueBadge(cue: '🏆', size: 58),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.quizAllCorrect, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  l10n.quizMistakeReview,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MistakeResultRow extends StatelessWidget {
  const _MistakeResultRow({required this.mistake});

  final QuizQuestion mistake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ImageCueBadge(cue: mistake.word.imageCue, size: 54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mistake.word.word, style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  mistake.explanation,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultScoreSummary extends StatelessWidget {
  const _ResultScoreSummary({
    required this.result,
    required this.accuracy,
    required this.currentXp,
  });

  final LessonResult result;
  final int accuracy;
  final int? currentXp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$accuracy%',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  l10n.quizAccuracy,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: result.accuracy,
              minHeight: 12,
              backgroundColor: AppTheme.progressTrack(context),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PillLabel(
                label: l10n.quizXpEarned(result.xpEarned),
                icon: Icons.bolt,
                color: AppTheme.mango,
              ),
              if (currentXp != null)
                PillLabel(
                  label: l10n.quizTotalXp(currentXp!),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppTheme.cyan,
                ),
              PillLabel(
                label: l10n.quizMistakeCount(result.mistakes.length),
                icon: Icons.replay_rounded,
                color: AppTheme.coral,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
