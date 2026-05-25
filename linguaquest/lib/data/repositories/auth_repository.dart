import '../models/user_profile.dart';

abstract class AuthRepository {
  Future<UserProfile?> loadSession();

  Future<UserProfile> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserProfile> login({required String email, required String password});

  Future<UserProfile> updateProfile(UserProfile profile);

  Future<void> logout();
}
