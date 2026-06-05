import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'config.dart';
import 'database.dart';
import 'json_response.dart';
import 'notification_policy.dart';

Router buildRouter(AppConfig config, AppDatabase database) {
  final router = Router();

  router.get('/health', (Request request) {
    return jsonResponse({'status': 'ok'});
  });

  router.post('/auth/register', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final password = body['password'] as String? ?? '';
    final name = (body['name'] as String? ?? '').trim();
    if (email.isEmpty || password.length < 6 || name.isEmpty) {
      return jsonResponse({
        'error': 'name, valid email, and 6+ character password are required',
      }, status: 400);
    }
    if (await database.userByEmail(email) != null) {
      return jsonResponse({'error': 'email already registered'}, status: 409);
    }
    final salt = newSalt();
    final uid = newId();
    await database.insertUser(
      id: uid,
      email: email,
      passwordHash: hashPassword(password, salt),
      passwordSalt: salt,
      name: name,
    );
    final user = await database.userById(uid);
    return jsonResponse({
      'token': issueToken(config, uid: uid, email: email),
      'user': userDto(user!),
    }, status: 201);
  });

  router.post('/auth/login', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final password = body['password'] as String? ?? '';
    final user = await database.userByEmail(email);
    if (user == null) {
      return jsonResponse({'error': 'invalid email or password'}, status: 401);
    }
    final expected = hashPassword(password, user['password_salt'] as String);
    if (expected != user['password_hash']) {
      return jsonResponse({'error': 'invalid email or password'}, status: 401);
    }
    return jsonResponse({
      'token': issueToken(config, uid: user['id'] as String, email: email),
      'user': userDto(user),
    });
  });

  router.get('/me', (Request request) async {
    return _protected(config, request, (uid) async {
      final user = await database.userById(uid);
      if (user == null)
        return jsonResponse({'error': 'user not found'}, status: 404);
      return jsonResponse({'user': userDto(user)});
    });
  });

  router.patch('/me', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final user = await database.updateUser(uid, body);
      return jsonResponse({'user': userDto(user)});
    });
  });

  router.get('/custom-words', (Request request) async {
    return _protected(config, request, (uid) async {
      final words = await database.customWords(uid);
      return jsonResponse(words.map(wordDto).toList());
    });
  });

  router.post('/custom-words', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final id = body['id'] as String? ?? newId();
      if ((body['word'] as String? ?? '').trim().isEmpty ||
          (body['meaning'] as String? ?? '').trim().isEmpty) {
        return jsonResponse({
          'error': 'word and meaning are required',
        }, status: 400);
      }
      final word = await database.upsertCustomWord(uid, {...body, 'id': id});
      return jsonResponse({'word': wordDto(word)}, status: 201);
    });
  });

  router.patch('/custom-words/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final existing = await database.customWordById(uid, id);
      if (existing == null)
        return jsonResponse({'error': 'word not found'}, status: 404);
      final merged = {...wordDto(existing), ...body, 'id': id};
      final word = await database.upsertCustomWord(uid, merged, id: id);
      return jsonResponse({'word': wordDto(word)});
    });
  });

  router.delete('/custom-words/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      await database.deleteCustomWord(uid, id);
      return jsonResponse({'deleted': true});
    });
  });

  router.get('/user-words', (Request request) async {
    return _protected(config, request, (uid) async {
      final words = await database.userWords(uid);
      return jsonResponse(words.map(userWordDto).toList());
    });
  });

  router.post('/user-words', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      if (bodyString(body, 'wordId').isEmpty) {
        return jsonResponse({'error': 'wordId is required'}, status: 400);
      }
      final word = await database.upsertUserWord(uid, body);
      return jsonResponse({'word': userWordDto(word)}, status: 201);
    });
  });

  router.post('/user-words/batch', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final rawWords = body['words'];
      if (rawWords is! List) {
        return jsonResponse({'error': 'words list is required'}, status: 400);
      }
      final words = rawWords.whereType<Map>().map((item) {
        return Map<String, dynamic>.from(item);
      }).toList();
      final saved = await database.upsertUserWords(uid, words);
      return jsonResponse({
        'words': saved.map(userWordDto).toList(),
      }, status: 201);
    });
  });

  router.post('/study-sessions', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      await database.insertStudySession(uid, body);
      return jsonResponse({'recorded': true}, status: 201);
    });
  });

  router.get('/review/due', (Request request) async {
    return _protected(config, request, (uid) async {
      final customWords = await database.customWords(uid, dueOnly: true);
      final userWords = await database.userWords(uid, dueOnly: true);
      return jsonResponse([
        ...customWords.map(wordDto),
        ...userWords.map((word) => {...userWordDto(word), 'source': 'target'}),
      ]);
    });
  });

  router.post('/review-events', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      await database.insertReviewEvent(uid, body);
      return jsonResponse({'recorded': true}, status: 201);
    });
  });

  router.get('/notifications', (Request request) async {
    return _protected(config, request, (uid) async {
      final type = request.url.queryParameters['type'];
      if (type != null && !notificationTypes.contains(type)) {
        return jsonResponse({
          'error': 'invalid notification type',
        }, status: 400);
      }
      final localDate = request.url.queryParameters['localDate'];
      if (localDate != null && !isNotificationDateKey(localDate)) {
        return jsonResponse({'error': 'invalid localDate'}, status: 400);
      }
      final timezoneOffsetMinutes = parseNotificationTimezoneOffsetMinutes(
        request.url.queryParameters['timezoneOffsetMinutes'],
      );
      if (timezoneOffsetMinutes == null) {
        return jsonResponse({
          'error': 'invalid timezoneOffsetMinutes',
        }, status: 400);
      }
      final dayWindow = notificationDayWindow(
        nowUtc: DateTime.now().toUtc(),
        localDate: localDate,
        timezoneOffsetMinutes: timezoneOffsetMinutes,
      );
      await _ensureNotificationsForToday(database, uid, dayWindow);
      final unreadOnly =
          request.url.queryParameters['unreadOnly']?.toLowerCase() == 'true';
      final notifications = await database.notifications(
        uid,
        unreadOnly: unreadOnly,
        type: type,
      );
      return jsonResponse(notifications.map(notificationDto).toList());
    });
  });

  router.patch('/notifications/read-all', (Request request) async {
    return _protected(config, request, (uid) async {
      final updated = await database.markAllNotificationsRead(uid);
      return jsonResponse({'updated': updated});
    });
  });

  router.patch('/notifications/<id>/read', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final notification = await database.markNotificationRead(uid, id);
      if (notification == null) {
        return jsonResponse({'error': 'notification not found'}, status: 404);
      }
      return jsonResponse({'notification': notificationDto(notification)});
    });
  });

  return router;
}

Middleware corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, Content-Type, Authorization',
  };
  return (innerHandler) {
    return (request) async {
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: headers);
      }
      final response = await innerHandler(request);
      return response.change(headers: {...response.headers, ...headers});
    };
  };
}

String bodyString(Map<String, dynamic> body, String key) {
  return body[key]?.toString().trim() ?? '';
}

Future<Response> _protected(
  AppConfig config,
  Request request,
  Future<Response> Function(String uid) action,
) async {
  final uid = verifyToken(config, request.headers['Authorization']);
  if (uid == null) {
    return jsonResponse({
      'error': 'missing or invalid bearer token',
    }, status: 401);
  }
  return action(uid);
}

Map<String, dynamic> userDto(Map<String, dynamic> row) {
  return {
    'uid': row['id'],
    'name': row['name'],
    'email': row['email'],
    'avatarUrl': null,
    'targetExam': row['target_exam'],
    'level': row['level'],
    'dailyGoal': row['daily_goal'],
    'xp': row['xp'],
    'streak': row['streak'],
    'lastStudyDate': (row['last_study_date'] as DateTime?)?.toIso8601String(),
    'createdAt': (row['created_at'] as DateTime).toIso8601String(),
    'updatedAt': (row['updated_at'] as DateTime).toIso8601String(),
  };
}

Map<String, dynamic> wordDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'uid': row['uid'],
    'word': row['word'],
    'meaning': row['meaning'],
    'exampleSentence': row['example_sentence'] ?? row['exampleSentence'] ?? '',
    'note': row['note'] ?? '',
    'tag': row['tag'] ?? 'custom',
    'difficulty': row['difficulty'] ?? 'Medium',
    'status': row['status'] ?? 'Learning',
    'easeFactor': row['ease_factor'] ?? row['easeFactor'] ?? 2.5,
    'intervalDays': row['interval_days'] ?? row['intervalDays'] ?? 0,
    'repetitionCount': row['repetition_count'] ?? row['repetitionCount'] ?? 0,
    'lapseCount': row['lapse_count'] ?? row['lapseCount'] ?? 0,
    'masteryLevel': row['mastery_level'] ?? row['masteryLevel'] ?? 0,
    'correctCount': row['correct_count'] ?? row['correctCount'] ?? 0,
    'wrongCount': row['wrong_count'] ?? row['wrongCount'] ?? 0,
    'meaningRecognitionScore':
        row['meaning_recognition_score'] ?? row['meaningRecognitionScore'] ?? 0,
    'meaningRecallScore':
        row['meaning_recall_score'] ?? row['meaningRecallScore'] ?? 0,
    'spellingScore': row['spelling_score'] ?? row['spellingScore'] ?? 0,
    'listeningScore': row['listening_score'] ?? row['listeningScore'] ?? 0,
    'contextScore': row['context_score'] ?? row['contextScore'] ?? 0,
    'confidenceScore': row['confidence_score'] ?? row['confidenceScore'] ?? 0,
    'nextReviewAt': _dateValue(row['next_review_at'] ?? row['nextReviewAt']),
    'lastReviewedAt': row['last_reviewed_at'] == null
        ? row['lastReviewedAt']?.toString()
        : _dateValue(row['last_reviewed_at']),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
    'source': row['source'] ?? 'custom',
  };
}

Map<String, dynamic> userWordDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'uid': row['uid'],
    'wordId': row['word_id'] ?? row['wordId'],
    'wordBookId': row['word_book_id'] ?? row['wordBookId'] ?? '',
    'word': row['word'] ?? row['wordId'],
    'meaning': row['meaning'] ?? '',
    'exampleSentence': row['example_sentence'] ?? row['exampleSentence'] ?? '',
    'difficulty': row['difficulty'] ?? 'Medium',
    'status': row['status'] ?? 'New',
    'isFavorite': row['is_favorite'] ?? row['isFavorite'] ?? false,
    'isInNewWordBook':
        row['is_in_new_word_book'] ?? row['isInNewWordBook'] ?? false,
    'isIgnored': row['is_ignored'] ?? row['isIgnored'] ?? false,
    'easeFactor': row['ease_factor'] ?? row['easeFactor'] ?? 2.5,
    'intervalDays': row['interval_days'] ?? row['intervalDays'] ?? 0,
    'repetitionCount': row['repetition_count'] ?? row['repetitionCount'] ?? 0,
    'lapseCount': row['lapse_count'] ?? row['lapseCount'] ?? 0,
    'masteryLevel': row['mastery_level'] ?? row['masteryLevel'] ?? 0,
    'correctCount': row['correct_count'] ?? row['correctCount'] ?? 0,
    'wrongCount': row['wrong_count'] ?? row['wrongCount'] ?? 0,
    'meaningRecognitionScore':
        row['meaning_recognition_score'] ?? row['meaningRecognitionScore'] ?? 0,
    'meaningRecallScore':
        row['meaning_recall_score'] ?? row['meaningRecallScore'] ?? 0,
    'spellingScore': row['spelling_score'] ?? row['spellingScore'] ?? 0,
    'listeningScore': row['listening_score'] ?? row['listeningScore'] ?? 0,
    'contextScore': row['context_score'] ?? row['contextScore'] ?? 0,
    'confidenceScore': row['confidence_score'] ?? row['confidenceScore'] ?? 0,
    'nextReviewAt': _dateValue(row['next_review_at'] ?? row['nextReviewAt']),
    'lastReviewedAt': row['last_reviewed_at'] == null
        ? row['lastReviewedAt']?.toString()
        : _dateValue(row['last_reviewed_at']),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
    'source': 'target',
  };
}

Map<String, dynamic> notificationDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'uid': row['uid'],
    'type': row['type'],
    'title': row['title'],
    'body': row['body'],
    'targetRoute': row['target_route'] ?? row['targetRoute'] ?? '/home',
    'isRead': row['is_read'] ?? row['isRead'] ?? false,
    'sourceKey': row['source_key'] ?? row['sourceKey'],
    'readAt': (row['read_at'] as DateTime?)?.toIso8601String(),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
  };
}

Future<void> _ensureNotificationsForToday(
  AppDatabase database,
  String uid,
  NotificationDayWindow dayWindow,
) async {
  final now = DateTime.now().toUtc();
  final user = await database.userById(uid);
  if (user == null) return;
  final hasStudyToday = await database.hasStudySessionInRange(
    uid,
    dayWindow.startUtc,
    dayWindow.endUtc,
  );
  final dueReviewCount = await database.dueReviewCount(uid);
  final lastStudyDate = user['last_study_date'];
  final hasCheckedIn =
      lastStudyDate is DateTime &&
      !lastStudyDate.toUtc().isBefore(dayWindow.startUtc) &&
      lastStudyDate.toUtc().isBefore(dayWindow.endUtc);
  final dailyGoal = user['daily_goal'] ?? 10;
  final generated = generatedNotificationsForToday(
    dateKey: dayWindow.dateKey,
    dailyGoal: dailyGoal is int ? dailyGoal : int.tryParse('$dailyGoal') ?? 10,
    hasStudyToday: hasStudyToday,
    dueReviewCount: dueReviewCount,
    hasCheckedIn: hasCheckedIn,
  );
  await database.upsertNotifications(uid, [
    for (final notification in generated)
      {
        'id': newId(),
        'type': notification['type'],
        'title': notification['title'],
        'body': notification['body'],
        'targetRoute': notification['targetRoute'],
        'isRead': false,
        'sourceKey': notification['sourceKey'],
        'createdAt': now,
      },
  ]);
}

String _dateValue(Object? value) {
  if (value is DateTime) return value.toIso8601String();
  return value?.toString() ?? DateTime.now().toUtc().toIso8601String();
}
