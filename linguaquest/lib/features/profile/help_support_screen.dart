import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const faqs = [
      (
        'How are reviews scheduled?',
        'A word moves between mastery 0-5. Higher mastery means a longer nextReviewAt interval.',
      ),
      (
        'Can I add my own words?',
        'Yes. Open Wordbook, then Custom Words, and use Add to create a card.',
      ),
      (
        'Is AI tutor live?',
        'Not yet. The current screen is a mock interaction for future API integration.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('Help / Support'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final faq in faqs)
              Card(
                child: ExpansionTile(
                  title: Text(faq.$1),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  children: [Text(faq.$2)],
                ),
              ),
            const SizedBox(height: 12),
            const ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('Contact support'),
              subtitle: Text('support@lingua.quest'),
            ),
          ],
        ),
      ),
    );
  }
}
