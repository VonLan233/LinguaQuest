import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/home/home_screen.dart';

void main() {
  test('wordOfDayIndex rotates by day and is stable within a day', () {
    expect(wordOfDayIndex(20000, 5), 20000 % 5);
    expect(wordOfDayIndex(20000, 5), wordOfDayIndex(20000, 5)); // stable
    expect(wordOfDayIndex(20001, 5) == wordOfDayIndex(20000, 5), isFalse); // changes next day
  });
  test('wordOfDayIndex is safe for empty pool', () {
    expect(wordOfDayIndex(20000, 0), 0);
  });
}
