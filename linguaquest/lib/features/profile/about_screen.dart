import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final infos = <(IconData, Color, String, String)>[
      (
        Icons.flag_outlined,
        AppTokens.azure,
        l10n.aboutGoalTitle,
        l10n.aboutGoalSubtitle,
      ),
      (
        Icons.groups_outlined,
        AppTokens.successColor(context),
        l10n.aboutTeamTitle,
        l10n.aboutTeamSubtitle,
      ),
      (
        Icons.extension_outlined,
        AppTokens.mangoColor(context),
        l10n.aboutCoreTitle,
        l10n.aboutCoreSubtitle,
      ),
      (
        Icons.privacy_tip_outlined,
        AppTokens.coralColor(context),
        l10n.aboutPrivacyTitle,
        l10n.aboutPrivacySubtitle,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: Text(l10n.profileAboutTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            AppCard(
              padding: EdgeInsets.zero,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTokens.s20),
                decoration: BoxDecoration(
                  color: AppTokens.brandNavy,
                  borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                ),
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
            ),
            const SizedBox(height: AppTokens.s20),
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s20),
              child: Text(l10n.aboutIntro, style: theme.textTheme.bodyMedium),
            ),
            const SizedBox(height: AppTokens.s16),
            AppCard(
              padding: const EdgeInsets.all(AppTokens.s16),
              child: Column(
                children: [
                  for (var i = 0; i < infos.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppTokens.s16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(infos[i].$1, color: infos[i].$2),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                infos[i].$3,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                infos[i].$4,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
