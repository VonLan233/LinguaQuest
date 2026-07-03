import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/article.dart';
import '../../data/repositories/article_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'reading_labels.dart';

/// Reading list ("时文阅读") for the current language: recommended-first plus a
/// level + theme filter. Tapping an article opens `/reading/<id>`.
class ReadingListScreen extends ConsumerStatefulWidget {
  const ReadingListScreen({super.key});

  @override
  ConsumerState<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends ConsumerState<ReadingListScreen> {
  late Future<_ReadingListData> _future;

  // null = "All" for that filter.
  String? _levelFilter;
  String? _themeFilter;

  @override
  void initState() {
    super.initState();
    _levelFilter = ref.read(appControllerProvider).currentWordBookId;
    _future = _load();
  }

  Future<_ReadingListData> _load() async {
    final controller = ref.read(appControllerProvider.notifier);
    final language = ref.read(appControllerProvider).currentLanguage;
    final articles = await controller.loadArticles(language: language);
    final progress = await controller.readingProgressForScope();
    final progressById = <String, ReadingProgress>{
      for (final p in progress) p.articleId: p,
    };
    return _ReadingListData(articles: articles, progressById: progressById);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(
      appControllerProvider.select((s) => s.currentLanguage),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.readingTitle)),
      body: FutureBuilder<_ReadingListData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;
          final levels = <String>{for (final a in data.articles) a.level}
              .toList()
            ..sort();
          final themes = <String>{for (final a in data.articles) a.theme}
              .toList();

          final filtered = data.articles.where((a) {
            if (_levelFilter != null && a.level != _levelFilter) return false;
            if (_themeFilter != null && a.theme != _themeFilter) return false;
            return true;
          }).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppTokens.s20,
              AppTokens.s20,
              AppTokens.s20,
              88,
            ),
            children: [
              _FilterRow(
                label: l10n.readingFilterLevel,
                values: levels,
                selected: _levelFilter,
                labelOf: (id) => readingLevelLabel(language, id),
                onSelect: (v) => setState(() => _levelFilter = v),
              ),
              const SizedBox(height: AppTokens.s12),
              _FilterRow(
                label: l10n.readingFilterTheme,
                values: themes,
                selected: _themeFilter,
                labelOf: (id) => readingThemeLabel(l10n, id),
                onSelect: (v) => setState(() => _themeFilter = v),
              ),
              const SizedBox(height: AppTokens.s24),
              SectionHeader(
                title: _themeFilter == null
                    ? l10n.readingAllArticles
                    : l10n.readingArticlesForTheme(
                        readingThemeLabel(l10n, _themeFilter!),
                      ),
              ),
              const SizedBox(height: AppTokens.s12),
              if (filtered.isEmpty)
                _EmptyState(message: l10n.readingEmpty)
              else
                for (final article in filtered) ...[
                  _ArticleRow(
                    article: article,
                    language: language,
                    progress: data.progressById[article.id],
                    onTap: () => context
                        .push('/reading/${article.id}')
                        .then((_) {
                      if (mounted) setState(() => _future = _load());
                    }),
                  ),
                  const SizedBox(height: AppTokens.s12),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _ReadingListData {
  const _ReadingListData({required this.articles, required this.progressById});

  final List<Article> articles;
  final Map<String, ReadingProgress> progressById;
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  final String label;
  final List<String> values;
  final String? selected;
  final String Function(String id) labelOf;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppTokens.s8),
        Wrap(
          spacing: AppTokens.s8,
          runSpacing: AppTokens.s8,
          children: [
            ChoiceChip(
              label: Text(l10n.readingFilterAll),
              selected: selected == null,
              onSelected: (_) => onSelect(null),
            ),
            for (final value in values)
              ChoiceChip(
                key: ValueKey('reading-filter-$value'),
                label: Text(labelOf(value)),
                selected: selected == value,
                onSelected: (_) => onSelect(value),
              ),
          ],
        ),
      ],
    );
  }
}

class _ArticleRow extends StatelessWidget {
  const _ArticleRow({
    required this.article,
    required this.language,
    required this.progress,
    required this.onTap,
  });

  final Article article;
  final String language;
  final ReadingProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final done = progress?.completed == true;
    final inProgress = !done && (progress?.lastParagraphIndex ?? 0) > 0;

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (article.titleTranslation.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              article.titleTranslation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Wrap(
            spacing: AppTokens.s8,
            runSpacing: AppTokens.s8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppPill(
                label: readingThemeLabel(l10n, article.theme),
                variant: PillVariant.primary,
              ),
              AppPill(
                label: readingLevelLabel(
                  language,
                  article.level,
                  examLevel: article.examLevel,
                ),
                variant: PillVariant.neutral,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    AppIcons.menuBook,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.readingMinutes(article.estimatedMinutes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              if (done)
                AppPill(
                  label: l10n.readingProgressDone,
                  icon: AppIcons.checkCircle,
                  variant: PillVariant.success,
                )
              else if (inProgress)
                AppPill(
                  label: l10n.readingProgressInProgress,
                  variant: PillVariant.streak,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.s24),
        child: Column(
          children: [
            Icon(
              AppIcons.autoStories,
              size: 40,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppTokens.s12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
