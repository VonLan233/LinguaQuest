import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/metric_tile.dart';
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
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: '生词卡',
                    value: '${state.customWords.length}',
                    icon: Icons.style_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: '已掌握',
                    value: '$mastered',
                    icon: Icons.verified_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: '正确率',
                    value: '$accuracy%',
                    icon: Icons.insights_outlined,
                  ),
                ),
              ],
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
