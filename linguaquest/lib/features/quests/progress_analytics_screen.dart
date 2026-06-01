import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/analytics_summary.dart';

class ProgressAnalyticsScreen extends ConsumerWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final summaryValue = ref.watch(analyticsSummaryProvider);
    final summary = summaryValue.hasValue ? summaryValue.value : null;
    final mastered = state.customWords
        .where((word) => word.masteryLevel >= 4)
        .length;
    final attempts = state.customWords.fold<int>(
      0,
      (sum, word) => sum + word.correctCount + word.wrongCount,
    );
    final correct = state.customWords.fold<int>(
      0,
      (sum, word) => sum + word.correctCount,
    );
    final accuracy = attempts == 0 ? 0 : (correct / attempts * 100).round();
    final displayAccuracy = summary == null
        ? accuracy
        : (summary.accuracy * 100).round();
    final reviewLoad = state.customWords.isEmpty
        ? 0.0
        : (state.dueWords.length / state.customWords.length).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: const Text('学习分析'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: '学习数据',
              subtitle: '根据学习记录、复习事件和积分流水生成的趋势视图。',
            ),
            const SizedBox(height: 16),
            if (summaryValue.isLoading) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ] else if (summaryValue.hasError) ...[
              Text(
                '暂时无法同步服务器统计，已显示当前设备上的学习状态。',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],
            _ProgressSignals(
              sessions: summary?.sessions ?? state.customWords.length,
              weakWords: summary?.weakWords ?? mastered,
              accuracy: displayAccuracy,
            ),
            const SizedBox(height: 20),
            _SummaryLine(summary: summary),
            const SizedBox(height: 20),
            Text(
              '复习负荷',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: reviewLoad),
            const SizedBox(height: 8),
            Text(
              '${state.customWords.length} 张生词卡中有 ${state.dueWords.length} 张到期',
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSignals extends StatelessWidget {
  const _ProgressSignals({
    required this.sessions,
    required this.weakWords,
    required this.accuracy,
  });

  final int sessions;
  final int weakWords;
  final int accuracy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProgressSignal(
            label: '学习次数',
            value: '$sessions',
            icon: Icons.style_outlined,
            color: AppTheme.cyan,
          ),
        ),
        const _ProgressSignalDivider(),
        Expanded(
          child: _ProgressSignal(
            label: '薄弱词',
            value: '$weakWords',
            icon: Icons.verified_outlined,
            color: AppTheme.success,
          ),
        ),
        const _ProgressSignalDivider(),
        Expanded(
          child: _ProgressSignal(
            label: '正确率',
            value: '$accuracy%',
            icon: Icons.insights_outlined,
            color: AppTheme.mango,
          ),
        ),
      ],
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.summary});

  final AnalyticsSummary? summary;

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return Text(
        '服务器统计同步后会显示学习时长、累计积分和社区互动。',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MiniStat(label: '学习时长', value: '${summary!.studyMinutes} 分钟'),
        _MiniStat(label: '累计积分', value: '${summary!.points} XP'),
        _MiniStat(label: '答题数', value: '${summary!.totalQuestions}'),
        _MiniStat(label: '社区互动', value: '${summary!.forumPosts}'),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.iconBadgeSurface(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label $value',
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w800,
        ),
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
