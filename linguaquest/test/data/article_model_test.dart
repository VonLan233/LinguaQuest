import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  group('Article model', () {
    test('round-trips through toJson/fromJson incl. paragraphs/vocab/comprehension', () {
      final original = Article(
        id: 'zh_hsk1_life_001',
        language: 'zh',
        level: 'hsk1',
        examLevel: 1,
        theme: 'life',
        title: '我的一天',
        titleTranslation: 'My Day',
        audioUrl: 'https://example.com/a.mp3',
        estimatedMinutes: 4,
        createdAt: DateTime.parse('2026-06-27T00:00:00.000Z'),
        paragraphs: const [
          ArticleParagraph(
            index: 0,
            text: '我每天七点起来。',
            translation: 'I get up at seven every day.',
            reading: 'wǒ měi tiān qī diǎn qǐ lái.',
            audioUrl: 'https://example.com/p0.mp3',
          ),
          ArticleParagraph(index: 1, text: '我先喝水。'),
        ],
        vocab: const [
          ArticleVocabRef(
            surface: '起来',
            wordId: 'w_qilai',
            reading: 'qǐ lái',
            meaning: 'to get up',
            role: 'key',
          ),
        ],
        comprehension: const [
          QuizQuestion(
            id: 'q1',
            type: QuizQuestionType.meaningChoice,
            prompt: '几点起来？',
            answer: '七点',
            options: ['六点', '七点'],
            explanation: '七点起来。',
            word: Word(
              id: '七点',
              word: '七点',
              phonetic: '',
              meaning: '',
              definition: '',
              partOfSpeech: '',
              exampleSentence: '',
              exampleTranslation: '',
              imageCue: '',
              difficulty: 'Medium',
              tags: [],
            ),
          ),
        ],
      );

      final restored = Article.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.language, 'zh');
      expect(restored.level, 'hsk1');
      expect(restored.examLevel, 1);
      expect(restored.theme, 'life');
      expect(restored.title, original.title);
      expect(restored.titleTranslation, 'My Day');
      expect(restored.audioUrl, original.audioUrl);
      expect(restored.estimatedMinutes, 4);
      expect(restored.createdAt.toUtc(), original.createdAt.toUtc());

      expect(restored.paragraphs.length, 2);
      expect(restored.paragraphs[0].text, '我每天七点起来。');
      expect(restored.paragraphs[0].translation, 'I get up at seven every day.');
      expect(restored.paragraphs[0].reading, 'wǒ měi tiān qī diǎn qǐ lái.');
      expect(restored.paragraphs[0].audioUrl, 'https://example.com/p0.mp3');
      expect(restored.paragraphs[1].translation, '');
      expect(restored.paragraphs[1].reading, '');

      expect(restored.vocab.length, 1);
      expect(restored.vocab[0].surface, '起来');
      expect(restored.vocab[0].wordId, 'w_qilai');
      expect(restored.vocab[0].reading, 'qǐ lái');
      expect(restored.vocab[0].meaning, 'to get up');
      expect(restored.vocab[0].role, 'key');

      expect(restored.comprehension.length, 1);
      expect(restored.comprehension[0].prompt, '几点起来？');
      expect(restored.comprehension[0].answer, '七点');
      expect(restored.comprehension[0].options, ['六点', '七点']);
    });

    test('missing-field JSON defaults safely (language=zh, empty lists)', () {
      final article = Article.fromJson({'id': 'bare'});

      expect(article.id, 'bare');
      expect(article.language, 'zh');
      expect(article.level, '');
      expect(article.examLevel, isNull);
      expect(article.theme, 'life');
      expect(article.title, '');
      expect(article.titleTranslation, '');
      expect(article.paragraphs, isEmpty);
      expect(article.vocab, isEmpty);
      expect(article.comprehension, isEmpty);
      expect(article.audioUrl, '');
      expect(article.estimatedMinutes, 3);
      expect(article.createdAt, isNotNull);
    });

    test('ArticleVocabRef defaults role to key when absent', () {
      final ref = ArticleVocabRef.fromJson({'surface': '学校'});
      expect(ref.surface, '学校');
      expect(ref.role, 'key');
      expect(ref.wordId, '');
      expect(ref.meaning, '');
    });
  });
}
