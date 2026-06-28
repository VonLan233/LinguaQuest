import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards that the Profile + Settings "Choose Language" rows navigate to the
/// language map route, not the bottom-sheet picker.
void main() {
  test('profile_screen Choose Language pushes /language-map', () {
    final src = File(
      'lib/features/profile/profile_screen.dart',
    ).readAsStringSync();
    // The language row's onTap must reference the map route.
    expect(src.contains("context.push('/language-map')"), isTrue);
  });

  test('settings_screen Learning Language pushes /language-map', () {
    final src = File(
      'lib/features/profile/settings_screen.dart',
    ).readAsStringSync();
    expect(src.contains("context.push('/language-map')"), isTrue);
  });
}
