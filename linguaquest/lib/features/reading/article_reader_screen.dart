import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/services/pronunciation_service.dart';
import '../../core/services/tts_completion.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/ai_error_card.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pill.dart';
import '../../data/models/article.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/user_word.dart';
import '../../data/repositories/article_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'reading_comprehension_screen.dart';
import 'reading_highlight_style.dart';
import 'reading_labels.dart';
import 'word_segmenter.dart';

/// Article reader (P3c): per-paragraph text with translation + reading toggles,
/// per-paragraph audio, tappable curated vocab surfaces (meaning sheet +
/// add-to-vocab), and scroll-based reading-progress save/restore.
class ArticleReaderScreen extends ConsumerStatefulWidget {
  const ArticleReaderScreen({required this.articleId, super.key});

  final String articleId;

  @override
  ConsumerState<ArticleReaderScreen> createState() =>
      _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends ConsumerState<ArticleReaderScreen> {
  late Future<_ReaderData> _future;

  // Local per-reader toggle state.
  bool _showTranslation = true;
  bool _showReading = true;
  bool _showHighlight = true;

  int _lastSavedIndex = -1;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ReaderData> _load() async {
    final controller = ref.read(appControllerProvider.notifier);
    final article = await controller.getArticle(widget.articleId);
    ReadingProgress? resume;
    if (article != null) {
      final all = await controller.readingProgressForScope();
      for (final p in all) {
        if (p.articleId == article.id) {
          resume = p;
          break;
        }
      }
    }
    return _ReaderData(article: article, resume: resume);
  }

  // #C3: 答题时隐藏正文翻译，答题结束后恢复；#D: 完成后 pop 回列表
  Future<void> _startComprehension(Article article) async {
    final prevShowTranslation = _showTranslation;
    setState(() => _showTranslation = false);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: ReadingComprehensionSheet(article: article),
      ),
    );
    if (!mounted) return;
    setState(() => _showTranslation = prevShowTranslation);
    if (result == true) Navigator.of(context).pop();
  }

  /// Persist progress for [paragraphIndex] (debounced by index change).
  void _saveProgress(String articleId, int paragraphIndex, int paragraphCount) {
    if (paragraphIndex <= _lastSavedIndex) return;
    _lastSavedIndex = paragraphIndex;
    final done = paragraphIndex >= paragraphCount - 1;
    ref
        .read(appControllerProvider.notifier)
        .saveReadingProgress(articleId, paragraphIndex, done: done);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: FutureBuilder<_ReaderData>(
        future: _future,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final article = snapshot.data!.article;
          if (article == null) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text(l10n.readingEmpty)),
            );
          }
          // Record that the resume position has been honoured so the first
          // visible paragraph doesn't immediately overwrite a later position.
          _lastSavedIndex = snapshot.data!.resume?.lastParagraphIndex ?? -1;
          return _ReaderBody(
            article: article,
            showTranslation: _showTranslation,
            showReading: _showReading,
            showHighlight: _showHighlight,
            onToggleTranslation: (v) => setState(() => _showTranslation = v),
            onToggleReading: (v) => setState(() => _showReading = v),
            onToggleHighlight: (v) => setState(() => _showHighlight = v),
            onParagraphSeen: (index) =>
                _saveProgress(article.id, index, article.paragraphs.length),
            onStartComprehension: () => _startComprehension(article),
          );
        },
      ),
    );
  }
}

class _ReaderData {
  const _ReaderData({required this.article, required this.resume});

  final Article? article;
  final ReadingProgress? resume;
}

class _ReaderBody extends ConsumerWidget {
  const _ReaderBody({
    required this.article,
    required this.showTranslation,
    required this.showReading,
    required this.showHighlight,
    required this.onToggleTranslation,
    required this.onToggleReading,
    required this.onToggleHighlight,
    required this.onParagraphSeen,
    required this.onStartComprehension,
  });

  final Article article;
  final bool showTranslation;
  final bool showReading;
  final bool showHighlight;
  final ValueChanged<bool> onToggleTranslation;
  final ValueChanged<bool> onToggleReading;
  final ValueChanged<bool> onToggleHighlight;
  final ValueChanged<int> onParagraphSeen;
  final Future<void> Function() onStartComprehension;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = article.language;

    // P3d: build the highlight index + classification inputs from app state.
    final wordBook = ref.watch(
      appControllerProvider.select((s) => s.currentWordBook),
    );
    final userWords = ref.watch(
      appControllerProvider.select((s) => s.userWords),
    );
    final reviewWords = ref.watch(
      appControllerProvider.select((s) => s.reviewWords),
    );
    final highlightVocab = buildHighlightVocab(
      article: article,
      wordBook: wordBook,
    );

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          expandedHeight: 132,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.fromLTRB(
              AppTokens.s16,
              0,
              AppTokens.s16,
              AppTokens.s12,
            ),
            title: Text(
              article.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s16,
            AppTokens.s20,
            88,
          ),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (article.titleTranslation.isNotEmpty && showTranslation) ...[
                Text(
                  article.titleTranslation,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
              ],
              _ToggleBar(
                showTranslation: showTranslation,
                showReading: showReading,
                showHighlight: showHighlight,
                onToggleTranslation: onToggleTranslation,
                onToggleReading: onToggleReading,
                onToggleHighlight: onToggleHighlight,
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                l10n.readingTapWordHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (showHighlight && !highlightVocab.isEmpty) ...[
                const SizedBox(height: AppTokens.s8),
                const _HighlightLegend(),
              ],
              const SizedBox(height: AppTokens.s16),
              for (final paragraph in article.paragraphs)
                _ParagraphCard(
                  paragraph: paragraph,
                  language: language,
                  showTranslation: showTranslation,
                  showReading: showReading,
                  showHighlight: showHighlight,
                  highlightVocab: highlightVocab,
                  userWords: userWords,
                  reviewWords: reviewWords,
                  onVisible: () => onParagraphSeen(paragraph.index),
                  onTapWord: (token) =>
                      _showWordSheet(context, ref, token, language),
                  onExplain: () =>
                      _showExplainSheet(context, ref, paragraph.text, language),
                ),
              const SizedBox(height: AppTokens.s16),
              // P3e: graded comprehension over article.comprehension, reusing the
              // quiz choice UI.
              AppPrimaryButton(
                key: const ValueKey('reading-comprehension-cta'),
                label: l10n.readingComprehensionStart,
                icon: AppIcons.playlistAddCheck,
                onPressed: article.comprehension.isEmpty
                    ? null
                    : onStartComprehension,
              ),
              if (article.comprehension.isEmpty) ...[
                const SizedBox(height: AppTokens.s8),
                Text(
                  l10n.readingComprehensionEmpty,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _showWordSheet(
    BuildContext context,
    WidgetRef ref,
    ReadingToken token,
    String language,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) =>
          _WordSheet(token: token, language: language, article: article),
    );
  }

  /// P3f: opens the AI per-paragraph explanation sheet. The explain runs in the
  /// article's [language] (not the global target-language setting), and reuses the
  /// existing AI pipeline via [AppController.explainParagraph].
  Future<void> _showExplainSheet(
    BuildContext context,
    WidgetRef ref,
    String paragraphText,
    String language,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) =>
          _ExplainSheet(paragraphText: paragraphText, language: language),
    );
  }
}

/// A small legend mapping highlight colors to word classes (P3d).
class _HighlightLegend extends StatelessWidget {
  const _HighlightLegend();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const classes = [
      WordClass.key,
      WordClass.unknown,
      WordClass.newWord,
      WordClass.known,
    ];
    return Wrap(
      spacing: AppTokens.s12,
      runSpacing: 6,
      children: [
        for (final cls in classes)
          _LegendChip(
            label: readingClassLabel(l10n, cls),
            style: ReadingHighlightStyle.forClass(cls),
          ),
      ],
    );
  }
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.label, required this.style});

  final String label;
  final ReadingHighlightStyle style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: style.color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ToggleBar extends StatelessWidget {
  const _ToggleBar({
    required this.showTranslation,
    required this.showReading,
    required this.showHighlight,
    required this.onToggleTranslation,
    required this.onToggleReading,
    required this.onToggleHighlight,
  });

  final bool showTranslation;
  final bool showReading;
  final bool showHighlight;
  final ValueChanged<bool> onToggleTranslation;
  final ValueChanged<bool> onToggleReading;
  final ValueChanged<bool> onToggleHighlight;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: [
        FilterChip(
          key: const ValueKey('reading-toggle-translation'),
          avatar: Icon(AppIcons.translate, size: 16),
          label: Text(l10n.readingToggleTranslation),
          selected: showTranslation,
          onSelected: onToggleTranslation,
        ),
        FilterChip(
          key: const ValueKey('reading-toggle-reading'),
          avatar: Icon(AppIcons.article, size: 16),
          label: Text(l10n.readingToggleReading),
          selected: showReading,
          onSelected: onToggleReading,
        ),
        FilterChip(
          key: const ValueKey('reading-toggle-highlight'),
          avatar: Icon(AppIcons.autoAwesome, size: 16),
          label: Text(l10n.readingToggleHighlight),
          selected: showHighlight,
          onSelected: onToggleHighlight,
        ),
      ],
    );
  }
}

class _ParagraphCard extends StatefulWidget {
  const _ParagraphCard({
    required this.paragraph,
    required this.language,
    required this.showTranslation,
    required this.showReading,
    required this.showHighlight,
    required this.highlightVocab,
    required this.userWords,
    required this.reviewWords,
    required this.onVisible,
    required this.onTapWord,
    required this.onExplain,
  });

  final ArticleParagraph paragraph;
  final String language;
  final bool showTranslation;
  final bool showReading;
  final bool showHighlight;
  final HighlightVocab highlightVocab;
  final List<UserWord> userWords;
  final List<CustomWord> reviewWords;
  final VoidCallback onVisible;
  final ValueChanged<ReadingToken> onTapWord;
  final VoidCallback onExplain;

  @override
  State<_ParagraphCard> createState() => _ParagraphCardState();
}

class _ParagraphCardState extends State<_ParagraphCard> {
  @override
  void initState() {
    super.initState();
    // A paragraph rendered into the list counts as "seen" — the longest index
    // wins in the controller, so this approximates scroll progress simply.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onVisible();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showReading && widget.paragraph.reading.isNotEmpty) ...[
              Text(
                widget.paragraph.reading,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTokens.primarySoftText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
            ],
            _ParagraphText(
              text: widget.paragraph.text,
              language: widget.language,
              showHighlight: widget.showHighlight,
              highlightVocab: widget.highlightVocab,
              userWords: widget.userWords,
              reviewWords: widget.reviewWords,
              onTapWord: widget.onTapWord,
            ),
            if (widget.showTranslation &&
                widget.paragraph.translation.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s8),
              Text(
                widget.paragraph.translation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppTokens.s8),
            Row(
              children: [
                _ParagraphAudioButton(
                  text: widget.paragraph.text,
                  audioUrl: widget.paragraph.audioUrl,
                  language: widget.language,
                ),
                const Spacer(),
                IconButton(
                  key: ValueKey('reading-explain-${widget.paragraph.index}'),
                  icon: const Icon(AppIcons.autoAwesome),
                  iconSize: 20,
                  color: theme.colorScheme.primary,
                  tooltip: AppLocalizations.of(context).readingExplainTooltip,
                  onPressed: widget.onExplain,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a paragraph as inline text using longest-match tokenization (P3d):
/// matched curated/wordbook surfaces are highlighted per [WordClass] and tappable
/// (opening their meaning); unmatched runs fall back to plain per-character text.
/// When [showHighlight] is off, the whole paragraph is rendered as plain text
/// (no colors, no tappable spans). Owns its [TapGestureRecognizer]s and disposes
/// them with the element.
class _ParagraphText extends StatefulWidget {
  const _ParagraphText({
    required this.text,
    required this.language,
    required this.showHighlight,
    required this.highlightVocab,
    required this.userWords,
    required this.reviewWords,
    required this.onTapWord,
  });

  final String text;
  final String language;
  final bool showHighlight;
  final HighlightVocab highlightVocab;
  final List<UserWord> userWords;
  final List<CustomWord> reviewWords;
  final ValueChanged<ReadingToken> onTapWord;

  @override
  State<_ParagraphText> createState() => _ParagraphTextState();
}

class _ParagraphTextState extends State<_ParagraphText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.titleMedium?.copyWith(
      height: 1.6,
      fontWeight: FontWeight.w500,
    );

    // Reset recognizers each build (toggles/relayout) to avoid stale closures.
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    // Highlight off → plain reading.
    if (!widget.showHighlight) {
      return Text(widget.text, style: baseStyle);
    }

    final tokens = segmentParagraph(
      text: widget.text,
      vocab: widget.highlightVocab,
      userWords: widget.userWords,
      reviewWords: widget.reviewWords,
    );

    final spans = <InlineSpan>[];
    for (final token in tokens) {
      if (!token.isMatched) {
        spans.add(TextSpan(text: token.text));
        continue;
      }
      final style = ReadingHighlightStyle.forClass(token.wordClass);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => widget.onTapWord(token);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: token.text,
          style: TextStyle(
            color: style.color,
            backgroundColor: style.background,
            fontWeight: style.bold ? FontWeight.w800 : FontWeight.w600,
            decoration: style.underline
                ? TextDecoration.underline
                : TextDecoration.none,
            decorationColor: style.color.withValues(alpha: 0.5),
          ),
          recognizer: recognizer,
        ),
      );
    }

    return Text.rich(TextSpan(style: baseStyle, children: spans));
  }
}

class _ParagraphAudioButton extends StatefulWidget {
  const _ParagraphAudioButton({
    required this.text,
    required this.audioUrl,
    required this.language,
  });

  final String text;
  final String audioUrl;
  final String language;

  @override
  State<_ParagraphAudioButton> createState() => _ParagraphAudioButtonState();
}

class _ParagraphAudioButtonState extends State<_ParagraphAudioButton> {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  bool _loading = false;
  bool _failed = false;

  late final PronunciationService _service = PronunciationService(
    audio: (url) async {
      try {
        await _player.stop();
        await _player.play(UrlSource(url));
        return true;
      } catch (_) {
        return false;
      }
    },
    tts: (text, _, slow) async {
      try {
        // Speak in the article language (zh-CN / ja-JP) rather than the
        // CJK-default the service infers.
        await _tts.setLanguage(_ttsLanguage(widget.language));
        await _tts.setSpeechRate(slow ? 0.4 : 0.5);
        await _tts.stop();
        return await awaitTtsCompletion(
          registerCompletion: (cb) => _tts.setCompletionHandler(cb),
          registerError: (cb) => _tts.setErrorHandler((_) => cb()),
          speak: () => _tts.speak(text),
        );
      } catch (_) {
        return false;
      }
    },
  );

  static String _ttsLanguage(String language) {
    switch (language) {
      case 'ja':
        return 'ja-JP';
      case 'zh':
        return 'zh-CN';
      default:
        return language;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  Future<void> _play() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final outcome = await _service.play(
      word: widget.text,
      audioUrl: widget.audioUrl,
      language: widget.language,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      _failed = outcome == PronunciationOutcome.failed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: const ValueKey('reading-paragraph-audio'),
        onPressed: _loading ? null : _play,
        icon: _loading
            ? const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(_failed ? AppIcons.refresh : AppIcons.volumeUp, size: 18),
        label: Text(l10n.readingParagraphAudio),
      ),
    );
  }
}

class _WordSheet extends ConsumerWidget {
  const _WordSheet({
    required this.token,
    required this.language,
    required this.article,
  });

  final ReadingToken token;
  final String language;
  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    // Resolve surface/reading/meaning from the token (curated vocab or wordbook
    // Word) so tapping any matched word shows its meaning.
    final surface = token.text;
    final reading = token.readingFor(language);
    final meaning = token.meaningFor(localeCode);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        0,
        AppTokens.s20,
        AppTokens.s24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  surface,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppPill(
                label: readingLevelLabel(
                  language,
                  article.level,
                  examLevel: article.examLevel,
                ),
                variant: PillVariant.neutral,
              ),
            ],
          ),
          if (reading.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              reading,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTokens.primarySoftText,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Text(
            meaning.isEmpty ? '—' : meaning,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.s20),
          AppPrimaryButton(
            label: l10n.readingWordAddToVocab,
            icon: AppIcons.bookmark,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final router = GoRouter.of(context);
              final navigator = Navigator.of(context);
              await ref
                  .read(appControllerProvider.notifier)
                  .addCustomWord(
                    word: surface,
                    meaning: meaning,
                    exampleSentence: '',
                    note: reading,
                    tag: 'Reading',
                    difficulty: 'medium',
                  );
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(l10n.readingWordAdded),
                  action: SnackBarAction(
                    label: l10n.commonView,
                    onPressed: () => router.push('/custom-words'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// P3f: AI per-paragraph explanation bottom sheet. Owns the loading/error/result
/// state for one explain request and reuses [AiErrorCard] for error + retry,
/// mirroring `ai_sentence_analysis_screen.dart`'s flow.
class _ExplainSheet extends ConsumerStatefulWidget {
  const _ExplainSheet({required this.paragraphText, required this.language});

  final String paragraphText;
  final String language;

  @override
  ConsumerState<_ExplainSheet> createState() => _ExplainSheetState();
}

class _ExplainSheetState extends ConsumerState<_ExplainSheet> {
  Map<String, dynamic>? _result;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });
    final result = await ref
        .read(appControllerProvider.notifier)
        .explainParagraph(
          paragraph: widget.paragraphText,
          language: widget.language,
        );
    if (!mounted) return;
    if (result.isEmpty) {
      final errMsg = ref.read(appControllerProvider).errorMessage;
      setState(() {
        _isLoading = false;
        _errorMessage = errMsg ?? AppLocalizations.of(context).aiErrorGeneric;
      });
    } else {
      setState(() {
        _isLoading = false;
        _result = result;
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppTokens.s20,
        0,
        AppTokens.s20,
        AppTokens.s20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    AppIcons.autoAwesome,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppTokens.s8),
                  Text(
                    l10n.readingExplainTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.s12),
              if (_isLoading)
                Padding(
                  key: const ValueKey('reading-explain-loading'),
                  padding: const EdgeInsets.symmetric(vertical: AppTokens.s24),
                  child: Center(
                    child: Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: AppTokens.s12),
                        Text(
                          l10n.readingExplainLoading,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_errorMessage != null)
                AiErrorCard(
                  key: const ValueKey('reading-explain-error'),
                  message: _errorMessage!,
                  onRetry: _run,
                )
              else if (_result != null)
                _ExplainResultCard(result: _result!),
            ],
          ),
        ),
      ),
    );
  }
}

/// Renders the structured `reading_explain` result: gist / key words / grammar
/// points / sentence structure / translation / practice. Styled to match
/// `ai_sentence_analysis_screen.dart`'s `_AnalysisResultCard`.
class _ExplainResultCard extends StatelessWidget {
  const _ExplainResultCard({required this.result});

  final Map<String, dynamic> result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final gist = result['gist'] as String? ?? '';
    final structure = result['structure'] as String? ?? '';
    final translation = result['translation'] as String? ?? '';
    final grammarPoints =
        (result['grammarPoints'] as List<dynamic>?)?.cast<dynamic>() ??
        const [];
    final keyWords =
        (result['keyWords'] as List<dynamic>?)?.cast<dynamic>() ?? const [];
    final practice =
        (result['practice'] as List<dynamic>?)?.cast<dynamic>() ?? const [];

    final keyWordLines = keyWords
        .map((w) {
          final m = (w as Map).cast<String, dynamic>();
          final word = m['word'] as String? ?? '';
          final reading = m['reading'] as String? ?? '';
          final meaning = m['meaning'] as String? ?? '';
          final readingPart = reading.isEmpty ? '' : ' [$reading]';
          return '$word$readingPart — $meaning';
        })
        .join('\n');

    final practiceLines = practice
        .map((p) {
          final m = (p as Map).cast<String, dynamic>();
          final prompt = m['prompt'] as String? ?? '';
          final answer = m['answer'] as String? ?? '';
          final options =
              (m['options'] as List<dynamic>?)?.cast<String>() ?? const [];
          final optionsPart = options.isEmpty
              ? ''
              : '\n  (${options.join(' / ')})';
          return '$prompt$optionsPart\n  ✓ $answer';
        })
        .join('\n\n');

    return AppCard(
      key: const ValueKey('reading-explain-result'),
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gist.isNotEmpty)
            _ExplainSection(label: l10n.readingExplainGist, content: gist),
          if (keyWordLines.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _ExplainSection(
              label: l10n.readingExplainKeyWords,
              content: keyWordLines,
            ),
          ],
          if (grammarPoints.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _ExplainSection(
              label: l10n.readingExplainGrammar,
              content: grammarPoints.map((e) => '• $e').join('\n'),
            ),
          ],
          if (structure.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _ExplainSection(
              label: l10n.readingExplainStructure,
              content: structure,
            ),
          ],
          if (translation.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _ExplainSection(
              label: l10n.readingExplainTranslation,
              content: translation,
            ),
          ],
          if (practiceLines.isNotEmpty) ...[
            const SizedBox(height: AppTokens.s8),
            _ExplainSection(
              label: l10n.readingExplainPractice,
              content: practiceLines,
            ),
          ],
        ],
      ),
    );
  }
}

class _ExplainSection extends StatelessWidget {
  const _ExplainSection({required this.label, required this.content});

  final String label;
  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(content, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}
