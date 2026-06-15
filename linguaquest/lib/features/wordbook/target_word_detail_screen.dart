import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/ai_word_support_link.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/pronunciation_controls.dart';
import '../../core/widgets/quest_panel.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/user_word.dart';
import '../../l10n/generated/app_localizations.dart';
import 'word_knowledge_sections.dart';

class TargetWordDetailScreen extends ConsumerWidget {
  const TargetWordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final detail = _find(state, l10n);
    if (detail == null) {
      return Scaffold(body: Center(child: Text(l10n.wordbookWordNotFound)));
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
                    l10n,
                  ),
                  icon: Icon(
                    progress?.isFavorite == true
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                  ),
                  label: Text(
                    progress?.isFavorite == true
                        ? l10n.wordbookFavorited
                        : l10n.wordbookFavorite,
                  ),
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
                    l10n,
                  ),
                  icon: Icon(
                    isInNewWordbook
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                  ),
                  label: Text(
                    isInNewWordbook
                        ? l10n.wordbookRemoveCustomWord
                        : l10n.wordbookAddToCustomWords,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s20,
            AppTokens.s20,
            112,
          ),
          children: [
            QuestPanel(
              child: _WordHero(
                word: word,
                bookTitle: detail.book.title,
                l10n: l10n,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            QuestPanel(child: _DefinitionSections(word: word, l10n: l10n)),
            const SizedBox(height: AppTokens.s16),
            QuestPanel(child: _ExampleSections(word: word, l10n: l10n)),
            const SizedBox(height: AppTokens.s16),
            WordKnowledgeSections(word: word),
            const SizedBox(height: AppTokens.s24),
            _WordTags(word: word, progress: progress, l10n: l10n),
            const SizedBox(height: AppTokens.s24),
            OutlinedButton.icon(
              onPressed: () => _toggleIgnored(
                context,
                ref,
                word,
                wordBookId,
                progress?.isIgnored ?? false,
                l10n,
              ),
              icon: Icon(
                progress?.isIgnored == true
                    ? Icons.undo_rounded
                    : Icons.block_outlined,
              ),
              label: Text(
                progress?.isIgnored == true
                    ? l10n.wordbookResumeLearning
                    : l10n.wordbookIgnoreEasy,
              ),
            ),
            const SizedBox(height: 12),
            _AiWordSupportLink(word: word),
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
    AppLocalizations l10n,
  ) async {
    await _updateFlags(
      context,
      ref,
      word,
      wordBookId,
      isFavorite: !current,
      successMessage: current
          ? l10n.wordbookFavoriteRemoved
          : l10n.wordbookFavorited,
      failureMessage: l10n.wordbookUpdateTargetFailed,
      l10n: l10n,
    );
  }

  Future<void> _toggleNewWordbook(
    BuildContext context,
    WidgetRef ref,
    Word word,
    String wordBookId,
    bool current,
    AppLocalizations l10n,
  ) async {
    await _updateFlags(
      context,
      ref,
      word,
      wordBookId,
      isInNewWordbook: !current,
      successMessage: current
          ? l10n.wordbookRemovedFromCustomWords
          : l10n.wordbookAddedToCustomWords,
      failureMessage: l10n.wordbookUpdateTargetFailed,
      l10n: l10n,
    );
  }

  Future<void> _toggleIgnored(
    BuildContext context,
    WidgetRef ref,
    Word word,
    String wordBookId,
    bool current,
    AppLocalizations l10n,
  ) async {
    await _updateFlags(
      context,
      ref,
      word,
      wordBookId,
      isIgnored: !current,
      successMessage: current
          ? l10n.wordbookLearningResumed
          : l10n.wordbookIgnored,
      failureMessage: l10n.wordbookUpdateTargetFailed,
      l10n: l10n,
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
    required String failureMessage,
    required AppLocalizations l10n,
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
              tag: word.tags.isEmpty
                  ? l10n.reviewCenterTargetWord
                  : displayWordTag(word.tags.first),
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
        : ref.read(appControllerProvider).errorMessage ?? failureMessage;
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

  _TargetWordDetail? _find(AppState state, AppLocalizations l10n) {
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
            book: currentBook ?? _fallbackBook(word, l10n),
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

  WordBook _fallbackBook(Word word, AppLocalizations l10n) {
    return WordBook(
      id: 'unknown',
      title: l10n.wordbookCurrentPlan,
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

class _AiWordSupportLink extends StatelessWidget {
  const _AiWordSupportLink({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    return AiWordSupportLink(
      word: word.word,
      exampleSentence: word.exampleSentence,
      exampleTranslation: word.exampleTranslation,
    );
  }
}

class _WordHero extends StatelessWidget {
  const _WordHero({
    required this.word,
    required this.bookTitle,
    required this.l10n,
  });

  final Word word;
  final String bookTitle;
  final AppLocalizations l10n;

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
          _PronunciationControls(word: word),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              PillLabel(label: word.partOfSpeech),
              PillLabel(label: bookTitle, color: AppTheme.cyan),
              PillLabel(
                label: l10n.wordbookCurrentPlan,
                icon: Icons.playlist_add_check_rounded,
                color: AppTheme.cyan,
              ),
              if (word.tags.isNotEmpty)
                PillLabel(
                  label: l10n.wordbookHighFrequencyDefinition,
                  color: AppTheme.coral,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PronunciationControls extends StatelessWidget {
  const _PronunciationControls({required this.word});

  final Word word;

  @override
  Widget build(BuildContext context) {
    return PronunciationControls(
      word: word.word,
      audioUKUrl: word.audioUKUrl,
      audioUSUrl: word.audioUSUrl,
    );
  }
}

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
        if (uk.isNotEmpty)
          Text(AppLocalizations.of(context).wordbookUkPhonetic(uk)),
        if (us.isNotEmpty)
          Text(AppLocalizations.of(context).wordbookUsPhonetic(us)),
        if (uk.isEmpty && us.isEmpty) Text('/$fallback/'),
      ],
    );
  }
}

class _DefinitionSections extends StatelessWidget {
  const _DefinitionSections({required this.word, required this.l10n});

  final Word word;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cn = word.definitions.isEmpty ? [word.meaning] : word.definitions;
    final en = word.englishDefinitions.isEmpty
        ? [word.definition]
        : word.englishDefinitions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wordbookBilingualDefinitions,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _DefinitionList(
          title: l10n.wordbookChineseDefinitions,
          values: cn,
          highFrequency: true,
          l10n: l10n,
        ),
        const SizedBox(height: 12),
        _DefinitionList(
          title: l10n.wordbookEnglishDefinitions,
          values: en,
          l10n: l10n,
        ),
      ],
    );
  }
}

class _DefinitionList extends StatelessWidget {
  const _DefinitionList({
    required this.title,
    required this.values,
    required this.l10n,
    this.highFrequency = false,
  });

  final String title;
  final List<String> values;
  final AppLocalizations l10n;
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
              PillLabel(
                label: l10n.wordbookHighFrequency,
                color: AppTheme.coral,
              ),
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
  const _ExampleSections({required this.word, required this.l10n});

  final Word word;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final examples = word.examples.isEmpty
        ? [WordExample(en: word.exampleSentence, cn: word.exampleTranslation)]
        : word.examples;
    final cleanExamples = examples
        .where((item) => item.en.trim().isNotEmpty)
        .toList();
    if (cleanExamples.isEmpty) return const SizedBox();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.wordbookContextExamples,
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
  const _WordTags({
    required this.word,
    required this.progress,
    required this.l10n,
  });

  final Word word;
  final UserWord? progress;
  final AppLocalizations l10n;

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
          PillLabel(label: l10n.wordbookMasteryLevel(progress!.masteryLevel)),
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
