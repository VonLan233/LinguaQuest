import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'config.dart';
import 'database.dart';
import 'json_response.dart';
import 'notification_policy.dart';
import 'reward_policy.dart';

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

  router.post('/study-sessions', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      await database.insertStudySession(uid, body);
      return jsonResponse({'recorded': true}, status: 201);
    });
  });

  router.get('/review/due', (Request request) async {
    return _protected(config, request, (uid) async {
      final words = await database.customWords(uid, dueOnly: true);
      return jsonResponse(words.map(wordDto).toList());
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

  router.get('/rewards/tasks', (Request request) async {
    return _protected(config, request, (uid) async {
      final dayWindow = _dayWindowFromQuery(request);
      if (dayWindow == null) {
        return jsonResponse({
          'error': 'valid localDate and timezoneOffsetMinutes are required',
        }, status: 400);
      }
      final tasks = await _dailyRewardTasks(database, uid, dayWindow);
      return jsonResponse({'dateKey': dayWindow.dateKey, 'tasks': tasks});
    });
  });

  router.post('/rewards/check-in', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final dayWindow = _dayWindowFromBody(body);
      if (dayWindow == null) {
        return jsonResponse({
          'error': 'valid localDate and timezoneOffsetMinutes are required',
        }, status: 400);
      }
      final user = await database.userById(uid);
      if (user == null) {
        return jsonResponse({'error': 'user not found'}, status: 404);
      }
      final inserted = await database.upsertCheckIn(uid, dayWindow.dateKey);
      final hadCheckedInToday = !inserted;
      var updatedUser = user;
      if (!hadCheckedInToday) {
        final now = DateTime.now().toUtc();
        final currentStreak = user['streak'] is int ? user['streak'] as int : 0;
        final hasStudyToday = await database.hasStudySessionInRange(
          uid,
          dayWindow.startUtc,
          dayWindow.endUtc,
        );
        var newStreak = currentStreak;
        if (!hasStudyToday) {
          final hasPreviousDayCheckIn = await database.hasCheckIn(
            uid,
            _previousDateKey(dayWindow.dateKey),
          );
          final hasPreviousDayStudy = await database.hasStudySessionInRange(
            uid,
            dayWindow.startUtc.subtract(const Duration(days: 1)),
            dayWindow.endUtc.subtract(const Duration(days: 1)),
          );
          newStreak = hasPreviousDayCheckIn || hasPreviousDayStudy
              ? currentStreak + 1
              : 1;
        }
        updatedUser = await database.updateUser(uid, {
          'streak': newStreak,
          'lastStudyDate': now,
        });
      }
      final tasks = await _dailyRewardTasks(database, uid, dayWindow);
      return jsonResponse({
        'checkedIn': true,
        'dateKey': dayWindow.dateKey,
        'tasks': tasks,
        'user': userDto(updatedUser),
      });
    });
  });

  router.post('/reward-events', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final type = body['type']?.toString() ?? '';
      if (!{
        'trainingChallenge',
        'wrongCleanup',
        'forumInteraction',
      }.contains(type)) {
        return jsonResponse({
          'error': 'invalid reward event type',
        }, status: 400);
      }
      final dayWindow = _dayWindowFromBody(body);
      if (dayWindow == null) {
        return jsonResponse({
          'error': 'valid localDate and timezoneOffsetMinutes are required',
        }, status: 400);
      }
      await database.recordDailyActivity(uid, dayWindow.dateKey, type);
      final tasks = await _dailyRewardTasks(database, uid, dayWindow);
      return jsonResponse({
        'recorded': true,
        'dateKey': dayWindow.dateKey,
        'tasks': tasks,
      }, status: 201);
    });
  });

  router.post('/rewards/tasks/<id>/claim', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final definition = rewardTaskDefinitionById(id);
      if (definition == null) {
        return jsonResponse({'error': 'reward task not found'}, status: 404);
      }
      final body = await readJsonMap(request);
      final dayWindow = _dayWindowFromBody(body);
      if (dayWindow == null) {
        return jsonResponse({
          'error': 'valid localDate and timezoneOffsetMinutes are required',
        }, status: 400);
      }
      final user = await database.userById(uid);
      if (user == null) {
        return jsonResponse({'error': 'user not found'}, status: 404);
      }
      final claimed = await database.rewardClaimsForDate(
        uid,
        dayWindow.dateKey,
      );
      if (claimed.contains(id)) {
        final tasks = await _dailyRewardTasks(database, uid, dayWindow);
        return jsonResponse({
          'claimed': false,
          'alreadyClaimed': true,
          'dateKey': dayWindow.dateKey,
          'tasks': tasks,
          'user': userDto(user),
        });
      }
      final behavior = await _dailyRewardBehavior(database, uid, dayWindow);
      if (!isRewardTaskDone(id, behavior)) {
        return jsonResponse({
          'error': 'task_not_complete',
          'tasks': dailyRewardTaskDtos(
            behavior: behavior,
            claimedTaskIds: claimed,
          ),
        }, status: 409);
      }
      final claim = await database.claimRewardTask(
        id: newId(),
        uid: uid,
        dateKey: dayWindow.dateKey,
        taskId: id,
        points: definition.points,
      );
      final tasks = await _dailyRewardTasks(database, uid, dayWindow);
      return jsonResponse({
        'claimed': claim.inserted,
        'dateKey': dayWindow.dateKey,
        'tasks': tasks,
        'user': userDto(claim.user ?? user),
      });
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
    'masteryLevel': row['mastery_level'] ?? row['masteryLevel'] ?? 0,
    'correctCount': row['correct_count'] ?? row['correctCount'] ?? 0,
    'wrongCount': row['wrong_count'] ?? row['wrongCount'] ?? 0,
    'nextReviewAt': _dateValue(row['next_review_at'] ?? row['nextReviewAt']),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
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
  final hasCheckedIn = await database.hasCheckIn(uid, dayWindow.dateKey);
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

NotificationDayWindow? _dayWindowFromQuery(Request request) {
  final localDate = request.url.queryParameters['localDate'];
  if (localDate != null && !isNotificationDateKey(localDate)) return null;
  final timezoneOffsetMinutes = parseNotificationTimezoneOffsetMinutes(
    request.url.queryParameters['timezoneOffsetMinutes'],
  );
  if (timezoneOffsetMinutes == null) return null;
  return notificationDayWindow(
    nowUtc: DateTime.now().toUtc(),
    localDate: localDate,
    timezoneOffsetMinutes: timezoneOffsetMinutes,
  );
}

NotificationDayWindow? _dayWindowFromBody(Map<String, dynamic> body) {
  final localDate = body['localDate']?.toString();
  if (localDate != null && !isNotificationDateKey(localDate)) return null;
  final timezoneOffsetMinutes = parseNotificationTimezoneOffsetMinutes(
    body['timezoneOffsetMinutes']?.toString(),
  );
  if (timezoneOffsetMinutes == null) return null;
  return notificationDayWindow(
    nowUtc: DateTime.now().toUtc(),
    localDate: localDate,
    timezoneOffsetMinutes: timezoneOffsetMinutes,
  );
}

Future<List<Map<String, dynamic>>> _dailyRewardTasks(
  AppDatabase database,
  String uid,
  NotificationDayWindow dayWindow,
) async {
  final behavior = await _dailyRewardBehavior(database, uid, dayWindow);
  final claimed = await database.rewardClaimsForDate(uid, dayWindow.dateKey);
  return dailyRewardTaskDtos(behavior: behavior, claimedTaskIds: claimed);
}

Future<DailyRewardBehavior> _dailyRewardBehavior(
  AppDatabase database,
  String uid,
  NotificationDayWindow dayWindow,
) async {
  final activity = await database.dailyActivity(uid, dayWindow.dateKey);
  return DailyRewardBehavior(
    checkedIn: await database.hasCheckIn(uid, dayWindow.dateKey),
    newLearningDone: await database.hasStudySessionInRange(
      uid,
      dayWindow.startUtc,
      dayWindow.endUtc,
      trainingOnly: false,
    ),
    reviewDone: await database.hasReviewEventInRange(
      uid,
      dayWindow.startUtc,
      dayWindow.endUtc,
    ),
    trainingChallengeDone:
        activity['training_challenge_completed'] == true ||
        await database.hasStudySessionInRange(
          uid,
          dayWindow.startUtc,
          dayWindow.endUtc,
          trainingOnly: true,
        ),
    wrongCleanupDone: activity['wrong_cleanup_completed'] == true,
    forumInteractionDone: activity['forum_interaction_completed'] == true,
  );
}

String _previousDateKey(String dateKey) {
  final parts = dateKey.split('-').map(int.parse).toList();
  final previous = DateTime.utc(
    parts[0],
    parts[1],
    parts[2],
  ).subtract(const Duration(days: 1));
  return notificationDateKey(previous);
}

String _dateValue(Object? value) {
  if (value is DateTime) return value.toIso8601String();
  return value?.toString() ?? DateTime.now().toUtc().toIso8601String();
}
