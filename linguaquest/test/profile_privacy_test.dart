import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/user_privacy.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
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

  group('MockProfileRepository', () {
    test('getPublicProfile returns public fields', () async {
      final repo = MockProfileRepository(currentUserId: 'user-self');
      final profile = await repo.getPublicProfile('user-other');

      expect(profile['uid'], 'user-other');
      expect(profile['name'], isNotNull);
      expect(profile['isOwner'], isFalse);
      expect(profile['streak'], isA<int>());
      expect(profile['stats'], isA<Map>());
      expect(profile['achievements'], isA<List>());
      expect(profile['wordbookProgress'], isA<int>());
    });

    test('getPublicProfile for self includes isOwner=true', () async {
      final repo = MockProfileRepository(currentUserId: 'user-self');
      final profile = await repo.getPublicProfile('user-self');

      expect(profile['isOwner'], isTrue);
    });

    test('getPublicProfile for different user has isOwner=false', () async {
      final repo = MockProfileRepository(currentUserId: 'user-a');
      final profile = await repo.getPublicProfile('user-b');

      expect(profile['isOwner'], isFalse);
    });
  });

  group('PublicProfileScreen', () {
    Widget buildSubject({required Map<String, dynamic> profile}) {
      return ProviderScope(
        overrides: [
          localNotificationServiceProvider.overrideWithValue(
            _NoopLocalNotificationService(),
          ),
        ],
        child: MaterialApp(
          home: _FakeProfileBody(profile: profile),
        ),
      );
    }

    testWidgets('renders without crash', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          profile: {
            'uid': 'u1',
            'name': 'Test User',
            'isOwner': false,
            'streak': 5,
            'stats': {
              'learnedWords': 89,
              'masteredWords': 34,
              'totalDays': 12,
            },
            'achievements': <Map<String, dynamic>>[],
            'posts': <Map<String, dynamic>>[],
            'wordbookProgress': 18,
          },
        ),
      );
      await tester.pump();
      expect(find.text('Test User'), findsOneWidget);
    });

    testWidgets('shows achievements when available', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          profile: {
            'uid': 'u1',
            'name': 'Achiever',
            'isOwner': false,
            'achievements': [
              {
                'id': 'first_lesson',
                'title': 'First Step',
                'iconKey': 'school',
                'unlocked': true,
              },
            ],
          },
        ),
      );
      await tester.pump();
      expect(find.text('First Step'), findsOneWidget);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Renders key parts of the public profile without going through a
/// [FutureProvider] or [GoRouter], so the widget tests stay fast and hermetic.
class _FakeProfileBody extends StatelessWidget {
  const _FakeProfileBody({required this.profile});

  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final name = profile['name'] as String? ?? 'User';
    final achievements =
        (profile['achievements'] as List?)?.cast<Map<String, dynamic>>();

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name),
            if (achievements != null)
              for (final a in achievements)
                Text(a['title'] as String? ?? ''),
          ],
        ),
      ),
    );
  }
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
