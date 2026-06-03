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
import '../../data/models/lesson.dart';
import '../../data/models/word_entry.dart';
import 'word_knowledge_sections.dart';

class TargetWordDetailScreen extends ConsumerStatefulWidget {
  const TargetWordDetailScreen({required this.wordId, super.key});

  final String wordId;

  @override
  ConsumerState<TargetWordDetailScreen> createState() => _TargetWordDetailScreenState();
}

class _TargetWordDetailScreenState extends ConsumerState<TargetWordDetailScreen> {
  WordEntry? _entry;

  @override
  void initState() {
    super.initState();
    _loadEntry();
  }

  Future<void> _loadEntry() async {
    final controller = ref.read(appControllerProvider.notifier);
    final result = await controller.getWord(widget.wordId);
    if (mounted) {
      setState(() {
        _entry = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final word = _find(state);
    if (word == null && _entry == null) {
      return const Scaffold(body: Center(child: Text('没有找到这个词')));
    }
    final displayWord = word ?? _wordFromEntry(_entry!);
    final isSaved = state.customWords.any(
      (item) => item.word.trim().toLowerCase() == displayWord.word.toLowerCase(),
    );

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/wordbook'),
        title: Text(displayWord.word),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.playlist_add_check_rounded),
                  label: const Text('当前计划中'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isSaved
                      ? null
                      : () => _addToCustomWords(context, ref, displayWord),
                  icon: Icon(
                    isSaved
                        ? Icons.check_circle_outline
                        : Icons.add_circle_outline,
                  ),
                  label: Text(isSaved ? '已加入生词本' : '加入生词本'),
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
                  ImageCueBadge(cue: displayWord.imageCue, size: 108),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      Text(
                        displayWord.word,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      PronunciationControls(word: displayWord.word, compact: true),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(displayWord.phonetic),
                  const SizedBox(height: 12),
                  Text(
                    displayWord.meaning,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(displayWord.definition, textAlign: TextAlign.center),
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
                        Text(displayWord.exampleSentence),
                        const SizedBox(height: 6),
                        Text(
                          displayWord.exampleTranslation,
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
            WordKnowledgeSections(word: displayWord),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(label: displayWord.partOfSpeech),
                PillLabel(
                  label: displayDifficulty(displayWord.difficulty),
                  color: AppTheme.coral,
                ),
                for (final tag in displayWord.tags)
                  PillLabel(label: displayWordTag(tag)),
              ],
            ),
            const SizedBox(height: 22),
            if (_entry != null) ...[
              _buildRichEntry(context, _entry!),
              const SizedBox(height: 22),
            ],
            AiWordSupportLink(word: displayWord.word),
          ],
        ),
      ),
    );
  }

  Widget _buildRichEntry(BuildContext context, WordEntry entry) {
    final sections = <Widget>[];

    if (entry.phoneticUK.isNotEmpty || entry.phoneticUS.isNotEmpty) {
      sections.add(_buildSectionTitle('音标'));
      if (entry.phoneticUK.isNotEmpty) {
        sections.add(Text('英 ${entry.phoneticUK}', style: Theme.of(context).textTheme.bodyLarge));
      }
      if (entry.phoneticUS.isNotEmpty) {
        sections.add(Text('美 ${entry.phoneticUS}', style: Theme.of(context).textTheme.bodyLarge));
      }
      sections.add(const SizedBox(height: 16));
    }

    if (entry.definitions.length > 1) {
      sections.add(_buildSectionTitle('更多释义'));
      for (var i = 1; i < entry.definitions.length; i++) {
        sections.add(Text('${i + 1}. ${entry.definitions[i]}'));
      }
      sections.add(const SizedBox(height: 16));
    }

    if (entry.exampleSentences.length > 1) {
      sections.add(_buildSectionTitle('更多例句'));
      for (var i = 1; i < entry.exampleSentences.length && i < 3; i++) {
        sections.add(Text(entry.exampleSentences[i].en, style: Theme.of(context).textTheme.bodyMedium));
        sections.add(Text(entry.exampleSentences[i].cn, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)));
        sections.add(const SizedBox(height: 8));
      }
      sections.add(const SizedBox(height: 8));
    }

    if (entry.collocations.isNotEmpty) {
      sections.add(_buildSectionTitle('常见搭配'));
      for (final col in entry.collocations.take(5)) {
        sections.add(Text('${col.phrase} — ${col.cn}'));
      }
      sections.add(const SizedBox(height: 16));
    }

    if (entry.synonyms.isNotEmpty) {
      sections.add(_buildSectionTitle('近义词'));
      sections.add(Wrap(
        spacing: 8,
        children: entry.synonyms.take(8).map((s) => Chip(label: Text(s))).toList(),
      ));
      sections.add(const SizedBox(height: 16));
    }

    if (entry.antonyms.isNotEmpty) {
      sections.add(_buildSectionTitle('反义词'));
      sections.add(Wrap(
        spacing: 8,
        children: entry.antonyms.take(8).map((s) => Chip(label: Text(s))).toList(),
      ));
      sections.add(const SizedBox(height: 16));
    }

    if (entry.derivatives.isNotEmpty) {
      sections.add(_buildSectionTitle('派生词'));
      sections.add(Wrap(
        spacing: 8,
        children: entry.derivatives.take(8).map((s) => Chip(label: Text(s))).toList(),
      ));
      sections.add(const SizedBox(height: 16));
    }

    if (entry.rootAffix.isNotEmpty) {
      sections.add(_buildSectionTitle('词根词缀'));
      sections.add(Text(entry.rootAffix));
      sections.add(const SizedBox(height: 16));
    }

    if (sections.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: sections,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Future<void> _addToCustomWords(
    BuildContext context,
    WidgetRef ref,
    Word word,
  ) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .addCustomWord(
          word: word.word,
          meaning: word.meaning,
          exampleSentence: word.exampleSentence,
          note: '${word.definition}\n${word.exampleTranslation}',
          tag: word.tags.isEmpty ? '目标词' : displayWordTag(word.tags.first),
          difficulty: word.difficulty,
        );
    if (!context.mounted) return;
    final message = succeeded
        ? '已加入生词本'
        : ref.read(appControllerProvider).errorMessage ?? '暂时无法加入生词本';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Word? _find(AppState state) {
    for (final lesson in state.formalLessons) {
      for (final word in lesson.words) {
        if (word.id == widget.wordId) return word;
      }
    }
    return null;
  }

  Word _wordFromEntry(WordEntry entry) {
    return Word(
      id: entry.id,
      word: entry.word,
      phonetic: entry.phoneticUK.isNotEmpty ? entry.phoneticUK : entry.phoneticUS,
      meaning: entry.definitions.isNotEmpty ? entry.definitions.first : '',
      definition: entry.englishDefinitions.isNotEmpty ? entry.englishDefinitions.first : '',
      partOfSpeech: entry.partOfSpeech,
      exampleSentence: entry.exampleSentences.isNotEmpty ? entry.exampleSentences.first.en : '',
      exampleTranslation: entry.exampleSentences.isNotEmpty ? entry.exampleSentences.first.cn : '',
      imageCue: '',
      difficulty: entry.difficulty.isNotEmpty
          ? entry.difficulty[0].toUpperCase() + entry.difficulty.substring(1)
          : 'Medium',
      tags: [...entry.examTags, entry.partOfSpeech].where((t) => t.isNotEmpty).toList(),
    );
  }
}
