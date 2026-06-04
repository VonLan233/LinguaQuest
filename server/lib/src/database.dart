import 'package:postgres/postgres.dart';

import 'config.dart';

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
  updated_at TIMESTAMPTZ NOT NULL,
  UNIQUE (uid, word_id, word_book_id)
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
  ${dueOnly ? "AND next_review_at <= NOW() AND is_ignored = FALSE AND status IN ('Review', 'Relearning', 'Mastered')" : ''}
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
      final existing = await userWordById(uid, wordId);
      final createdAt =
          existing?['created_at'] as DateTime? ??
          _date(data['createdAt']) ??
          now;
      await connection.execute(
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
      saved.add((await userWordById(uid, wordId))!);
    }
    return saved;
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

  Future<void> upsertNotification(String uid, Map<String, dynamic> data) async {
    await upsertNotifications(uid, [data]);
  }

  Future<void> upsertNotifications(
    String uid,
    List<Map<String, dynamic>> notifications,
  ) async {
    if (notifications.isEmpty) return;
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
    await connection.execute(
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
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value.toString())?.toUtc();
}
