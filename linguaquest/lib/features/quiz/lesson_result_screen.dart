import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/lesson.dart';
import '../../data/models/lesson_result.dart';

class LessonResultScreen extends ConsumerWidget {
  const LessonResultScreen({this.result, super.key});

  final LessonResult? result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resolved = result ?? ref.watch(appControllerProvider).lastResult;
    if (resolved == null) {
      return const Scaffold(body: Center(child: Text('还没有课程结果')));
    }

    final accuracy = (resolved.accuracy * 100).round();
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/learn'),
        title: const Text('课程结果'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            SectionHeader(
              title: accuracy >= 80 ? '表现很棒！' : '课程完成',
              subtitle:
                  '答对 ${resolved.correctAnswers}/${resolved.totalQuestions} 题 · 获得 ${resolved.xpEarned} XP · 错题已进入复习。',
            ),
            const SizedBox(height: 12),
            PillLabel(
              label: resolved.lessonTitle,
              icon: Icons.workspace_premium_outlined,
              color: AppTheme.cyan,
            ),
            const SizedBox(height: 12),
            _ResultScoreSummary(result: resolved, accuracy: accuracy),
            const SizedBox(height: 20),
            Text(
              '错题',
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
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => context.go('/review'),
              icon: const Icon(Icons.replay),
              label: const Text('去复习中心'),
            ),
            OutlinedButton.icon(
              onPressed: () => context.go('/learn'),
              icon: const Icon(Icons.route_outlined),
              label: const Text('返回学习路径'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PerfectResultRow extends StatelessWidget {
  const _PerfectResultRow();

  @override
  Widget build(BuildContext context) {
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
                Text('全对通关', style: theme.textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '没有错题需要加入复习。',
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
  const _ResultScoreSummary({required this.result, required this.accuracy});

  final LessonResult result;
  final int accuracy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                  '正确率',
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
                label: '+${result.xpEarned} XP',
                icon: Icons.bolt,
                color: AppTheme.mango,
              ),
              PillLabel(
                label: '${result.mistakes.length} 个错题',
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
