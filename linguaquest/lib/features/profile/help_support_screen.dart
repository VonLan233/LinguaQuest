import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/quest_list_row.dart';
import '../../core/widgets/quest_panel.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
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
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            QuestPanel(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.s8,
                vertical: AppTokens.s4,
              ),
              child: Theme(
                data: theme.copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: [
                    for (final faq in faqs)
                      ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.s12,
                        ),
                        title: Text(
                          faq.$1,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          AppTokens.s12,
                          0,
                          AppTokens.s12,
                          AppTokens.s16,
                        ),
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              faq.$2,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTokens.s20),
            SectionHeader(title: l10n.helpContactSupport),
            const SizedBox(height: AppTokens.s12),
            QuestPanel(
              padding: const EdgeInsets.all(AppTokens.s8),
              child: QuestListRow(
                icon: Icons.mail_outline,
                iconColor: AppTokens.azure,
                title: l10n.helpContactSupport,
                subtitle: 'support@lingua.quest',
                showChevron: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
