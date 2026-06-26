import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../core/state/app_controller.dart';
import '../../core/services/pronunciation_service.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_pill.dart';
import '../../data/models/article.dart';
import '../../data/repositories/article_repository.dart';
import '../../l10n/generated/app_localizations.dart';
import 'reading_labels.dart';

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
            onToggleTranslation: (v) => setState(() => _showTranslation = v),
            onToggleReading: (v) => setState(() => _showReading = v),
            onParagraphSeen: (index) =>
                _saveProgress(article.id, index, article.paragraphs.length),
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
    required this.onToggleTranslation,
    required this.onToggleReading,
    required this.onParagraphSeen,
  });

  final Article article;
  final bool showTranslation;
  final bool showReading;
  final ValueChanged<bool> onToggleTranslation;
  final ValueChanged<bool> onToggleReading;
  final ValueChanged<int> onParagraphSeen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = article.language;
    // Resolve curated vocab surfaces for tap-word matching.
    final vocabBySurface = <String, ArticleVocabRef>{
      for (final v in article.vocab)
        if (v.surface.isNotEmpty) v.surface: v,
    };

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
                    color: AppTokens.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppTokens.s12),
              ],
              _ToggleBar(
                showTranslation: showTranslation,
                showReading: showReading,
                onToggleTranslation: onToggleTranslation,
                onToggleReading: onToggleReading,
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                l10n.readingTapWordHint,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textHintLight,
                ),
              ),
              const SizedBox(height: AppTokens.s16),
              for (final paragraph in article.paragraphs)
                _ParagraphCard(
                  paragraph: paragraph,
                  language: language,
                  showTranslation: showTranslation,
                  showReading: showReading,
                  vocabBySurface: vocabBySurface,
                  onVisible: () => onParagraphSeen(paragraph.index),
                  onTapWord: (vocab) =>
                      _showWordSheet(context, ref, vocab, language),
                ),
              const SizedBox(height: AppTokens.s16),
              // Comprehension CTA placeholder — graded comprehension lands in
              // P3e, so this is intentionally disabled with a hint.
              AppPrimaryButton(
                label: l10n.readingComprehensionCta,
                icon: AppIcons.playlistAddCheck,
                onPressed: null,
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                l10n.readingComprehensionSoon,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTokens.textHintLight,
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Future<void> _showWordSheet(
    BuildContext context,
    WidgetRef ref,
    ArticleVocabRef vocab,
    String language,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => _WordSheet(
        vocab: vocab,
        language: language,
        article: article,
      ),
    );
  }
}

class _ToggleBar extends StatelessWidget {
  const _ToggleBar({
    required this.showTranslation,
    required this.showReading,
    required this.onToggleTranslation,
    required this.onToggleReading,
  });

  final bool showTranslation;
  final bool showReading;
  final ValueChanged<bool> onToggleTranslation;
  final ValueChanged<bool> onToggleReading;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: FilterChip(
            key: const ValueKey('reading-toggle-translation'),
            avatar: Icon(AppIcons.translate, size: 16),
            label: Text(l10n.readingToggleTranslation),
            selected: showTranslation,
            onSelected: onToggleTranslation,
          ),
        ),
        const SizedBox(width: AppTokens.s8),
        Expanded(
          child: FilterChip(
            key: const ValueKey('reading-toggle-reading'),
            avatar: Icon(AppIcons.article, size: 16),
            label: Text(l10n.readingToggleReading),
            selected: showReading,
            onSelected: onToggleReading,
          ),
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
    required this.vocabBySurface,
    required this.onVisible,
    required this.onTapWord,
  });

  final ArticleParagraph paragraph;
  final String language;
  final bool showTranslation;
  final bool showReading;
  final Map<String, ArticleVocabRef> vocabBySurface;
  final VoidCallback onVisible;
  final ValueChanged<ArticleVocabRef> onTapWord;

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
              vocabBySurface: widget.vocabBySurface,
              onTapWord: widget.onTapWord,
            ),
            if (widget.showTranslation &&
                widget.paragraph.translation.isNotEmpty) ...[
              const SizedBox(height: AppTokens.s8),
              Text(
                widget.paragraph.translation,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTokens.textSecondaryLight,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: AppTokens.s8),
            _ParagraphAudioButton(
              text: widget.paragraph.text,
              audioUrl: widget.paragraph.audioUrl,
              language: widget.language,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a paragraph as inline text where curated vocab surfaces are tappable
/// spans (rest plain). Longest-match against [vocabBySurface]; per-character
/// segmentation/highlight is P3d. Owns its [TapGestureRecognizer]s and disposes
/// them with the element.
class _ParagraphText extends StatefulWidget {
  const _ParagraphText({
    required this.text,
    required this.vocabBySurface,
    required this.onTapWord,
  });

  final String text;
  final Map<String, ArticleVocabRef> vocabBySurface;
  final ValueChanged<ArticleVocabRef> onTapWord;

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

    final surfaces = widget.vocabBySurface.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    final text = widget.text;
    final spans = <InlineSpan>[];
    var i = 0;
    final buffer = StringBuffer();

    void flushPlain() {
      if (buffer.isNotEmpty) {
        spans.add(TextSpan(text: buffer.toString()));
        buffer.clear();
      }
    }

    while (i < text.length) {
      String? matched;
      for (final surface in surfaces) {
        if (surface.isNotEmpty && text.startsWith(surface, i)) {
          matched = surface;
          break;
        }
      }
      if (matched != null) {
        flushPlain();
        final vocab = widget.vocabBySurface[matched]!;
        final recognizer = TapGestureRecognizer()
          ..onTap = () => widget.onTapWord(vocab);
        _recognizers.add(recognizer);
        spans.add(
          TextSpan(
            text: matched,
            style: TextStyle(
              color: AppTokens.azure,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
              decorationColor: AppTokens.azure.withValues(alpha: 0.4),
            ),
            recognizer: recognizer,
          ),
        );
        i += matched.length;
      } else {
        buffer.write(text[i]);
        i += 1;
      }
    }
    flushPlain();

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
        await _tts.speak(text);
        return true;
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
            : Icon(
                _failed ? AppIcons.refresh : AppIcons.volumeUp,
                size: 18,
              ),
        label: Text(l10n.readingParagraphAudio),
      ),
    );
  }
}

class _WordSheet extends ConsumerWidget {
  const _WordSheet({
    required this.vocab,
    required this.language,
    required this.article,
  });

  final ArticleVocabRef vocab;
  final String language;
  final Article article;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
                  vocab.surface,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              AppPill(
                label: readingLevelLabel(language, article.level,
                    examLevel: article.examLevel),
                variant: PillVariant.neutral,
              ),
            ],
          ),
          if (vocab.reading.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              vocab.reading,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTokens.primarySoftText,
              ),
            ),
          ],
          const SizedBox(height: AppTokens.s12),
          Text(
            vocab.meaning.isEmpty ? '—' : vocab.meaning,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: AppTokens.s20),
          AppPrimaryButton(
            label: l10n.readingWordAddToVocab,
            icon: AppIcons.bookmark,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              await ref.read(appControllerProvider.notifier).addCustomWord(
                    word: vocab.surface,
                    meaning: vocab.meaning,
                    exampleSentence: '',
                    note: vocab.reading,
                    tag: '阅读',
                    difficulty: 'medium',
                  );
              navigator.pop();
              messenger.showSnackBar(
                SnackBar(content: Text(l10n.readingWordAdded)),
              );
            },
          ),
        ],
      ),
    );
  }
}
