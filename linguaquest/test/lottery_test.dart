import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/lottery.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/lottery_repository.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/services/local_notification_service.dart';
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

  test('bootstrap tolerates lottery data failures', () async {
    final now = DateTime(2026, 6, 3);
    final profile = UserProfile(
      uid: 'lottery-failure-user',
      name: 'Ava',
      email: 'ava@lingua.quest',
      targetExam: 'IELTS',
      level: 'Intermediate',
      dailyGoal: 12,
      xp: 120,
      streak: 4,
      createdAt: now,
      updatedAt: now,
    );
    SharedPreferences.setMockInitialValues({
      'linguaquest.profile': jsonEncode(profile.toJson()),
    });
    final container = ProviderContainer(
      overrides: [
        lotteryRepositoryProvider.overrideWithValue(
          _FailingLotteryRepository(),
        ),
        localNotificationServiceProvider.overrideWithValue(
          _NoopLocalNotificationService(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(appControllerProvider.notifier).bootstrap();
    final state = container.read(appControllerProvider);

    expect(state.isBootstrapped, isTrue);
    expect(state.user?.uid, 'lottery-failure-user');
    expect(state.lotteryPrizes, isEmpty);
    expect(state.userAssets, isEmpty);
    expect(state.errorMessage, isNull);
  });
}

class _FailingLotteryRepository implements LotteryRepository {
  @override
  Future<List<LotteryPrize>> prizePool() async {
    throw StateError('lottery service unavailable');
  }

  @override
  Future<List<UserAsset>> assets(String uid) async {
    throw StateError('lottery service unavailable');
  }

  @override
  Future<LotteryDrawResponse> draw({
    required String uid,
    required int currentXp,
  }) async {
    throw StateError('lottery service unavailable');
  }
}

class _NoopLocalNotificationService implements LocalNotificationService {
  @override
  Future<void> initialize({
    required void Function(String route) onSelectRoute,
  }) async {}

  @override
  Future<void> scheduleDailyStudyReminder({
    required bool enabled,
    required int hour,
    required int minute,
  }) async {}

  @override
  Future<void> scheduleReviewDueReminder({required int dueCount}) async {}
}
