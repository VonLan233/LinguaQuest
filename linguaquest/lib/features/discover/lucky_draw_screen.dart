import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
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
      body: const SafeArea(child: _LotteryPanel()),
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
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppTokens.s20),
            children: [
              AppCard(
                padding: const EdgeInsets.all(AppTokens.s20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const ImageCueBadge(cue: '🎁', size: 52),
                        const SizedBox(width: AppTokens.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.luckyDrawCostLine(lotteryDrawCost),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppTokens.s4),
                              Text(
                                l10n.luckyDrawBalanceHint(user?.xp ?? 0),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.s12),
                    Wrap(
                      spacing: AppTokens.s8,
                      runSpacing: AppTokens.s8,
                      children: [
                        AppPill(
                          label: l10n.luckyDrawInventoryCount(inventoryCount),
                          variant: PillVariant.primary,
                          icon: AppIcons.inventory2,
                        ),
                        AppPill(
                          label: l10n.luckyDrawNoBoost,
                          variant: PillVariant.neutral,
                          icon: AppIcons.balance,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.s12),
              AppCard(child: _ProbabilityList(prizes: state.lotteryPrizes)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppTokens.s20,
            AppTokens.s12,
            AppTokens.s20,
            AppTokens.s16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  AppPrimaryButton(
                    onPressed: canDraw ? () => _draw(context, ref) : null,
                    icon: state.isLoading ? null : AppIcons.casino,
                    label: canDraw
                        ? l10n.luckyDrawNow
                        : l10n.luckyDrawInsufficient,
                  ),
                  if (state.isLoading)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if ((user?.xp ?? 0) < lotteryDrawCost) ...[
                const SizedBox(height: AppTokens.s8),
                Text(
                  l10n.luckyDrawShortfall(lotteryDrawCost - (user?.xp ?? 0)),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppTokens.s12),
              AppSecondaryButton(
                label: l10n.luckyDrawViewMyAssets,
                onPressed: () => context.go('/discover/assets'),
              ),
            ],
          ),
        ),
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
            const SizedBox(height: AppTokens.s8),
            Text(
              '${displayLotteryCategory(result.prize.category, l10n: l10n)} · '
              '${displayLotteryRarity(result.prize.rarity, l10n: l10n)}',
            ),
            const SizedBox(height: AppTokens.s8),
            Text(result.prize.description),
            const SizedBox(height: AppTokens.s12),
            Text(l10n.luckyDrawDeducted(result.balanceAfter, result.cost)),
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
                context.go('/discover/assets');
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
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    const categoryOrder = [
      'avatarFrame',
      'profileBackground',
      'badge',
      'title',
      'cardSkin',
      'fragment',
    ];
    final grouped = <String, List<LotteryPrize>>{};
    for (final prize in prizes) {
      grouped.putIfAbsent(prize.category, () => []).add(prize);
    }
    final orderedCategories = [
      ...categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !categoryOrder.contains(k)),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppTokens.s12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final category in orderedCategories) ...[
            Padding(
              padding: const EdgeInsets.only(
                top: AppTokens.s8,
                bottom: AppTokens.s4,
              ),
              child: Text(
                displayLotteryCategory(category, l10n: l10n),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            for (final prize in grouped[category]!)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prize.name,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    AppPill(
                      label: displayLotteryRarity(prize.rarity, l10n: l10n),
                      variant: _rarityVariant(prize.rarity),
                    ),
                    const SizedBox(width: AppTokens.s8),
                    Text(
                      '${_formatProbability(prize.probability)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

PillVariant _rarityVariant(String rarity) {
  return switch (rarity) {
    'rare' => PillVariant.primary,
    'uncommon' => PillVariant.xp,
    'comfort' => PillVariant.streak,
    _ => PillVariant.neutral,
  };
}

String _formatProbability(double probability) {
  if (probability % 1 == 0) return probability.toStringAsFixed(0);
  return probability.toString();
}
