import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/user_privacy.dart';
import 'package:linguaquest/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserPrivacySettings', () {
    test('defaults to expected values', () {
      const s = UserPrivacySettings.defaults;
      expect(s.publicStats, isTrue);
      expect(s.publicStreak, isTrue);
      expect(s.publicWordbook, isFalse);
      expect(s.publicPosts, isTrue);
    });

    test('copyWith preserves unmodified fields', () {
      const original = UserPrivacySettings(
        publicStats: false,
        publicStreak: true,
        publicWordbook: true,
        publicPosts: false,
      );
      final updated = original.copyWith(publicStats: true);
      expect(updated.publicStats, isTrue);
      expect(updated.publicStreak, isTrue);
      expect(updated.publicWordbook, isTrue);
      expect(updated.publicPosts, isFalse);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      const original = UserPrivacySettings(
        publicStats: false,
        publicStreak: false,
        publicWordbook: true,
        publicPosts: false,
      );
      final json = original.toJson();
      final restored = UserPrivacySettings.fromJson(json);
      expect(restored.publicStats, isFalse);
      expect(restored.publicStreak, isFalse);
      expect(restored.publicWordbook, isTrue);
      expect(restored.publicPosts, isFalse);
    });

    test('fromJson uses defaults for missing keys', () {
      final s = UserPrivacySettings.fromJson({});
      expect(s.publicStats, isTrue);
      expect(s.publicStreak, isTrue);
      expect(s.publicWordbook, isFalse);
      expect(s.publicPosts, isTrue);
    });
  });

  group('AppController privacy', () {
    test('updatePrivacySettings persists to SharedPreferences', () async {
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

      const updated = UserPrivacySettings(
        publicStats: false,
        publicStreak: false,
        publicWordbook: true,
        publicPosts: false,
      );
      await container
          .read(appControllerProvider.notifier)
          .updatePrivacySettings(updated);

      // Verify in-memory state.
      final state = container.read(appControllerProvider);
      expect(state.privacySettings.publicStats, isFalse);
      expect(state.privacySettings.publicStreak, isFalse);
      expect(state.privacySettings.publicWordbook, isTrue);
      expect(state.privacySettings.publicPosts, isFalse);

      // Verify persisted to SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('linguaquest.privacy_settings');
      expect(raw, isNotNull);
      final decoded = UserPrivacySettings.fromJson(
        jsonDecode(raw!) as Map<String, dynamic>,
      );
      expect(decoded.publicStats, isFalse);
      expect(decoded.publicStreak, isFalse);
      expect(decoded.publicWordbook, isTrue);
      expect(decoded.publicPosts, isFalse);
    });

    test('bootstrap restores saved privacy settings', () async {
      const saved = UserPrivacySettings(
        publicStats: false,
        publicStreak: true,
        publicWordbook: true,
        publicPosts: false,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.privacy_settings': jsonEncode(saved.toJson()),
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

      expect(state.privacySettings.publicStats, isFalse);
      expect(state.privacySettings.publicStreak, isTrue);
      expect(state.privacySettings.publicWordbook, isTrue);
      expect(state.privacySettings.publicPosts, isFalse);
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
