import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:linguaquest/data/repositories/mock_repositories.dart';

void main() {
  test('MockLotteryRepository.prizePool returns 15 prizes', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockLotteryRepository();
    final prizes = await repo.prizePool();

    expect(prizes.length, 15);
  });

  test('MockLotteryRepository prize pool probabilities sum to 100', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockLotteryRepository();
    final prizes = await repo.prizePool();

    final total = prizes.fold<double>(0, (sum, p) => sum + p.probability);
    expect(total, 100.0);
  });

  test('MockLotteryRepository prize pool covers all 6 categories', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockLotteryRepository();
    final prizes = await repo.prizePool();

    final categories = prizes.map((p) => p.category).toSet();
    expect(categories, containsAll([
      'avatarFrame',
      'profileBackground',
      'badge',
      'title',
      'cardSkin',
      'fragment',
    ]));
  });

  test('MockLotteryRepository prize pool has no learning or score boost',
      () async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockLotteryRepository();
    final prizes = await repo.prizePool();

    final categories = prizes.map((p) => p.category).toSet();
    expect(categories, isNot(contains('learningBoost')));
    expect(categories, isNot(contains('scoreBoost')));
  });

  test('MockLotteryRepository all prize ids are unique', () async {
    SharedPreferences.setMockInitialValues({});
    final repo = MockLotteryRepository();
    final prizes = await repo.prizePool();

    final ids = prizes.map((p) => p.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
