// 测试 classifyToken 的优先级修改：正在复习且吃力的词覆盖作者 key 色（Task 8 #E）
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/article.dart';
import 'package:linguaquest/data/models/custom_word.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/user_word.dart';
import 'package:linguaquest/features/reading/word_segmenter.dart';

/// 最小 Word，仅用于 UserWord.create() 的必填参数。
Word _minWord() => const Word(
      id: 'w1',
      word: '老师',
      phonetic: '',
      meaning: '',
      definition: '',
      partOfSpeech: '',
      exampleSentence: '',
      exampleTranslation: '',
      imageCue: '',
      difficulty: 'medium',
      tags: [],
      kana: '',
      englishDefinitions: [],
    );

const _keyVocab = ArticleVocabRef(surface: '老师', role: 'key');

void main() {
  test('key 词被加入生词本(reviewWord 未掌握)后显红 unknown', () {
    // reviewWord.masteryLevel == 0 → 吃力，应覆盖 key 显红
    final reviewWord = CustomWord.create(
      id: 'c1',
      uid: 'u',
      word: '老师',
      meaning: 'teacher',
      exampleSentence: '',
    ); // 默认 masteryLevel: 0
    final result = classifyToken(
      surface: '老师',
      vocab: _keyVocab,
      reviewWord: reviewWord,
    );
    expect(result, WordClass.unknown);
  });

  test('key 词未标记仍显蓝 key', () {
    // 无 userWord / reviewWord → 纯作者 key 词 → key
    final result = classifyToken(
      surface: '老师',
      vocab: _keyVocab,
    );
    expect(result, WordClass.key);
  });

  test('key 词且 userWord 已掌握仍显 key（不回归）', () {
    // userWord status:'Mastered', masteryLevel:4 → 非吃力，不覆盖 key
    final userWord = UserWord.create(
      uid: 'u',
      word: _minWord(),
      wordBookId: 'hsk1',
    ).copyWith(status: 'Mastered', masteryLevel: 4);
    final result = classifyToken(
      surface: '老师',
      vocab: _keyVocab,
      userWord: userWord,
    );
    expect(result, WordClass.key);
  });

  test('struggling userWord + key vocab → unknown', () {
    // userWord status:'New', masteryLevel:0 → 吃力，覆盖 key
    final strugglingWord = UserWord.create(
      uid: 'u',
      word: _minWord(),
      wordBookId: 'hsk1',
    ); // 默认 status: 'New', masteryLevel: 0
    final result = classifyToken(
      surface: '老师',
      vocab: _keyVocab,
      userWord: strugglingWord,
    );
    expect(result, WordClass.unknown);
  });
}
