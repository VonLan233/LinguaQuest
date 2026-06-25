class UserPrivacyFlags {
  final bool publicStats;
  final bool publicStreak;
  final bool publicWordbook;
  final bool publicPosts;

  const UserPrivacyFlags({
    this.publicStats = true,
    this.publicStreak = true,
    this.publicWordbook = false,
    this.publicPosts = true,
  });

  Map<String, dynamic> toJson() => {
    'publicStats': publicStats,
    'publicStreak': publicStreak,
    'publicWordbook': publicWordbook,
    'publicPosts': publicPosts,
  };

  factory UserPrivacyFlags.fromJson(Map<String, dynamic> j) => UserPrivacyFlags(
    publicStats: j['publicStats'] as bool? ?? true,
    publicStreak: j['publicStreak'] as bool? ?? true,
    publicWordbook: j['publicWordbook'] as bool? ?? false,
    publicPosts: j['publicPosts'] as bool? ?? true,
  );
}

class PrivacyPolicy {
  /// Returns only fields allowed by privacy flags
  static Map<String, dynamic> filterPublicProfile(
    Map<String, dynamic> profile,
    UserPrivacyFlags flags,
  ) {
    return {
      'uid': profile['uid'],
      'name': profile['name'],
      if (flags.publicStats) 'stats': profile['stats'],
      if (flags.publicStreak) 'streak': profile['streak'],
      if (flags.publicWordbook) 'wordbookProgress': profile['wordbookProgress'],
      if (flags.publicPosts) 'posts': profile['posts'],
    };
  }
}
