import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/lesson.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/language_wordbook_picker.dart';
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
                  '${state.currentStudyBook.name} · ${l10n.commonNew} ${state.dailyNewTarget} · ${l10n.commonReview} ${state.dailyReviewLimit}',
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
            _LearningLanguageSetting(
              currentLanguage: state.currentLanguage,
              currentWordBookId: state.currentWordBookId,
              currentWordBook: state.currentWordBook,
            ),
            const SizedBox(height: AppTokens.s12),
            _SensorySettingsCard(sensorySettings: state.sensorySettings),
            const SizedBox(height: AppTokens.s12),
            _ThemeSettingCard(
              themeMode: ref.watch(
                appControllerProvider.select((s) => s.themeMode),
              ),
              onChanged: (mode) => ref
                  .read(appControllerProvider.notifier)
                  .updateThemeMode(mode),
            ),
            const SizedBox(height: AppTokens.s12),
            _SettingsAction(
              icon: AppIcons.lock,
              title: 'Privacy Settings',
              subtitle: 'Control what others can see about you',
              route: '/profile/privacy',
            ),
            const SizedBox(height: AppTokens.s12),
            _SettingsAction(
              icon: AppIcons.person,
              title: 'Data & Account',
              subtitle: 'Cache, export, and account deletion',
              route: '/profile/data',
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

class _LearningLanguageSetting extends StatelessWidget {
  const _LearningLanguageSetting({
    required this.currentLanguage,
    required this.currentWordBookId,
    this.currentWordBook,
  });

  final String currentLanguage;
  final String currentWordBookId;
  final WordBook? currentWordBook;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final langLabel = languageLabel(currentLanguage, l10n);
    final bookLabel =
        currentWordBook?.nameFor(localeCode) ?? currentWordBookId;
    return AppCard(
      onTap: () => context.push('/language-map'),
      child: Row(
        children: [
          Icon(AppIcons.language, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Learning Language', style: theme.textTheme.titleMedium),
                Text(
                  '$langLabel · $bookLabel',
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

class _ThemeSettingCard extends StatelessWidget {
  const _ThemeSettingCard({
    required this.themeMode,
    required this.onChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.contrastCircle, color: theme.colorScheme.primary),
              const SizedBox(width: AppTokens.s12),
              Text(l10n.settingsTheme, style: theme.textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppTokens.s12),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l10n.settingsThemeSystem),
                icon: const Icon(Icons.brightness_auto),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                label: Text(l10n.settingsThemeLight),
                icon: const Icon(Icons.brightness_7),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                label: Text(l10n.settingsThemeDark),
                icon: const Icon(Icons.brightness_2),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (Set<ThemeMode> selection) {
              if (selection.isNotEmpty) onChanged(selection.first);
            },
          ),
        ],
      ),
    );
  }
}

class _SensorySettingsCard extends ConsumerWidget {
  const _SensorySettingsCard({required this.sensorySettings});

  final SensorySettings sensorySettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void update(SensorySettings updated) =>
        ref.read(appControllerProvider.notifier).updateSensorySettings(updated);

    return AppCard(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(AppIcons.volumeUp),
            title: const Text('Sound Effects'),
            subtitle: const Text('Play sounds during quizzes'),
            value: sensorySettings.soundEnabled,
            onChanged: (v) =>
                update(sensorySettings.copyWith(soundEnabled: v)),
          ),
          const Divider(height: AppTokens.s16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(AppIcons.vibration),
            title: const Text('Vibration'),
            subtitle: const Text('Haptic feedback on answers'),
            value: sensorySettings.vibrationEnabled,
            onChanged: (v) =>
                update(sensorySettings.copyWith(vibrationEnabled: v)),
          ),
          const Divider(height: AppTokens.s16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(AppIcons.contrastCircle),
            title: const Text('High Contrast'),
            subtitle: const Text('Enhanced color contrast for answer feedback'),
            value: sensorySettings.highContrastMode,
            onChanged: (v) =>
                update(sensorySettings.copyWith(highContrastMode: v)),
          ),
        ],
      ),
    );
  }
}

