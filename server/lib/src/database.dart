import 'dart:convert';

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
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS avatar_url TEXT,
  ADD COLUMN IF NOT EXISTS daily_new_target INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS daily_review_limit INTEGER NOT NULL DEFAULT 20,
  ADD COLUMN IF NOT EXISTS current_word_book_id TEXT NOT NULL DEFAULT 'beginner',
  ADD COLUMN IF NOT EXISTS total_study_days INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS total_study_minutes INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS points INTEGER NOT NULL DEFAULT 0;
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
CREATE TABLE IF NOT EXISTS classrooms (
  id TEXT PRIMARY KEY,
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  teacher_name TEXT NOT NULL DEFAULT 'LinguaQuest',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS class_members (
  class_id TEXT NOT NULL REFERENCES classrooms(id) ON DELETE CASCADE,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL DEFAULT 'student',
  joined_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (class_id, uid)
);
''');

    await connection.execute('''
ALTER TABLE custom_words
  ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'Learning',
  ADD COLUMN IF NOT EXISTS ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
  ADD COLUMN IF NOT EXISTS interval_days INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS repetition_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS lapse_count INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS meaning_recognition_score INTEGER NOT NULL DEFAULT 20,
  ADD COLUMN IF NOT EXISTS meaning_recall_score INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS spelling_score INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS listening_score INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS context_score INTEGER NOT NULL DEFAULT 10,
  ADD COLUMN IF NOT EXISTS confidence_score INTEGER NOT NULL DEFAULT 10;
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS user_words (
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id TEXT NOT NULL,
  word_book_id TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'New',
  is_favorite BOOLEAN NOT NULL DEFAULT FALSE,
  is_in_new_word_book BOOLEAN NOT NULL DEFAULT FALSE,
  ease_factor DOUBLE PRECISION NOT NULL DEFAULT 2.5,
  interval_days INTEGER NOT NULL DEFAULT 0,
  repetition_count INTEGER NOT NULL DEFAULT 0,
  lapse_count INTEGER NOT NULL DEFAULT 0,
  next_review_at TIMESTAMPTZ NOT NULL,
  last_reviewed_at TIMESTAMPTZ,
  correct_count INTEGER NOT NULL DEFAULT 0,
  wrong_count INTEGER NOT NULL DEFAULT 0,
  meaning_recognition_score INTEGER NOT NULL DEFAULT 0,
  meaning_recall_score INTEGER NOT NULL DEFAULT 0,
  spelling_score INTEGER NOT NULL DEFAULT 0,
  listening_score INTEGER NOT NULL DEFAULT 0,
  context_score INTEGER NOT NULL DEFAULT 0,
  confidence_score INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (uid, word_id)
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS study_plans (
  uid TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  word_book_id TEXT NOT NULL,
  daily_new_target INTEGER NOT NULL DEFAULT 10,
  daily_review_limit INTEGER NOT NULL DEFAULT 20,
  start_date DATE NOT NULL,
  target_finish_date DATE,
  reminder_time TEXT,
  status TEXT NOT NULL DEFAULT 'active',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS study_sessions (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lesson_id TEXT NOT NULL,
  mode TEXT NOT NULL DEFAULT 'lesson',
  source TEXT NOT NULL DEFAULT 'home',
  started_at TIMESTAMPTZ NOT NULL,
  ended_at TIMESTAMPTZ NOT NULL,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  wrong_answers INTEGER NOT NULL DEFAULT 0,
  xp_earned INTEGER NOT NULL,
  earned_points INTEGER NOT NULL DEFAULT 0,
  duration_seconds INTEGER NOT NULL DEFAULT 0,
  mistake_word_ids TEXT NOT NULL DEFAULT ''
);
''');

    await connection.execute('''
ALTER TABLE study_sessions
  ADD COLUMN IF NOT EXISTS mode TEXT NOT NULL DEFAULT 'lesson',
  ADD COLUMN IF NOT EXISTS source TEXT NOT NULL DEFAULT 'home',
  ADD COLUMN IF NOT EXISTS wrong_answers INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS earned_points INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS duration_seconds INTEGER NOT NULL DEFAULT 0;
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS exercise_records (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  word_id TEXT NOT NULL,
  exercise_type TEXT NOT NULL,
  prompt TEXT NOT NULL,
  options TEXT NOT NULL DEFAULT '',
  correct_answer TEXT NOT NULL,
  user_answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  response_time_ms INTEGER NOT NULL DEFAULT 0,
  confidence INTEGER,
  created_at TIMESTAMPTZ NOT NULL
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
CREATE TABLE IF NOT EXISTS reward_claims (
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  task_id TEXT NOT NULL,
  claim_date DATE NOT NULL,
  points INTEGER NOT NULL,
  claimed_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (uid, task_id, claim_date)
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS lottery_draws (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  prize TEXT NOT NULL,
  points_cost INTEGER NOT NULL,
  drawn_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS forum_posts (
  id TEXT PRIMARY KEY,
  author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  image_urls TEXT NOT NULL DEFAULT '',
  tags TEXT NOT NULL DEFAULT '',
  like_count INTEGER NOT NULL DEFAULT 0,
  comment_count INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'published',
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS forum_comments (
  id TEXT PRIMARY KEY,
  post_id TEXT NOT NULL REFERENCES forum_posts(id) ON DELETE CASCADE,
  author_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  content TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'published',
  created_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS notifications (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  target_route TEXT,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS ai_conversations (
  id TEXT PRIMARY KEY,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  feature TEXT NOT NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL,
  updated_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS ai_messages (
  id TEXT PRIMARY KEY,
  conversation_id TEXT NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role TEXT NOT NULL,
  content TEXT NOT NULL,
  payload TEXT NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL
);
''');

    await connection.execute('''
CREATE TABLE IF NOT EXISTS achievements (
  uid TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  achievement_id TEXT NOT NULL,
  unlocked_at TIMESTAMPTZ NOT NULL,
  PRIMARY KEY (uid, achievement_id)
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

  Future<List<Map<String, dynamic>>> classesForUser(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT c.*, cm.role, cm.joined_at,
  (SELECT COUNT(*) FROM class_members WHERE class_id=c.id) AS member_count
FROM class_members cm
JOIN classrooms c ON c.id=cm.class_id
WHERE cm.uid=@uid
ORDER BY cm.joined_at DESC
'''),
      parameters: {'uid': uid},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>> joinClass({
    required String uid,
    required String classId,
    required String code,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final now = DateTime.now().toUtc();
    final existing = await connection.execute(
      Sql.named('SELECT * FROM classrooms WHERE code=@code LIMIT 1'),
      parameters: {'code': normalizedCode},
    );
    var resolvedClassId = classId;
    if (existing.isEmpty) {
      await connection.execute(
        Sql.named('''
INSERT INTO classrooms (id, code, name, description, teacher_name, created_at, updated_at)
VALUES (@id, @code, @name, @description, @teacherName, @createdAt, @updatedAt)
'''),
        parameters: {
          'id': classId,
          'code': normalizedCode,
          'name': '$normalizedCode 学习班',
          'description': '由班级码加入的 LinguaQuest 学习小组',
          'teacherName': 'LinguaQuest',
          'createdAt': now,
          'updatedAt': now,
        },
      );
    } else {
      resolvedClassId = existing.first.toColumnMap()['id'] as String;
    }
    await connection.execute(
      Sql.named('''
INSERT INTO class_members (class_id, uid, role, joined_at)
VALUES (@classId, @uid, 'student', @joinedAt)
ON CONFLICT (class_id, uid) DO UPDATE SET joined_at=class_members.joined_at
'''),
      parameters: {'classId': resolvedClassId, 'uid': uid, 'joinedAt': now},
    );
    return (await classesForUser(
      uid,
    )).firstWhere((item) => item['id'] == resolvedClassId);
  }

  Future<Map<String, dynamic>?> classByIdForUser(
    String uid, {
    String? classId,
  }) async {
    final classes = await classesForUser(uid);
    if (classes.isEmpty) return null;
    if (classId == null || classId.isEmpty) return classes.first;
    for (final item in classes) {
      if (item['id'] == classId) return item;
    }
    return null;
  }

  Future<Map<String, dynamic>?> classProgress(
    String uid, {
    String? classId,
  }) async {
    final classroom = await classByIdForUser(uid, classId: classId);
    if (classroom == null) return null;
    final resolvedClassId = classroom['id'] as String;
    final members = await connection.execute(
      Sql.named('''
SELECT
  u.id,
  u.name,
  u.avatar_url,
  u.points,
  u.xp,
  u.streak,
  u.total_study_days,
  u.total_study_minutes,
  cm.role,
  cm.joined_at,
  COUNT(s.id) AS sessions,
  COALESCE(SUM(s.total_questions), 0) AS total_questions,
  COALESCE(SUM(s.correct_answers), 0) AS correct_answers,
  COALESCE(SUM(s.earned_points), 0) AS earned_points
FROM class_members cm
JOIN users u ON u.id=cm.uid
LEFT JOIN study_sessions s ON s.uid=u.id
WHERE cm.class_id=@classId
GROUP BY
  u.id,
  u.name,
  u.avatar_url,
  u.points,
  u.xp,
  u.streak,
  u.total_study_days,
  u.total_study_minutes,
  cm.role,
  cm.joined_at
ORDER BY points DESC, xp DESC, streak DESC
'''),
      parameters: {'classId': resolvedClassId},
    );
    final lessons = await connection.execute(
      Sql.named('''
SELECT
  s.lesson_id,
  COUNT(*) AS sessions,
  COALESCE(SUM(s.total_questions), 0) AS total_questions,
  COALESCE(SUM(s.correct_answers), 0) AS correct_answers,
  MAX(s.ended_at) AS last_practiced_at
FROM study_sessions s
JOIN class_members cm ON cm.uid=s.uid
WHERE cm.class_id=@classId
GROUP BY s.lesson_id
ORDER BY last_practiced_at DESC
LIMIT 12
'''),
      parameters: {'classId': resolvedClassId},
    );
    final weakWords = await connection.execute(
      Sql.named('''
SELECT re.word_id, COUNT(*) AS mistake_count
FROM review_events re
JOIN class_members cm ON cm.uid=re.uid
WHERE cm.class_id=@classId AND re.is_correct=FALSE
GROUP BY re.word_id
ORDER BY mistake_count DESC, re.word_id ASC
LIMIT 12
'''),
      parameters: {'classId': resolvedClassId},
    );
    return {
      'classroom': classroom,
      'members': members.map((row) => row.toColumnMap()).toList(),
      'lessons': lessons.map((row) => row.toColumnMap()).toList(),
      'weakWords': weakWords.map((row) => row.toColumnMap()).toList(),
    };
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
  avatar_url=@avatarUrl,
  target_exam=@targetExam,
  level=@level,
  daily_goal=@dailyGoal,
  daily_new_target=@dailyNewTarget,
  daily_review_limit=@dailyReviewLimit,
  current_word_book_id=@currentWordBookId,
  xp=@xp,
  points=@points,
  streak=@streak,
  total_study_days=@totalStudyDays,
  total_study_minutes=@totalStudyMinutes,
  last_study_date=@lastStudyDate,
  updated_at=@updatedAt
WHERE id=@uid
'''),
      parameters: {
        'uid': uid,
        'name': data['name'] ?? existing['name'],
        'avatarUrl': data['avatarUrl'] ?? existing['avatar_url'],
        'targetExam': data['targetExam'] ?? existing['target_exam'],
        'level': data['level'] ?? existing['level'],
        'dailyGoal': data['dailyGoal'] ?? existing['daily_goal'],
        'dailyNewTarget':
            data['dailyNewTarget'] ?? existing['daily_new_target'],
        'dailyReviewLimit':
            data['dailyReviewLimit'] ?? existing['daily_review_limit'],
        'currentWordBookId':
            data['currentWordBookId'] ?? existing['current_word_book_id'],
        'xp': data['xp'] ?? existing['xp'],
        'points': data['points'] ?? existing['points'],
        'streak': data['streak'] ?? existing['streak'],
        'totalStudyDays':
            data['totalStudyDays'] ?? existing['total_study_days'],
        'totalStudyMinutes':
            data['totalStudyMinutes'] ?? existing['total_study_minutes'],
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
  next_review_at, created_at, updated_at
) VALUES (
  @id, @uid, @word, @meaning, @exampleSentence, @note, @tag, @difficulty,
  @status, @easeFactor, @intervalDays, @repetitionCount, @lapseCount,
  @masteryLevel, @correctCount, @wrongCount,
  @meaningRecognitionScore, @meaningRecallScore, @spellingScore,
  @listeningScore, @contextScore, @confidenceScore,
  @nextReviewAt, @createdAt, @updatedAt
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

  Future<List<Map<String, dynamic>>> userWords(String uid) async {
    final rows = await connection.execute(
      Sql.named(
        'SELECT * FROM user_words WHERE uid=@uid ORDER BY updated_at DESC',
      ),
      parameters: {'uid': uid},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>> upsertUserWord(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now().toUtc();
    final createdAt = _date(data['createdAt']) ?? now;
    await connection.execute(
      Sql.named('''
INSERT INTO user_words (
  uid, word_id, word_book_id, status, is_favorite, is_in_new_word_book,
  ease_factor, interval_days, repetition_count, lapse_count, next_review_at,
  last_reviewed_at, correct_count, wrong_count, meaning_recognition_score,
  meaning_recall_score, spelling_score, listening_score, context_score,
  confidence_score, created_at, updated_at
) VALUES (
  @uid, @wordId, @wordBookId, @status, @isFavorite, @isInNewWordBook,
  @easeFactor, @intervalDays, @repetitionCount, @lapseCount, @nextReviewAt,
  @lastReviewedAt, @correctCount, @wrongCount, @meaningRecognitionScore,
  @meaningRecallScore, @spellingScore, @listeningScore, @contextScore,
  @confidenceScore, @createdAt, @updatedAt
)
ON CONFLICT (uid, word_id) DO UPDATE SET
  word_book_id=EXCLUDED.word_book_id,
  status=EXCLUDED.status,
  is_favorite=EXCLUDED.is_favorite,
  is_in_new_word_book=EXCLUDED.is_in_new_word_book,
  ease_factor=EXCLUDED.ease_factor,
  interval_days=EXCLUDED.interval_days,
  repetition_count=EXCLUDED.repetition_count,
  lapse_count=EXCLUDED.lapse_count,
  next_review_at=EXCLUDED.next_review_at,
  last_reviewed_at=EXCLUDED.last_reviewed_at,
  correct_count=EXCLUDED.correct_count,
  wrong_count=EXCLUDED.wrong_count,
  meaning_recognition_score=EXCLUDED.meaning_recognition_score,
  meaning_recall_score=EXCLUDED.meaning_recall_score,
  spelling_score=EXCLUDED.spelling_score,
  listening_score=EXCLUDED.listening_score,
  context_score=EXCLUDED.context_score,
  confidence_score=EXCLUDED.confidence_score,
  updated_at=EXCLUDED.updated_at
'''),
      parameters: {
        'uid': uid,
        'wordId': data['wordId'],
        'wordBookId': data['wordBookId'],
        'status': data['status'] ?? 'New',
        'isFavorite': data['isFavorite'] ?? false,
        'isInNewWordBook': data['isInNewWordBook'] ?? false,
        'easeFactor': data['easeFactor'] ?? 2.5,
        'intervalDays': data['intervalDays'] ?? 0,
        'repetitionCount': data['repetitionCount'] ?? 0,
        'lapseCount': data['lapseCount'] ?? 0,
        'nextReviewAt': _date(data['nextReviewAt']) ?? now,
        'lastReviewedAt': _date(data['lastReviewedAt']),
        'correctCount': data['correctCount'] ?? 0,
        'wrongCount': data['wrongCount'] ?? 0,
        'meaningRecognitionScore': data['meaningRecognitionScore'] ?? 0,
        'meaningRecallScore': data['meaningRecallScore'] ?? 0,
        'spellingScore': data['spellingScore'] ?? 0,
        'listeningScore': data['listeningScore'] ?? 0,
        'contextScore': data['contextScore'] ?? 0,
        'confidenceScore': data['confidenceScore'] ?? 0,
        'createdAt': createdAt,
        'updatedAt': now,
      },
    );
    final rows = await connection.execute(
      Sql.named(
        'SELECT * FROM user_words WHERE uid=@uid AND word_id=@wordId LIMIT 1',
      ),
      parameters: {'uid': uid, 'wordId': data['wordId']},
    );
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>?> studyPlan(String uid) async {
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
    final now = DateTime.now().toUtc();
    final createdAt = _date(data['createdAt']) ?? now;
    final startDate = _dateOnly(data['startDate']) ?? _dateOnly(createdAt)!;
    final targetFinishDate =
        _dateOnly(data['targetFinishDate']) ?? _dateOnly(data['deadline']);
    await connection.execute(
      Sql.named('''
INSERT INTO study_plans (
  uid, word_book_id, daily_new_target, daily_review_limit, start_date,
  target_finish_date, reminder_time, status, created_at, updated_at
) VALUES (
  @uid, @wordBookId, @dailyNewTarget, @dailyReviewLimit, @startDate,
  @targetFinishDate, @reminderTime, @status, @createdAt, @updatedAt
)
ON CONFLICT (uid) DO UPDATE SET
  word_book_id=EXCLUDED.word_book_id,
  daily_new_target=EXCLUDED.daily_new_target,
  daily_review_limit=EXCLUDED.daily_review_limit,
  target_finish_date=EXCLUDED.target_finish_date,
  reminder_time=EXCLUDED.reminder_time,
  status=EXCLUDED.status,
  updated_at=EXCLUDED.updated_at
'''),
      parameters: {
        'uid': uid,
        'wordBookId': data['wordBookId'],
        'dailyNewTarget': data['dailyNewTarget'] ?? data['dailyWords'] ?? 10,
        'dailyReviewLimit': data['dailyReviewLimit'] ?? 20,
        'startDate': startDate,
        'targetFinishDate': targetFinishDate,
        'reminderTime': data['reminderTime'],
        'status': data['status'] ?? 'active',
        'createdAt': createdAt,
        'updatedAt': now,
      },
    );
    return (await studyPlan(uid))!;
  }

  Future<void> deleteStudyPlan(String uid) async {
    await connection.execute(
      Sql.named('DELETE FROM study_plans WHERE uid=@uid'),
      parameters: {'uid': uid},
    );
  }

  Future<void> insertStudySession(String uid, Map<String, dynamic> data) async {
    final sessionId = data['id'] as String;
    final startedAt = _date(data['startedAt']) ?? DateTime.now().toUtc();
    final endedAt = _date(data['endedAt']) ?? DateTime.now().toUtc();
    final totalQuestions = data['totalQuestions'] ?? 0;
    final correctAnswers = data['correctAnswers'] ?? 0;
    final wrongAnswers =
        data['wrongAnswers'] ?? (totalQuestions - correctAnswers).clamp(0, 999);
    final xpEarned = data['xpEarned'] ?? 0;
    final earnedPoints = data['earnedPoints'] ?? xpEarned;
    final durationSeconds =
        data['durationSeconds'] ??
        endedAt.difference(startedAt).inSeconds.clamp(0, 86400).toInt();
    await connection.execute(
      Sql.named('''
INSERT INTO study_sessions (
  id, uid, lesson_id, mode, source, started_at, ended_at, total_questions,
  correct_answers, wrong_answers, xp_earned, earned_points, duration_seconds,
  mistake_word_ids
) VALUES (
  @id, @uid, @lessonId, @mode, @source, @startedAt, @endedAt, @totalQuestions,
  @correctAnswers, @wrongAnswers, @xpEarned, @earnedPoints, @durationSeconds,
  @mistakeWordIds
)
'''),
      parameters: {
        'id': sessionId,
        'uid': uid,
        'lessonId': data['lessonId'],
        'mode': data['mode'] ?? 'lesson',
        'source': data['source'] ?? 'home',
        'startedAt': startedAt,
        'endedAt': endedAt,
        'totalQuestions': totalQuestions,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
        'xpEarned': xpEarned,
        'earnedPoints': earnedPoints,
        'durationSeconds': durationSeconds,
        'mistakeWordIds': ((data['mistakeWordIds'] as List?) ?? const []).join(
          ',',
        ),
      },
    );
    await _applyStudyTotals(
      uid: uid,
      endedAt: endedAt,
      xpEarned: xpEarned,
      earnedPoints: earnedPoints,
      durationSeconds: durationSeconds,
    );
    final records = (data['exerciseRecords'] as List?) ?? const [];
    for (final item in records) {
      if (item is! Map) continue;
      await insertExerciseRecord(
        uid,
        sessionId,
        Map<String, dynamic>.from(item),
      );
    }
  }

  Future<void> _applyStudyTotals({
    required String uid,
    required DateTime endedAt,
    required int xpEarned,
    required int earnedPoints,
    required int durationSeconds,
  }) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT COUNT(DISTINCT DATE(ended_at)) AS study_days
FROM study_sessions
WHERE uid=@uid
'''),
      parameters: {'uid': uid},
    );
    final studyDays = (rows.first.toColumnMap()['study_days'] as num).toInt();
    await connection.execute(
      Sql.named('''
UPDATE users SET
  xp=xp + @xpEarned,
  points=points + @earnedPoints,
  total_study_days=@studyDays,
  total_study_minutes=total_study_minutes + @minutes,
  last_study_date=@lastStudyDate,
  updated_at=@updatedAt
WHERE id=@uid
'''),
      parameters: {
        'uid': uid,
        'xpEarned': xpEarned,
        'earnedPoints': earnedPoints,
        'studyDays': studyDays,
        'minutes': (durationSeconds / 60).ceil(),
        'lastStudyDate': endedAt,
        'updatedAt': DateTime.now().toUtc(),
      },
    );
  }

  Future<void> insertExerciseRecord(
    String uid,
    String sessionId,
    Map<String, dynamic> data,
  ) async {
    await connection.execute(
      Sql.named('''
INSERT INTO exercise_records (
  id, session_id, uid, word_id, exercise_type, prompt, options, correct_answer,
  user_answer, is_correct, response_time_ms, confidence, created_at
) VALUES (
  @id, @sessionId, @uid, @wordId, @exerciseType, @prompt, @options, @correctAnswer,
  @userAnswer, @isCorrect, @responseTimeMs, @confidence, @createdAt
)
'''),
      parameters: {
        'id': data['id'],
        'sessionId': data['sessionId'] ?? sessionId,
        'uid': uid,
        'wordId': data['wordId'],
        'exerciseType': data['exerciseType'],
        'prompt': data['prompt'] ?? '',
        'options': ((data['options'] as List?) ?? const []).join('\n'),
        'correctAnswer': data['correctAnswer'] ?? '',
        'userAnswer': data['userAnswer'] ?? '',
        'isCorrect': data['isCorrect'] ?? false,
        'responseTimeMs': data['responseTimeMs'] ?? 0,
        'confidence': data['confidence'],
        'createdAt': _date(data['createdAt']) ?? DateTime.now().toUtc(),
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

  Future<Map<String, int>> todayActivityCounts(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT
  (SELECT COUNT(*) FROM study_sessions
    WHERE uid=@uid AND ended_at >= @start AND ended_at < @end) AS sessions,
  (SELECT COUNT(*) FROM study_sessions
    WHERE uid=@uid AND mode='training' AND ended_at >= @start AND ended_at < @end) AS training_sessions,
  (SELECT COUNT(*) FROM review_events
    WHERE uid=@uid AND reviewed_at >= @start AND reviewed_at < @end) AS reviews,
  (SELECT COUNT(*) FROM review_events
    WHERE uid=@uid AND is_correct=TRUE AND reviewed_at >= @start AND reviewed_at < @end) AS correct_reviews,
  (SELECT COUNT(*) FROM forum_posts
    WHERE author_id=@uid AND created_at >= @start AND created_at < @end) AS forum_posts,
  (SELECT COUNT(*) FROM forum_comments
    WHERE author_id=@uid AND created_at >= @start AND created_at < @end) AS forum_comments
'''),
      parameters: {
        'uid': uid,
        'start': _todayStart(),
        'end': _todayStart().add(const Duration(days: 1)),
      },
    );
    final row = rows.first.toColumnMap();
    return {
      for (final entry in row.entries) entry.key: (entry.value as num).toInt(),
    };
  }

  Future<Map<String, List<String>>> activitySummary(String uid) async {
    final start = _todayStart();
    final end = start.add(const Duration(days: 1));
    final completedLessons = await connection.execute(
      Sql.named('''
SELECT DISTINCT lesson_id FROM study_sessions
WHERE uid=@uid
ORDER BY lesson_id
'''),
      parameters: {'uid': uid},
    );
    final todayLessons = await connection.execute(
      Sql.named('''
SELECT DISTINCT lesson_id FROM study_sessions
WHERE uid=@uid AND ended_at >= @start AND ended_at < @end
ORDER BY lesson_id
'''),
      parameters: {'uid': uid, 'start': start, 'end': end},
    );
    final todayReviews = await connection.execute(
      Sql.named('''
SELECT DISTINCT word_id FROM review_events
WHERE uid=@uid AND reviewed_at >= @start AND reviewed_at < @end
ORDER BY word_id
'''),
      parameters: {'uid': uid, 'start': start, 'end': end},
    );
    return {
      'completedLessonIds': _stringColumn(completedLessons, 'lesson_id'),
      'todayCompletedLessonIds': _stringColumn(todayLessons, 'lesson_id'),
      'todayReviewWordIds': _stringColumn(todayReviews, 'word_id'),
    };
  }

  Future<List<Map<String, dynamic>>> rewardClaimsForDate(
    String uid,
    DateTime date,
  ) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM reward_claims
WHERE uid=@uid AND claim_date=@claimDate
ORDER BY claimed_at DESC
'''),
      parameters: {'uid': uid, 'claimDate': _dateOnly(date)},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>> insertRewardClaim({
    required String uid,
    required String taskId,
    required int points,
    required DateTime claimDate,
  }) async {
    final now = DateTime.now().toUtc();
    await connection.execute(
      Sql.named('''
INSERT INTO reward_claims (uid, task_id, claim_date, points, claimed_at)
VALUES (@uid, @taskId, @claimDate, @points, @claimedAt)
'''),
      parameters: {
        'uid': uid,
        'taskId': taskId,
        'claimDate': _dateOnly(claimDate),
        'points': points,
        'claimedAt': now,
      },
    );
    await addUserPoints(uid, points);
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM reward_claims
WHERE uid=@uid AND task_id=@taskId AND claim_date=@claimDate
LIMIT 1
'''),
      parameters: {
        'uid': uid,
        'taskId': taskId,
        'claimDate': _dateOnly(claimDate),
      },
    );
    return rows.first.toColumnMap();
  }

  Future<void> addUserPoints(String uid, int points) async {
    await connection.execute(
      Sql.named('''
UPDATE users SET
  points=points + @points,
  xp=xp + @points,
  updated_at=@updatedAt
WHERE id=@uid
'''),
      parameters: {
        'uid': uid,
        'points': points,
        'updatedAt': DateTime.now().toUtc(),
      },
    );
  }

  Future<Map<String, dynamic>> insertLotteryDraw({
    required String id,
    required String uid,
    required String prize,
    required int pointsCost,
  }) async {
    final user = await userById(uid);
    final currentPoints = (user?['points'] as int?) ?? 0;
    if (currentPoints < pointsCost) {
      throw StateError('not enough points');
    }
    final now = DateTime.now().toUtc();
    await connection.execute(
      Sql.named('''
UPDATE users SET points=points - @pointsCost, updated_at=@updatedAt WHERE id=@uid
'''),
      parameters: {'uid': uid, 'pointsCost': pointsCost, 'updatedAt': now},
    );
    await connection.execute(
      Sql.named('''
INSERT INTO lottery_draws (id, uid, prize, points_cost, drawn_at)
VALUES (@id, @uid, @prize, @pointsCost, @drawnAt)
'''),
      parameters: {
        'id': id,
        'uid': uid,
        'prize': prize,
        'pointsCost': pointsCost,
        'drawnAt': now,
      },
    );
    return {
      'id': id,
      'uid': uid,
      'prize': prize,
      'pointsCost': pointsCost,
      'drawnAt': now,
    };
  }

  Future<List<Map<String, dynamic>>> notifications(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM notifications
WHERE uid=@uid
ORDER BY created_at DESC
LIMIT 80
'''),
      parameters: {'uid': uid},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<void> insertNotification({
    required String id,
    required String uid,
    required String type,
    required String title,
    required String body,
    String? targetRoute,
  }) async {
    await connection.execute(
      Sql.named('''
INSERT INTO notifications (id, uid, type, title, body, target_route, created_at)
VALUES (@id, @uid, @type, @title, @body, @targetRoute, @createdAt)
'''),
      parameters: {
        'id': id,
        'uid': uid,
        'type': type,
        'title': title,
        'body': body,
        'targetRoute': targetRoute,
        'createdAt': DateTime.now().toUtc(),
      },
    );
  }

  Future<void> markNotificationRead(String uid, String id) async {
    await connection.execute(
      Sql.named('''
UPDATE notifications SET is_read=TRUE WHERE uid=@uid AND id=@id
'''),
      parameters: {'uid': uid, 'id': id},
    );
  }

  Future<List<Map<String, dynamic>>> forumPosts({String? authorId}) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT p.*, u.name AS author_name, u.avatar_url AS author_avatar_url
FROM forum_posts p
JOIN users u ON u.id=p.author_id
WHERE p.status='published' ${authorId == null ? '' : 'AND p.author_id=@authorId'}
ORDER BY p.created_at DESC
LIMIT 80
'''),
      parameters: {'authorId': authorId},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> forumPostById(String id) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT p.*, u.name AS author_name, u.avatar_url AS author_avatar_url
FROM forum_posts p
JOIN users u ON u.id=p.author_id
WHERE p.id=@id AND p.status='published'
LIMIT 1
'''),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<Map<String, dynamic>> insertForumPost(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now().toUtc();
    await connection.execute(
      Sql.named('''
INSERT INTO forum_posts (
  id, author_id, title, content, image_urls, tags, created_at, updated_at
) VALUES (
  @id, @authorId, @title, @content, @imageUrls, @tags, @createdAt, @updatedAt
)
'''),
      parameters: {
        'id': data['id'],
        'authorId': uid,
        'title': data['title'],
        'content': data['content'],
        'imageUrls': ((data['imageUrls'] as List?) ?? const []).join('\n'),
        'tags': ((data['tags'] as List?) ?? const []).join(','),
        'createdAt': now,
        'updatedAt': now,
      },
    );
    await addUserPoints(uid, 3);
    return (await forumPostById(data['id'] as String))!;
  }

  Future<List<Map<String, dynamic>>> forumComments(String postId) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT c.*, u.name AS author_name, u.avatar_url AS author_avatar_url
FROM forum_comments c
JOIN users u ON u.id=c.author_id
WHERE c.post_id=@postId AND c.status='published'
ORDER BY c.created_at ASC
'''),
      parameters: {'postId': postId},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>> insertForumComment(
    String uid,
    String postId,
    Map<String, dynamic> data,
  ) async {
    final now = DateTime.now().toUtc();
    await connection.execute(
      Sql.named('''
INSERT INTO forum_comments (id, post_id, author_id, content, created_at)
VALUES (@id, @postId, @authorId, @content, @createdAt)
'''),
      parameters: {
        'id': data['id'],
        'postId': postId,
        'authorId': uid,
        'content': data['content'],
        'createdAt': now,
      },
    );
    await connection.execute(
      Sql.named('''
UPDATE forum_posts SET comment_count=comment_count + 1, updated_at=@updatedAt
WHERE id=@postId
'''),
      parameters: {'postId': postId, 'updatedAt': now},
    );
    await addUserPoints(uid, 1);
    final rows = await connection.execute(
      Sql.named('SELECT * FROM forum_comments WHERE id=@id LIMIT 1'),
      parameters: {'id': data['id']},
    );
    return rows.first.toColumnMap();
  }

  Future<void> likeForumPost(String id) async {
    await connection.execute(
      Sql.named('''
UPDATE forum_posts SET like_count=like_count + 1, updated_at=@updatedAt
WHERE id=@id
'''),
      parameters: {'id': id, 'updatedAt': DateTime.now().toUtc()},
    );
  }

  Future<Map<String, dynamic>> insertAiExchange({
    required String uid,
    required String conversationId,
    required String feature,
    required String title,
    required String userMessageId,
    required String assistantMessageId,
    required String prompt,
    required String response,
    required Map<String, dynamic> payload,
  }) async {
    final now = DateTime.now().toUtc();
    await connection.execute(
      Sql.named('''
INSERT INTO ai_conversations (id, uid, feature, title, created_at, updated_at)
VALUES (@id, @uid, @feature, @title, @createdAt, @updatedAt)
ON CONFLICT (id) DO UPDATE SET
  title=EXCLUDED.title,
  updated_at=EXCLUDED.updated_at
'''),
      parameters: {
        'id': conversationId,
        'uid': uid,
        'feature': feature,
        'title': title,
        'createdAt': now,
        'updatedAt': now,
      },
    );
    await connection.execute(
      Sql.named('''
INSERT INTO ai_messages (id, conversation_id, uid, role, content, payload, created_at)
VALUES (@id, @conversationId, @uid, @role, @content, @payload, @createdAt)
'''),
      parameters: {
        'id': userMessageId,
        'conversationId': conversationId,
        'uid': uid,
        'role': 'user',
        'content': prompt,
        'payload': '{}',
        'createdAt': now,
      },
    );
    await connection.execute(
      Sql.named('''
INSERT INTO ai_messages (id, conversation_id, uid, role, content, payload, created_at)
VALUES (@id, @conversationId, @uid, @role, @content, @payload, @createdAt)
'''),
      parameters: {
        'id': assistantMessageId,
        'conversationId': conversationId,
        'uid': uid,
        'role': 'assistant',
        'content': response,
        'payload': jsonEncode(payload),
        'createdAt': now,
      },
    );
    return {
      'conversationId': conversationId,
      'feature': feature,
      'title': title,
      'response': response,
      'payload': payload,
      'createdAt': now,
    };
  }

  Future<List<Map<String, dynamic>>> aiConversations(String uid) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM ai_conversations WHERE uid=@uid ORDER BY updated_at DESC LIMIT 60
'''),
      parameters: {'uid': uid},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>?> aiConversationById(
    String uid,
    String id,
  ) async {
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM ai_conversations WHERE uid=@uid AND id=@id LIMIT 1
'''),
      parameters: {'uid': uid, 'id': id},
    );
    if (rows.isEmpty) return null;
    return rows.first.toColumnMap();
  }

  Future<List<Map<String, dynamic>>> aiMessages(
    String uid,
    String conversationId,
  ) async {
    final conversation = await aiConversationById(uid, conversationId);
    if (conversation == null) return const [];
    final rows = await connection.execute(
      Sql.named('''
SELECT * FROM ai_messages
WHERE uid=@uid AND conversation_id=@conversationId
ORDER BY created_at ASC
'''),
      parameters: {'uid': uid, 'conversationId': conversationId},
    );
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<bool> deleteAiConversation(String uid, String id) async {
    final existing = await aiConversationById(uid, id);
    if (existing == null) return false;
    await connection.execute(
      Sql.named('''
DELETE FROM ai_conversations WHERE uid=@uid AND id=@id
'''),
      parameters: {'uid': uid, 'id': id},
    );
    return true;
  }

  Future<List<Map<String, dynamic>>> leaderboard() async {
    final rows = await connection.execute('''
SELECT id, name, avatar_url, points, xp, streak, total_study_days
FROM users
ORDER BY points DESC, xp DESC, streak DESC
LIMIT 50
''');
    return rows.map((row) => row.toColumnMap()).toList();
  }

  Future<Map<String, dynamic>> analyticsSummary(String uid) async {
    final sessions = await connection.execute(
      Sql.named('''
SELECT
  COUNT(*) AS sessions,
  COALESCE(SUM(total_questions), 0) AS total_questions,
  COALESCE(SUM(correct_answers), 0) AS correct_answers,
  COALESCE(SUM(duration_seconds), 0) AS duration_seconds,
  COALESCE(SUM(earned_points), 0) AS earned_points
FROM study_sessions
WHERE uid=@uid
'''),
      parameters: {'uid': uid},
    );
    final weak = await connection.execute(
      Sql.named('''
SELECT COUNT(*) AS weak_words
FROM user_words
WHERE uid=@uid AND (wrong_count > correct_count OR context_score < 40 OR spelling_score < 40)
'''),
      parameters: {'uid': uid},
    );
    final posts = await connection.execute(
      Sql.named('''
SELECT COUNT(*) AS forum_posts FROM forum_posts WHERE author_id=@uid
'''),
      parameters: {'uid': uid},
    );
    return {
      ...sessions.first.toColumnMap(),
      ...weak.first.toColumnMap(),
      ...posts.first.toColumnMap(),
    };
  }
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value.toString())?.toUtc();
}

DateTime? _dateOnly(Object? value) {
  final date = _date(value);
  if (date == null) return null;
  return DateTime.utc(date.year, date.month, date.day);
}

DateTime _todayStart() {
  final now = DateTime.now().toUtc();
  return DateTime.utc(now.year, now.month, now.day);
}

List<String> _stringColumn(Iterable<dynamic> rows, String column) {
  return [
    for (final row in rows)
      if (row.toColumnMap()[column] != null)
        row.toColumnMap()[column].toString(),
  ];
}
