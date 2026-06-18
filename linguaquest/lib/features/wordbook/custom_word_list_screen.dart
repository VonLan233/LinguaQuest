import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:linguaquest/core/theme/app_icons.dart';
import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/custom_word_localization.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/custom_word.dart';
import '../../l10n/generated/app_localizations.dart';

class CustomWordListScreen extends ConsumerStatefulWidget {
  const CustomWordListScreen({super.key});

  @override
  ConsumerState<CustomWordListScreen> createState() =>
      _CustomWordListScreenState();
}

class _CustomWordListScreenState extends ConsumerState<CustomWordListScreen> {
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final words = _filtered(state.customWords, l10n);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/wordbook'),
        title: Text(l10n.commonCustomWords),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/custom-words/new'),
        icon: const Icon(AppIcons.add),
        label: Text(l10n.commonAdd),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: SectionHeader(
                title: l10n.customWordsMyCards,
                subtitle: l10n.customWordsMyCardsSubtitle,
                trailing: AppPill(
                  label: l10n.customWordsCardCount(state.customWords.length),
                  variant: PillVariant.neutral,
                  icon: AppIcons.addCard,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: TextField(
                decoration: InputDecoration(
                  labelText: l10n.customWordsSearchLabel,
                  prefixIcon: const Icon(AppIcons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  for (final filter in const [
                    'All',
                    'Easy',
                    'Medium',
                    'Hard',
                    'Weak',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterPillButton(
                        label: displayDifficultyFilter(filter, l10n: l10n),
                        selected: _filter == filter,
                        onSelected: () => setState(() => _filter = filter),
                        color: filter == 'Weak'
                            ? AppTheme.coral
                            : AppTheme.teal,
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: words.isEmpty
                  ? MascotEmptyState(
                      title: l10n.customWordsNoMatchTitle,
                      message: l10n.customWordsNoMatchMessage,
                      action: AppPrimaryButton(
                        onPressed: () => context.push('/custom-words/new'),
                        icon: AppIcons.add,
                        label: l10n.customWordsAddCard,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
                      itemCount: words.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) => _CustomWordTile(
                        word: words[index],
                        onDelete: () => _confirmDelete(words[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<CustomWord> _filtered(List<CustomWord> words, AppLocalizations l10n) {
    final query = _query.trim().toLowerCase();
    return words.where((word) {
      final matchesQuery =
          query.isEmpty ||
          word.word.toLowerCase().contains(query) ||
          word.meaning.toLowerCase().contains(query) ||
          word.tag.toLowerCase().contains(query) ||
          displayCustomTag(word.tag, l10n: l10n).toLowerCase().contains(query);
      final matchesFilter =
          _filter == 'All' ||
          word.difficulty == _filter ||
          (_filter == 'Weak' && word.isWeak);
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _confirmDelete(CustomWord word) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.customWordsDeleteTitle(word.word)),
        content: Text(l10n.customWordsDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(AppIcons.delete),
            label: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .deleteCustomWord(word.id);
    if (!mounted) return;
    if (!succeeded) {
      final message = ref.read(appControllerProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message ?? l10n.customWordsDeleteFailed(word.word)),
        ),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.customWordsDeleted(word.word))));
  }
}

class _CustomWordTile extends StatelessWidget {
  const _CustomWordTile({required this.word, required this.onDelete});

  final CustomWord word;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final mastery = word.masteryLevel / 5;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    return AppCard(
      onTap: () => context.push('/custom-words/${word.id}'),
      child: Row(
        children: [
          ImageCueBadge(cue: wordInitialCue(word.word), size: 58),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        word.word,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    AppPill(
                      label: displayDifficulty(word.difficulty, l10n: l10n),
                      variant: _difficultyVariant(word.difficulty),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${customWordMeaningFor(word, localeCode)} · ${displayCustomTag(word.tag, l10n: l10n)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 9),
                AppProgressBar(value: mastery),
              ],
            ),
          ),
          QuestIconButton(
            tooltip: l10n.commonDelete,
            icon: AppIcons.delete,
            color: AppTheme.coral,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }

  PillVariant _difficultyVariant(String difficulty) => switch (difficulty) {
    'Hard' => PillVariant.streak,
    'Medium' => PillVariant.primary,
    'Easy' => PillVariant.success,
    _ => PillVariant.neutral,
  };
}
