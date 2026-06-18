// One-off seed generator. NOT part of the app build.
//
// Usage:
//   curl -fsSL \
//     https://raw.githubusercontent.com/drkameleon/complete-hsk-vocabulary/main/wordlists/exclusive/new/1.json \
//     -o /tmp/hsk_new_1.json
//   dart run tools/hsk_seed/convert_hsk.dart /tmp/hsk_new_1.json \
//     linguaquest/lib/assets/data/wordbook_hsk1.json
//
// Source entry shape (drkameleon/complete-hsk-vocabulary):
//   { "simplified": "爱", "pos": ["v"], "frequency": 130,
//     "forms": [ { "traditional": "愛",
//                  "transcriptions": { "pinyin": "ài", ... },
//                  "meanings": ["to love", ...],
//                  "classifiers": [] } ] }
import 'dart:convert';
import 'dart:io';

const _hskLevel = 1;
// Fixed timestamp keeps the generated asset deterministic across runs.
const _createdAt = '2026-06-19T00:00:00.000Z';

void main(List<String> args) {
  if (args.length != 2) {
    stderr.writeln('Usage: dart run tools/hsk_seed/convert_hsk.dart <input.json> <output.json>');
    exit(64);
  }
  final raw = jsonDecode(File(args[0]).readAsStringSync());
  if (raw is! List) {
    stderr.writeln('Expected a JSON array at top level.');
    exit(65);
  }

  final words = <Map<String, dynamic>>[];
  final usedIds = <String>{};
  for (var i = 0; i < raw.length; i++) {
    final entry = Map<String, dynamic>.from(raw[i] as Map);
    final simplified = (entry['simplified'] ?? '').toString();
    if (simplified.isEmpty) continue;
    final forms = (entry['forms'] as List?) ?? const [];
    if (forms.isEmpty) continue;
    final form = Map<String, dynamic>.from(forms.first as Map);
    final transcriptions =
        Map<String, dynamic>.from((form['transcriptions'] ?? {}) as Map);
    final pinyin = (transcriptions['pinyin'] ?? '').toString();
    final meanings = <String>[
      for (final m in (form['meanings'] as List? ?? const []))
        m.toString().trim(),
    ].where((m) => m.isNotEmpty).toList();
    if (meanings.isEmpty) continue;
    final pos = <String>[
      for (final p in (entry['pos'] as List? ?? const [])) p.toString().trim(),
    ].where((p) => p.isNotEmpty).toList();

    final id = _uniqueId(usedIds, pinyin, i);
    final encoded = Uri.encodeComponent(simplified);
    words.add({
      'id': id,
      'word': simplified,
      'phoneticUK': pinyin,
      'phoneticUS': pinyin,
      'audioUKUrl': 'https://dict.youdao.com/dictvoice?audio=$encoded&type=1',
      'audioUSUrl': 'https://dict.youdao.com/dictvoice?audio=$encoded&type=2',
      'partOfSpeech': pos.join('/'),
      'definitions': meanings,
      'englishDefinitions': meanings,
      'malayDefinitions': const <String>[],
      'exampleSentences': const <Map<String, String>>[],
      'collocations': const <Map<String, String>>[],
      'synonyms': const <String>[],
      'antonyms': const <String>[],
      'derivatives': const <String>[],
      'rootAffix': '',
      'examTags': const <String>[],
      'difficulty': 'Easy',
      'imageUrl': '',
      'hskLevel': _hskLevel,
    });
  }

  final book = {
    'id': 'hsk1',
    'title': 'HSK 1',
    'titleEn': 'HSK 1',
    'titleMs': 'HSK 1',
    'category': 'hsk',
    'examType': 'HSK 1',
    'coverUrl': '',
    'totalWords': words.length,
    'includedWords': words.length,
    'description': 'Core vocabulary for HSK Level 1.',
    'wordIds': [for (final w in words) w['id']],
    'createdAt': _createdAt,
    'words': words,
  };

  final encoder = const JsonEncoder.withIndent('  ');
  File(args[1]).writeAsStringSync('${encoder.convert(book)}\n');
  stdout.writeln('Wrote ${words.length} words to ${args[1]}');
}

String _uniqueId(Set<String> used, String pinyin, int index) {
  final ascii = pinyin
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z]'), '');
  final base = 'hsk1_${index.toString().padLeft(3, '0')}_${ascii.isEmpty ? 'x' : ascii}';
  var id = base;
  var suffix = 1;
  while (!used.add(id)) {
    id = '${base}_$suffix';
    suffix++;
  }
  return id;
}
