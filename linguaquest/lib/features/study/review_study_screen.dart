import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';

class ReviewStudyScreen extends ConsumerStatefulWidget {
  const ReviewStudyScreen({super.key});

  @override
  ConsumerState<ReviewStudyScreen> createState() => _ReviewStudyScreenState();
}

class _ReviewStudyScreenState extends ConsumerState<ReviewStudyScreen> {
  final List<CustomWord> _queue = [];
  final Set<String> _completedIds = {};
  final Set<String> _reinforcementIds = {};
  var _revealed = false;
  var _reviewedCount = 0;
  var _isSubmitting = false;
  var _queueInitialized = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    _syncQueue(state.dueWords);
    final currentWord = _queue.isEmpty ? null : _queue.first;
    final totalCount = _reviewedCount + _queue.length;

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
              onMissed: () => setState(() => _revealed = true),
              onContinueAfterReveal: () =>
                  _review(currentWord, isCorrect: false),
              onKnown: () => _review(currentWord, isCorrect: true),
            ),
      body: SafeArea(
        child: currentWord == null
            ? _QueueCompleteView(hasReviewed: _reviewedCount > 0)
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                children: [
                  SectionHeader(
                    title: '今日复习',
                    subtitle: '先回想，再翻开答案；答错会回到本轮稍后巩固。',
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
                  _MemoryHintLine(word: currentWord, isRevealed: _revealed),
                ],
              ),
      ),
    );
  }

  Future<void> _review(CustomWord word, {required bool isCorrect}) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final isReinforcementPass =
        isCorrect && _reinforcementIds.contains(word.id);
    if (isReinforcementPass) {
      _completeCurrentReview(word, requeue: false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('已完成本轮巩固')));
      return;
    }

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
    _completeCurrentReview(word, requeue: !isCorrect);
  }

  void _syncQueue(List<CustomWord> dueWords) {
    if (!_queueInitialized) {
      _queue
        ..clear()
        ..addAll(dueWords);
      _queueInitialized = true;
      return;
    }

    final queuedIds = _queue.map((word) => word.id).toSet();
    for (final word in dueWords) {
      if (_completedIds.contains(word.id) || queuedIds.contains(word.id)) {
        continue;
      }
      _queue.add(word);
      queuedIds.add(word.id);
    }
  }

  CustomWord _latestWordSnapshot(CustomWord fallback) {
    final words = ref.read(appControllerProvider).customWords;
    for (final word in words) {
      if (word.id == fallback.id) return word;
    }
    return fallback;
  }

  void _completeCurrentReview(CustomWord word, {required bool requeue}) {
    setState(() {
      if (_queue.isNotEmpty && _queue.first.id == word.id) {
        _queue.removeAt(0);
      } else {
        _queue.removeWhere((item) => item.id == word.id);
      }
      _reviewedCount += 1;
      _revealed = false;
      _isSubmitting = false;
      if (requeue) {
        final snapshot = _latestWordSnapshot(word);
        _reinforcementIds.add(word.id);
        final insertIndex = _queue.length < 3 ? _queue.length : 3;
        _queue.insert(insertIndex, snapshot);
      } else {
        _completedIds.add(word.id);
        _reinforcementIds.remove(word.id);
      }
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

class _MemoryHintLine extends StatelessWidget {
  const _MemoryHintLine({required this.word, required this.isRevealed});

  final CustomWord word;
  final bool isRevealed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppTheme.iconBadgeSurface(context),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isRevealed ? Icons.lightbulb_outline : Icons.visibility_outlined,
            color: colorScheme.secondary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            isRevealed
                ? '下次复习：${formatRelativeDue(word.nextReviewAt, DateTime.now())}'
                : '答对不打断；答错才展示知识卡，并在本轮稍后再出现。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.42,
            ),
          ),
        ),
      ],
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
    required this.onMissed,
    required this.onContinueAfterReveal,
    required this.onKnown,
  });

  final bool isRevealed;
  final bool isSubmitting;
  final VoidCallback onMissed;
  final VoidCallback onContinueAfterReveal;
  final VoidCallback onKnown;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final compactButtonStyle = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    final compactOutlineStyle = OutlinedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    );
    return Material(
      color: colorScheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: isRevealed
              ? FilledButton.icon(
                  onPressed: isSubmitting ? null : onContinueAfterReveal,
                  style: compactButtonStyle,
                  icon: const Icon(Icons.replay_rounded),
                  label: const FittedBox(child: Text('加入巩固队列')),
                )
              : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSubmitting ? null : onMissed,
                        style: compactOutlineStyle,
                        icon: const Icon(Icons.visibility_outlined),
                        label: const FittedBox(child: Text('没记住')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: isSubmitting ? null : onKnown,
                        style: compactButtonStyle,
                        icon: const Icon(Icons.check_rounded),
                        label: const FittedBox(child: Text('记住了')),
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
