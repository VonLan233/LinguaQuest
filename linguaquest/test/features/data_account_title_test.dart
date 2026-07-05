import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Task 7.3: the "Data & Account" destination and both of its entry points must
/// share ONE localized title, instead of three divergent hardcoded strings
/// ('Data & storage' / 'Data & Account' / 'Data & Account').
void main() {
  test(
    'profile_screen data entry uses l10n.dataAccountTitle, not a literal',
    () {
      final src = File(
        'lib/features/profile/profile_screen.dart',
      ).readAsStringSync();
      expect(src.contains('l10n.dataAccountTitle'), isTrue);
      expect(src.contains("'Data & storage'"), isFalse);
      expect(src.contains("'Data & Account'"), isFalse);
    },
  );

  test(
    'settings_screen data entry uses l10n.dataAccountTitle, not a literal',
    () {
      final src = File(
        'lib/features/profile/settings_screen.dart',
      ).readAsStringSync();
      expect(src.contains('l10n.dataAccountTitle'), isTrue);
      expect(src.contains("'Data & Account'"), isFalse);
    },
  );

  test('data_settings_screen AppBar uses dataAccountTitle, not a literal', () {
    final src = File(
      'lib/features/profile/data_settings_screen.dart',
    ).readAsStringSync();
    expect(src.contains('dataAccountTitle'), isTrue);
    expect(src.contains("'Data & Account'"), isFalse);
  });

  test('/profile/data route is declared before /profile/:userId', () {
    final src = File('lib/core/routing/app_router.dart').readAsStringSync();
    final dataRouteIndex = src.indexOf("path: '/profile/data'");
    final publicProfileRouteIndex = src.indexOf("path: '/profile/:userId'");

    expect(dataRouteIndex, isNonNegative);
    expect(publicProfileRouteIndex, isNonNegative);
    expect(dataRouteIndex, lessThan(publicProfileRouteIndex));
  });
}
