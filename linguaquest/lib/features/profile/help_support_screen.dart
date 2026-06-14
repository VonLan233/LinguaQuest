import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final faqs = [
      (l10n.helpFaqReviewScheduleQ, l10n.helpFaqReviewScheduleA),
      (l10n.helpFaqCustomWordsQ, l10n.helpFaqCustomWordsA),
      (l10n.helpFaqAiTutorQ, l10n.helpFaqAiTutorA),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: Text(l10n.profileHelpTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final faq in faqs)
              ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(faq.$1),
                childrenPadding: const EdgeInsets.only(bottom: 16),
                children: [
                  Align(alignment: Alignment.centerLeft, child: Text(faq.$2)),
                ],
              ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: Text(l10n.helpContactSupport),
              subtitle: const Text('support@lingua.quest'),
            ),
          ],
        ),
      ),
    );
  }
}
