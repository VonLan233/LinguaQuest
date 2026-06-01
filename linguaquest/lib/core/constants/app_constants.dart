class AppConstants {
  const AppConstants._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8080',
  );
  static const demoUid = 'demo-user';
  static const appName = 'LinguaQuest';
}
