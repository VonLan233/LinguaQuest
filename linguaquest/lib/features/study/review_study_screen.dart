import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';

class ReviewStudyScreen extends ConsumerStatefulWidget {
  const ReviewStudyScreen({super.key});

  @override
  ConsumerState<ReviewStudyScreen> createState() => _ReviewStudyScreenState();
}

class _ReviewStudyScreenState extends ConsumerState<ReviewStudyScreen> {
  final Set<String> _completedIds = {};
  var _revealed = false;
  var _reviewedCount = 0;
  var _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final queue = state.dueWords
        .where((word) => !_completedIds.contains(word.id))
        .toList();
    final currentWord = queue.isEmpty ? null : queue.first;
    final totalCount = _reviewedCount + queue.length;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('复习'),
        actions: [
          TextButton(
            onPressed: () => context.push('/review'),
            child: const Text('管理复习队列'),
          ),
        ],
      ),
      bottomNavigationBar: currentWord == null
          ? null
          : _ReviewActions(
              isRevealed: _revealed,
              isSubmitting: _isSubmitting,
              onForgot: () => setState(() => _revealed = true),
              onContinueAfterReveal: () =>
                  _review(currentWord, isCorrect: false),
              onRemembered: () => _review(currentWord, isCorrect: true),
            ),
      body: SafeArea(
        child: currentWord == null
            ? _QueueCompleteView(hasReviewed: _reviewedCount > 0)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  SectionHeader(
                    title: '今日复习',
                    subtitle: '先回想，再翻开答案；答错会回到更近的复习计划。',
                    trailing: PillLabel(
                      label: '${_reviewedCount + 1}/$totalCount',
                      icon: Icons.auto_graph,
                      color: AppTheme.cyan,
                    ),
                  ),
                  const SizedBox(height: 14),
                  LinearProgressIndicator(
                    value: totalCount == 0
                        ? 1
                        : (_reviewedCount / totalCount).clamp(0.0, 1.0),
                    minHeight: 9,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: AppTheme.progressTrack(context),
                  ),
                  const SizedBox(height: 18),
                  _ReviewWordCard(word: currentWord, isRevealed: _revealed),
                  const SizedBox(height: 14),
                  _MemoryHintCard(word: currentWord, isRevealed: _revealed),
                ],
              ),
      ),
    );
  }

  Future<void> _review(CustomWord word, {required bool isCorrect}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .reviewWord(word.id, isCorrect);
    if (!mounted) return;
    if (!succeeded) {
      final message =
          ref.read(appControllerProvider).errorMessage ?? '暂时无法更新这张词卡';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _isSubmitting = false);
      return;
    }

    final message = isCorrect ? '已记住，复习间隔已延后' : '已标记为需巩固，稍后再练';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
    setState(() {
      _completedIds.add(word.id);
      _reviewedCount += 1;
      _revealed = false;
      _isSubmitting = false;
    });
  }
}

class _ReviewWordCard extends StatelessWidget {
  const _ReviewWordCard({required this.word, required this.isRevealed});

  final CustomWord word;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return QuestCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ImageCueBadge(cue: wordInitialCue(word.word), size: 66),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      word.word,
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        PillLabel(
                          label: word.tag,
                          icon: Icons.label_outline,
                          color: AppTheme.teal,
                        ),
                        PillLabel(
                          label: '熟练度 ${word.masteryLevel}/5',
                          icon: Icons.psychology_alt_outlined,
                          color: AppTheme.mango,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _MasteryMeter(value: word.masteryLevel / 5),
          if (isRevealed) ...[
            const SizedBox(height: 18),
            Text(
              word.meaning,
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            if (word.exampleSentence.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                word.exampleSentence,
                style: textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
            ],
            if (word.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                word.note,
                style: textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ] else ...[
            const SizedBox(height: 18),
            Text(
              '看英文先回想中文释义。记得就直接进入下一张，忘了再展开知识卡。',
              style: textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemoryHintCard extends StatelessWidget {
  const _MemoryHintCard({required this.word, required this.isRevealed});

  final CustomWord word;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return QuestCard(
      color: AppTheme.accentSurface(context),
      borderColor: colorScheme.secondary.withValues(alpha: 0.24),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isRevealed ? Icons.lightbulb_outline : Icons.visibility_outlined,
            color: colorScheme.secondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isRevealed
                  ? '下次复习：${formatRelativeDue(word.nextReviewAt, DateTime.now())}'
                  : '答对不打断；答错才展示知识卡，并安排更近的复习。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.42,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MasteryMeter extends StatelessWidget {
  const _MasteryMeter({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: 12,
        backgroundColor: AppTheme.progressTrack(context),
      ),
    );
  }
}

class _ReviewActions extends StatelessWidget {
  const _ReviewActions({
    required this.isRevealed,
    required this.isSubmitting,
    required this.onForgot,
    required this.onContinueAfterReveal,
    required this.onRemembered,
  });

  final bool isRevealed;
  final bool isSubmitting;
  final VoidCallback onForgot;
  final VoidCallback onContinueAfterReveal;
  final VoidCallback onRemembered;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: isRevealed
              ? FilledButton.icon(
                  onPressed: isSubmitting ? null : onContinueAfterReveal,
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('加入巩固队列'),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : onForgot,
                        icon: const Icon(Icons.visibility_outlined),
                        label: const Text('没记住'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isSubmitting ? null : onRemembered,
                        icon: const Icon(Icons.check_rounded),
                        label: const Text('记住了'),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _QueueCompleteView extends StatelessWidget {
  const _QueueCompleteView({required this.hasReviewed});

  final bool hasReviewed;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 88),
      children: [
        EmptyState(
          icon: Icons.check_circle_outline,
          title: hasReviewed ? '今日复习完成' : '复习队列已清空',
          message: hasReviewed
              ? '已更新本轮词卡的下次复习时间。'
              : '添加自定义词，或把错题加入错词卡后，这里会生成复习任务。',
          action: Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.home_outlined),
                label: const Text('回到首页'),
              ),
              OutlinedButton.icon(
                onPressed: () => context.push('/review'),
                icon: const Icon(Icons.style_outlined),
                label: const Text('管理复习队列'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
