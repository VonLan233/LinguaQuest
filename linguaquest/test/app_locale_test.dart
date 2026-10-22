import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/l10n/generated/app_localizations.dart';

void main() {
  test(
    'resolves each explanation language independently of the study language',
    () {
      for (final code in ['zh', 'ja', 'en']) {
        expect(
          resolveAppLocale(
            Locale(code),
            AppLocalizations.supportedLocales,
          ).languageCode,
          code,
        );
      }
      expect(
        resolveAppLocale(
          const Locale('fr'),
          AppLocalizations.supportedLocales,
        ).languageCode,
        'en',
      );
      expect(
        resolveAppLocale(null, AppLocalizations.supportedLocales).languageCode,
        'en',
      );
    },
  );
}
