import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SensorySettings', () {
    test('defaults to sound and vibration on, high contrast off', () {
      const s = SensorySettings.defaults;
      expect(s.soundEnabled, isTrue);
      expect(s.vibrationEnabled, isTrue);
      expect(s.highContrastMode, isFalse);
    });

    test('copyWith preserves unmodified fields', () {
      const original = SensorySettings(
        soundEnabled: false,
        vibrationEnabled: true,
        highContrastMode: false,
      );
      final updated = original.copyWith(highContrastMode: true);
      expect(updated.soundEnabled, isFalse);
      expect(updated.vibrationEnabled, isTrue);
      expect(updated.highContrastMode, isTrue);
    });

    test('toJson / fromJson round-trips correctly', () {
      const original = SensorySettings(
        soundEnabled: false,
        vibrationEnabled: false,
        highContrastMode: true,
      );
      final json = original.toJson();
      final restored = SensorySettings.fromJson(json);
      expect(restored.soundEnabled, isFalse);
      expect(restored.vibrationEnabled, isFalse);
      expect(restored.highContrastMode, isTrue);
    });

    test('fromJson uses defaults for missing keys', () {
      final s = SensorySettings.fromJson({});
      expect(s.soundEnabled, isTrue);
      expect(s.vibrationEnabled, isTrue);
      expect(s.highContrastMode, isFalse);
    });
  });

  group('AppController sensory settings', () {
    test('updateSensorySettings persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          localNotificationServiceProvider.overrideWithValue(
            _NoopLocalNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();

      const updated = SensorySettings(
        soundEnabled: false,
        vibrationEnabled: true,
        highContrastMode: true,
      );
      await container
          .read(appControllerProvider.notifier)
          .updateSensorySettings(updated);

      // Verify in-memory state.
      final state = container.read(appControllerProvider);
      expect(state.sensorySettings.soundEnabled, isFalse);
      expect(state.sensorySettings.vibrationEnabled, isTrue);
      expect(state.sensorySettings.highContrastMode, isTrue);

      // Verify persisted to SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('linguaquest.sensory_settings');
      expect(raw, isNotNull);
      final decoded =
          SensorySettings.fromJson(jsonDecode(raw!) as Map<String, dynamic>);
      expect(decoded.soundEnabled, isFalse);
      expect(decoded.vibrationEnabled, isTrue);
      expect(decoded.highContrastMode, isTrue);
    });

    test('bootstrap restores saved sensory settings', () async {
      const saved = SensorySettings(
        soundEnabled: false,
        vibrationEnabled: false,
        highContrastMode: true,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.sensory_settings': jsonEncode(saved.toJson()),
      });

      final container = ProviderContainer(
        overrides: [
          localNotificationServiceProvider.overrideWithValue(
            _NoopLocalNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final state = container.read(appControllerProvider);

      expect(state.sensorySettings.soundEnabled, isFalse);
      expect(state.sensorySettings.vibrationEnabled, isFalse);
      expect(state.sensorySettings.highContrastMode, isTrue);
    });
  });
}

class _NoopLocalNotificationService implements LocalNotificationService {
  @override
  Future<void> initialize({
    required void Function(String route) onSelectRoute,
  }) async {}

  @override
  Future<void> scheduleDailyStudyReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required LocalNotificationStrings strings,
  }) async {}

  @override
  Future<void> scheduleReviewDueReminder({
    required int dueCount,
    required String title,
    required LocalNotificationStrings strings,
  }) async {}
}
