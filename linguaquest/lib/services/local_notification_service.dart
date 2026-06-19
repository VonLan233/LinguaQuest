import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import '../l10n/generated/app_localizations.dart';

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

/// Localized, locale-resolved copy for OS push notifications and the Android
/// notification channel. Resolved by the scheduler from [AppLocalizations] so
/// the service stays free of widget context.
class LocalNotificationStrings {
  const LocalNotificationStrings({
    required this.studyReminderTitle,
    required this.studyReminderBody,
    required this.reviewDueBody,
    required this.channelName,
    required this.channelDescription,
  });

  factory LocalNotificationStrings.fromL10n(AppLocalizations l10n) {
    return LocalNotificationStrings(
      studyReminderTitle: l10n.osNotificationStudyReminderTitle,
      studyReminderBody: l10n.osNotificationStudyReminderBody,
      reviewDueBody: l10n.osNotificationReviewDueBody,
      channelName: l10n.osNotificationChannelName,
      channelDescription: l10n.osNotificationChannelDescription,
    );
  }

  final String studyReminderTitle;
  final String studyReminderBody;
  final String reviewDueBody;
  final String channelName;
  final String channelDescription;
}

abstract class LocalNotificationService {
  Future<void> initialize({required void Function(String route) onSelectRoute});

  Future<void> scheduleDailyStudyReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required LocalNotificationStrings strings,
  });

  Future<void> scheduleReviewDueReminder({
    required int dueCount,
    required String title,
    required LocalNotificationStrings strings,
  });
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
    required LocalNotificationStrings strings,
  }) async {}

  @override
  Future<void> scheduleReviewDueReminder({
    required int dueCount,
    required String title,
    required LocalNotificationStrings strings,
  }) async {}
}

class FlutterLocalNotificationService implements LocalNotificationService {
  FlutterLocalNotificationService();

  static const _studyReminderId = 8101;
  static const _reviewReminderId = 8102;
  static const _androidChannelId = 'linguaquest_study_reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  bool _isPluginAvailable = false;

  @override
  Future<void> initialize({
    required void Function(String route) onSelectRoute,
  }) async {
    if (_isInitialized) return;
    try {
      await _initializeLocalTimezone();
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
      _isPluginAvailable = true;
      _isInitialized = true;
    } on MissingPluginException {
      _isPluginAvailable = false;
      _isInitialized = true;
    } catch (error, stackTrace) {
      _isPluginAvailable = false;
      assert(() {
        debugPrint('LocalNotificationService initialization unavailable: $error');
        debugPrintStack(stackTrace: stackTrace);
        return true;
      }());
      _isInitialized = true;
    }
  }

  Future<void> _initializeLocalTimezone() async {
    timezone_data.initializeTimeZones();
    try {
      final Object localTimezone = await FlutterTimezone.getLocalTimezone();
      final timezoneIdentifier = localTimezone is String
          ? localTimezone
          : (localTimezone as dynamic).identifier.toString();
      timezone.setLocalLocation(timezone.getLocation(timezoneIdentifier));
    } catch (_) {
      timezone.setLocalLocation(timezone.UTC);
    }
  }

  @override
  Future<void> scheduleDailyStudyReminder({
    required bool enabled,
    required int hour,
    required int minute,
    required LocalNotificationStrings strings,
  }) async {
    if (!_isPluginAvailable) return;
    await _guarded(() async {
      if (!enabled) {
        await _plugin.cancel(id: _studyReminderId);
        return;
      }
      await _plugin.zonedSchedule(
        id: _studyReminderId,
        title: strings.studyReminderTitle,
        body: strings.studyReminderBody,
        scheduledDate: _nextTime(hour: hour, minute: minute),
        notificationDetails: _notificationDetails(strings),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/home',
      );
    });
  }

  @override
  Future<void> scheduleReviewDueReminder({
    required int dueCount,
    required String title,
    required LocalNotificationStrings strings,
  }) async {
    if (!_isPluginAvailable) return;
    await _guarded(() async {
      if (dueCount <= 0) {
        await _plugin.cancel(id: _reviewReminderId);
        return;
      }
      await _plugin.zonedSchedule(
        id: _reviewReminderId,
        title: title,
        body: strings.reviewDueBody,
        scheduledDate: _nextTime(hour: 9, minute: 0),
        notificationDetails: _notificationDetails(strings),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: '/study/review',
      );
    });
  }

  NotificationDetails _notificationDetails(LocalNotificationStrings strings) {
    final android = AndroidNotificationDetails(
      _androidChannelId,
      strings.channelName,
      channelDescription: strings.channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const darwin = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    return NotificationDetails(android: android, iOS: darwin);
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
    } catch (error, stackTrace) {
      assert(() {
        debugPrint('LocalNotificationService error: $error');
        debugPrintStack(stackTrace: stackTrace);
        return true;
      }());
    }
  }
}
