import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/metric_tile.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';

class ReviewCenterScreen extends ConsumerWidget {
  const ReviewCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final due = state.dueWords;
    final weak = state.weakWords;
    final lessonMistakes = state.lastResult?.mistakes ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('复习')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
          children: [
            SectionHeader(
              title: due.isEmpty ? '今日复习已清空' : '${due.length} 张卡片待复习',
              subtitle: '答对快速进入下一张；答错才展开词卡，并回收到本轮稍后再练。',
              trailing: due.isEmpty
                  ? TextButton.icon(
                      onPressed: () => context.push('/custom-words/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('添加'),
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: MetricTile(
                    label: '今日到期',
                    value: '${due.length}',
                    icon: Icons.today_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: '错词',
                    value: '${weak.length}',
                    icon: Icons.warning_amber_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricTile(
                    label: '词卡',
                    value: '${state.customWords.length}',
                    icon: Icons.style_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              '今日到期',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (due.isEmpty)
              EmptyState(
                icon: Icons.check_circle_outline,
                title: '复习队列已清空',
                message: '添加自定义词卡，或把错题加入错词本后，这里会生成复习队列。',
                action: OutlinedButton.icon(
                  onPressed: () => context.push('/custom-words/new'),
                  icon: const Icon(Icons.add),
                  label: const Text('添加自定义词'),
                ),
              )
            else
              for (final word in due) _ReviewTile(word: word),
            const SizedBox(height: 22),
            Text(
              '错词本',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (lessonMistakes.isEmpty && weak.isEmpty)
              const Text('还没有弱项词或课程错题。')
            else ...[
              if (lessonMistakes.isNotEmpty)
                _MistakeWordImporter(mistakes: lessonMistakes),
              for (final mistake in lessonMistakes.take(5))
                QuestCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      ImageCueBadge(cue: mistake.word.imageCue, size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mistake.word.word,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(mistake.explanation),
                          ],
                        ),
                      ),
                      PillLabel(
                        label: '课程',
                        icon: Icons.school_outlined,
                        color: AppTheme.coral,
                      ),
                    ],
                  ),
                ),
              if (lessonMistakes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/mistake-book'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('打开错词本'),
                  ),
                ),
              for (final word in weak.take(5))
                QuestCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  onTap: () => context.push('/custom-words/${word.id}'),
                  child: Row(
                    children: [
                      ImageCueBadge(cue: wordInitialCue(word.word), size: 52),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              word.word,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text('错 ${word.wrongCount} 次 · ${word.meaning}'),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.word});

  final CustomWord word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      appControllerProvider.select((state) => state.isLoading),
    );
    final canReview = word.isDue(DateTime.now()) && !isLoading;
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageCueBadge(cue: wordInitialCue(word.word), size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(word.word),
                  subtitle: Text(
                    '${word.meaning} · ${formatRelativeDue(word.nextReviewAt, DateTime.now())}',
                  ),
                ),
              ),
              Chip(label: Text('${word.masteryLevel}/5')),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: canReview
                      ? () => _review(context, ref, isCorrect: false)
                      : null,
                  icon: const Icon(Icons.close),
                  label: const FittedBox(child: Text('没记住')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: canReview
                      ? () => _review(context, ref, isCorrect: true)
                      : null,
                  icon: const Icon(Icons.check),
                  label: const FittedBox(child: Text('记住了')),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _review(
    BuildContext context,
    WidgetRef ref, {
    required bool isCorrect,
  }) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .reviewWord(word.id, isCorrect);
    if (!context.mounted) return;
    final message = succeeded
        ? isCorrect
              ? '已标记为记住，下次复习会延后'
              : '已加入更近的复习计划'
        : ref.read(appControllerProvider).errorMessage ?? '暂时无法更新这张卡片';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MistakeWordImporter extends ConsumerStatefulWidget {
  const _MistakeWordImporter({required this.mistakes});

  final List<QuizQuestion> mistakes;

  @override
  ConsumerState<_MistakeWordImporter> createState() =>
      _MistakeWordImporterState();
}

class _MistakeWordImporterState extends ConsumerState<_MistakeWordImporter> {
  static const _visibleMistakeLimit = 6;

  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = _visibleMistakeIds();
  }

  @override
  void didUpdateWidget(covariant _MistakeWordImporter oldWidget) {
    super.didUpdateWidget(oldWidget);
    final currentIds = widget.mistakes
        .take(_visibleMistakeLimit)
        .map((mistake) => mistake.word.id)
        .toSet();
    _selectedIds = _selectedIds.intersection(currentIds);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final visibleMistakes = widget.mistakes.take(_visibleMistakeLimit).toList();
    final existingWords = state.customWords
        .map((word) => word.word.trim().toLowerCase())
        .toSet();
    final selectableCount = visibleMistakes
        .where(
          (mistake) =>
              !existingWords.contains(mistake.word.word.trim().toLowerCase()),
        )
        .length;
    final selectedAddableCount = visibleMistakes
        .where(
          (mistake) =>
              _selectedIds.contains(mistake.word.id) &&
              !existingWords.contains(mistake.word.word.trim().toLowerCase()),
        )
        .length;

    return QuestCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      color: AppTheme.warmSurface(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('加入错词卡', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(selectableCount == 0 ? '最近错题已经全部在自定义词卡里。' : '选择错词后，可以直接加入复习卡片。'),
          const SizedBox(height: 10),
          for (final mistake in visibleMistakes) ...[
            Builder(
              builder: (context) {
                final exists = existingWords.contains(
                  mistake.word.word.trim().toLowerCase(),
                );
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: !exists && _selectedIds.contains(mistake.word.id),
                  enabled: !exists,
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        _selectedIds.add(mistake.word.id);
                      } else {
                        _selectedIds.remove(mistake.word.id);
                      }
                    });
                  },
                  title: Text(mistake.word.word),
                  subtitle: Text(exists ? '已加入' : mistake.word.meaning),
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: selectedAddableCount == 0 || state.isLoading
                ? null
                : _addSelected,
            icon: const Icon(Icons.add_card_outlined),
            label: Text('加入已选 ($selectedAddableCount)'),
          ),
        ],
      ),
    );
  }

  Future<void> _addSelected() async {
    final added = await ref
        .read(appControllerProvider.notifier)
        .addMistakesToCustomWords(
          _selectedIds.intersection(_visibleMistakeIds()),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('已加入 $added 张错词卡')));
    if (added > 0) setState(() => _selectedIds.clear());
  }

  Set<String> _visibleMistakeIds() {
    return widget.mistakes
        .take(_visibleMistakeLimit)
        .map((mistake) => mistake.word.id)
        .toSet();
  }
}
