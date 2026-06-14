import 'user_profile.dart';

class PointGrantResult {
  const PointGrantResult({
    required this.pointsAwarded,
    required this.alreadyGranted,
    this.user,
  });

  final int pointsAwarded;
  final bool alreadyGranted;
  final UserProfile? user;

  bool get awarded => pointsAwarded > 0 && !alreadyGranted;
}
