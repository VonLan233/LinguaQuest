import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/features/study/session/recognition_prompt.dart';

void main() {
  group('recognitionPromptSegments', () {
    String joined(List<PromptSegment> segs) => segs.map((s) => s.text).join();

    test('underlines an exact occurrence of the tested word', () {
      final segs = recognitionPromptSegments(
        'How could she abandon her own child?',
        'abandon',
      );
      expect(joined(segs), 'How could she abandon her own child?');
      final highlighted = segs.where((s) => s.highlight).toList();
      expect(highlighted, hasLength(1));
      expect(highlighted.single.text, 'abandon');
    });

    test('matches case-insensitively but preserves original casing', () {
      final segs = recognitionPromptSegments('Abandon ship now.', 'abandon');
      final highlighted = segs.where((s) => s.highlight).toList();
      expect(highlighted.single.text, 'Abandon');
      expect(joined(segs), 'Abandon ship now.');
    });

    test('matches an inflected form by stem', () {
      final segs = recognitionPromptSegments(
        'She abandoned the plan.',
        'abandon',
      );
      final highlighted = segs.where((s) => s.highlight).toList();
      expect(highlighted.single.text, 'abandoned');
      expect(joined(segs), 'She abandoned the plan.');
    });

    test('does not highlight punctuation adjacent to the word', () {
      final segs = recognitionPromptSegments('I love this child!', 'child');
      final highlighted = segs.where((s) => s.highlight).toList();
      expect(highlighted.single.text, 'child');
      // The trailing '!' must remain, in a non-highlighted segment.
      expect(joined(segs), 'I love this child!');
      expect(segs.last.highlight, isFalse);
      expect(segs.last.text.contains('!'), isTrue);
    });

    test('returns one plain segment when the word is absent', () {
      final segs = recognitionPromptSegments('Hello world', 'abandon');
      expect(segs, hasLength(1));
      expect(segs.single.highlight, isFalse);
      expect(segs.single.text, 'Hello world');
    });

    test('returns one plain segment when the target is empty', () {
      final segs = recognitionPromptSegments('Hello world', '');
      expect(segs, hasLength(1));
      expect(segs.single.highlight, isFalse);
      expect(segs.single.text, 'Hello world');
    });

    test('highlights a multi-word phrase as a substring', () {
      final segs = recognitionPromptSegments(
        'They had to give up the search.',
        'give up',
      );
      final highlighted = segs.where((s) => s.highlight).toList();
      expect(highlighted.single.text, 'give up');
      expect(joined(segs), 'They had to give up the search.');
    });

    test('does not over-match unrelated longer words', () {
      // 'art' must not light up 'started'.
      final segs = recognitionPromptSegments('They started early.', 'art');
      expect(segs.where((s) => s.highlight), isEmpty);
      expect(joined(segs), 'They started early.');
    });
  });
}
