import 'dart:io';

class AppConfig {
  const AppConfig({
    required this.port,
    required this.firebaseProjectId,
    required this.firebaseServiceAccountJsonBase64,
    required this.jwtSecret,
  });

  final int port;
  final String firebaseProjectId;
  final String firebaseServiceAccountJsonBase64;
  final String jwtSecret;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      port: int.tryParse(_env('PORT', '8080')) ?? 8080,
      firebaseProjectId: _env('FIREBASE_PROJECT_ID', ''),
      firebaseServiceAccountJsonBase64: _env(
        'FIREBASE_SERVICE_ACCOUNT_JSON_BASE64',
        '',
      ),
      jwtSecret: _env('JWT_SECRET', 'dev-secret-change-me'),
    );
  }
}

String _env(String key, String fallback) {
  return Platform.environment[key] ?? fallback;
}
