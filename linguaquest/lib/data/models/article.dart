import 'lesson.dart';

/// Allowed article themes (carried as strings for forward-compat / no enum churn).
const articleThemes = <String>[
  'campus',
  'life',
  'travel',
  'tech',
  'culture',
  'news',
  'business',
  'exam',
];

/// A single paragraph of a reading article.
///
/// Mirrors the model conventions in `models/lesson.dart`: defaulting helpers and
/// a lossless `toJson`. All fields except [index]/[text] default so older/partial
/// JSON parses safely.
class ArticleParagraph {
  const ArticleParagraph({
    required this.index,
    required this.text,
    this.translation = '',
    this.reading = '',
    this.audioUrl = '',
  });

  final int index;

  /// Source-language paragraph text.
  final String text;

  /// English (or zh-for-ja) translation of the paragraph (translation toggle).
  final String translation;

  /// Pre-segmented reading line: pinyin for zh, kana/romaji for ja (reading toggle).
  final String reading;

  /// Optional per-paragraph audio; TTS fallback when empty.
  final String audioUrl;

  factory ArticleParagraph.fromJson(Map<String, dynamic> json) {
    return ArticleParagraph(
      index: _int(json['index']) ?? 0,
      text: _string(json['text']),
      translation: _string(json['translation']),
      reading: _string(json['reading']),
      audioUrl: _string(json['audioUrl']),
    );
  }

  Map<String, dynamic> toJson() => {
    'index': index,
    'text': text,
    'translation': translation,
    'reading': reading,
    'audioUrl': audioUrl,
  };
}

/// A curated key word that appears in an article.
///
/// [wordId] is a soft link into the article's wordbook `Word` list; when absent
/// the inline [surface]/[reading]/[meaning] are the offline fallback.
class ArticleVocabRef {
  const ArticleVocabRef({
    required this.surface,
    this.wordId = '',
    this.reading = '',
    this.meaning = '',
    this.role = 'key',
  });

  /// The exact substring as it appears in the text (for matching/highlight).
  final String surface;

  /// Links to a `Word` id in the article's wordbook when known.
  final String wordId;

  /// Pinyin / kana reading.
  final String reading;

  /// Inline gloss so tap-meaning works offline even when [wordId] is unresolved.
  final String meaning;

  /// Author hint: 'key' | 'new'. Runtime may override.
  final String role;

  factory ArticleVocabRef.fromJson(Map<String, dynamic> json) {
    return ArticleVocabRef(
      surface: _string(json['surface']),
      wordId: _string(json['wordId']),
      reading: _string(json['reading']),
      meaning: _string(json['meaning']),
      role: _string(json['role'], fallback: 'key'),
    );
  }

  Map<String, dynamic> toJson() => {
    'surface': surface,
    'wordId': wordId,
    'reading': reading,
    'meaning': meaning,
    'role': role,
  };
}

/// A reading article ("时文阅读"), classified by language × level × theme.
///
/// Reuses [QuizQuestion] from `models/lesson.dart` for comprehension so the
/// existing quiz UI works unchanged. All new fields default for backward-compat;
/// `fromJson` is tolerant of missing fields (like [Word]), `toJson` is lossless.
class Article {
  const Article({
    required this.id,
    this.language = 'zh',
    this.level = '',
    this.examLevel,
    this.theme = 'life',
    this.title = '',
    this.titleTranslation = '',
    this.paragraphs = const [],
    this.vocab = const [],
    this.comprehension = const [],
    this.audioUrl = '',
    this.estimatedMinutes = 3,
    required this.createdAt,
  });

  /// e.g. "zh_hsk1_life_001".
  final String id;

  /// 'zh' | 'ja' (default 'zh' for back-compat).
  final String language;

  /// Canonical wordbook id: 'hsk1' | 'jlpt_n5' (== wordBookId space).
  final String level;

  /// Display chip number (HSK n / JLPT Nn). Null when unknown.
  final int? examLevel;

  /// One of [articleThemes]: campus|life|travel|tech|culture|news|business|exam.
  final String theme;

  final String title;

  /// en (or zh-for-ja) gloss of the title.
  final String titleTranslation;

  final List<ArticleParagraph> paragraphs;

  /// Curated key words appearing in the article.
  final List<ArticleVocabRef> vocab;

  /// Reading-comprehension questions (REUSES the existing model).
  final List<QuizQuestion> comprehension;

  /// Optional whole-article audio (TTS fallback when empty).
  final String audioUrl;

  final int estimatedMinutes;

  final DateTime createdAt;

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: _string(json['id']),
      language: _string(json['language'], fallback: 'zh'),
      level: _string(json['level']),
      examLevel: _int(json['examLevel']),
      theme: _string(json['theme'], fallback: 'life'),
      title: _string(json['title']),
      titleTranslation: _string(json['titleTranslation']),
      paragraphs: _mapList(json['paragraphs'])
          .map(ArticleParagraph.fromJson)
          .toList(),
      vocab: _mapList(json['vocab']).map(ArticleVocabRef.fromJson).toList(),
      comprehension: _mapList(json['comprehension'])
          .map(QuizQuestion.fromJson)
          .toList(),
      audioUrl: _string(json['audioUrl']),
      estimatedMinutes: _int(json['estimatedMinutes']) ?? 3,
      createdAt:
          DateTime.tryParse(_string(json['createdAt'])) ??
          DateTime.now().toUtc(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'language': language,
    'level': level,
    'examLevel': examLevel,
    'theme': theme,
    'title': title,
    'titleTranslation': titleTranslation,
    'paragraphs': [for (final p in paragraphs) p.toJson()],
    'vocab': [for (final v in vocab) v.toJson()],
    'comprehension': [for (final q in comprehension) q.toJson()],
    'audioUrl': audioUrl,
    'estimatedMinutes': estimatedMinutes,
    'createdAt': createdAt.toIso8601String(),
  };
}

String _string(Object? value, {String fallback = ''}) {
  final result = value?.toString();
  if (result == null || result.isEmpty) return fallback;
  return result;
}

int? _int(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! Iterable) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}
