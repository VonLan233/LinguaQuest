import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/data/models/app_notification.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('app notification JSON roundtrips and marks read', () {
    final createdAt = DateTime.utc(2026, 6, 2, 9, 30);
    final notification = AppNotification(
      id: 'n1',
      uid: 'u1',
      type: AppNotificationType.reviewDue,
      title: '复习到期',
      body: '3 个词需要复习',
      targetRoute: '/study/review',
      isRead: false,
      createdAt: createdAt,
      sourceKey: 'reviewDue:2026-06-02',
    );

    final decoded = AppNotification.fromJson(notification.toJson());
    expect(decoded.type, AppNotificationType.reviewDue);
    expect(decoded.targetRoute, '/study/review');
    expect(decoded.isRead, isFalse);
    expect(decoded.createdAt, createdAt);

    final read = decoded.markRead(
      now: createdAt.add(const Duration(minutes: 4)),
    );
    expect(read.isRead, isTrue);
    expect(read.readAt, createdAt.add(const Duration(minutes: 4)));
  });

  test('app notification parser defaults unknown types to activity', () {
    final notification = AppNotification.fromJson({
      'id': 'n2',
      'uid': 'u1',
      'type': 'unknown',
      'title': '活动',
      'body': '任务刷新',
      'createdAt': '2026-06-02T09:00:00.000',
    });

    expect(notification.type, AppNotificationType.activity);
    expect(notification.targetRoute, '/home');
    expect(notification.isRead, isFalse);
  });

  test('app notification timestamp fallbacks are UTC', () {
    final before = DateTime.now().toUtc();
    final notification = AppNotification.fromJson({
      'id': 'n2b',
      'uid': 'u1',
      'type': 'activity',
    });
    final read = notification.markRead();
    final after = DateTime.now().toUtc();

    expect(notification.createdAt.isUtc, isTrue);
    expect(
      notification.createdAt.isAfter(
        before.subtract(const Duration(seconds: 1)),
      ),
      isTrue,
    );
    expect(
      notification.createdAt.isBefore(after.add(const Duration(seconds: 1))),
      isTrue,
    );
    expect(read.readAt?.isUtc, isTrue);
  });

  test(
    'mock notifications persist read state and avoid daily duplicates',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockNotificationRepository();
      final now = DateTime.utc(2026, 6, 2, 9);
      final notification = AppNotification(
        id: 'n3',
        uid: 'persist-user',
        type: AppNotificationType.learningReminder,
        title: '今日学习计划待完成',
        body: '先开始新学。',
        targetRoute: '/study/new',
        isRead: false,
        createdAt: now,
        sourceKey: 'learningReminder:2026-06-02',
      );

      await repo.ensureGenerated('persist-user', [notification]);
      await repo.markRead('persist-user', 'n3');
      await repo.ensureGenerated('persist-user', [
        notification.copyWith(id: 'n4', title: '重复提醒'),
      ]);

      final notifications = await MockNotificationRepository().list(
        'persist-user',
      );
      expect(notifications, hasLength(1));
      expect(notifications.single.id, 'n3');
      expect(notifications.single.isRead, isTrue);
    },
  );

  testWidgets(
    'home badge opens notifications and mark all read clears unread',
    (tester) async {
      final now = DateTime(2026, 6, 2);
      final profile = UserProfile(
        uid: 'notification-widget-user',
        name: 'Ava',
        email: 'ava@lingua.quest',
        targetExam: 'IELTS',
        level: 'Intermediate',
        dailyGoal: 12,
        xp: 240,
        streak: 6,
        createdAt: now,
        updatedAt: now,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localNotificationServiceProvider.overrideWithValue(
              NoopLocalNotificationService(),
            ),
          ],
          child: const LinguaQuestApp(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('4'), findsOneWidget);
      await tester.tap(find.byTooltip('消息通知'));
      await tester.pumpAndSettle();

      expect(find.text('消息通知'), findsOneWidget);
      expect(find.text('4 条未读消息'), findsOneWidget);
      final filterTop = tester.getTopLeft(find.text('全部')).dy;
      for (final label in ['未读', '学习', '活动']) {
        expect(tester.getTopLeft(find.text(label)).dy, closeTo(filterTop, 1));
      }

      await tester.tap(find.text('全部已读'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('未读'));
      await tester.pumpAndSettle();

      expect(find.text('当前没有未读消息。'), findsOneWidget);
    },
  );
}
