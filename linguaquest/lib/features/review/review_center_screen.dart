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
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('复习'),
      ),
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
            _ReviewQueueSignals(
              dueCount: due.length,
              weakCount: weak.length,
              cardCount: state.customWords.length,
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
                _LessonMistakeRow(mistake: mistake),
              if (lessonMistakes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/mistake-book'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('打开错词本'),
                  ),
                ),
              for (final word in weak.take(5)) _WeakWordRow(word: word),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReviewQueueSignals extends StatelessWidget {
  const _ReviewQueueSignals({
    required this.dueCount,
    required this.weakCount,
    required this.cardCount,
  });

  final int dueCount;
  final int weakCount;
  final int cardCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ReviewSignal(
            label: '今日到期',
            value: '$dueCount',
            icon: Icons.today_outlined,
            color: AppTheme.teal,
          ),
        ),
        const _ReviewSignalDivider(),
        Expanded(
          child: _ReviewSignal(
            label: '错词',
            value: '$weakCount',
            icon: Icons.warning_amber_outlined,
            color: AppTheme.coral,
          ),
        ),
        const _ReviewSignalDivider(),
        Expanded(
          child: _ReviewSignal(
            label: '词卡',
            value: '$cardCount',
            icon: Icons.style_outlined,
            color: AppTheme.cyan,
          ),
        ),
      ],
    );
  }
}

class _ReviewSignal extends StatelessWidget {
  const _ReviewSignal({
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

class _ReviewSignalDivider extends StatelessWidget {
  const _ReviewSignalDivider();

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

class _ReviewTile extends ConsumerWidget {
  const _ReviewTile({required this.word});

  final CustomWord word;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      appControllerProvider.select((state) => state.isLoading),
    );
    final canReview = word.isDue(DateTime.now()) && !isLoading;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ImageCueBadge(cue: wordInitialCue(word.word), size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(word.word, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      '${word.meaning} · ${formatRelativeDue(word.nextReviewAt, DateTime.now())}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PillLabel(
                label: '掌握 ${word.masteryLevel}/5',
                icon: Icons.psychology_outlined,
                color: AppTheme.mango,
              ),
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
          const SizedBox(height: 14),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
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

class _LessonMistakeRow extends StatelessWidget {
  const _LessonMistakeRow({required this.mistake});

  final QuizQuestion mistake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          ImageCueBadge(cue: mistake.word.imageCue, size: 52),
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
          const SizedBox(width: 10),
          PillLabel(
            label: '课程',
            icon: Icons.school_outlined,
            color: AppTheme.coral,
          ),
        ],
      ),
    );
  }
}

class _WeakWordRow extends StatelessWidget {
  const _WeakWordRow({required this.word});

  final CustomWord word;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('/custom-words/${word.id}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                ImageCueBadge(cue: wordInitialCue(word.word), size: 52),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(word.word, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        '错 ${word.wrongCount} 次 · ${word.meaning}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
        ),
      ),
    );
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
