import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../l10n/generated/app_localizations.dart';
import '../reading/reading_labels.dart';

class DataSettingsScreen extends ConsumerWidget {
  const DataSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scopeLabel = ref.watch(
      appControllerProvider.select(
        (s) => readingLevelLabel(s.currentLanguage, s.currentWordBookId),
      ),
    );
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/settings'),
        title: Text(AppLocalizations.of(context).dataAccountTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            // §7 (P4e): offline content status + manual refresh.
            AppCard(
              key: const ValueKey('offline-content-card'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.offline_pin_outlined),
                    title: const Text('Available offline'),
                    subtitle: Text('Current scope: $scopeLabel'),
                  ),
                  const Divider(height: AppTokens.s16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: const ValueKey('offline-refresh-button'),
                      onPressed: () => _refreshOfflineContent(context, ref),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh content'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.s16),
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear all data and restart'),
                    subtitle: const Text(
                      'Remove all local app data and return to a fresh start',
                    ),
                    trailing: const Icon(Icons.restart_alt),
                    onTap: () => _confirmClearAllData(context, ref),
                  ),
                  const Divider(height: AppTokens.s16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear AI history'),
                    subtitle: const Text('Remove all AI interaction history'),
                    trailing: const Icon(Icons.history_outlined),
                    onTap: () => _confirmClearAiHistory(context, ref),
                  ),
                  const Divider(height: AppTokens.s16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Delete account',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently remove your account and all data',
                    ),
                    trailing: Icon(
                      Icons.warning_amber_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    onTap: () => _confirmDeleteAccount(context, ref),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshOfflineContent(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final ok = await ref
        .read(appControllerProvider.notifier)
        .refreshOfflineContent();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Offline content refreshed' : 'Could not refresh content',
        ),
      ),
    );
  }

  Future<void> _confirmClearAllData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear all data and restart'),
        content: const Text(
          'This will remove all local app data, sign you out, and restart from a fresh state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear and restart'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(appControllerProvider.notifier)
          .clearAllDataAndRestart();
      if (context.mounted) {
        if (ok) {
          context.go('/onboarding');
        } else {
          final error = ref.read(appControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Could not clear app data')),
          );
        }
      }
    }
  }

  Future<void> _confirmClearAiHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = ref.read(appControllerProvider);
    final historyIds = controller.aiHistory.map((e) => e.id).toList();
    if (historyIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No AI history to clear')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear AI history'),
        content: Text(
          'This will permanently delete ${historyIds.length} AI interaction record(s). This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final notifier = ref.read(appControllerProvider.notifier);
      await notifier.clearAiHistory();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('AI history cleared')));
      }
    }
  }

  Future<void> _confirmDeleteAccount(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete account',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: const Text(
          'This will permanently delete your account, clear this device, and cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(appControllerProvider.notifier)
          .deleteAccountAndRestart();
      if (context.mounted) {
        if (ok) {
          context.go('/onboarding');
        } else {
          final error = ref.read(appControllerProvider).errorMessage;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error ?? 'Could not delete account')),
          );
        }
      }
    }
  }
}
