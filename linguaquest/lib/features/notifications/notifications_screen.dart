import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/app_notification.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  _NotificationFilter _filter = _NotificationFilter.all;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final notifications = _filter.apply(state.notifications);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('消息通知'),
        actions: [
          TextButton(
            onPressed: state.unreadNotificationCount == 0
                ? null
                : () => ref
                      .read(appControllerProvider.notifier)
                      .markAllNotificationsRead(),
            child: const Text('全部已读'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 88),
          children: [
            SectionHeader(
              title: '消息中心',
              subtitle: state.unreadNotificationCount == 0
                  ? '学习提醒、复习到期、打卡和活动消息都会集中在这里。'
                  : '${state.unreadNotificationCount} 条未读消息',
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _NotificationFilter.values)
                  FilterPillButton(
                    label: filter.label,
                    selected: _filter == filter,
                    onSelected: () => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (notifications.isEmpty)
              EmptyState(
                icon: Icons.notifications_none_outlined,
                title: '没有符合条件的消息',
                message: _filter == _NotificationFilter.unread
                    ? '当前没有未读消息。'
                    : '完成学习和复习后，这里会继续沉淀学习提醒和活动消息。',
                action: OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('回到首页'),
                ),
              )
            else
              _NotificationList(notifications: notifications),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications});

  final List<AppNotification> notifications;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < notifications.length; index++) ...[
          _NotificationRow(notification: notifications[index]),
          if (index != notifications.length - 1)
            Divider(
              height: 10,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _notificationColor(notification.type);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _open(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconCueBadge(
                icon: _notificationIcon(notification.type),
                color: color,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead
                                  ? FontWeight.w700
                                  : FontWeight.w900,
                            ),
                          ),
                        ),
                        if (!notification.isRead) ...[
                          const SizedBox(width: 8),
                          _UnreadDot(color: color),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.body,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        PillLabel(
                          label: appNotificationTypeLabel(notification.type),
                          icon: Icons.label_outline,
                          color: color,
                        ),
                        PillLabel(
                          label: formatFullDate(
                            notification.createdAt.toLocal(),
                          ),
                          icon: Icons.schedule_outlined,
                          color: AppTheme.cyan,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final route = await ref
        .read(appControllerProvider.notifier)
        .openNotification(notification);
    if (!context.mounted) return;
    if (route == '/home' ||
        route == '/discover' ||
        route == '/training' ||
        route == '/ai-learning' ||
        route == '/profile') {
      context.go(route);
      return;
    }
    context.push(route);
  }
}

class _UnreadDot extends StatelessWidget {
  const _UnreadDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      margin: const EdgeInsets.only(top: 7),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

enum _NotificationFilter {
  all('全部'),
  unread('未读'),
  learning('学习'),
  activity('活动');

  const _NotificationFilter(this.label);

  final String label;

  List<AppNotification> apply(List<AppNotification> notifications) {
    return notifications.where((notification) {
      switch (this) {
        case _NotificationFilter.all:
          return true;
        case _NotificationFilter.unread:
          return !notification.isRead;
        case _NotificationFilter.learning:
          return notification.isLearningType;
        case _NotificationFilter.activity:
          return notification.type == AppNotificationType.activity;
      }
    }).toList();
  }
}

IconData _notificationIcon(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.learningReminder:
      return Icons.school_outlined;
    case AppNotificationType.reviewDue:
      return Icons.replay_outlined;
    case AppNotificationType.checkInReminder:
      return Icons.local_fire_department_outlined;
    case AppNotificationType.activity:
      return Icons.emoji_events_outlined;
  }
}

Color _notificationColor(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.learningReminder:
      return AppTheme.teal;
    case AppNotificationType.reviewDue:
      return AppTheme.mango;
    case AppNotificationType.checkInReminder:
      return AppTheme.coral;
    case AppNotificationType.activity:
      return AppTheme.cyan;
  }
}
