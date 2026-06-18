import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: Text(l10n.settingsAppBar),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            _SettingsAction(
              icon: AppIcons.flag,
              title: l10n.commonStudyPlan,
              subtitle:
                  '${displayWordbookTitle(state.currentStudyBook.id, l10n: l10n)} · ${l10n.commonNew} ${state.dailyNewTarget} · ${l10n.commonReview} ${state.dailyReviewLimit}',
              route: '/settings/study-plan',
            ),
            const SizedBox(height: AppTokens.s12),
            _SettingsAction(
              icon: AppIcons.notifications,
              title: l10n.commonDailyReminder,
              subtitle: state.reminderSettings.enabled
                  ? '${l10n.commonDay} ${state.reminderSettings.formattedTime}'
                  : l10n.settingsReminderOff,
              route: '/settings/reminder',
            ),
            const SizedBox(height: AppTokens.s12),
            _TargetLanguageSetting(
              targetLanguage: state.targetLanguage,
              onChanged: (code) => ref
                  .read(appControllerProvider.notifier)
                  .updateTargetLanguage(code),
            ),
            const SizedBox(height: AppTokens.s12),
            _SettingsInfoLine(
              icon: AppIcons.volumeUp,
              title: l10n.settingsSoundFeedback,
              subtitle: l10n.settingsSoundFeedbackSubtitle,
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
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(
      appControllerProvider.select((state) => state.reminderSettings),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/settings'),
        title: Text(l10n.settingsReminderTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            AppCard(
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
                    title: Text(l10n.settingsReminderTitle),
                    subtitle: Text(
                      settings.enabled
                          ? '${l10n.settingsReminderTime}${l10n.localeName == 'zh' ? '：' : ': '}${settings.formattedTime}'
                          : l10n.settingsReminderDisabled,
                    ),
                  ),
                  const Divider(height: AppTokens.s20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    enabled: settings.enabled,
                    leading: const Icon(AppIcons.schedule),
                    title: Text(l10n.settingsReminderTime),
                    subtitle: Text(settings.formattedTime),
                    trailing: const Icon(AppIcons.chevronRight),
                    onTap: settings.enabled
                        ? () => _pickTime(context, ref, settings)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              l10n.settingsReminderDescription,
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

class _TargetLanguageSetting extends StatelessWidget {
  const _TargetLanguageSetting({
    required this.targetLanguage,
    required this.onChanged,
  });

  final String targetLanguage;
  final ValueChanged<String> onChanged;

  // Active languages plus coming-soon placeholders.
  static const _active = {'zh': 'Chinese (中文)'};
  static const _comingSoon = {
    'es': 'Spanish (Español)',
    'fr': 'French (Français)',
    'ja': 'Japanese (日本語)',
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = _active[targetLanguage] ?? _active['zh']!;
    return AppCard(
      onTap: () => _showSheet(context),
      child: Row(
        children: [
          Icon(AppIcons.language, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Target language', style: theme.textTheme.titleMedium),
                Text(
                  label,
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRight),
        ],
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _active.entries)
              ListTile(
                leading: Icon(
                  entry.key == targetLanguage
                      ? AppIcons.radioButtonChecked
                      : AppIcons.radioButtonUnchecked,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
                title: Text(entry.value),
                selected: entry.key == targetLanguage,
                onTap: () {
                  onChanged(entry.key);
                  Navigator.pop(ctx);
                },
              ),
            for (final entry in _comingSoon.entries)
              Opacity(
                opacity: 0.6,
                child: ListTile(
                  leading: const Icon(AppIcons.radioButtonUnchecked),
                  title: Text(entry.value),
                  trailing: const AppPill(
                    label: 'Coming Soon',
                    variant: PillVariant.neutral,
                  ),
                  enabled: false,
                ),
              ),
          ],
        ),
      ),
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
    return AppCard(
      onTap: () => context.push(route),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s12),
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
          const Icon(AppIcons.chevronRight),
        ],
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
    return AppCard(
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppTokens.s12),
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

