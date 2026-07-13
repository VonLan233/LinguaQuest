import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/data/models/study_plan.dart';

void main() {
  test('study plan wordbook helpers preserve real shipped wordbook ids', () {
    expect(normalizedStudyBookId('hsk2'), 'hsk2');
    expect(normalizedStudyBookId('jlpt_n5'), 'jlpt_n5');
    expect(normalizedStudyBookId('en_basic'), 'en_basic');
    expect(normalizedStudyBookId('fr_basic'), 'fr_basic');
  });

  test('study plan target helpers map known targets without HSK1 collapse', () {
    expect(studyBookIdForTarget('HSK 2'), 'hsk2');
    expect(studyBookIdForTarget('JLPT N5'), 'jlpt_n5');
    expect(studyBookIdForTarget('Daily English'), 'en_basic');
    expect(studyBookIdForTarget('CET-4'), 'cet4');
    expect(studyBookIdForTarget('考研'), 'kaoyan');

    expect(targetForStudyBookId('hsk2'), 'HSK 2');
    expect(targetForStudyBookId('jlpt_n5'), 'JLPT N5');
    expect(targetForStudyBookId('en_basic'), 'Daily English');
    expect(targetForStudyBookId('cet4'), 'CET-4');
    expect(targetForStudyBookId('kaoyan'), 'Kaoyan');
  });
}
