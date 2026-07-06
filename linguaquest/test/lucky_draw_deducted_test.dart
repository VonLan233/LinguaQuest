import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/l10n/generated/app_localizations_en.dart';

void main() {
  test('luckyDrawDeducted 按 (balance, cost) 顺序渲染：消耗30余13', () {
    final l10n = AppLocalizationsEn();
    // 生成签名为 luckyDrawDeducted(balance, cost)。余额13、消耗30。
    expect(
      l10n.luckyDrawDeducted(13, 30),
      'Deducted 30 XP, 13 XP remaining.',
    );
  });
}
