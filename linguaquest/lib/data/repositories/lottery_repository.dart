import '../models/app_notification.dart';
import '../models/lottery.dart';
import '../models/user_profile.dart';

const lotteryDrawCost = 30;

class LotteryDrawResponse {
  const LotteryDrawResponse({
    required this.result,
    this.user,
    this.notifications = const [],
  });

  final LotteryDrawResult result;
  final UserProfile? user;
  final List<AppNotification> notifications;
}

abstract class LotteryRepository {
  Future<List<LotteryPrize>> prizePool();

  Future<List<UserAsset>> assets(String uid);

  Future<LotteryDrawResponse> draw({
    required String uid,
    required int currentXp,
  });
}
