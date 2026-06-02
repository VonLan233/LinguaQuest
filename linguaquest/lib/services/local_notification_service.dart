import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

final localNotificationTapRouteProvider =
    NotifierProvider<LocalNotificationTapRoute, String?>(
      LocalNotificationTapRoute.new,
    );

class LocalNotificationTapRoute extends Notifier<String?> {
  @override
  String? build() => null;

  void show(String route) {
    state = route;
  }

  void clear() {
    state = null;
  }
}

final localNotificationServiceProvider = Provider<LocalNotificationService>(
  (ref) => FlutterLocalNotificationService(),
);

abstract class LocalNotificationService {
  Future<void> initialize({required void Function(String route) onSelectRoute});

  Future<void> scheduleDailyStudyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  });

  Future<void> scheduleReviewDueReminder({required int dueCount});
}

class NoopLocalNotificationService implements LocalNotificationService {
  @override
  Future<void> initialize({
    required void Function(String route) onSelectRoute,
  }) async {}

  @override
  Future<void> scheduleDailyStudyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> scheduleReviewDueReminder({required int dueCount}) async {}
}

class FlutterLocalNotificationService implements LocalNotificationService {
  FlutterLocalNotificationService();

  static const _studyReminderId = 8101;
  static const _reviewReminderId = 8102;
  static const _androidChannelId = 'linguaquest_study_reminders';
  static const _androidChannelName = '学习提醒';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  @override
  Future<void> initialize({
    required void Function(String route) onSelectRoute,
  }) async {
    if (_isInitialized) return;
    try {
      timezone_data.initializeTimeZones();
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: android,
          iOS: darwin,
          macOS: darwin,
        ),
        onDidReceiveNotificationResponse: (response) {
          final route = response.payload;
          if (route == null || route.isEmpty) return;
          onSelectRoute(route);
        },
      );
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      _isInitialized = true;
    } on MissingPluginException {
      _isInitialized = true;
    } catch (_) {
      _isInitialized = true;
    }
  }

  @override
  Future<void> scheduleDailyStudyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {
    await _guarded(() async {
      if (!enabled) {
        await _plugin.cancel(id: _studyReminderId);
        return;
      }
      await _plugin.zonedSchedule(
        id: _studyReminderId,
        title: '今天的学习任务等你开始',
        body: '完成新学、复习和打卡，保持你的连续学习节奏。',
        scheduledDate: _nextTime(hour: hour, minute: minute),
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/home',
      );
    });
  }

  @override
  Future<void> scheduleReviewDueReminder({required int dueCount}) async {
    await _guarded(() async {
      if (dueCount <= 0) {
        await _plugin.cancel(id: _reviewReminderId);
        return;
      }
      await _plugin.zonedSchedule(
        id: _reviewReminderId,
        title: '$dueCount 个词到期复习',
        body: '先清掉复习队列，再开始今天的新词。',
        scheduledDate: _nextTime(hour: 9, minute: 0),
        notificationDetails: _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/study/review',
      );
    });
  }

  NotificationDetails _notificationDetails() {
    const android = AndroidNotificationDetails(
      _androidChannelId,
      _androidChannelName,
      channelDescription: '学习提醒、复习到期和打卡提醒',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return const NotificationDetails(android: android, iOS: darwin);
  }

  timezone.TZDateTime _nextTime({required int hour, required int minute}) {
    final now = timezone.TZDateTime.now(timezone.local);
    var scheduled = timezone.TZDateTime(
      timezone.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> _guarded(Future<void> Function() action) async {
    try {
      await action();
    } on MissingPluginException {
      return;
    } catch (_) {
      return;
    }
  }
}
