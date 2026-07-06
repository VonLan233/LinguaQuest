import '../../data/models/lesson.dart';

/// Converts an AI `/ai/cloze` result `{passage, blanks:[{index,answer,options}]}`
/// into one [QuizQuestion] per blank (type [QuizQuestionType.contextChoice]).
///
/// Each question's prompt is the passage with the active blank shown as `____`
/// and the other blanks filled with their answers (for readability). Returns an
/// empty list when the result is malformed or has no usable blanks.
List<QuizQuestion> passageClozeQuestions(
  Map<String, dynamic> aiResult,
  List<Word> wordbook,
) {
  final passage = aiResult['passage'] as String? ?? '';
  final rawBlanks = aiResult['blanks'];
  if (passage.isEmpty || rawBlanks is! List) return const [];

  final blanks = <Map<String, dynamic>>[];
  for (final b in rawBlanks) {
    if (b is Map) blanks.add(Map<String, dynamic>.from(b));
  }
  if (blanks.isEmpty) return const [];

  final byWord = {for (final w in wordbook) w.word.trim().toLowerCase(): w};

  String renderForActive(int activeIdx) {
    // Replace the i-th "___" run: active -> "____", others -> their answer.
    var result = passage;
    final marker = RegExp('_+');
    var seen = 0;
    result = result.replaceAllMapped(marker, (m) {
      final i = seen++;
      if (i == activeIdx) return '____';
      final ans = (i < blanks.length ? blanks[i]['answer'] : null) as String?;
      return ans ?? '____';
    });
    // If the passage has no underscores, append the active blank cue.
    if (seen == 0) return '$passage\n\n(Blank ${activeIdx + 1})';
    return result;
  }

  final questions = <QuizQuestion>[];
  for (var i = 0; i < blanks.length; i++) {
    final answer = (blanks[i]['answer'] as String? ?? '').trim();
    if (answer.isEmpty) continue;
    final options =
        (blanks[i]['options'] as List<dynamic>?)?.whereType<String>().toList() ??
            <String>[answer];
    if (!options.contains(answer)) options.insert(0, answer);
    final word = byWord[answer.toLowerCase()] ??
        Word(
          id: 'cloze-$i-$answer',
          word: answer,
          phonetic: '',
          meaning: '',
          definition: '',
          partOfSpeech: '',
          exampleSentence: passage,
          exampleTranslation: '',
          imageCue: '',
          difficulty: 'A1',
          tags: const [],
        );
    questions.add(
      QuizQuestion(
        id: 'passage-cloze-$i',
        type: QuizQuestionType.contextChoice,
        prompt: renderForActive(i),
        answer: answer,
        options: List.unmodifiable(options),
        explanation: passage,
        word: word,
      ),
    );
  }
  return questions;
}
