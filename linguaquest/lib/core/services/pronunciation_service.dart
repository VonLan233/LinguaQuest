import '../utils/text_language.dart';

/// Plays an audio URL; returns true on success.
typedef AudioSink = Future<bool> Function(String url);

/// Speaks [text] in [language] (slow if true); returns true on success.
typedef TtsSink = Future<bool> Function(String text, String language, bool slow);

enum PronunciationOutcome { playedUrl, playedTts, failed }

class PronunciationService {
  PronunciationService({required this.audio, required this.tts});

  final AudioSink audio;
  final TtsSink tts;

  Future<PronunciationOutcome> play({
    required String word,
    String audioUrl = '',
    bool slow = false,
    String language = '',
  }) async {
    final trimmed = word.trim();
    final ttsLocale = _resolveTtsLocale(language, trimmed);
    // #15: 中文场景只用本地 flutter_tts（跳过慢/不稳的有道音频）。
    final chineseTtsOnly = ttsLocale == 'zh-CN';
    if (!chineseTtsOnly && audioUrl.trim().isNotEmpty) {
      final ok = await audio(audioUrl.trim());
      if (ok) return PronunciationOutcome.playedUrl;
    }
    if (trimmed.isEmpty) return PronunciationOutcome.failed;
    final spoken = await tts(trimmed, ttsLocale, slow);
    return spoken ? PronunciationOutcome.playedTts : PronunciationOutcome.failed;
  }

  /// Maps a learning-language code to a TTS locale. Known languages win over
  /// CJK auto-detection so kana-only Japanese routes to ja-JP, not the
  /// zh-CN/en-GB fallback used when [language] is empty/unknown.
  String _resolveTtsLocale(String language, String text) {
    switch (language) {
      case 'ja':
        return 'ja-JP';
      case 'zh':
        return 'zh-CN';
      default:
        return containsCjkText(text) ? 'zh-CN' : 'en-GB';
    }
  }
}
