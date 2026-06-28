import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Guards that the community screen exposes exactly one compose entry (the FAB),
/// not the redundant top "Share an update" outlined button.
void main() {
  test('community screen has no top Share-an-update button', () {
    final src = File(
      'lib/features/discover/community_screen.dart',
    ).readAsStringSync();
    expect(src.contains('communityShareUpdate'), isFalse);
    // FAB compose entry remains.
    expect(src.contains("context.push('/forum/compose')"), isTrue);
  });
}
