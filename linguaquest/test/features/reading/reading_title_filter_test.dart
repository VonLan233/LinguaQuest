import 'package:flutter_test/flutter_test.dart';

// 镜像 reading_list_screen 的标题选择：无主题筛选→all，否则→"{theme} articles"。
String titleFor(String? themeFilter, String allLabel, String themedLabel) =>
    themeFilter == null ? allLabel : themedLabel;

void main() {
  test('无主题筛选用 All articles', () {
    expect(titleFor(null, 'All articles', 'Travel articles'), 'All articles');
  });
  test('选了主题用 {theme} articles', () {
    expect(titleFor('travel', 'All articles', 'Travel articles'),
        'Travel articles');
  });
}
