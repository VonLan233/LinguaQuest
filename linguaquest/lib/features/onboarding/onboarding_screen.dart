import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_card.dart';
import '../../core/widgets/section_header.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cards = [
      const _OnboardingCard(
        cue: '🖼',
        icon: Icons.image_search_outlined,
        title: 'Image word cards',
        body: 'Words carry meaning, examples, mastery, and visual cues.',
      ),
      const _OnboardingCard(
        cue: '🛤',
        icon: Icons.route_outlined,
        title: 'A clear path',
        body:
            'Short lessons decide what to learn next, so daily study stays simple.',
      ),
      const _OnboardingCard(
        cue: '🔁',
        icon: Icons.replay_outlined,
        title: 'Review at the right time',
        body: 'Weak words return sooner; mastered words wait longer.',
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.accentSurface(context),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Image.asset('lib/assets/image/icon_transparent.png'),
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: SectionHeader(
                    title: 'LinguaQuest',
                    subtitle:
                        'Bite-sized lessons, visual memory cards, and smart review.',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                PillLabel(label: '词境星球', icon: Icons.language_outlined),
                PillLabel(label: 'XP', icon: Icons.bolt, color: AppTheme.mango),
                PillLabel(
                  label: 'Streak',
                  icon: Icons.local_fire_department,
                  color: AppTheme.coral,
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              'Pick up where modern language apps work best',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final card in cards) ...[card, const SizedBox(height: 12)],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => context.go('/register'),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Create account'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.go('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Log in'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingCard extends StatelessWidget {
  const _OnboardingCard({
    required this.cue,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String cue;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return QuestCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ImageCueBadge(cue: cue, size: 68),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 18),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
