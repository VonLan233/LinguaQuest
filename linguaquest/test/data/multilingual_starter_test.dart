import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  for (final target in ['zh', 'ja', 'en']) {
    for (final explanation in ['zh', 'ja', 'en']) {
      test(
        '$explanation explanations for $target learning survive a round trip',
        () {
          final source = jsonDecode(
            File(
              'lib/assets/data/wordbook_${target}_starter.json',
            ).readAsStringSync(),
          );
          final book = WordBook.fromJson(source as Map<String, dynamic>);
          final restored = WordBook.fromJson(book.toJson());
          expect(restored.language, target);
          expect(restored.words.length, 24);
          expect(restored.nameFor('ja'), isNotEmpty);
          final meanings = restored.words
              .map((w) => w.primaryDefinitionFor(explanation))
              .toList();
          expect(meanings.every((value) => value.isNotEmpty), isTrue);
          expect(
            meanings.toSet().length,
            meanings.length,
            reason: 'Choice questions must have distinct answers',
          );
          for (final word in restored.words) {
            expect(
              word.definitionsFor(explanation),
              word.localizedDefinitions[explanation],
            );
            expect(word.primaryDefinitionFor(explanation), isNot(word.word));
          }
        },
      );
    }
  }
}
