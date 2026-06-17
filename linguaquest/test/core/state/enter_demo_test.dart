import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('enterDemo logs in as the demo account in mock mode', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final ok = await container.read(appControllerProvider.notifier).enterDemo();
    expect(ok, isTrue);

    final state = container.read(appControllerProvider);
    expect(state.user, isNotNull);
    expect(state.user!.uid, 'demo-user');
    expect(state.isAuthenticated, isTrue);
  });
}
