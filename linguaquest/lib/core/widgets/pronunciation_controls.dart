import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../../l10n/generated/app_localizations.dart';
import '../services/pronunciation_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../utils/text_language.dart';

enum _PronunciationAccent { uk, us }

String _accentLabel(AppLocalizations l10n, _PronunciationAccent accent) {
  switch (accent) {
    case _PronunciationAccent.uk:
      return l10n.pronunciationAccentUk;
    case _PronunciationAccent.us:
      return l10n.pronunciationAccentUs;
  }
}

class PronunciationControls extends StatefulWidget {
  const PronunciationControls({
    required this.word,
    this.audioUKUrl = '',
    this.audioUSUrl = '',
    this.compact = false,
    super.key,
  });

  final String word;
  final String audioUKUrl;
  final String audioUSUrl;
  final bool compact;

  @override
  State<PronunciationControls> createState() => _PronunciationControlsState();
}

class _PronunciationControlsState extends State<PronunciationControls> {
  _PronunciationAccent? _loadingAccent;
  _PronunciationAccent? _failedAccent;
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
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
    tts: (text, lang, slow) async {
      try {
        await _tts.setLanguage(lang);
        await _tts.setSpeechRate(slow ? 0.4 : 0.5);
        await _tts.stop();
        await _tts.speak(text);
        return true;
      } catch (_) {
        return false;
      }
    },
  );

  @override
  void didUpdateWidget(covariant PronunciationControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.word != widget.word ||
        oldWidget.audioUKUrl != widget.audioUKUrl ||
        oldWidget.audioUSUrl != widget.audioUSUrl) {
      _loadingAccent = null;
      _failedAccent = null;
      _player.stop();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failedAccent = _failedAccent;

    // Chinese (HSK) words have a single Mandarin pronunciation — show one
    // button instead of the UK/US pair.
    if (containsCjkText(widget.word)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _PronunciationButton(
                accent: _PronunciationAccent.us,
                compact: widget.compact,
                isLoading: _loadingAccent != null && !_isSlow,
                hasFailed: failedAccent != null && !_isSlow,
                onPressed: () => _play(_PronunciationAccent.us),
                labelOverride: 'Audio',
              ),
              const SizedBox(width: 8),
              _SlowButton(
                compact: widget.compact,
                isLoading: _loadingAccent != null && _isSlow,
                onPressed: () => _play(_PronunciationAccent.us, slow: true),
              ),
            ],
          ),
          if (failedAccent != null) ...[
            const SizedBox(height: 6),
            Text(
              'Audio unavailable, tap to retry.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PronunciationButton(
              accent: _PronunciationAccent.uk,
              compact: widget.compact,
              isLoading: _loadingAccent == _PronunciationAccent.uk && !_isSlow,
              hasFailed: failedAccent == _PronunciationAccent.uk,
              onPressed: () => _play(_PronunciationAccent.uk),
            ),
            const SizedBox(width: 8),
            _PronunciationButton(
              accent: _PronunciationAccent.us,
              compact: widget.compact,
              isLoading: _loadingAccent == _PronunciationAccent.us && !_isSlow,
              hasFailed: failedAccent == _PronunciationAccent.us,
              onPressed: () => _play(_PronunciationAccent.us),
            ),
            const SizedBox(width: 8),
            _SlowButton(
              compact: widget.compact,
              isLoading: _loadingAccent != null && _isSlow,
              onPressed: () => _play(
                _lastAccent ?? _PronunciationAccent.us,
                slow: true,
              ),
            ),
          ],
        ),
        if (failedAccent != null) ...[
          const SizedBox(height: 6),
          Text(
            l10n.pronunciationFailedRetry(_accentLabel(l10n, failedAccent)),
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }

  _PronunciationAccent? _lastAccent;
  bool _isSlow = false;

  Future<void> _play(_PronunciationAccent accent, {bool slow = false}) async {
    if (_loadingAccent != null) return;
    final view = View.of(context);
    final l10n = AppLocalizations.of(context);
    final accentLabel = _accentLabel(l10n, accent);
    setState(() {
      _loadingAccent = accent;
      _failedAccent = null;
      _isSlow = slow;
      _lastAccent = accent;
    });

    final word = widget.word.trim();
    final audioUrl = switch (accent) {
      _PronunciationAccent.uk => widget.audioUKUrl.trim(),
      _PronunciationAccent.us => widget.audioUSUrl.trim(),
    };
    final hasWord = word.isNotEmpty;

    if (hasWord) {
      await HapticFeedback.selectionClick();
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        view,
        l10n.pronunciationAnnounce(accentLabel, word),
        TextDirection.ltr,
      );
    }

    final outcome = await _service.play(word: word, audioUrl: audioUrl, slow: slow);
    if (!mounted || widget.word.trim() != word) return;

    setState(() {
      _loadingAccent = null;
      _isSlow = false;
      _failedAccent = outcome == PronunciationOutcome.failed ? accent : null;
    });
  }
}

class _SlowButton extends StatelessWidget {
  const _SlowButton({
    required this.compact,
    required this.isLoading,
    required this.onPressed,
  });

  final bool compact;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return OutlinedButton.icon(
      key: const ValueKey('pronunciation-slow'),
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(compact ? 64 : 72, compact ? 36 : 40),
        padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11),
        foregroundColor: AppTheme.teal,
        disabledForegroundColor: AppTheme.teal.withValues(alpha: 0.72),
        backgroundColor: isLoading
            ? AppTheme.selectedSurface(context)
            : Colors.transparent,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
        ),
      ),
      icon: isLoading
          ? SizedBox.square(
              dimension: compact ? 13 : 15,
              child: CircularProgressIndicator(strokeWidth: compact ? 2 : 2.2),
            )
          : Icon(Icons.slow_motion_video, size: compact ? 16 : 18),
      label: Text(isLoading ? 'Loading…' : '0.5×'),
    );
  }
}

class _PronunciationButton extends StatelessWidget {
  const _PronunciationButton({
    required this.accent,
    required this.compact,
    required this.isLoading,
    required this.hasFailed,
    required this.onPressed,
    this.labelOverride,
  });

  final _PronunciationAccent accent;
  final bool compact;
  final bool isLoading;
  final bool hasFailed;
  final VoidCallback onPressed;

  /// When set, the button shows this label (and neutral loading/retry text)
  /// instead of the UK/US accent label — used for the single Chinese button.
  final String? labelOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final accentLabel = _accentLabel(l10n, accent);
    final color = hasFailed ? theme.colorScheme.error : AppTheme.teal;
    return OutlinedButton.icon(
      key: ValueKey('pronunciation-${accent.name}'),
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: Size(compact ? 64 : 72, compact ? 36 : 40),
        padding: EdgeInsets.symmetric(horizontal: compact ? 9 : 11),
        foregroundColor: color,
        disabledForegroundColor: color.withValues(alpha: 0.72),
        backgroundColor: isLoading
            ? AppTheme.selectedSurface(context)
            : Colors.transparent,
        side: BorderSide(color: theme.colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 12 : 14),
        ),
      ),
      icon: isLoading
          ? SizedBox.square(
              dimension: compact ? 13 : 15,
              child: CircularProgressIndicator(strokeWidth: compact ? 2 : 2.2),
            )
          : Icon(
              hasFailed ? AppIcons.refresh : AppIcons.volumeUp,
              size: compact ? 16 : 18,
            ),
      label: Text(
        isLoading
            ? (labelOverride == null
                  ? l10n.pronunciationLoading(accentLabel)
                  : 'Loading…')
            : hasFailed
            ? (labelOverride == null
                  ? l10n.pronunciationRetry(accentLabel)
                  : 'Retry')
            : (labelOverride ?? accentLabel),
      ),
    );
  }
}
