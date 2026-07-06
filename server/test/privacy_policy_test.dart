import 'package:linguaquest_server/src/privacy_policy.dart';
import 'package:test/test.dart';

void main() {
  group('UserPrivacyFlags', () {
    test('defaults match expected values', () {
      const flags = UserPrivacyFlags();
      expect(flags.publicStats, isTrue);
      expect(flags.publicStreak, isTrue);
      expect(flags.publicWordbook, isFalse);
      expect(flags.publicPosts, isTrue);
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      const original = UserPrivacyFlags(
        publicStats: false,
        publicStreak: true,
        publicWordbook: true,
        publicPosts: false,
      );
      final json = original.toJson();
      final restored = UserPrivacyFlags.fromJson(json);
      expect(restored.publicStats, original.publicStats);
      expect(restored.publicStreak, original.publicStreak);
      expect(restored.publicWordbook, original.publicWordbook);
      expect(restored.publicPosts, original.publicPosts);
    });

    test('fromJson fills missing fields with defaults', () {
      final flags = UserPrivacyFlags.fromJson({});
      expect(flags.publicStats, isTrue);
      expect(flags.publicStreak, isTrue);
      expect(flags.publicWordbook, isFalse);
      expect(flags.publicPosts, isTrue);
    });
  });

  group('PrivacyPolicy.filterPublicProfile', () {
    final fullProfile = {
      'uid': 'u1',
      'name': 'Alice',
      'stats': {'xp': 100},
      'streak': 5,
      'wordbookProgress': 0.3,
      'posts': ['post1'],
    };

    test('filterPublicProfile hides stats when publicStats=false', () {
      const flags = UserPrivacyFlags(publicStats: false);
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, flags);
      expect(result.containsKey('stats'), isFalse);
    });

    test('filterPublicProfile always includes uid and name', () {
      const flags = UserPrivacyFlags(
        publicStats: false,
        publicStreak: false,
        publicWordbook: false,
        publicPosts: false,
      );
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, flags);
      expect(result['uid'], 'u1');
      expect(result['name'], 'Alice');
    });

    test('filterPublicProfile includes streak when publicStreak=true', () {
      const flags = UserPrivacyFlags(publicStreak: true);
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, flags);
      expect(result.containsKey('streak'), isTrue);
    });

    test('filterPublicProfile hides wordbook when publicWordbook=false', () {
      const flags = UserPrivacyFlags(publicWordbook: false);
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, flags);
      expect(result.containsKey('wordbookProgress'), isFalse);
    });

    test('filterPublicProfile shows wordbook when publicWordbook=true', () {
      const flags = UserPrivacyFlags(publicWordbook: true);
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, flags);
      expect(result['wordbookProgress'], 0.3);
    });

    test('filterPublicProfile hides posts when publicPosts=false', () {
      const flags = UserPrivacyFlags(publicPosts: false);
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, flags);
      expect(result.containsKey('posts'), isFalse);
    });
  });

  group('GET /users/:id/profile (PrivacyPolicy logic)', () {
    final fullProfile = {
      'uid': 'user-abc',
      'name': 'Test User',
      'stats': {'learnedWords': 50, 'masteredWords': 20, 'totalDays': 7},
      'streak': 10,
      'wordbookProgress': 25,
      'posts': <Map<String, dynamic>>[],
    };

    test('returns public fields with default privacy flags', () {
      // Default flags: publicStats=true, publicStreak=true, publicWordbook=false, publicPosts=true
      const flags = UserPrivacyFlags();
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, flags);
      expect(result['uid'], 'user-abc');
      expect(result['name'], 'Test User');
      expect(result.containsKey('stats'), isTrue);
      expect(result.containsKey('streak'), isTrue);
      // publicWordbook defaults to false
      expect(result.containsKey('wordbookProgress'), isFalse);
      expect(result.containsKey('posts'), isTrue);
    });

    test('isOwner scenario: all fields visible (simulated by full flags)', () {
      // When the caller is the owner, the app can show all fields
      // regardless of privacy flags. We simulate this by using all-true flags.
      const ownerFlags = UserPrivacyFlags(
        publicStats: true,
        publicStreak: true,
        publicWordbook: true,
        publicPosts: true,
      );
      final result = PrivacyPolicy.filterPublicProfile(fullProfile, ownerFlags);
      expect(result.containsKey('stats'), isTrue);
      expect(result.containsKey('streak'), isTrue);
      expect(result.containsKey('wordbookProgress'), isTrue);
      expect(result.containsKey('posts'), isTrue);
    });
  });
}
