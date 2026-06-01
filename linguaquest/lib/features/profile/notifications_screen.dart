import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/app_notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/home'),
        title: const Text('消息通知'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(notificationsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: '消息通知',
                subtitle: '学习提醒、奖励结果和社区互动都会从服务器同步到这里。',
              ),
              const SizedBox(height: 14),
              notifications.when(
                data: (items) {
                  if (items.isEmpty) return const _NotificationEmpty();
                  return Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        _NotificationRow(item: items[index]),
                        if (index != items.length - 1)
                          Divider(
                            height: 12,
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                      ],
                    ],
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) => const _NotificationError(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.item});

  final AppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _colorForType(item.type);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () async {
          if (!item.isRead) {
            await ref
                .read(appControllerProvider.notifier)
                .markNotificationRead(item.id);
          }
          if (!context.mounted) return;
          final route = item.targetRoute;
          if (route != null && route.startsWith('/')) context.push(route);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconCueBadge(icon: _iconForType(item.type), color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        if (!item.isRead)
                          const PillLabel(label: '未读', color: AppTheme.coral),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _timeLabel(item.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationEmpty extends StatelessWidget {
  const _NotificationEmpty();

  @override
  Widget build(BuildContext context) {
    return Text(
      '暂无消息。完成学习、抽奖或社区互动后，通知会自动出现在这里。',
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _NotificationError extends StatelessWidget {
  const _NotificationError();

  @override
  Widget build(BuildContext context) {
    return Text(
      '暂时无法同步消息通知，请稍后重试。',
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

IconData _iconForType(String type) {
  return switch (type) {
    'reward' => Icons.card_giftcard_outlined,
    'community' => Icons.forum_outlined,
    'study' => Icons.school_outlined,
    _ => Icons.notifications_outlined,
  };
}

Color _colorForType(String type) {
  return switch (type) {
    'reward' => AppTheme.mango,
    'community' => AppTheme.coral,
    'study' => AppTheme.cyan,
    _ => AppTheme.deepTeal,
  };
}

String _timeLabel(DateTime value) {
  final local = value.toLocal();
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$month-$day $hour:$minute';
}
