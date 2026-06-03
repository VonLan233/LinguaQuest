import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/repositories/lottery_repository.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'mock lottery draw deducts XP, stores asset, and emits notification',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockLotteryRepository();

      final response = await repo.draw(uid: 'lottery-user', currentXp: 120);
      final assets = await repo.assets('lottery-user');

      expect(response.result.cost, lotteryDrawCost);
      expect(response.result.balanceAfter, 90);
      expect(response.result.prize.category, isNot('learningBoost'));
      expect(response.result.prize.category, isNot('scoreBoost'));
      expect(assets, hasLength(1));
      expect(assets.single.prizeId, response.result.prize.id);
      expect(assets.single.quantity, 1);
      expect(response.notifications.single.title, '积分抽奖结果');
      expect(response.notifications.single.targetRoute, '/profile');
    },
  );

  test('mock lottery draw accumulates repeated prize quantities', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockLotteryRepository();
    final pool = await repo.prizePool();

    for (var index = 0; index < pool.length * 8; index++) {
      await repo.draw(uid: 'repeat-user', currentXp: 999);
    }

    final assets = await repo.assets('repeat-user');
    final totalQuantity = assets.fold<int>(
      0,
      (total, asset) => total + asset.quantity,
    );

    expect(totalQuantity, pool.length * 8);
    expect(assets.any((asset) => asset.quantity > 1), isTrue);
  });

  test(
    'mock lottery draw rejects insufficient XP before writing inventory',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockLotteryRepository();

      expect(
        () => repo.draw(uid: 'poor-user', currentXp: lotteryDrawCost - 1),
        throwsStateError,
      );
      expect(await repo.assets('poor-user'), isEmpty);
    },
  );
}
