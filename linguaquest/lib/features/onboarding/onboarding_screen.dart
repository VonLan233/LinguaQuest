import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_icons.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/mascot_image.dart';
import '../../l10n/generated/app_localizations.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final steps = [
      _OnboardingStepData(
        cue: '🖼',
        icon: AppIcons.imageSearch,
        title: l10n.onboardingFeatureImageCards,
        body: l10n.onboardingFeatureImageCardsDesc,
      ),
      _OnboardingStepData(
        cue: '🛤',
        icon: AppIcons.route,
        title: l10n.onboardingFeaturePath,
        body: l10n.onboardingFeaturePathDesc,
      ),
      _OnboardingStepData(
        cue: '🔁',
        icon: AppIcons.replay,
        title: l10n.onboardingFeatureReview,
        body: l10n.onboardingFeatureReviewDesc,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.s24,
            vertical: AppTokens.s32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppTokens.s24),
              const Center(child: MascotImage(size: 96)),
              const SizedBox(height: AppTokens.s20),
              Text(
                l10n.onboardingTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: AppTokens.s8),
              Text(
                l10n.onboardingTagline,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTokens.s32),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.s20,
                  vertical: AppTokens.s8,
                ),
                child: _OnboardingStepList(steps: steps),
              ),
              const SizedBox(height: AppTokens.s32),
              AppPrimaryButton(
                onPressed: () => context.go('/register'),
                icon: AppIcons.personAdd,
                label: l10n.onboardingRegisterButton,
              ),
              const SizedBox(height: AppTokens.s12),
              AppSecondaryButton(
                onPressed: () => context.go('/login'),
                icon: AppIcons.login,
                label: l10n.commonLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingStepList extends StatelessWidget {
  const _OnboardingStepList({required this.steps});

  final List<_OnboardingStepData> steps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < steps.length; index++) ...[
          _OnboardingStepRow(step: steps[index]),
          if (index != steps.length - 1)
            Divider(
              height: 18,
              color: Theme.of(
                context,
              ).colorScheme.outlineVariant.withValues(alpha: 0.7),
            ),
        ],
      ],
    );
  }
}

class _OnboardingStepRow extends StatelessWidget {
  const _OnboardingStepRow({required this.step});

  final _OnboardingStepData step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ImageCueBadge(cue: step.cue, size: 62),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Icon(
                    step.icon,
                    color: theme.colorScheme.primary,
                    size: 18,
                  ),
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
                  step.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(step.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStepData {
  const _OnboardingStepData({
    required this.cue,
    required this.icon,
    required this.title,
    required this.body,
  });

  final String cue;
  final IconData icon;
  final String title;
  final String body;
}
