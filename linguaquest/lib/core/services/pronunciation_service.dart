import '../constants/app_constants.dart';
import '../utils/text_language.dart';

/// Plays an audio URL; returns true on success.
typedef AudioSink = Future<bool> Function(String url);

/// Speaks [text] in [language] (slow if true); returns true on success.
typedef TtsSink = Future<bool> Function(String text, String language, bool slow);

enum PronunciationOutcome { playedUrl, playedTts, failed }

class PronunciationService {
  PronunciationService({
    required this.audio,
    required this.tts,
    String? apiBaseUrl,
  }) : _apiBaseUrl = apiBaseUrl ?? AppConstants.apiBaseUrl;

  final AudioSink audio;
  final TtsSink tts;
  final String _apiBaseUrl;

  Future<PronunciationOutcome> play({
    required String word,
    String audioUrl = '',
    bool slow = false,
    String language = '',
  }) async {
    final trimmed = word.trim();
    final ttsLocale = _resolveTtsLocale(language, trimmed);

    // CJK languages (zh, ja) skip external dictionary audio (e.g. youdao URLs)
    // and go straight to server TTS or local TTS. English words may carry real
    // dictionary audio (UK/US accent) which retains its original priority.
    final isCjkLanguage = ttsLocale == 'zh-CN' || ttsLocale == 'ja-JP';

    // Step 1: Non-CJK with a real external audio URL — try it first.
    if (!isCjkLanguage && audioUrl.trim().isNotEmpty) {
      final ok = await audio(audioUrl.trim());
      if (ok) return PronunciationOutcome.playedUrl;
    }

    if (trimmed.isEmpty) return PronunciationOutcome.failed;

    // Step 2: If a backend is configured, use server TTS (covers zh, ja, and
    // en words without an external URL, or whose external URL failed above).
    if (_apiBaseUrl.isNotEmpty) {
      final lang = _toServerLang(ttsLocale);
      final serverUrl =
          '$_apiBaseUrl/tts?text=${Uri.encodeComponent(trimmed)}&lang=$lang&slow=$slow';
      final ok = await audio(serverUrl);
      if (ok) return PronunciationOutcome.playedUrl;
    }

    // Step 3: Fallback — local flutter_tts.
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

  /// Maps a TTS locale to the lang parameter accepted by the /tts endpoint.
  String _toServerLang(String ttsLocale) {
    switch (ttsLocale) {
      case 'zh-CN':
        return 'zh';
      case 'ja-JP':
        return 'ja';
      default:
        return 'en';
    }
  }
}
