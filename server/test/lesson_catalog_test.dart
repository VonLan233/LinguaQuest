import 'package:linguaquest_server/src/lesson_catalog.dart';
import 'package:test/test.dart';

void main() {
  test('lesson catalog exposes frontend-compatible lesson DTOs', () {
    final lessons = lessonCatalog();

    expect(lessons, hasLength(greaterThanOrEqualTo(6)));
    for (final lesson in lessons) {
      expect(lesson['id'], isA<String>());
      expect(lesson['title'], isA<String>());
      expect(lesson['section'], isA<String>());
      expect(lesson['status'], isA<String>());
      expect(lesson['xpReward'], isA<int>());
      expect(lesson['estimatedMinutes'], isA<int>());
      expect(lesson['words'], isA<List>());
      expect(lesson['questions'], isA<List>());
    }

    final first = lessons.first;
    final words = first['words'] as List;
    final questions = first['questions'] as List;
    expect(words, isNotEmpty);
    expect(questions, isNotEmpty);

    expect(words.first, containsPair('imageCue', isA<String>()));
    expect(words.first, containsPair('tags', isA<List>()));
    expect(questions.first, containsPair('type', 'meaningChoice'));
    expect(questions.first, containsPair('word', words.first));
  });
}
