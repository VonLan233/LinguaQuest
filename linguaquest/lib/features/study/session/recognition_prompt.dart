/// A contiguous run of prompt text. [highlight] marks the tested word, which
/// the UI underlines so the learner knows which word the question is about.
class PromptSegment {
  const PromptSegment(this.text, {this.highlight = false});

  final String text;
  final bool highlight;
}

/// Splits [sentence] into segments, marking the occurrence of [target] (the
/// word being tested) for underlining.
///
/// Concatenating the segments' text reproduces [sentence] exactly, so the
/// rendered prompt is character-identical to the source — only the styling of
/// the tested word changes. Matching is case-insensitive and tolerates simple
/// inflections (e.g. `abandon` matches `abandoned`). A multi-word [target]
/// (e.g. a phrasal verb) is matched as a case-insensitive substring. When
/// [target] is empty or cannot be found, a single plain segment is returned.
List<PromptSegment> recognitionPromptSegments(String sentence, String target) {
  final trimmedTarget = target.trim();
  if (sentence.isEmpty || trimmedTarget.isEmpty) {
    return [PromptSegment(sentence)];
  }

  if (trimmedTarget.contains(' ')) {
    return _highlightSubstring(sentence, trimmedTarget);
  }
  return _highlightWord(sentence, trimmedTarget);
}

/// Highlights the first case-insensitive occurrence of a single-word [target],
/// matching whole alphabetic tokens (with light inflection tolerance) so we
/// never light up a substring of an unrelated word.
List<PromptSegment> _highlightWord(String sentence, String target) {
  final targetLower = target.toLowerCase();
  final segments = <PromptSegment>[];
  final wordPattern = RegExp(r'[A-Za-z]+');
  var cursor = 0;
  var matched = false;

  for (final match in wordPattern.allMatches(sentence)) {
    if (matched) break;
    final token = match.group(0)!;
    if (!_tokenMatches(token.toLowerCase(), targetLower)) continue;
    if (match.start > cursor) {
      segments.add(PromptSegment(sentence.substring(cursor, match.start)));
    }
    segments.add(PromptSegment(token, highlight: true));
    cursor = match.end;
    matched = true;
  }

  if (!matched) return [PromptSegment(sentence)];
  if (cursor < sentence.length) {
    segments.add(PromptSegment(sentence.substring(cursor)));
  }
  return segments;
}

/// True when alphabetic [token] (already lowercased) is the tested word or one
/// of its short inflections. Both directions allow up to three trailing
/// characters of difference (e.g. abandon↔abandoned, child↔children).
bool _tokenMatches(String token, String target) {
  if (token == target) return true;
  if (token.startsWith(target) && token.length - target.length <= 3) {
    return true;
  }
  if (target.startsWith(token) &&
      token.length >= 4 &&
      target.length - token.length <= 3) {
    return true;
  }
  return false;
}

List<PromptSegment> _highlightSubstring(String sentence, String target) {
  final index = sentence.toLowerCase().indexOf(target.toLowerCase());
  if (index < 0) return [PromptSegment(sentence)];
  final segments = <PromptSegment>[];
  if (index > 0) segments.add(PromptSegment(sentence.substring(0, index)));
  segments.add(
    PromptSegment(
      sentence.substring(index, index + target.length),
      highlight: true,
    ),
  );
  final end = index + target.length;
  if (end < sentence.length) {
    segments.add(PromptSegment(sentence.substring(end)));
  }
  return segments;
}
