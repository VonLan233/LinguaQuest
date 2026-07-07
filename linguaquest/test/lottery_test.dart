import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/app_notification.dart';
import 'package:linguaquest/data/models/lottery.dart';
import 'package:linguaquest/data/models/user_profile.dart';
import 'package:linguaquest/data/repositories/auth_repository.dart';
import 'package:linguaquest/data/repositories/lottery_repository.dart';
import 'package:linguaquest/data/repositories/mock_repositories.dart';
import 'package:linguaquest/data/repositories/notification_repository.dart';
import 'package:linguaquest/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'mock lottery draw deducts XP, stores asset, and emits notification',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repo = MockLotteryRepository();
      final profile = UserProfile.demo().copyWith(uid: 'lottery-user', xp: 120);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'linguaquest.profile',
        jsonEncode(profile.toJson()),
      );

      final response = await repo.draw(uid: 'lottery-user', currentXp: 120);
      final assets = await repo.assets('lottery-user');
      final storedProfile = UserProfile.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(prefs.getString('linguaquest.profile')!) as Map,
        ),
      );

      expect(response.result.cost, lotteryDrawCost);
      expect(response.result.balanceAfter, 90);
      expect(response.result.createdAt.isUtc, isTrue);
      expect(response.user?.xp, 90);
      expect(response.user?.updatedAt.isUtc, isTrue);
      expect(storedProfile.xp, 90);
      expect(storedProfile.updatedAt.isUtc, isTrue);
      expect(response.result.prize.category, isNot('learningBoost'));
      expect(response.result.prize.category, isNot('scoreBoost'));
      expect(assets, hasLength(1));
      expect(assets.single.prizeId, response.result.prize.id);
      expect(assets.single.quantity, 1);
      expect(assets.single.acquiredAt.isUtc, isTrue);
      expect(assets.single.updatedAt.isUtc, isTrue);
      expect(response.notifications.single.title, 'Lucky draw result');
      expect(response.notifications.single.targetRoute, '/profile');
      expect(response.notifications.single.createdAt.isUtc, isTrue);
    },
  );

  test('lottery models parse snake case API fields', () {
    final prize = LotteryPrize.fromJson({
      'id': 'snake-prize',
      'name': 'Snake Prize',
      'category': 'badge',
      'rarity': 'common',
      'description': 'Decorative only.',
      'probability': '12.5',
      'fragment_value': 7,
      'is_active': false,
    });
    final acquiredAt = DateTime.utc(2026, 6, 3, 1);
    final updatedAt = DateTime.utc(2026, 6, 3, 2);
    final asset = UserAsset.fromJson({
      'id': 'asset-1',
      'uid': 'user-1',
      'prize_id': 'snake-prize',
      'category': 'badge',
      'rarity': 'common',
      'name': 'Snake Prize',
      'description': 'Decorative only.',
      'quantity': '2',
      'fragment_value': 7,
      'acquired_at': acquiredAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    });

    expect(prize.fragmentValue, 7);
    expect(prize.isActive, isFalse);
    expect(asset.prizeId, 'snake-prize');
    expect(asset.categoryLabel, 'Learning badge');
    expect(asset.quantity, 2);
    expect(asset.fragmentValue, 7);
    expect(asset.acquiredAt, acquiredAt);
    expect(asset.updatedAt, updatedAt);
  });

  test('lottery draw result parses snake case draw fields', () {
    final createdAt = DateTime.utc(2026, 6, 3, 3);
    final result = LotteryDrawResult.fromJson({
      'draw': {
        'id': 'draw-1',
        'cost': 30,
        'balance_after': 90,
        'created_at': createdAt.toIso8601String(),
      },
      'prize': {
        'id': 'snake-prize',
        'name': 'Snake Prize',
        'fragment_value': 7,
      },
      'asset': {
        'id': 'asset-1',
        'uid': 'user-1',
        'prize_id': 'snake-prize',
        'fragment_value': 7,
        'acquired_at': createdAt.toIso8601String(),
        'updated_at': createdAt.toIso8601String(),
      },
    });

    expect(result.drawId, 'draw-1');
    expect(result.cost, 30);
    expect(result.balanceAfter, 90);
    expect(result.createdAt, createdAt);
  });

  test('lottery models use UTC fallback timestamps', () {
    final asset = UserAsset.fromJson({
      'id': 'asset-fallback-time',
      'uid': 'user-1',
    });
    final result = LotteryDrawResult.fromJson({
      'draw': {'id': 'draw-fallback-time'},
      'prize': {'id': 'fallback-prize'},
      'asset': {'id': 'asset-fallback-time', 'uid': 'user-1'},
    });

    expect(asset.acquiredAt.isUtc, isTrue);
    expect(asset.updatedAt.isUtc, isTrue);
    expect(result.createdAt.isUtc, isTrue);
  });

  test('mock lottery draw refreshes cached auth session profile', () async {
    SharedPreferences.setMockInitialValues({});
    final auth = MockAuthRepository();
    final repo = MockLotteryRepository();
    final profile = UserProfile.demo().copyWith(uid: 'cached-user', xp: 120);
    await auth.updateProfile(profile);
    expect((await auth.loadSession())?.xp, 120);

    final response = await repo.draw(uid: 'cached-user', currentXp: 120);

    expect(response.user?.xp, 90);
    expect((await auth.loadSession())?.xp, 90);
  });

  test('mock lottery draw removes corrupted persisted profile JSON', () async {
    SharedPreferences.setMockInitialValues({'linguaquest.profile': '[]'});
    final repo = MockLotteryRepository();

    final response = await repo.draw(uid: 'corrupt-user', currentXp: 120);
    final prefs = await SharedPreferences.getInstance();

    expect(response.user, isNull);
    expect(prefs.getString('linguaquest.profile'), isNull);
  });

  test(
    'controller draw fallback updates state without persisting profile',
    () async {
      final now = DateTime.utc(2026, 6, 3);
      final profile = UserProfile.demo().copyWith(
        uid: 'fallback-user',
        xp: 120,
        updatedAt: now,
      );
      SharedPreferences.setMockInitialValues({
        'linguaquest.profile': jsonEncode(profile.toJson()),
      });
      final auth = _CountingAuthRepository(profile);
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(auth),
          lotteryRepositoryProvider.overrideWithValue(
            _UserlessLotteryRepository(),
          ),
          notificationRepositoryProvider.overrideWithValue(
            _EmptyNotificationRepository(),
          ),
          localNotificationServiceProvider.overrideWithValue(
            _NoopLocalNotificationService(),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container.read(appControllerProvider.notifier).bootstrap();
      final succeeded = await container
          .read(appControllerProvider.notifier)
          .drawLottery();

      expect(succeeded, isTrue);
      expect(container.read(appControllerProvider).user?.xp, 90);
      expect(auth.updateCount, 0);
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

class _CountingAuthRepository implements AuthRepository {
  _CountingAuthRepository(this.profile);

  UserProfile profile;
  var updateCount = 0;

  @override
  Future<UserProfile?> loadSession() async => profile;

  @override
  Future<UserProfile> login({required String email, required String password}) {
    throw UnimplementedError();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> resendCode(String email) async {}

  @override
  Future<UserProfile> updateProfile(UserProfile profile) async {
    updateCount++;
    this.profile = profile;
    return profile;
  }
}

class _UserlessLotteryRepository implements LotteryRepository {
  @override
  Future<List<UserAsset>> assets(String uid) async => [];

  @override
  Future<LotteryDrawResponse> draw({
    required String uid,
    required int currentXp,
  }) async {
    final now = DateTime.utc(2026, 6, 3);
    return LotteryDrawResponse(
      result: LotteryDrawResult(
        drawId: 'draw-fallback',
        prize: const LotteryPrize(
          id: 'fallback-prize',
          name: 'Fallback Prize',
          category: 'badge',
          rarity: 'common',
          description: 'Decorative only.',
          probability: 100,
          fragmentValue: 1,
        ),
        asset: UserAsset(
          id: 'asset-fallback',
          uid: uid,
          prizeId: 'fallback-prize',
          category: 'badge',
          rarity: 'common',
          name: 'Fallback Prize',
          description: 'Decorative only.',
          quantity: 1,
          fragmentValue: 1,
          acquiredAt: now,
          updatedAt: now,
        ),
        cost: lotteryDrawCost,
        balanceAfter: currentXp - lotteryDrawCost,
        createdAt: now,
      ),
    );
  }

  @override
  Future<List<LotteryPrize>> prizePool() async => [];
}

class _EmptyNotificationRepository implements NotificationRepository {
  @override
  Future<void> ensureGenerated(
    String uid,
    List<AppNotification> notifications,
  ) async {}

  @override
  Future<List<AppNotification>> list(
    String uid, {
    bool unreadOnly = false,
    AppNotificationType? type,
  }) async => [];

  @override
  Future<int> markAllRead(String uid) async => 0;

  @override
  Future<AppNotification?> markRead(String uid, String id) async => null;
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
    required LocalNotificationStrings strings,
  }) async {}

  @override
  Future<void> scheduleReviewDueReminder({
    required int dueCount,
    required String title,
    required LocalNotificationStrings strings,
  }) async {}
}
