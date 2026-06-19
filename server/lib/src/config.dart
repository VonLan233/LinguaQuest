import 'dart:io';

class AppConfig {
  const AppConfig({
    required this.port,
    required this.databaseUrl,
    required this.jwtSecret,
    this.smtpHost = '',
    this.smtpPort = 587,
    this.smtpUsername = '',
    this.smtpPassword = '',
    this.smtpFrom = 'no-reply@linguaquest.app',
    this.aiProvider = 'mock',
    this.aiApiKey = '',
    this.aiApiBaseUrl = '',
    this.aiDailyLimitPerUser = 20,
  });

  final int port;
  final String databaseUrl;
  final String jwtSecret;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String smtpFrom;
  final String aiProvider;
  final String aiApiKey;
  final String aiApiBaseUrl;
  final int aiDailyLimitPerUser;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      port: int.tryParse(_env('PORT', '8080')) ?? 8080,
      databaseUrl: _env(
        'DATABASE_URL',
        'postgresql://linguaquest:linguaquest@localhost:5432/linguaquest?sslmode=disable',
      ),
      jwtSecret: _env('JWT_SECRET', 'dev-secret-change-me'),
      smtpHost: _env('SMTP_HOST', ''),
      smtpPort: int.tryParse(_env('SMTP_PORT', '587')) ?? 587,
      smtpUsername: _env('SMTP_USERNAME', ''),
      smtpPassword: _env('SMTP_PASSWORD', ''),
      smtpFrom: _env('SMTP_FROM', 'no-reply@linguaquest.app'),
      aiProvider: _env('AI_PROVIDER', 'mock'),
      aiApiKey: _env('AI_API_KEY', ''),
      aiApiBaseUrl: _env('AI_API_BASE_URL', ''),
      aiDailyLimitPerUser:
          int.tryParse(_env('AI_DAILY_LIMIT_PER_USER', '20')) ?? 20,
    );
  }
}

String _env(String key, String fallback) {
  return Platform.environment[key] ?? fallback;
}
