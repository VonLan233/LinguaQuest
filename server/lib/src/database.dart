import 'dart:convert';

import 'package:postgres/postgres.dart';

import 'config.dart';

const resetCustomWordProgressSql = '''
UPDATE custom_words
SET mastery_level=0,
    correct_count=0,
    wrong_count=0,
    next_review_at=@resetAt,
    updated_at=@resetAt
WHERE uid=@uid
''';

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
  level TEXT NOT NULL DEFAULT 'Intermediate',
  daily_goal INTEGER NOT NULL DEFAULT 10,
  xp INTEGER NOT NULL DEFAULT 0,
  streak INTEGER NOT NULL DEFAULT 0,
  last_study_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
ALTER TABLE users ALTER COLUMN level SET DEFAULT 'Intermediate';
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
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL,
  UNIQUE (uid, source_key)
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
CREATE INDEX IF NOT EXISTS idx_custom_words_uid_next_review
ON custom_words (uid, next_review_at);
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

  Future<Map<String, dynamic>?> studyPlanByUid(String uid) async {
    final rows = await connection.execute(
      Sql.named('SELECT * FROM study_plans WHERE uid=@uid LIMIT 1'),
      parameters: {'uid': uid},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>> upsertStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final existing = await studyPlanByUid(uid);
    final now = DateTime.now().toUtc();
    final id = existing?['id']?.toString() ?? data['id']?.toString();
    final updatedAt = _date(data['now']) ?? now;
    await connection.execute(
      Sql.named('''
INSERT INTO study_plans (
  id, uid, word_book_id, daily_new_target, daily_review_limit, start_date,
  target_finish_date, reminder_time, status, created_at, updated_at
) VALUES (
  @id, @uid, @wordBookId, @dailyNewTarget, @dailyReviewLimit, @startDate,
  @targetFinishDate, @reminderTime, @status, @createdAt, @updatedAt
)
ON CONFLICT (uid) DO UPDATE SET
  word_book_id=EXCLUDED.word_book_id,
  daily_new_target=EXCLUDED.daily_new_target,
  daily_review_limit=EXCLUDED.daily_review_limit,
  start_date=EXCLUDED.start_date,
  target_finish_date=EXCLUDED.target_finish_date,
  reminder_time=EXCLUDED.reminder_time,
  status=EXCLUDED.status,
  updated_at=EXCLUDED.updated_at
'''),
      parameters: {
        'id': id ?? data['id'],
        'uid': uid,
        'wordBookId': data['wordBookId'],
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
    return (await studyPlanByUid(uid))!;
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
