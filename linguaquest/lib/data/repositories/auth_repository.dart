import '../models/user_profile.dart';

/// Result of a registration attempt.
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.profile);
  final UserProfile profile;
}

class AuthVerificationRequired extends AuthResult {
  const AuthVerificationRequired(this.email);
  final String email;
}

/// Thrown by [AuthRepository.login] when the account exists but is unverified.
class EmailNotVerifiedException implements Exception {
  const EmailNotVerifiedException(this.email);
  final String email;
}

/// Thrown by [AuthRepository.verifyEmail] for code problems. [reason] is one of
/// 'invalid_code', 'code_expired', 'too_many_attempts'.
class EmailVerificationException implements Exception {
  const EmailVerificationException(this.reason);
  final String reason;
}

abstract class AuthRepository {
  Future<UserProfile?> loadSession();

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  });

  Future<UserProfile> login({required String email, required String password});

  Future<UserProfile> verifyEmail({
    required String email,
    required String code,
  });

  Future<void> resendCode(String email);

  Future<UserProfile> updateProfile(UserProfile profile);

  Future<void> logout();
}
