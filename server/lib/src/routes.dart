import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth.dart';
import 'config.dart';
import 'database.dart';
import 'json_response.dart';

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

  router.post('/exercise-records', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final rawRecords = body['records'];
      if (rawRecords is! List) {
        return jsonResponse({'error': 'records must be a list'}, status: 400);
      }
      if (rawRecords.length > 100) {
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
    'status': row['status'] ?? 'Learning',
    'easeFactor': row['ease_factor'] ?? row['easeFactor'] ?? 2.5,
    'intervalDays': row['interval_days'] ?? row['intervalDays'] ?? 0,
    'repetitionCount': row['repetition_count'] ?? row['repetitionCount'] ?? 0,
    'lapseCount': row['lapse_count'] ?? row['lapseCount'] ?? 0,
    'masteryLevel': row['mastery_level'] ?? row['masteryLevel'] ?? 0,
    'correctCount': row['correct_count'] ?? row['correctCount'] ?? 0,
    'wrongCount': row['wrong_count'] ?? row['wrongCount'] ?? 0,
    'meaningRecognitionScore':
        row['meaning_recognition_score'] ??
        row['meaningRecognitionScore'] ??
        20,
    'meaningRecallScore':
        row['meaning_recall_score'] ?? row['meaningRecallScore'] ?? 10,
    'spellingScore': row['spelling_score'] ?? row['spellingScore'] ?? 10,
    'listeningScore': row['listening_score'] ?? row['listeningScore'] ?? 10,
    'contextScore': row['context_score'] ?? row['contextScore'] ?? 10,
    'confidenceScore': row['confidence_score'] ?? row['confidenceScore'] ?? 10,
    'nextReviewAt': _dateValue(row['next_review_at'] ?? row['nextReviewAt']),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
  };
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
