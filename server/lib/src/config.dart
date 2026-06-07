import 'dart:io';

class AppConfig {
  const AppConfig({
    required this.port,
    required this.databaseUrl,
    required this.jwtSecret,
  });

  final int port;
  final String databaseUrl;
  final String jwtSecret;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      port: int.tryParse(_env('PORT', '8080')) ?? 8080,
      databaseUrl: _env(
        'DATABASE_URL',
        'postgresql://linguaquest:linguaquest@localhost:5432/linguaquest?sslmode=disable',
      ),
      jwtSecret: _env('JWT_SECRET', 'dev-secret-change-me'),
    );
  }
}

String _env(String key, String fallback) {
  return Platform.environment[key] ?? fallback;
}
