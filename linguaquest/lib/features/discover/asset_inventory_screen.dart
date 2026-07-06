import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/ui_labels.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/mascot_empty_state.dart';
import '../../data/models/lottery.dart';
import '../../l10n/generated/app_localizations.dart';

class AssetInventoryScreen extends ConsumerWidget {
  const AssetInventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final assets = ref.watch(
      appControllerProvider.select((s) => s.userAssets),
    );

    final totalOwned =
        assets.fold<int>(0, (sum, asset) => sum + asset.quantity);
    final totalFragments = assets.fold<int>(
      0,
      (sum, asset) => sum + asset.totalFragments,
    );

    // Group by category in canonical order
    const categoryOrder = [
      'avatarFrame',
      'profileBackground',
      'badge',
      'title',
      'cardSkin',
      'fragment',
    ];
    final grouped = <String, List<UserAsset>>{};
    for (final asset in assets) {
      grouped.putIfAbsent(asset.category, () => []).add(asset);
    }

    final orderedCategories = [
      ...categoryOrder.where(grouped.containsKey),
      ...grouped.keys.where((k) => !categoryOrder.contains(k)),
    ];

    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(
          fallbackLocation: '/discover/lucky-draw',
        ),
        title: Text(l10n.assetInventoryTitle),
      ),
      body: SafeArea(
        child: assets.isEmpty
            ? MascotEmptyState(
                title: l10n.assetInventoryEmpty,
              )
            : ListView(
                padding: const EdgeInsets.all(AppTokens.s20),
                children: [
                  // Header summary card
                  AppCard(
                    padding: const EdgeInsets.all(AppTokens.s16),
                    child: Wrap(
                      spacing: AppTokens.s8,
                      runSpacing: AppTokens.s8,
                      children: [
                        AppPill(
                          label: l10n.assetInventoryTotalOwned(totalOwned),
                          variant: PillVariant.primary,
                        ),
                        AppPill(
                          label: l10n.assetInventoryTotalFragments(
                            totalFragments,
                          ),
                          variant: PillVariant.xp,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.s16),
                  // Category sections
                  for (final category in orderedCategories) ...[
                    _CategorySection(
                      category: category,
                      assets: grouped[category]!,
                    ),
                    const SizedBox(height: AppTokens.s12),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.assets,
  });

  final String category;
  final List<UserAsset> assets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppTokens.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayLotteryCategory(category, l10n: l10n),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppTokens.s8),
          for (final asset in assets) _AssetRow(asset: asset),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset});

  final UserAsset asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  asset.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${displayLotteryCategory(asset.category, l10n: l10n)} · '
                  '${displayLotteryRarity(asset.rarity, l10n: l10n)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (asset.category == 'fragment' || asset.rarity == 'comfort') ...[
                  const SizedBox(height: 2),
                  Text(
                    l10n.assetInventoryTotalFragments(asset.totalFragments),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppTokens.s8),
          if (asset.quantity > 1)
            AppPill(
              label: l10n.assetInventoryQuantityBadge(asset.quantity),
              variant: PillVariant.streak,
            ),
        ],
      ),
    );
  }
}
