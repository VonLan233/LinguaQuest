import 'dart:convert';

import 'package:linguaquest_server/src/auth.dart';
import 'package:linguaquest_server/src/config.dart';
import 'package:linguaquest_server/src/database.dart';
import 'package:linguaquest_server/src/routes.dart';
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

void main() {
  test('study plan reset route persists custom word progress reset', () async {
    const uid = 'route-reset-user';
    final originalReviewAt = DateTime.utc(2026, 6, 1, 8);
    final database = InMemoryAppDatabase();
    await database.insertUser(
      id: uid,
      email: 'route@lingua.quest',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      name: 'Route User',
    );
    await database.upsertStudyPlan(uid, {
      'id': 'plan-1',
      'wordBookId': 'ielts',
      'dailyNewTarget': 20,
      'dailyReviewLimit': 40,
      'startDate': '2026-05-01',
      'targetFinishDate': '2026-08-04',
      'reminderTime': '07:05',
      'status': 'paused',
      'createdAt': originalReviewAt,
      'now': originalReviewAt,
    });
    await database.upsertCustomWord(uid, {
      'id': 'word-1',
      'word': 'abstract',
      'meaning': '抽象的',
      'masteryLevel': 4,
      'correctCount': 7,
      'wrongCount': 2,
      'nextReviewAt': originalReviewAt,
      'createdAt': originalReviewAt,
    });

    const config = AppConfig(
      port: 0,
      firebaseProjectId: 'test-project',
      firebaseServiceAccountJsonBase64: 'unused',
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
    final resetWord = await database.customWordById(uid, 'word-1');

    expect(response.statusCode, 200);
    expect(studyPlan['status'], 'active');
    expect(studyPlan['id'], 'plan-1');
    expect(studyPlan['wordBookId'], 'ielts');
    expect(studyPlan['reminderTime'], '07:05');
    expect(resetWord?['mastery_level'], 0);
    expect(resetWord?['correct_count'], 0);
    expect(resetWord?['wrong_count'], 0);
    expect(resetWord?['next_review_at'], resetAt);
    expect(resetWord?['updated_at'], resetAt);
  });

  test('study plan reset route returns 404 when no plan exists', () async {
    const uid = 'missing-plan-user';
    final database = InMemoryAppDatabase();
    await database.insertUser(
      id: uid,
      email: 'missing@lingua.quest',
      passwordHash: 'hash',
      passwordSalt: 'salt',
      name: 'Missing User',
    );
    const config = AppConfig(
      port: 0,
      firebaseProjectId: 'test-project',
      firebaseServiceAccountJsonBase64: 'unused',
      jwtSecret: 'test-secret',
    );
    final token = issueToken(config, uid: uid, email: 'missing@lingua.quest');
    final router = buildRouter(config, database);
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
