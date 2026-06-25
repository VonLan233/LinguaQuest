import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'achievement_policy.dart';
import 'ai_policy.dart';
import 'analytics_policy.dart';
import 'auth.dart';
import 'recommendation_policy.dart';
import 'config.dart';
import 'database.dart';
import 'email_sender.dart';
import 'forum_policy.dart';
import 'json_response.dart';
import 'lesson_catalog.dart';
import 'lottery_policy.dart';
import 'moderation_policy.dart';
import 'notification_policy.dart';
import 'privacy_policy.dart';
import 'reward_policy.dart';
import 'reward_task_policy.dart';
import 'study_plan_policy.dart';
import 'study_spot_policy.dart';

final _httpClient = http.Client();

Router buildRouter(
  AppConfig config,
  AppDatabase database, {
  http.Client? httpClient,
  EmailSender? emailSender,
  AiPolicyService? aiPolicy,
}) {
  final client = httpClient ?? _httpClient;
  final mailer = emailSender ?? EmailSender.fromConfig(config);
  final router = Router();

  router.get('/health', (Request request) {
    return jsonResponse({'status': 'ok'});
  });

  router.get('/tts', (Request request) async {
    final word = request.url.queryParameters['word']?.trim() ?? '';
    final type = request.url.queryParameters['type']?.trim() ?? '1';
    if (word.isEmpty || word.length > 100) {
      return jsonResponse({
        'error': 'word is required and must be under 100 characters',
      }, status: 400);
    }
    if (type != '1' && type != '2') {
      return jsonResponse({
        'error': 'type must be 1 (UK) or 2 (US)',
      }, status: 400);
    }
    try {
      final uri = Uri.https('dict.youdao.com', '/dictvoice', {
        'audio': word,
        'type': type,
      });
      final streamedResponse = await client
          .send(http.Request('GET', uri))
          .timeout(const Duration(seconds: 5));
      if (streamedResponse.statusCode != 200) {
        await streamedResponse.stream.listen((_) {}).cancel();
        return jsonResponse({'error': 'tts unavailable'}, status: 502);
      }
      final contentLength = streamedResponse.contentLength;
      if (contentLength != null && contentLength > 5 * 1024 * 1024) {
        await streamedResponse.stream.listen((_) {}).cancel();
        return jsonResponse({'error': 'tts response too large'}, status: 502);
      }
      final contentType =
          (streamedResponse.headers['content-type'] ??
                  streamedResponse.headers['Content-Type'] ??
                  'audio/mpeg')
              .toLowerCase();
      if (!contentType.startsWith('audio/')) {
        await streamedResponse.stream.listen((_) {}).cancel();
        return jsonResponse({'error': 'tts unavailable'}, status: 502);
      }
      final bytesBuilder = BytesBuilder();
      var totalBytes = 0;
      const maxBytes = 5 * 1024 * 1024;
      await for (final chunk in streamedResponse.stream.timeout(
        const Duration(seconds: 5),
      )) {
        totalBytes += chunk.length;
        if (totalBytes > maxBytes) {
          return jsonResponse({
            'error': 'tts response invalid or too large',
          }, status: 502);
        }
        bytesBuilder.add(chunk);
      }
      final bytes = bytesBuilder.takeBytes();
      if (bytes.isEmpty) {
        return jsonResponse({
          'error': 'tts response invalid or too large',
        }, status: 502);
      }
      return Response.ok(
        bytes,
        headers: {
          'Content-Type': contentType,
          'Cache-Control': 'public, max-age=86400',
        },
      );
    } catch (e, stackTrace) {
      stderr.writeln('TTS proxy error: $e\n$stackTrace');
      return jsonResponse({'error': 'tts unavailable'}, status: 502);
    }
  });

  router.get('/lessons', (Request request) {
    return jsonResponse(lessonCatalog());
  });

  router.get('/wordbooks', (Request request) async {
    final books = await _loadWordBooks();
    return jsonResponse(books);
  });

  router.get('/wordbooks/<id>', (Request request, String id) async {
    final books = await _loadWordBooks();
    final book = _wordBookById(books, id);
    if (book == null) {
      return jsonResponse({'error': 'wordbook not found'}, status: 404);
    }
    return jsonResponse({'wordbook': book});
  });

  router.get('/words', (Request request) async {
    final books = await _loadWordBooks();
    final wordBookId = request.url.queryParameters['wordBookId'];
    final query = request.url.queryParameters['q']?.trim().toLowerCase();
    final scopedBooks = wordBookId == null
        ? books
        : books.where((book) => book['id'] == wordBookId).toList();
    if (wordBookId != null && scopedBooks.isEmpty) {
      return jsonResponse({'error': 'wordbook not found'}, status: 404);
    }
    final words = _wordsFromBooks(scopedBooks).where((word) {
      if (query == null || query.isEmpty) return true;
      return _wordMatchesQuery(word, query);
    }).toList();
    return jsonResponse(words);
  });

  router.get('/words/<id>', (Request request, String id) async {
    final word = _wordById(await _loadWordBooks(), id);
    if (word == null) {
      return jsonResponse({'error': 'word not found'}, status: 404);
    }
    return jsonResponse({'word': word});
  });

  router.post('/auth/register', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final password = body['password'] as String? ?? '';
    final name = (body['name'] as String? ?? '').trim();
    if (name.isEmpty || !isValidEmail(email) || password.length < 6) {
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
    await _issueAndSendCode(config, database, mailer, uid: uid, email: email);
    return jsonResponse(
      {'status': 'verification_required', 'email': email},
      status: 202,
    );
  });

  router.post('/auth/verify', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final code = (body['code'] as String? ?? '').trim();
    final user = await database.userByEmail(email);
    if (user == null) {
      return jsonResponse({'error': 'invalid_code'}, status: 400);
    }
    final uid = user['id'] as String;
    if (user['email_verified'] == true) {
      return jsonResponse({
        'token': issueToken(config, uid: uid, email: email),
        'user': userDto(user),
      });
    }
    final row = await database.verificationCodeFor(uid);
    if (row == null ||
        (row['expires_at'] as DateTime).isBefore(DateTime.now().toUtc())) {
      return jsonResponse({'error': 'code_expired'}, status: 410);
    }
    if ((row['attempts'] as int) >= 5) {
      return jsonResponse({'error': 'too_many_attempts'}, status: 429);
    }
    final expected = hashPassword(code, row['code_salt'] as String);
    if (expected != row['code_hash']) {
      await database.incrementVerificationAttempts(uid);
      return jsonResponse({'error': 'invalid_code'}, status: 400);
    }
    await database.setEmailVerified(uid);
    await database.deleteVerificationCode(uid);
    final verified = await database.userById(uid);
    return jsonResponse({
      'token': issueToken(config, uid: uid, email: email),
      'user': userDto(verified!),
    });
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
    if (user['email_verified'] != true) {
      await _issueAndSendCode(
        config, database, mailer,
        uid: user['id'] as String, email: email,
      );
      return jsonResponse(
        {'error': 'email_not_verified', 'email': email},
        status: 403,
      );
    }
    return jsonResponse({
      'token': issueToken(config, uid: user['id'] as String, email: email),
      'user': userDto(user),
    });
  });

  router.post('/auth/resend', (Request request) async {
    final body = await readJsonMap(request);
    final email = (body['email'] as String? ?? '').trim().toLowerCase();
    final user = await database.userByEmail(email);
    // Don't leak account existence / verified state.
    if (user == null || user['email_verified'] == true) {
      return jsonResponse({'status': 'sent'});
    }
    final uid = user['id'] as String;
    final existing = await database.verificationCodeFor(uid);
    if (existing != null) {
      final last = existing['last_sent_at'] as DateTime;
      final elapsed = DateTime.now().toUtc().difference(last);
      if (elapsed < const Duration(seconds: 60)) {
        return jsonResponse(
          {'error': 'resend_cooldown', 'retryAfter': 60 - elapsed.inSeconds},
          status: 429,
        );
      }
    }
    await _issueAndSendCode(config, database, mailer, uid: uid, email: email);
    return jsonResponse({'status': 'sent'});
  });

  router.get('/me', (Request request) async {
    return _protected(config, request, (uid) async {
      final user = await database.userById(uid);
      if (user == null) {
        return jsonResponse({'error': 'user not found'}, status: 404);
      }
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
      if (existing == null) {
        return jsonResponse({'error': 'word not found'}, status: 404);
      }
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
      final words = userWordBatchItems(rawWords);
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

  router.get('/study-plan', (Request request) async {
    return _protected(config, request, (uid) async {
      final plan = await database.studyPlanByUid(uid);
      return jsonResponse({
        'studyPlan': plan == null ? null : studyPlanDto(plan),
      });
    });
  });

  router.put('/study-plan', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final validation = validateStudyPlanPayload(body);
      if (!validation.isValid) {
        return jsonResponse({'error': validation.error}, status: 400);
      }
      final plan = await database.upsertStudyPlan(uid, {
        ...validation.data!,
        'id': body['id']?.toString() ?? newId(),
      });
      await database.updateUser(uid, {
        'targetExam': _targetExamForWordBook(plan['word_book_id'] as String),
        'dailyGoal': plan['daily_new_target'],
      });
      return jsonResponse({'studyPlan': studyPlanDto(plan)});
    });
  });

  router.post('/study-plan/reset', (Request request) async {
    return _protected(config, request, (uid) async {
      final existing = await database.studyPlanByUid(uid);
      if (existing == null) {
        return jsonResponse({'error': 'study plan not found'}, status: 404);
      }
      final now = DateTime.now().toUtc();
      final today = DateTime.utc(now.year, now.month, now.day);
      final existingFinishDate = parseStudyPlanDate(
        existing['target_finish_date'] ?? existing['targetFinishDate'],
      );
      final resetFinishDate =
          existingFinishDate == null || existingFinishDate.isBefore(today)
          ? today.add(const Duration(days: 30))
          : existingFinishDate;
      final validation = validateStudyPlanPayload({
        'wordBookId': existing['word_book_id'] ?? existing['wordBookId'],
        'dailyNewTarget':
            existing['daily_new_target'] ?? existing['dailyNewTarget'],
        'dailyReviewLimit':
            existing['daily_review_limit'] ?? existing['dailyReviewLimit'],
        'reminderTime': existing['reminder_time'] ?? existing['reminderTime'],
        'status': 'active',
        'startDate': _dateKey(today),
        'targetFinishDate': _dateKey(resetFinishDate),
      }, now: now);
      if (!validation.isValid) {
        return jsonResponse({'error': validation.error}, status: 400);
      }
      final plan = await database.upsertStudyPlan(uid, {
        ...validation.data!,
        'id': existing['id']?.toString() ?? newId(),
      });
      await database.resetCustomWordProgress(
        uid,
        now: _dateTimeValue(plan['updated_at'] ?? plan['updatedAt']) ?? now,
      );
      return jsonResponse({'studyPlan': studyPlanDto(plan)});
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

  router.get('/lottery/prizes', (Request request) async {
    return _protected(config, request, (uid) async {
      final prizes = await database.lotteryPrizes();
      return jsonResponse({
        'cost': lotteryDrawCost,
        'prizes': prizes.map(prizeDto).toList(),
      });
    });
  });

  router.get('/lottery/assets', (Request request) async {
    return _protected(config, request, (uid) async {
      final assets = await database.userAssets(uid);
      return jsonResponse({'assets': assets.map(assetDto).toList()});
    });
  });

  router.post('/lottery/draw', (Request request) async {
    return _protected(config, request, (uid) async {
      final result = await database.drawLottery(
        uid: uid,
        drawId: newId(),
        assetId: newId(),
        notificationId: newId(),
      );
      if (result == null) {
        return jsonResponse({
          'error': 'not enough XP for this draw',
          'cost': lotteryDrawCost,
        }, status: 409);
      }
      final user = await database.userById(uid);
      final notifications = await database.notifications(uid, unreadOnly: true);
      return jsonResponse({
        'result': {
          'draw': result['draw'],
          'prize': prizeDto(result['prize'] as Map<String, dynamic>),
          'asset': assetDto(result['asset'] as Map<String, dynamic>),
          'balanceAfter': result['balanceAfter'],
        },
        'user': user == null ? null : userDto(user),
        'notifications': notifications.map(notificationDto).toList(),
      }, status: 201);
    });
  });

  router.post('/rewards/points', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final sourceType = (body['sourceType'] as String? ?? '').trim();
      final sourceId = (body['sourceId'] as String? ?? '').trim();
      final requestedPoints = body['points'] as int? ?? 0;
      final description = (body['description'] as String? ?? '').trim();
      final reward = validatedRewardPoints(
        sourceType: sourceType,
        sourceId: sourceId,
        requestedPoints: requestedPoints,
      );
      if (sourceType.isEmpty || sourceId.isEmpty || reward == null) {
        return jsonResponse({
          'error': 'invalid reward source or point rule',
        }, status: 400);
      }
      final result = await database.grantPoints(
        uid,
        sourceType: sourceType,
        sourceId: reward.canonicalSourceId,
        points: reward.points,
        description: description,
      );
      final awarded = result['awarded'] == true;
      return jsonResponse({
        'pointsAwarded': result['points_awarded'] ?? 0,
        'alreadyGranted': !awarded,
        'user': userDto(result),
      }, status: awarded ? 201 : 200);
    });
  });

  router.post('/exercise-records', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final rawRecords = body['records'];
      if (rawRecords is! List) {
        return jsonResponse({'error': 'records must be a list'}, status: 400);
      }
      if (rawRecords.length > 250) {
        return jsonResponse({
          'error': 'too many exercise records',
        }, status: 400);
      }
      final records = <Map<String, dynamic>>[];
      for (final rawRecord in rawRecords) {
        if (rawRecord is! Map) {
          return jsonResponse({
            'error': 'invalid exercise record',
          }, status: 400);
        }
        final record = Map<String, dynamic>.from(rawRecord);
        final validationError = _validateExerciseRecord(record);
        if (validationError != null) {
          return jsonResponse({'error': validationError}, status: 400);
        }
        records.add(record);
      }
      await database.insertExerciseRecords(uid, records);
      return jsonResponse({'recorded': true}, status: 201);
    });
  });

  router.get('/learning-progress', (Request request) async {
    return _protected(config, request, (uid) async {
      final dayWindow = _dayWindowFromQuery(request);
      if (dayWindow == null) {
        return jsonResponse({
          'error': 'invalid localDate or timezoneOffsetMinutes',
        }, status: 400);
      }
      return jsonResponse(await learningProgressDto(database, uid, dayWindow));
    });
  });

  router.post('/reward-claims', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final rewardId = (body['id'] as String? ?? '').trim();
      final points = _intValue(body['points']) ?? 0;
      if (rewardId.isEmpty || points <= 0) {
        return jsonResponse({
          'error': 'reward id and positive points are required',
        }, status: 400);
      }
      final dayWindow = _dayWindowFromBody(body);
      if (dayWindow == null) {
        return jsonResponse({
          'error': 'invalid localDate or timezoneOffsetMinutes',
        }, status: 400);
      }
      final claimed = await database.claimReward(
        uid: uid,
        rewardId: rewardId,
        localDate: dayWindow.dateKey,
        points: points,
      );
      final user = await database.userById(uid);
      if (user == null) {
        return jsonResponse({'error': 'user not found'}, status: 404);
      }
      return jsonResponse({
        'claimed': claimed,
        'user': userDto(user),
        'progress': await learningProgressDto(database, uid, dayWindow),
      }, status: claimed ? 201 : 200);
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

  // ── Analytics & Achievement & Leaderboard 路由 ────────────────────────────

  router.get('/analytics', (Request request) async {
    return _protected(config, request, (uid) async {
      final analytics = LearningAnalytics.mock();
      return jsonResponse(analytics.toJson());
    });
  });

  router.get('/recommendations', (Request request) async {
    return _protected(config, request, (uid) async {
      // Build word stats from the user's custom words in the database.
      // For mock/initial deployments we return 3 representative recommendations.
      final customWords = await database.customWords(uid);
      final wordStats = customWords.map((w) {
        return <String, dynamic>{
          'wordId': w['id']?.toString() ?? '',
          'listeningScore': _intValue(w['listening_score'] ?? w['listeningScore']) ?? 100,
          'contextScore': _intValue(w['context_score'] ?? w['contextScore']) ?? 100,
          'meaningRecallScore': _intValue(w['meaning_recall_score'] ?? w['meaningRecallScore']) ?? 100,
          'wrongCount': _intValue(w['wrong_count'] ?? w['wrongCount']) ?? 0,
        };
      }).toList();

      final recs = RecommendationPolicy.generate(wordStats: wordStats);

      // When there are no real weak words (e.g. new user), return mock recs
      // so the UI always has something useful to show.
      if (recs.isEmpty) {
        final mockRecs = [
          const Recommendation(
            targetWordIds: ['mock_w1', 'mock_w2'],
            exerciseType: 'listeningWordChoice',
            reason: 'Strengthen your listening recognition with these words',
            priority: 1,
            estimatedMinutes: 2,
          ),
          const Recommendation(
            targetWordIds: ['mock_w3', 'mock_w4'],
            exerciseType: 'sentenceCloze',
            reason: 'Practice using these words in context',
            priority: 2,
            estimatedMinutes: 2,
          ),
          const Recommendation(
            targetWordIds: ['mock_w5'],
            exerciseType: 'meaningChoice',
            reason: 'Review the meanings of these recently learned words',
            priority: 3,
            estimatedMinutes: 1,
          ),
        ];
        return jsonResponse(mockRecs.map((r) => r.toJson()).toList());
      }

      return jsonResponse(recs.map((r) => r.toJson()).toList());
    });
  });

  router.get('/achievements', (Request request) async {
    return _protected(config, request, (uid) async {
      final user = await database.userById(uid);
      final streak = user == null ? 0 : (user['streak'] as int? ?? 0);
      final xp = user == null ? 0 : (user['xp'] as int? ?? 0);
      final userWords = await database.userWords(uid);
      final masteredWords = userWords
          .where((w) => (w['mastery_level'] as int? ?? 0) >= 4)
          .length;
      final studySessions = await database.completedLessonIds(uid);
      final totalStudyDays = studySessions.length > 0 ? 1 : 0;
      final achievements = AchievementPolicy.evaluate(
        streakDays: streak,
        masteredWords: masteredWords,
        totalStudyDays: totalStudyDays,
        trainingXp: xp,
      );
      return jsonResponse(achievements.map((a) => a.toJson()).toList());
    });
  });

  router.get('/leaderboard', (Request request) async {
    return _protected(config, request, (uid) async {
      final dimension =
          request.url.queryParameters['dimension'] ?? 'global';
      final user = await database.userById(uid);
      final currentXp = user == null ? 0 : (user['xp'] as int? ?? 0);
      final currentName = user == null
          ? 'You'
          : (user['name'] as String? ?? 'You');

      final List<Map<String, dynamic>> mockEntries;
      switch (dimension) {
        case 'friends':
          mockEntries = [
            {'rank': 1, 'userId': 'mock_f1', 'name': 'Alex', 'xp': currentXp + 150, 'isCurrentUser': false},
            {'rank': 2, 'userId': 'mock_f2', 'name': 'Jordan', 'xp': currentXp + 50, 'isCurrentUser': false},
            {'rank': 3, 'userId': uid, 'name': currentName, 'xp': currentXp, 'isCurrentUser': true},
            {'rank': 4, 'userId': 'mock_f3', 'name': 'Morgan', 'xp': currentXp - 80, 'isCurrentUser': false},
          ];
        case 'class':
          mockEntries = [
            {'rank': 1, 'userId': 'mock_c1', 'name': 'Sam', 'xp': currentXp + 200, 'isCurrentUser': false},
            {'rank': 2, 'userId': uid, 'name': currentName, 'xp': currentXp, 'isCurrentUser': true},
            {'rank': 3, 'userId': 'mock_c2', 'name': 'Taylor', 'xp': currentXp - 120, 'isCurrentUser': false},
          ];
        default: // global
          mockEntries = [
            {'rank': 1, 'userId': 'mock_g1', 'name': 'Alice', 'xp': currentXp + 500, 'isCurrentUser': false},
            {'rank': 2, 'userId': 'mock_g2', 'name': 'Bob', 'xp': currentXp + 300, 'isCurrentUser': false},
            {'rank': 3, 'userId': 'mock_g3', 'name': 'Charlie', 'xp': currentXp + 100, 'isCurrentUser': false},
            {'rank': 4, 'userId': 'mock_g4', 'name': 'Diana', 'xp': currentXp + 20, 'isCurrentUser': false},
            {'rank': 5, 'userId': uid, 'name': currentName, 'xp': currentXp, 'isCurrentUser': true},
          ];
      }

      final currentUserRank = mockEntries
          .firstWhere(
            (e) => e['isCurrentUser'] == true,
            orElse: () => {'rank': -1},
          )['rank'] as int;

      return jsonResponse({
        'dimension': dimension,
        'entries': mockEntries,
        'currentUserRank': currentUserRank,
      });
    });
  });

  // ── AI 路由 ──────────────────────────────────────────────────────────────

  AiProvider _buildAiProvider() {
    if (config.aiProvider == 'remote' && config.aiApiKey.isNotEmpty) {
      return RemoteAiProvider(
        client: client,
        apiKey: config.aiApiKey,
        baseUrl: config.aiApiBaseUrl,
        model: config.aiModel,
      );
    }
    return MockAiProvider();
  }

  final effectiveAiPolicy = aiPolicy ??
      AiPolicyService(
        provider: _buildAiProvider(),
        dailyLimitPerUser: config.aiDailyLimitPerUser,
        dailyCountLookup: database.countAiHistoryToday,
      );

  Future<Response> _handleAiRequest(
    Request request,
    String featureType,
    String uid,
  ) async {
    final body = await readJsonMap(request);
    final prompt = body['prompt'] as String? ?? '';
    final targetWord = body['targetWord'] as String?;
    final targetLanguage = body['targetLanguage'] as String? ?? 'zh';
    if (prompt.isEmpty) {
      return jsonResponse({'error': 'prompt is required'}, status: 400);
    }
    final aiRequest = AiRequest(
      featureType: featureType,
      userId: uid,
      prompt: prompt,
      targetWord: targetWord,
      targetLanguage: targetLanguage,
    );
    final response = await effectiveAiPolicy.handle(aiRequest);
    if (!response.success) {
      final code = response.errorCode ?? 'ai_error';
      final status = switch (code) {
        'too_long' || 'blocked' => 400,
        'rate_limited' => 429,
        'ai_unavailable' => 503,
        _ => 422,
      };
      return jsonResponse({'error': code}, status: status);
    }
    final record = await database.insertAiHistory(
      uid,
      featureType,
      prompt,
      response.data,
    );
    return jsonResponse({
      'historyId': record['id'],
      'featureType': featureType,
      'data': response.data,
      'createdAt': record['createdAt'],
    });
  }

  // ── Public profile route (no auth required; isOwner determined by optional JWT) ──

  router.get('/users/<userId>/profile', (Request request, String userId) async {
    // Try to extract the requester's UID from the Bearer token (if present).
    final callerUid = verifyToken(config, request.headers['Authorization']);

    // Load the target user's data.
    final user = await database.userById(userId);
    if (user == null) {
      return jsonResponse({'error': 'user not found'}, status: 404);
    }

    // Load the target user's privacy flags.
    final privacyRow = await database.getUserPrivacy(userId);
    final flags = privacyRow == null
        ? const UserPrivacyFlags()
        : UserPrivacyFlags.fromJson({
            'publicStats': privacyRow['publicStats'],
            'publicStreak': privacyRow['publicStreak'],
            'publicWordbook': privacyRow['publicWordbook'],
            'publicPosts': privacyRow['publicPosts'],
          });

    final isOwner = callerUid != null && callerUid == userId;

    // Build the full profile before filtering.
    final streak = user['streak'] as int? ?? 0;
    final xp = user['xp'] as int? ?? 0;
    final userWords = await database.userWords(userId);
    final masteredWords = userWords
        .where((w) => (w['mastery_level'] as int? ?? 0) >= 4)
        .length;
    final learnedWords = userWords.length;

    final achievements = AchievementPolicy.evaluate(
      streakDays: streak,
      masteredWords: masteredWords,
      totalStudyDays: 0,
      trainingXp: xp,
    );
    final unlockedAchievements = achievements
        .where((a) => a.unlocked)
        .take(3)
        .map((a) => a.toJson())
        .toList();

    final fullProfile = <String, dynamic>{
      'uid': userId,
      'name': user['name'] ?? '',
      'streak': streak,
      'stats': {
        'learnedWords': learnedWords,
        'masteredWords': masteredWords,
        'totalDays': 0,
      },
      'wordbookProgress': masteredWords,
      'posts': <Map<String, dynamic>>[],
    };

    final filtered = PrivacyPolicy.filterPublicProfile(fullProfile, flags);

    return jsonResponse({
      ...filtered,
      'isOwner': isOwner,
      'achievements': unlockedAchievements,
    });
  });

  router.get('/privacy', (Request request) async {
    return _protected(config, request, (uid) async {
      final row = await database.getUserPrivacy(uid);
      final flags = row == null
          ? const UserPrivacyFlags()
          : UserPrivacyFlags.fromJson({
              'publicStats': row['publicStats'],
              'publicStreak': row['publicStreak'],
              'publicWordbook': row['publicWordbook'],
              'publicPosts': row['publicPosts'],
            });
      return jsonResponse(flags.toJson());
    });
  });

  router.put('/privacy', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final flags = UserPrivacyFlags.fromJson(body);
      await database.upsertUserPrivacy(uid, flags.toJson());
      return jsonResponse(flags.toJson());
    });
  });

  // ── Forum routes ──────────────────────────────────────────────────────────

  router.get('/forum/posts', (Request request) async {
    return _protected(config, request, (uid) async {
      final posts = await database.listForumPosts(status: 'approved');
      final result = <Map<String, dynamic>>[];
      for (final post in posts) {
        final postId = post['id'].toString();
        final liked = await database.hasLiked(uid, postId);
        final favorited = await database.hasFavorited(uid, postId);
        result.add(_forumPostDto(post, isLiked: liked, isFavorited: favorited));
      }
      return jsonResponse({'posts': result});
    });
  });

  router.post('/forum/posts', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final title = (body['title'] as String? ?? '').trim();
      final postBody = (body['body'] as String? ?? '').trim();
      final tag = (body['tag'] as String? ?? 'General').trim();
      final status = ForumPolicy.autoModeratePost(title, postBody);
      if (status == ContentStatus.rejected) {
        return jsonResponse({
          'error': 'title and body are required, title ≤ 200 chars, body ≤ 5000 chars',
        }, status: 400);
      }
      final post = await database.insertForumPost({
        'authorId': uid,
        'title': title,
        'body': postBody,
        'tag': tag,
        'status': status.name,
      });
      return jsonResponse(
        {'post': _forumPostDto(post, isLiked: false, isFavorited: false)},
        status: 201,
      );
    });
  });

  router.get('/forum/posts/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final post = await database.getForumPost(id);
      if (post == null) {
        return jsonResponse({'error': 'post not found'}, status: 404);
      }
      final comments = await database.listForumComments(id);
      final liked = await database.hasLiked(uid, id);
      final favorited = await database.hasFavorited(uid, id);
      return jsonResponse({
        'post': _forumPostDto(post, isLiked: liked, isFavorited: favorited),
        'comments': comments.map(_forumCommentDto).toList(),
      });
    });
  });

  router.post(
    '/forum/posts/<id>/comments',
    (Request request, String id) async {
      return _protected(config, request, (uid) async {
        final post = await database.getForumPost(id);
        if (post == null) {
          return jsonResponse({'error': 'post not found'}, status: 404);
        }
        final body = await readJsonMap(request);
        final commentBody = (body['body'] as String? ?? '').trim();
        final status = ForumPolicy.autoModerateComment(commentBody);
        if (status == ContentStatus.rejected) {
          return jsonResponse({
            'error': 'body is required and must be under 5000 chars',
          }, status: 400);
        }
        final comment = await database.insertForumComment({
          'postId': id,
          'authorId': uid,
          'body': commentBody,
          'status': status.name,
        });
        return jsonResponse({'comment': comment}, status: 201);
      });
    },
  );

  router.post('/forum/posts/<id>/like', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final post = await database.getForumPost(id);
      if (post == null) {
        return jsonResponse({'error': 'post not found'}, status: 404);
      }
      final liked = await database.toggleLike(uid, id);
      return jsonResponse({'liked': liked});
    });
  });

  router.post(
    '/forum/posts/<id>/favorite',
    (Request request, String id) async {
      return _protected(config, request, (uid) async {
        final post = await database.getForumPost(id);
        if (post == null) {
          return jsonResponse({'error': 'post not found'}, status: 404);
        }
        final favorited = await database.toggleFavorite(uid, id);
        return jsonResponse({'favorited': favorited});
      });
    },
  );

  router.post('/reports', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final contentType = body['contentType'] as String? ?? '';
      final contentId = body['contentId'] as String? ?? '';
      final reason = body['reason'] as String? ?? '';
      final detail = body['detail'] as String?;
      if (contentType.isEmpty || contentId.isEmpty) {
        return jsonResponse(
          {'error': 'contentType and contentId are required'},
          status: 400,
        );
      }
      if (!ModerationPolicy.isValidReport(reason, detail)) {
        return jsonResponse({'error': 'invalid reason'}, status: 400);
      }
      final report = await database.insertContentReport({
        'reporterUserId': uid,
        'contentType': contentType,
        'contentId': contentId,
        'reason': reason,
        'detail': detail,
      });
      return jsonResponse(report, status: 201);
    });
  });

  router.post('/ai/chat', (Request request) async {
    return _protected(
      config,
      request,
      (uid) => _handleAiRequest(request, 'chat', uid),
    );
  });

  router.post('/ai/sentence-analysis', (Request request) async {
    return _protected(
      config,
      request,
      (uid) => _handleAiRequest(request, 'sentence_analysis', uid),
    );
  });

  router.post('/ai/cloze', (Request request) async {
    return _protected(
      config,
      request,
      (uid) => _handleAiRequest(request, 'cloze', uid),
    );
  });

  router.get('/ai/history', (Request request) async {
    return _protected(config, request, (uid) async {
      final history = await database.listAiHistory(uid);
      return jsonResponse({
        'history': history.map((h) {
          return {
            'id': h['id'],
            'featureType': h['featureType'],
            'prompt': h['prompt'],
            'response': h['response'],
            'createdAt': h['createdAt'],
          };
        }).toList(),
      });
    });
  });

  router.delete('/ai/history/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final deleted = await database.softDeleteAiHistory(uid, id);
      if (!deleted) {
        return jsonResponse({'error': 'not found'}, status: 404);
      }
      return jsonResponse({'deleted': true});
    });
  });

  router.post('/ai/writing-review', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final prompt = body['prompt'] as String? ?? '';
      final examType = body['examType'] as String?;
      final targetScore = body['targetScore'];
      final targetLanguage = body['targetLanguage'] as String? ?? 'zh';
      if (prompt.isEmpty) {
        return jsonResponse({'error': 'prompt is required'}, status: 400);
      }
      final aiPrompt = buildWritingReviewPrompt(
        prompt,
        examType: examType,
        targetScore: targetScore,
      );
      final aiRequest = AiRequest(
        featureType: 'writing_review',
        userId: uid,
        prompt: aiPrompt,
        targetLanguage: targetLanguage,
      );
      final response = await effectiveAiPolicy.handle(aiRequest);
      if (!response.success) {
        final code = response.errorCode ?? 'ai_error';
        final status = switch (code) {
          'too_long' || 'blocked' => 400,
          'rate_limited' => 429,
          'ai_unavailable' => 503,
          _ => 422,
        };
        return jsonResponse({'error': code}, status: status);
      }
      final record = await database.insertAiHistory(
        uid,
        'writing_review',
        prompt,
        response.data,
      );
      return jsonResponse({
        'historyId': record['id'],
        'featureType': 'writing_review',
        'data': response.data,
        'createdAt': record['createdAt'],
      });
    });
  });

  router.get('/study-spots', (Request request) async {
    return _protected(config, request, (uid) async {
      final spots = await database.listStudySpots(uid);
      return jsonResponse({'spots': spots});
    });
  });

  router.post('/study-spots', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      if (body['latitude'] == null || body['longitude'] == null) {
        return jsonResponse({'error': 'invalid_coordinates'}, status: 400);
      }
      final name = (body['name'] as String? ?? '').trim();
      final lat = (body['latitude'] as num?)?.toDouble() ?? 0;
      final lng = (body['longitude'] as num?)?.toDouble() ?? 0;
      final minutes = (body['studyMinutes'] as num?)?.toInt() ?? 0;
      final err = StudySpotPolicy.validate(name: name, latitude: lat, longitude: lng);
      if (err != null) return jsonResponse({'error': err}, status: 400);
      final spot = await database.insertStudySpot(
        uid, name: name, latitude: lat, longitude: lng, studyMinutes: minutes);
      return jsonResponse(spot, status: 201);
    });
  });

  router.delete('/study-spots/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final ok = await database.deleteStudySpot(uid, id);
      if (!ok) return jsonResponse({'error': 'not found'}, status: 404);
      return jsonResponse({'deleted': true});
    });
  });

  return router;
}

Map<String, dynamic> _forumPostDto(
  Map<String, dynamic> row, {
  required bool isLiked,
  required bool isFavorited,
}) {
  return {
    'id': row['id'].toString(),
    'authorId': row['author_id'],
    'title': row['title'],
    'body': row['body'],
    'tag': row['tag'],
    'status': row['status'],
    'likeCount': row['like_count'],
    'commentCount': row['comment_count'],
    'isLiked': isLiked,
    'isFavorited': isFavorited,
    'createdAt': _isoString(row['created_at']),
    'updatedAt': _isoString(row['updated_at']),
  };
}

Map<String, dynamic> _forumCommentDto(Map<String, dynamic> row) {
  return {
    'id': row['id'].toString(),
    'postId': row['post_id'].toString(),
    'authorId': row['author_id'],
    'body': row['body'],
    'status': row['status'],
    'createdAt': _isoString(row['created_at']),
  };
}

String _isoString(Object? value) {
  if (value == null) return '';
  if (value is DateTime) return value.toIso8601String();
  return value.toString();
}

Future<Map<String, dynamic>> learningProgressDto(
  AppDatabase database,
  String uid,
  NotificationDayWindow dayWindow,
) async {
  final results = await Future.wait([
    database.completedLessonIds(uid),
    database.lessonIdsInRange(uid, dayWindow.startUtc, dayWindow.endUtc),
    database.reviewWordIdsInRange(uid, dayWindow.startUtc, dayWindow.endUtc),
    database.rewardIdsForDate(uid, dayWindow.dateKey),
  ]);
  return {
    'localDate': dayWindow.dateKey,
    'completedLessonIds': results[0],
    'todayCompletedLessonIds': results[1],
    'todayReviewWordIds': results[2],
    'todayClaimedRewardIds': results[3],
  };
}

Middleware corsMiddleware() {
  const headers = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
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

List<Map<String, dynamic>> userWordBatchItems(List rawWords) {
  return rawWords
      .whereType<Map>()
      .map((item) {
        final body = Map<String, dynamic>.from(item);
        return {
          ...body,
          'id': bodyString(body, 'id'),
          'wordId': bodyString(body, 'wordId'),
        };
      })
      .where((item) => item['id'].isNotEmpty && item['wordId'].isNotEmpty)
      .toList();
}

Future<List<Map<String, dynamic>>> _loadWordBooks() async {
  final cached = _cachedWordBooks;
  if (cached != null) return cached;
  final loading = _loadingWordBooks;
  if (loading != null) return loading;

  final future = _readWordBooks();
  _loadingWordBooks = future;
  try {
    final books = await future;
    _cachedWordBooks = books;
    return books;
  } catch (_) {
    _loadingWordBooks = null;
    rethrow;
  }
}

List<Map<String, dynamic>>? _cachedWordBooks;
Future<List<Map<String, dynamic>>>? _loadingWordBooks;

Future<List<Map<String, dynamic>>> _readWordBooks() async {
  final file = _wordBookDataFile();
  final decoded = jsonDecode(await file.readAsString());
  if (decoded is! List) {
    throw const FormatException('wordbooks_p0.json must be a list');
  }
  return decoded.whereType<Map>().map((item) {
    return Map<String, dynamic>.from(item);
  }).toList();
}

File _wordBookDataFile() {
  final serverRelative = File('data/wordbooks_p0.json');
  if (serverRelative.existsSync()) return serverRelative;
  final repoRelative = File('server/data/wordbooks_p0.json');
  if (repoRelative.existsSync()) return repoRelative;
  return serverRelative;
}

Map<String, dynamic>? _wordBookById(
  List<Map<String, dynamic>> books,
  String id,
) {
  for (final book in books) {
    if (book['id'] == id) return book;
  }
  return null;
}

List<Map<String, dynamic>> _wordsFromBooks(List<Map<String, dynamic>> books) {
  final words = <Map<String, dynamic>>[];
  for (final book in books) {
    final bookId = book['id']?.toString() ?? '';
    final items = book['words'];
    if (items is! List) continue;
    for (final item in items.whereType<Map>()) {
      words.add({...Map<String, dynamic>.from(item), 'wordBookId': bookId});
    }
  }
  return words;
}

Map<String, dynamic>? _wordById(List<Map<String, dynamic>> books, String id) {
  for (final word in _wordsFromBooks(books)) {
    if (word['id'] == id) return word;
  }
  return null;
}

bool _wordMatchesQuery(Map<String, dynamic> word, String query) {
  return _containsQuery(word['word'], query) ||
      _containsQuery(word['partOfSpeech'], query) ||
      _containsQuery(word['rootAffix'], query) ||
      _listContainsQuery(word['definitions'], query) ||
      _listContainsQuery(word['englishDefinitions'], query) ||
      _listContainsQuery(word['synonyms'], query) ||
      _listContainsQuery(word['antonyms'], query) ||
      _listContainsQuery(word['derivatives'], query) ||
      _listContainsQuery(word['examTags'], query) ||
      _examplesContainQuery(word['exampleSentences'], query) ||
      _phrasesContainQuery(word['collocations'], query);
}

bool _containsQuery(Object? value, String query) {
  return value?.toString().toLowerCase().contains(query) ?? false;
}

bool _listContainsQuery(Object? value, String query) {
  if (value is! List) return false;
  return value.any((item) => _containsQuery(item, query));
}

bool _examplesContainQuery(Object? value, String query) {
  if (value is! List) return false;
  return value.whereType<Map>().any((item) {
    return _containsQuery(item['en'], query) ||
        _containsQuery(item['cn'], query);
  });
}

bool _phrasesContainQuery(Object? value, String query) {
  if (value is! List) return false;
  return value.whereType<Map>().any((item) {
    return _containsQuery(item['phrase'] ?? item['en'], query) ||
        _containsQuery(item['cn'], query);
  });
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
    'emailVerified': row['email_verified'] ?? true,
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
    'lastReviewedAt': nullableDateValue(
      row['last_reviewed_at'] ?? row['lastReviewedAt'],
    ),
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
    'lastReviewedAt': nullableDateValue(
      row['last_reviewed_at'] ?? row['lastReviewedAt'],
    ),
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
    'params': _notificationParams(row['params']),
    'readAt': (row['read_at'] as DateTime?)?.toIso8601String(),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
  };
}

Map<String, dynamic> _notificationParams(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.trim().isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return const <String, dynamic>{};
    }
  }
  return const <String, dynamic>{};
}

Map<String, dynamic> prizeDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'name': row['name'],
    'category': row['category'],
    'rarity': row['rarity'],
    'description': row['description'],
    'probability': row['probability'],
    'fragmentValue': row['fragment_value'] ?? row['fragmentValue'] ?? 0,
    'isActive': row['is_active'] ?? row['isActive'] ?? true,
  };
}

Map<String, dynamic> assetDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'uid': row['uid'],
    'prizeId': row['prize_id'] ?? row['prizeId'],
    'category': row['category'],
    'rarity': row['rarity'],
    'name': row['name'],
    'description': row['description'],
    'quantity': row['quantity'] ?? 1,
    'fragmentValue': row['fragment_value'] ?? row['fragmentValue'] ?? 0,
    'acquiredAt': _dateValue(row['acquired_at'] ?? row['acquiredAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
  };
}

Map<String, dynamic> studyPlanDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'uid': row['uid'],
    'userId': row['uid'],
    'wordBookId': row['word_book_id'] ?? row['wordBookId'],
    'dailyNewTarget': row['daily_new_target'] ?? row['dailyNewTarget'],
    'dailyReviewLimit': row['daily_review_limit'] ?? row['dailyReviewLimit'],
    'startDate': _dateValue(row['start_date'] ?? row['startDate']),
    'targetFinishDate': _dateValue(
      row['target_finish_date'] ?? row['targetFinishDate'],
    ),
    'reminderTime': row['reminder_time'] ?? row['reminderTime'],
    'status': row['status'],
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
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
  final studyPlan = await database.studyPlanByUid(uid);
  final planPaused = studyPlan?['status'] == 'paused';
  final reviewLimit = _intValue(studyPlan?['daily_review_limit']) ?? 9999;
  final dueReviewCount = planPaused
      ? 0
      : math.min(await database.dueReviewCount(uid), reviewLimit);
  final hasCheckedIn = await database.hasCheckIn(uid, dayWindow.dateKey);
  final dailyGoal = studyPlan?['daily_new_target'] ?? user['daily_goal'] ?? 10;
  final generated = generatedNotificationsForToday(
    dateKey: dayWindow.dateKey,
    dailyGoal: dailyGoal is int ? dailyGoal : int.tryParse('$dailyGoal') ?? 10,
    hasStudyToday: planPaused || hasStudyToday,
    dueReviewCount: dueReviewCount,
    hasCheckedIn: planPaused || hasCheckedIn,
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
        'params': notification['params'],
        'createdAt': now,
      },
  ]);
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

String? _validateExerciseRecord(Map<String, dynamic> record) {
  for (final field in ['id', 'sessionId', 'gameId', 'wordId', 'promptType']) {
    final value = record[field];
    if (value is! String || value.trim().isEmpty) return '$field is required';
  }
  if (record['isCorrect'] is! bool) return 'isCorrect must be a boolean';
  final answerTimeMs = record['answerTimeMs'];
  if (answerTimeMs is! int || answerTimeMs < 0) {
    return 'answerTimeMs must be a non-negative integer';
  }
  final createdAt = record['createdAt'];
  if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
    return 'createdAt must be an ISO timestamp';
  }
  return null;
}

NotificationDayWindow? _dayWindowFromQuery(Request request) {
  final localDate = request.url.queryParameters['localDate'];
  if (localDate != null && !isNotificationDateKey(localDate)) return null;
  final offsetParam = request.url.queryParameters['timezoneOffsetMinutes'];
  final timezoneOffsetMinutes = offsetParam == null
      ? 0
      : parseNotificationTimezoneOffsetMinutes(offsetParam);
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
  final offsetValue = body['timezoneOffsetMinutes'];
  final timezoneOffsetMinutes = offsetValue == null
      ? 0
      : parseNotificationTimezoneOffsetMinutes(offsetValue.toString());
  if (timezoneOffsetMinutes == null) return null;
  return notificationDayWindow(
    nowUtc: DateTime.now().toUtc(),
    localDate: localDate,
    timezoneOffsetMinutes: timezoneOffsetMinutes,
  );
}

DateTime? _dateTimeValue(Object? value) {
  if (value is DateTime) return value.toUtc();
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toUtc();
}

String _targetExamForWordBook(String wordBookId) {
  switch (wordBookId) {
    case 'hsk1':
      return 'HSK 1';
    case 'hsk2':
      return 'HSK 2';
    case 'hsk3':
      return 'HSK 3';
    case 'hsk4':
      return 'HSK 4';
    case 'hsk5':
      return 'HSK 5';
    case 'hsk6':
      return 'HSK 6';
    // Legacy pre-HSK targets, retained for safety. Study-plan validation now
    // normalizes these wordbook ids to hsk1 before this is reached.
    case 'toefl':
      return 'TOEFL';
    case 'gre':
      return 'GRE';
    case 'ielts':
    case 'exam-core':
      return 'IELTS';
    case 'beginner':
    case 'daily-english':
      return 'Daily English';
  }
  return 'HSK 1';
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

int? _intValue(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

String? nullableDateValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  return value.toString();
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

bool isValidEmail(String email) => _emailPattern.hasMatch(email.trim());

String generateOtpCode() {
  final rng = math.Random.secure();
  return (rng.nextInt(900000) + 100000).toString();
}

Future<void> _issueAndSendCode(
  AppConfig config,
  AppDatabase database,
  EmailSender mailer, {
  required String uid,
  required String email,
}) async {
  final code = generateOtpCode();
  final salt = newSalt();
  final now = DateTime.now().toUtc();
  await database.upsertVerificationCode(
    uid,
    codeHash: hashPassword(code, salt),
    codeSalt: salt,
    expiresAt: now.add(const Duration(minutes: 10)),
    sentAt: now,
  );
  await mailer.sendVerificationCode(to: email, code: code);
}
