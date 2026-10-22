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
    this.resendApiKey = '',
    this.mailFrom = 'no-reply@linguaquest.app',
    this.aiProvider = 'mock',
    this.aiApiKey = '',
    this.aiApiBaseUrl = 'https://opencode.ai/inference/openai/v1',
    this.aiModel = 'deepseek-v4.1-flash-free',
    this.opencodeServerUrl = 'http://opencode:4096',
    this.opencodeServerPassword = '',
    this.aiClozeModel = '',
    this.aiDailyLimitPerUser = 20,
    this.ttsServiceUrl = 'http://tts:5002',
    this.ttsCacheDir = '/tmp/tts-cache',
  });

  final int port;
  final String databaseUrl;
  final String jwtSecret;
  final String smtpHost;
  final int smtpPort;
  final String smtpUsername;
  final String smtpPassword;
  final String smtpFrom;
  final String resendApiKey;
  final String mailFrom;
  final String aiProvider;
  final String aiApiKey;
  final String aiApiBaseUrl;
  final String aiModel;
  final String opencodeServerUrl;
  final String opencodeServerPassword;

  /// Optional model used only for `cloze`. Empty → fall back to [aiModel].
  final String aiClozeModel;
  final int aiDailyLimitPerUser;
  final String ttsServiceUrl;
  final String ttsCacheDir;

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
      resendApiKey: _env('RESEND_API_KEY', ''),
      mailFrom: _env('MAIL_FROM', 'no-reply@linguaquest.app'),
      aiProvider: _env('AI_PROVIDER', 'mock'),
      aiApiKey: _env('AI_API_KEY', ''),
      aiApiBaseUrl: _env(
        'AI_API_BASE_URL',
        'https://opencode.ai/inference/openai/v1',
      ),
      aiModel: _env('AI_MODEL', 'deepseek-v4.1-flash-free'),
      opencodeServerUrl: _env('OPENCODE_SERVER_URL', 'http://opencode:4096'),
      opencodeServerPassword: _env('OPENCODE_SERVER_PASSWORD', ''),
      aiClozeModel: _env('AI_CLOZE_MODEL', ''),
      aiDailyLimitPerUser:
          int.tryParse(_env('AI_DAILY_LIMIT_PER_USER', '20')) ?? 20,
      ttsServiceUrl: _env('TTS_SERVICE_URL', 'http://tts:5002'),
      ttsCacheDir: _env('TTS_CACHE_DIR', '/tmp/tts-cache'),
    );
  }

  AppConfig copyWith({
    int? port,
    String? databaseUrl,
    String? jwtSecret,
    String? smtpHost,
    int? smtpPort,
    String? smtpUsername,
    String? smtpPassword,
    String? smtpFrom,
    String? resendApiKey,
    String? mailFrom,
    String? aiProvider,
    String? aiApiKey,
    String? aiApiBaseUrl,
    String? aiModel,
    String? opencodeServerUrl,
    String? opencodeServerPassword,
    String? aiClozeModel,
    int? aiDailyLimitPerUser,
    String? ttsServiceUrl,
    String? ttsCacheDir,
  }) {
    return AppConfig(
      port: port ?? this.port,
      databaseUrl: databaseUrl ?? this.databaseUrl,
      jwtSecret: jwtSecret ?? this.jwtSecret,
      smtpHost: smtpHost ?? this.smtpHost,
      smtpPort: smtpPort ?? this.smtpPort,
      smtpUsername: smtpUsername ?? this.smtpUsername,
      smtpPassword: smtpPassword ?? this.smtpPassword,
      smtpFrom: smtpFrom ?? this.smtpFrom,
      resendApiKey: resendApiKey ?? this.resendApiKey,
      mailFrom: mailFrom ?? this.mailFrom,
      aiProvider: aiProvider ?? this.aiProvider,
      aiApiKey: aiApiKey ?? this.aiApiKey,
      aiApiBaseUrl: aiApiBaseUrl ?? this.aiApiBaseUrl,
      aiModel: aiModel ?? this.aiModel,
      opencodeServerUrl: opencodeServerUrl ?? this.opencodeServerUrl,
      opencodeServerPassword:
          opencodeServerPassword ?? this.opencodeServerPassword,
      aiClozeModel: aiClozeModel ?? this.aiClozeModel,
      aiDailyLimitPerUser: aiDailyLimitPerUser ?? this.aiDailyLimitPerUser,
      ttsServiceUrl: ttsServiceUrl ?? this.ttsServiceUrl,
      ttsCacheDir: ttsCacheDir ?? this.ttsCacheDir,
    );
  }
}

String _env(String key, String fallback) {
  return Platform.environment[key] ?? fallback;
}
