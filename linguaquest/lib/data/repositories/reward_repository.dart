import '../models/point_grant_result.dart';

abstract class RewardRepository {
  Future<PointGrantResult> grantPoints({
    required String uid,
    required String sourceType,
    required String sourceId,
    required int points,
    required String description,
  });
}
