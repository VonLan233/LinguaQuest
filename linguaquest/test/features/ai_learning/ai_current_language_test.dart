// test/features/ai_learning/ai_current_language_test.dart
//
// §5 (P4b): AI Learning explains the language being *learned*. askAi() and
// reviewWriting() must forward state.currentLanguage (not the legacy
// targetLanguage exam setting) to the AI repository.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linguaquest/core/state/app_controller.dart';
import 'package:linguaquest/data/models/ai_feature.dart';
import 'package:linguaquest/data/repositories/ai_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Spy AiRepository recording the targetLanguage of the last call per method.
class _SpyAiRepository implements AiRepository {
  String? chatLanguage;
  String? analyzeLanguage;
  String? clozeLanguage;
  String? confusionLanguage;
  String? sentencesLanguage;
  String? reviewLanguage;

  @override
  Future<Map<String, dynamic>> chat({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    chatLanguage = targetLanguage;
    return {'answer': '', 'cautions': <String>[], 'relatedWords': <String>[]};
  }

  @override
  Future<Map<String, dynamic>> analyzeStatement({
    required String prompt,
    required String targetLanguage,
  }) async {
    analyzeLanguage = targetLanguage;
    return {'mainClause': '', 'translation': '', 'clauses': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> generateCloze({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    clozeLanguage = targetLanguage;
    return {'passage': '', 'blanks': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> generateConfusion({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    confusionLanguage = targetLanguage;
    return {'pairs': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> generateSentences({
    required String prompt,
    required String targetLanguage,
    String? targetWord,
  }) async {
    sentencesLanguage = targetLanguage;
    return {'sentences': <dynamic>[], 'rewrites': <dynamic>[]};
  }

  @override
  Future<Map<String, dynamic>> explainParagraph({
    required String paragraph,
    required String language,
    String? level,
  }) async =>
      {};

  @override
  Future<List<AiHistoryEntry>> listHistory() async => [];

  @override
  Future<void> deleteHistory(String id) async {}

  @override
  Future<Map<String, dynamic>> reviewWriting({
    required String essay,
    required String targetLanguage,
    String? examType,
    double? targetScore,
  }) async {
    reviewLanguage = targetLanguage;
    return {'score': 0};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('askAi + reviewWriting forward currentLanguage=ja', () async {
    // Bootstrap into Japanese so state.currentLanguage == 'ja'.
    SharedPreferences.setMockInitialValues({
      'linguaquest.current_language': 'ja',
    });

    final spy = _SpyAiRepository();
    final container = ProviderContainer(
      overrides: [aiRepositoryProvider.overrideWithValue(spy)],
    );
    addTearDown(container.dispose);

    final controller = container.read(appControllerProvider.notifier);
    await controller.bootstrap();

    expect(
      container.read(appControllerProvider).currentLanguage,
      'ja',
      reason: 'bootstrap should resolve currentLanguage from prefs',
    );

    await controller.askAi(featureType: 'chat', prompt: 'p', targetWord: 'w');
    await controller.askAi(featureType: 'sentence_analysis', prompt: 'p');
    await controller.askAi(featureType: 'cloze', prompt: 'p', targetWord: 'w');
    await controller.reviewWriting(essay: 'e');

    expect(spy.chatLanguage, 'ja');
    expect(spy.analyzeLanguage, 'ja');
    expect(spy.clozeLanguage, 'ja');
    expect(spy.reviewLanguage, 'ja');
  });
}
