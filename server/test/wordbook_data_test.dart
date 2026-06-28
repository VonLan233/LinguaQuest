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
    }
  });
}
