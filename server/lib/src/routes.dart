import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'ai_service.dart';
import 'auth.dart';
import 'config.dart';
import 'database.dart';
import 'json_response.dart';

Router buildRouter(AppConfig config, AppDatabase database) {
  final router = Router();
  final aiService = AiService.fromEnvironment();

  router.get('/health', (Request request) {
    return jsonResponse({'status': 'ok'});
  });

  router.get('/word-books', (Request request) async {
    final file = File('data/wordbooks_p0.json');
    if (!await file.exists()) {
      return jsonResponse({
        'error': 'word book seed data not found',
      }, status: 500);
    }
    final data = jsonDecode(await file.readAsString()) as List<dynamic>;
    return jsonResponse(data);
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
      return jsonResponse({
        'recorded': true,
        'user': userDto((await database.userById(uid))!),
      }, status: 201);
    });
  });

  router.get('/review/due', (Request request) async {
    return _protected(config, request, (uid) async {
      final words = await database.customWords(uid, dueOnly: true);
      return jsonResponse(words.map(wordDto).toList());
    });
  });

  router.get('/user-words', (Request request) async {
    return _protected(config, request, (uid) async {
      final words = await database.userWords(uid);
      return jsonResponse(words.map(userWordDto).toList());
    });
  });

  router.put('/user-words/<wordId>', (Request request, String wordId) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final word = await database.upsertUserWord(uid, {
        ...body,
        'wordId': wordId,
      });
      return jsonResponse({'word': userWordDto(word)});
    });
  });

  router.get('/study-plan', (Request request) async {
    return _protected(config, request, (uid) async {
      final plan = await database.studyPlan(uid);
      return jsonResponse({'plan': plan == null ? null : studyPlanDto(plan)});
    });
  });

  router.put('/study-plan', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      if ((body['wordBookId'] as String? ?? '').trim().isEmpty) {
        return jsonResponse({'error': 'wordBookId is required'}, status: 400);
      }
      final plan = await database.upsertStudyPlan(uid, body);
      return jsonResponse({'plan': studyPlanDto(plan)});
    });
  });

  router.delete('/study-plan', (Request request) async {
    return _protected(config, request, (uid) async {
      await database.deleteStudyPlan(uid);
      return jsonResponse({'deleted': true});
    });
  });

  router.get('/activity/summary', (Request request) async {
    return _protected(config, request, (uid) async {
      return jsonResponse(await database.activitySummary(uid));
    });
  });

  router.get('/classes', (Request request) async {
    return _protected(config, request, (uid) async {
      final classes = await database.classesForUser(uid);
      return jsonResponse({'classes': classes.map(classDto).toList()});
    });
  });

  router.post('/classes/join', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final code = (body['code'] as String? ?? '').trim().toUpperCase();
      if (code.isEmpty) {
        return jsonResponse({'error': 'class code is required'}, status: 400);
      }
      final classroom = await database.joinClass(
        uid: uid,
        classId: newId(),
        code: code,
      );
      await database.insertNotification(
        id: newId(),
        uid: uid,
        type: 'study',
        title: '已加入班级',
        body: '你已加入 ${classroom['name']}，可以查看班级进度。',
        targetRoute: '/class-progress',
      );
      return jsonResponse({'class': classDto(classroom)}, status: 201);
    });
  });

  router.get('/classes/progress', (Request request) async {
    return _protected(config, request, (uid) async {
      final classId = request.url.queryParameters['classId'];
      final progress = await database.classProgress(uid, classId: classId);
      if (progress == null) {
        return jsonResponse({'error': 'class not found'}, status: 404);
      }
      return jsonResponse({'progress': classProgressDto(progress)});
    });
  });

  router.get('/rewards/tasks', (Request request) async {
    return _protected(config, request, (uid) async {
      final counts = await database.todayActivityCounts(uid);
      final claims = await database.rewardClaimsForDate(uid, DateTime.now());
      return jsonResponse({'tasks': rewardTaskDtos(counts, claims)});
    });
  });

  router.post('/rewards/claim', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final taskId = body['taskId'] as String? ?? '';
      final counts = await database.todayActivityCounts(uid);
      final claims = await database.rewardClaimsForDate(uid, DateTime.now());
      final tasks = rewardTaskDtos(counts, claims);
      final task = _firstById(tasks, taskId);
      if (task == null) {
        return jsonResponse({'error': 'reward task not found'}, status: 404);
      }
      if (task['claimed'] == true) {
        return jsonResponse({'error': 'reward already claimed'}, status: 409);
      }
      if (task['available'] != true) {
        return jsonResponse({
          'error': 'reward task is not available',
        }, status: 400);
      }
      final claim = await database.insertRewardClaim(
        uid: uid,
        taskId: taskId,
        points: task['points'] as int,
        claimDate: DateTime.now(),
      );
      return jsonResponse({
        'claim': rewardClaimDto(claim),
        'tasks': rewardTaskDtos(
          await database.todayActivityCounts(uid),
          await database.rewardClaimsForDate(uid, DateTime.now()),
        ),
        'user': userDto((await database.userById(uid))!),
      }, status: 201);
    });
  });

  router.post('/rewards/lottery', (Request request) async {
    return _protected(config, request, (uid) async {
      const cost = 20;
      final prize = _lotteryPrize();
      try {
        final draw = await database.insertLotteryDraw(
          id: newId(),
          uid: uid,
          prize: prize,
          pointsCost: cost,
        );
        await database.insertNotification(
          id: newId(),
          uid: uid,
          type: 'reward',
          title: '抽奖结果',
          body: '你抽中了 $prize。',
          targetRoute: '/discover',
        );
        return jsonResponse({
          'draw': lotteryDrawDto(draw),
          'user': userDto((await database.userById(uid))!),
        }, status: 201);
      } on StateError catch (error) {
        return jsonResponse({'error': error.message}, status: 400);
      }
    });
  });

  router.get('/notifications', (Request request) async {
    return _protected(config, request, (uid) async {
      final items = await database.notifications(uid);
      return jsonResponse({
        'notifications': items.map(notificationDto).toList(),
      });
    });
  });

  router.patch('/notifications/<id>/read', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      await database.markNotificationRead(uid, id);
      return jsonResponse({'updated': true});
    });
  });

  router.get('/forum/posts', (Request request) async {
    final posts = await database.forumPosts();
    return jsonResponse({'posts': posts.map(forumPostDto).toList()});
  });

  router.post('/forum/posts', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final title = (body['title'] as String? ?? '').trim();
      final content = (body['content'] as String? ?? '').trim();
      if (title.isEmpty || content.isEmpty) {
        return jsonResponse({
          'error': 'title and content are required',
        }, status: 400);
      }
      final post = await database.insertForumPost(uid, {
        ...body,
        'id': body['id'] as String? ?? newId(),
        'title': title,
        'content': content,
      });
      return jsonResponse({'post': forumPostDto(post)}, status: 201);
    });
  });

  router.get('/forum/posts/<id>', (Request request, String id) async {
    final post = await database.forumPostById(id);
    if (post == null)
      return jsonResponse({'error': 'post not found'}, status: 404);
    final comments = await database.forumComments(id);
    return jsonResponse({
      'post': forumPostDto(post),
      'comments': comments.map(forumCommentDto).toList(),
    });
  });

  router.post('/forum/posts/<id>/comments', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final post = await database.forumPostById(id);
      if (post == null)
        return jsonResponse({'error': 'post not found'}, status: 404);
      final body = await readJsonMap(request);
      final content = (body['content'] as String? ?? '').trim();
      if (content.isEmpty) {
        return jsonResponse({'error': 'content is required'}, status: 400);
      }
      final comment = await database.insertForumComment(uid, id, {
        'id': body['id'] as String? ?? newId(),
        'content': content,
      });
      return jsonResponse({'comment': forumCommentDto(comment)}, status: 201);
    });
  });

  router.post('/forum/posts/<id>/like', (Request request, String id) async {
    await database.likeForumPost(id);
    final post = await database.forumPostById(id);
    if (post == null)
      return jsonResponse({'error': 'post not found'}, status: 404);
    return jsonResponse({'post': forumPostDto(post)});
  });

  router.get('/ai/conversations', (Request request) async {
    return _protected(config, request, (uid) async {
      final conversations = await database.aiConversations(uid);
      return jsonResponse({
        'conversations': conversations.map(aiConversationDto).toList(),
      });
    });
  });

  router.get('/ai/conversations/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final conversation = await database.aiConversationById(uid, id);
      if (conversation == null) {
        return jsonResponse({'error': 'conversation not found'}, status: 404);
      }
      final messages = await database.aiMessages(uid, id);
      return jsonResponse({
        'conversation': aiConversationDto(conversation),
        'messages': messages.map(aiMessageDto).toList(),
      });
    });
  });

  router.delete('/ai/conversations/<id>', (Request request, String id) async {
    return _protected(config, request, (uid) async {
      final deleted = await database.deleteAiConversation(uid, id);
      if (!deleted) {
        return jsonResponse({'error': 'conversation not found'}, status: 404);
      }
      return jsonResponse({'deleted': true});
    });
  });

  router.post('/ai/complete', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      final feature = (body['feature'] as String? ?? 'qa').trim();
      final prompt = (body['prompt'] as String? ?? '').trim();
      if (prompt.isEmpty) {
        return jsonResponse({'error': 'prompt is required'}, status: 400);
      }
      final generated = await aiService.complete(
        feature: feature,
        prompt: prompt,
      );
      final requestedConversationId = (body['conversationId'] as String?)
          ?.trim();
      final conversationId =
          requestedConversationId == null || requestedConversationId.isEmpty
          ? newId()
          : requestedConversationId;
      if (requestedConversationId != null &&
          requestedConversationId.isNotEmpty &&
          await database.aiConversationById(uid, conversationId) == null) {
        return jsonResponse({'error': 'conversation not found'}, status: 404);
      }
      final exchange = await database.insertAiExchange(
        uid: uid,
        conversationId: conversationId,
        feature: generated.feature,
        title: generated.title,
        userMessageId: newId(),
        assistantMessageId: newId(),
        prompt: prompt,
        response: generated.response,
        payload: generated.payload,
      );
      return jsonResponse({'result': aiResultDto(exchange)}, status: 201);
    });
  });

  router.get('/analytics/summary', (Request request) async {
    return _protected(config, request, (uid) async {
      final user = await database.userById(uid);
      final summary = await database.analyticsSummary(uid);
      return jsonResponse({'summary': analyticsDto(user!, summary)});
    });
  });

  router.get('/leaderboard', (Request request) async {
    final rows = await database.leaderboard();
    return jsonResponse({'leaderboard': rows.map(leaderboardDto).toList()});
  });

  router.get('/achievements', (Request request) async {
    return _protected(config, request, (uid) async {
      final user = await database.userById(uid);
      final summary = await database.analyticsSummary(uid);
      return jsonResponse({'achievements': achievementDtos(user!, summary)});
    });
  });

  router.post('/review-events', (Request request) async {
    return _protected(config, request, (uid) async {
      final body = await readJsonMap(request);
      await database.insertReviewEvent(uid, body);
      return jsonResponse({'recorded': true}, status: 201);
    });
  });

  return router;
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
    'avatarUrl': row['avatar_url'],
    'targetExam': row['target_exam'],
    'level': row['level'],
    'dailyGoal': row['daily_goal'],
    'dailyNewTarget': row['daily_new_target'] ?? 10,
    'dailyReviewLimit': row['daily_review_limit'] ?? 20,
    'currentWordBookId': row['current_word_book_id'] ?? 'beginner',
    'xp': row['xp'],
    'points': row['points'] ?? row['xp'] ?? 0,
    'streak': row['streak'],
    'totalStudyDays': row['total_study_days'] ?? 0,
    'totalStudyMinutes': row['total_study_minutes'] ?? 0,
    'lastStudyDate': (row['last_study_date'] as DateTime?)?.toIso8601String(),
    'createdAt': (row['created_at'] as DateTime).toIso8601String(),
    'updatedAt': (row['updated_at'] as DateTime).toIso8601String(),
  };
}

Map<String, dynamic> classDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'code': row['code'],
    'name': row['name'],
    'description': row['description'] ?? '',
    'teacherName': row['teacher_name'] ?? row['teacherName'] ?? 'LinguaQuest',
    'role': row['role'] ?? 'student',
    'memberCount': (row['member_count'] as num?)?.toInt() ?? 0,
    'joinedAt': _dateValue(row['joined_at'] ?? row['joinedAt']),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
  };
}

Map<String, dynamic> classProgressDto(Map<String, dynamic> data) {
  final classroom = data['classroom'] as Map<String, dynamic>;
  final members = (data['members'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final lessons = (data['lessons'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final weakWords = (data['weakWords'] as List<dynamic>)
      .cast<Map<String, dynamic>>();
  final totalQuestions = members.fold<int>(
    0,
    (sum, row) => sum + ((row['total_questions'] as num?)?.toInt() ?? 0),
  );
  final correctAnswers = members.fold<int>(
    0,
    (sum, row) => sum + ((row['correct_answers'] as num?)?.toInt() ?? 0),
  );
  return {
    'class': classDto(classroom),
    'memberCount': members.length,
    'totalQuestions': totalQuestions,
    'correctAnswers': correctAnswers,
    'accuracy': totalQuestions == 0 ? 0.0 : correctAnswers / totalQuestions,
    'members': members.map(classMemberProgressDto).toList(),
    'lessons': lessons.map(classLessonProgressDto).toList(),
    'weakWords': weakWords.map(classWeakWordDto).toList(),
  };
}

Map<String, dynamic> classMemberProgressDto(Map<String, dynamic> row) {
  final total = (row['total_questions'] as num?)?.toInt() ?? 0;
  final correct = (row['correct_answers'] as num?)?.toInt() ?? 0;
  return {
    'uid': row['id'],
    'name': row['name'],
    'avatarUrl': row['avatar_url'],
    'role': row['role'] ?? 'student',
    'points': (row['points'] as num?)?.toInt() ?? 0,
    'xp': (row['xp'] as num?)?.toInt() ?? 0,
    'streak': (row['streak'] as num?)?.toInt() ?? 0,
    'totalStudyDays': (row['total_study_days'] as num?)?.toInt() ?? 0,
    'totalStudyMinutes': (row['total_study_minutes'] as num?)?.toInt() ?? 0,
    'sessions': (row['sessions'] as num?)?.toInt() ?? 0,
    'totalQuestions': total,
    'correctAnswers': correct,
    'accuracy': total == 0 ? 0.0 : correct / total,
    'earnedPoints': (row['earned_points'] as num?)?.toInt() ?? 0,
    'joinedAt': _dateValue(row['joined_at']),
  };
}

Map<String, dynamic> classLessonProgressDto(Map<String, dynamic> row) {
  final total = (row['total_questions'] as num?)?.toInt() ?? 0;
  final correct = (row['correct_answers'] as num?)?.toInt() ?? 0;
  return {
    'lessonId': row['lesson_id'],
    'sessions': (row['sessions'] as num?)?.toInt() ?? 0,
    'totalQuestions': total,
    'correctAnswers': correct,
    'accuracy': total == 0 ? 0.0 : correct / total,
    'lastPracticedAt': _nullableDateValue(row['last_practiced_at']),
  };
}

Map<String, dynamic> classWeakWordDto(Map<String, dynamic> row) {
  return {
    'wordId': row['word_id'],
    'mistakeCount': (row['mistake_count'] as num?)?.toInt() ?? 0,
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

Map<String, dynamic> userWordDto(Map<String, dynamic> row) {
  return {
    'wordId': row['word_id'] ?? row['wordId'],
    'wordBookId': row['word_book_id'] ?? row['wordBookId'],
    'status': row['status'] ?? 'New',
    'isFavorite': row['is_favorite'] ?? row['isFavorite'] ?? false,
    'isInNewWordBook':
        row['is_in_new_word_book'] ?? row['isInNewWordBook'] ?? false,
    'easeFactor': row['ease_factor'] ?? row['easeFactor'] ?? 2.5,
    'intervalDays': row['interval_days'] ?? row['intervalDays'] ?? 0,
    'repetitionCount': row['repetition_count'] ?? row['repetitionCount'] ?? 0,
    'lapseCount': row['lapse_count'] ?? row['lapseCount'] ?? 0,
    'nextReviewAt': _dateValue(row['next_review_at'] ?? row['nextReviewAt']),
    'lastReviewedAt': _nullableDateValue(
      row['last_reviewed_at'] ?? row['lastReviewedAt'],
    ),
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
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
  };
}

Map<String, dynamic> studyPlanDto(Map<String, dynamic> row) {
  final wordBookId = row['word_book_id'] ?? row['wordBookId'];
  return {
    'target': _targetForWordBook(wordBookId?.toString()),
    'wordBookId': wordBookId,
    'dailyWords': row['daily_new_target'] ?? row['dailyNewTarget'] ?? 10,
    'dailyReviewLimit':
        row['daily_review_limit'] ?? row['dailyReviewLimit'] ?? 20,
    'deadline': _nullableDateValue(
      row['target_finish_date'] ?? row['targetFinishDate'],
    ),
    'targetFinishDate': _nullableDateValue(
      row['target_finish_date'] ?? row['targetFinishDate'],
    ),
    'reminderTime': row['reminder_time'] ?? row['reminderTime'],
    'status': row['status'] ?? 'active',
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
  };
}

List<Map<String, dynamic>> rewardTaskDtos(
  Map<String, int> counts,
  List<Map<String, dynamic>> claims,
) {
  final claimed = claims.map((row) => row['task_id'] as String).toSet();
  final definitions = [
    (
      id: 'daily-checkin',
      title: '每日签到',
      taskType: 'checkin',
      condition: '当天完成一次学习或复习动作',
      points: 5,
      available: ((counts['sessions'] ?? 0) + (counts['reviews'] ?? 0)) > 0,
    ),
    (
      id: 'complete-new',
      title: '完成新学',
      taskType: 'study',
      condition: '完成任意正式学习 Session',
      points: 12,
      available: (counts['sessions'] ?? 0) > 0,
    ),
    (
      id: 'complete-review',
      title: '完成复习',
      taskType: 'review',
      condition: '完成任意复习题',
      points: 10,
      available: (counts['reviews'] ?? 0) > 0,
    ),
    (
      id: 'training-challenge',
      title: '训练场挑战',
      taskType: 'training',
      condition: '完成任意训练场游戏',
      points: 10,
      available: (counts['training_sessions'] ?? 0) > 0,
    ),
    (
      id: 'mistake-cleanup',
      title: '错词清理',
      taskType: 'review',
      condition: '今日错词再次答对',
      points: 8,
      available: (counts['correct_reviews'] ?? 0) > 0,
    ),
    (
      id: 'forum-interaction',
      title: '论坛互动',
      taskType: 'community',
      condition: '发帖或评论通过审核',
      points: 3,
      available:
          ((counts['forum_posts'] ?? 0) + (counts['forum_comments'] ?? 0)) > 0,
    ),
  ];
  return [
    for (final item in definitions)
      {
        'id': item.id,
        'title': item.title,
        'taskType': item.taskType,
        'condition': item.condition,
        'points': item.points,
        'available': item.available,
        'claimed': claimed.contains(item.id),
        'claimedAt': _claimedAt(claims, item.id),
      },
  ];
}

Map<String, dynamic> rewardClaimDto(Map<String, dynamic> row) {
  return {
    'taskId': row['task_id'],
    'claimDate': _dateValue(row['claim_date']),
    'points': row['points'],
    'claimedAt': _dateValue(row['claimed_at']),
  };
}

Map<String, dynamic> lotteryDrawDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'prize': row['prize'],
    'pointsCost': row['pointsCost'] ?? row['points_cost'],
    'drawnAt': _dateValue(row['drawnAt'] ?? row['drawn_at']),
  };
}

Map<String, dynamic> notificationDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'type': row['type'],
    'title': row['title'],
    'body': row['body'],
    'targetRoute': row['target_route'] ?? row['targetRoute'],
    'isRead': row['is_read'] ?? row['isRead'] ?? false,
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
  };
}

Map<String, dynamic> forumPostDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'authorId': row['author_id'] ?? row['authorId'],
    'authorName': row['author_name'] ?? row['authorName'] ?? '学习者',
    'authorAvatarUrl': row['author_avatar_url'] ?? row['authorAvatarUrl'],
    'title': row['title'],
    'content': row['content'],
    'imageUrls': _splitLines(row['image_urls'] ?? row['imageUrls']),
    'tags': _splitCsv(row['tags']),
    'likeCount': row['like_count'] ?? row['likeCount'] ?? 0,
    'commentCount': row['comment_count'] ?? row['commentCount'] ?? 0,
    'status': row['status'] ?? 'published',
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
  };
}

Map<String, dynamic> forumCommentDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'postId': row['post_id'] ?? row['postId'],
    'authorId': row['author_id'] ?? row['authorId'],
    'authorName': row['author_name'] ?? row['authorName'] ?? '学习者',
    'authorAvatarUrl': row['author_avatar_url'] ?? row['authorAvatarUrl'],
    'content': row['content'],
    'status': row['status'] ?? 'published',
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
  };
}

Map<String, dynamic> aiConversationDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'feature': row['feature'],
    'title': row['title'],
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
    'updatedAt': _dateValue(row['updated_at'] ?? row['updatedAt']),
  };
}

Map<String, dynamic> aiMessageDto(Map<String, dynamic> row) {
  return {
    'id': row['id'],
    'conversationId': row['conversation_id'] ?? row['conversationId'],
    'role': row['role'],
    'content': row['content'],
    'payload': _jsonMap(row['payload']),
    'createdAt': _dateValue(row['created_at'] ?? row['createdAt']),
  };
}

Map<String, dynamic> aiResultDto(Map<String, dynamic> row) {
  return {
    'conversationId': row['conversationId'],
    'feature': row['feature'],
    'title': row['title'],
    'response': row['response'],
    'payload': row['payload'],
    'createdAt': _dateValue(row['createdAt']),
  };
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value == null) return const {};
  try {
    final decoded = jsonDecode(value.toString());
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return const {};
  }
  return const {};
}

Map<String, dynamic> analyticsDto(
  Map<String, dynamic> user,
  Map<String, dynamic> summary,
) {
  final total = (summary['total_questions'] as num?)?.toInt() ?? 0;
  final correct = (summary['correct_answers'] as num?)?.toInt() ?? 0;
  return {
    'sessions': (summary['sessions'] as num?)?.toInt() ?? 0,
    'totalQuestions': total,
    'correctAnswers': correct,
    'accuracy': total == 0 ? 0.0 : correct / total,
    'studyMinutes': (((summary['duration_seconds'] as num?)?.toInt() ?? 0) / 60)
        .ceil(),
    'earnedPoints': (summary['earned_points'] as num?)?.toInt() ?? 0,
    'weakWords': (summary['weak_words'] as num?)?.toInt() ?? 0,
    'forumPosts': (summary['forum_posts'] as num?)?.toInt() ?? 0,
    'streakDays': user['streak'] ?? 0,
    'totalStudyDays': user['total_study_days'] ?? 0,
    'totalStudyMinutes': user['total_study_minutes'] ?? 0,
    'points': user['points'] ?? 0,
    'xp': user['xp'] ?? 0,
  };
}

Map<String, dynamic> leaderboardDto(Map<String, dynamic> row) {
  return {
    'uid': row['id'],
    'name': row['name'],
    'avatarUrl': row['avatar_url'],
    'points': row['points'] ?? 0,
    'xp': row['xp'] ?? 0,
    'streak': row['streak'] ?? 0,
    'totalStudyDays': row['total_study_days'] ?? 0,
  };
}

List<Map<String, dynamic>> achievementDtos(
  Map<String, dynamic> user,
  Map<String, dynamic> summary,
) {
  final points = (user['points'] as int?) ?? 0;
  final studyDays = (user['total_study_days'] as int?) ?? 0;
  final sessions = (summary['sessions'] as num?)?.toInt() ?? 0;
  final forumPosts = (summary['forum_posts'] as num?)?.toInt() ?? 0;
  final achievements = [
    ('first-session', '启航学习者', '完成第 1 次学习 Session', sessions >= 1),
    ('seven-day', '七日旅人', '累计学习 7 天', studyDays >= 7),
    ('point-100', '积分新星', '累计获得 100 积分', points >= 100),
    ('community-voice', '社区发声', '发布第 1 篇帖子', forumPosts >= 1),
  ];
  return [
    for (final item in achievements)
      {
        'id': item.$1,
        'title': item.$2,
        'description': item.$3,
        'unlocked': item.$4,
      },
  ];
}

Map<String, dynamic>? _firstById(List<Map<String, dynamic>> rows, String id) {
  for (final row in rows) {
    if (row['id'] == id) return row;
  }
  return null;
}

String? _claimedAt(List<Map<String, dynamic>> claims, String taskId) {
  for (final claim in claims) {
    if (claim['task_id'] == taskId) return _dateValue(claim['claimed_at']);
  }
  return null;
}

String _lotteryPrize() {
  const prizes = ['星球头像框', '复习加油卡', '词根徽章', '训练场入场券', '今日高亮主题'];
  return prizes[DateTime.now().microsecond % prizes.length];
}

List<String> _splitLines(Object? value) {
  if (value == null) return const [];
  return value
      .toString()
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<String> _splitCsv(Object? value) {
  if (value == null) return const [];
  return value
      .toString()
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _targetForWordBook(String? wordBookId) {
  switch (wordBookId) {
    case 'ielts':
      return 'IELTS';
    case 'toefl':
      return 'TOEFL';
    case 'gre':
      return 'GRE';
    case 'gmat':
      return 'GMAT';
    case 'sat':
      return 'SAT';
    default:
      return 'Daily English';
  }
}

String _dateValue(Object? value) {
  if (value is DateTime) return value.toIso8601String();
  return value?.toString() ?? DateTime.now().toUtc().toIso8601String();
}

String? _nullableDateValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value.toIso8601String();
  return value.toString();
}
