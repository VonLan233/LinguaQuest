import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../data/dictionary_search.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _query = '';
  DictionarySearchScope _scope = DictionarySearchScope.currentWordBook;

  late final ProviderSubscription<AppState> _stateSubscription;

  Timer? _searchDebounce;
  int _searchVersion = 0;
  bool _isSearching = false;

  List<DictionaryWordSearchResult> _targetWords = const [];
  List<CustomWordSearchResult> _customWords = const [];

  List<Lesson>? _cachedFormalLessons;
  List<Word> _cachedCurrentWords = const [];

  String? _lastCurrentWordBookId;
  List<WordBook>? _lastWordBooks;
  List<Lesson>? _lastFormalLessons;
  List<CustomWord>? _lastCustomWords;

  @override
  void initState() {
    super.initState();
    final initialState = ref.read(appControllerProvider);
    _lastCurrentWordBookId = initialState.currentWordBookId;
    _lastWordBooks = initialState.wordBooks;
    _lastFormalLessons = initialState.formalLessons;
    _lastCustomWords = initialState.customWords;
    _stateSubscription = ref.listenManual<AppState>(appControllerProvider, (
      AppState? _,
      AppState state,
    ) {
      if (!mounted) return;
      final shouldSearch =
          _lastCurrentWordBookId != state.currentWordBookId ||
          !_listEquals(_lastWordBooks, state.wordBooks) ||
          !_listEquals(_lastCustomWords, state.customWords) ||
          !identical(_lastFormalLessons, state.formalLessons);
      _lastCurrentWordBookId = state.currentWordBookId;
      _lastWordBooks = state.wordBooks;
      _lastFormalLessons = state.formalLessons;
      _lastCustomWords = state.customWords;
      if (shouldSearch) {
        _scheduleSearch();
      }
    });
  }

  @override
  void dispose() {
    _stateSubscription.close();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final query = normalizeDictionaryQuery(_query);
    final hasQuery = query.isNotEmpty;
    final hasResults = _targetWords.isNotEmpty || _customWords.isNotEmpty;
    final localeCode = Localizations.localeOf(context).languageCode;
    final currentBookTitle = state.currentWordBook?.title.isNotEmpty == true
        ? state.currentWordBook!.nameFor(localeCode)
        : null;

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(currentBookTitle ?? l10n.searchTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            TextField(
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.searchFieldLabel,
                prefixIcon: const Icon(AppIcons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() => _query = value);
                _scheduleSearch();
              },
            ),
            const SizedBox(height: 12),
            _SearchScopeSelector(
              selected: _scope,
              currentBookTitle:
                  currentBookTitle ?? l10n.reviewCenterCurrentBook,
              l10n: l10n,
              onSelected: (scope) {
                if (scope == _scope) return;
                setState(() => _scope = scope);
                _scheduleSearch();
              },
            ),
            const SizedBox(height: 16),
            if (_isSearching)
              const Center(
                child: Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (!hasQuery)
              MascotEmptyState(
                title: l10n.searchStartTitle,
                message: l10n.searchStartMessage,
              )
            else if (!hasResults)
              MascotEmptyState(
                title: l10n.searchNoResultsTitle,
                message: l10n.searchNoResultsMessage,
                action: OutlinedButton.icon(
                  onPressed: () => context.push('/custom-words/new'),
                  icon: const Icon(AppIcons.add),
                  label: Text(l10n.wordbookAddCustom),
                ),
              )
            else ...[
              if (_targetWords.isNotEmpty) ...[
                _SearchSectionTitle(
                  title: dictionaryScopeLabel(_scope),
                  count: _targetWords.length,
                ),
                for (final result in _targetWords.take(20))
                  _TargetWordTile(result: result, l10n: l10n),
              ],
              if (_customWords.isNotEmpty) ...[
                const SizedBox(height: 12),
                _SearchSectionTitle(
                  title: l10n.commonCustomWords,
                  count: _customWords.length,
                ),
                for (final result in _customWords.take(20))
                  _CustomWordTile(result: result),
              ],
            ],
          ],
        ),
      ),
    );
  }

  void _scheduleSearch() {
    _searchDebounce?.cancel();

    final query = normalizeDictionaryQuery(_query);
    if (query.isEmpty) {
      setState(() {
        _targetWords = const [];
        _customWords = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _targetWords = const [];
      _customWords = const [];
      _isSearching = true;
    });

    _searchDebounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(query),
    );
  }

  void _runSearch(String query) {
    if (!mounted) return;
    final requestVersion = ++_searchVersion;
    final state = ref.read(appControllerProvider);
    final currentWords = _collectCurrentWords(state);

    try {
      final targetWords = searchDictionaryWords(
        wordBooks: state.wordBooks,
        currentWordBookId: state.currentWordBookId,
        scope: _scope,
        query: query,
        currentWords: currentWords,
        tagLabeler: _displayTargetTag,
      );
      final customWords = searchCustomWords(
        customWords: state.customWords,
        query: query,
        tagLabeler: displayCustomTag,
      );

      if (!mounted || requestVersion != _searchVersion) return;
      setState(() {
        _targetWords = targetWords;
        _customWords = customWords;
        _isSearching = false;
      });
    } catch (error, stackTrace) {
      assert(() {
        debugPrint('SearchScreen search failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        return true;
      }());
      if (!mounted || requestVersion != _searchVersion) return;
      setState(() => _isSearching = false);
    }
  }

  List<Word> _collectCurrentWords(AppState state) {
    if (identical(_cachedFormalLessons, state.formalLessons)) {
      return _cachedCurrentWords;
    }

    final words = <Word>[];
    for (final lesson in state.formalLessons) {
      words.addAll(lesson.words);
    }

    _cachedFormalLessons = state.formalLessons;
    _cachedCurrentWords = words;
    return words;
  }

  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

String _displayTargetTag(String tag) => displayWordTag(tag);

class _SearchScopeSelector extends StatelessWidget {
  const _SearchScopeSelector({
    required this.selected,
    required this.currentBookTitle,
    required this.l10n,
    required this.onSelected,
  });

  final DictionarySearchScope selected;
  final String currentBookTitle;
  final AppLocalizations l10n;
  final ValueChanged<DictionarySearchScope> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.searchScopeSummary(
            l10n.searchAllWordbooksScope,
            currentBookTitle,
          ),
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilterPillButton(
              label: l10n.searchCurrentWordbookScope,
              selected: selected == DictionarySearchScope.currentWordBook,
              onSelected: () =>
                  onSelected(DictionarySearchScope.currentWordBook),
            ),
            FilterPillButton(
              label: l10n.searchAllWordbooksScope,
              selected: selected == DictionarySearchScope.allWordBooks,
              onSelected: () => onSelected(DictionarySearchScope.allWordBooks),
              color: AppTheme.cyan,
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchSectionTitle extends StatelessWidget {
  const _SearchSectionTitle({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(width: 8),
          AppPill(label: '$count', variant: PillVariant.neutral),
        ],
      ),
    );
  }
}

class _TargetWordTile extends StatelessWidget {
  const _TargetWordTile({required this.result, required this.l10n});

  final DictionaryWordSearchResult result;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final word = result.word;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: AppCard(
        onTap: () => context.push('/wordbook/${word.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageCueBadge(cue: word.imageCue, size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.word, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(word.primaryDefinitionFor(localeCode)),
                  const SizedBox(height: 4),
                  Text(
                    '${result.matchedBy} · ${result.preview}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.book.nameFor(localeCode),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppPill(
                  label: displayDifficulty(word.difficulty),
                  variant: PillVariant.neutral,
                ),
                if (result.inCurrentWordBook) ...[
                  const SizedBox(height: 6),
                  AppPill(
                    label: l10n.searchCurrentPlan,
                    variant: PillVariant.success,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomWordTile extends StatelessWidget {
  const _CustomWordTile({required this.result});

  final CustomWordSearchResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final word = result.word;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: AppCard(
        onTap: () => context.push('/custom-words/${word.id}'),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ImageCueBadge(cue: wordInitialCue(word.word), size: 54),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.word, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(word.meaning),
                  const SizedBox(height: 4),
                  Text(
                    '${result.matchedBy} · ${result.preview}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${displayDifficulty(word.difficulty)} · ${displayCustomTag(word.tag)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const Icon(AppIcons.chevronRight),
          ],
        ),
      ),
    );
  }
}
