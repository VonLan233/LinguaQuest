import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/utils/ui_labels.dart';

void main() {
  group('displayWordbookTitle — HSK', () {
    test('hsk1 → HSK 1', () => expect(displayWordbookTitle('hsk1'), 'HSK 1'));
    test('hsk3 → HSK 3', () => expect(displayWordbookTitle('hsk3'), 'HSK 3'));
    test('hsk6 → HSK 6', () => expect(displayWordbookTitle('hsk6'), 'HSK 6'));
    test('HSK1 (uppercase) → HSK 1',
        () => expect(displayWordbookTitle('HSK1'), 'HSK 1'));
  });

  group('displayWordbookTitle — JLPT', () {
    test('jlpt_n5 → JLPT N5',
        () => expect(displayWordbookTitle('jlpt_n5'), 'JLPT N5'));
    test('jlpt_n1 → JLPT N1',
        () => expect(displayWordbookTitle('jlpt_n1'), 'JLPT N1'));
    test('jlptn3 (no separator) → JLPT N3',
        () => expect(displayWordbookTitle('jlptn3'), 'JLPT N3'));
    test('JLPT_N2 (uppercase) → JLPT N2',
        () => expect(displayWordbookTitle('JLPT_N2'), 'JLPT N2'));
  });

  group('displayWordbookTitle — unknown id fallback', () {
    test('unknown id returns id itself (no l10n)',
        () => expect(displayWordbookTitle('something_unknown'), 'something_unknown'));
  });
}
