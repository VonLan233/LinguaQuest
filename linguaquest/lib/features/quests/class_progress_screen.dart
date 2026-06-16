import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/app_progress_bar.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class ClassProgressScreen extends StatelessWidget {
  const ClassProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = [
      (l10n.classTopicExamSignals, '92%', 'allocate'),
      (l10n.classTopicTravelBasics, '64%', 'itinerary'),
      (l10n.classTopicWorkplace, '38%', 'negotiate'),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/class-mode'),
        title: Text(l10n.classProgressTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: l10n.classProgressOverview,
              subtitle: l10n.classProgressSubtitle,
            ),
            const SizedBox(height: 16),
            for (final row in rows) _ClassProgressRow(row: row),
          ],
        ),
      ),
    );
  }
}

class _ClassProgressRow extends StatelessWidget {
  const _ClassProgressRow({required this.row});

  final (String, String, String) row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (int.tryParse(row.$2.replaceAll('%', '')) ?? 0) / 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.s12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.$1, style: theme.textTheme.titleMedium),
                      const SizedBox(height: 3),
                      Text(
                        AppLocalizations.of(
                          context,
                        ).classProgressWeakWord(row.$3),
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                AppPill(label: row.$2, variant: PillVariant.primary),
              ],
            ),
            const SizedBox(height: AppTokens.s12),
            AppProgressBar(value: percent),
          ],
        ),
      ),
    );
  }
}
