import 'package:postgres/postgres.dart';

import 'config.dart';
import 'lottery_policy.dart';

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
  target_exam TEXT NOT NULL DEFAULT 'Daily English',
  level TEXT NOT NULL DEFAULT 'Elementary',
  daily_goal INTEGER NOT NULL DEFAULT 10,
  xp INTEGER NOT NULL DEFAULT 0,
  streak INTEGER NOT NULL DEFAULT 0,
  last_study_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
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
  mastery_level INTEGER NOT NULL DEFAULT 0,
  correct_count INTEGER NOT NULL DEFAULT 0,
  wrong_count INTEGER NOT NULL DEFAULT 0,
  next_review_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
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
  mistake_word_ids TEXT NOT NULL DEFAULT ''
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS review_events (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  answer_time_ms INTEGER NOT NULL,
  reviewed_at TIMESTAMPTZ NOT NULL,
  mastery_before INTEGER NOT NULL,
  mastery_after INTEGER NOT NULL,
  next_review_at TIMESTAMPTZ NOT NULL
);
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
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  UNIQUE (uid, source_key)
);
''');

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

    await _seedLotteryPrizes();
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
  xp=@xp,
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
        'xp': data['xp'] ?? existing['xp'],
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
ORDER BY updated_at DESC
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
  mastery_level, correct_count, wrong_count, next_review_at, created_at, updated_at
) VALUES (
  @id, @uid, @word, @meaning, @exampleSentence, @note, @tag, @difficulty,
  @masteryLevel, @correctCount, @wrongCount, @nextReviewAt, @createdAt, @updatedAt
)
ON CONFLICT (id) DO UPDATE SET
  word=EXCLUDED.word,
  meaning=EXCLUDED.meaning,
  example_sentence=EXCLUDED.example_sentence,
  note=EXCLUDED.note,
  tag=EXCLUDED.tag,
  difficulty=EXCLUDED.difficulty,
  mastery_level=EXCLUDED.mastery_level,
  correct_count=EXCLUDED.correct_count,
  wrong_count=EXCLUDED.wrong_count,
  next_review_at=EXCLUDED.next_review_at,
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
        'masteryLevel': data['masteryLevel'] ?? 0,
        'correctCount': data['correctCount'] ?? 0,
        'wrongCount': data['wrongCount'] ?? 0,
        'nextReviewAt': nextReviewAt,
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

  Future<void> insertStudySession(String uid, Map<String, dynamic> data) async {
    await connection.execute(
      Sql.named('''
INSERT INTO study_sessions (
  id, uid, lesson_id, started_at, ended_at, total_questions, correct_answers, xp_earned, mistake_word_ids
) VALUES (
  @id, @uid, @lessonId, @startedAt, @endedAt, @totalQuestions, @correctAnswers, @xpEarned, @mistakeWordIds
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
      },
    );
  }

  Future<void> insertReviewEvent(String uid, Map<String, dynamic> data) async {
    await connection.execute(
      Sql.named('''
INSERT INTO review_events (
  id, uid, word_id, is_correct, answer_time_ms, reviewed_at, mastery_before, mastery_after, next_review_at
) VALUES (
  @id, @uid, @wordId, @isCorrect, @answerTimeMs, @reviewedAt, @masteryBefore, @masteryAfter, @nextReviewAt
)
'''),
      parameters: {
        'id': data['id'],
        'uid': uid,
        'wordId': data['wordId'],
        'isCorrect': data['isCorrect'],
        'answerTimeMs': data['answerTimeMs'] ?? 0,
        'reviewedAt': _date(data['reviewedAt']) ?? DateTime.now().toUtc(),
        'masteryBefore': data['masteryBefore'] ?? 0,
        'masteryAfter': data['masteryAfter'] ?? 0,
        'nextReviewAt': _date(data['nextReviewAt']) ?? DateTime.now().toUtc(),
      },
    );
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
 @isRead$index, @sourceKey$index, @readAt$index, @createdAt$index)
''');
      parameters.addAll({
        'id$index': data['id'],
        'type$index': data['type'],
        'title$index': data['title'],
        'body$index': data['body'],
        'targetRoute$index': data['targetRoute'] ?? '/home',
        'isRead$index': data['isRead'] ?? false,
        'sourceKey$index': data['sourceKey'],
        'readAt$index': _date(data['readAt']),
        'createdAt$index': _date(data['createdAt']) ?? DateTime.now().toUtc(),
      });
    }
    await executor.execute(
      Sql.named('''
INSERT INTO notifications (
  id, uid, type, title, body, target_route, is_read, source_key, read_at, created_at
) VALUES
  ${values.join(',\n')}
ON CONFLICT (uid, source_key) DO UPDATE SET
  type=EXCLUDED.type,
  title=EXCLUDED.title,
  body=EXCLUDED.body,
  target_route=EXCLUDED.target_route
WHERE notifications.type IS DISTINCT FROM EXCLUDED.type
   OR notifications.title IS DISTINCT FROM EXCLUDED.title
   OR notifications.body IS DISTINCT FROM EXCLUDED.body
   OR notifications.target_route IS DISTINCT FROM EXCLUDED.target_route
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
    DateTime endUtc,
  ) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT id FROM study_sessions
WHERE uid=@uid AND ended_at >= @startUtc AND ended_at < @endUtc
LIMIT 1
'''),
      parameters: {'uid': uid, 'startUtc': startUtc, 'endUtc': endUtc},
    );
    return rows.isNotEmpty;
  }

  Future<int> dueReviewCount(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT COUNT(*) AS count FROM custom_words
WHERE uid=@uid AND next_review_at <= NOW()
'''),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return 0;
    final value = rows.first.toColumnMap()['count'];
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value.toString())?.toUtc();
}
