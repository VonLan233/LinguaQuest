import 'package:flutter_test/flutter_test.dart';

// 镜像 wordbook_screen 的拼音行构造逻辑（去 POS 后只保留拼音）。
String phoneticLine(String phonetic, String partOfSpeech) => phonetic;

void main() {
  test('拼音行只显拼音，不含 POS 代码', () {
    expect(phoneticLine('bǎi', 'v/vn/b'), 'bǎi');
    expect(phoneticLine('bǎi', 'v/vn/b').contains('/'), isFalse);
  });
}
