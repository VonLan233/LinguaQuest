import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  final supported = AppLocalizations.supportedLocales;

  group('app locale is hard-locked to English', () {
    test('returns English regardless of a supported device language', () {
      expect(resolveAppLocale(const Locale('zh'), supported).languageCode, 'en');
      expect(resolveAppLocale(const Locale('ms'), supported).languageCode, 'en');
      expect(resolveAppLocale(const Locale('en'), supported).languageCode, 'en');
    });

    test('returns English for an unsupported language or null device locale', () {
      expect(resolveAppLocale(const Locale('fr'), supported).languageCode, 'en');
      expect(resolveAppLocale(null, supported).languageCode, 'en');
    });
  });
}
