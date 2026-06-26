import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/lesson.dart';
import '../../l10n/generated/app_localizations.dart';
import '../state/app_controller.dart';
import '../theme/app_icons.dart';
import '../theme/app_tokens.dart';
import 'app_card.dart';
import 'app_pill.dart';

// ---------------------------------------------------------------------------
// Data-driven language catalog
// ---------------------------------------------------------------------------

/// One entry per supported learning language.
///
/// Set [hasBooks] to true once wordbook data for the language is shipped.
/// P2d will flip `ja` to `hasBooks: true` when Japanese books land — the picker
/// then surfaces the language and its books automatically with no other change.
class SupportedLanguage {
  const SupportedLanguage({
    required this.code,
    required this.hasBooks,
  });

  final String code;
  final bool hasBooks;
}

/// Add entries here to support new languages.
///
/// Order is the display order in level 1. `hasBooks: false` renders the row as
/// a non-selectable "coming soon" entry.
const List<SupportedLanguage> kSupportedLanguages = [
  SupportedLanguage(code: 'zh', hasBooks: true),
  SupportedLanguage(code: 'ja', hasBooks: true),  // P2d: JLPT books are now shipped
];

/// Returns a localized, human-readable label for a language [code].
String languageLabel(String code, AppLocalizations l10n) {
  switch (code) {
    case 'zh':
      return l10n.pickerLanguageChinese;
    case 'ja':
      return l10n.pickerLanguageJapanese;
    default:
      return code;
  }
}

// ---------------------------------------------------------------------------
// Public entry point
// ---------------------------------------------------------------------------

/// Opens the two-level language → wordbook picker as a modal bottom sheet.
///
/// The sheet inherits the app-level [ProviderScope] through the element tree,
/// so it can `ref.watch`/`ref.read` the [appControllerProvider] without an
/// explicit container hand-off.
Future<void> showLanguageWordbookPicker(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => _LanguageWordbookPickerSheet(
      onDismiss: () => Navigator.of(sheetCtx).pop(),
    ),
  );
}

// ---------------------------------------------------------------------------
// Internal sheet widget
// ---------------------------------------------------------------------------

class _LanguageWordbookPickerSheet extends ConsumerStatefulWidget {
  const _LanguageWordbookPickerSheet({required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  ConsumerState<_LanguageWordbookPickerSheet> createState() =>
      _LanguageWordbookPickerSheetState();
}

class _LanguageWordbookPickerSheetState
    extends ConsumerState<_LanguageWordbookPickerSheet> {
  /// null = showing Level 1 (language list).
  /// non-null = showing Level 2 (wordbook list for that language code).
  String? _selectedLanguage;

  Future<void> _onBookSelected(String bookId) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final booksBefore = ref.read(appControllerProvider).wordBooks;

    final notifier = ref.read(appControllerProvider.notifier);
    final ok = await notifier.switchWordBook(bookId);
    if (!mounted) return;

    if (ok) {
      WordBook? selected;
      for (final b in booksBefore) {
        if (b.id == bookId) {
          selected = b;
          break;
        }
      }
      final label = selected?.nameFor(localeCode) ?? bookId;
      widget.onDismiss();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pickerSwitchSuccess(label))),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.pickerSwitchFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppTokens.radiusSheet),
            ),
          ),
          child: Column(
            children: [
              // Drag handle.
              Padding(
                padding: const EdgeInsets.only(top: AppTokens.s12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTokens.hairline,
                    borderRadius: BorderRadius.circular(AppTokens.radiusPill),
                  ),
                ),
              ),
              // Header row.
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.s16,
                  AppTokens.s12,
                  AppTokens.s8,
                  AppTokens.s8,
                ),
                child: Row(
                  children: [
                    if (_selectedLanguage != null)
                      IconButton(
                        icon: const Icon(AppIcons.arrowBack),
                        onPressed: () =>
                            setState(() => _selectedLanguage = null),
                        tooltip:
                            MaterialLocalizations.of(context).backButtonTooltip,
                      ),
                    Expanded(
                      child: Text(
                        _selectedLanguage == null
                            ? l10n.pickerChooseLanguage
                            : l10n.pickerChooseWordbook,
                        style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(AppIcons.close),
                      onPressed: widget.onDismiss,
                      tooltip:
                          MaterialLocalizations.of(context).closeButtonLabel,
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Body.
              Expanded(
                child: AnimatedSwitcher(
                  duration: AppTokens.medium,
                  child: _selectedLanguage == null
                      ? _LanguageList(
                          key: const ValueKey('lang-list'),
                          currentLanguage: state.currentLanguage,
                          scrollController: scrollController,
                          l10n: l10n,
                          onLanguageSelected: (code) {
                            final entry = kSupportedLanguages
                                .firstWhere((e) => e.code == code);
                            if (entry.hasBooks) {
                              setState(() => _selectedLanguage = code);
                            }
                            // !hasBooks rows are not selectable (null onTap),
                            // so this branch is only reached for active langs.
                          },
                        )
                      : _WordbookList(
                          key: ValueKey('book-list-$_selectedLanguage'),
                          books: state.wordBooks
                              .where((b) => b.language == _selectedLanguage)
                              .toList(),
                          currentWordBookId: state.currentWordBookId,
                          scrollController: scrollController,
                          l10n: l10n,
                          onBookSelected: _onBookSelected,
                        ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Level 1: Language list
// ---------------------------------------------------------------------------

class _LanguageList extends StatelessWidget {
  const _LanguageList({
    super.key,
    required this.currentLanguage,
    required this.scrollController,
    required this.l10n,
    required this.onLanguageSelected,
  });

  final String currentLanguage;
  final ScrollController scrollController;
  final AppLocalizations l10n;
  final ValueChanged<String> onLanguageSelected;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTokens.s16),
      itemCount: kSupportedLanguages.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTokens.s8),
      itemBuilder: (_, index) {
        final lang = kSupportedLanguages[index];
        final isCurrent = lang.code == currentLanguage;
        final isActive = lang.hasBooks;
        return _LanguageRow(
          label: languageLabel(lang.code, l10n),
          isCurrent: isCurrent,
          isActive: isActive,
          comingSoonLabel: l10n.pickerComingSoon,
          currentLabel: l10n.pickerCurrentBadge,
          onTap: isActive ? () => onLanguageSelected(lang.code) : null,
        );
      },
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.isCurrent,
    required this.isActive,
    required this.comingSoonLabel,
    required this.currentLabel,
    required this.onTap,
  });

  final String label;
  final bool isCurrent;
  final bool isActive;
  final String comingSoonLabel;
  final String currentLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? AppTokens.textPrimaryLight
                        : AppTokens.textHintLight,
                  ),
            ),
          ),
          const Spacer(),
          if (isCurrent)
            AppPill(
              label: currentLabel,
              variant: PillVariant.success,
              icon: AppIcons.checkCircle,
            )
          else if (!isActive)
            AppPill(
              label: comingSoonLabel,
              variant: PillVariant.neutral,
            ),
          if (isActive && !isCurrent)
            const Padding(
              padding: EdgeInsets.only(left: AppTokens.s8),
              child: Icon(
                AppIcons.chevronRight,
                size: 20,
                color: AppTokens.textSecondaryLight,
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Level 2: Wordbook list
// ---------------------------------------------------------------------------

class _WordbookList extends StatelessWidget {
  const _WordbookList({
    super.key,
    required this.books,
    required this.currentWordBookId,
    required this.scrollController,
    required this.l10n,
    required this.onBookSelected,
  });

  final List<WordBook> books;
  final String currentWordBookId;
  final ScrollController scrollController;
  final AppLocalizations l10n;
  final ValueChanged<String> onBookSelected;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;

    // No books for this language yet (e.g. ja before P2d): coming-soon state.
    if (books.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              AppIcons.menuBook,
              size: 48,
              color: AppTokens.textHintLight,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              l10n.pickerComingSoon,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTokens.textSecondaryLight,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppTokens.s16),
      itemCount: books.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppTokens.s8),
      itemBuilder: (_, index) {
        final book = books[index];
        final isCurrent = book.id == currentWordBookId;
        return _WordbookRow(
          book: book,
          localeCode: localeCode,
          isCurrent: isCurrent,
          currentLabel: l10n.pickerCurrentBadge,
          onTap: isCurrent ? null : () => onBookSelected(book.id),
        );
      },
    );
  }
}

class _WordbookRow extends StatelessWidget {
  const _WordbookRow({
    required this.book,
    required this.localeCode,
    required this.isCurrent,
    required this.currentLabel,
    required this.onTap,
  });

  final WordBook book;
  final String localeCode;
  final bool isCurrent;
  final String currentLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = book.nameFor(localeCode);
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.s16,
        vertical: AppTokens.s12,
      ),
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          if (isCurrent)
            AppPill(
              label: currentLabel,
              variant: PillVariant.success,
              icon: AppIcons.checkCircle,
            ),
        ],
      ),
    );
  }
}
