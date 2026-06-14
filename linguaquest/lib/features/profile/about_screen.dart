import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: Text(l10n.profileAboutTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'LinguaQuest',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(l10n.aboutVersion),
            const SizedBox(height: 20),
            Text(l10n.aboutIntro),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.aboutGoalTitle),
              subtitle: Text(l10n.aboutGoalSubtitle),
            ),
            ListTile(
              leading: const Icon(Icons.groups_outlined),
              title: Text(l10n.aboutTeamTitle),
              subtitle: Text(l10n.aboutTeamSubtitle),
            ),
            ListTile(
              leading: const Icon(Icons.extension_outlined),
              title: Text(l10n.aboutCoreTitle),
              subtitle: Text(l10n.aboutCoreSubtitle),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.aboutPrivacyTitle),
              subtitle: Text(l10n.aboutPrivacySubtitle),
            ),
          ],
        ),
      ),
    );
  }
}
