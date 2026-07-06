import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_state.dart';
import 'package:linguaquest/data/models/lesson.dart';
import 'package:linguaquest/data/models/study_plan.dart';

WordBook _book(String id, String title, String language) => WordBook(
  id: id,
  title: title,
  category: 'basic',
  examType: 'Basic',
  coverUrl: '',
  totalWords: 30,
  includedWords: 30,
  description: 'desc-$id',
  wordIds: const [],
  createdAt: DateTime(2026, 1, 1),
  words: const [],
  language: language,
);

void main() {
  test('StudyPlan.fromJson keeps the real wordBookId', () {
    final plan = StudyPlan.fromJson({
      'uid': 'u1',
      'wordBookId': 'en_basic',
      'dailyNewTarget': 10,
      'dailyReviewLimit': 20,
      'startDate': '2026-06-20',
      'targetFinishDate': '2026-07-20',
      'reminderTime': '20:00',
      'status': 'active',
    });
    expect(plan.wordBookId, 'en_basic');
  });

  test('StudyPlan.fromJson falls back to hsk1 when wordBookId missing/empty', () {
    expect(StudyPlan.fromJson({'uid': 'u1'}).wordBookId, 'hsk1');
    expect(
      StudyPlan.fromJson({'uid': 'u1', 'wordBookId': '  '}).wordBookId,
      'hsk1',
    );
  });

  test('studyPlanCoverEmoji maps language to emoji', () {
    expect(studyPlanCoverEmoji('ja'), '🗾');
    expect(studyPlanCoverEmoji('en'), '🔤');
    expect(studyPlanCoverEmoji('zh'), '🀄');
    expect(studyPlanCoverEmoji('unknown'), '🀄');
  });

  test('currentStudyBook reflects the current wordbook, not hsk1', () {
    final state = AppState.initial().copyWith(
      wordBooks: [
        _book('hsk1', 'HSK 1', 'zh'),
        _book('en_basic', 'English Basics', 'en'),
      ],
      currentWordBookId: 'en_basic',
    );
    expect(state.currentStudyBook.id, 'en_basic');
    expect(state.currentStudyBook.name, 'English Basics');
    expect(state.currentStudyBook.cover, '🔤');
  });
}
