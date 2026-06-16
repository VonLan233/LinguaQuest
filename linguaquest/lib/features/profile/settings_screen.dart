import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
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
              icon: Icons.flag_outlined,
              title: l10n.commonStudyPlan,
              subtitle:
                  '${state.currentStudyBook.name} · ${l10n.commonNew} ${state.dailyNewTarget} · ${l10n.commonReview} ${state.dailyReviewLimit}',
              route: '/settings/study-plan',
            ),
            const SizedBox(height: AppTokens.s12),
            _SettingsAction(
              icon: Icons.notifications_outlined,
              title: l10n.commonDailyReminder,
              subtitle: state.reminderSettings.enabled
                  ? '${l10n.commonDay} ${state.reminderSettings.formattedTime}'
                  : l10n.settingsReminderOff,
              route: '/settings/reminder',
            ),
            const SizedBox(height: AppTokens.s12),
            _SettingsAction(
              icon: Icons.dark_mode_outlined,
              title: l10n.commonTheme,
              subtitle: _themeModeLabel(state.themeMode, l10n),
              route: '/settings/theme',
            ),
            const SizedBox(height: AppTokens.s12),
            _LanguageSetting(
              currentLocale: state.locale,
              onChanged: (locale) =>
                  ref.read(appControllerProvider.notifier).updateLocale(locale),
            ),
            const SizedBox(height: AppTokens.s12),
            _SettingsInfoLine(
              icon: Icons.volume_up_outlined,
              title: l10n.settingsSoundFeedback,
              subtitle: l10n.settingsSoundFeedbackSubtitle,
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
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(
      appControllerProvider.select((state) => state.themeMode),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/settings'),
        title: Text(l10n.commonTheme),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            _ThemeOption(
              value: ThemeMode.system,
              groupValue: themeMode,
              icon: Icons.phone_android_outlined,
              title: l10n.settingsThemeSystem,
              subtitle: l10n.settingsThemeSystemSubtitle,
            ),
            const SizedBox(height: AppTokens.s12),
            _ThemeOption(
              value: ThemeMode.light,
              groupValue: themeMode,
              icon: Icons.light_mode_outlined,
              title: l10n.settingsThemeLight,
              subtitle: l10n.settingsThemeLightSubtitle,
            ),
            const SizedBox(height: AppTokens.s12),
            _ThemeOption(
              value: ThemeMode.dark,
              groupValue: themeMode,
              icon: Icons.dark_mode_outlined,
              title: l10n.settingsThemeDark,
              subtitle: l10n.settingsThemeDarkSubtitle,
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
                    leading: const Icon(Icons.schedule_outlined),
                    title: Text(l10n.settingsReminderTime),
                    subtitle: Text(settings.formattedTime),
                    trailing: const Icon(Icons.chevron_right_rounded),
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

class _LanguageSetting extends StatelessWidget {
  const _LanguageSetting({
    required this.currentLocale,
    required this.onChanged,
  });

  final Locale? currentLocale;
  final ValueChanged<Locale> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final langCode = currentLocale?.languageCode ?? 'zh';
    return AppCard(
      onTap: () => _showLanguageSheet(context, langCode),
      child: Row(
        children: [
          Icon(Icons.language_outlined, color: theme.colorScheme.primary),
          const SizedBox(width: AppTokens.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.languageSetting, style: theme.textTheme.titleMedium),
                Text(
                  _localeLabel(langCode),
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }

  void _showLanguageSheet(BuildContext context, String current) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LanguageOption(
              code: 'zh',
              label: '中文',
              selected: current == 'zh',
              onTap: () {
                onChanged(const Locale('zh'));
                Navigator.pop(ctx);
              },
            ),
            _LanguageOption(
              code: 'ms',
              label: 'Bahasa Melayu',
              selected: current == 'ms',
              onTap: () {
                onChanged(const Locale('ms'));
                Navigator.pop(ctx);
              },
            ),
            _LanguageOption(
              code: 'en',
              label: 'English',
              selected: current == 'en',
              onTap: () {
                onChanged(const Locale('en'));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _localeLabel(String langCode) {
    switch (langCode) {
      case 'zh':
        return '中文';
      case 'ms':
        return 'Bahasa Melayu';
      case 'en':
        return 'English';
      default:
        return '中文';
    }
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String code;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: selected ? theme.colorScheme.primary : null,
      ),
      title: Text(label),
      selected: selected,
      onTap: onTap,
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
          const Icon(Icons.chevron_right_rounded),
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
    return AppCard(
      onTap: () =>
          ref.read(appControllerProvider.notifier).updateThemeMode(value),
      child: Row(
        children: [
          Icon(
            icon,
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
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
          Icon(
            selected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

String _themeModeLabel(ThemeMode mode, AppLocalizations l10n) {
  switch (mode) {
    case ThemeMode.light:
      return l10n.settingsThemeLight;
    case ThemeMode.dark:
      return l10n.settingsThemeDark;
    case ThemeMode.system:
      return l10n.settingsThemeSystem;
  }
}
