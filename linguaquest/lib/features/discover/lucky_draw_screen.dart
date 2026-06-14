import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
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
    final theme = Theme.of(context);
    final state = ref.watch(appControllerProvider);
    final user = state.user;
    final canDraw =
        user != null && user.xp >= lotteryDrawCost && !state.isLoading;
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
                    '消耗 $lotteryDrawCost XP 抽一次',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '当前余额 ${user?.xp ?? 0} XP；奖品包含头像框、主页背景、徽章、称号、卡片皮肤和安慰碎片。',
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
              label:
                  '库存 ${state.userAssets.fold<int>(0, (sum, asset) => sum + asset.quantity)} 件',
              icon: Icons.inventory_2_outlined,
              color: AppTheme.teal,
            ),
            const PillLabel(
              label: '无学习加成',
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
          label: Text(canDraw ? '立即抽奖' : '余额不足，先完成任务'),
        ),
        if ((user?.xp ?? 0) < lotteryDrawCost) ...[
          const SizedBox(height: 8),
          Text(
            '还差 ${lotteryDrawCost - (user?.xp ?? 0)} XP。完成新学、复习或错词清理即可领取积分。',
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  Future<void> _draw(BuildContext context, WidgetRef ref) async {
    final succeeded = await ref
        .read(appControllerProvider.notifier)
        .drawLottery();
    if (!context.mounted) return;
    final state = ref.read(appControllerProvider);
    final result = state.lastLotteryResult;
    if (!succeeded || result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage ?? '抽奖失败，请稍后重试')),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('抽奖成功'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('获得：${result.prize.name}'),
            const SizedBox(height: 6),
            Text('${result.prize.categoryLabel} · ${result.prize.rarityLabel}'),
            const SizedBox(height: 6),
            Text(result.prize.description),
            const SizedBox(height: 10),
            Text('已扣除 ${result.cost} XP，剩余 ${result.balanceAfter} XP。'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('继续看看'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (context.mounted) {
                context.go('/profile');
              }
            },
            child: const Text('查看个人资产'),
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
    final theme = Theme.of(context);
    if (prizes.isEmpty) {
      return Text(
        '奖池加载中：头像框、主页背景、学习徽章、训练场称号、卡片皮肤、安慰碎片。',
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
                    '${prize.name} · ${prize.categoryLabel}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${prize.rarityLabel} ${_formatProbability(prize.probability)}%',
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
