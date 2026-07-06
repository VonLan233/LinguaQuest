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

  test('language ja routes kana-only word to ja-JP tts', () async {
    String? lang;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, l, slow) async {
        lang = l;
        return true;
      },
    );
    await svc.play(word: 'こんにちは', language: 'ja');
    expect(lang, 'ja-JP');
  });

  test('language zh routes to zh-CN tts', () async {
    String? lang;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, l, slow) async {
        lang = l;
        return true;
      },
    );
    await svc.play(word: 'hello', language: 'zh');
    expect(lang, 'zh-CN');
  });

  test('empty language keeps CJK auto-detect fallback', () async {
    String? lang;
    final svc = PronunciationService(
      audio: (url) async => true,
      tts: (text, l, slow) async {
        lang = l;
        return true;
      },
    );
    await svc.play(word: '你好');
    expect(lang, 'zh-CN');
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

  group('server TTS URL (apiBaseUrl injection)', () {
    test('Chinese with apiBaseUrl: audio called with server TTS URL', () async {
      String? calledUrl;
      var ttsCalled = false;
      final svc = PronunciationService(
        audio: (url) async {
          calledUrl = url;
          return true;
        },
        tts: (text, lang, slow) async {
          ttsCalled = true;
          return true;
        },
        apiBaseUrl: 'http://server',
      );
      final outcome = await svc.play(word: '你好', language: 'zh');
      expect(outcome, PronunciationOutcome.playedUrl);
      expect(calledUrl, contains('/tts?'));
      expect(calledUrl, contains('lang=zh'));
      expect(calledUrl, contains(Uri.encodeComponent('你好')));
      expect(ttsCalled, isFalse);
    });

    test('server TTS audio fails: fallback to local TTS', () async {
      var ttsCalled = false;
      final svc = PronunciationService(
        audio: (url) async => false,
        tts: (text, lang, slow) async {
          ttsCalled = true;
          return true;
        },
        apiBaseUrl: 'http://server',
      );
      final outcome = await svc.play(word: '你好', language: 'zh');
      expect(outcome, PronunciationOutcome.playedTts);
      expect(ttsCalled, isTrue);
    });

    test('apiBaseUrl empty: Chinese goes directly to local TTS', () async {
      var audioCalled = false;
      final svc = PronunciationService(
        audio: (url) async {
          audioCalled = true;
          return true;
        },
        tts: (text, lang, slow) async => true,
        apiBaseUrl: '',
      );
      final outcome = await svc.play(word: '你好', language: 'zh');
      expect(outcome, PronunciationOutcome.playedTts);
      expect(audioCalled, isFalse);
    });

    test('en external audioUrl still preferred over server TTS', () async {
      final calledUrls = <String>[];
      final svc = PronunciationService(
        audio: (url) async {
          calledUrls.add(url);
          return true;
        },
        tts: (text, lang, slow) async => true,
        apiBaseUrl: 'http://server',
      );
      final outcome = await svc.play(
        word: 'hello',
        audioUrl: 'http://dict/hello.mp3',
      );
      expect(outcome, PronunciationOutcome.playedUrl);
      expect(calledUrls.length, 1);
      expect(calledUrls.first, 'http://dict/hello.mp3');
    });

    test('Japanese with apiBaseUrl uses server TTS URL with lang=ja', () async {
      String? calledUrl;
      final svc = PronunciationService(
        audio: (url) async {
          calledUrl = url;
          return true;
        },
        tts: (text, lang, slow) async => true,
        apiBaseUrl: 'http://server',
      );
      final outcome = await svc.play(word: 'こんにちは', language: 'ja');
      expect(outcome, PronunciationOutcome.playedUrl);
      expect(calledUrl, contains('lang=ja'));
    });
  });
}
