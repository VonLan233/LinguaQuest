import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/date_formatting.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/app_notification.dart';
import '../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final notifications = _filter.apply(state.notifications);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: Text(l10n.notificationTitle),
        actions: [
          TextButton(
            onPressed: state.unreadNotificationCount == 0
                ? null
                : () => ref
                      .read(appControllerProvider.notifier)
                      .markAllNotificationsRead(),
            child: Text(l10n.notificationMarkAllRead),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader(
                    title: l10n.notificationCenter,
                    subtitle: state.unreadNotificationCount == 0
                        ? l10n.notificationCenterDesc
                        : l10n.notificationUnreadCount(
                            state.unreadNotificationCount,
                          ),
                  ),
                  const SizedBox(height: 14),
                  _NotificationFilterTabs(
                    selected: _filter,
                    onSelected: (filter) => setState(() => _filter = filter),
                    l10n: l10n,
                  ),
                ],
              ),
            ),
            Expanded(
              child: notifications.isEmpty
                  ? ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 88),
                      children: [
                        MascotEmptyState(
                          title: l10n.notificationEmptyTitle,
                          message: _filter == _NotificationFilter.unread
                              ? l10n.notificationEmptyUnread
                              : l10n.notificationEmptyAll,
                          action: AppSecondaryButton(
                            label: l10n.notificationBackHome,
                            icon: Icons.home_outlined,
                            onPressed: () => context.go('/home'),
                          ),
                        ),
                      ],
                    )
                  : _NotificationList(notifications: notifications, l10n: l10n),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationFilterTabs extends StatelessWidget {
  const _NotificationFilterTabs({
    required this.selected,
    required this.onSelected,
    required this.l10n,
  });

  final _NotificationFilter selected;
  final ValueChanged<_NotificationFilter> onSelected;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.isDark(context)
            ? theme.colorScheme.surfaceContainerHigh
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          for (final filter in _NotificationFilter.values)
            Expanded(
              child: _NotificationFilterTab(
                filter: filter,
                selected: selected == filter,
                onPressed: () => onSelected(filter),
                l10n: l10n,
              ),
            ),
        ],
      ),
    );
  }
}

class _NotificationFilterTab extends StatelessWidget {
  const _NotificationFilterTab({
    required this.filter,
    required this.selected,
    required this.onPressed,
    required this.l10n,
  });

  final _NotificationFilter filter;
  final bool selected;
  final VoidCallback onPressed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedForeground = AppTheme.isDark(context)
        ? theme.colorScheme.onPrimaryContainer
        : AppTheme.ink;
    return Material(
      color: selected ? AppTheme.selectedSurface(context) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Center(
          child: Text(
            filter.label(l10n),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected
                  ? selectedForeground
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.notifications, required this.l10n});

  final List<AppNotification> notifications;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
      itemCount: notifications.length,
      itemBuilder: (context, index) =>
          _NotificationRow(notification: notifications[index], l10n: l10n),
      separatorBuilder: (context, index) => const SizedBox(height: 10),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification, required this.l10n});

  final AppNotification notification;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _notificationColor(notification.type);
    return AppCard(
      padding: const EdgeInsets.all(12),
      onTap: () => _open(context, ref),
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
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 7),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    AppPill(
                      label: appNotificationTypeLabel(
                        notification.type,
                        l10n: l10n,
                      ),
                      variant: _notificationPillVariant(notification.type),
                      icon: Icons.label_outline,
                    ),
                    AppPill(
                      label: formatFullDate(notification.createdAt.toLocal()),
                      variant: PillVariant.neutral,
                      icon: Icons.schedule_outlined,
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
  all,
  unread,
  learning,
  activity;

  String label(AppLocalizations l10n) {
    switch (this) {
      case _NotificationFilter.all:
        return l10n.notificationFilterAll;
      case _NotificationFilter.unread:
        return l10n.notificationFilterUnread;
      case _NotificationFilter.learning:
        return l10n.notificationFilterLearning;
      case _NotificationFilter.activity:
        return l10n.notificationFilterActivity;
    }
  }

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

PillVariant _notificationPillVariant(AppNotificationType type) {
  switch (type) {
    case AppNotificationType.learningReminder:
      return PillVariant.success;
    case AppNotificationType.reviewDue:
      return PillVariant.streak;
    case AppNotificationType.checkInReminder:
      return PillVariant.streak;
    case AppNotificationType.activity:
      return PillVariant.primary;
  }
}
