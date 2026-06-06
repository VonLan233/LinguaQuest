import 'dart:convert';

import 'package:googleapis/firestore/v1.dart' as fs;
import 'package:googleapis_auth/auth_io.dart';

import 'config.dart';

abstract class AppDatabase {
  static Future<AppDatabase> connect(AppConfig config) =>
      FirestoreAppDatabase.connect(config);

  Future<void> migrate();
  Future<Map<String, dynamic>?> userByEmail(String email);
  Future<Map<String, dynamic>?> userById(String uid);
  Future<Map<String, dynamic>> updateUser(
    String uid,
    Map<String, dynamic> data,
  );
  Future<void> insertUser({
    required String id,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    required String name,
  });
  Future<List<Map<String, dynamic>>> customWords(
    String uid, {
    bool dueOnly = false,
  });
  Future<Map<String, dynamic>?> customWordById(String uid, String id);
  Future<Map<String, dynamic>> upsertCustomWord(
    String uid,
    Map<String, dynamic> data, {
    String? id,
  });
  Future<void> deleteCustomWord(String uid, String id);
  Future<List<Map<String, dynamic>>> userWords(
    String uid, {
    bool dueOnly = false,
  });
  Future<Map<String, dynamic>?> userWordById(String uid, String id);
  Future<Map<String, dynamic>> upsertUserWord(
    String uid,
    Map<String, dynamic> data,
  );
  Future<List<Map<String, dynamic>>> upsertUserWords(
    String uid,
    List<Map<String, dynamic>> words,
  );
  Future<void> insertStudySession(String uid, Map<String, dynamic> data);
  Future<Map<String, dynamic>?> studyPlanByUid(String uid);
  Future<Map<String, dynamic>> upsertStudyPlan(
    String uid,
    Map<String, dynamic> data,
  );
  Future<void> resetCustomWordProgress(String uid, {DateTime? now});
  Future<void> insertReviewEvent(String uid, Map<String, dynamic> data);
  Future<List<String>> completedLessonIds(String uid);
  Future<List<String>> lessonIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  );
  Future<List<String>> reviewWordIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  );
  Future<List<String>> rewardIdsForDate(String uid, String localDate);
  Future<bool> claimReward({
    required String uid,
    required String rewardId,
    required String localDate,
    required int points,
  });
  Future<List<Map<String, dynamic>>> notifications(
    String uid, {
    bool unreadOnly = false,
    String? type,
  });
  Future<Map<String, dynamic>?> notificationById(String uid, String id);
  Future<void> upsertNotification(String uid, Map<String, dynamic> data);
  Future<void> upsertNotifications(
    String uid,
    List<Map<String, dynamic>> notifications,
  );
  Future<Map<String, dynamic>?> markNotificationRead(String uid, String id);
  Future<int> markAllNotificationsRead(String uid);
  Future<bool> hasStudySessionInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  );
  Future<int> dueReviewCount(String uid);
}

class FirestoreAppDatabase implements AppDatabase {
  FirestoreAppDatabase._(this._api, this._projectId);

  final fs.FirestoreApi _api;
  final String _projectId;

  String get _database => 'projects/$_projectId/databases/(default)';
  String get _documents => '$_database/documents';

  static Future<FirestoreAppDatabase> connect(AppConfig config) async {
    if (config.firebaseProjectId.isEmpty) {
      throw StateError('FIREBASE_PROJECT_ID is required');
    }
    if (config.firebaseServiceAccountJsonBase64.isEmpty) {
      throw StateError('FIREBASE_SERVICE_ACCOUNT_JSON_BASE64 is required');
    }
    final credentialsJson = utf8.decode(
      base64.decode(config.firebaseServiceAccountJsonBase64),
    );
    final credentials = ServiceAccountCredentials.fromJson(
      jsonDecode(credentialsJson),
    );
    final client = await clientViaServiceAccount(credentials, [
      'https://www.googleapis.com/auth/datastore',
    ]);
    return FirestoreAppDatabase._(
      fs.FirestoreApi(client),
      config.firebaseProjectId,
    );
  }

  @override
  Future<void> migrate() async {}

  @override
  Future<Map<String, dynamic>?> userByEmail(String email) async {
    final index = await _get(['email_index', _encodedId(email)]);
    final uid = index?['uid']?.toString();
    if (uid == null || uid.isEmpty) return null;
    return userById(uid);
  }

  @override
  Future<Map<String, dynamic>?> userById(String uid) => _get(['users', uid]);

  @override
  Future<Map<String, dynamic>> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final existing = await userById(uid);
    if (existing == null) throw StateError('user not found');
    final now = DateTime.now().toUtc();
    final row = {
      ...existing,
      'name': data['name'] ?? existing['name'],
      'target_exam': data['targetExam'] ?? data['target_exam'],
      'level': data['level'] ?? existing['level'],
      'daily_goal': data['dailyGoal'] ?? existing['daily_goal'],
      'xp': data['xp'] ?? existing['xp'],
      'streak': data['streak'] ?? existing['streak'],
      'last_study_date':
          _date(data['lastStudyDate']) ?? existing['last_study_date'],
      'updated_at': now,
    };
    await _set(['users', uid], row);
    return row;
  }

  @override
  Future<void> insertUser({
    required String id,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    required String name,
  }) async {
    final now = DateTime.now().toUtc();
    final normalizedEmail = email.trim().toLowerCase();
    final user = {
      'id': id,
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'name': name,
      'target_exam': 'Daily English',
      'level': 'Elementary',
      'daily_goal': 10,
      'xp': 0,
      'streak': 0,
      'last_study_date': null,
      'created_at': now,
      'updated_at': now,
    };
    final emailIndex = {'uid': id, 'email': normalizedEmail, 'created_at': now};
    try {
      await _api.projects.databases.documents.commit(
        fs.CommitRequest(
          writes: [
            fs.Write(
              update: _document(['users', id], user),
              currentDocument: fs.Precondition(exists: false),
            ),
            fs.Write(
              update: _document([
                'email_index',
                _encodedId(normalizedEmail),
              ], emailIndex),
              currentDocument: fs.Precondition(exists: false),
            ),
          ],
        ),
        _database,
      );
    } catch (error) {
      if (_isWritePreconditionError(error)) {
        throw StateError('email already registered');
      }
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> customWords(
    String uid, {
    bool dueOnly = false,
  }) async {
    final rows = await _list(['users', uid], 'custom_words');
    final now = DateTime.now().toUtc();
    final filtered = dueOnly
        ? rows.where((row) {
            final dueAt = _date(row['next_review_at']);
            return dueAt != null && !dueAt.isAfter(now);
          }).toList()
        : rows;
    filtered.sort((a, b) {
      if (dueOnly) {
        final dueA =
            _date(a['next_review_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dueB =
            _date(b['next_review_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dueCompare = dueA.compareTo(dueB);
        if (dueCompare != 0) return dueCompare;
      }
      final updatedA =
          _date(a['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final updatedB =
          _date(b['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return updatedB.compareTo(updatedA);
    });
    return filtered;
  }

  @override
  Future<Map<String, dynamic>?> customWordById(String uid, String id) {
    return _get(['users', uid, 'custom_words', id]);
  }

  @override
  Future<Map<String, dynamic>> upsertCustomWord(
    String uid,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final now = DateTime.now().toUtc();
    final wordId = id ?? data['id'] as String;
    final existing = await customWordById(uid, wordId);
    final createdAt =
        _date(existing?['created_at']) ?? _date(data['createdAt']) ?? now;
    final row = {
      'id': wordId,
      'uid': uid,
      'word': data['word'],
      'meaning': data['meaning'],
      'example_sentence': _field(
        data,
        'exampleSentence',
        'example_sentence',
        '',
      ),
      'note': data['note'] ?? '',
      'tag': data['tag'] ?? 'custom',
      'difficulty': data['difficulty'] ?? 'Medium',
      'status': data['status'] ?? 'Learning',
      'ease_factor': _field(data, 'easeFactor', 'ease_factor', 2.5),
      'interval_days': _field(data, 'intervalDays', 'interval_days', 0),
      'repetition_count': _field(
        data,
        'repetitionCount',
        'repetition_count',
        0,
      ),
      'lapse_count': _field(data, 'lapseCount', 'lapse_count', 0),
      'mastery_level': _field(data, 'masteryLevel', 'mastery_level', 0),
      'correct_count': _field(data, 'correctCount', 'correct_count', 0),
      'wrong_count': _field(data, 'wrongCount', 'wrong_count', 0),
      'meaning_recognition_score': _field(
        data,
        'meaningRecognitionScore',
        'meaning_recognition_score',
        20,
      ),
      'meaning_recall_score': _field(
        data,
        'meaningRecallScore',
        'meaning_recall_score',
        10,
      ),
      'spelling_score': _field(data, 'spellingScore', 'spelling_score', 10),
      'listening_score': _field(data, 'listeningScore', 'listening_score', 10),
      'context_score': _field(data, 'contextScore', 'context_score', 10),
      'confidence_score': _field(
        data,
        'confidenceScore',
        'confidence_score',
        10,
      ),
      'next_review_at':
          _date(data['nextReviewAt'] ?? data['next_review_at']) ?? now,
      'last_reviewed_at': _date(
        data['lastReviewedAt'] ?? data['last_reviewed_at'],
      ),
      'created_at': createdAt,
      'updated_at': now,
    };
    await _set(['users', uid, 'custom_words', wordId], row);
    return row;
  }

  @override
  Future<void> deleteCustomWord(String uid, String id) {
    return _delete(['users', uid, 'custom_words', id]);
  }

  @override
  Future<List<Map<String, dynamic>>> userWords(
    String uid, {
    bool dueOnly = false,
  }) async {
    final rows = await _list(['users', uid], 'user_words');
    final now = DateTime.now().toUtc();
    final filtered = dueOnly
        ? rows.where((row) {
            final dueAt = _date(row['next_review_at']);
            final status = row['status']?.toString();
            return dueAt != null &&
                !dueAt.isAfter(now) &&
                row['is_ignored'] != true &&
                status != 'New' &&
                status != 'Previewed' &&
                status != 'Ignored';
          }).toList()
        : rows;
    filtered.sort((a, b) {
      if (dueOnly) {
        final dueA =
            _date(a['next_review_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dueB =
            _date(b['next_review_at']) ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dueCompare = dueA.compareTo(dueB);
        if (dueCompare != 0) return dueCompare;
        return _int(b['wrong_count']).compareTo(_int(a['wrong_count']));
      }
      final updatedA =
          _date(a['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final updatedB =
          _date(b['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return updatedB.compareTo(updatedA);
    });
    return filtered;
  }

  @override
  Future<Map<String, dynamic>?> userWordById(String uid, String id) {
    return _get(['users', uid, 'user_words', id]);
  }

  @override
  Future<Map<String, dynamic>> upsertUserWord(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final rows = await upsertUserWords(uid, [data]);
    return rows.first;
  }

  @override
  Future<List<Map<String, dynamic>>> upsertUserWords(
    String uid,
    List<Map<String, dynamic>> words,
  ) async {
    final saved = <Map<String, dynamic>>[];
    for (final data in words) {
      final now = DateTime.now().toUtc();
      final id = data['id'] as String;
      final row = {
        'id': id,
        'uid': uid,
        'word_id': data['wordId'] ?? data['word_id'],
        'word_book_id': _field(data, 'wordBookId', 'word_book_id', ''),
        'word': data['word'] ?? data['wordId'],
        'meaning': data['meaning'] ?? '',
        'example_sentence': _field(
          data,
          'exampleSentence',
          'example_sentence',
          '',
        ),
        'difficulty': data['difficulty'] ?? 'Medium',
        'status': data['status'] ?? 'New',
        'is_favorite': _field(data, 'isFavorite', 'is_favorite', false),
        'is_in_new_word_book': _field(
          data,
          'isInNewWordBook',
          'is_in_new_word_book',
          false,
        ),
        'is_ignored': _field(
          data,
          'isIgnored',
          'is_ignored',
          data['status'] == 'Ignored',
        ),
        'ease_factor': _field(data, 'easeFactor', 'ease_factor', 2.5),
        'interval_days': _field(data, 'intervalDays', 'interval_days', 0),
        'repetition_count': _field(
          data,
          'repetitionCount',
          'repetition_count',
          0,
        ),
        'lapse_count': _field(data, 'lapseCount', 'lapse_count', 0),
        'mastery_level': _field(data, 'masteryLevel', 'mastery_level', 0),
        'correct_count': _field(data, 'correctCount', 'correct_count', 0),
        'wrong_count': _field(data, 'wrongCount', 'wrong_count', 0),
        'meaning_recognition_score': _field(
          data,
          'meaningRecognitionScore',
          'meaning_recognition_score',
          20,
        ),
        'meaning_recall_score': _field(
          data,
          'meaningRecallScore',
          'meaning_recall_score',
          10,
        ),
        'spelling_score': _field(data, 'spellingScore', 'spelling_score', 10),
        'listening_score': _field(
          data,
          'listeningScore',
          'listening_score',
          10,
        ),
        'context_score': _field(data, 'contextScore', 'context_score', 10),
        'confidence_score': _field(
          data,
          'confidenceScore',
          'confidence_score',
          10,
        ),
        'next_review_at':
            _date(data['nextReviewAt'] ?? data['next_review_at']) ?? now,
        'last_reviewed_at': _date(
          data['lastReviewedAt'] ?? data['last_reviewed_at'],
        ),
        'created_at': _date(data['createdAt']) ?? now,
        'updated_at': _date(data['updatedAt']) ?? now,
      };
      await _set(['users', uid, 'user_words', id], row);
      saved.add(row);
    }
    return saved;
  }

  @override
  Future<void> insertStudySession(String uid, Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await _set(
      ['users', uid, 'study_sessions', id],
      {
        'id': id,
        'uid': uid,
        'lesson_id': data['lessonId'],
        'started_at': _date(data['startedAt']) ?? DateTime.now().toUtc(),
        'ended_at': _date(data['endedAt']) ?? DateTime.now().toUtc(),
        'total_questions': data['totalQuestions'] ?? 0,
        'correct_answers': data['correctAnswers'] ?? 0,
        'xp_earned': data['xpEarned'] ?? 0,
        'mistake_word_ids': ((data['mistakeWordIds'] as List?) ?? const [])
            .join(','),
        'answer_events': jsonEncode(
          (data['answerEvents'] as List?) ?? const [],
        ),
      },
    );
  }

  @override
  Future<Map<String, dynamic>?> studyPlanByUid(String uid) {
    return _get(['users', uid, 'study_plans', 'current']);
  }

  @override
  Future<Map<String, dynamic>> upsertStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final existing = await studyPlanByUid(uid);
    final now = DateTime.now().toUtc();
    final updatedAt = _date(data['now']) ?? now;
    final row = {
      'id': existing?['id']?.toString() ?? data['id']?.toString(),
      'uid': uid,
      'word_book_id': data['wordBookId'],
      'daily_new_target': data['dailyNewTarget'],
      'daily_review_limit': data['dailyReviewLimit'],
      'start_date': data['startDate'],
      'target_finish_date': data['targetFinishDate'],
      'reminder_time': data['reminderTime'],
      'status': data['status'],
      'created_at': existing?['created_at'] ?? _date(data['createdAt']) ?? now,
      'updated_at': updatedAt,
    };
    await _set(['users', uid, 'study_plans', 'current'], row);
    return row;
  }

  @override
  Future<void> resetCustomWordProgress(String uid, {DateTime? now}) async {
    final resetAt = now ?? DateTime.now().toUtc();
    for (final word in await customWords(uid)) {
      await _set(
        ['users', uid, 'custom_words', word['id'] as String],
        {
          ...word,
          'mastery_level': 0,
          'correct_count': 0,
          'wrong_count': 0,
          'next_review_at': resetAt,
          'updated_at': resetAt,
        },
      );
    }
  }

  @override
  Future<void> insertReviewEvent(String uid, Map<String, dynamic> data) async {
    final id = data['id'] as String;
    await _set(
      ['users', uid, 'review_events', id],
      {
        'id': id,
        'uid': uid,
        'word_id': data['wordId'] ?? data['word_id'],
        'is_correct': data['isCorrect'],
        'answer_time_ms': data['answerTimeMs'] ?? 0,
        'confidence': data['confidence'] ?? 3,
        'wrong_option': data['wrongOption'] ?? data['wrong_option'],
        'reviewed_at': _date(data['reviewedAt']) ?? DateTime.now().toUtc(),
        'mastery_before': data['masteryBefore'] ?? 0,
        'mastery_after': data['masteryAfter'] ?? 0,
        'next_review_at':
            _date(data['nextReviewAt'] ?? data['next_review_at']) ??
            DateTime.now().toUtc(),
      },
    );
  }

  @override
  Future<List<String>> completedLessonIds(String uid) async {
    final sessions = await _list(['users', uid], 'study_sessions');
    return _distinctSorted(sessions.map((row) => row['lesson_id']));
  }

  @override
  Future<List<String>> lessonIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final sessions = await _list(['users', uid], 'study_sessions');
    return _distinctSorted(
      sessions
          .where((row) {
            final endedAt = _date(row['ended_at']);
            return endedAt != null &&
                !endedAt.isBefore(startUtc) &&
                endedAt.isBefore(endUtc);
          })
          .map((row) => row['lesson_id']),
    );
  }

  @override
  Future<List<String>> reviewWordIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final events = await _list(['users', uid], 'review_events');
    return _distinctSorted(
      events
          .where((row) {
            final reviewedAt = _date(row['reviewed_at']);
            return reviewedAt != null &&
                !reviewedAt.isBefore(startUtc) &&
                reviewedAt.isBefore(endUtc);
          })
          .map((row) => row['word_id']),
    );
  }

  @override
  Future<List<String>> rewardIdsForDate(String uid, String localDate) async {
    final rewards = await _list(['users', uid], 'reward_claims');
    rewards.sort((a, b) {
      final aDate =
          _date(a['claimed_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate =
          _date(b['claimed_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aDate.compareTo(bDate);
    });
    return [
      for (final row in rewards)
        if (row['local_date'] == localDate) row['reward_id'].toString(),
    ];
  }

  @override
  Future<bool> claimReward({
    required String uid,
    required String rewardId,
    required String localDate,
    required int points,
  }) async {
    final user = await userById(uid);
    if (user == null) throw StateError('user not found');
    final rewardDocId = '${_encodedId(localDate)}_${_encodedId(rewardId)}';
    if (await _get(['users', uid, 'reward_claims', rewardDocId]) != null) {
      return false;
    }
    final now = DateTime.now().toUtc();
    try {
      await _api.projects.databases.documents.commit(
        fs.CommitRequest(
          writes: [
            fs.Write(
              update: _document(
                ['users', uid, 'reward_claims', rewardDocId],
                {
                  'uid': uid,
                  'reward_id': rewardId,
                  'local_date': localDate,
                  'points': points,
                  'claimed_at': now,
                },
              ),
              currentDocument: fs.Precondition(exists: false),
            ),
            fs.Write(
              update: _document(
                ['users', uid],
                {...user, 'xp': _int(user['xp']) + points, 'updated_at': now},
              ),
            ),
          ],
        ),
        _database,
      );
      return true;
    } catch (error) {
      if (_isWritePreconditionError(error)) return false;
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> notifications(
    String uid, {
    bool unreadOnly = false,
    String? type,
  }) async {
    final rows = await _list(['users', uid], 'notifications');
    final filtered = rows.where((row) {
      if (unreadOnly && row['is_read'] == true) return false;
      if (type != null && row['type'] != type) return false;
      return true;
    }).toList();
    filtered.sort((a, b) {
      final createdA =
          _date(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final createdB =
          _date(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return createdB.compareTo(createdA);
    });
    return filtered;
  }

  @override
  Future<Map<String, dynamic>?> notificationById(String uid, String id) {
    return _get(['users', uid, 'notifications', id]);
  }

  @override
  Future<void> upsertNotification(String uid, Map<String, dynamic> data) {
    return upsertNotifications(uid, [data]);
  }

  @override
  Future<void> upsertNotifications(
    String uid,
    List<Map<String, dynamic>> notifications,
  ) async {
    for (final data in notifications) {
      final sourceKey = data['sourceKey']?.toString();
      final existing = sourceKey == null
          ? null
          : (await this.notifications(uid)).where((row) {
              return row['source_key'] == sourceKey;
            }).firstOrNull;
      final id = existing?['id']?.toString() ?? data['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final row = {
        ...?existing,
        'id': id,
        'uid': uid,
        'type': data['type'],
        'title': data['title'],
        'body': data['body'],
        'target_route': data['targetRoute'] ?? '/home',
        'is_read': existing?['is_read'] ?? data['isRead'] ?? false,
        'source_key': sourceKey,
        'read_at': existing?['read_at'] ?? _date(data['readAt']),
        'created_at':
            existing?['created_at'] ??
            _date(data['createdAt']) ??
            DateTime.now().toUtc(),
      };
      await _set(['users', uid, 'notifications', id], row);
    }
  }

  @override
  Future<Map<String, dynamic>?> markNotificationRead(
    String uid,
    String id,
  ) async {
    final existing = await notificationById(uid, id);
    if (existing == null) return null;
    final row = {
      ...existing,
      'is_read': true,
      'read_at': existing['read_at'] ?? DateTime.now().toUtc(),
    };
    await _set(['users', uid, 'notifications', id], row);
    return row;
  }

  @override
  Future<int> markAllNotificationsRead(String uid) async {
    var updated = 0;
    for (final notification in await notifications(uid, unreadOnly: true)) {
      await markNotificationRead(uid, notification['id'] as String);
      updated++;
    }
    return updated;
  }

  @override
  Future<bool> hasStudySessionInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    final ids = await lessonIdsInRange(uid, startUtc, endUtc);
    return ids.isNotEmpty;
  }

  @override
  Future<int> dueReviewCount(String uid) async {
    return (await customWords(uid, dueOnly: true)).length +
        (await userWords(uid, dueOnly: true)).length;
  }

  Future<Map<String, dynamic>?> _get(List<String> path) async {
    try {
      final document = await _api.projects.databases.documents.get(
        _documentName(path),
      );
      return _rowFromDocument(document);
    } catch (error) {
      if (error.toString().contains('404')) return null;
      rethrow;
    }
  }

  Future<void> _set(List<String> path, Map<String, dynamic> data) async {
    await _api.projects.databases.documents.commit(
      fs.CommitRequest(writes: [fs.Write(update: _document(path, data))]),
      _database,
    );
  }

  Future<void> _delete(List<String> path) async {
    try {
      await _api.projects.databases.documents.delete(_documentName(path));
    } catch (error) {
      if (!error.toString().contains('404')) rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> _list(
    List<String> parentPath,
    String collectionId,
  ) async {
    final parent = parentPath.isEmpty ? _documents : _documentName(parentPath);
    final rows = <Map<String, dynamic>>[];
    String? pageToken;
    do {
      final response = await _api.projects.databases.documents.list(
        parent,
        collectionId,
        pageSize: 1000,
        pageToken: pageToken,
      );
      rows.addAll((response.documents ?? const []).map(_rowFromDocument));
      pageToken = response.nextPageToken;
    } while (pageToken != null && pageToken.isNotEmpty);
    return rows;
  }

  fs.Document _document(List<String> path, Map<String, dynamic> data) {
    return fs.Document(name: _documentName(path), fields: _fields(data));
  }

  String _documentName(List<String> path) => '$_documents/${path.join('/')}';
}

class InMemoryAppDatabase implements AppDatabase {
  final _users = <String, Map<String, dynamic>>{};
  final _emailIndex = <String, String>{};
  final _customWords = <String, Map<String, Map<String, dynamic>>>{};
  final _userWords = <String, Map<String, Map<String, dynamic>>>{};
  final _studySessions = <String, Map<String, Map<String, dynamic>>>{};
  final _reviewEvents = <String, Map<String, Map<String, dynamic>>>{};
  final _studyPlans = <String, Map<String, dynamic>>{};
  final _rewardClaims = <String, Map<String, Map<String, dynamic>>>{};
  final _notifications = <String, Map<String, Map<String, dynamic>>>{};

  @override
  Future<void> migrate() async {}

  @override
  Future<Map<String, dynamic>?> userByEmail(String email) async {
    final uid = _emailIndex[email.trim().toLowerCase()];
    return uid == null ? null : userById(uid);
  }

  @override
  Future<Map<String, dynamic>?> userById(String uid) async =>
      _copy(_users[uid]);

  @override
  Future<Map<String, dynamic>> updateUser(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final existing = _users[uid];
    if (existing == null) throw StateError('user not found');
    final row = {
      ...existing,
      'name': data['name'] ?? existing['name'],
      'target_exam': data['targetExam'] ?? existing['target_exam'],
      'level': data['level'] ?? existing['level'],
      'daily_goal': data['dailyGoal'] ?? existing['daily_goal'],
      'xp': data['xp'] ?? existing['xp'],
      'streak': data['streak'] ?? existing['streak'],
      'last_study_date':
          _date(data['lastStudyDate']) ?? existing['last_study_date'],
      'updated_at': DateTime.now().toUtc(),
    };
    _users[uid] = row;
    return _copy(row)!;
  }

  @override
  Future<void> insertUser({
    required String id,
    required String email,
    required String passwordHash,
    required String passwordSalt,
    required String name,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (_emailIndex.containsKey(normalizedEmail)) {
      throw StateError('email already registered');
    }
    final now = DateTime.now().toUtc();
    _emailIndex[normalizedEmail] = id;
    _users[id] = {
      'id': id,
      'email': normalizedEmail,
      'password_hash': passwordHash,
      'password_salt': passwordSalt,
      'name': name,
      'target_exam': 'Daily English',
      'level': 'Elementary',
      'daily_goal': 10,
      'xp': 0,
      'streak': 0,
      'last_study_date': null,
      'created_at': now,
      'updated_at': now,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> customWords(
    String uid, {
    bool dueOnly = false,
  }) async {
    final rows = _collection(_customWords, uid);
    return _filterReviewRows(rows, dueOnly: dueOnly, includeNew: true);
  }

  @override
  Future<Map<String, dynamic>?> customWordById(String uid, String id) async {
    return _copy(_customWords[uid]?[id]);
  }

  @override
  Future<Map<String, dynamic>> upsertCustomWord(
    String uid,
    Map<String, dynamic> data, {
    String? id,
  }) async {
    final now = DateTime.now().toUtc();
    final wordId = id ?? data['id'] as String;
    final existing = _customWords[uid]?[wordId];
    final row = {
      'id': wordId,
      'uid': uid,
      'word': data['word'],
      'meaning': data['meaning'],
      'example_sentence': _field(
        data,
        'exampleSentence',
        'example_sentence',
        '',
      ),
      'note': data['note'] ?? '',
      'tag': data['tag'] ?? 'custom',
      'difficulty': data['difficulty'] ?? 'Medium',
      'status': data['status'] ?? 'Learning',
      'ease_factor': _field(data, 'easeFactor', 'ease_factor', 2.5),
      'interval_days': _field(data, 'intervalDays', 'interval_days', 0),
      'repetition_count': _field(
        data,
        'repetitionCount',
        'repetition_count',
        0,
      ),
      'lapse_count': _field(data, 'lapseCount', 'lapse_count', 0),
      'mastery_level': _field(data, 'masteryLevel', 'mastery_level', 0),
      'correct_count': _field(data, 'correctCount', 'correct_count', 0),
      'wrong_count': _field(data, 'wrongCount', 'wrong_count', 0),
      'meaning_recognition_score': _field(
        data,
        'meaningRecognitionScore',
        'meaning_recognition_score',
        20,
      ),
      'meaning_recall_score': _field(
        data,
        'meaningRecallScore',
        'meaning_recall_score',
        10,
      ),
      'spelling_score': _field(data, 'spellingScore', 'spelling_score', 10),
      'listening_score': _field(data, 'listeningScore', 'listening_score', 10),
      'context_score': _field(data, 'contextScore', 'context_score', 10),
      'confidence_score': _field(
        data,
        'confidenceScore',
        'confidence_score',
        10,
      ),
      'next_review_at':
          _date(data['nextReviewAt'] ?? data['next_review_at']) ?? now,
      'last_reviewed_at': _date(
        data['lastReviewedAt'] ?? data['last_reviewed_at'],
      ),
      'created_at': existing?['created_at'] ?? _date(data['createdAt']) ?? now,
      'updated_at': now,
    };
    (_customWords[uid] ??= {})[wordId] = row;
    return _copy(row)!;
  }

  @override
  Future<void> deleteCustomWord(String uid, String id) async {
    _customWords[uid]?.remove(id);
  }

  @override
  Future<List<Map<String, dynamic>>> userWords(
    String uid, {
    bool dueOnly = false,
  }) async {
    final rows = _collection(_userWords, uid);
    return _filterReviewRows(rows, dueOnly: dueOnly, includeNew: false);
  }

  @override
  Future<Map<String, dynamic>?> userWordById(String uid, String id) async {
    return _copy(_userWords[uid]?[id]);
  }

  @override
  Future<Map<String, dynamic>> upsertUserWord(
    String uid,
    Map<String, dynamic> data,
  ) async {
    return (await upsertUserWords(uid, [data])).first;
  }

  @override
  Future<List<Map<String, dynamic>>> upsertUserWords(
    String uid,
    List<Map<String, dynamic>> words,
  ) async {
    final now = DateTime.now().toUtc();
    final saved = <Map<String, dynamic>>[];
    for (final data in words) {
      final id = data['id'] as String;
      final row = {
        'id': id,
        'uid': uid,
        'word_id': data['wordId'] ?? data['word_id'],
        'word_book_id': _field(data, 'wordBookId', 'word_book_id', ''),
        'word': data['word'] ?? data['wordId'] ?? data['word_id'],
        'meaning': data['meaning'] ?? '',
        'example_sentence': _field(
          data,
          'exampleSentence',
          'example_sentence',
          '',
        ),
        'difficulty': data['difficulty'] ?? 'Medium',
        'status': data['status'] ?? 'New',
        'is_favorite': _field(data, 'isFavorite', 'is_favorite', false),
        'is_in_new_word_book': _field(
          data,
          'isInNewWordBook',
          'is_in_new_word_book',
          false,
        ),
        'is_ignored': _field(
          data,
          'isIgnored',
          'is_ignored',
          data['status'] == 'Ignored',
        ),
        'ease_factor': _field(data, 'easeFactor', 'ease_factor', 2.5),
        'interval_days': _field(data, 'intervalDays', 'interval_days', 0),
        'repetition_count': _field(
          data,
          'repetitionCount',
          'repetition_count',
          0,
        ),
        'lapse_count': _field(data, 'lapseCount', 'lapse_count', 0),
        'mastery_level': _field(data, 'masteryLevel', 'mastery_level', 0),
        'correct_count': _field(data, 'correctCount', 'correct_count', 0),
        'wrong_count': _field(data, 'wrongCount', 'wrong_count', 0),
        'meaning_recognition_score': _field(
          data,
          'meaningRecognitionScore',
          'meaning_recognition_score',
          20,
        ),
        'meaning_recall_score': _field(
          data,
          'meaningRecallScore',
          'meaning_recall_score',
          10,
        ),
        'spelling_score': _field(data, 'spellingScore', 'spelling_score', 10),
        'listening_score': _field(
          data,
          'listeningScore',
          'listening_score',
          10,
        ),
        'context_score': _field(data, 'contextScore', 'context_score', 10),
        'confidence_score': _field(
          data,
          'confidenceScore',
          'confidence_score',
          10,
        ),
        'next_review_at':
            _date(data['nextReviewAt'] ?? data['next_review_at']) ?? now,
        'last_reviewed_at': _date(
          data['lastReviewedAt'] ?? data['last_reviewed_at'],
        ),
        'created_at': _date(data['createdAt']) ?? now,
        'updated_at': _date(data['updatedAt']) ?? now,
      };
      (_userWords[uid] ??= {})[id] = row;
      saved.add(_copy(row)!);
    }
    return saved;
  }

  @override
  Future<void> insertStudySession(String uid, Map<String, dynamic> data) async {
    final id = data['id'] as String;
    (_studySessions[uid] ??= {})[id] = {
      'id': id,
      'uid': uid,
      'lesson_id': data['lessonId'],
      'started_at': _date(data['startedAt']) ?? DateTime.now().toUtc(),
      'ended_at': _date(data['endedAt']) ?? DateTime.now().toUtc(),
      'total_questions': data['totalQuestions'] ?? 0,
      'correct_answers': data['correctAnswers'] ?? 0,
      'xp_earned': data['xpEarned'] ?? 0,
      'mistake_word_ids': ((data['mistakeWordIds'] as List?) ?? const []).join(
        ',',
      ),
      'answer_events': jsonEncode((data['answerEvents'] as List?) ?? const []),
    };
  }

  @override
  Future<Map<String, dynamic>?> studyPlanByUid(String uid) async {
    return _copy(_studyPlans[uid]);
  }

  @override
  Future<Map<String, dynamic>> upsertStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async {
    final existing = _studyPlans[uid];
    final now = DateTime.now().toUtc();
    final row = {
      'id': existing?['id']?.toString() ?? data['id']?.toString(),
      'uid': uid,
      'word_book_id': data['wordBookId'],
      'daily_new_target': data['dailyNewTarget'],
      'daily_review_limit': data['dailyReviewLimit'],
      'start_date': data['startDate'],
      'target_finish_date': data['targetFinishDate'],
      'reminder_time': data['reminderTime'],
      'status': data['status'],
      'created_at': existing?['created_at'] ?? _date(data['createdAt']) ?? now,
      'updated_at': _date(data['now']) ?? now,
    };
    _studyPlans[uid] = row;
    return _copy(row)!;
  }

  @override
  Future<void> resetCustomWordProgress(String uid, {DateTime? now}) async {
    final resetAt = now ?? DateTime.now().toUtc();
    final words = _customWords[uid]?.values;
    if (words == null) return;
    for (final word in words) {
      word
        ..['mastery_level'] = 0
        ..['correct_count'] = 0
        ..['wrong_count'] = 0
        ..['next_review_at'] = resetAt
        ..['updated_at'] = resetAt;
    }
  }

  @override
  Future<void> insertReviewEvent(String uid, Map<String, dynamic> data) async {
    final id = data['id'] as String;
    (_reviewEvents[uid] ??= {})[id] = {
      'id': id,
      'uid': uid,
      'word_id': data['wordId'] ?? data['word_id'],
      'is_correct': data['isCorrect'],
      'answer_time_ms': data['answerTimeMs'] ?? 0,
      'confidence': data['confidence'] ?? 3,
      'wrong_option': data['wrongOption'] ?? data['wrong_option'],
      'reviewed_at': _date(data['reviewedAt']) ?? DateTime.now().toUtc(),
      'mastery_before': data['masteryBefore'] ?? 0,
      'mastery_after': data['masteryAfter'] ?? 0,
      'next_review_at':
          _date(data['nextReviewAt'] ?? data['next_review_at']) ??
          DateTime.now().toUtc(),
    };
  }

  @override
  Future<List<String>> completedLessonIds(String uid) async {
    return _distinctSorted(
      _collection(_studySessions, uid).map((row) => row['lesson_id']),
    );
  }

  @override
  Future<List<String>> lessonIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    return _distinctSorted(
      _collection(_studySessions, uid)
          .where((row) {
            final endedAt = _date(row['ended_at']);
            return endedAt != null &&
                !endedAt.isBefore(startUtc) &&
                endedAt.isBefore(endUtc);
          })
          .map((row) => row['lesson_id']),
    );
  }

  @override
  Future<List<String>> reviewWordIdsInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    return _distinctSorted(
      _collection(_reviewEvents, uid)
          .where((row) {
            final reviewedAt = _date(row['reviewed_at']);
            return reviewedAt != null &&
                !reviewedAt.isBefore(startUtc) &&
                reviewedAt.isBefore(endUtc);
          })
          .map((row) => row['word_id']),
    );
  }

  @override
  Future<List<String>> rewardIdsForDate(String uid, String localDate) async {
    return [
      for (final row in _collection(_rewardClaims, uid))
        if (row['local_date'] == localDate) row['reward_id'].toString(),
    ];
  }

  @override
  Future<bool> claimReward({
    required String uid,
    required String rewardId,
    required String localDate,
    required int points,
  }) async {
    final user = _users[uid];
    if (user == null) throw StateError('user not found');
    final id = '$localDate:$rewardId';
    final claims = _rewardClaims[uid] ??= {};
    if (claims.containsKey(id)) return false;
    claims[id] = {
      'uid': uid,
      'reward_id': rewardId,
      'local_date': localDate,
      'points': points,
      'claimed_at': DateTime.now().toUtc(),
    };
    user['xp'] = _int(user['xp']) + points;
    user['updated_at'] = DateTime.now().toUtc();
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> notifications(
    String uid, {
    bool unreadOnly = false,
    String? type,
  }) async {
    final rows = _collection(_notifications, uid).where((row) {
      if (unreadOnly && row['is_read'] == true) return false;
      if (type != null && row['type'] != type) return false;
      return true;
    }).toList();
    rows.sort((a, b) {
      final createdA =
          _date(a['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final createdB =
          _date(b['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return createdB.compareTo(createdA);
    });
    return rows;
  }

  @override
  Future<Map<String, dynamic>?> notificationById(String uid, String id) async {
    return _copy(_notifications[uid]?[id]);
  }

  @override
  Future<void> upsertNotification(String uid, Map<String, dynamic> data) {
    return upsertNotifications(uid, [data]);
  }

  @override
  Future<void> upsertNotifications(
    String uid,
    List<Map<String, dynamic>> notifications,
  ) async {
    for (final data in notifications) {
      final sourceKey = data['sourceKey']?.toString();
      final existing = sourceKey == null
          ? null
          : _collection(_notifications, uid).where((row) {
              return row['source_key'] == sourceKey;
            }).firstOrNull;
      final id = existing?['id']?.toString() ?? data['id']?.toString();
      if (id == null || id.isEmpty) continue;
      (_notifications[uid] ??= {})[id] = {
        ...?existing,
        'id': id,
        'uid': uid,
        'type': data['type'],
        'title': data['title'],
        'body': data['body'],
        'target_route': data['targetRoute'] ?? '/home',
        'is_read': existing?['is_read'] ?? data['isRead'] ?? false,
        'source_key': sourceKey,
        'read_at': existing?['read_at'] ?? _date(data['readAt']),
        'created_at':
            existing?['created_at'] ??
            _date(data['createdAt']) ??
            DateTime.now().toUtc(),
      };
    }
  }

  @override
  Future<Map<String, dynamic>?> markNotificationRead(
    String uid,
    String id,
  ) async {
    final row = _notifications[uid]?[id];
    if (row == null) return null;
    row['is_read'] = true;
    row['read_at'] ??= DateTime.now().toUtc();
    return _copy(row);
  }

  @override
  Future<int> markAllNotificationsRead(String uid) async {
    var count = 0;
    final rows = _notifications[uid]?.values;
    if (rows == null) return 0;
    for (final row in rows) {
      if (row['is_read'] != true) {
        row['is_read'] = true;
        row['read_at'] ??= DateTime.now().toUtc();
        count++;
      }
    }
    return count;
  }

  @override
  Future<bool> hasStudySessionInRange(
    String uid,
    DateTime startUtc,
    DateTime endUtc,
  ) async {
    return (await lessonIdsInRange(uid, startUtc, endUtc)).isNotEmpty;
  }

  @override
  Future<int> dueReviewCount(String uid) async {
    return (await customWords(uid, dueOnly: true)).length +
        (await userWords(uid, dueOnly: true)).length;
  }

  List<Map<String, dynamic>> _collection(
    Map<String, Map<String, Map<String, dynamic>>> store,
    String uid,
  ) {
    return [
      for (final row in store[uid]?.values ?? const <Map<String, dynamic>>[])
        _copy(row)!,
    ];
  }

  List<Map<String, dynamic>> _filterReviewRows(
    List<Map<String, dynamic>> rows, {
    required bool dueOnly,
    required bool includeNew,
  }) {
    final now = DateTime.now().toUtc();
    final filtered = dueOnly
        ? rows.where((row) {
            final dueAt = _date(row['next_review_at']);
            if (dueAt == null || dueAt.isAfter(now)) return false;
            if (includeNew) return true;
            final status = row['status']?.toString();
            return row['is_ignored'] != true &&
                status != 'New' &&
                status != 'Previewed' &&
                status != 'Ignored';
          }).toList()
        : rows;
    filtered.sort((a, b) {
      final updatedA =
          _date(a['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      final updatedB =
          _date(b['updated_at']) ?? DateTime.fromMillisecondsSinceEpoch(0);
      return updatedB.compareTo(updatedA);
    });
    return filtered;
  }
}

Map<String, fs.Value> _fields(Map<String, dynamic> data) {
  return data.map((key, value) => MapEntry(key, _value(value)));
}

fs.Value _value(Object? value) {
  if (value == null) return fs.Value(nullValue: 'NULL_VALUE');
  if (value is bool) return fs.Value(booleanValue: value);
  if (value is int) return fs.Value(integerValue: value.toString());
  if (value is double) return fs.Value(doubleValue: value);
  if (value is DateTime) {
    return fs.Value(timestampValue: value.toUtc().toIso8601String());
  }
  if (value is List) {
    return fs.Value(
      arrayValue: fs.ArrayValue(
        values: [for (final item in value) _value(item)],
      ),
    );
  }
  if (value is Map) {
    return fs.Value(
      mapValue: fs.MapValue(fields: _fields(Map<String, dynamic>.from(value))),
    );
  }
  return fs.Value(stringValue: value.toString());
}

Map<String, dynamic> _rowFromDocument(fs.Document document) {
  final row = <String, dynamic>{};
  for (final entry
      in document.fields?.entries ?? const <MapEntry<String, fs.Value>>[]) {
    row[entry.key] = _decodeValue(entry.value);
  }
  row.putIfAbsent('id', () => document.name?.split('/').last);
  return row;
}

Object? _decodeValue(fs.Value value) {
  if (value.nullValue != null) return null;
  if (value.booleanValue != null) return value.booleanValue;
  if (value.integerValue != null) return int.tryParse(value.integerValue!);
  if (value.doubleValue != null) return value.doubleValue;
  if (value.timestampValue != null) {
    return DateTime.tryParse(value.timestampValue!)?.toUtc();
  }
  if (value.arrayValue != null) {
    return [
      for (final item in value.arrayValue?.values ?? const <fs.Value>[])
        _decodeValue(item),
    ];
  }
  if (value.mapValue != null) {
    return value.mapValue?.fields?.map(
      (key, nested) => MapEntry(key, _decodeValue(nested)),
    );
  }
  return value.stringValue ?? value.referenceValue ?? value.bytesValue;
}

DateTime? _date(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value.toString())?.toUtc();
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

Object? _field(
  Map<String, dynamic> data,
  String camelKey,
  String snakeKey,
  Object? fallback,
) {
  return data[camelKey] ?? data[snakeKey] ?? fallback;
}

bool _isWritePreconditionError(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('already') ||
      message.contains('exists') ||
      message.contains('precondition') ||
      message.contains('409');
}

String _encodedId(String value) {
  return base64Url.encode(utf8.encode(value)).replaceAll('=', '');
}

List<String> _distinctSorted(Iterable<Object?> values) {
  return values
      .where((value) => value != null && value.toString().isNotEmpty)
      .map((value) => value.toString())
      .toSet()
      .toList()
    ..sort();
}

Map<String, dynamic>? _copy(Map<String, dynamic>? row) {
  return row == null ? null : Map<String, dynamic>.from(row);
}
