import 'package:test/test.dart';

// POST /custom-words 的查重决策：若已存在同 (uid, lower(word)) 行则返回既有，不插入。
Map<String, dynamic>? decidePost({
  Map<String, dynamic>? existingByWord,
}) => existingByWord;

void main() {
  test('已存在同词 → 返回既有行（不新建）', () {
    final existing = {'id': 'w1', 'word': '老师'};
    expect(decidePost(existingByWord: existing), same(existing));
  });
  test('无同词 → null（走插入）', () {
    expect(decidePost(existingByWord: null), isNull);
  });
}
