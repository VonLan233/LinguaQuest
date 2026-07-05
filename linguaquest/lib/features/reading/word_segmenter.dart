import '../../data/models/article.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';
import '../../data/models/user_word.dart';

/// Classification of a matched token for highlight styling.
///
/// Precedence (highest first): [key] > [unknown] > [newWord] > [known] > [plain].
/// See [classifyToken].
enum WordClass {
  /// Author-hinted key word (`ArticleVocabRef.role == 'key'`). Accent style.
  key,

  /// In the wordbook/review set but struggling (status New/Relearning or low
  /// mastery) — needs attention.
  unknown,

  /// In the current wordbook but never studied (no [UserWord] yet).
  newWord,

  /// Learned/mastered — a known word.
  known,

  /// Non-vocabulary run rendered as plain per-character text.
  plain,
}

/// A single token emitted by [segmentParagraph]: a matched vocabulary surface or
/// a plain (unmatched) character run.
class ReadingToken {
  const ReadingToken({
    required this.text,
    required this.wordClass,
    this.vocab,
    this.word,
  });

  /// The exact substring of the paragraph this token covers.
  final String text;

  /// Highlight class for this token (always [WordClass.plain] for unmatched runs).
  final WordClass wordClass;

  /// The matched curated vocab ref (when the match came from `article.vocab`).
  final ArticleVocabRef? vocab;

  /// The matched wordbook [Word] (when the match resolved to a wordbook word).
  final Word? word;

  /// Whether this token is highlightable + tappable-with-meaning.
  bool get isMatched => wordClass != WordClass.plain;

  /// The reading (pinyin/kana) to show in the tap sheet, if resolvable.
  String readingFor(String language) {
    if (vocab != null && vocab!.reading.isNotEmpty) return vocab!.reading;
    if (word != null) return word!.phoneticFor(language);
    return vocab?.reading ?? '';
  }

  /// The meaning to show in the tap sheet, if resolvable.
  String meaningFor(String languageCode) {
    if (vocab != null && vocab!.meaning.isNotEmpty) return vocab!.meaning;
    if (word != null) {
      final defs = word!.definitionsFor(languageCode);
      if (defs.isNotEmpty) return defs.join('; ');
    }
    return vocab?.meaning ?? '';
  }
}

/// Surfaces that can be highlighted, each carrying its source data so a matched
/// token can resolve a meaning. Built once per (article, wordbook) by
/// [buildHighlightVocab].
class HighlightVocab {
  const HighlightVocab({
    required this.byVocab,
    required this.byWord,
    required this.surfacesLongestFirst,
  });

  /// surface → curated vocab ref.
  final Map<String, ArticleVocabRef> byVocab;

  /// surface → wordbook word.
  final Map<String, Word> byWord;

  /// All highlightable surfaces, sorted longest-first (for longest-match).
  final List<String> surfacesLongestFirst;

  bool get isEmpty => surfacesLongestFirst.isEmpty;
}

/// Single-kana Japanese grammatical particles that must NOT become highlightable
/// surfaces via a content word's `kana`. Their single-mora homophones (e.g. 歯
/// `ha` "tooth" → kana は) would otherwise mis-highlight the far more common
/// particle は/を/… in running text as a content word (SVV D-07).
///
/// ponytail: naive fixed particle set — no morphological analyzer. Covers only
/// the frequent single-kana particles that collide with single-mora content
/// words; multi-kana readings (e.g. いきます) are unaffected and still match, and
/// the word's kanji surface (歯) still highlights. Upgrade path: swap for a real
/// ja tokenizer (e.g. kuromoji) if genuinely-intended single-kana entries ever
/// need to match.
const _jaParticleSurfaces = {'は', 'が', 'を', 'に', 'へ', 'と', 'も', 'の'};

/// Builds the highlightable-surface index from the article's curated vocab and
/// the current wordbook words (matching on `word` surface and, for ja, `kana`).
///
/// A pure function — no storage. Curated `ArticleVocabRef.surface` and wordbook
/// `Word.word`/`Word.kana` are merged; when both a vocab ref and a wordbook word
/// share a surface, both are retained so classification can use either.
HighlightVocab buildHighlightVocab({
  required Article article,
  required WordBook? wordBook,
}) {
  final byVocab = <String, ArticleVocabRef>{};
  for (final v in article.vocab) {
    if (v.surface.isNotEmpty) {
      byVocab[v.surface] = v;
    }
  }

  final byWord = <String, Word>{};
  if (wordBook != null) {
    for (final w in wordBook.words) {
      if (w.word.isNotEmpty) {
        byWord.putIfAbsent(w.word, () => w);
      }
      if (w.kana.isNotEmpty && !_jaParticleSurfaces.contains(w.kana)) {
        byWord.putIfAbsent(w.kana, () => w);
      }
    }
  }

  final surfaces = <String>{...byVocab.keys, ...byWord.keys}.toList()
    ..sort((a, b) {
      final byLen = b.length.compareTo(a.length);
      if (byLen != 0) return byLen;
      return a.compareTo(b); // stable tie-break for deterministic output
    });

  return HighlightVocab(
    byVocab: byVocab,
    byWord: byWord,
    surfacesLongestFirst: surfaces,
  );
}

/// Longest-match left-to-right tokenization of [text] against [vocab].
///
/// At each position, greedily matches the longest known surface; emits it as a
/// matched (highlightable + tappable) token classified via [classifyToken]. When
/// nothing matches, emits the single character as a [WordClass.plain] token.
/// Consecutive plain characters are NOT merged — one token per char — so the
/// renderer can style/measure them uniformly (callers may merge for efficiency).
///
/// No NLP segmenter: only curated/wordbook vocabulary is highlightable, which is
/// exactly the set we have meanings for. O(n · maxSurfaceLen).
List<ReadingToken> segmentParagraph({
  required String text,
  required HighlightVocab vocab,
  required List<UserWord> userWords,
  required List<CustomWord> reviewWords,
}) {
  final tokens = <ReadingToken>[];
  if (text.isEmpty) return tokens;

  // Index user/review words by surface text for O(1) classification lookup.
  final userByText = <String, UserWord>{};
  for (final uw in userWords) {
    if (uw.word.isNotEmpty) userByText.putIfAbsent(uw.word, () => uw);
  }
  final reviewByText = <String, CustomWord>{};
  for (final cw in reviewWords) {
    final key = cw.word.trim();
    if (key.isNotEmpty) reviewByText.putIfAbsent(key, () => cw);
  }

  var i = 0;
  while (i < text.length) {
    String? matched;
    for (final surface in vocab.surfacesLongestFirst) {
      if (surface.isNotEmpty && text.startsWith(surface, i)) {
        matched = surface;
        break;
      }
    }
    if (matched != null) {
      final ref = vocab.byVocab[matched];
      final word = vocab.byWord[matched];
      final cls = classifyToken(
        surface: matched,
        vocab: ref,
        word: word,
        userWord: userByText[matched],
        reviewWord: reviewByText[matched],
      );
      tokens.add(
        ReadingToken(
          text: matched,
          wordClass: cls,
          vocab: ref,
          word: word,
        ),
      );
      i += matched.length;
    } else {
      tokens.add(
        ReadingToken(text: text[i], wordClass: WordClass.plain),
      );
      i += 1;
    }
  }
  return tokens;
}

/// Pure classification of a matched token into [WordClass].
///
/// 优先级（高 → 低）：
/// 1. 用户正在复习且吃力（struggling userWord 或 reviewWord 未掌握）→ unknown（红）；
///    即使是作者 key 词也覆盖，避免用户加入生词本/复习后永不显红（#E）。
/// 2. 作者 key 提示（非 struggling 词）→ key（蓝）。
/// 3. 已掌握的 user/review 词 → known（淡）。
/// 4. 词书内未学过 → newWord；其余 curated vocab → newWord；否则 plain。
///
/// 输入全部来自现有 app state（[UserWord]、[CustomWord]、wordbook [Word]、
/// [ArticleVocabRef]），不触发存储。
WordClass classifyToken({
  required String surface,
  ArticleVocabRef? vocab,
  Word? word,
  UserWord? userWord,
  CustomWord? reviewWord,
}) {
  // 1. 用户正在复习且吃力的词优先显红——即使是作者 key 词（#E）。
  if (userWord != null) {
    final struggling = userWord.status == 'New' ||
        userWord.status == 'Relearning' ||
        userWord.masteryLevel <= 1;
    final mastered = userWord.status == 'Mastered' ||
        userWord.status == 'Review' ||
        userWord.masteryLevel >= 3;
    if (struggling && !mastered) return WordClass.unknown;
  }
  if (reviewWord != null && reviewWord.masteryLevel < 3) {
    return WordClass.unknown;
  }

  // 2. 作者 key 提示（对非 struggling 词）。
  if (vocab != null && vocab.role == 'key') return WordClass.key;

  // 3. 已掌握的 user/review 词 → known。
  if (userWord != null) return WordClass.known;
  if (reviewWord != null) return WordClass.known;

  // 4. 词书内未学过 → new；其余 curated → new；否则 plain。
  if (word != null) return WordClass.newWord;
  if (vocab != null) return WordClass.newWord;
  return WordClass.plain;
}
