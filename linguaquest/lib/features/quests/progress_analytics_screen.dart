import 'package:fl_chart/fl_chart.dart';
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
import '../../data/models/custom_word.dart';
import '../../data/models/recommendation.dart';
import '../../l10n/generated/app_localizations.dart';
import '../reading/reading_labels.dart';
import '../reading/reading_metrics.dart';

class ProgressAnalyticsScreen extends ConsumerStatefulWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  ConsumerState<ProgressAnalyticsScreen> createState() =>
      _ProgressAnalyticsScreenState();
}

class _ProgressAnalyticsScreenState
    extends ConsumerState<ProgressAnalyticsScreen> {
  // Reading metrics computed client-side from saved ReadingResults (P3e).
  ReadingMetrics _readingMetrics = ReadingMetrics.empty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appControllerProvider.notifier).refreshAnalytics();
      ref.read(appControllerProvider.notifier).refreshRecommendations();
      _loadReadingMetrics();
    });
  }

  Future<void> _loadReadingMetrics() async {
    final results = await ref
        .read(appControllerProvider.notifier)
        .readingResultsForScope();
    if (!mounted) return;
    setState(() => _readingMetrics = ReadingMetrics.fromResults(results));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    // §6 (P4d): scope analytics to the current (language, wordbook). reviewWords
    // is built globally from all userWords/customWords, so filter to the active
    // wordbook (keeping personal cards that aren't bound to a wordbook).
    final reviewWords = state.reviewWords
        .where((w) =>
            w.wordBookId == null || w.wordBookId == state.currentWordBookId)
        .toList();
    final scopeLabel = readingLevelLabel(
      state.currentLanguage,
      state.currentWordBookId,
    );
    final mastered = reviewWords.where((w) => w.masteryLevel >= 4).length;
    final attempts = reviewWords.fold<int>(
      0,
      (sum, w) => sum + w.correctCount + w.wrongCount,
    );
    final correct = reviewWords.fold<int>(0, (sum, w) => sum + w.correctCount);
    final accuracy = attempts == 0 ? 0 : (correct / attempts * 100).round();
    final l10n = AppLocalizations.of(context);
    final analytics = state.analyticsSnapshot;
    final recommendations = state.recommendations;
    final sevenDayXp = analytics?.sevenDayXp ?? const <int>[];
    final weekXp = sevenDayXp.fold<int>(0, (a, b) => a + b);
    // D-10: "Today XP" must share the same source (backend sevenDayXp — total
    // XP across all activities) as the XP-trend chart and the "This week XP"
    // pill. Previously it showed local training-only `todayTrainingXp`, which
    // did not match the chart's today value and desynced across restarts/devices.
    final todayXp = sevenDayXp.isNotEmpty ? sevenDayXp.last : 0;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: Text(l10n.questAnalytics),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── 1. Report header ────────────────────────────────────────────
            SectionHeader(
              title: l10n.analyticsReportTitle,
              subtitle: l10n.analyticsReportSubtitle,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: AppPill(
                key: const ValueKey('analytics-scope-pill'),
                label: l10n.analyticsScopeLabel(scopeLabel),
                icon: AppIcons.menuBook,
                variant: PillVariant.primary,
              ),
            ),
            const SizedBox(height: 16),

            // ── 2. Summary band ─────────────────────────────────────────────
            _ProgressSignals(
              cardCount: reviewWords.length,
              masteredCount: mastered,
              accuracy: accuracy,
              trainingXp: state.todayTrainingXp,
            ),
            const SizedBox(height: 20),

            // ── 3. XP Trend ─────────────────────────────────────────────────
            SectionHeader(title: l10n.analyticsXpTrendTitle),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _XpTrendChart(
                    xpData: analytics?.dailyXp.isNotEmpty == true
                        ? analytics!.dailyXp
                        : analytics?.sevenDayXp ?? [],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      AppPill(
                        label: '${l10n.analyticsWeekXp}: $weekXp XP',
                        variant: PillVariant.xp,
                      ),
                      const SizedBox(width: 8),
                      AppPill(
                        label: '${l10n.analyticsTodayXp}: $todayXp XP',
                        variant: PillVariant.primary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 4. Ability Radar ─────────────────────────────────────────────
            SectionHeader(title: l10n.analyticsAbilityTitle),
            const SizedBox(height: 8),
            AppCard(
              child: _AbilityRadarChart(
                reviewWords: reviewWords,
                l10n: l10n,
              ),
            ),
            const SizedBox(height: 20),

            // ── 5. Modality Accuracy ─────────────────────────────────────────
            SectionHeader(title: l10n.analyticsModalityTitle),
            const SizedBox(height: 8),
            AppCard(
              child: _ModalityAccuracyChart(
                modalityAccuracy: analytics?.modalityAccuracy ??
                    _fallbackModalityFromWords(reviewWords),
                l10n: l10n,
              ),
            ),
            const SizedBox(height: 20),

            // ── 6. Word Mastery ──────────────────────────────────────────────
            SectionHeader(title: l10n.analyticsMasteryTitle),
            const SizedBox(height: 8),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MasteryPieChart(reviewWords: reviewWords, l10n: l10n),
                  const SizedBox(height: 12),
                  Text(
                    l10n.analyticsReviewLoad,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6),
                  AppProgressBar(
                    value: reviewWords.isEmpty
                        ? 0
                        : (state.dueWords.length / reviewWords.length)
                            .clamp(0.0, 1.0),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.analyticsAssetsDue(
                      state.dueWords.length,
                      reviewWords.length,
                    ),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── 7. Detailed Stats ────────────────────────────────────────────
            if (analytics != null) ...[
              SectionHeader(title: l10n.analyticsDetailTitle),
              const SizedBox(height: 8),
              _ExtendedAnalyticsSection(
                analytics: analytics,
                weakWordCount: state.weakWords.length,
                dueWordCount: state.dueWords.length,
                l10n: l10n,
              ),
              const SizedBox(height: 20),
            ] else ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 20),
            ],

            // ── 8. Reading ───────────────────────────────────────────────────
            SectionHeader(title: l10n.readingAnalyticsTitle),
            const SizedBox(height: 8),
            _ReadingSection(metrics: _readingMetrics, l10n: l10n),
            const SizedBox(height: 20),

            // ── 9. Recommended Practice ──────────────────────────────────────
            SectionHeader(title: l10n.analyticsFocusTitle),
            const SizedBox(height: 8),
            _RecommendedPracticeSection(recommendations: recommendations),
          ],
        ),
      ),
    );
  }
}

/// Reading metrics card (P3e): articles read, comprehension accuracy, and a
/// per-theme breakdown — computed client-side from saved ReadingResults.
class _ReadingSection extends StatelessWidget {
  const _ReadingSection({required this.metrics, required this.l10n});

  final ReadingMetrics metrics;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (metrics.isEmpty) {
      return AppCard(
        key: const ValueKey('reading-analytics-empty'),
        child: Text(
          l10n.readingAnalyticsEmpty,
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    final themes = metrics.themeDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return AppCard(
      key: const ValueKey('reading-analytics-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _ReadingStat(
                  label: l10n.readingAnalyticsArticlesRead,
                  value: '${metrics.articlesRead}',
                ),
              ),
              Expanded(
                child: _ReadingStat(
                  label: l10n.readingAnalyticsAccuracy,
                  value: '${metrics.accuracyPct}%',
                ),
              ),
            ],
          ),
          if (themes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              l10n.readingAnalyticsThemes,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in themes)
                  AppPill(
                    label: '${readingThemeLabel(l10n, e.key)} · ${e.value}',
                    variant: PillVariant.primary,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReadingStat extends StatelessWidget {
  const _ReadingStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Fallback modality accuracy from CustomWord dimension scores when server
/// data is unavailable or sparse.
Map<String, int> _fallbackModalityFromWords(List<CustomWord> words) {
  if (words.isEmpty) return const {};
  int sumMeaning = 0, sumListening = 0, sumSpelling = 0, sumContext = 0;
  for (final w in words) {
    sumMeaning += (w.meaningRecognitionScore + w.meaningRecallScore) ~/ 2;
    sumListening += w.listeningScore;
    sumSpelling += w.spellingScore;
    sumContext += w.contextScore;
  }
  final n = words.length;
  return {
    'meaning': (sumMeaning / n).round(),
    'listening': (sumListening / n).round(),
    'spelling': (sumSpelling / n).round(),
    'context': (sumContext / n).round(),
  };
}

// ── C1 XP Trend Line Chart ────────────────────────────────────────────────────

class _XpTrendChart extends StatelessWidget {
  const _XpTrendChart({required this.xpData});

  final List<int> xpData;

  @override
  Widget build(BuildContext context) {
    if (xpData.isEmpty || xpData.every((v) => v == 0)) {
      return const SizedBox(
        height: 160,
        child: Center(
          child: Text('No XP data yet — start learning!'),
        ),
      );
    }

    final spots = xpData
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
        .toList();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (val, meta) {
                  final idx = val.toInt();
                  if (idx < 0 || idx >= xpData.length) {
                    return const SizedBox.shrink();
                  }
                  // Show every 2nd label to avoid crowding
                  if (idx % 2 != 0 && idx != xpData.length - 1) {
                    return const SizedBox.shrink();
                  }
                  final labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final label = idx < labels.length ? labels[idx] : '${idx + 1}';
                  return Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 9,
                        ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              gradient: LinearGradient(
                colors: [AppTheme.mango, AppTheme.success],
              ),
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppTheme.mango.withValues(alpha: 0.15),
                    AppTheme.success.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── C2 Modality Accuracy Bar Chart ────────────────────────────────────────────

class _ModalityAccuracyChart extends StatelessWidget {
  const _ModalityAccuracyChart({
    required this.modalityAccuracy,
    required this.l10n,
  });

  final Map<String, int> modalityAccuracy;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final modalities = ['meaning', 'listening', 'spelling', 'context'];
    final colors = [AppTheme.cyan, AppTheme.coral, AppTheme.mango, AppTheme.success];
    final labels = [
      l10n.analyticsModalityMeaning,
      l10n.analyticsModalityListening,
      l10n.analyticsModalitySpelling,
      l10n.analyticsModalityContext,
    ];

    final hasData = modalityAccuracy.values.any((v) => v > 0);
    if (!hasData) {
      return SizedBox(
        height: 140,
        child: Center(
          child: Text(
            'No modality data yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final groups = modalities.asMap().entries.map((e) {
      final i = e.key;
      final key = e.value;
      final value = (modalityAccuracy[key] ?? 0).toDouble();
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: value,
            color: colors[i],
            width: 22,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          maxY: 100,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (v) => FlLine(
              color: Theme.of(context).colorScheme.outlineVariant,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (val, meta) {
                  if (val % 50 != 0) return const SizedBox.shrink();
                  return Text(
                    '${val.toInt()}%',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                  return Text(
                    labels[i],
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: groups,
        ),
      ),
    );
  }
}

// ── C3 Mastery Pie (Donut) Chart ──────────────────────────────────────────────

class _MasteryPieChart extends StatelessWidget {
  const _MasteryPieChart({
    required this.reviewWords,
    required this.l10n,
  });

  final List<CustomWord> reviewWords;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final total = reviewWords.length;
    final newCount =
        reviewWords.where((w) => w.masteryLevel <= 0).length;
    final learningCount =
        reviewWords.where((w) => w.masteryLevel > 0 && w.masteryLevel < 4).length;
    final masteredCount = reviewWords.where((w) => w.masteryLevel >= 4).length;

    if (total == 0) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'No words yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 180,
          width: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 50,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  value: newCount.toDouble().clamp(0.01, double.infinity),
                  color: AppTheme.cyan,
                  radius: 40,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: learningCount.toDouble().clamp(0.01, double.infinity),
                  color: AppTheme.mango,
                  radius: 40,
                  showTitle: false,
                ),
                PieChartSectionData(
                  value: masteredCount.toDouble().clamp(0.01, double.infinity),
                  color: AppTheme.success,
                  radius: 40,
                  showTitle: false,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(
                color: AppTheme.cyan,
                label: l10n.analyticsMasteryNew,
                value: newCount,
              ),
              const SizedBox(height: 8),
              _LegendDot(
                color: AppTheme.mango,
                label: l10n.analyticsMasteryLearning,
                value: learningCount,
              ),
              const SizedBox(height: 8),
              _LegendDot(
                color: AppTheme.success,
                label: l10n.analyticsMasteryMastered,
                value: masteredCount,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Text(
          '$value',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

// ── C4 Ability Radar Chart ────────────────────────────────────────────────────

class _AbilityRadarChart extends StatelessWidget {
  const _AbilityRadarChart({
    required this.reviewWords,
    required this.l10n,
  });

  final List<CustomWord> reviewWords;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (reviewWords.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No words yet',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }

    final n = reviewWords.length;
    final avgRecognition =
        reviewWords.fold<double>(0, (s, w) => s + w.meaningRecognitionScore) /
            n;
    final avgRecall =
        reviewWords.fold<double>(0, (s, w) => s + w.meaningRecallScore) / n;
    final avgContext =
        reviewWords.fold<double>(0, (s, w) => s + w.contextScore) / n;
    final avgListening =
        reviewWords.fold<double>(0, (s, w) => s + w.listeningScore) / n;
    final avgSpelling =
        reviewWords.fold<double>(0, (s, w) => s + w.spellingScore) / n;

    // Clamp scores to [0, 100] for radar
    double clamp(double v) => v.clamp(0.0, 100.0);

    final featureLabels = [
      l10n.analyticsDimMeaningRecognition,
      l10n.analyticsDimMeaningRecall,
      l10n.analyticsDimContext,
      l10n.analyticsDimListening,
      l10n.analyticsDimSpelling,
    ];

    return SizedBox(
      height: 200,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 2,
          ticksTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ) ??
              const TextStyle(fontSize: 8),
          gridBorderData: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
          tickBorderData: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
          radarBorderData: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
          getTitle: (index, angle) {
            return RadarChartTitle(
              text: featureLabels[index % featureLabels.length],
              angle: angle,
            );
          },
          titleTextStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9,
              ) ??
              const TextStyle(fontSize: 9),
          titlePositionPercentageOffset: 0.15,
          dataSets: [
            RadarDataSet(
              fillColor: AppTheme.cyan.withValues(alpha: 0.15),
              borderColor: AppTheme.cyan,
              borderWidth: 2,
              entryRadius: 3,
              dataEntries: [
                RadarEntry(value: clamp(avgRecognition)),
                RadarEntry(value: clamp(avgRecall)),
                RadarEntry(value: clamp(avgContext)),
                RadarEntry(value: clamp(avgListening)),
                RadarEntry(value: clamp(avgSpelling)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Progress Signals (top summary band) ──────────────────────────────────────

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

// ── Detailed stats section ─────────────────────────────────────────────────────

class _ExtendedAnalyticsSection extends StatelessWidget {
  const _ExtendedAnalyticsSection({
    required this.analytics,
    required this.weakWordCount,
    required this.dueWordCount,
    required this.l10n,
  });

  final LearningAnalytics analytics;
  final int weakWordCount;
  final int dueWordCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        children: [
          _StatRow(
            label: 'Streak',
            value: '${analytics.streakDays} days',
            icon: AppIcons.localFireDepartment,
            color: AppTheme.mango,
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Total Study Days',
            value: '${analytics.totalStudyDays} days',
            icon: AppIcons.calendarMonth,
            color: AppTheme.cyan,
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Learned Words',
            value: '${analytics.learnedWords}',
            icon: AppIcons.menuBook,
            color: AppTheme.success,
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Today Study Time',
            value: '${analytics.todayMinutes} min',
            icon: AppIcons.timer,
            color: AppTheme.coral,
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Total Study Time',
            value: '${analytics.totalMinutes} min',
            icon: AppIcons.schedule,
            color: AppTheme.mango,
          ),
          const Divider(height: 20),
          _StatRow(
            label: 'Wordbook Progress',
            value: '${analytics.wordbookProgressPct}%',
            icon: AppIcons.insights,
            color: AppTokens.primarySoftText,
          ),
          const Divider(height: 20),
          _StatRow(
            label: l10n.analyticsWeakWords,
            value: '$weakWordCount',
            icon: AppIcons.warningAmber,
            color: AppTheme.coral,
          ),
          const Divider(height: 20),
          _StatRow(
            label: l10n.analyticsDueNow,
            value: '$dueWordCount',
            icon: AppIcons.schedule,
            color: AppTheme.cyan,
          ),
          if (analytics.topErrorTypes.isNotEmpty) ...[
            const Divider(height: 20),
            _StatRow(
              label: l10n.analyticsTopErrors,
              value: analytics.topErrorTypes.take(2).join(', '),
              icon: AppIcons.warningAmber,
              color: AppTheme.coral,
            ),
          ],
        ],
      ),
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

// ── Recommended Practice Section ──────────────────────────────────────────────

class _RecommendedPracticeSection extends StatelessWidget {
  const _RecommendedPracticeSection({required this.recommendations});

  final List<Recommendation> recommendations;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                    style: Theme.of(context).textTheme.bodyMedium,
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
