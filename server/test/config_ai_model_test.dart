import 'package:test/test.dart';
import '../lib/src/config.dart';

void main() {
  test('default aiModel is deepseek-v4.1-flash-free', () {
    const cfg = AppConfig(port: 8080, databaseUrl: 'x', jwtSecret: 'x');
    expect(cfg.aiModel, 'deepseek-v4.1-flash-free');
  });
}
