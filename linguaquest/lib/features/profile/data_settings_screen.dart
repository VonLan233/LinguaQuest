import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/fallback_back_button.dart';

class DataSettingsScreen extends ConsumerWidget {
  const DataSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/settings'),
        title: const Text('Data & Account'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTokens.s20),
          children: [
            AppCard(
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear local cache'),
                    subtitle: const Text(
                      'Remove locally stored data and sign out',
                    ),
                    trailing: const Icon(Icons.delete_outline),
                    onTap: () => _confirmClearCache(context, ref),
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
                    title: const Text('Export account data'),
                    subtitle: const Text('Download a copy of your data'),
                    trailing: const Icon(Icons.download_outlined),
                    onTap: () => _showExportInfo(context),
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
                    onTap: () => _confirmDeleteAccount(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmClearCache(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear local cache'),
        content: const Text(
          'This will remove all locally stored data and sign you out. Your account data stored on the server will not be affected.',
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
      await ref.read(appControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  void _showExportInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export account data'),
        content: const Text('Not available in this version.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearAiHistory(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final controller = ref.read(appControllerProvider);
    final historyIds = controller.aiHistory.map((e) => e.id).toList();
    if (historyIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No AI history to clear')),
      );
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
      for (final id in historyIds) {
        await notifier.deleteAiHistory(id);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('AI history cleared')),
        );
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete account',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        content: const Text(
          'Account deletion is not yet available in-app. '
          'To permanently delete your account and all associated data, '
          'please contact support at support@linguaquest.app. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
