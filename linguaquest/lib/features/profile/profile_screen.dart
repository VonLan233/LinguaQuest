import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/brand_hero_card.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/progress_ring.dart';
import '../../core/widgets/quest_panel.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../data/models/lottery.dart';
import '../../l10n/generated/app_localizations.dart';

int newWordbookCount(AppState state) => state.customWords.length;

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final reviewWords = state.reviewWords;
    final masteredWords = reviewWords
        .where((word) => word.masteryLevel >= 4 || word.status == 'Mastered')
        .length;

    return ListView(
      key: const ValueKey('profileDashboard'),
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 88),
      children: [
        // Telegram-style header: large centered avatar + name
        _ProfileHeader(
          name: user?.name ?? l10n.profileLearner,
          email: user?.email ?? l10n.profileNoEmail,
          target: displayTarget(user?.targetExam, l10n: l10n),
          level: displayLevel(user?.level, l10n: l10n),
          xp: user?.xp ?? 0,
          streak: user?.streak ?? 0,
          l10n: l10n,
        ),
        const SizedBox(height: AppTokens.s24),
        // Key stats in a clean row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          child: _ProfileStatsRow(
            learned: state.completedLearningWords,
            mastered: masteredWords,
            streak: user?.streak ?? 0,
            l10n: l10n,
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        // Progress card
        if (state.totalLearningWords > 0)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
            child: _ProfileProgressCard(
              progress: state.learningPathProgress,
              completedWords: state.completedLearningWords,
              totalWords: state.totalLearningWords,
              l10n: l10n,
            ),
          ),
        const SizedBox(height: AppTokens.s24),
        // Settings group
        _SettingsGroup(
          children: [
            _SettingsItem(
              icon: Icons.flag_outlined,
              title: l10n.profilePlanLabel,
              value: state.currentStudyBook.name,
              onTap: () => context.push('/settings/study-plan'),
            ),
            _SettingsItem(
              icon: Icons.menu_book_outlined,
              title: l10n.commonWordbook,
              value: '${state.totalLearningWords} ${l10n.commonWords}',
              onTap: () => context.push('/wordbook'),
            ),
            _SettingsItem(
              icon: Icons.style_outlined,
              title: l10n.commonCustomWords,
              value: '${newWordbookCount(state)}',
              onTap: () => context.push('/custom-words'),
            ),
            _SettingsItem(
              icon: Icons.warning_amber_outlined,
              title: l10n.commonMistakeBook,
              value: '${state.weakWords.length}',
              onTap: () => context.push('/mistake-book'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _SettingsGroup(
          children: [
            _SettingsItem(
              icon: Icons.dark_mode_outlined,
              title: l10n.commonTheme,
              value: _themeModeLabel(state.themeMode, l10n),
              onTap: () => context.push('/settings/theme'),
            ),
            _SettingsItem(
              icon: Icons.notifications_outlined,
              title: l10n.commonDailyReminder,
              value: state.reminderSettings.enabled
                  ? state.reminderSettings.formattedTime
                  : l10n.settingsReminderOff,
              onTap: () => context.push('/settings/reminder'),
            ),
            _LanguageSettingsItem(
              currentLocale: state.locale,
              onChanged: (locale) =>
                  ref.read(appControllerProvider.notifier).updateLocale(locale),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _SettingsGroup(
          children: [
            _SettingsItem(
              icon: Icons.help_outline,
              title: l10n.profileHelpTitle,
              onTap: () => context.push('/help'),
            ),
            _SettingsItem(
              icon: Icons.info_outline,
              title: l10n.profileAboutTitle,
              onTap: () => context.push('/about'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: l10n.profileAssetsTitle,
                subtitle: l10n.profileAssetsSubtitle,
              ),
              const SizedBox(height: AppTokens.s8),
              _AssetInventory(assets: state.userAssets),
            ],
          ),
        ),
        const SizedBox(height: AppTokens.s24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.s20),
          child: OutlinedButton.icon(
            onPressed: () async {
              await ref.read(appControllerProvider.notifier).logout();
              if (context.mounted) context.go('/onboarding');
            },
            icon: const Icon(Icons.logout),
            label: Text(l10n.profileLogout),
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.target,
    required this.level,
    required this.xp,
    required this.streak,
    required this.l10n,
  });

  final String name;
  final String email;
  final String target;
  final String level;
  final int xp;
  final int streak;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        0,
      ),
      child: BrandHeroCard(
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              child: const Icon(
                Icons.person_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              name,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppTokens.s8),
            Text(email, style: const TextStyle(fontSize: 15)),
            const SizedBox(height: AppTokens.s4),
            Text('$target · $level', style: const TextStyle(fontSize: 13)),
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s8,
              runSpacing: AppTokens.s8,
              alignment: WrapAlignment.center,
              children: [
                PillLabel(
                  label: '$xp ${l10n.commonXP}',
                  icon: Icons.bolt,
                  color: AppTheme.mango,
                ),
                PillLabel(
                  label: '$streak ${l10n.profileStreakDays}',
                  icon: Icons.local_fire_department,
                  color: AppTheme.coral,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({
    required this.learned,
    required this.mastered,
    required this.streak,
    required this.l10n,
  });

  final int learned;
  final int mastered;
  final int streak;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return QuestPanel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: StatTile(
              value: '$learned',
              label: l10n.profileLearnedWords,
              accent: AppTheme.teal,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: StatTile(
              value: '$mastered',
              label: l10n.profileMasteredWords,
              accent: AppTheme.success,
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          Expanded(
            child: StatTile(
              value: '$streak',
              label: l10n.onboardingTagPillStreak,
              accent: AppTheme.coral,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileProgressCard extends StatelessWidget {
  const _ProfileProgressCard({
    required this.progress,
    required this.completedWords,
    required this.totalWords,
    required this.l10n,
  });

  final double progress;
  final int completedWords;
  final int totalWords;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    return QuestPanel(
      child: Row(
        children: [
          ProgressRing(
            progress: progress,
            color: AppTheme.success,
            centerLabel: '$percent%',
          ),
          const SizedBox(width: AppTokens.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.profileCurrentBookProgress,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppTokens.s8),
                Text(
                  '$completedWords / $totalWords ${l10n.commonWords}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 56,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.5),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
              ),
              if (value != null)
                Text(
                  value!,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSettingsItem extends StatelessWidget {
  const _LanguageSettingsItem({
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showLanguageSheet(context, langCode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.language_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  l10n.languageSetting,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 15),
                ),
              ),
              Text(
                _localeLabel(langCode),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
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
                Navigator.pop(ctx);
                onChanged(const Locale('zh'));
              },
            ),
            _LanguageOption(
              code: 'ms',
              label: 'Bahasa Melayu',
              selected: current == 'ms',
              onTap: () {
                Navigator.pop(ctx);
                onChanged(const Locale('ms'));
              },
            ),
            _LanguageOption(
              code: 'en',
              label: 'English',
              selected: current == 'en',
              onTap: () {
                Navigator.pop(ctx);
                onChanged(const Locale('en'));
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

class _AssetInventory extends StatelessWidget {
  const _AssetInventory({required this.assets});

  final List<UserAsset> assets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (assets.isEmpty) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconCueBadge(
            icon: Icons.inventory_2_outlined,
            color: AppTheme.mango,
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.profileAssetsEmpty,
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.42,
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      children: [
        for (var index = 0; index < assets.length; index++) ...[
          _AssetRow(asset: assets[index]),
          if (index != assets.length - 1)
            Divider(
              height: 14,
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset});

  final UserAsset asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconCueBadge(
          icon: _assetIcon(asset.category),
          color: _assetColor(asset.rarity),
          size: 38,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(asset.name, style: theme.textTheme.titleMedium),
              const SizedBox(height: 2),
              Text(
                l10n.profileAssetMeta(
                  displayLotteryCategory(asset.category, l10n: l10n),
                  asset.quantity,
                  asset.totalFragments,
                ),
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 2),
              Text(
                asset.description,
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _assetIcon(String category) {
    switch (category) {
      case 'avatarFrame':
        return Icons.account_circle_outlined;
      case 'profileBackground':
        return Icons.wallpaper_outlined;
      case 'badge':
        return Icons.workspace_premium_outlined;
      case 'title':
        return Icons.military_tech_outlined;
      case 'cardSkin':
        return Icons.style_outlined;
      default:
        return Icons.auto_awesome_outlined;
    }
  }

  Color _assetColor(String rarity) {
    switch (rarity) {
      case 'rare':
        return AppTheme.coral;
      case 'uncommon':
        return AppTheme.teal;
      case 'common':
        return AppTheme.cyan;
      default:
        return AppTheme.mango;
    }
  }
}
