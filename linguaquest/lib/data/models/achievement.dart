class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.iconKey,
    required this.unlocked,
    this.unlockedAt,
  });

  final String id;
  final String title;
  final String description;
  final String iconKey;
  final bool unlocked;
  final DateTime? unlockedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'iconKey': iconKey,
        'unlocked': unlocked,
        'unlockedAt': unlockedAt?.toIso8601String(),
      };

  factory Achievement.fromJson(Map<String, dynamic> j) => Achievement(
        id: j['id'] as String? ?? '',
        title: j['title'] as String? ?? '',
        description: j['description'] as String? ?? '',
        iconKey: j['iconKey'] as String? ?? 'star',
        unlocked: j['unlocked'] as bool? ?? false,
        unlockedAt: j['unlockedAt'] == null
            ? null
            : DateTime.tryParse(j['unlockedAt'] as String),
      );
}

/// Client-side achievement evaluation logic mirroring server-side AchievementPolicy.
class AchievementEvaluator {
  static List<Achievement> evaluate({
    required int streakDays,
    required int masteredWords,
    required int totalStudyDays,
    required int trainingXp,
    bool hasPerfectQuiz = false,
    bool hasListening = false,
    bool hasMapLanguage = false,
  }) {
    final now = DateTime.now();
    return [
      Achievement(
        id: 'first_lesson',
        title: 'First Step',
        description: 'Complete your first lesson',
        iconKey: 'school',
        unlocked: totalStudyDays >= 1,
        unlockedAt: totalStudyDays >= 1 ? now : null,
      ),
      Achievement(
        id: 'streak_3',
        title: '3-Day Streak',
        description: 'Study 3 days in a row',
        iconKey: 'local_fire_department',
        unlocked: streakDays >= 3,
        unlockedAt: streakDays >= 3 ? now : null,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week Warrior',
        description: 'Study 7 days in a row',
        iconKey: 'military_tech',
        unlocked: streakDays >= 7,
        unlockedAt: streakDays >= 7 ? now : null,
      ),
      Achievement(
        id: 'mastered_10',
        title: 'Word Master',
        description: 'Master 10 words',
        iconKey: 'star',
        unlocked: masteredWords >= 10,
        unlockedAt: masteredWords >= 10 ? now : null,
      ),
      Achievement(
        id: 'mastered_50',
        title: 'Vocabulary Builder',
        description: 'Master 50 words',
        iconKey: 'emoji_events',
        unlocked: masteredWords >= 50,
        unlockedAt: masteredWords >= 50 ? now : null,
      ),
      Achievement(
        id: 'xp_1000',
        title: 'Training Champion',
        description: 'Earn 1000 training XP total',
        iconKey: 'sports_martial_arts',
        unlocked: trainingXp >= 1000,
        unlockedAt: trainingXp >= 1000 ? now : null,
      ),
      Achievement(
        id: 'learn_100_words',
        title: 'Century Scholar',
        description: 'Master 100 words',
        iconKey: 'workspace_premium',
        unlocked: masteredWords >= 100,
        unlockedAt: masteredWords >= 100 ? now : null,
      ),
      Achievement(
        id: 'quiz_perfect',
        title: 'Flawless Run',
        description: 'Complete a quiz session with 100% accuracy (4+ questions)',
        iconKey: 'verified',
        unlocked: hasPerfectQuiz,
        unlockedAt: hasPerfectQuiz ? now : null,
      ),
      Achievement(
        id: 'first_listening',
        title: 'First Echo',
        description: 'Complete your first listening exercise',
        iconKey: 'hearing',
        unlocked: hasListening,
        unlockedAt: hasListening ? now : null,
      ),
      Achievement(
        id: 'first_map_language',
        title: 'Cartographer',
        description: 'Pick a language from the language map',
        iconKey: 'map',
        unlocked: hasMapLanguage,
        unlockedAt: hasMapLanguage ? now : null,
      ),
    ];
  }
}
