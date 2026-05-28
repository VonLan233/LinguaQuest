import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SettingsAction(
              icon: Icons.notifications_outlined,
              title: 'Daily Reminder',
              subtitle: state.reminderSettings.enabled
                  ? 'Every day at ${state.reminderSettings.formattedTime}'
                  : 'Reminder is off',
              route: '/settings/reminder',
            ),
            _SettingsAction(
              icon: Icons.dark_mode_outlined,
              title: 'Theme',
              subtitle: _themeModeLabel(state.themeMode),
              route: '/settings/theme',
            ),
            const QuestCard(
              margin: EdgeInsets.only(top: 10),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.volume_up_outlined),
                title: Text('Quiz Sound Feedback'),
                subtitle: Text('Prepared for future pronunciation support'),
              ),
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
        title: const Text('Theme'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _ThemeOption(
              value: ThemeMode.system,
              groupValue: themeMode,
              icon: Icons.phone_android_outlined,
              title: 'System',
              subtitle: 'Follow the device light or dark preference',
            ),
            _ThemeOption(
              value: ThemeMode.light,
              groupValue: themeMode,
              icon: Icons.light_mode_outlined,
              title: 'Light',
              subtitle: 'Keep LinguaQuest bright',
            ),
            _ThemeOption(
              value: ThemeMode.dark,
              groupValue: themeMode,
              icon: Icons.dark_mode_outlined,
              title: 'Dark',
              subtitle: 'Use the dark learning interface',
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
        title: const Text('Daily Reminder'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            QuestCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.enabled,
                    onChanged: (value) {
                      ref
                          .read(appControllerProvider.notifier)
                          .updateReminderSettings(
                            settings.copyWith(enabled: value),
                          );
                    },
                    title: const Text('Daily Reminder'),
                    subtitle: Text(
                      settings.enabled
                          ? 'Reminder time: ${settings.formattedTime}'
                          : 'No reminder will be shown in the app',
                    ),
                  ),
                  const Divider(height: 24),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: settings.enabled,
                    leading: const Icon(Icons.schedule_outlined),
                    title: const Text('Reminder Time'),
                    subtitle: Text(settings.formattedTime),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: settings.enabled
                        ? () => _pickTime(context, ref, settings)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This setting is saved in the app. System notifications are not enabled in this build.',
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
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () => context.push(route),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                Text(subtitle),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
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
    return QuestCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: () =>
          ref.read(appControllerProvider.notifier).updateThemeMode(value),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Text(title), Text(subtitle)],
            ),
          ),
          Icon(
            value == groupValue
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

String _themeModeLabel(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'Light mode';
    case ThemeMode.dark:
      return 'Dark mode';
    case ThemeMode.system:
      return 'Follows system setting';
  }
}
