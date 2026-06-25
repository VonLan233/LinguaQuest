import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import 'package:linguaquest/core/theme/app_icons.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/analytics.dart';
import '../../data/models/recommendation.dart';
import '../../l10n/generated/app_localizations.dart';

class ProgressAnalyticsScreen extends ConsumerStatefulWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  ConsumerState<ProgressAnalyticsScreen> createState() =>
      _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState
    extends ConsumerState<ProgressAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).refreshAnalytics();
      ref.read(appControllerProvider.notifier).refreshRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final reviewWords = state.reviewWords;
    final mastered = reviewWords.where((word) => word.masteryLevel >= 4).length;
    final attempts = reviewWords.fold<int>(
      0,
      (sum, word) => sum + word.correctCount + word.wrongCount,
    );
    final correct = reviewWords.fold<int>(
      0,
      (sum, word) => sum + word.correctCount,
    );
    final accuracy = attempts == 0 ? 0 : (correct / attempts * 100).round();
    final l10n = AppLocalizations.of(context);
    final analytics = state.analyticsSnapshot;
    final recommendations = state.recommendations;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: Text(l10n.questAnalytics),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: l10n.analyticsDataTitle,
              subtitle: l10n.analyticsDataSubtitle,
            ),
            const SizedBox(height: 16),
            _ProgressSignals(
              cardCount: reviewWords.length,
              masteredCount: mastered,
              accuracy: accuracy,
              trainingXp: state.todayTrainingXp,
            ),
            const SizedBox(height: 20),
            Text(
              '复习负荷',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            AppProgressBar(
              value: reviewWords.isEmpty
                  ? 0
                  : (state.dueWords.length / reviewWords.length).clamp(
                      0.0,
                      1.0,
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.analyticsAssetsDue(
                state.dueWords.length,
                reviewWords.length,
              ),
            ),
            if (analytics != null) ...[
              const SizedBox(height: 24),
              _ExtendedAnalyticsSection(analytics: analytics),
            ] else ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
            ],
            const SizedBox(height: 24),
            _RecommendedPracticeSection(recommendations: recommendations),
          ],
        ),
      ),
    );
  }
}

class _ExtendedAnalyticsSection extends StatelessWidget {
  const _ExtendedAnalyticsSection({required this.analytics});

  final LearningAnalytics analytics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detailed Stats',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        // Stat grid
        AppCard(
          child: Column(
            children: [
              _StatRow(label: 'Streak', value: '${analytics.streakDays} days', icon: AppIcons.localFireDepartment, color: AppTheme.mango),
              const Divider(height: 20),
              _StatRow(label: 'Total Study Days', value: '${analytics.totalStudyDays} days', icon: AppIcons.calendarMonth, color: AppTheme.cyan),
              const Divider(height: 20),
              _StatRow(label: 'Learned Words', value: '${analytics.learnedWords}', icon: AppIcons.menuBook, color: AppTheme.success),
              const Divider(height: 20),
              _StatRow(label: 'Today Study Time', value: '${analytics.todayMinutes} min', icon: AppIcons.timer, color: AppTheme.coral),
              const Divider(height: 20),
              _StatRow(label: 'Total Study Time', value: '${analytics.totalMinutes} min', icon: AppIcons.schedule, color: AppTheme.mango),
              const Divider(height: 20),
              _StatRow(label: 'Wordbook Progress', value: '${analytics.wordbookProgressPct}%', icon: AppIcons.insights, color: AppTokens.primarySoftText),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 7-day XP chart
        Text(
          '7-Day XP Trend',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: _SevenDayXpChart(xpData: analytics.sevenDayXp),
        ),
        const SizedBox(height: 16),
        // Weakest exercise type
        AppCard(
          child: Row(
            children: [
              Icon(AppIcons.warningAmber, color: AppTheme.coral, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Focus Area',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Needs work: ${analytics.weakestExerciseType}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (analytics.achievementCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.mango.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '🏆 ${analytics.achievementCount}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(label, style: theme.textTheme.bodyMedium),
        ),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SevenDayXpChart extends StatelessWidget {
  const _SevenDayXpChart({required this.xpData});

  final List<int> xpData;

  @override
  Widget build(BuildContext context) {
    if (xpData.isEmpty) return const SizedBox.shrink();
    final maxXp = xpData.reduce((a, b) => a > b ? a : b);
    final maxBarHeight = 60.0;
    final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(xpData.length.clamp(0, 7), (i) {
        final xp = xpData[i];
        final fraction = maxXp == 0 ? 0.0 : xp / maxXp;
        final barH = (fraction * maxBarHeight).clamp(4.0, maxBarHeight);
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              '$xp',
              style: theme.textTheme.labelSmall?.copyWith(fontSize: 9),
            ),
            const SizedBox(height: 2),
            Container(
              width: 26,
              height: barH,
              decoration: BoxDecoration(
                color: AppTheme.mango.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              i < dayLabels.length ? dayLabels[i] : '${i + 1}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _ProgressSignals extends StatelessWidget {
  const _ProgressSignals({
    required this.cardCount,
    required this.masteredCount,
    required this.accuracy,
    required this.trainingXp,
  });

  final int cardCount;
  final int masteredCount;
  final int accuracy;
  final int trainingXp;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: _ProgressSignal(
              label: l10n.analyticsCards,
              value: '$cardCount',
              icon: AppIcons.style,
              color: AppTheme.cyan,
            ),
          ),
          const _ProgressSignalDivider(),
          Expanded(
            child: _ProgressSignal(
              label: l10n.homeMastered,
              value: '$masteredCount',
              icon: AppIcons.verified,
              color: AppTheme.success,
            ),
          ),
          const _ProgressSignalDivider(),
          Expanded(
            child: _ProgressSignal(
              label: l10n.analyticsTrainingXp,
              value: '$trainingXp',
              icon: AppIcons.sportsEsports,
              color: AppTheme.mango,
            ),
          ),
          const _ProgressSignalDivider(),
          Expanded(
            child: _ProgressSignal(
              label: l10n.analyticsAccuracy,
              value: '$accuracy%',
              icon: AppIcons.insights,
              color: AppTheme.coral,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSignal extends StatelessWidget {
  const _ProgressSignal({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressSignalDivider extends StatelessWidget {
  const _ProgressSignalDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: VerticalDivider(
        width: 16,
        thickness: 1,
        color: Theme.of(context).colorScheme.outlineVariant,
      ),
    );
  }
}

// ── Recommended Practice Section ─────────────────────────────────────────────

class _RecommendedPracticeSection extends StatelessWidget {
  const _RecommendedPracticeSection({required this.recommendations});

  final List<Recommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended Practice',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
          AppCard(
            child: Row(
              children: [
                Icon(
                  AppIcons.verified,
                  color: AppTheme.success,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Great job! No weak areas detected.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )
        else
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendationCard(recommendation: rec),
            ),
          ),
      ],
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.recommendation});

  final Recommendation recommendation;

  String get _exerciseTypeLabel {
    switch (recommendation.exerciseType) {
      case 'listeningWordChoice':
      case 'listeningMeaningChoice':
        return 'Listening';
      case 'sentenceCloze':
        return 'Context';
      case 'meaningChoice':
      case 'chineseChoice':
        return 'Meaning';
      case 'confusableChoice':
        return 'Confusables';
      case 'collocationChoice':
        return 'Collocation';
      default:
        return recommendation.exerciseType;
    }
  }

  Color _priorityColor(BuildContext context) {
    switch (recommendation.priority) {
      case 1:
        return AppTheme.coral;
      case 2:
        return AppTheme.mango;
      default:
        return AppTheme.cyan;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppPill(
                label: _exerciseTypeLabel,
                variant: PillVariant.primary,
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _priorityColor(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                ),
                child: Text(
                  'P${recommendation.priority}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _priorityColor(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '~${recommendation.estimatedMinutes} min',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            recommendation.reason,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '${recommendation.targetWordIds.length} word${recommendation.targetWordIds.length == 1 ? '' : 's'}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          AppSecondaryButton(
            label: 'Start Practice',
            onPressed: () => context.push('/study/review'),
          ),
        ],
      ),
    );
  }
}
