import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/utils/ui_labels.dart';
import 'package:linguaquest/data/models/lesson.dart';

void main() {
  test('system label fallbacks are English when l10n is unavailable', () {
    final labels = <String>[
      displayTarget('CET-4'),
      displayTarget('CET-6'),
      displayTarget('考研'),
      displayTarget(null),
      displayQuestionType(QuizQuestionType.meaningChoice),
      displayQuestionType(QuizQuestionType.chineseChoice),
      displayQuestionType(QuizQuestionType.contextChoice),
      displayQuestionType(QuizQuestionType.imageChoice),
      displayQuestionType(QuizQuestionType.listeningWordChoice),
      displayQuestionType(QuizQuestionType.listeningMeaningChoice),
      displayQuestionType(QuizQuestionType.spelling),
      displayLevel('Beginner'),
      displayLevel(null),
      displayDifficulty('Easy'),
      displayDifficultyFilter('All'),
      displayWordStatus('Mastered'),
      displayCustomTag('custom'),
      displayWordTag('academic'),
      displayWordTag('kaoyan'),
      displayWordTag(''),
      displayLotteryCategory('badge'),
      displayLotteryRarity('rare'),
    ];

    for (final label in labels) {
      expect(label, isNot(matches(RegExp(r'[\u4e00-\u9fff]'))));
    }
  });
}
