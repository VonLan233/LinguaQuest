import '../models/ai_feature.dart';

abstract class AiRepository {
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  });

  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
    required String targetLanguage,
  });

  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  });

  /// Explains a reading paragraph in [language] (the article's language, not the
  /// global target-language setting). Returns the structured strict-JSON shape:
  /// gist / keyWords / grammarPoints / structure / translation / practice.
  Future<Map<String, dynamic>> explainParagraph({
    required String paragraph,
    required String language,
    String? level,
  });

  Future<List<AiHistoryEntry>> listHistory();

  Future<void> deleteHistory(String id);

  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    required String targetLanguage,
    String? examType,
    double? targetScore,
  });
}
