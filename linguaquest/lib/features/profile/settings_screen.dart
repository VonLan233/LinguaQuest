import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/fallback_back_button.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('设置'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SettingsAction(
              icon: Icons.notifications_outlined,
              title: '每日提醒',
              subtitle: state.reminderSettings.enabled
                  ? '每天 ${state.reminderSettings.formattedTime}'
                  : '提醒已关闭',
              route: '/settings/reminder',
            ),
            _SettingsAction(
              icon: Icons.dark_mode_outlined,
              title: '主题',
              subtitle: _themeModeLabel(state.themeMode),
              route: '/settings/theme',
            ),
            const SizedBox(height: 8),
            const _SettingsInfoLine(
              icon: Icons.volume_up_outlined,
              title: '答题音效反馈',
              subtitle: '用于提醒答题结果和练习节奏',
            ),
          ],
        ),
      ),
    );
  }
}

class ThemeSettingsScreen extends ConsumerWidget {
  const ThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(
      appControllerProvider.select((state) => state.themeMode),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/settings'),
        title: const Text('主题'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ThemeOption(
              value: ThemeMode.system,
              groupValue: themeMode,
              icon: Icons.phone_android_outlined,
              title: '跟随系统',
              subtitle: '根据设备浅色或深色偏好自动切换',
            ),
            _ThemeOption(
              value: ThemeMode.light,
              groupValue: themeMode,
              icon: Icons.light_mode_outlined,
              title: '浅色',
              subtitle: '保持明亮清爽的学习界面',
            ),
            _ThemeOption(
              value: ThemeMode.dark,
              groupValue: themeMode,
              icon: Icons.dark_mode_outlined,
              title: '深色',
              subtitle: '使用深色学习界面',
            ),
          ],
        ),
      ),
    );
  }
}

class ReminderSettingsScreen extends ConsumerWidget {
  const ReminderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(
      appControllerProvider.select((state) => state.reminderSettings),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/settings'),
        title: const Text('每日提醒'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: settings.enabled,
              onChanged: (value) {
                ref
                    .read(appControllerProvider.notifier)
                    .updateReminderSettings(settings.copyWith(enabled: value));
              },
              title: const Text('每日提醒'),
              subtitle: Text(
                settings.enabled
                    ? '提醒时间：${settings.formattedTime}'
                    : '应用内不会显示提醒',
              ),
            ),
            const Divider(height: 20),
            ListTile(
              contentPadding: EdgeInsets.zero,
              enabled: settings.enabled,
              leading: const Icon(Icons.schedule_outlined),
              title: const Text('提醒时间'),
              subtitle: Text(settings.formattedTime),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: settings.enabled
                  ? () => _pickTime(context, ref, settings)
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              '应用会记住提醒时间，方便你按固定节奏打开学习。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    DailyReminderSettings settings,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
    );
    if (picked == null) return;
    if (!context.mounted) return;
    await ref
        .read(appControllerProvider.notifier)
        .updateReminderSettings(
          settings.copyWith(hour: picked.hour, minute: picked.minute),
        );
  }
}

class _SettingsAction extends StatelessWidget {
  const _SettingsAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push(route),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsInfoLine extends StatelessWidget {
  const _SettingsInfoLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                Text(
                  subtitle,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends ConsumerWidget {
  const _ThemeOption({
    required this.value,
    required this.groupValue,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final ThemeMode value;
  final ThemeMode groupValue;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selected = value == groupValue;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () =>
            ref.read(appControllerProvider.notifier).updateThemeMode(value),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return '浅色';
    case ThemeMode.dark:
      return '深色';
    case ThemeMode.system:
      return '跟随系统';
  }
}
