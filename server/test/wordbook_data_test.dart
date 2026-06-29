import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

void main() {
  test('JLPT server data file exists and holds 5 ja books', () {
    final file = File('data/wordbooks_jlpt.json');
    expect(file.existsSync(), isTrue,
        reason: 'run the generator step from the repo root');
    final decoded = jsonDecode(file.readAsStringSync());
    expect(decoded, isA<List>());
    final books = (decoded as List).cast<Map<String, dynamic>>();
    expect(books.length, 5);
    expect(books.map((b) => b['id']).toSet(),
        {'jlpt_n5', 'jlpt_n4', 'jlpt_n3', 'jlpt_n2', 'jlpt_n1'});
    for (final b in books) {
      expect(b['language'], 'ja');
      expect(b['words'], isA<List>());
      // Guard against a regenerated-but-empty data file slipping through.
      expect((b['words'] as List), isNotEmpty);
    }
  });

  test('p0 HSK file holds 6 full books (hsk2-6 no longer stubs)', () {
    final file = File('data/wordbooks_p0.json');
    expect(file.existsSync(), isTrue);
    final books = (jsonDecode(file.readAsStringSync()) as List)
        .cast<Map<String, dynamic>>();
    expect(books.length, 6);
    expect(books.map((b) => b['id']).toList(),
        ['hsk1', 'hsk2', 'hsk3', 'hsk4', 'hsk5', 'hsk6']);
    for (final b in books) {
      expect((b['words'] as List).length, greaterThan(3),
          reason: '${b['id']} should be a full book, not a 3-word stub');
    }
  });
}
