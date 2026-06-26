import 'package:linguaquest_server/src/lottery_policy.dart';
import 'package:test/test.dart';

void main() {
  test('lottery prize seed is transparent and decorative only', () {
    final probabilityTotal = lotteryPrizeSeed.fold<num>(
      0,
      (total, prize) => total + (prize['probability'] as num),
    );

    expect(lotteryDrawCost, 30);
    expect(probabilityTotal, 100);
    expect(
      lotteryPrizeSeed.map((prize) => prize['category']),
      containsAll([
        'avatarFrame',
        'profileBackground',
        'badge',
        'title',
        'cardSkin',
        'fragment',
      ]),
    );
    expect(
      lotteryPrizeSeed.map((prize) => prize['category']),
      isNot(contains('learningBoost')),
    );
    expect(
      lotteryPrizeSeed.map((prize) => prize['category']),
      isNot(contains('scoreBoost')),
    );
    expect(lotteryPrizeSeed.length, 15);
    expect(
      lotteryPrizeSeed.map((prize) => prize['id']).toSet().length,
      15,
    );
  });

  test(
    'lottery chooser ignores inactive prizes and falls back to seed pool',
    () {
      final activePrize = {
        'id': 'active-prize',
        'name': 'Active Prize',
        'category': 'badge',
        'rarity': 'common',
        'description': 'Decorative only.',
        'probability': 100,
        'fragment_value': 1,
        'is_active': true,
      };
      final inactivePrize = {
        ...activePrize,
        'id': 'inactive-prize',
        'is_active': false,
      };
      final camelInactivePrize = {
        'id': 'camel-inactive-prize',
        'name': 'Camel Inactive Prize',
        'category': 'badge',
        'rarity': 'common',
        'description': 'Decorative only.',
        'probability': 100,
        'fragment_value': 1,
        'isActive': false,
      };

      expect(
        chooseLotteryPrize([inactivePrize, activePrize])['id'],
        'active-prize',
      );
      expect(
        lotteryPrizeSeed.map((prize) => prize['id']),
        contains(chooseLotteryPrize([inactivePrize])['id']),
      );
      expect(
        lotteryPrizeSeed.map((prize) => prize['id']),
        contains(chooseLotteryPrize([camelInactivePrize])['id']),
      );
      expect(chooseLotteryPrize([inactivePrize])['fragmentValue'], isA<int>());
    },
  );
}
