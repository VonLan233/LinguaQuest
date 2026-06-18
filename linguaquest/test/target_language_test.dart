import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_state.dart';

void main() {
  test('AppState defaults targetLanguage to Chinese', () {
    expect(AppState.initial().targetLanguage, 'zh');
  });

  test('copyWith updates targetLanguage', () {
    final updated = AppState.initial().copyWith(targetLanguage: 'es');
    expect(updated.targetLanguage, 'es');
  });
}
