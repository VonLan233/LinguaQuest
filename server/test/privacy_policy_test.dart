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
  });
}
