import 'package:linguaquest_server/src/routes.dart';
import 'package:test/test.dart';

void main() {
  group('ttsVoiceFor', () {
    test('maps zh to zh-CN-XiaoxiaoNeural', () {
      expect(ttsVoiceFor('zh'), 'zh-CN-XiaoxiaoNeural');
    });

    test('maps en to en-US-AriaNeural', () {
      expect(ttsVoiceFor('en'), 'en-US-AriaNeural');
    });

    test('maps ja to ja-JP-NanamiNeural', () {
      expect(ttsVoiceFor('ja'), 'ja-JP-NanamiNeural');
    });

    test('unknown lang falls back to zh-CN-XiaoxiaoNeural', () {
      expect(ttsVoiceFor('fr'), 'zh-CN-XiaoxiaoNeural');
      expect(ttsVoiceFor(''), 'zh-CN-XiaoxiaoNeural');
    });
  });

  group('ttsRateFor', () {
    test('slow==true returns -25%', () {
      expect(ttsRateFor('true'), '-25%');
    });

    test('slow!=true returns +0%', () {
      expect(ttsRateFor('false'), '+0%');
      expect(ttsRateFor(''), '+0%');
      expect(ttsRateFor('1'), '+0%');
    });
  });

  group('isTtsLangValid', () {
    test('accepts zh, en, ja', () {
      expect(isTtsLangValid('zh'), isTrue);
      expect(isTtsLangValid('en'), isTrue);
      expect(isTtsLangValid('ja'), isTrue);
    });

    test('rejects other langs', () {
      expect(isTtsLangValid('fr'), isFalse);
      expect(isTtsLangValid(''), isFalse);
      expect(isTtsLangValid('ZH'), isFalse);
      expect(isTtsLangValid('zh-CN'), isFalse);
    });
  });
}
