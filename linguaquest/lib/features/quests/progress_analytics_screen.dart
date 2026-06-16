import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class ProgressAnalyticsScreen extends ConsumerWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          ],
        ),
      ),
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
              icon: Icons.style_outlined,
              color: AppTheme.cyan,
            ),
          ),
          const _ProgressSignalDivider(),
          Expanded(
            child: _ProgressSignal(
              label: l10n.homeMastered,
              value: '$masteredCount',
              icon: Icons.verified_outlined,
              color: AppTheme.success,
            ),
          ),
          const _ProgressSignalDivider(),
          Expanded(
            child: _ProgressSignal(
              label: l10n.analyticsTrainingXp,
              value: '$trainingXp',
              icon: Icons.sports_esports_outlined,
              color: AppTheme.mango,
            ),
          ),
          const _ProgressSignalDivider(),
          Expanded(
            child: _ProgressSignal(
              label: l10n.analyticsAccuracy,
              value: '$accuracy%',
              icon: Icons.insights_outlined,
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
