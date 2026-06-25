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
  }) async {
    final trimmed = word.trim();
    if (audioUrl.trim().isNotEmpty) {
      final ok = await audio(audioUrl.trim());
      if (ok) return PronunciationOutcome.playedUrl;
    }
    if (trimmed.isEmpty) return PronunciationOutcome.failed;
    final language = containsCjkText(trimmed) ? 'zh-CN' : 'en-GB';
    final spoken = await tts(trimmed, language, slow);
    return spoken ? PronunciationOutcome.playedTts : PronunciationOutcome.failed;
  }
}
