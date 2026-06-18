import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failedAccent = _failedAccent;
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
              isLoading: _loadingAccent == _PronunciationAccent.uk,
              hasFailed: failedAccent == _PronunciationAccent.uk,
              onPressed: () => _play(_PronunciationAccent.uk),
            ),
            const SizedBox(width: 8),
            _PronunciationButton(
              accent: _PronunciationAccent.us,
              compact: widget.compact,
              isLoading: _loadingAccent == _PronunciationAccent.us,
              hasFailed: failedAccent == _PronunciationAccent.us,
              onPressed: () => _play(_PronunciationAccent.us),
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

  Future<void> _play(_PronunciationAccent accent) async {
    if (_loadingAccent != null) return;
    final view = View.of(context);
    final l10n = AppLocalizations.of(context);
    final accentLabel = _accentLabel(l10n, accent);
    setState(() {
      _loadingAccent = accent;
      _failedAccent = null;
    });

    final word = widget.word.trim();
    final audioUrl = switch (accent) {
      _PronunciationAccent.uk => widget.audioUKUrl.trim(),
      _PronunciationAccent.us => widget.audioUSUrl.trim(),
    };
    final hasWord = word.isNotEmpty;
    final hasAudioUrl = audioUrl.isNotEmpty;

    if (hasWord) {
      await HapticFeedback.selectionClick();
      if (!mounted) return;
      SemanticsService.sendAnnouncement(
        view,
        l10n.pronunciationAnnounce(accentLabel, word),
        TextDirection.ltr,
      );
    }

    if (hasAudioUrl) {
      try {
        await _player.stop();
        if (!mounted || widget.word.trim() != word) return;
        await _player.play(UrlSource(audioUrl));
        if (!mounted || widget.word.trim() != word) return;
        setState(() {
          _loadingAccent = null;
          _failedAccent = null;
        });
        _showMessage(l10n.pronunciationPlaying(accentLabel, word));
      } catch (_) {
        if (!mounted || widget.word.trim() != word) return;
        setState(() {
          _loadingAccent = null;
          _failedAccent = accent;
        });
        _showMessage(l10n.pronunciationFailedRetry(accentLabel));
      }
    } else {
      if (!mounted || widget.word.trim() != word) return;
      setState(() {
        _loadingAccent = null;
        _failedAccent = hasWord ? null : accent;
      });
      final message = hasWord
          ? l10n.pronunciationPlaying(accentLabel, word)
          : l10n.pronunciationUnavailable(accentLabel);
      _showMessage(message);
    }
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.clearSnackBars();
    messenger?.showSnackBar(
      SnackBar(
        duration: const Duration(milliseconds: 1200),
        content: Text(message),
      ),
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
  });

  final _PronunciationAccent accent;
  final bool compact;
  final bool isLoading;
  final bool hasFailed;
  final VoidCallback onPressed;

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
            ? l10n.pronunciationLoading(accentLabel)
            : hasFailed
            ? l10n.pronunciationRetry(accentLabel)
            : accentLabel,
      ),
    );
  }
}
