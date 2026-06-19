import 'package:test/test.dart';
import '../lib/src/config.dart';

void main() {
  group('AppConfig AI defaults', () {
    test('aiModel defaults to deepseek-v4-flash-free', () {
      const config = AppConfig(
        port: 8080,
        databaseUrl: 'x',
        jwtSecret: 'y',
      );
      expect(config.aiModel, equals('deepseek-v4-flash-free'));
    });

    test('aiApiBaseUrl defaults to OpenCode Zen v1 endpoint', () {
      const config = AppConfig(
        port: 8080,
        databaseUrl: 'x',
        jwtSecret: 'y',
      );
      expect(config.aiApiBaseUrl, equals('https://opencode.ai/zen/v1'));
    });

    test('aiProvider still defaults to mock', () {
      const config = AppConfig(
        port: 8080,
        databaseUrl: 'x',
        jwtSecret: 'y',
      );
      expect(config.aiProvider, equals('mock'));
      expect(config.aiApiKey, equals(''));
    });
  });
}
