import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'config.dart';
import 'database.dart';
import 'json_response.dart';
import 'lesson_catalog.dart';
import 'notification_policy.dart';
import 'study_plan_policy.dart';

Router buildRouter(AppConfig config, AppDatabase database) {
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
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      if (response.statusCode != 200) {
        return jsonResponse({'error': 'tts unavailable'}, status: 502);
      }
      final bytes = response.bodyBytes;
      if (bytes.length > 5 * 1024 * 1024) {
        return jsonResponse({'error': 'tts response too large'}, status: 502);
      }
      return Response.ok(bytes, headers: {
        'Content-Type': 'audio/mpeg',
        'Cache-Control': 'public, max-age=86400',
      });
    } catch (_) {
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

  return router;
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
    'readAt': (row['read_at'] as DateTime?)?.toIso8601String(),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
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
  final lastStudyDate = user['last_study_date'];
  final hasCheckedIn =
      lastStudyDate is DateTime &&
      !lastStudyDate.toUtc().isBefore(dayWindow.startUtc) &&
      lastStudyDate.toUtc().isBefore(dayWindow.endUtc);
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
        'createdAt': now,
      },
  ]);
}

String _dateValue(Object? value) {
  if (value is DateTime) return value.toIso8601String();
  return value?.toString() ?? DateTime.now().toUtc().toIso8601String();
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
  return 'Daily English';
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
