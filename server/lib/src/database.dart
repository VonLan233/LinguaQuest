import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'auth.dart';
import 'config.dart';
import 'lottery_policy.dart';
import 'study_spot_policy.dart';

const resetCustomWordProgressSql = '''
UPDATE custom_words
SET mastery_level=0,
    correct_count=0,
    wrong_count=0,
    next_review_at=@resetAt,
    updated_at=@resetAt
WHERE uid=@uid
''';

const setEmailVerifiedSql =
    'UPDATE users SET email_verified=TRUE, updated_at=@now WHERE id=@uid';

const countAiHistoryTodaySql =
    'SELECT COUNT(*) FROM ai_history '
    'WHERE user_id=@userId '
    'AND is_deleted=FALSE '
    'AND created_at::date = CURRENT_DATE';

const upsertVerificationCodeSql = '''
INSERT INTO email_verification_codes (uid, code_hash, code_salt, expires_at, attempts, last_sent_at, created_at)
VALUES (@uid, @codeHash, @codeSalt, @expiresAt, 0, @sentAt, @sentAt)
ON CONFLICT (uid) DO UPDATE SET
  code_hash=@codeHash,
  code_salt=@codeSalt,
  expires_at=@expiresAt,
  attempts=0,
  last_sent_at=@sentAt
''';

const incrementVerificationAttemptsSql =
    'UPDATE email_verification_codes SET attempts=attempts+1 WHERE uid=@uid';

const deleteVerificationCodeSql =
    'DELETE FROM email_verification_codes WHERE uid=@uid';

/// Picks the primary-key id for an upserted study plan. Reuse the existing
/// scope's id so `ON CONFLICT (uid, language, word_book_id)` updates that row;
/// otherwise mint a fresh id. It deliberately ignores any client-supplied id —
/// when a user switches to a new (language, wordbook) scope the client sends
/// its CURRENT plan's id, and reusing it would collide with that other row's
/// primary key (study_plans_pkey → 500).
String studyPlanRowId(Map<String, dynamic>? existing) =>
    existing?['id']?.toString() ?? newId();

class AppDatabase {
  AppDatabase(this.connection);

  final Connection connection;

  static Future<AppDatabase> connect(AppConfig config) async {
    final connection = await Connection.openFromUrl(config.databaseUrl);
    return AppDatabase(connection);
  }

  Future<void> migrate() async {
    await connection.execute('''
CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  password_salt TEXT NOT NULL,
  name TEXT NOT NULL,
  target_exam TEXT NOT NULL DEFAULT 'HSK 1',
  level TEXT NOT NULL DEFAULT 'Intermediate',
  daily_goal INTEGER NOT NULL DEFAULT 10,
  xp INTEGER NOT NULL DEFAULT 0,
  streak INTEGER NOT NULL DEFAULT 0,
  last_study_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute(
      "ALTER TABLE users ALTER COLUMN level SET DEFAULT 'Intermediate'",
    );
    // HSK pivot: new users default to the HSK 1 exam target (was 'Daily
    // English'). Existing rows keep their stored value. Idempotent.
    await connection.execute(
      "ALTER TABLE users ALTER COLUMN target_exam SET DEFAULT 'HSK 1'",
    );

    // Email verification: backfill EXISTING users to verified (ADD COLUMN with
    // DEFAULT TRUE sets existing rows TRUE), then flip the default so NEW
    // registrations are created unverified. Idempotent across restarts.
    await connection.execute(
      'ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT TRUE',
    );
    await connection.execute(
      'ALTER TABLE users ALTER COLUMN email_verified SET DEFAULT FALSE',
    );
    await connection.execute('''
CREATE TABLE IF NOT EXISTS email_verification_codes (
  uid TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  code_hash TEXT NOT NULL,
  code_salt TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  attempts INTEGER NOT NULL DEFAULT 0,
  last_sent_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS custom_words (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  example_sentence TEXT NOT NULL,
  note TEXT NOT NULL DEFAULT '',
  tag TEXT NOT NULL DEFAULT 'custom',
  difficulty TEXT NOT NULL DEFAULT 'Medium',
  status TEXT NOT NULL DEFAULT 'Learning',
  ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
  interval_days INTEGER NOT NULL DEFAULT 0,
  repetition_count INTEGER NOT NULL DEFAULT 0,
  lapse_count INTEGER NOT NULL DEFAULT 0,
  mastery_level INTEGER NOT NULL DEFAULT 0,
  correct_count INTEGER NOT NULL DEFAULT 0,
  wrong_count INTEGER NOT NULL DEFAULT 0,
  meaning_recognition_score INTEGER NOT NULL DEFAULT 20,
  meaning_recall_score INTEGER NOT NULL DEFAULT 10,
  spelling_score INTEGER NOT NULL DEFAULT 10,
  listening_score INTEGER NOT NULL DEFAULT 10,
  context_score INTEGER NOT NULL DEFAULT 10,
  confidence_score INTEGER NOT NULL DEFAULT 10,
  next_review_at TIMESTAMPTZ NOT NULL,
  last_reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_custom_words_uid_next_review
ON custom_words (uid, next_review_at);
''');

    for (final statement in [
      "ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'Learning'",
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS interval_days INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS repetition_count INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS lapse_count INTEGER NOT NULL DEFAULT 0',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS meaning_recognition_score INTEGER NOT NULL DEFAULT 20',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS meaning_recall_score INTEGER NOT NULL DEFAULT 10',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS spelling_score INTEGER NOT NULL DEFAULT 10',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS listening_score INTEGER NOT NULL DEFAULT 10',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS context_score INTEGER NOT NULL DEFAULT 10',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS confidence_score INTEGER NOT NULL DEFAULT 10',
      'ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS last_reviewed_at TIMESTAMPTZ',
    ]) {
      await connection.execute(statement);
    }

    await connection.execute(
      "ALTER TABLE users ADD COLUMN IF NOT EXISTS first_map_language_at TIMESTAMPTZ",
    );

    await connection.execute('''
CREATE TABLE IF NOT EXISTS user_words (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id TEXT NOT NULL,
  word_book_id TEXT NOT NULL,
  word TEXT NOT NULL,
  meaning TEXT NOT NULL,
  example_sentence TEXT NOT NULL DEFAULT '',
  difficulty TEXT NOT NULL DEFAULT 'Medium',
  status TEXT NOT NULL DEFAULT 'New',
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  is_in_new_word_book BOOLEAN NOT NULL DEFAULT FALSE,
  is_ignored BOOLEAN NOT NULL DEFAULT FALSE,
  ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
  interval_days INTEGER NOT NULL DEFAULT 0,
  repetition_count INTEGER NOT NULL DEFAULT 0,
  lapse_count INTEGER NOT NULL DEFAULT 0,
  mastery_level INTEGER NOT NULL DEFAULT 0,
  correct_count INTEGER NOT NULL DEFAULT 0,
  wrong_count INTEGER NOT NULL DEFAULT 0,
  meaning_recognition_score INTEGER NOT NULL DEFAULT 20,
  meaning_recall_score INTEGER NOT NULL DEFAULT 10,
  spelling_score INTEGER NOT NULL DEFAULT 10,
  listening_score INTEGER NOT NULL DEFAULT 10,
  context_score INTEGER NOT NULL DEFAULT 10,
  confidence_score INTEGER NOT NULL DEFAULT 10,
  next_review_at TIMESTAMPTZ NOT NULL,
  last_reviewed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
ALTER TABLE user_words
DROP CONSTRAINT IF EXISTS user_words_uid_word_id_word_book_id_key;
''');

    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_user_words_uid_next_review
ON user_words (uid, next_review_at)
WHERE is_ignored = FALSE AND status NOT IN ('New', 'Previewed', 'Ignored');
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS study_sessions (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lesson_id TEXT NOT NULL,
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  xp_earned INTEGER NOT NULL,
  mistake_word_ids TEXT NOT NULL DEFAULT '',
  answer_events TEXT NOT NULL DEFAULT ''
);
''');
    await connection.execute(
      "ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS answer_events TEXT NOT NULL DEFAULT ''",
    );

    await connection.execute('''
CREATE TABLE IF NOT EXISTS review_events (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  answer_time_ms INTEGER NOT NULL,
  confidence INTEGER NOT NULL DEFAULT 3,
  wrong_option TEXT,
  reviewed_at TIMESTAMPTZ NOT NULL,
  mastery_before INTEGER NOT NULL,
  mastery_after INTEGER NOT NULL,
  next_review_at TIMESTAMPTZ NOT NULL
);
''');
    await connection.execute(
      'ALTER TABLE review_events ADD COLUMN IF NOT EXISTS confidence INTEGER NOT NULL DEFAULT 3',
    );
    await connection.execute(
      'ALTER TABLE review_events ADD COLUMN IF NOT EXISTS wrong_option TEXT',
    );

    await connection.execute('''
CREATE TABLE IF NOT EXISTS exercise_records (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  session_id TEXT NOT NULL,
  game_id TEXT NOT NULL,
  word_id TEXT NOT NULL,
  prompt_type TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  answer TEXT NOT NULL DEFAULT '',
  correct_answer TEXT NOT NULL DEFAULT '',
  answer_time_ms INTEGER NOT NULL DEFAULT 0,
  dimension TEXT NOT NULL DEFAULT 'confidence',
  created_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS reward_claims (
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_id TEXT NOT NULL,
  local_date TEXT NOT NULL,
  points INTEGER NOT NULL,
  claimed_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (uid, reward_id, local_date)
);
''');

    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_study_sessions_uid_ended_at
ON study_sessions (uid, ended_at);
''');

    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_review_events_uid_reviewed_at
ON review_events (uid, reviewed_at);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_route TEXT NOT NULL DEFAULT '/home',
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  source_key TEXT,
  params TEXT NOT NULL DEFAULT '{}',
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  UNIQUE (uid, source_key)
);
''');

    await connection.execute(
      "ALTER TABLE notifications ADD COLUMN IF NOT EXISTS params TEXT NOT NULL DEFAULT '{}'",
    );

    await connection.execute('''
CREATE TABLE IF NOT EXISTS lottery_prizes (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  rarity TEXT NOT NULL,
  description TEXT NOT NULL,
  probability DOUBLE PRECISION NOT NULL,
  fragment_value INTEGER NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS daily_checkins (
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_key TEXT NOT NULL,
  checked_in_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (uid, date_key)
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS daily_activity (
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_key TEXT NOT NULL,
  training_challenge_completed BOOLEAN NOT NULL DEFAULT FALSE,
  wrong_cleanup_completed BOOLEAN NOT NULL DEFAULT FALSE,
  forum_interaction_completed BOOLEAN NOT NULL DEFAULT FALSE,
  updated_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (uid, date_key)
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS daily_task_claims (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date_key TEXT NOT NULL,
  task_id TEXT NOT NULL,
  points INTEGER NOT NULL,
  claimed_at TIMESTAMPTZ NOT NULL,
  UNIQUE (uid, date_key, task_id)
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS point_transactions (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  source_type TEXT NOT NULL,
  source_id TEXT NOT NULL,
  points INTEGER NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL,
  UNIQUE (uid, source_type, source_id)
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS study_plans (
  id TEXT PRIMARY KEY,
  uid TEXT UNIQUE NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_book_id TEXT NOT NULL,
  daily_new_target INTEGER NOT NULL,
  daily_review_limit INTEGER NOT NULL,
  start_date DATE NOT NULL,
  target_finish_date DATE NOT NULL,
  reminder_time TEXT NOT NULL,
  status TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS lottery_draws (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  prize_id TEXT NOT NULL REFERENCES lottery_prizes(id),
  cost INTEGER NOT NULL,
  balance_after INTEGER NOT NULL,
  prize_name TEXT NOT NULL,
  prize_category TEXT NOT NULL,
  prize_rarity TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS user_assets (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  prize_id TEXT NOT NULL REFERENCES lottery_prizes(id),
  category TEXT NOT NULL,
  rarity TEXT NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 1,
  fragment_value INTEGER NOT NULL DEFAULT 0,
  acquired_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  UNIQUE (uid, prize_id)
);
''');

    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_study_sessions_uid_ended_at
ON study_sessions (uid, ended_at)
''');
    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_review_events_uid_reviewed_at
ON review_events (uid, reviewed_at)
''');
    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_custom_words_uid
ON custom_words (uid)
''');
    await connection.execute('''
CREATE INDEX IF NOT EXISTS idx_custom_words_uid_next_review
ON custom_words (uid, next_review_at)
''');

    // #G: 清理历史重复生词（保留每个 (uid, lower(word)) 最早一条），再建唯一索引。
    await connection.execute('''
DELETE FROM custom_words a
USING custom_words b
WHERE a.uid = b.uid
  AND LOWER(a.word) = LOWER(b.word)
  AND (a.created_at > b.created_at
       OR (a.created_at = b.created_at AND a.id > b.id))
''');
    await connection.execute('''
CREATE UNIQUE INDEX IF NOT EXISTS idx_custom_words_uid_word_unique
ON custom_words (uid, LOWER(word))
''');

    await connection.execute('''
DO \$\$
BEGIN
  IF to_regclass('public.user_words') IS NOT NULL THEN
    ALTER TABLE user_words
      DROP CONSTRAINT IF EXISTS user_words_uid_word_id_word_book_id_key;
    EXECUTE 'CREATE INDEX IF NOT EXISTS idx_user_words_uid_next_review ON user_words (uid, next_review_at) WHERE is_ignored = FALSE AND status IN (''Review'', ''Relearning'', ''Mastered'')';
  END IF;
END
\$\$;
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS ai_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  feature_type TEXT NOT NULL,
  prompt TEXT NOT NULL,
  response JSONB NOT NULL,
  is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
''');
    await connection.execute(
      'CREATE INDEX IF NOT EXISTS ai_history_user_id_idx ON ai_history(user_id)',
    );

    await connection.execute('''
CREATE TABLE IF NOT EXISTS study_spots (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id TEXT NOT NULL,
  name TEXT NOT NULL,
  latitude DOUBLE PRECISION NOT NULL,
  longitude DOUBLE PRECISION NOT NULL,
  study_minutes INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
''');
    await connection.execute(
      'CREATE INDEX IF NOT EXISTS study_spots_user_id_idx ON study_spots(user_id)',
    );
    await connection.execute(
      'ALTER TABLE study_spots ADD COLUMN IF NOT EXISTS visit_count INTEGER NOT NULL DEFAULT 1',
    );

    await connection.execute('''
CREATE TABLE IF NOT EXISTS user_privacy (
  user_id TEXT PRIMARY KEY,
  public_stats BOOLEAN NOT NULL DEFAULT TRUE,
  public_streak BOOLEAN NOT NULL DEFAULT TRUE,
  public_wordbook BOOLEAN NOT NULL DEFAULT FALSE,
  public_posts BOOLEAN NOT NULL DEFAULT TRUE,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS content_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reporter_user_id TEXT NOT NULL,
  content_type TEXT NOT NULL,
  content_id TEXT NOT NULL,
  reason TEXT NOT NULL,
  detail TEXT,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
''');

    await _seedLotteryPrizes();

    await connection.execute('''
CREATE TABLE IF NOT EXISTS forum_posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  tag TEXT NOT NULL DEFAULT 'General',
  status TEXT NOT NULL DEFAULT 'pending',
  like_count INT NOT NULL DEFAULT 0,
  comment_count INT NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS forum_comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  author_id TEXT NOT NULL,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS forum_likes (
  user_id TEXT NOT NULL,
  post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, post_id)
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS forum_favorites (
  user_id TEXT NOT NULL,
  post_id UUID NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, post_id)
);
''');

    await connection.execute('''
CREATE INDEX IF NOT EXISTS forum_posts_status_idx ON forum_posts(status);
''');

    // P2b: Add language column to user_words (additive, default 'zh')
    await connection.execute(
      "ALTER TABLE user_words ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'zh'",
    );

    // P2b: Add language column to custom_words scope (additive, nullable)
    await connection.execute(
      "ALTER TABLE custom_words ADD COLUMN IF NOT EXISTS scope TEXT",
    );

    // P2b: study_plans — add language column first
    await connection.execute(
      "ALTER TABLE study_plans ADD COLUMN IF NOT EXISTS language TEXT NOT NULL DEFAULT 'zh'",
    );

    // P2b: study_plans — swap UNIQUE(uid) → UNIQUE(uid, language, word_book_id)
    // We do this safely: drop the old constraint, add the new one (both IF NOT EXISTS / conditional).
    // The DROP is conditional via DO block to avoid error if already swapped.
    await connection.execute(r'''
DO $$
BEGIN
  -- Drop old single-uid unique constraint if it still exists.
  IF EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'study_plans'
      AND constraint_type = 'UNIQUE'
      AND constraint_name = 'study_plans_uid_key'
  ) THEN
    ALTER TABLE study_plans DROP CONSTRAINT study_plans_uid_key;
  END IF;
END
$$;
''');

    // Add composite unique constraint if it doesn't already exist.
    await connection.execute(r'''
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'study_plans'
      AND constraint_type = 'UNIQUE'
      AND constraint_name = 'study_plans_uid_language_word_book_id_key'
  ) THEN
    ALTER TABLE study_plans
      ADD CONSTRAINT study_plans_uid_language_word_book_id_key
      UNIQUE (uid, language, word_book_id);
  END IF;
END
$$;
''');
  }

  Future<Map<String, dynamic>?> getUserPrivacy(String userId) async {
    final result = await connection.execute(
      Sql.named(
        'SELECT user_id, public_stats, public_streak, public_wordbook, public_posts FROM user_privacy WHERE user_id=@userId',
      ),
      parameters: {'userId': userId},
    );
    if (result.isEmpty) return null;
    final row = result.first;
    return {
      'userId': row[0],
      'publicStats': row[1],
      'publicStreak': row[2],
      'publicWordbook': row[3],
      'publicPosts': row[4],
    };
  }

  Future<void> upsertUserPrivacy(
    String userId,
    Map<String, dynamic> flags,
  ) async {
    await connection.execute(
      Sql.named('''
INSERT INTO user_privacy (user_id, public_stats, public_streak, public_wordbook, public_posts, updated_at)
VALUES (@userId, @publicStats, @publicStreak, @publicWordbook, @publicPosts, NOW())
ON CONFLICT (user_id) DO UPDATE SET
  public_stats=@publicStats,
  public_streak=@publicStreak,
  public_wordbook=@publicWordbook,
  public_posts=@publicPosts,
  updated_at=NOW()
'''),
      parameters: {
        'userId': userId,
        'publicStats': flags['publicStats'] as bool? ?? true,
        'publicStreak': flags['publicStreak'] as bool? ?? true,
        'publicWordbook': flags['publicWordbook'] as bool? ?? false,
        'publicPosts': flags['publicPosts'] as bool? ?? true,
      },
    );
  }

  Future<Map<String, dynamic>> insertContentReport(
    Map<String, dynamic> report,
  ) async {
    final result = await connection.execute(
      Sql.named('''
INSERT INTO content_reports (reporter_user_id, content_type, content_id, reason, detail, status, created_at)
VALUES (@reporterUserId, @contentType, @contentId, @reason, @detail, 'pending', NOW())
RETURNING id, reporter_user_id, content_type, content_id, reason, detail, status, created_at
'''),
      parameters: {
        'reporterUserId': report['reporterUserId'],
        'contentType': report['contentType'],
        'contentId': report['contentId'],
        'reason': report['reason'],
        'detail': report['detail'],
      },
    );
    final row = result.first;
    return {
      'id': row[0].toString(),
      'reporterUserId': row[1],
      'contentType': row[2],
      'contentId': row[3],
      'reason': row[4],
      'detail': row[5],
      'status': row[6],
      'createdAt': (row[7] as DateTime).toIso8601String(),
    };
  }

  Future<void> _seedLotteryPrizes() async {
    final now = DateTime.now().toUtc();
    for (final prize in lotteryPrizeSeed) {
      await connection.execute(
        Sql.named('''
INSERT INTO lottery_prizes (
  id, name, category, rarity, description, probability, fragment_value,
  is_active, created_at, updated_at
) VALUES (
  @id, @name, @category, @rarity, @description, @probability, @fragmentValue,
  TRUE, @createdAt, @updatedAt
)
ON CONFLICT (id) DO UPDATE SET
  name=EXCLUDED.name,
  category=EXCLUDED.category,
  rarity=EXCLUDED.rarity,
  description=EXCLUDED.description,
  probability=EXCLUDED.probability,
  fragment_value=EXCLUDED.fragment_value,
  is_active=TRUE,
  updated_at=EXCLUDED.updated_at
'''),
        parameters: {...prize, 'createdAt': now, 'updatedAt': now},
      );
    }
  }

  Future<Map<String, dynamic>?> userByEmail(String email) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM users WHERE email=@email LIMIT 1'),
      parameters: {'email': email},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>?> userById(String uid) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM users WHERE id=@uid LIMIT 1'),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<void> setEmailVerified(String uid) async {
    await connection.execute(
      Sql.named(setEmailVerifiedSql),
      parameters: {'uid': uid, 'now': DateTime.now().toUtc()},
    );
  }

  Future<void> upsertVerificationCode(
    String uid, {
    required String codeHash,
    required String codeSalt,
    required DateTime expiresAt,
    required DateTime sentAt,
  }) async {
    await connection.execute(
      Sql.named(upsertVerificationCodeSql),
      parameters: {
        'uid': uid,
        'codeHash': codeHash,
        'codeSalt': codeSalt,
        'expiresAt': expiresAt,
        'sentAt': sentAt,
      },
    );
  }

  Future<Map<String, dynamic>?> verificationCodeFor(String uid) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM email_verification_codes WHERE uid=@uid LIMIT 1'),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<void> incrementVerificationAttempts(String uid) async {
    await connection.execute(
      Sql.named(incrementVerificationAttemptsSql),
      parameters: {'uid': uid},
    );
  }

  Future<void> deleteVerificationCode(String uid) async {
    await connection.execute(
      Sql.named(deleteVerificationCodeSql),
      parameters: {'uid': uid},
    );
  }

  Future<Map<String, dynamic>> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final existing = await userById(uid);
    if (existing == null) {
      throw StateError('user not found');
    }
    final now = DateTime.now().toUtc();
    await connection.execute(
      Sql.named('''
UPDATE users SET
  name=@name,
  target_exam=@targetExam,
  level=@level,
  daily_goal=@dailyGoal,
  streak=@streak,
  last_study_date=@lastStudyDate,
  updated_at=@updatedAt
WHERE id=@uid
'''),
      parameters: {
        'uid': uid,
        'name': data['name'] ?? existing['name'],
        'targetExam': data['targetExam'] ?? existing['target_exam'],
        'level': data['level'] ?? existing['level'],
        'dailyGoal': data['dailyGoal'] ?? existing['daily_goal'],
        'streak': data['streak'] ?? existing['streak'],
        'lastStudyDate':
            _date(data['lastStudyDate']) ?? existing['last_study_date'],
        'updatedAt': now,
      },
    );
    return (await userById(uid))!;
  }

  Future<void> insertUser({
    required String id,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    required String name,
  }) async {
    final now = DateTime.now().toUtc();
    await connection.execute(
      Sql.named('''
INSERT INTO users (id, email, password_hash, password_salt, name, created_at, updated_at)
VALUES (@id, @email, @passwordHash, @passwordSalt, @name, @createdAt, @updatedAt)
'''),
      parameters: {
        'id': id,
        'email': email,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        'name': name,
        'createdAt': now,
        'updatedAt': now,
      },
    );
  }

  Future<List<Map<String, dynamic>>> customWords(
    String uid, {
    bool dueOnly = false,
  }) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM custom_words
WHERE uid=@uid ${dueOnly ? 'AND next_review_at <= NOW()' : ''}
ORDER BY ${dueOnly ? 'next_review_at ASC, updated_at DESC' : 'updated_at DESC'}
'''),
      parameters: {'uid': uid},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> customWordById(String uid, String id) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM custom_words WHERE uid=@uid AND id=@id LIMIT 1'),
      parameters: {'uid': uid, 'id': id},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>?> customWordByWord(String uid, String word) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT * FROM custom_words WHERE uid=@uid AND LOWER(word)=LOWER(@word) LIMIT 1',
      ),
      parameters: {'uid': uid, 'word': word},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>> upsertCustomWord(
    String uid,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final now = DateTime.now().toUtc();
    final wordId = id ?? data['id'] as String;
    final existing = await customWordById(uid, wordId);
    final createdAt =
        existing?['created_at'] as DateTime? ?? _date(data['createdAt']) ?? now;
    final nextReviewAt = _date(data['nextReviewAt']) ?? now;

    await connection.execute(
      Sql.named('''
INSERT INTO custom_words (
  id, uid, word, meaning, example_sentence, note, tag, difficulty,
  status, ease_factor, interval_days, repetition_count, lapse_count,
  mastery_level, correct_count, wrong_count,
  meaning_recognition_score, meaning_recall_score, spelling_score,
  listening_score, context_score, confidence_score,
  next_review_at, last_reviewed_at, created_at, updated_at
) VALUES (
  @id, @uid, @word, @meaning, @exampleSentence, @note, @tag, @difficulty,
  @status, @easeFactor, @intervalDays, @repetitionCount, @lapseCount,
  @masteryLevel, @correctCount, @wrongCount,
  @meaningRecognitionScore, @meaningRecallScore, @spellingScore,
  @listeningScore, @contextScore, @confidenceScore,
  @nextReviewAt, @lastReviewedAt, @createdAt, @updatedAt
)
ON CONFLICT (id) DO UPDATE SET
  word=EXCLUDED.word,
  meaning=EXCLUDED.meaning,
  example_sentence=EXCLUDED.example_sentence,
  note=EXCLUDED.note,
  tag=EXCLUDED.tag,
  difficulty=EXCLUDED.difficulty,
  status=EXCLUDED.status,
  ease_factor=EXCLUDED.ease_factor,
  interval_days=EXCLUDED.interval_days,
  repetition_count=EXCLUDED.repetition_count,
  lapse_count=EXCLUDED.lapse_count,
  mastery_level=EXCLUDED.mastery_level,
  correct_count=EXCLUDED.correct_count,
  wrong_count=EXCLUDED.wrong_count,
  meaning_recognition_score=EXCLUDED.meaning_recognition_score,
  meaning_recall_score=EXCLUDED.meaning_recall_score,
  spelling_score=EXCLUDED.spelling_score,
  listening_score=EXCLUDED.listening_score,
  context_score=EXCLUDED.context_score,
  confidence_score=EXCLUDED.confidence_score,
  next_review_at=EXCLUDED.next_review_at,
  last_reviewed_at=EXCLUDED.last_reviewed_at,
  updated_at=EXCLUDED.updated_at
'''),
      parameters: {
        'id': wordId,
        'uid': uid,
        'word': data['word'],
        'meaning': data['meaning'],
        'exampleSentence': data['exampleSentence'] ?? '',
        'note': data['note'] ?? '',
        'tag': data['tag'] ?? 'custom',
        'difficulty': data['difficulty'] ?? 'Medium',
        'status': data['status'] ?? 'Learning',
        'easeFactor': data['easeFactor'] ?? 2.5,
        'intervalDays': data['intervalDays'] ?? 0,
        'repetitionCount': data['repetitionCount'] ?? 0,
        'lapseCount': data['lapseCount'] ?? 0,
        'masteryLevel': data['masteryLevel'] ?? 0,
        'correctCount': data['correctCount'] ?? 0,
        'wrongCount': data['wrongCount'] ?? 0,
        'meaningRecognitionScore': data['meaningRecognitionScore'] ?? 20,
        'meaningRecallScore': data['meaningRecallScore'] ?? 10,
        'spellingScore': data['spellingScore'] ?? 10,
        'listeningScore': data['listeningScore'] ?? 10,
        'contextScore': data['contextScore'] ?? 10,
        'confidenceScore': data['confidenceScore'] ?? 10,
        'nextReviewAt': nextReviewAt,
        'lastReviewedAt': _date(data['lastReviewedAt']),
        'createdAt': createdAt,
        'updatedAt': now,
      },
    );

    return (await customWordById(uid, wordId))!;
  }

  Future<void> deleteCustomWord(String uid, String id) async {
    await connection.execute(
      Sql.named('DELETE FROM custom_words WHERE uid=@uid AND id=@id'),
      parameters: {'uid': uid, 'id': id},
    );
  }

  Future<List<Map<String, dynamic>>> userWords(
    String uid, {
    bool dueOnly = false,
  }) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM user_words
WHERE uid=@uid
  ${dueOnly ? "AND next_review_at <= NOW() AND is_ignored = FALSE AND status NOT IN ('New', 'Previewed', 'Ignored')" : ''}
ORDER BY ${dueOnly ? 'next_review_at ASC, wrong_count DESC' : 'updated_at DESC'}
'''),
      parameters: {'uid': uid},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> userWordById(String uid, String id) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM user_words WHERE uid=@uid AND id=@id LIMIT 1'),
      parameters: {'uid': uid, 'id': id},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>> upsertUserWord(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final rows = await upsertUserWords(uid, [data]);
    return rows.first;
  }

  Future<List<Map<String, dynamic>>> upsertUserWords(
    String uid,
    List<Map<String, dynamic>> words,
  ) async {
    if (words.isEmpty) return [];
    final saved = <Map<String, dynamic>>[];
    for (final data in words) {
      final now = DateTime.now().toUtc();
      final wordId = data['id'] as String;
      final createdAt = _date(data['createdAt']) ?? now;
      final rows = await connection.execute(
        Sql.named('''
INSERT INTO user_words (
  id, uid, word_id, word_book_id, word, meaning, example_sentence, difficulty,
  status, is_favorite, is_in_new_word_book, is_ignored,
  ease_factor, interval_days, repetition_count, lapse_count, mastery_level,
  correct_count, wrong_count,
  meaning_recognition_score, meaning_recall_score, spelling_score,
  listening_score, context_score, confidence_score,
  next_review_at, last_reviewed_at, created_at, updated_at
) VALUES (
  @id, @uid, @wordId, @wordBookId, @word, @meaning, @exampleSentence, @difficulty,
  @status, @isFavorite, @isInNewWordBook, @isIgnored,
  @easeFactor, @intervalDays, @repetitionCount, @lapseCount, @masteryLevel,
  @correctCount, @wrongCount,
  @meaningRecognitionScore, @meaningRecallScore, @spellingScore,
  @listeningScore, @contextScore, @confidenceScore,
  @nextReviewAt, @lastReviewedAt, @createdAt, @updatedAt
)
ON CONFLICT (id) DO UPDATE SET
  word_book_id=EXCLUDED.word_book_id,
  word=EXCLUDED.word,
  meaning=EXCLUDED.meaning,
  example_sentence=EXCLUDED.example_sentence,
  difficulty=EXCLUDED.difficulty,
  status=EXCLUDED.status,
  is_favorite=EXCLUDED.is_favorite,
  is_in_new_word_book=EXCLUDED.is_in_new_word_book,
  is_ignored=EXCLUDED.is_ignored,
  ease_factor=EXCLUDED.ease_factor,
  interval_days=EXCLUDED.interval_days,
  repetition_count=EXCLUDED.repetition_count,
  lapse_count=EXCLUDED.lapse_count,
  mastery_level=EXCLUDED.mastery_level,
  correct_count=EXCLUDED.correct_count,
  wrong_count=EXCLUDED.wrong_count,
  meaning_recognition_score=EXCLUDED.meaning_recognition_score,
  meaning_recall_score=EXCLUDED.meaning_recall_score,
  spelling_score=EXCLUDED.spelling_score,
  listening_score=EXCLUDED.listening_score,
  context_score=EXCLUDED.context_score,
  confidence_score=EXCLUDED.confidence_score,
  next_review_at=EXCLUDED.next_review_at,
  last_reviewed_at=EXCLUDED.last_reviewed_at,
  updated_at=EXCLUDED.updated_at
RETURNING *
'''),
        parameters: {
          'id': wordId,
          'uid': uid,
          'wordId': data['wordId'],
          'wordBookId': data['wordBookId'] ?? '',
          'word': data['word'] ?? data['wordId'],
          'meaning': data['meaning'] ?? '',
          'exampleSentence': data['exampleSentence'] ?? '',
          'difficulty': data['difficulty'] ?? 'Medium',
          'status': data['status'] ?? 'New',
          'isFavorite': data['isFavorite'] ?? false,
          'isInNewWordBook': data['isInNewWordBook'] ?? false,
          'isIgnored': data['isIgnored'] ?? data['status'] == 'Ignored',
          'easeFactor': data['easeFactor'] ?? 2.5,
          'intervalDays': data['intervalDays'] ?? 0,
          'repetitionCount': data['repetitionCount'] ?? 0,
          'lapseCount': data['lapseCount'] ?? 0,
          'masteryLevel': data['masteryLevel'] ?? 0,
          'correctCount': data['correctCount'] ?? 0,
          'wrongCount': data['wrongCount'] ?? 0,
          'meaningRecognitionScore': data['meaningRecognitionScore'] ?? 20,
          'meaningRecallScore': data['meaningRecallScore'] ?? 10,
          'spellingScore': data['spellingScore'] ?? 10,
          'listeningScore': data['listeningScore'] ?? 10,
          'contextScore': data['contextScore'] ?? 10,
          'confidenceScore': data['confidenceScore'] ?? 10,
          'nextReviewAt': _date(data['nextReviewAt']) ?? now,
          'lastReviewedAt': _date(data['lastReviewedAt']),
          'createdAt': createdAt,
          'updatedAt': _date(data['updatedAt']) ?? now,
        },
      );
      saved.add(rows.first.toColumnMap());
    }
    return saved;
  }

  Future<void> insertStudySession(String uid, Map<String, dynamic> data) async {
    await connection.execute(
      Sql.named('''
INSERT INTO study_sessions (
  id, uid, lesson_id, started_at, ended_at, total_questions, correct_answers, xp_earned, mistake_word_ids, answer_events
) VALUES (
  @id, @uid, @lessonId, @startedAt, @endedAt, @totalQuestions, @correctAnswers, @xpEarned, @mistakeWordIds, @answerEvents
)
'''),
      parameters: {
        'id': data['id'],
        'uid': uid,
        'lessonId': data['lessonId'],
        'startedAt': _date(data['startedAt']) ?? DateTime.now().toUtc(),
        'endedAt': _date(data['endedAt']) ?? DateTime.now().toUtc(),
        'totalQuestions': data['totalQuestions'] ?? 0,
        'correctAnswers': data['correctAnswers'] ?? 0,
        'xpEarned': data['xpEarned'] ?? 0,
        'mistakeWordIds': ((data['mistakeWordIds'] as List?) ?? const []).join(
          ',',
        ),
        'answerEvents': jsonEncode((data['answerEvents'] as List?) ?? const []),
      },
    );
  }

  Future<Map<String, dynamic>> grantPoints(
    String uid, {
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  }) async {
    final now = DateTime.now().toUtc();
    final rows = await connection.execute(
      Sql.named('''
WITH inserted AS (
  INSERT INTO point_transactions (
    id, uid, source_type, source_id, points, description, created_at
  ) VALUES (
    @id, @uid, @sourceType, @sourceId, @points, @description, @createdAt
  )
  ON CONFLICT (uid, source_type, source_id) DO NOTHING
  RETURNING points
), updated AS (
  UPDATE users
  SET xp = xp + COALESCE((SELECT points FROM inserted), 0),
      updated_at = @createdAt
  WHERE id = @uid AND EXISTS (SELECT 1 FROM inserted)
  RETURNING *
)
SELECT
  EXISTS (SELECT 1 FROM inserted) AS awarded,
  COALESCE((SELECT points FROM inserted), 0) AS points_awarded,
  COALESCE((SELECT id FROM updated), users.id) AS id,
  COALESCE((SELECT email FROM updated), users.email) AS email,
  COALESCE((SELECT password_hash FROM updated), users.password_hash) AS password_hash,
  COALESCE((SELECT password_salt FROM updated), users.password_salt) AS password_salt,
  COALESCE((SELECT name FROM updated), users.name) AS name,
  COALESCE((SELECT target_exam FROM updated), users.target_exam) AS target_exam,
  COALESCE((SELECT level FROM updated), users.level) AS level,
  COALESCE((SELECT daily_goal FROM updated), users.daily_goal) AS daily_goal,
  COALESCE((SELECT xp FROM updated), users.xp) AS xp,
  COALESCE((SELECT streak FROM updated), users.streak) AS streak,
  COALESCE((SELECT last_study_date FROM updated), users.last_study_date) AS last_study_date,
  COALESCE((SELECT created_at FROM updated), users.created_at) AS created_at,
  COALESCE((SELECT updated_at FROM updated), users.updated_at) AS updated_at
FROM users
WHERE id = @uid
LIMIT 1
'''),
      parameters: {
        'id': newId(),
        'uid': uid,
        'sourceType': sourceType,
        'sourceId': sourceId,
        'points': points,
        'description': description,
        'createdAt': now,
      },
    );
    if (rows.isEmpty) throw StateError('user not found');
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>?> studyPlanByUid(String uid) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM study_plans WHERE uid=@uid LIMIT 1'),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>?> studyPlanByScope(
    String uid,
    String language,
    String wordBookId,
  ) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT * FROM study_plans WHERE uid=@uid AND language=@language AND word_book_id=@wordBookId LIMIT 1',
      ),
      parameters: {'uid': uid, 'language': language, 'wordBookId': wordBookId},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>> upsertStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final language = data['language'] as String? ?? 'zh';
    final wordBookId = data['wordBookId'] as String;
    final existing = await studyPlanByScope(uid, language, wordBookId);
    final now = DateTime.now().toUtc();
    final id = studyPlanRowId(existing);
    final updatedAt = _date(data['now']) ?? now;
    await connection.execute(
      Sql.named('''
INSERT INTO study_plans (
  id, uid, language, word_book_id, daily_new_target, daily_review_limit, start_date,
  target_finish_date, reminder_time, status, created_at, updated_at
) VALUES (
  @id, @uid, @language, @wordBookId, @dailyNewTarget, @dailyReviewLimit, @startDate,
  @targetFinishDate, @reminderTime, @status, @createdAt, @updatedAt
)
ON CONFLICT (uid, language, word_book_id) DO UPDATE SET
  daily_new_target=EXCLUDED.daily_new_target,
  daily_review_limit=EXCLUDED.daily_review_limit,
  start_date=EXCLUDED.start_date,
  target_finish_date=EXCLUDED.target_finish_date,
  reminder_time=EXCLUDED.reminder_time,
  status=EXCLUDED.status,
  updated_at=EXCLUDED.updated_at
'''),
      parameters: {
        'id': id,
        'uid': uid,
        'language': language,
        'wordBookId': wordBookId,
        'dailyNewTarget': data['dailyNewTarget'],
        'dailyReviewLimit': data['dailyReviewLimit'],
        'startDate': data['startDate'],
        'targetFinishDate': data['targetFinishDate'],
        'reminderTime': data['reminderTime'],
        'status': data['status'],
        'createdAt': existing?['created_at'] ?? _date(data['createdAt']) ?? now,
        'updatedAt': updatedAt,
      },
    );
    return (await studyPlanByScope(uid, language, wordBookId))!;
  }

  Future<void> resetCustomWordProgress(String uid, {DateTime? now}) async {
    final resetAt = now ?? DateTime.now().toUtc();
    await connection.execute(
      Sql.named(resetCustomWordProgressSql),
      parameters: {'uid': uid, 'resetAt': resetAt},
    );
  }

  Future<void> insertReviewEvent(String uid, Map<String, dynamic> data) async {
    await connection.execute(
      Sql.named('''
INSERT INTO review_events (
  id, uid, word_id, is_correct, answer_time_ms, confidence, wrong_option, reviewed_at, mastery_before, mastery_after, next_review_at
) VALUES (
  @id, @uid, @wordId, @isCorrect, @answerTimeMs, @confidence, @wrongOption, @reviewedAt, @masteryBefore, @masteryAfter, @nextReviewAt
)
'''),
      parameters: {
        'id': data['id'],
        'uid': uid,
        'wordId': data['wordId'],
        'isCorrect': data['isCorrect'],
        'answerTimeMs': data['answerTimeMs'] ?? 0,
        'confidence': data['confidence'] ?? 3,
        'wrongOption': data['wrongOption'] ?? data['wrong_option'],
        'reviewedAt': _date(data['reviewedAt']) ?? DateTime.now().toUtc(),
        'masteryBefore': data['masteryBefore'] ?? 0,
        'masteryAfter': data['masteryAfter'] ?? 0,
        'nextReviewAt': _date(data['nextReviewAt']) ?? DateTime.now().toUtc(),
      },
    );
  }

  Future<void> insertExerciseRecords(
    String uid,
    List<Map<String, dynamic>> records,
  ) async {
    for (final data in records) {
      await connection.execute(
        Sql.named('''
INSERT INTO exercise_records (
  id, uid, session_id, game_id, word_id, prompt_type, is_correct,
  answer, correct_answer, answer_time_ms, dimension, created_at
) VALUES (
  @id, @uid, @sessionId, @gameId, @wordId, @promptType, @isCorrect,
  @answer, @correctAnswer, @answerTimeMs, @dimension, @createdAt
)
ON CONFLICT (id) DO NOTHING
'''),
        parameters: {
          'id': data['id'],
          'uid': uid,
          'sessionId': data['sessionId'],
          'gameId': data['gameId'],
          'wordId': data['wordId'],
          'promptType': data['promptType'] ?? 'choice',
          'isCorrect': data['isCorrect'] ?? false,
          'answer': data['answer'] ?? '',
          'correctAnswer': data['correctAnswer'] ?? '',
          'answerTimeMs': data['answerTimeMs'] ?? 0,
          'dimension': data['dimension'] ?? 'confidence',
          'createdAt': _date(data['createdAt']) ?? DateTime.now().toUtc(),
        },
      );
    }
  }

  /// Returns true if the user has at least one session where all answers
  /// were correct and the session contained at least 4 records.
  Future<bool> hasPerfectSession(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT session_id
FROM exercise_records
WHERE uid = @uid
GROUP BY session_id
HAVING COUNT(*) >= 4 AND bool_and(is_correct)
LIMIT 1
'''),
      parameters: {'uid': uid},
    );
    return rows.isNotEmpty;
  }

  /// Returns true if the user has at least one exercise record with
  /// dimension = 'listening'.
  Future<bool> hasListeningRecord(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT 1 FROM exercise_records
WHERE uid = @uid AND dimension = 'listening'
LIMIT 1
'''),
      parameters: {'uid': uid},
    );
    return rows.isNotEmpty;
  }

  /// Returns true if the user has at least one user_word in Japanese.
  Future<bool> hasJapaneseStudy(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT 1 FROM user_words
WHERE uid = @uid AND language = 'ja'
LIMIT 1
'''),
      parameters: {'uid': uid},
    );
    return rows.isNotEmpty;
  }

  /// Returns true if the user has at least one reading-comprehension exercise
  /// record (game_id prefixed 'reading-', written by completeReading).
  Future<bool> hasReadingRecord(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT 1 FROM exercise_records
WHERE uid = @uid AND game_id LIKE 'reading-%'
LIMIT 1
'''),
      parameters: {'uid': uid},
    );
    return rows.isNotEmpty;
  }

  /// Sets users.first_map_language_at to now if not already set.
  Future<void> setFirstMapLanguageAt(String uid) async {
    await connection.execute(
      Sql.named('''
UPDATE users
SET first_map_language_at = NOW()
WHERE id = @uid AND first_map_language_at IS NULL
'''),
      parameters: {'uid': uid},
    );
  }

  /// Returns users.first_map_language_at for the given user (null if not set).
  Future<DateTime?> firstMapLanguageAt(String uid) async {
    final rows = await connection.execute(
      Sql.named('SELECT first_map_language_at FROM users WHERE id = @uid'),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return null;
    return rows.first[0] as DateTime?;
  }

  Future<List<String>> completedLessonIds(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT DISTINCT lesson_id FROM study_sessions
WHERE uid=@uid
ORDER BY lesson_id
'''),
      parameters: {'uid': uid},
    );
    return [
      for (final row in rows)
        if (row[0] != null) row[0].toString(),
    ];
  }

  Future<List<String>> lessonIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT DISTINCT lesson_id FROM study_sessions
WHERE uid=@uid AND ended_at >= @startUtc AND ended_at < @endUtc
ORDER BY lesson_id
'''),
      parameters: {'uid': uid, 'startUtc': startUtc, 'endUtc': endUtc},
    );
    return [
      for (final row in rows)
        if (row[0] != null) row[0].toString(),
    ];
  }

  Future<List<String>> reviewWordIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT DISTINCT word_id FROM review_events
WHERE uid=@uid AND reviewed_at >= @startUtc AND reviewed_at < @endUtc
ORDER BY word_id
'''),
      parameters: {'uid': uid, 'startUtc': startUtc, 'endUtc': endUtc},
    );
    return [
      for (final row in rows)
        if (row[0] != null) row[0].toString(),
    ];
  }

  Future<List<String>> rewardIdsForDate(String uid, String localDate) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT reward_id FROM reward_claims
WHERE uid=@uid AND local_date=@localDate
ORDER BY claimed_at
'''),
      parameters: {'uid': uid, 'localDate': localDate},
    );
    return [
      for (final row in rows)
        if (row[0] != null) row[0].toString(),
    ];
  }

  Future<bool> claimReward({
    required String uid,
    required String rewardId,
    required String localDate,
    required int points,
  }) async {
    final now = DateTime.now().toUtc();
    return connection.runTx((tx) async {
      final rows = await tx.execute(
        Sql.named('''
INSERT INTO reward_claims (uid, reward_id, local_date, points, claimed_at)
VALUES (@uid, @rewardId, @localDate, @points, @claimedAt)
ON CONFLICT (uid, reward_id, local_date) DO NOTHING
RETURNING reward_id
'''),
        parameters: {
          'uid': uid,
          'rewardId': rewardId,
          'localDate': localDate,
          'points': points,
          'claimedAt': now,
        },
      );
      if (rows.isEmpty) return false;
      await tx.execute(
        Sql.named('''
UPDATE users
SET xp = xp + @points,
    updated_at = @updatedAt
WHERE id=@uid
'''),
        parameters: {'uid': uid, 'points': points, 'updatedAt': now},
      );
      return true;
    });
  }

  Future<List<Map<String, dynamic>>> notifications(
    String uid, {
    bool unreadOnly = false,
    String? type,
  }) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM notifications
WHERE uid=@uid
  ${unreadOnly ? 'AND is_read = FALSE' : ''}
  ${type == null ? '' : 'AND type = @type'}
ORDER BY created_at DESC
'''),
      parameters: {'uid': uid, if (type != null) 'type': type},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> notificationById(String uid, String id) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT * FROM notifications WHERE uid=@uid AND id=@id LIMIT 1',
      ),
      parameters: {'uid': uid, 'id': id},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<void> upsertNotification(
    String uid,
    Map<String, dynamic> data, {
    Session? session,
  }) async {
    await upsertNotifications(uid, [data], session: session);
  }

  Future<void> upsertNotifications(
    String uid,
    List<Map<String, dynamic>> notifications, {
    Session? session,
  }) async {
    if (notifications.isEmpty) return;
    final executor = session ?? connection;
    final values = <String>[];
    final parameters = <String, dynamic>{'uid': uid};
    for (var index = 0; index < notifications.length; index++) {
      final data = notifications[index];
      values.add('''
(@id$index, @uid, @type$index, @title$index, @body$index, @targetRoute$index,
 @isRead$index, @sourceKey$index, @params$index, @readAt$index, @createdAt$index)
''');
      parameters.addAll({
        'id$index': data['id'],
        'type$index': data['type'],
        'title$index': data['title'],
        'body$index': data['body'],
        'targetRoute$index': data['targetRoute'] ?? '/home',
        'isRead$index': data['isRead'] ?? false,
        'sourceKey$index': data['sourceKey'],
        'params$index': jsonEncode(_mapValue(data['params'])),
        'readAt$index': _date(data['readAt']),
        'createdAt$index': _date(data['createdAt']) ?? DateTime.now().toUtc(),
      });
    }
    await executor.execute(
      Sql.named('''
INSERT INTO notifications (
  id, uid, type, title, body, target_route, is_read, source_key, params, read_at, created_at
) VALUES
  ${values.join(',\n')}
ON CONFLICT (uid, source_key) DO UPDATE SET
  type=EXCLUDED.type,
  title=EXCLUDED.title,
  body=EXCLUDED.body,
  target_route=EXCLUDED.target_route,
  params=EXCLUDED.params
WHERE notifications.type IS DISTINCT FROM EXCLUDED.type
   OR notifications.title IS DISTINCT FROM EXCLUDED.title
   OR notifications.body IS DISTINCT FROM EXCLUDED.body
   OR notifications.target_route IS DISTINCT FROM EXCLUDED.target_route
   OR notifications.params IS DISTINCT FROM EXCLUDED.params
'''),
      parameters: parameters,
    );
  }

  Future<Map<String, dynamic>?> markNotificationRead(
    String uid,
    String id,
  ) async {
    final rows = await connection.execute(
      Sql.named('''
UPDATE notifications
SET is_read = TRUE,
    read_at = COALESCE(read_at, @readAt)
WHERE uid=@uid AND id=@id
RETURNING *
'''),
      parameters: {'uid': uid, 'id': id, 'readAt': DateTime.now().toUtc()},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<int> markAllNotificationsRead(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
UPDATE notifications
SET is_read = TRUE,
    read_at = COALESCE(read_at, @readAt)
WHERE uid=@uid AND is_read = FALSE
RETURNING id
'''),
      parameters: {'uid': uid, 'readAt': DateTime.now().toUtc()},
    );
    return rows.length;
  }

  Future<List<Map<String, dynamic>>> lotteryPrizes({Session? session}) async {
    final executor = session ?? connection;
    final rows = await executor.execute('''
SELECT * FROM lottery_prizes
WHERE is_active = TRUE
ORDER BY probability DESC, rarity, name
''');
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<List<Map<String, dynamic>>> userAssets(
    String uid, {
    Session? session,
  }) async {
    final executor = session ?? connection;
    final rows = await executor.execute(
      Sql.named('''
SELECT * FROM user_assets
WHERE uid=@uid
ORDER BY updated_at DESC
'''),
      parameters: {'uid': uid},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> drawLottery({
    required String uid,
    required String drawId,
    required String assetId,
    required String notificationId,
  }) async {
    final now = DateTime.now().toUtc();
    return connection.runTx((tx) async {
      final userRows = await tx.execute(
        Sql.named('''
UPDATE users
SET xp = xp - @cost,
    updated_at = @updatedAt
WHERE id=@uid AND xp >= @cost
RETURNING xp
'''),
        parameters: {'uid': uid, 'cost': lotteryDrawCost, 'updatedAt': now},
      );
      if (userRows.isEmpty) {
        return null;
      }
      final prizes = await lotteryPrizes(session: tx);
      final prize = chooseLotteryPrize(prizes);
      final balanceAfter = userRows.first.toColumnMap()['xp'] as int;

      await tx.execute(
        Sql.named('''
INSERT INTO lottery_draws (
  id, uid, prize_id, cost, balance_after, prize_name, prize_category,
  prize_rarity, created_at
) VALUES (
  @id, @uid, @prizeId, @cost, @balanceAfter, @prizeName, @prizeCategory,
  @prizeRarity, @createdAt
)
'''),
        parameters: {
          'id': drawId,
          'uid': uid,
          'prizeId': prize['id'],
          'cost': lotteryDrawCost,
          'balanceAfter': balanceAfter,
          'prizeName': prize['name'],
          'prizeCategory': prize['category'],
          'prizeRarity': prize['rarity'],
          'createdAt': now,
        },
      );

      final assetRows = await tx.execute(
        Sql.named('''
INSERT INTO user_assets (
  id, uid, prize_id, category, rarity, name, description, quantity,
  fragment_value, acquired_at, updated_at
) VALUES (
  @id, @uid, @prizeId, @category, @rarity, @name, @description, 1,
  @fragmentValue, @acquiredAt, @updatedAt
)
ON CONFLICT (uid, prize_id) DO UPDATE SET
  quantity=user_assets.quantity + 1,
  category=EXCLUDED.category,
  rarity=EXCLUDED.rarity,
  name=EXCLUDED.name,
  description=EXCLUDED.description,
  fragment_value=EXCLUDED.fragment_value,
  updated_at=EXCLUDED.updated_at
RETURNING *
'''),
        parameters: {
          'id': assetId,
          'uid': uid,
          'prizeId': prize['id'],
          'category': prize['category'],
          'rarity': prize['rarity'],
          'name': prize['name'],
          'description': prize['description'],
          'fragmentValue':
              prize['fragment_value'] ?? prize['fragmentValue'] ?? 0,
          'acquiredAt': now,
          'updatedAt': now,
        },
      );

      await upsertNotification(uid, {
        'id': notificationId,
        'type': 'activity',
        'title': '积分抽奖结果',
        'body': '获得「${prize['name']}」，已放入个人资产。',
        'targetRoute': '/profile',
        'isRead': false,
        'sourceKey': 'lottery:$drawId',
        'params': {'kind': 'lottery', 'prizeName': prize['name']},
        'createdAt': now,
      }, session: tx);
      return {
        'draw': {
          'id': drawId,
          'uid': uid,
          'prizeId': prize['id'],
          'cost': lotteryDrawCost,
          'balanceAfter': balanceAfter,
          'createdAt': now.toIso8601String(),
        },
        'prize': prize,
        'asset': assetRows.first.toColumnMap(),
        'balanceAfter': balanceAfter,
      };
    });
  }

  Future<bool> hasStudySessionInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc, {
    bool? trainingOnly,
  }) async {
    final trainingClause = trainingOnly == null
        ? ''
        : trainingOnly
        ? "AND lesson_id LIKE 'lesson-campus-%'"
        : "AND lesson_id NOT LIKE 'lesson-campus-%'";
    final rows = await connection.execute(
      Sql.named('''
SELECT id FROM study_sessions
WHERE uid=@uid AND ended_at >= @startUtc AND ended_at < @endUtc
$trainingClause
LIMIT 1
'''),
      parameters: {'uid': uid, 'startUtc': startUtc, 'endUtc': endUtc},
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasReviewEventInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT id FROM review_events
WHERE uid=@uid AND reviewed_at >= @startUtc AND reviewed_at < @endUtc
LIMIT 1
'''),
      parameters: {'uid': uid, 'startUtc': startUtc, 'endUtc': endUtc},
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasCheckIn(String uid, String dateKey) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT uid FROM daily_checkins
WHERE uid=@uid AND date_key=@dateKey
LIMIT 1
'''),
      parameters: {'uid': uid, 'dateKey': dateKey},
    );
    return rows.isNotEmpty;
  }

  Future<bool> upsertCheckIn(String uid, String dateKey) async {
    final rows = await connection.execute(
      Sql.named('''
INSERT INTO daily_checkins (uid, date_key, checked_in_at)
VALUES (@uid, @dateKey, @checkedInAt)
ON CONFLICT (uid, date_key) DO NOTHING
RETURNING uid
'''),
      parameters: {
        'uid': uid,
        'dateKey': dateKey,
        'checkedInAt': DateTime.now().toUtc(),
      },
    );
    return rows.isNotEmpty;
  }

  Future<Map<String, dynamic>> dailyActivity(String uid, String dateKey) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM daily_activity
WHERE uid=@uid AND date_key=@dateKey
LIMIT 1
'''),
      parameters: {'uid': uid, 'dateKey': dateKey},
    );
    if (rows.isEmpty) return const <String, dynamic>{};
    return rows.first.toColumnMap();
  }

  Future<void> recordDailyActivity(
    String uid,
    String dateKey,
    String type,
  ) async {
    final field = switch (type) {
      'trainingChallenge' => 'training_challenge_completed',
      'wrongCleanup' => 'wrong_cleanup_completed',
      'forumInteraction' => 'forum_interaction_completed',
      _ => throw ArgumentError.value(type, 'type', 'unsupported activity type'),
    };
    await connection.execute(
      Sql.named('''
INSERT INTO daily_activity (uid, date_key, $field, updated_at)
VALUES (@uid, @dateKey, TRUE, @updatedAt)
ON CONFLICT (uid, date_key) DO UPDATE SET
  $field = TRUE,
  updated_at = EXCLUDED.updated_at
'''),
      parameters: {
        'uid': uid,
        'dateKey': dateKey,
        'updatedAt': DateTime.now().toUtc(),
      },
    );
  }

  Future<Set<String>> rewardClaimsForDate(String uid, String dateKey) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT task_id FROM daily_task_claims
WHERE uid=@uid AND date_key=@dateKey
'''),
      parameters: {'uid': uid, 'dateKey': dateKey},
    );
    return rows
        .map((row) => row.toColumnMap()['task_id']?.toString())
        .whereType<String>()
        .toSet();
  }

  Future<bool> insertRewardClaim({
    required String id,
    required String uid,
    required String dateKey,
    required String taskId,
    required int points,
  }) async {
    final rows = await connection.execute(
      Sql.named('''
INSERT INTO daily_task_claims (id, uid, date_key, task_id, points, claimed_at)
VALUES (@id, @uid, @dateKey, @taskId, @points, @claimedAt)
ON CONFLICT (uid, date_key, task_id) DO NOTHING
RETURNING id
'''),
      parameters: {
        'id': id,
        'uid': uid,
        'dateKey': dateKey,
        'taskId': taskId,
        'points': points,
        'claimedAt': DateTime.now().toUtc(),
      },
    );
    return rows.isNotEmpty;
  }

  Future<({bool inserted, Map<String, dynamic>? user})> claimRewardTask({
    required String id,
    required String uid,
    required String dateKey,
    required String taskId,
    required int points,
  }) async {
    return connection.runTx((tx) async {
      final insertedRows = await tx.execute(
        Sql.named('''
INSERT INTO daily_task_claims (id, uid, date_key, task_id, points, claimed_at)
VALUES (@id, @uid, @dateKey, @taskId, @points, @claimedAt)
ON CONFLICT (uid, date_key, task_id) DO NOTHING
RETURNING id
'''),
        parameters: {
          'id': id,
          'uid': uid,
          'dateKey': dateKey,
          'taskId': taskId,
          'points': points,
          'claimedAt': DateTime.now().toUtc(),
        },
      );
      final inserted = insertedRows.isNotEmpty;
      if (!inserted) {
        final rows = await tx.execute(
          Sql.named('SELECT * FROM users WHERE id=@uid LIMIT 1'),
          parameters: {'uid': uid},
        );
        return (
          inserted: false,
          user: rows.isEmpty ? null : rows.first.toColumnMap(),
        );
      }
      final rows = await tx.execute(
        Sql.named('''
UPDATE users
SET xp = xp + @points,
    updated_at = @updatedAt
WHERE id=@uid
RETURNING *
'''),
        parameters: {
          'uid': uid,
          'points': points,
          'updatedAt': DateTime.now().toUtc(),
        },
      );
      return (
        inserted: inserted,
        user: rows.isEmpty ? null : rows.first.toColumnMap(),
      );
    });
  }

  Future<Map<String, dynamic>?> addUserXp(String uid, int points) async {
    final rows = await connection.execute(
      Sql.named('''
UPDATE users
SET xp = xp + @points,
    updated_at = @updatedAt
WHERE id=@uid
RETURNING *
'''),
      parameters: {
        'uid': uid,
        'points': points,
        'updatedAt': DateTime.now().toUtc(),
      },
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<int> dueReviewCount(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT
  (SELECT COUNT(*) FROM custom_words WHERE uid=@uid AND next_review_at <= NOW()) +
  (SELECT COUNT(*) FROM user_words
   WHERE uid=@uid
     AND next_review_at <= NOW()
     AND is_ignored = FALSE
     AND status IN ('Review', 'Relearning', 'Mastered')) AS count
'''),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return 0;
    final value = rows.first.toColumnMap()['count'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  Future<Map<String, dynamic>> insertAiHistory(
    String userId,
    String featureType,
    String prompt,
    Map<String, dynamic> response,
  ) async {
    final result = await connection.execute(
      Sql.named(
        "INSERT INTO ai_history (user_id, feature_type, prompt, response) "
        "VALUES (@userId, @featureType, @prompt, @response::jsonb) "
        "RETURNING id, user_id, feature_type, prompt, response, is_deleted, created_at",
      ),
      parameters: {
        'userId': userId,
        'featureType': featureType,
        'prompt': prompt,
        'response': jsonEncode(response),
      },
    );
    final row = result.first;
    return {
      'id': row[0].toString(),
      'userId': row[1],
      'featureType': row[2],
      'prompt': row[3],
      'response': row[4],
      'isDeleted': row[5],
      'createdAt': row[6].toString(),
    };
  }

  Future<List<Map<String, dynamic>>> listAiHistory(String userId) async {
    final result = await connection.execute(
      Sql.named(
        'SELECT id, user_id, feature_type, prompt, response, is_deleted, created_at '
        'FROM ai_history '
        'WHERE user_id=@userId AND is_deleted=FALSE '
        'ORDER BY created_at DESC',
      ),
      parameters: {'userId': userId},
    );
    return result.map((row) {
      return {
        'id': row[0].toString(),
        'userId': row[1],
        'featureType': row[2],
        'prompt': row[3],
        'response': row[4],
        'isDeleted': row[5],
        'createdAt': row[6].toString(),
      };
    }).toList();
  }

  Future<bool> softDeleteAiHistory(String userId, String historyId) async {
    final result = await connection.execute(
      Sql.named(
        'UPDATE ai_history SET is_deleted=TRUE '
        'WHERE id=@id::uuid AND user_id=@userId AND is_deleted=FALSE',
      ),
      parameters: {'id': historyId, 'userId': userId},
    );
    return result.affectedRows > 0;
  }

  Future<int> countAiHistoryToday(String userId) async {
    final result = await connection.execute(
      Sql.named(countAiHistoryTodaySql),
      parameters: {'userId': userId},
    );
    if (result.isEmpty) return 0;
    return (result.first[0] as int?) ?? 0;
  }

  // ---------------------------------------------------------------------------
  // Forum
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> listForumPosts({String? status}) async {
    final whereClause = status != null ? 'WHERE fp.status=@status' : '';
    final rows = await connection.execute(
      Sql.named(
        'SELECT fp.id, fp.author_id, fp.title, fp.body, fp.tag, fp.status, '
        'fp.like_count, '
        "(SELECT COUNT(*) FROM forum_comments fc "
        "WHERE fc.post_id=fp.id AND fc.status='approved') AS comment_count, "
        'fp.created_at, fp.updated_at, u.name AS author_name '
        'FROM forum_posts fp '
        'LEFT JOIN users u ON u.id = fp.author_id '
        '$whereClause ORDER BY fp.created_at DESC',
      ),
      parameters: {if (status != null) 'status': status},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> getForumPost(String id) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT fp.id, fp.author_id, fp.title, fp.body, fp.tag, fp.status, '
        'fp.like_count, '
        "(SELECT COUNT(*) FROM forum_comments fc "
        "WHERE fc.post_id=fp.id AND fc.status='approved') AS comment_count, "
        'fp.created_at, fp.updated_at, u.name AS author_name '
        'FROM forum_posts fp '
        'LEFT JOIN users u ON u.id = fp.author_id '
        'WHERE fp.id=@id::uuid LIMIT 1',
      ),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>> insertForumPost(
    Map<String, dynamic> data,
  ) async {
    final result = await connection.execute(
      Sql.named('''
INSERT INTO forum_posts (author_id, title, body, tag, status)
VALUES (@authorId, @title, @body, @tag, @status)
RETURNING id, author_id, title, body, tag, status, like_count, comment_count, created_at, updated_at
'''),
      parameters: {
        'authorId': data['authorId'],
        'title': data['title'],
        'body': data['body'],
        'tag': data['tag'] ?? 'General',
        'status': data['status'] ?? 'approved',
      },
    );
    final row = result.first;
    return _forumPostRowToMap(row);
  }

  Future<Map<String, dynamic>> insertForumComment(
    Map<String, dynamic> data,
  ) async {
    final result = await connection.execute(
      Sql.named('''
INSERT INTO forum_comments (post_id, author_id, body, status)
VALUES (@postId::uuid, @authorId, @body, @status)
RETURNING id, post_id, author_id, body, status, created_at
'''),
      parameters: {
        'postId': data['postId'],
        'authorId': data['authorId'],
        'body': data['body'],
        'status': data['status'] ?? 'approved',
      },
    );
    await connection.execute(
      Sql.named('''
UPDATE forum_posts
SET comment_count = comment_count + 1, updated_at = NOW()
WHERE id = @postId::uuid
'''),
      parameters: {'postId': data['postId']},
    );
    final row = result.first;
    return {
      'id': row[0].toString(),
      'postId': row[1].toString(),
      'authorId': row[2],
      'body': row[3],
      'status': row[4],
      'createdAt': (row[5] as DateTime).toIso8601String(),
    };
  }

  Future<List<Map<String, dynamic>>> listForumComments(String postId) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM forum_comments
WHERE post_id=@postId::uuid AND status='approved'
ORDER BY created_at ASC
'''),
      parameters: {'postId': postId},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  /// Returns true if the like was added, false if it was removed.
  Future<bool> toggleLike(String userId, String postId) async {
    return connection.runTx((tx) async {
      final existing = await tx.execute(
        Sql.named(
          'SELECT user_id FROM forum_likes WHERE user_id=@userId AND post_id=@postId::uuid LIMIT 1',
        ),
        parameters: {'userId': userId, 'postId': postId},
      );
      if (existing.isNotEmpty) {
        await tx.execute(
          Sql.named(
            'DELETE FROM forum_likes WHERE user_id=@userId AND post_id=@postId::uuid',
          ),
          parameters: {'userId': userId, 'postId': postId},
        );
        await tx.execute(
          Sql.named(
            'UPDATE forum_posts SET like_count = GREATEST(like_count - 1, 0), updated_at=NOW() WHERE id=@postId::uuid',
          ),
          parameters: {'postId': postId},
        );
        return false;
      } else {
        await tx.execute(
          Sql.named(
            'INSERT INTO forum_likes (user_id, post_id) VALUES (@userId, @postId::uuid) ON CONFLICT DO NOTHING',
          ),
          parameters: {'userId': userId, 'postId': postId},
        );
        await tx.execute(
          Sql.named(
            'UPDATE forum_posts SET like_count = like_count + 1, updated_at=NOW() WHERE id=@postId::uuid',
          ),
          parameters: {'postId': postId},
        );
        return true;
      }
    });
  }

  /// Returns true if the favorite was added, false if it was removed.
  Future<bool> toggleFavorite(String userId, String postId) async {
    return connection.runTx((tx) async {
      final existing = await tx.execute(
        Sql.named(
          'SELECT user_id FROM forum_favorites WHERE user_id=@userId AND post_id=@postId::uuid LIMIT 1',
        ),
        parameters: {'userId': userId, 'postId': postId},
      );
      if (existing.isNotEmpty) {
        await tx.execute(
          Sql.named(
            'DELETE FROM forum_favorites WHERE user_id=@userId AND post_id=@postId::uuid',
          ),
          parameters: {'userId': userId, 'postId': postId},
        );
        return false;
      } else {
        await tx.execute(
          Sql.named(
            'INSERT INTO forum_favorites (user_id, post_id) VALUES (@userId, @postId::uuid) ON CONFLICT DO NOTHING',
          ),
          parameters: {'userId': userId, 'postId': postId},
        );
        return true;
      }
    });
  }

  Future<bool> hasLiked(String userId, String postId) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT user_id FROM forum_likes WHERE user_id=@userId AND post_id=@postId::uuid LIMIT 1',
      ),
      parameters: {'userId': userId, 'postId': postId},
    );
    return rows.isNotEmpty;
  }

  Future<bool> hasFavorited(String userId, String postId) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT user_id FROM forum_favorites WHERE user_id=@userId AND post_id=@postId::uuid LIMIT 1',
      ),
      parameters: {'userId': userId, 'postId': postId},
    );
    return rows.isNotEmpty;
  }

  /// 返回用户收藏的所有已审核帖子，按创建时间倒序。
  Future<List<Map<String, dynamic>>> listFavoritedPostsByUser(
    String userId,
  ) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT p.id, p.author_id, p.title, p.body, p.tag, p.status, '
        'p.like_count, '
        "(SELECT COUNT(*) FROM forum_comments fc "
        "WHERE fc.post_id=p.id AND fc.status='approved') AS comment_count, "
        'p.created_at, p.updated_at, u.name AS author_name '
        'FROM forum_posts p '
        'JOIN forum_favorites f ON f.post_id = p.id '
        'LEFT JOIN users u ON u.id = p.author_id '
        "WHERE f.user_id = @userId AND p.status = 'approved' "
        'ORDER BY p.created_at DESC',
      ),
      parameters: {'userId': userId},
    );
    return rows.map((r) => r.toColumnMap()).toList();
  }

  static Map<String, dynamic> _forumPostRowToMap(dynamic row) {
    if (row is Map) return Map<String, dynamic>.from(row);
    final list = row as List;
    return {
      'id': list[0].toString(),
      'author_id': list[1],
      'title': list[2],
      'body': list[3],
      'tag': list[4],
      'status': list[5],
      'like_count': list[6],
      'comment_count': list[7],
      'created_at': list[8],
      'updated_at': list[9],
    };
  }

  // ---------------------------------------------------------------------------
  // Study Spots
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> listStudySpots(String userId) async {
    final result = await connection.execute(
      Sql.named(
        'SELECT id, name, latitude, longitude, study_minutes, visit_count, created_at '
        'FROM study_spots WHERE user_id=@userId ORDER BY created_at DESC',
      ),
      parameters: {'userId': userId},
    );
    return result.map((row) => {
          'id': row[0].toString(),
          'name': row[1],
          'latitude': row[2],
          'longitude': row[3],
          'studyMinutes': row[4],
          'visitCount': row[5],
          'createdAt': row[6].toString(),
        }).toList();
  }

  /// Nearby upsert: if an existing spot is within 100 m, increment its
  /// visit_count and bump created_at; otherwise insert a new spot
  /// (visit_count = 1). Returns the affected spot.
  ///
  /// ponytail: SELECT-then-UPDATE/INSERT is not atomic — two concurrent
  /// visits for the same user can both insert or both miss an increment.
  /// Study spots are cosmetic (no trust/data-integrity boundary) and visits
  /// arrive sequentially per user, so this is acceptable; upgrade to a single
  /// upsert with a spatial/unique constraint if concurrency ever matters.
  Future<Map<String, dynamic>> recordStudyVisit(
    String userId, {
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final existing = await connection.execute(
      Sql.named(
        'SELECT id, latitude, longitude FROM study_spots WHERE user_id=@userId',
      ),
      parameters: {'userId': userId},
    );
    final spots = existing
        .map((row) => (
              id: row[0].toString(),
              latitude: (row[1] as num).toDouble(),
              longitude: (row[2] as num).toDouble(),
            ))
        .toList();
    final idx = StudySpotPolicy.nearestWithin(
      spots.map((s) => (latitude: s.latitude, longitude: s.longitude)).toList(),
      latitude,
      longitude,
    );
    const returning =
        'RETURNING id, name, latitude, longitude, study_minutes, visit_count, created_at';
    final result = idx != null
        ? await connection.execute(
            // ponytail: created_at 在就近重访时被更新为最近访问时间，用于 listStudySpots 的
            // 最近优先排序（表结构约定，语义上等同于 last_visited_at；非新增列）。
            Sql.named(
              'UPDATE study_spots SET visit_count = visit_count + 1, created_at = NOW() '
              'WHERE id=@id::uuid AND user_id=@userId $returning',
            ),
            parameters: {'id': spots[idx].id, 'userId': userId},
          )
        : await connection.execute(
            Sql.named(
              'INSERT INTO study_spots (user_id, name, latitude, longitude, visit_count) '
              'VALUES (@userId, @name, @lat, @lng, 1) $returning',
            ),
            parameters: {
              'userId': userId,
              'name': name,
              'lat': latitude,
              'lng': longitude,
            },
          );
    final row = result.first;
    return {
      'id': row[0].toString(),
      'name': row[1],
      'latitude': row[2],
      'longitude': row[3],
      'studyMinutes': row[4],
      'visitCount': row[5],
      'createdAt': row[6].toString(),
    };
  }

  Future<bool> deleteStudySpot(String userId, String id) async {
    final result = await connection.execute(
      Sql.named('DELETE FROM study_spots WHERE id=@id::uuid AND user_id=@userId'),
      parameters: {'id': id, 'userId': userId},
    );
    return result.affectedRows > 0;
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value.toString())?.toUtc();
}

Map<String, dynamic> _mapValue(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}
