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
import '../../data/models/user_word.dart';
import 'word_knowledge_sections.dart';

class TargetWordDetailScreen extends ConsumerWidget {
  const TargetWordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final detail = _find(state);
    if (detail == null) {
      return const Scaffold(body: Center(child: Text('没有找到这个词')));
    }
    final word = detail.word;
    final lesson = _findLesson(state);
    final progress = state.userWords
        .where((item) => item.wordId == word.id)
        .firstOrNull;
    final savedWord = _savedCustomWord(state, word);
    final isSaved = savedWord != null;
    final isInNewWordbook = progress?.isInNewWordbook == true || isSaved;
    final wordBookId = lesson?.section ?? detail.book.id;

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
                    wordBookId,
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
                    wordBookId,
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
          children: [
            _WordHero(word: word, bookTitle: detail.book.title),
            const SizedBox(height: 18),
            _DefinitionSections(word: word),
            const SizedBox(height: 18),
            _ExampleSections(word: word),
            const SizedBox(height: 18),
            WordKnowledgeSections(word: word),
            const SizedBox(height: 22),
            _WordTags(word: word, progress: progress),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              onPressed: () => _toggleIgnored(
                context,
                ref,
                word,
                wordBookId,
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
            _aiWordSupportLink(word),
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

  _TargetWordDetail? _find(AppState state) {
    final currentBook = state.currentWordBook;
    if (currentBook != null) {
      for (final word in currentBook.words) {
        if (word.id == wordId) {
          return _TargetWordDetail(word: word, book: currentBook);
        }
      }
    }
    for (final book in state.wordBooks) {
      for (final word in book.words) {
        if (word.id == wordId) return _TargetWordDetail(word: word, book: book);
      }
    }
    for (final lesson in state.formalLessons) {
      for (final word in lesson.words) {
        if (word.id == wordId) {
          return _TargetWordDetail(
            word: word,
            book: currentBook ?? _fallbackBook(word),
          );
        }
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

  WordBook _fallbackBook(Word word) {
    return WordBook(
      id: 'unknown',
      title: '当前词书',
      category: 'exam',
      examType: '',
      coverUrl: '',
      totalWords: 1,
      includedWords: 1,
      description: '',
      wordIds: [word.id],
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      words: [word],
    );
  }
}

Widget _aiWordSupportLink(Word word) {
  final w = word.word;
  final e = word.exampleSentence;
  final t = word.exampleTranslation;
  return AiWordSupportLink(word: w, exampleSentence: e, exampleTranslation: t);
}

class _WordHero extends StatelessWidget {
  const _WordHero({required this.word, required this.bookTitle});

  final Word word;
  final String bookTitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          ImageCueBadge(cue: word.imageCue, size: 108),
          const SizedBox(height: 16),
          Text(
            word.word,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          _PhoneticLine(word: word),
          const SizedBox(height: 12),
          _pronunciationControls(word),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              PillLabel(label: word.partOfSpeech),
              PillLabel(label: bookTitle, color: AppTheme.cyan),
              const PillLabel(
                label: '当前计划中',
                icon: Icons.playlist_add_check_rounded,
                color: AppTheme.cyan,
              ),
              if (word.tags.isNotEmpty)
                const PillLabel(label: '考试高频释义', color: AppTheme.coral),
            ],
          ),
        ],
      ),
    );
  }
}

Widget _pronunciationControls(Word word) {
  final w = word.word;
  final ukAudio = word.audioUKUrl;
  final usAudio = word.audioUSUrl;
  if (ukAudio.isEmpty && usAudio.isEmpty) return _basePronunciationControls(w);
  return PronunciationControls(
    word: w,
    audioUKUrl: ukAudio,
    audioUSUrl: usAudio,
  );
}

Widget _basePronunciationControls(String w) => PronunciationControls(word: w);

class _PhoneticLine extends StatelessWidget {
  const _PhoneticLine({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final uk = word.phoneticUK.trim();
    final us = word.phoneticUS.trim();
    final fallback = word.phonetic.trim();
    if (uk.isEmpty && us.isEmpty && fallback.isEmpty) return const SizedBox();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 6,
      children: [
        if (uk.isNotEmpty) Text('英 /$uk/'),
        if (us.isNotEmpty) Text('美 /$us/'),
        if (uk.isEmpty && us.isEmpty) Text('/$fallback/'),
      ],
    );
  }
}

class _DefinitionSections extends StatelessWidget {
  const _DefinitionSections({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final cn = word.definitions.isEmpty ? [word.meaning] : word.definitions;
    final en = word.englishDefinitions.isEmpty
        ? [word.definition]
        : word.englishDefinitions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('中英释义', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _DefinitionList(title: '中文释义', values: cn, highFrequency: true),
        const SizedBox(height: 12),
        _DefinitionList(title: '英文释义', values: en),
      ],
    );
  }
}

class _DefinitionList extends StatelessWidget {
  const _DefinitionList({
    required this.title,
    required this.values,
    this.highFrequency = false,
  });

  final String title;
  final List<String> values;
  final bool highFrequency;

  @override
  Widget build(BuildContext context) {
    final cleanValues = values
        .where((value) => value.trim().isNotEmpty)
        .toList();
    if (cleanValues.isEmpty) return const SizedBox();
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            if (highFrequency) ...[
              const SizedBox(width: 8),
              const PillLabel(label: '高频', color: AppTheme.coral),
            ],
          ],
        ),
        const SizedBox(height: 8),
        for (final value in cleanValues.take(4))
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('• $value'),
          ),
      ],
    );
  }
}

class _ExampleSections extends StatelessWidget {
  const _ExampleSections({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final examples = word.examples.isEmpty
        ? [WordExample(en: word.exampleSentence, cn: word.exampleTranslation)]
        : word.examples;
    final cleanExamples = examples.where((item) => item.en.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('语境例句', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        for (final example in cleanExamples.take(3))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.format_quote, color: AppTheme.coral),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(example.en),
                      if (example.cn.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          example.cn,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _WordTags extends StatelessWidget {
  const _WordTags({required this.word, required this.progress});

  final Word word;
  final UserWord? progress;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (progress != null) ...[
          PillLabel(
            label: displayWordStatus(progress!.status),
            icon: Icons.psychology_outlined,
            color: AppTheme.mango,
          ),
          PillLabel(label: '掌握 ${progress!.masteryLevel}/5'),
        ],
        PillLabel(label: word.partOfSpeech),
        PillLabel(
          label: displayDifficulty(word.difficulty),
          color: AppTheme.coral,
        ),
        for (final tag in word.tags) PillLabel(label: displayWordTag(tag)),
      ],
    );
  }
}

class _TargetWordDetail {
  const _TargetWordDetail({required this.word, required this.book});

  final Word word;
  final WordBook book;
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
