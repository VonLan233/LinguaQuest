class UserPrivacySettings {
  final bool publicStats;
  final bool publicStreak;
  final bool publicWordbook;
  final bool publicPosts;

  const UserPrivacySettings({
    this.publicStats = true,
    this.publicStreak = true,
    this.publicWordbook = false,
    this.publicPosts = true,
  });

  static const defaults = UserPrivacySettings();

  UserPrivacySettings copyWith({
    bool? publicStats,
    bool? publicStreak,
    bool? publicWordbook,
    bool? publicPosts,
  }) =>
      UserPrivacySettings(
        publicStats: publicStats ?? this.publicStats,
        publicStreak: publicStreak ?? this.publicStreak,
        publicWordbook: publicWordbook ?? this.publicWordbook,
        publicPosts: publicPosts ?? this.publicPosts,
      );

  Map<String, dynamic> toJson() => {
    'publicStats': publicStats,
    'publicStreak': publicStreak,
    'publicWordbook': publicWordbook,
    'publicPosts': publicPosts,
  };

  factory UserPrivacySettings.fromJson(Map<String, dynamic> j) =>
      UserPrivacySettings(
        publicStats: j['publicStats'] as bool? ?? true,
        publicStreak: j['publicStreak'] as bool? ?? true,
        publicWordbook: j['publicWordbook'] as bool? ?? false,
        publicPosts: j['publicPosts'] as bool? ?? true,
      );
}
