import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/services/pronunciation_service.dart';

void main() {
  test('Chinese skips youdao audio URL and uses local TTS only', () async {
    var audioCalled = false;
    var ttsLocale = '';
    final svc = PronunciationService(
      audio: (url) async { audioCalled = true; return true; },
      tts: (text, locale, slow) async { ttsLocale = locale; return true; },
    );
    final outcome = await svc.play(
        word: '你好', audioUrl: 'https://youdao/zh.mp3', language: 'zh');
    expect(audioCalled, isFalse);            // 不调有道
    expect(ttsLocale, 'zh-CN');
    expect(outcome, PronunciationOutcome.playedTts);
  });

  test('Non-Chinese still prefers the audio URL', () async {
    var audioCalled = false;
    final svc = PronunciationService(
      audio: (url) async { audioCalled = true; return true; },
      tts: (t, l, s) async => true,
    );
    final outcome = await svc.play(
        word: 'hello', audioUrl: 'https://youdao/en.mp3', language: 'en');
    expect(audioCalled, isTrue);
    expect(outcome, PronunciationOutcome.playedUrl);
  });
}
