import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/lottery.dart';
import '../../data/repositories/lottery_repository.dart';
import '../../l10n/generated/app_localizations.dart';

class LuckyDrawScreen extends ConsumerWidget {
  const LuckyDrawScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/discover'),
        title: Text(l10n.discoverLuckyDraw),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: const [_LotteryPanel()],
        ),
      ),
    );
  }
}

class _LotteryPanel extends ConsumerWidget {
  const _LotteryPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final canDraw =
        user != null && user.xp >= lotteryDrawCost && !state.isLoading;
    final inventoryCount = state.userAssets.fold<int>(
      0,
      (sum, asset) => sum + asset.quantity,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ImageCueBadge(cue: '🎁', size: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.luckyDrawCostLine(lotteryDrawCost),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.luckyDrawBalanceHint(user?.xp ?? 0),
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            PillLabel(
              label: l10n.luckyDrawInventoryCount(inventoryCount),
              icon: Icons.inventory_2_outlined,
              color: AppTheme.teal,
            ),
            PillLabel(
              label: l10n.luckyDrawNoBoost,
              icon: Icons.balance_outlined,
              color: AppTheme.coral,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProbabilityList(prizes: state.lotteryPrizes),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: canDraw ? () => _draw(context, ref) : null,
          icon: state.isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.casino_outlined),
          label: Text(canDraw ? l10n.luckyDrawNow : l10n.luckyDrawInsufficient),
        ),
        if ((user?.xp ?? 0) < lotteryDrawCost) ...[
          const SizedBox(height: 8),
          Text(
            l10n.luckyDrawShortfall(lotteryDrawCost - (user?.xp ?? 0)),
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Future<void> _draw(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .drawLottery();
    if (!context.mounted) return;
    final state = ref.read(appControllerProvider);
    final result = state.lastLotteryResult;
    if (!succeeded || result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? l10n.luckyDrawFailed)),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.luckyDrawSuccessTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.luckyDrawReward(result.prize.name)),
            const SizedBox(height: 6),
            Text(
              '${displayLotteryCategory(result.prize.category, l10n: l10n)} · '
              '${displayLotteryRarity(result.prize.rarity, l10n: l10n)}',
            ),
            const SizedBox(height: 6),
            Text(result.prize.description),
            const SizedBox(height: 10),
            Text(l10n.luckyDrawDeducted(result.cost, result.balanceAfter)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.luckyDrawKeepLooking),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                context.go('/profile');
              }
            },
            child: Text(l10n.luckyDrawViewAssets),
          ),
        ],
      ),
    );
  }
}

class _ProbabilityList extends StatelessWidget {
  const _ProbabilityList({required this.prizes});

  final List<LotteryPrize> prizes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (prizes.isEmpty) {
      return Text(
        l10n.luckyDrawPoolLoading,
        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    return Column(
      children: [
        for (final prize in prizes)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${prize.name} · '
                    '${displayLotteryCategory(prize.category, l10n: l10n)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${displayLotteryRarity(prize.rarity, l10n: l10n)} '
                  '${_formatProbability(prize.probability)}%',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

String _formatProbability(double probability) {
  if (probability % 1 == 0) return probability.toStringAsFixed(0);
  return probability.toString();
}
