import 'dart:convert';
import 'dart:io';

const requiredBookIds = {
  'beginner',
  'ielts',
  'toefl',
  'gre',
  'cet4',
  'cet6',
  'kaoyan',
};

const requiredWordFields = {
  'id',
  'word',
  'phoneticUK',
  'phoneticUS',
  'audioUKUrl',
  'audioUSUrl',
  'partOfSpeech',
  'definitions',
  'englishDefinitions',
  'exampleSentences',
  'collocations',
  'synonyms',
  'antonyms',
  'derivatives',
  'rootAffix',
  'examTags',
  'difficulty',
  'imageUrl',
};

void main(List<String> args) {
  final path = args.isEmpty ? 'data/wordbooks_p0.json' : args.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Wordbook data not found: $path');
    exitCode = 1;
    return;
  }

  final errors = validateWordBooks(jsonDecode(file.readAsStringSync()));
  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln('- $error');
    }
    exitCode = 1;
    return;
  }
  stdout.writeln('Wordbook data quality check passed.');
}

List<String> validateWordBooks(Object? decoded) {
  final errors = <String>[];
  if (decoded is! List) return ['root must be a list of wordbooks'];

  final books = decoded.whereType<Map>().map((item) {
    return Map<String, dynamic>.from(item);
  }).toList();
  final bookIds = books.map((book) => _text(book['id'])).toSet();
  for (final id in requiredBookIds) {
    if (!bookIds.contains(id)) errors.add('missing required wordbook: $id');
  }

  final globalWordIds = <String>{};
  for (final book in books) {
    final bookId = _text(book['id']);
    if (bookId.isEmpty) errors.add('wordbook has empty id');
    _requireText(book, 'title', errors, 'wordbook $bookId');
    _requireText(book, 'examType', errors, 'wordbook $bookId');
    _requireText(book, 'description', errors, 'wordbook $bookId');

    final words = book['words'];
    if (words is! List || words.isEmpty) {
      errors.add('wordbook $bookId has no words');
      continue;
    }
    final bookTerms = <String>{};
    final meanings = <String>{};
    for (final rawWord in words.whereType<Map>()) {
      final word = Map<String, dynamic>.from(rawWord);
      final wordId = _text(word['id']);
      final term = _text(word['word']).toLowerCase();
      if (!globalWordIds.add(wordId)) errors.add('duplicate word id: $wordId');
      if (!bookTerms.add(term)) errors.add('duplicate word in $bookId: $term');
      for (final field in requiredWordFields) {
        _requireField(word, field, errors, '$bookId/$wordId');
      }
      for (final meaning in _stringList(word['definitions'])) {
        meanings.add(meaning.toLowerCase());
      }
      if (!_hasTranslatedExample(word['exampleSentences'])) {
        errors.add('$bookId/$wordId needs an example and translation');
      }
    }
    if (bookTerms.length < 4) {
      errors.add('wordbook $bookId needs at least 4 unique word distractors');
    }
    if (meanings.length < 4) {
      errors.add(
        'wordbook $bookId needs at least 4 unique meaning distractors',
      );
    }
  }
  return errors;
}

void _requireField(
  Map<String, dynamic> json,
  String field,
  List<String> errors,
  String scope,
) {
  final value = json[field];
  if (value is List) {
    if (value.isEmpty) errors.add('$scope has empty $field');
    return;
  }
  if (_text(value).isEmpty) errors.add('$scope has empty $field');
}

void _requireText(
  Map<String, dynamic> json,
  String field,
  List<String> errors,
  String scope,
) {
  if (_text(json[field]).isEmpty) errors.add('$scope has empty $field');
}

bool _hasTranslatedExample(Object? value) {
  if (value is! List) return false;
  return value.whereType<Map>().any((item) {
    return _text(item['en']).isNotEmpty && _text(item['cn']).isNotEmpty;
  });
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value.map(_text).where((item) => item.isNotEmpty).toList();
}

String _text(Object? value) => value?.toString().trim() ?? '';
