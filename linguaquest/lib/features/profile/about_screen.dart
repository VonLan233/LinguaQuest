import 'package:flutter/material.dart';

import '../../core/widgets/fallback_back_button.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/profile'),
        title: const Text('About'),
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
            const Text('词境星球 · Version 1.0.0'),
            const SizedBox(height: 20),
            const Text(
              'LinguaQuest combines image word cards, guided lesson paths, spaced review, XP, streaks, and custom vocabulary CRUD into one mobile-first learning app.',
            ),
            const SizedBox(height: 20),
            const ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Project Goal'),
              subtitle: Text(
                'Help learners build a daily English habit through short lessons, mistake recovery, and visible progress.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.groups_outlined),
              title: Text('Development Team'),
              subtitle: Text(
                'ASM2 Mobile team. Built as a product-oriented Flutter learning app prototype.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.extension_outlined),
              title: Text('Core Experience'),
              subtitle: Text(
                'Goal planning, visual vocabulary, quiz practice, review scheduling, and personal word cards.',
              ),
            ),
            const ListTile(
              leading: Icon(Icons.privacy_tip_outlined),
              title: Text('Privacy'),
              subtitle: Text(
                'Custom words and study sessions are scoped to the signed-in user.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
