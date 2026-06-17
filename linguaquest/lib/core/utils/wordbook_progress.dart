import '../../data/models/study_plan.dart';
import '../../data/models/user_word.dart';

const _unlearnedStatuses = {'New', 'Previewed', 'Ignored'};

bool isLearnedUserWord(UserWord word) {
  if (word.isIgnored) return false;
  return !_unlearnedStatuses.contains(word.status);
}

int learnedWordCountForBook({
  required Iterable<UserWord> userWords,
  required String wordBookId,
  Set<String> wordIds = const {},
}) {
  final targetBookId = normalizedStudyBookId(wordBookId);
  final learnedWordIds = <String>{};
  for (final word in userWords) {
    final sameBook = normalizedStudyBookId(word.wordBookId) == targetBookId;
    final containedInBook = wordIds.contains(word.wordId);
    if ((sameBook || containedInBook) && isLearnedUserWord(word)) {
      learnedWordIds.add(word.wordId);
    }
  }
  return learnedWordIds.length;
}

double wordbookProgressValue({
  required int learnedWords,
  required int totalWords,
}) {
  if (totalWords <= 0) return 0;
  return (learnedWords / totalWords).clamp(0.0, 1.0);
}
