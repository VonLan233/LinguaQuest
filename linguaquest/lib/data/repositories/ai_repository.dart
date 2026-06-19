import '../models/ai_feature.dart';

abstract class AiRepository {
  Future<Map<String, dynamic>> chat({
    required String prompt,
    String? targetWord,
  });

  Future<Map<String, dynamic>> analyzeStatement({required String prompt});

  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    String? targetWord,
  });

  Future<List<AiHistoryEntry>> listHistory();

  Future<void> deleteHistory(String id);
}
