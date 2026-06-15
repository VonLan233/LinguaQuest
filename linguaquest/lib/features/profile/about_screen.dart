import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/brand_hero_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_list_row.dart';
import '../../core/widgets/quest_panel.dart';
import '../../l10n/generated/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: Text(l10n.profileAboutTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            BrandHeroCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LinguaQuest',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: AppTokens.s8),
                  Text(
                    l10n.aboutVersion,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            QuestPanel(
              padding: const EdgeInsets.all(AppTokens.s20),
              child: Text(
                l10n.aboutIntro,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            QuestPanel(
              padding: const EdgeInsets.all(AppTokens.s8),
              child: Column(
                children: [
                  QuestListRow(
                    icon: Icons.flag_outlined,
                    iconColor: AppTokens.azure,
                    title: l10n.aboutGoalTitle,
                    subtitle: l10n.aboutGoalSubtitle,
                    showChevron: false,
                  ),
                  QuestListRow(
                    icon: Icons.groups_outlined,
                    iconColor: AppTokens.successColor(context),
                    title: l10n.aboutTeamTitle,
                    subtitle: l10n.aboutTeamSubtitle,
                    showChevron: false,
                  ),
                  QuestListRow(
                    icon: Icons.extension_outlined,
                    iconColor: AppTokens.mangoColor(context),
                    title: l10n.aboutCoreTitle,
                    subtitle: l10n.aboutCoreSubtitle,
                    showChevron: false,
                  ),
                  QuestListRow(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppTokens.coralColor(context),
                    title: l10n.aboutPrivacyTitle,
                    subtitle: l10n.aboutPrivacySubtitle,
                    showChevron: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
