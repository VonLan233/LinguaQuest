import 'package:flutter/material.dart';
import '../../core/theme/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/language_wordbook_picker.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../core/widgets/mascot_image.dart';
import '../../core/widgets/progress_ring.dart';
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
    final localeCode = Localizations.localeOf(context).languageCode;
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final reviewWords = state.reviewWords;
    final masteredWords = reviewWords
        .where((word) => word.masteryLevel >= 4 || word.status == 'Mastered')
        .length;

    return ListView(
      key: const ValueKey('profileDashboard'),
      padding: const EdgeInsets.fromLTRB(
        AppTokens.s20,
        AppTokens.s20,
        AppTokens.s20,
        88,
      ),
      children: [
        // Hero: mascot avatar + name/email/target·level + XP/streak pills.
        _ProfileHeader(
          name: displayUserName(user, l10n: l10n),
          email: user?.email ?? l10n.profileNoEmail,
          target: displayTarget(user?.targetExam, l10n: l10n),
          level: displayLevel(user?.level, l10n: l10n),
          xp: user?.xp ?? 0,
          streak: user?.streak ?? 0,
          l10n: l10n,
          onAvatarTap: user?.uid != null
              ? () => context.push('/profile/${user!.uid}')
              : null,
        ),
        const SizedBox(height: AppTokens.s32),
        // Key stats in a clean row.
        _ProfileStatsRow(
          learned: state.completedLearningWords,
          mastered: masteredWords,
          streak: user?.streak ?? 0,
          l10n: l10n,
        ),
        const SizedBox(height: AppTokens.s32),
        // Progress card.
        if (state.totalLearningWords > 0) ...[
          _ProfileProgressCard(
            progress: state.learningPathProgress,
            completedWords: state.completedLearningWords,
            totalWords: state.totalLearningWords,
            l10n: l10n,
          ),
          const SizedBox(height: AppTokens.s32),
        ],
        // Settings group: study plan / wordbook / custom words / mistake book.
        _SettingsGroup(
          children: [
            _SettingsItem(
              icon: AppIcons.settings,
              title: l10n.commonSettings,
              onTap: () => context.push('/settings'),
            ),
            _SettingsItem(
              icon: AppIcons.flag,
              title: l10n.profilePlanLabel,
              value: state.currentWordBook?.nameFor(localeCode) ??
                  state.currentStudyBook.name,
              onTap: () => context.push('/settings/study-plan'),
            ),
            _SettingsItem(
              icon: AppIcons.menuBook,
              title: l10n.commonWordbook,
              value: '${state.totalLearningWords} ${l10n.commonWords}',
              onTap: () => context.push('/wordbook'),
            ),
            _SettingsItem(
              icon: AppIcons.language,
              title: l10n.pickerChooseLanguage,
              value:
                  '${languageLabel(state.currentLanguage, l10n)} · ${state.currentWordBook?.nameFor(localeCode) ?? state.currentWordBookId}',
              onTap: () => context.push('/language-map'),
            ),
            _SettingsItem(
              icon: AppIcons.style,
              title: l10n.commonCustomWords,
              value: '${newWordbookCount(state)}',
              onTap: () => context.push('/custom-words'),
            ),
            _SettingsItem(
              icon: AppIcons.warningAmber,
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
              icon: AppIcons.notifications,
              title: l10n.commonDailyReminder,
              value: state.reminderSettings.enabled
                  ? state.reminderSettings.formattedTime
                  : l10n.settingsReminderOff,
              onTap: () => context.push('/settings/reminder'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _SettingsGroup(
          children: [
            _SettingsItem(
              icon: AppIcons.privacyTip,
              title: l10n.aboutPrivacyTitle,
              onTap: () => context.push('/profile/privacy'),
            ),
            _SettingsItem(
              icon: AppIcons.inventory2,
              title: 'Data & storage',
              onTap: () => context.push('/profile/data'),
            ),
            _SettingsItem(
              icon: AppIcons.notifications,
              title: l10n.notificationTitle,
              onTap: () => context.push('/notifications'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s16),
        _SettingsGroup(
          children: [
            _SettingsItem(
              icon: AppIcons.help,
              title: l10n.profileHelpTitle,
              onTap: () => context.push('/help'),
            ),
            _SettingsItem(
              icon: AppIcons.info,
              title: l10n.profileAboutTitle,
              onTap: () => context.push('/about'),
            ),
          ],
        ),
        const SizedBox(height: AppTokens.s32),
        SectionHeader(
          title: l10n.profileAssetsTitle,
        ),
        const SizedBox(height: AppTokens.s12),
        _AssetInventory(assets: state.userAssets),
        const SizedBox(height: AppTokens.s32),
        AppSecondaryButton(
          label: l10n.profileLogout,
          onPressed: () async {
            await ref.read(appControllerProvider.notifier).logout();
            if (context.mounted) context.go('/onboarding');
          },
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
    this.onAvatarTap,
  });

  final String name;
  final String email;
  final String target;
  final String level;
  final int xp;
  final int streak;
  final AppLocalizations l10n;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppTokens.s24),
        decoration: BoxDecoration(
          color: AppTokens.brandNavy,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        ),
        child: Column(
          children: [
            GestureDetector(
              onTap: onAvatarTap,
              child: const MascotImage(size: 72),
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
            Text(
              email,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: AppTokens.s4),
            Text(
              '$target · $level',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: AppTokens.s12),
            Wrap(
              spacing: AppTokens.s12,
              runSpacing: AppTokens.s12,
              alignment: WrapAlignment.center,
              children: [
                AppPill(
                  label: '$xp ${l10n.commonXP}',
                  variant: PillVariant.xp,
                  icon: AppIcons.bolt,
                ),
                AppPill(
                  label: l10n.profileStreakDays(streak),
                  variant: PillVariant.streak,
                  icon: AppIcons.localFireDepartment,
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
    return AppCard(
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
    return AppCard(
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
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              const Divider(
                height: 0.5,
                thickness: 0.5,
                indent: 56,
                color: AppTokens.hairline,
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
      borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s16,
            vertical: AppTokens.s12,
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 22),
              const SizedBox(width: AppTokens.s16),
              Expanded(child: Text(title, style: theme.textTheme.bodyMedium)),
              if (value != null)
                Text(
                  value!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const SizedBox(width: AppTokens.s4),
              Icon(
                AppIcons.chevronRight,
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

class _AssetInventory extends StatelessWidget {
  const _AssetInventory({required this.assets});

  final List<UserAsset> assets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (assets.isEmpty) {
      return AppCard(
        child: MascotEmptyState(
          title: l10n.profileAssetsEmpty,
        ),
      );
    }
    return AppCard(
      child: Column(
        children: [
          for (var index = 0; index < assets.length; index++) ...[
            _AssetRow(asset: assets[index]),
            if (index != assets.length - 1)
              const Divider(
                height: AppTokens.s16,
                thickness: 0.5,
                color: AppTokens.hairline,
              ),
          ],
        ],
      ),
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
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _assetColor(asset.rarity).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
          ),
          alignment: Alignment.center,
          child: Icon(
            _assetIcon(asset.category),
            color: _assetColor(asset.rarity),
            size: 20,
          ),
        ),
        const SizedBox(width: AppTokens.s12),
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
        return AppIcons.accountCircle;
      case 'profileBackground':
        return AppIcons.wallpaper;
      case 'badge':
        return AppIcons.workspacePremium;
      case 'title':
        return AppIcons.militaryTech;
      case 'cardSkin':
        return AppIcons.style;
      default:
        return AppIcons.autoAwesome;
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
