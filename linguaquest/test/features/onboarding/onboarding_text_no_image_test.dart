import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';
import 'package:linguaquest/l10n/generated/app_localizations_en.dart';
import 'package:linguaquest/l10n/generated/app_localizations_ms.dart';
import 'package:linguaquest/l10n/generated/app_localizations_zh.dart';

// Bug 1 (task 7.1): splash/onboarding/about copy claimed "image word cards"
// but no real images exist. Copy must describe word cards without the
// misleading "image / 图像 / visual / bergambar" wording.
void main() {
  final locales = <String, AppLocalizations>{
    'en': AppLocalizationsEn(),
    'zh': AppLocalizationsZh(),
    'ms': AppLocalizationsMs(),
  };

  // Words that falsely imply the cards contain images.
  final banned = <String>['image', 'visual', '图像', '视觉', 'bergambar'];

  bool clean(String value) {
    final lower = value.toLowerCase();
    return banned.every((word) => !lower.contains(word.toLowerCase()));
  }

  locales.forEach((code, l10n) {
    test('[$code] splashTagline has no misleading image wording', () {
      expect(clean(l10n.splashTagline), isTrue, reason: l10n.splashTagline);
    });

    test('[$code] onboarding feature card copy has no image wording', () {
      expect(
        clean(l10n.onboardingFeatureImageCards),
        isTrue,
        reason: l10n.onboardingFeatureImageCards,
      );
      expect(
        clean(l10n.onboardingFeatureImageCardsDesc),
        isTrue,
        reason: l10n.onboardingFeatureImageCardsDesc,
      );
    });

    test('[$code] about copy has no image wording', () {
      expect(clean(l10n.aboutIntro), isTrue, reason: l10n.aboutIntro);
      expect(
        clean(l10n.aboutCoreSubtitle),
        isTrue,
        reason: l10n.aboutCoreSubtitle,
      );
    });
  });
}
