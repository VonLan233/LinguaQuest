import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/lesson_factory.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  test('training lessons generated from a wordbook use English titles and descriptions', () {
    final book = WordBook(
      id: 'es_basic',
      title: 'Español Básico',
      category: 'language',
      examType: 'ES',
      coverUrl: '',
      totalWords: 4,
      includedWords: 4,
      description: 'Spanish basics',
      wordIds: const ['hola', 'adios', 'gracias', 'por-favor'],
      createdAt: DateTime(2026, 7, 6),
      language: 'es',
      words: const [
        Word(
          id: 'hola',
          word: 'hola',
          phonetic: '',
          meaning: 'hello',
          definition: 'hello',
          partOfSpeech: 'word',
          exampleSentence: 'Hola, Ana.',
          exampleTranslation: 'Hello, Ana.',
          imageCue: 'H',
          difficulty: 'Easy',
          tags: [],
        ),
        Word(
          id: 'adios',
          word: 'adiós',
          phonetic: '',
          meaning: 'goodbye',
          definition: 'goodbye',
          partOfSpeech: 'word',
          exampleSentence: 'Adiós.',
          exampleTranslation: 'Goodbye.',
          imageCue: 'A',
          difficulty: 'Easy',
          tags: [],
        ),
        Word(
          id: 'gracias',
          word: 'gracias',
          phonetic: '',
          meaning: 'thanks',
          definition: 'thanks',
          partOfSpeech: 'word',
          exampleSentence: 'Gracias.',
          exampleTranslation: 'Thanks.',
          imageCue: 'G',
          difficulty: 'Easy',
          tags: [],
        ),
        Word(
          id: 'por-favor',
          word: 'por favor',
          phonetic: '',
          meaning: 'please',
          definition: 'please',
          partOfSpeech: 'phrase',
          exampleSentence: 'Por favor.',
          exampleTranslation: 'Please.',
          imageCue: 'P',
          difficulty: 'Easy',
          tags: [],
        ),
      ],
    );

    final lessons = trainingLessonsFromWordBook(book);

    expect(lessons.map((lesson) => lesson.title), contains('Español Básico · Campus Sprint'));
    expect(
      lessons.expand((lesson) => [lesson.title, lesson.description]),
      everyElement(isNot(contains(RegExp(r'[\u3400-\u9fff]')))),
    );
  });
}
