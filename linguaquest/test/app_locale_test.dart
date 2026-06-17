import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  final supported = AppLocalizations.supportedLocales;

  group('resolveAppLocale follows the system language', () {
    test('returns the matching supported locale for a supported device language', () {
      expect(resolveAppLocale(const Locale('en'), supported).languageCode, 'en');
      expect(resolveAppLocale(const Locale('ms'), supported).languageCode, 'ms');
      expect(resolveAppLocale(const Locale('zh'), supported).languageCode, 'zh');
    });

    test('ignores region subtag, matching by languageCode', () {
      expect(
        resolveAppLocale(const Locale('en', 'US'), supported).languageCode,
        'en',
      );
      expect(
        resolveAppLocale(const Locale('zh', 'CN'), supported).languageCode,
        'zh',
      );
    });

    test('falls back to Chinese for an unsupported device language', () {
      expect(resolveAppLocale(const Locale('fr'), supported).languageCode, 'zh');
      expect(resolveAppLocale(const Locale('de'), supported).languageCode, 'zh');
    });

    test('falls back to Chinese when the device locale is null', () {
      expect(resolveAppLocale(null, supported).languageCode, 'zh');
    });
  });
}
