import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/ai_word_support_link.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import 'word_knowledge_sections.dart';

class TargetWordDetailScreen extends ConsumerWidget {
  const TargetWordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final word = _find(state);
    final lesson = _findLesson(state);
    if (word == null) {
      return const Scaffold(body: Center(child: Text('没有找到这个词')));
    }
    final progress = state.userWords
        .where((item) => item.wordId == word.id)
        .firstOrNull;
    final savedWord = _savedCustomWord(state, word);
    final isSaved = savedWord != null;
    final isInNewWordbook = progress?.isInNewWordbook == true || isSaved;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/wordbook'),
        title: Text(word.word),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _toggleFavorite(
                    context,
                    ref,
                    word,
                    lesson?.section ?? '目标词书',
                    progress?.isFavorite ?? false,
                  ),
                  icon: Icon(
                    progress?.isFavorite == true
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                  ),
                  label: Text(progress?.isFavorite == true ? '已收藏' : '收藏'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _toggleNewWordbook(
                    context,
                    ref,
                    word,
                    lesson?.section ?? '目标词书',
                    isInNewWordbook,
                  ),
                  icon: Icon(
                    isInNewWordbook
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                  ),
                  label: Text(isInNewWordbook ? '移出生词本' : '加入生词本'),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ImageCueBadge(cue: word.imageCue, size: 108),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        word.word,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      PronunciationControls(word: word.word, compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(word.phonetic),
                  const SizedBox(height: 12),
                  Text(
                    word.meaning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(word.definition, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const PillLabel(
                    label: '当前计划中',
                    icon: Icons.playlist_add_check_rounded,
                    color: AppTheme.cyan,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote, color: AppTheme.coral),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(word.exampleSentence),
                        const SizedBox(height: 6),
                        Text(
                          word.exampleTranslation,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            WordKnowledgeSections(word: word),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (progress != null) ...[
                  PillLabel(
                    label: displayWordStatus(progress.status),
                    icon: Icons.psychology_outlined,
                    color: AppTheme.mango,
                  ),
                  PillLabel(label: '掌握 ${progress.masteryLevel}/5'),
                ],
                PillLabel(label: word.partOfSpeech),
                PillLabel(
                  label: displayDifficulty(word.difficulty),
                  color: AppTheme.coral,
                ),
                for (final tag in word.tags)
                  PillLabel(label: displayWordTag(tag)),
              ],
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => _toggleIgnored(
                context,
                ref,
                word,
                lesson?.section ?? '目标词书',
                progress?.isIgnored ?? false,
              ),
              icon: Icon(
                progress?.isIgnored == true
                    ? Icons.undo_rounded
                    : Icons.block_outlined,
              ),
              label: Text(progress?.isIgnored == true ? '恢复学习' : '忽略太简单'),
            ),
            const SizedBox(height: 12),
            AiWordSupportLink(word: word.word),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    WidgetRef ref,
    Word word,
    String wordBookId,
    bool current,
  ) async {
    await _updateFlags(
      context,
      ref,
      word,
      wordBookId,
      isFavorite: !current,
      successMessage: current ? '已取消收藏' : '已收藏',
    );
  }

  Future<void> _toggleNewWordbook(
    BuildContext context,
    WidgetRef ref,
    Word word,
    String wordBookId,
    bool current,
  ) async {
    await _updateFlags(
      context,
      ref,
      word,
      wordBookId,
      isInNewWordbook: !current,
      successMessage: current ? '已移出生词本' : '已加入生词本',
    );
  }

  Future<void> _toggleIgnored(
    BuildContext context,
    WidgetRef ref,
    Word word,
    String wordBookId,
    bool current,
  ) async {
    await _updateFlags(
      context,
      ref,
      word,
      wordBookId,
      isIgnored: !current,
      successMessage: current ? '已恢复学习' : '已忽略，后续不进入复习队列',
    );
  }

  Future<void> _updateFlags(
    BuildContext context,
    WidgetRef ref,
    Word word,
    String wordBookId, {
    bool? isFavorite,
    bool? isInNewWordbook,
    bool? isIgnored,
    required String successMessage,
  }) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .updateTargetWordFlags(
          word,
          wordBookId: wordBookId,
          isFavorite: isFavorite,
          isInNewWordbook: isInNewWordbook,
          isIgnored: isIgnored,
        );
    if (succeeded && isInNewWordbook == true) {
      final alreadySaved = ref
          .read(appControllerProvider)
          .customWords
          .any((item) => _sameWord(item.word, word.word));
      if (!alreadySaved) {
        await ref
            .read(appControllerProvider.notifier)
            .addCustomWord(
              word: word.word,
              meaning: word.meaning,
              exampleSentence: word.exampleSentence,
              note: '${word.definition}\n${word.exampleTranslation}',
              tag: word.tags.isEmpty ? '目标词' : displayWordTag(word.tags.first),
              difficulty: word.difficulty,
            );
      }
    } else if (succeeded && isInNewWordbook == false) {
      final existing = ref.read(appControllerProvider).customWords.where((
        item,
      ) {
        return _sameWord(item.word, word.word);
      }).firstOrNull;
      if (existing != null) {
        await ref
            .read(appControllerProvider.notifier)
            .deleteCustomWord(existing.id);
      }
    }
    if (!context.mounted) return;
    final message = succeeded
        ? successMessage
        : ref.read(appControllerProvider).errorMessage ?? '暂时无法更新目标词';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  CustomWord? _savedCustomWord(AppState state, Word word) {
    final target = word.word.trim().toLowerCase();
    for (final item in state.customWords) {
      if (item.word.trim().toLowerCase() == target) return item;
    }
    return null;
  }

  Word? _find(AppState state) {
    for (final lesson in state.formalLessons) {
      for (final word in lesson.words) {
        if (word.id == wordId) return word;
      }
    }
    return null;
  }

  Lesson? _findLesson(AppState state) {
    for (final lesson in state.formalLessons) {
      for (final word in lesson.words) {
        if (word.id == wordId) return lesson;
      }
    }
    return null;
  }
}

bool _sameWord(String left, String right) {
  return left.trim().toLowerCase() == right.trim().toLowerCase();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
