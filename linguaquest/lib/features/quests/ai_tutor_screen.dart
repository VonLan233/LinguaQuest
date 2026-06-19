import 'package:flutter/material.dart';

import 'package:linguaquest/core/theme/app_icons.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/section_header.dart';
import '../../l10n/generated/app_localizations.dart';

class AiTutorScreen extends StatefulWidget {
  const AiTutorScreen({super.key});

  @override
  State<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends State<AiTutorScreen> {
  final _promptController = TextEditingController();
  bool _promptInitialized = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_promptInitialized) {
      _promptController.text = l10n.aiTutorSamplePrompt;
      _promptInitialized = true;
    }
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/quest'),
        title: Text(l10n.questAiTutor),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionHeader(
              title: l10n.aiTutorInstantFeedback,
              subtitle: l10n.aiTutorSubtitle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: l10n.aiTutorInputLabel,
                prefixIcon: const Icon(AppIcons.smartToy),
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    AppIcons.psychologyAlt,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AppTokens.s12),
                  Expanded(
                    child: Text(
                      l10n.aiTutorSampleAnswer,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
