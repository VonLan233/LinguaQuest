import 'dart:convert';

import 'package:linguaquest_server/src/auth.dart';
import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/database.dart';
import 'package:linguaquest_server/src/routes.dart';
import 'package:postgres/postgres.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('study plan reset route persists custom word progress reset', () async {
    const uid = 'route-reset-user';
    final originalReviewAt = DateTime.utc(2026, 6, 1, 8);
    final database = _RouteTestDatabase()
      ..existingStudyPlan = {
        'id': 'plan-1',
        'uid': uid,
        'word_book_id': 'hsk1',
        'daily_new_target': 20,
        'daily_review_limit': 40,
        'start_date': DateTime.utc(2026, 5, 1),
        'target_finish_date': DateTime.utc(2026, 8, 4),
        'reminder_time': '7:05',
        'status': 'paused',
        'created_at': originalReviewAt,
        'updated_at': originalReviewAt,
      }
      ..customWordRows.addAll([
        {
          'id': 'word-1',
          'uid': uid,
          'mastery_level': 4,
          'correct_count': 7,
          'wrong_count': 2,
          'next_review_at': originalReviewAt,
          'updated_at': originalReviewAt,
        },
        {
          'id': 'word-2',
          'uid': uid,
          'mastery_level': 3,
          'correct_count': 5,
          'wrong_count': 1,
          'next_review_at': originalReviewAt,
          'updated_at': originalReviewAt,
        },
        {
          'id': 'other-user-word',
          'uid': 'other-user',
          'mastery_level': 5,
          'correct_count': 9,
          'wrong_count': 0,
          'next_review_at': originalReviewAt,
          'updated_at': originalReviewAt,
        },
      ]);
    const config = AppConfig(
      port: 0,
      databaseUrl: 'postgresql://unused',
      jwtSecret: 'test-secret',
    );
    final token = issueToken(config, uid: uid, email: 'route@lingua.quest');
    final router = buildRouter(config, database);
    final request = Request(
      'POST',
      Uri.parse('http://localhost/study-plan/reset'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: '',
    );

    final response = await router(request);
    final responseBody = jsonDecode(await response.readAsString());
    final studyPlan = responseBody['studyPlan'] as Map<String, dynamic>;
    final resetAt = DateTime.parse(studyPlan['updatedAt'] as String).toUtc();

    expect(response.statusCode, 200);
    expect(studyPlan['status'], 'active');
    expect(studyPlan['id'], 'plan-1');
    expect(studyPlan['wordBookId'], 'hsk1');
    expect(database.upsertedPayload?['id'], 'plan-1');
    expect(database.upsertedPayload?['reminderTime'], '07:05');
    expect(database.resetCalledWithUid, uid);
    expect(database.resetCalledWithTimestamp, resetAt);
    for (final row in database.customWordRows.where(
      (row) => row['uid'] == uid,
    )) {
      expect(row['mastery_level'], 0);
      expect(row['correct_count'], 0);
      expect(row['wrong_count'], 0);
      expect(row['next_review_at'], resetAt);
      expect(row['updated_at'], resetAt);
    }
    final otherUserWord = database.customWordRows.singleWhere(
      (row) => row['uid'] == 'other-user',
    );
    expect(otherUserWord['mastery_level'], 5);
    expect(otherUserWord['next_review_at'], originalReviewAt);
  });

  test('study plan reset route returns 404 when no plan exists', () async {
    const uid = 'missing-plan-user';
    const config = AppConfig(
      port: 0,
      databaseUrl: 'postgresql://unused',
      jwtSecret: 'test-secret',
    );
    final token = issueToken(config, uid: uid, email: 'missing@lingua.quest');
    final router = buildRouter(config, _RouteTestDatabase());
    final request = Request(
      'POST',
      Uri.parse('http://localhost/study-plan/reset'),
      headers: {'Authorization': 'Bearer $token'},
      body: '',
    );

    final response = await router(request);
    final body = jsonDecode(await response.readAsString());

    expect(response.statusCode, 404);
    expect(body['error'], 'study plan not found');
  });
}

class _RouteTestDatabase extends AppDatabase {
  _RouteTestDatabase() : super(_UnusedConnection());

  final List<Map<String, dynamic>> customWordRows = [];
  Map<String, dynamic>? existingStudyPlan;
  Map<String, dynamic>? upsertedPayload;
  String? resetCalledWithUid;
  DateTime? resetCalledWithTimestamp;

  @override
  Future<Map<String, dynamic>?> studyPlanByUid(String uid) async {
    final plan = existingStudyPlan;
    if (plan == null || plan['uid'] != uid) return null;
    return plan;
  }

  @override
  Future<Map<String, dynamic>> upsertStudyPlan(
    String uid,
    Map<String, dynamic> data,
  ) async {
    upsertedPayload = Map<String, dynamic>.from(data);
    final rawNow = data['now'];
    final updatedAt = rawNow is DateTime
        ? rawNow.toUtc()
        : DateTime.now().toUtc();
    return {
      'id': data['id'],
      'uid': uid,
      'word_book_id': data['wordBookId'],
      'daily_new_target': data['dailyNewTarget'],
      'daily_review_limit': data['dailyReviewLimit'],
      'start_date': data['startDate'],
      'target_finish_date': data['targetFinishDate'],
      'reminder_time': data['reminderTime'],
      'status': data['status'],
      'created_at': updatedAt,
      'updated_at': updatedAt,
    };
  }

  @override
  Future<void> resetCustomWordProgress(String uid, {DateTime? now}) async {
    final resetAt = now ?? DateTime.now().toUtc();
    resetCalledWithUid = uid;
    resetCalledWithTimestamp = resetAt;
    for (final row in customWordRows.where((row) => row['uid'] == uid)) {
      row['mastery_level'] = 0;
      row['correct_count'] = 0;
      row['wrong_count'] = 0;
      row['next_review_at'] = resetAt;
      row['updated_at'] = resetAt;
    }
  }
}

class _UnusedConnection implements Connection {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
