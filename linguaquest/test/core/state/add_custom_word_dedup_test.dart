import 'package:flutter_test/flutter_test.dart';

bool isDuplicate(List<String> existing, String word) =>
    existing.any((w) => w.trim().toLowerCase() == word.trim().toLowerCase());

void main() {
  test('同词（忽略大小写/空格）判为重复', () {
    expect(isDuplicate(['老师'], ' 老师 '), isTrue);
    expect(isDuplicate(['老师'], '学生'), isFalse);
  });
}
