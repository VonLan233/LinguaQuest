import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
import '../../data/models/custom_word.dart';

class WordDetailScreen extends ConsumerWidget {
  const WordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final word = _find(ref);
    if (word == null) {
      return const Scaffold(body: Center(child: Text('没有找到这个词')));
    }
    final state = ref.watch(appControllerProvider);
    final canReview = word.isDue(DateTime.now()) && !state.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/custom-words'),
        title: Text(word.word),
        actions: [
          IconButton(
            tooltip: '编辑',
            onPressed: () => context.push('/custom-words/${word.id}/edit'),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ImageCueBadge(cue: wordInitialCue(word.word), size: 104),
                  const SizedBox(height: 16),
                  Text(
                    word.word,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    word.meaning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '“${word.exampleSentence}”',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (word.note.isNotEmpty) ...[
                    const Divider(height: 28),
                    Text(word.note, textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(label: word.tag),
                PillLabel(
                  label: displayDifficulty(word.difficulty),
                  color: AppTheme.coral,
                ),
                PillLabel(
                  label: '掌握 ${word.masteryLevel}/5',
                  icon: Icons.psychology_outlined,
                ),
                PillLabel(
                  label:
                      '下次 ${formatRelativeDue(word.nextReviewAt, DateTime.now())}',
                  icon: Icons.schedule_outlined,
                ),
              ],
            ),
            const SizedBox(height: 20),
            QuestCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('复习统计', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _StatLine(
                          label: '记住',
                          value: '${word.correctCount}',
                        ),
                      ),
                      Expanded(
                        child: _StatLine(
                          label: '没记住',
                          value: '${word.wrongCount}',
                        ),
                      ),
                      Expanded(
                        child: _StatLine(
                          label: '掌握度',
                          value: '${word.masteryLevel}/5',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: canReview
                  ? () => _review(context, ref, word.id, isCorrect: true)
                  : null,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('标记为记住'),
            ),
            OutlinedButton.icon(
              onPressed: canReview
                  ? () => _review(context, ref, word.id, isCorrect: false)
                  : null,
              icon: const Icon(Icons.replay),
              label: const Text('安排近期再练'),
            ),
          ],
        ),
      ),
    );
  }

  CustomWord? _find(WidgetRef ref) {
    for (final word in ref.watch(appControllerProvider).customWords) {
      if (word.id == wordId) return word;
    }
    return null;
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    String id, {
    required bool isCorrect,
  }) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .reviewWord(id, isCorrect);
    if (!context.mounted) return;
    final message = succeeded
        ? isCorrect
              ? '已标记为记住'
              : '已安排近期再练'
        : ref.read(appControllerProvider).errorMessage ?? '暂时无法更新这张卡片';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
