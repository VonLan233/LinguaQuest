import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/app.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/app_notification.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/data/repositories/notification_repository.dart';
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

  test(
    'notification read actions update optimistically on repository failure',
    () async {
      final now = DateTime(2026, 6, 2);
      final profile = UserProfile(
        uid: 'optimistic-user',
        name: 'Ava',
        email: 'optimistic@lingua.quest',
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
      final notifications = _FailingNotificationRepository();
      final container = ProviderContainer(
        overrides: [
          notificationRepositoryProvider.overrideWithValue(notifications),
          localNotificationServiceProvider.overrideWithValue(
            NoopLocalNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final notification = container
          .read(appControllerProvider)
          .notifications
          .firstWhere((item) => !item.isRead);

      final route = await container
          .read(appControllerProvider.notifier)
          .openNotification(notification);

      expect(route, notification.targetRoute);
      expect(
        container
            .read(appControllerProvider)
            .notifications
            .firstWhere((item) => item.id == notification.id)
            .isRead,
        isTrue,
      );

      final updatedCount = await container
          .read(appControllerProvider.notifier)
          .markAllNotificationsRead();

      expect(updatedCount, 0);
      expect(
        container
            .read(appControllerProvider)
            .notifications
            .every((notification) => notification.isRead),
        isTrue,
      );
    },
  );

  test('notification refresh ignores stale user results', () async {
    final now = DateTime(2026, 6, 2);
    final profile = UserProfile(
      uid: 'stale-user',
      name: 'Ava',
      email: 'stale@lingua.quest',
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
    final notifications = _DelayedListNotificationRepository();
    final container = ProviderContainer(
      overrides: [
        notificationRepositoryProvider.overrideWithValue(notifications),
        localNotificationServiceProvider.overrideWithValue(
          NoopLocalNotificationService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(appControllerProvider.notifier);
    await controller.bootstrap();

    final refresh = controller.refreshNotifications();
    await notifications.secondListStarted.future;
    await controller.logout();
    notifications.releaseSecondList();
    await refresh;

    final state = container.read(appControllerProvider);
    expect(state.user, isNull);
    expect(state.notifications, isEmpty);
  });

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

class _FailingNotificationRepository implements NotificationRepository {
  final List<AppNotification> _notifications = [];

  @override
  Future<void> ensureGenerated(
    String uid,
    List<AppNotification> notifications,
  ) async {
    _notifications.addAll(notifications);
  }

  @override
  Future<List<AppNotification>> list(
    String uid, {
    bool unreadOnly = false,
    AppNotificationType? type,
  }) async {
    return _notifications.where((notification) {
      if (unreadOnly && notification.isRead) return false;
      if (type != null && notification.type != type) return false;
      return true;
    }).toList();
  }

  @override
  Future<AppNotification?> markRead(String uid, String id) async {
    throw StateError('network unavailable');
  }

  @override
  Future<int> markAllRead(String uid) async {
    throw StateError('network unavailable');
  }
}

class _DelayedListNotificationRepository implements NotificationRepository {
  final secondListStarted = Completer<void>();
  final _releaseSecondList = Completer<void>();
  var _listCalls = 0;

  void releaseSecondList() {
    if (!_releaseSecondList.isCompleted) {
      _releaseSecondList.complete();
    }
  }

  @override
  Future<void> ensureGenerated(
    String uid,
    List<AppNotification> notifications,
  ) async {}

  @override
  Future<List<AppNotification>> list(
    String uid, {
    bool unreadOnly = false,
    AppNotificationType? type,
  }) async {
    _listCalls += 1;
    if (_listCalls == 1) return [];
    secondListStarted.complete();
    await _releaseSecondList.future;
    return [
      AppNotification(
        id: 'stale-notification',
        uid: uid,
        type: AppNotificationType.activity,
        title: '旧账号消息',
        body: '不应写入当前状态',
        targetRoute: '/discover',
        isRead: false,
        createdAt: DateTime.utc(2026, 6, 2, 9),
      ),
    ];
  }

  @override
  Future<AppNotification?> markRead(String uid, String id) async => null;

  @override
  Future<int> markAllRead(String uid) async => 0;
}
