import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/services/pronunciation_service.dart';

void main() {
  test('plays url when audioUrl present and url succeeds', () async {
    var ttsCalled = false;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, lang, slow) async {
        ttsCalled = true;
        return true;
      },
    );
    final outcome = await svc.play(word: 'hello', audioUrl: 'http://x/h.mp3');
    expect(outcome, PronunciationOutcome.playedUrl);
    expect(ttsCalled, isFalse);
  });

  test('falls back to TTS when no url', () async {
    String? lang;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, l, slow) async {
        lang = l;
        return true;
      },
    );
    final outcome = await svc.play(word: '你好');
    expect(outcome, PronunciationOutcome.playedTts);
    expect(lang, 'zh-CN');
  });

  test('falls back to TTS when url playback fails', () async {
    final svc = PronunciationService(
      audio: (url) async => false,
      tts: (text, lang, slow) async => true,
    );
    final outcome =
        await svc.play(word: 'hello', audioUrl: 'http://x/h.mp3');
    expect(outcome, PronunciationOutcome.playedTts);
  });

  test('english uses en language for tts', () async {
    String? lang;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, l, slow) async {
        lang = l;
        return true;
      },
    );
    await svc.play(word: 'hello');
    expect(lang, startsWith('en'));
  });

  test('returns failed when both url and tts fail', () async {
    final svc = PronunciationService(
      audio: (url) async => false,
      tts: (text, lang, slow) async => false,
    );
    final outcome =
        await svc.play(word: 'hello', audioUrl: 'http://x/h.mp3');
    expect(outcome, PronunciationOutcome.failed);
  });
}
