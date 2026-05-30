import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';

class ProgressAnalyticsScreen extends ConsumerWidget {
  const ProgressAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
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
              subtitle: '根据生词卡和复习记录生成的首版分析视图。',
            ),
            const SizedBox(height: 16),
            _ProgressSignals(
              cardCount: state.customWords.length,
              masteredCount: mastered,
              accuracy: accuracy,
            ),
            const SizedBox(height: 20),
            Text(
              '复习负荷',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: state.customWords.isEmpty
                  ? 0
                  : (state.dueWords.length / state.customWords.length).clamp(
                      0.0,
                      1.0,
                    ),
            ),
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
    required this.cardCount,
    required this.masteredCount,
    required this.accuracy,
  });

  final int cardCount;
  final int masteredCount;
  final int accuracy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProgressSignal(
            label: '生词卡',
            value: '$cardCount',
            icon: Icons.style_outlined,
            color: AppTheme.cyan,
          ),
        ),
        const _ProgressSignalDivider(),
        Expanded(
          child: _ProgressSignal(
            label: '已掌握',
            value: '$masteredCount',
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
