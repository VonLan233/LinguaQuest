# Design: 时文阅读 Reading Module (LinguaQuest) — DEVELOPMENT_PLAN §4

Status: design (no source changes). Date: 2026-06-27.
Scope: add a reading module ("时文阅读") on top of the multi-language foundation
(spec `2026-06-27-multilang-foundation-design.md`). Articles are classified by
**language × level × theme**, read per-paragraph with pinyin/kana + translation +
audio toggles, support tap-a-word meaning, add-to-vocab, word highlighting against the
current wordbook, reading-comprehension questions that feed learning stats, and an
AI per-paragraph explanation that **reuses the existing AI backend**.

This spec chooses the **minimal correct** path: articles are **client-bundled JSON
assets** loaded exactly like wordbooks (`WordBookAssetLoader`); the server stores only
**reading results** (optional). No CMS, no article-authoring backend.

---

## 0. Current architecture this design reuses (verified by reading the code)

- **Content loading**: `WordBookAssetLoader` (`wordbook_asset_loader.dart`) loads
  `lib/assets/data/wordbook_<id>.json` per id, lazily, with per-file try/catch. Articles
  will load the same way from a parallel `ArticleAssetLoader`.
- **Model conventions**: `Word`/`WordBook`/`Lesson` (`models/lesson.dart`) use
  `fromJson`/`toJson` with defaulting helpers (`_string`, `_int`, `_stringList`,
  `_mapList`) and additive backward-compat fields (P2a added `kana`/`romaji`/`examLevel`
  to `Word`, `language` default `'zh'` to `WordBook`). New `Article` follows the same
  style and **reuses** `QuizQuestion` for comprehension.
- **Repository switch**: every repo is `abstract` + `Mock*` + `Api*` with a
  `Provider<XRepository>` in `app_controller.dart` that returns the Api impl when
  `AppConstants.apiBaseUrl.isNotEmpty` else the Mock (lines 56–152). **Mandatory** to
  follow for `ArticleRepository`.
- **Scope**: progress is namespaced by `progressScope(language, wordBookId)`
  → `"zh::hsk1"` (`core/utils/progress_scope.dart`). `AppState` carries
  `currentLanguage` + `currentWordBookId`; `currentWordBook` getter resolves the active
  book; `userWords` (`List<UserWord>` with `wordId`/`status`/`isFavorite`) and
  `reviewWords` (`List<CustomWord>` with `masteryLevel`/`status`) are exposed for
  highlight classification. Reading progress will be persisted with the same scoped-key
  scheme used for `completedLessons` etc.
- **AI**: `AppController.askAi({featureType, prompt, targetWord})` (line 2609)
  dispatches to `AiRepository` (chat/sentence_analysis/cloze), records history, and on
  failure sets `errorMessage` and returns `{}`. Screens render loading / `AiErrorCard`
  (with `onRetry`) / structured result (see `ai_sentence_analysis_screen.dart`). Server
  `ai_policy.dart` validates `featureType`, builds a per-feature system prompt, and
  returns strict-JSON `data`. Adding a `reading_explain` feature = one new `case` in
  three places (Mock provider, `buildSystemPrompt`, the Dart `askAi` switch) + one repo
  method. No new transport.
- **Audio**: `PronunciationControls` + `PronunciationService` already do
  audio-url-or-TTS with loading/failure/retry and a CJK single-button branch. Paragraph
  audio reuses `PronunciationService` (TTS the paragraph text in the article language).
- **Quiz/results**: `QuizQuestion` model + `quiz_session_screen.dart` +
  `lesson_result_screen.dart` render single-choice questions and a result screen;
  `LessonResult`/`ExerciseRecord` + `_learningRepository.recordExerciseRecords` /
  `recordStudySession` feed analytics (`completeTraining`, line 1542). Comprehension
  reuses `QuizQuestion` and records a `StudySession` + `ExerciseRecord`s the same way.
- **Word detail / meaning popup**: `word_detail_screen.dart` /
  `target_word_detail_screen.dart` show a `Word`'s meaning/phonetic/examples. Tap-a-word
  opens a lightweight bottom-sheet reusing `Word.phoneticFor(language)` /
  `primaryDefinitionFor(locale)`, with an "add to vocab" action.
- **Routes / entry**: `app_router.dart` is a flat `GoRoute` list; `DiscoverScreen`
  cards `context.push('/discover/...')`. Reading adds `/reading` (list) and
  `/reading/:id` (reader) plus a Discover card and a Home entry.

---

## 1. Data model — `Article`

New file `lib/data/models/article.dart`. Mirrors the existing model style (defaulting
helpers, lossless `toJson`). **Reuses** `QuizQuestion` from `models/lesson.dart` for
comprehension so the quiz UI works unchanged.

### 1.1 Shape

```
Article
  id                String                  // e.g. "zh_hsk3_campus_001"
  language          String   = 'zh'         // 'zh' | 'ja' (default 'zh' for back-compat)
  level             String                  // canonical: 'hsk3' | 'jlpt_n4' (== wordBookId space)
  examLevel         int?                     // 3 / 4 — display chip (HSK n / JLPT Nn)
  theme             String                  // enum-as-string: campus|life|travel|tech|culture|news|business|exam
  title             String
  titleTranslation  String   = ''           // en (or zh-for-ja) gloss of the title
  paragraphs        List<ArticleParagraph>
  vocab             List<ArticleVocabRef>   // curated key words appearing in the article
  comprehension     List<QuizQuestion>      // REUSE existing model
  audioUrl          String   = ''           // optional whole-article audio (TTS fallback if empty)
  estimatedMinutes  int      = 3
  createdAt         DateTime

ArticleParagraph
  index       int
  text        String                  // source-language paragraph
  translation String   = ''           // en/zh translation (toggle)
  reading     String   = ''           // optional pre-segmented pinyin / kana reading line (toggle)
  audioUrl    String   = ''           // optional per-paragraph audio (else TTS the text)

ArticleVocabRef
  wordId   String   = ''   // links to a Word id in the article's wordbook when known
  surface  String          // the exact substring as it appears in text (for matching/highlight)
  reading  String   = ''   // pinyin / kana
  meaning  String   = ''   // inline gloss (so tap-meaning works offline even if wordId is unresolved)
  role     String   = 'key' // 'key' | 'new' — author hint; runtime may override (see §4)
```

### 1.2 Relationship to Word / WordBook
- `Article.level` is **the wordbook id** (`hsk3`, `jlpt_n4`), so an article maps 1:1 to a
  `WordBook` and reuses `progressScope(language, level)` for recommendation and progress.
- `ArticleVocabRef.wordId` is a soft link into that wordbook's `Word` list. When present,
  the tap-meaning sheet and "add to vocab" can pull the full `Word`; when absent (AI-seeded
  articles often won't resolve every word), the inline `surface`/`reading`/`meaning` on the
  ref is the fallback so the feature degrades gracefully offline.
- `comprehension` items are `QuizQuestion`s. Comprehension types map onto existing
  `QuizQuestionType`:
  - single-choice / detail-location / main-idea → `meaningChoice` (generic single-choice;
    `prompt` carries the question, `options`/`answer` the choices). A new optional
    `category` discriminator is **not** added to the enum (YAGNI); instead the article JSON
    tags each question with a string `comprehensionKind`
    (`single|trueFalse|wordMeaning|mainIdea|detail`) carried in the question `explanation`
    prefix or, cleaner, an extra `kind` key parsed alongside (see 1.3). True/false is a
    two-option single-choice. Word-meaning reuses `meaningChoice` with the target word as
    `prompt`.

### 1.3 Backward-compat / defaults
- All new fields default (`language='zh'`, empty strings/lists, `examLevel` null).
- Comprehension `kind`: parse `json['kind']` with a `_string` fallback to `'single'`; it is
  display/analytics metadata only and never breaks the quiz engine.
- `toJson` is lossless (serialize every field) like `Word.toJson`, so authored assets and
  any server round-trip are stable.

### 1.4 Seed content plan (bundled JSON)
- **Files**: `lib/assets/data/articles_<level>.json`, one file per wordbook level
  (`articles_hsk1.json` … `articles_hsk6.json`, `articles_jlpt_n5.json` …
  `articles_jlpt_n1.json`). Each file = `{ "level": "...", "language": "...",
  "articles": [ Article… ] }`. Registered in `pubspec.yaml` assets and an
  `ArticleAssetLoader._levelIds` list (mirrors `WordBookAssetLoader._bookIds`).
- **Volume for a credible demo**: target **2 articles per (level × theme)** for the two
  most-used levels per language (zh: hsk2/hsk3; ja: jlpt_n5/jlpt_n4) across the 8 themes
  = ~64 articles, and **1 per theme** for the remaining levels as stubs. Concretely: ship
  **~40–60 articles** total. Each article: 3–5 short paragraphs, title + translation,
  6–12 vocab refs, 3–5 comprehension questions.
- **Authoring approach (AI-generated is acceptable — this is app data, not a student
  submission)**: a `tools/generate_reading_articles.py` script (mirrors
  `generate_hsk_wordbooks.py`): prompt an LLM per `(language, level, theme)` to emit
  strict JSON matching the `Article` schema (level-appropriate vocabulary constrained to
  the level's wordbook word list, which the script passes in), with per-paragraph
  translation + reading (pinyin via `pypinyin`, kana via the JLPT reading data), and
  comprehension questions. Output is reviewed/spot-checked, then written to the asset
  files. Readings can be precomputed offline so the app needs no segmenter for the
  authored `reading` line.
- Rejected: a server articles table as the source of truth (over-engineered for a demo;
  bundling keeps it offline and matches wordbook handling).

---

## 2. Repository + state

### 2.1 `ArticleRepository` (mandatory Mock + Api + provider)
New `lib/data/repositories/article_repository.dart`:

```
abstract class ArticleRepository {
  Future<List<Article>> listArticles({String? language, String? level, String? theme});
  Future<Article?> getArticle(String id);
  Future<ReadingProgress?> loadProgress(String uid, String scope);     // scope = language::level
  Future<void> saveProgress(ReadingProgress progress);
  Future<void> recordComprehensionResult(ReadingResult result);        // analytics feed
}
```

- **`MockArticleRepository`**: loads all bundled articles via `ArticleAssetLoader`
  (cached future, like the wordbook loader), filters in memory; reading progress + results
  persisted to `SharedPreferences` under scoped keys (see 2.3). Comprehension results also
  appended to a local list for the analytics aggregation.
- **`ApiArticleRepository`**: `listArticles`/`getArticle` may still read bundled assets
  (articles are client-bundled even in API mode — recommended minimal path), while
  `loadProgress`/`saveProgress`/`recordComprehensionResult` hit the server (see 2.4). This
  keeps article content offline while results sync. Implement `getArticle` against the
  same loader to avoid divergence.
- **Provider** in `app_controller.dart` following the exact existing pattern:
  ```
  final articleRepositoryProvider = Provider<ArticleRepository>((ref) {
    if (AppConstants.apiBaseUrl.isNotEmpty) {
      return ApiArticleRepository(ref.watch(apiClientProvider), ArticleAssetLoader());
    }
    return MockArticleRepository(ArticleAssetLoader());
  });
  ```
  `AppController.build()` adds `_articleRepository = ref.watch(articleRepositoryProvider);`.

### 2.2 New models
- `ReadingProgress { uid, scope, articleId, lastParagraphIndex, completed, updatedAt }`.
- `ReadingResult { uid, scope, articleId, totalQuestions, correctAnswers, theme,
  createdAt, perKindCorrect }` — drives reading metrics.

### 2.3 Reading-progress state + scoped keys (like P2b)
- Progress is **per (language, level=wordBookId)** = the same scope token. Keys:
  - `linguaquest.reading.progress.<scope>` → JSON map `{articleId: {lastIndex, completed}}`.
  - `linguaquest.reading.results.<uid>.<scope>` → JSON list of `ReadingResult`.
  - `linguaquest.reading.read.<scope>` → set of completed article ids (for "articles read"
    metric + list checkmarks).
- `AppState` additions (all defaulted, threaded through ctor/`copyWith`/`initial`):
  - `List<Article> articles` (loaded lazily on first reading-screen entry; not in
    `bootstrap` to keep startup cheap).
  - `Set<String> readArticleIds` (active scope).
  - `Map<String,int> readingResume` (articleId → lastParagraphIndex, active scope).
  - Reloaded on `switchScope`/`switchLanguage`/`switchWordBook` exactly like the other
    scoped collections — each scope reads/writes only its own keys, so siblings are
    untouched by construction.
- Controller methods: `loadArticles()`, `recommendedArticles()` (filter by
  `currentLanguage` + `currentWordBookId`), `saveReadingProgress(articleId, index, {done})`,
  `completeReading(ReadingResult)`.

### 2.4 Server (minimal, recommended path)
**Keep articles client-bundled. Only record results + progress.** Additive, idempotent
(same `CREATE TABLE IF NOT EXISTS` block in `database.dart`):
- `reading_progress(uid, language, word_book_id, article_id, last_index, completed,
  updated_at, PRIMARY KEY(uid, language, word_book_id, article_id))`.
- `reading_results(id, uid, language, word_book_id, article_id, total, correct, theme,
  per_kind JSON, created_at)`.
- Routes: `GET/PUT /reading/progress`, `POST /reading/results`,
  `GET /reading/results` (for analytics). All scoped by `(uid, language, wordBookId)` and
  validated against `allowedWordBookIds`/`allowedLanguages` already in
  `study_plan_policy.dart`.
- No article tables, no article upload endpoint. If even this is deferred, ship Mock-only
  (SharedPreferences) and gate the Api impl behind the same flag — the provider switch
  makes that a one-line decision.

---

## 3. UI

### 3.1 Reading list — `lib/features/reading/reading_list_screen.dart` (`/reading`)
- On entry: `recommendedArticles()` for the current scope shown first ("为你推荐"),
  then a filter bar: **level** chips (the language's wordbook ids) + **theme** chips (8
  themes). Switching level/theme re-filters (client-side over the loaded list).
- Each row: title, theme chip, level chip (HSK n / JLPT Nn via `examLevel`+language),
  estimated minutes, read/in-progress badge from `readArticleIds`/`readingResume`.
- Empty/loading states reuse existing `AppCard` patterns.

### 3.2 Article reader — `lib/features/reading/article_reader_screen.dart` (`/reading/:id`)
- Header: title + `titleTranslation` (translation toggle), whole-article audio button
  (reuses `PronunciationControls`/`PronunciationService` with article language).
- **Per-paragraph layout**: each paragraph is an `_ParagraphCard` showing:
  - the source text rendered as **tappable tokens** (see §4 tokenization) with highlight
    colors for known/unknown/key/new;
  - a `reading` line (pinyin for zh / kana for ja) shown when the **reading toggle** is on
    (`Word.phoneticFor` convention; uses the authored `reading` line, no runtime
    segmenter);
  - a `translation` line shown when the **translation toggle** is on;
  - a compact paragraph audio button (reuses `PronunciationService`; per-paragraph
    `audioUrl` or TTS the `text`);
  - an **"AI 讲解" button** (§3.4).
- **Tap a word** → bottom sheet (reuses word-detail building blocks): surface, reading,
  meaning, part of speech if resolvable from the wordbook `Word`; actions
  **加入生词本/收藏** (calls existing favorite/vocab path — `addUserWordFavorite` /
  `CustomWord.create` like the training-mistake path) and **AI 解释该词** (optional, routes
  to existing `/ai-chat?word=`).
- Toggles persisted as user prefs (global, like theme — not scoped). Scroll position →
  `saveReadingProgress(articleId, visibleParagraphIndex)` (debounced); resume on reopen.

### 3.3 Comprehension flow (reuse quiz UI)
- A "做题 (Comprehension)" CTA at article end opens the **existing**
  `quiz_session_screen.dart` seeded with `article.comprehension` (they are `QuizQuestion`s).
  Reuse `lesson_result_screen.dart` for the result.
- On finish, `completeReading(ReadingResult)` records a `StudySession` +
  `ExerciseRecord`s (reuse `recordStudySession`/`recordExerciseRecords` like
  `completeTraining`) **and** a `ReadingResult` (per-kind correctness + theme), marks the
  article read, awards a small XP reward.

### 3.4 AI paragraph explain (reuse `askAi`)
- New AI feature `reading_explain`. Reuse `AppController.askAi` by adding a `case
  'reading_explain'` → new `AiRepository.explainParagraph({paragraph, targetLanguage})`
  (Mock returns canned structured data; Api posts to a new `/ai/reading-explain` route that
  reuses `_handleAiRequest`).
- Server `ai_policy.dart`: add `case 'reading_explain'` to the Mock provider's `generate`
  switch and to `buildSystemPrompt`, returning strict JSON:
  ```
  { "gist": string,               // 大意
    "keyWords": [{"word":string,"reading":string,"meaning":string}],  // 重点词
    "grammarPoints": string[],    // 语法点
    "structure": string,          // 句子结构
    "translation": string,        // 翻译
    "practice": [{"prompt":string,"answer":string,"options":string[]}] }  // 可生成练习题
  ```
- UI: a bottom sheet / expandable card on the paragraph with **loading → `AiErrorCard`
  (onRetry) → structured sections** exactly like `_AnalysisResultCard`. Generated practice
  items can be pushed into the same quiz UI. History optional (reuse `aiHistory` plumbing;
  may be filtered out of the history list to avoid noise).

### 3.5 Entry point
- **Discover card** "时文阅读" → `context.push('/reading')` (one row in
  `discover_screen.dart`, matching the existing card list).
- Optional **Home** quick-entry card next to existing learning entries.
- Routes added to `app_router.dart`: `/reading` and `/reading/:id`.

---

## 4. Highlighting + tokenization (the interesting bit)

### 4.1 Classification (reuse `userWords` + `reviewWords`)
For a token resolved to a wordbook `Word` (or matched `ArticleVocabRef`):
- **known**: appears in `userWords` with `status` in {`Learned`,`Mastered`} OR a
  `reviewWords` (CustomWord) entry with high `masteryLevel`.
- **unknown / new**: in the current wordbook's `Word` list but **not** in `userWords`
  (never studied) → "new".
- **key**: `ArticleVocabRef.role == 'key'` (author hint) — rendered with an accent even if
  also known.
- **unknown (struggling)**: in `userWords`/`reviewWords` but `status`=`New`/`Relearning`
  or `isWeak`/low mastery → "unknown" (needs attention).
Precedence: key (author) > unknown(struggling) > new(unseen) > known > plain.
All inputs already live in `AppState` (`userWords`, `reviewWords`, `currentWordBook.words`),
so classification is a pure function — no new persistence.

### 4.2 Tokenization (SIMPLE — YAGNI, no NLP segmenter)
Chinese/Japanese have no spaces. **Do not** add a morphological segmenter. Instead:
- Build a **vocabulary trie/set** from (a) the article's `ArticleVocabRef.surface` list and
  (b) the current wordbook's `Word.word` surfaces (+ `kana` for ja).
- **Longest-match left-to-right** over each paragraph against that set: at each position,
  greedily match the longest known surface; emit it as a highlightable token; if nothing
  matches, emit the single character as a plain (non-highlight, but still tappable) token.
- This means **only curated/wordbook vocabulary is highlightable and tappable-with-meaning**
  — exactly the words we have data for — which is the correct scope. Unknown runs fall back
  to per-character plain text.
- Japanese identical (match on `Word.word` kanji surface and `kana`). English/space-
  delimited languages (future) split on whitespace.
- The matcher is a small pure utility `lib/features/reading/word_segmenter.dart` with unit
  tests; O(n·maxLen) which is trivial for short paragraphs.

---

## 5. Stats integration (§3 analytics already aggregates)

- `ReadingResult`s are recorded via the learning/analytics path. Add reading metrics to
  `LearningAnalytics` (additive, defaulted like existing optional fields):
  - `articlesRead` (int) — count of completed article ids across scopes (or active scope).
  - `readingAccuracyPct` (int) — correct/total over reading comprehension.
  - `themeDistribution` (Map<String,int>) — articles read per theme.
- These default to `0`/`{}` in `fromJson` (same pattern as `modalityAccuracy`), so existing
  analytics payloads keep parsing. The analytics screen gains a small "阅读" section.
- Comprehension answers also flow through `ExerciseRecord`/`StudySession` so existing
  accuracy/XP/streak aggregation counts them with zero extra server work in Mock mode.

---

## 6. Decomposition into ordered, independently shippable sub-phases

Each phase compiles, ships, and is testable alone; earlier phases add defaults so the app
keeps working until later phases light up. Prefix **P3** to follow the multilang P2 series.

- **P3a — Model + seed content + repository (no UI).** `Article`/`ArticleParagraph`/
  `ArticleVocabRef`/`ReadingProgress`/`ReadingResult` models; `ArticleAssetLoader`;
  `ArticleRepository` + `MockArticleRepository` (+ `ApiArticleRepository` stub) + provider;
  `tools/generate_reading_articles.py` and the first batch of bundled `articles_*.json`;
  `pubspec.yaml` asset registration; controller `loadArticles()`/`recommendedArticles()`.
  Ship: data + repo present, no entry point. Test: model round-trip; asset-load (all files
  parse); recommend filter by scope; provider switch returns right impl.

- **P3b — Reading list screen + entry point.** `/reading` route, Discover card, recommend
  + level/theme filters, read/in-progress badges. Ship: browse + recommend works. Test:
  filter widget tests; recommended-first ordering for the active scope.

- **P3c — Article reader: layout + toggles + audio + tap-meaning + progress.** Per-paragraph
  cards; pinyin/kana toggle, translation toggle; whole-article + per-paragraph audio
  (reuse `PronunciationService`); tap-word bottom sheet with meaning + add-to-vocab/favorite
  (reuse existing favorite path); save/resume reading progress. (Highlight may be plain in
  this phase.) Ship: full reading experience minus highlight/comprehension/AI. Test: toggle
  visibility; tap opens sheet with correct `Word`; resume restores paragraph; audio button
  states.

- **P3d — Highlighting (segmenter + classification).** `word_segmenter.dart` longest-match;
  classify known/unknown/key/new from `userWords`/`reviewWords`/wordbook. Ship: colored,
  tappable vocabulary. Test: segmenter golden cases (overlapping/longest-match, no-match
  fallback) for zh and ja; classification table tests against fixture `userWords`.

- **P3e — Comprehension questions + stats.** Reuse quiz UI seeded from
  `article.comprehension`; `completeReading` records `StudySession`/`ExerciseRecord` +
  `ReadingResult`; add reading metrics to `LearningAnalytics` + analytics screen section;
  optional server `reading_results`/`reading_progress` tables + routes. Ship: graded
  reading feeding analytics. Test: comprehension flow end-to-end; metrics appear; server
  result upsert scoped per (uid, language, wordBookId).

- **P3f — AI paragraph explain + polish.** `reading_explain` feature across Mock provider /
  `buildSystemPrompt` / `askAi` switch / `AiRepository`; structured sheet with
  loading/`AiErrorCard`/retry; push AI-generated practice into quiz UI; per-language polish
  (kana vs pinyin labels, ja reading line, theme localization). Ship: complete module.
  Test: AI loading/error/retry states; Mock structured result renders; ja vs zh reader
  snapshot.

Recommended order: P3a → P3b → P3c → P3d → P3e → P3f. P3a gates everything; P3d and P3f are
the highest-uncertainty (tokenization + AI) and intentionally land last on a working reader.

---

## 7. Testing strategy per sub-phase (summary)

- **P3a**: unit — `Article.fromJson/toJson` round-trip incl. ja + missing-field defaults;
  asset loader parses every shipped file; recommend filter; provider switch.
- **P3b**: widget — filter chips re-filter; recommended-first; badges reflect read state.
- **P3c**: widget — each toggle shows/hides; tap-word sheet content + add-to-vocab calls the
  controller; progress save/resume; audio button loading/failure (mock `PronunciationService`).
- **P3d**: unit — segmenter longest-match + fallback (zh/ja); classification precedence with
  fixture `userWords`/`reviewWords`; render test that colors match classes.
- **P3e**: integration — comprehension run updates accuracy/XP/streak and `ReadingResult`;
  analytics exposes `articlesRead`/`readingAccuracyPct`/`themeDistribution`; server route
  scoping + idempotent upsert.
- **P3f**: widget — AI sheet loading→error(retry)→result; Mock `reading_explain` structured
  fields; generated practice opens quiz; zh/ja layout snapshots.
- Cross-cutting: existing wordbook/quiz/AI/analytics flows unchanged (additive defaults).

---

## 8. Risks

1. **Chinese/Japanese tokenization for highlight + tap-word (highest).** A real segmenter is
   out of scope; the longest-match-against-known-vocab approach only highlights curated
   words and may mis-split overlapping compounds. Mitigation: scope highlight/tap to
   wordbook + `ArticleVocabRef` surfaces (the only words we have meanings for anyway),
   per-character fallback for the rest, golden tests on tricky overlaps. Accept that
   non-vocabulary text is plain.
2. **Content authoring effort / quality.** ~40–60 articles with translations, readings, and
   comprehension is real work; AI-generated seed content can contain level-inappropriate
   vocabulary or wrong readings. Mitigation: constrain the generator to the level's wordbook
   word list, precompute readings (`pypinyin`/JLPT kana), spot-review, keep volume modest
   for the demo, mark `role`/`wordId` only when confidently resolved.
3. **AI reuse correctness.** `reading_explain` must return strict JSON and stay within the
   existing daily rate limit / language policy; a malformed response should degrade to the
   error/retry card, not crash. Mitigation: reuse `_handleAiRequest` validation + the
   `AiErrorCard` path; tolerant parsing with per-field defaults like `_AnalysisResultCard`.

Secondary: progress/scope leakage if reading keys aren't scoped (mitigated by reusing
`progressScope` + per-scope reload); startup cost (mitigated by lazy `loadArticles`).

---

## 9. Open decisions

- **OD-1**: Server-bundled vs client-bundled articles. Lean: **client-bundled** (offline,
  matches wordbooks); server stores only results/progress.
- **OD-2**: Is `articlesRead` global or per-scope in analytics? Lean: report active scope,
  store per-scope (consistent with P2b isolation).
- **OD-3**: Add a `comprehensionKind` enum to `QuizQuestionType`, or carry `kind` as a
  parsed string on the question JSON? Lean: **string `kind`** (no enum churn; analytics-only).
- **OD-4**: Should AI paragraph-explain results land in `aiHistory` like other features, or
  be ephemeral? Lean: ephemeral (avoid history noise), revisit if users want to revisit
  explanations.
- **OD-5**: Persist reading toggles globally vs per-article. Lean: global user prefs (like
  theme).
- **OD-6**: Reuse `meaningChoice` for all comprehension types vs a dedicated single-choice
  type. Lean: reuse `meaningChoice` (the quiz engine is generic single-choice already).
- **OD-7**: Per-paragraph audio = authored `audioUrl` only, or always allow TTS fallback?
  Lean: TTS fallback (no audio hosting needed, mirrors `PronunciationService`).

---

## Critical files for implementation
- linguaquest/lib/data/models/article.dart (new — reuses QuizQuestion from models/lesson.dart)
- linguaquest/lib/data/repositories/article_repository.dart + mock_repositories.dart + api_repositories.dart
- linguaquest/lib/core/state/app_controller.dart (provider switch, loadArticles, completeReading, askAi reading_explain)
- linguaquest/lib/features/reading/article_reader_screen.dart (+ reading_list_screen.dart, word_segmenter.dart)
- server/lib/src/ai_policy.dart (reading_explain feature) + routes.dart/database.dart (reading_results/progress)
