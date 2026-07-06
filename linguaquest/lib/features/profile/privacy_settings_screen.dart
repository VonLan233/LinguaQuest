import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../data/models/user_privacy.dart';

class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final privacy = ref.watch(
      appControllerProvider.select((s) => s.privacySettings),
    );
    final notifier = ref.read(appControllerProvider.notifier);

    void update(UserPrivacySettings updated) =>
        notifier.updatePrivacySettings(updated);

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/settings'),
        title: const Text('Privacy Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            AppCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show learning stats publicly'),
                    subtitle: const Text(
                      'Allow others to see your XP and progress',
                    ),
                    value: privacy.publicStats,
                    onChanged: (v) =>
                        update(privacy.copyWith(publicStats: v)),
                  ),
                  const Divider(height: AppTokens.s16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show streak publicly'),
                    subtitle: const Text(
                      'Allow others to see your daily streak count',
                    ),
                    value: privacy.publicStreak,
                    onChanged: (v) =>
                        update(privacy.copyWith(publicStreak: v)),
                  ),
                  const Divider(height: AppTokens.s16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show wordbook progress publicly'),
                    subtitle: const Text(
                      'Allow others to see your wordbook completion',
                    ),
                    value: privacy.publicWordbook,
                    onChanged: (v) =>
                        update(privacy.copyWith(publicWordbook: v)),
                  ),
                  const Divider(height: AppTokens.s16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show posts publicly'),
                    subtitle: const Text(
                      'Allow others to see your community posts',
                    ),
                    value: privacy.publicPosts,
                    onChanged: (v) =>
                        update(privacy.copyWith(publicPosts: v)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            Text(
              'These settings control what other users can see on your public profile.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
