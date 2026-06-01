import 'dart:convert';
import 'dart:io';

class AiService {
  AiService({
    required this.provider,
    required this.model,
    required this.apiKey,
    required this.baseUrl,
    required this.safetyEnabled,
  });

  final String provider;
  final String model;
  final String apiKey;
  final Uri baseUrl;
  final bool safetyEnabled;

  factory AiService.fromEnvironment() {
    return AiService(
      provider: _env('AI_PROVIDER', 'local').trim().toLowerCase(),
      model: _env('AI_MODEL', 'linguaquest-structured-local'),
      apiKey: _env('AI_API_KEY', ''),
      baseUrl: Uri.parse(
        _env('AI_BASE_URL', 'https://api.openai.com/v1/chat/completions'),
      ),
      safetyEnabled: _env('AI_SAFETY_ENABLED', 'true').toLowerCase() != 'false',
    );
  }

  Future<AiCompletion> complete({
    required String feature,
    required String prompt,
  }) async {
    final normalizedFeature = normalizeFeature(feature);
    final cleanPrompt = prompt.trim();
    final safety = evaluateSafety(cleanPrompt);
    if (!safety.allowed) {
      return AiCompletion(
        feature: normalizedFeature,
        title: titleFor(normalizedFeature, cleanPrompt),
        response: '这个请求包含不适合学习场景的内容。请改写为单词、语法、作文或阅读理解相关问题。',
        payload: {
          'provider': provider,
          'model': model,
          'safety': safety.toJson(),
          'sections': [
            {'title': '处理结果', 'body': '请求已被内容安全规则拦截，没有调用生成模型。'},
          ],
        },
      );
    }

    if (provider == 'openai-compatible') {
      return _completeWithOpenAiCompatible(
        feature: normalizedFeature,
        prompt: cleanPrompt,
        safety: safety,
      );
    }

    return _completeLocally(
      feature: normalizedFeature,
      prompt: cleanPrompt,
      safety: safety,
    );
  }

  AiSafetyResult evaluateSafety(String prompt) {
    if (!safetyEnabled) return const AiSafetyResult(allowed: true);
    final trimmed = prompt.trim();
    if (trimmed.isEmpty) {
      return const AiSafetyResult(
        allowed: false,
        reason: 'empty_prompt',
        category: 'input',
      );
    }
    if (trimmed.length > 4000) {
      return const AiSafetyResult(
        allowed: false,
        reason: 'prompt_too_long',
        category: 'input',
      );
    }
    final lower = trimmed.toLowerCase();
    const blockedTerms = [
      'self-harm',
      'suicide',
      'kill myself',
      'bomb',
      'weapon',
      'bypass exam',
      'cheat on exam',
      '色情',
      '自杀',
      '作弊',
      '炸弹',
    ];
    for (final term in blockedTerms) {
      if (lower.contains(term)) {
        return AiSafetyResult(
          allowed: false,
          reason: 'blocked_term',
          category: term,
        );
      }
    }
    return const AiSafetyResult(allowed: true);
  }

  Future<AiCompletion> _completeWithOpenAiCompatible({
    required String feature,
    required String prompt,
    required AiSafetyResult safety,
  }) async {
    if (apiKey.isEmpty) {
      return _completeLocally(
        feature: feature,
        prompt: prompt,
        safety: safety,
        providerNote: 'AI_API_KEY 未配置，已使用后端结构化本地 provider。',
      );
    }

    final client = HttpClient();
    try {
      final request = await client.postUrl(baseUrl);
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $apiKey');
      request.write(
        jsonEncode({
          'model': model,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt(feature)},
            {'role': 'user', 'content': prompt},
          ],
        }),
      );
      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AiServiceException(
          'AI provider returned ${response.statusCode}: ${body.substring(0, body.length.clamp(0, 240).toInt())}',
        );
      }
      final data = jsonDecode(body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>? ?? const [];
      final message = choices.isEmpty
          ? const <String, dynamic>{}
          : choices.first as Map<String, dynamic>;
      final content =
          (message['message'] as Map<String, dynamic>?)?['content']
              ?.toString() ??
          '{}';
      final generated = _safeJsonObject(content);
      final responseText =
          generated['response']?.toString() ??
          generated['summary']?.toString() ??
          'AI 已返回结构化学习反馈。';
      return AiCompletion(
        feature: feature,
        title: titleFor(feature, prompt),
        response: responseText,
        payload: {
          ...generated,
          'provider': provider,
          'model': model,
          'safety': safety.toJson(),
        },
      );
    } finally {
      client.close(force: true);
    }
  }

  AiCompletion _completeLocally({
    required String feature,
    required String prompt,
    required AiSafetyResult safety,
    String? providerNote,
  }) {
    final payload = switch (feature) {
      'sentence' => _sentencePayload(prompt),
      'essay' => _essayPayload(prompt),
      'cloze' => _clozePayload(prompt),
      'confuse' => _confusePayload(prompt),
      _ => _qaPayload(prompt),
    };
    return AiCompletion(
      feature: feature,
      title: titleFor(feature, prompt),
      response: payload['response'] as String,
      payload: {
        ...payload,
        'provider': provider,
        'model': model,
        'safety': safety.toJson(),
        if (providerNote != null) 'providerNote': providerNote,
      },
    );
  }

  static String normalizeFeature(String value) {
    return switch (value.trim().toLowerCase()) {
      'sentence' || 'long_sentence' => 'sentence',
      'essay' || 'writing' => 'essay',
      'cloze' || 'story_cloze' => 'cloze',
      'confuse' || 'confusable' => 'confuse',
      _ => 'qa',
    };
  }

  static String titleFor(String feature, String prompt) {
    final clean = prompt.length > 18 ? '${prompt.substring(0, 18)}...' : prompt;
    final label = switch (feature) {
      'sentence' => '长难句',
      'essay' => '作文批改',
      'cloze' => '情景填空',
      'confuse' => '易混词',
      _ => '知识问答',
    };
    return '$label · $clean';
  }

  Map<String, dynamic> _qaPayload(String prompt) {
    return {
      'response': '可以从词义、语境、搭配和语气四个角度理解：$prompt',
      'sections': [
        {'title': '基本释义', 'body': '先确认核心含义，再判断它在句子里的具体指向。'},
        {'title': '常见搭配', 'body': '记录高频动词、介词和名词搭配，避免只背孤立中文。'},
        {'title': '练习建议', 'body': '把这个词放入一个自己的例句，并在复习中做反向回忆。'},
      ],
      'practice': [
        {'type': 'context', 'prompt': '用目标词补全一个真实语境句。'},
      ],
    };
  }

  Map<String, dynamic> _sentencePayload(String prompt) {
    return {
      'response': '句子主干已拆分：先找谓语，再回看主语和宾语；从句或修饰语可以先折叠，最后再恢复语义。',
      'highlightedText': prompt,
      'sections': [
        {'title': '主干', 'body': '定位核心动词，确认谁做了什么。'},
        {'title': '修饰', 'body': '把介词短语、定语从句和插入语作为补充信息处理。'},
        {'title': '翻译策略', 'body': '先译主干，再按中文习惯把修饰信息前置或拆句。'},
      ],
    };
  }

  Map<String, dynamic> _essayPayload(String prompt) {
    return {
      'response': '作文反馈已生成：先保证论点清楚，再优化连接词和词汇多样性。',
      'score': 7.0,
      'sections': [
        {'title': '任务回应', 'body': '观点明确，但例证可以更具体。'},
        {'title': '连贯衔接', 'body': '段落顺序清楚，部分连接词可替换为更自然表达。'},
        {'title': '词汇语法', 'body': '减少重复词，优先使用准确搭配而不是堆叠难词。'},
      ],
      'issues': ['论点展开还可以更具体', '部分句子连接略生硬'],
      'revision': '建议每段加入一个具体例子，并减少重复表达。',
    };
  }

  Map<String, dynamic> _clozePayload(String prompt) {
    return {
      'response': '已生成一段情景填空练习，重点考查语境理解和词义辨析。',
      'passage':
          'A steady learner reviews words in context before the memory fades.',
      'blanks': [
        {'answer': 'reviews', 'hint': '复习'},
        {'answer': 'context', 'hint': '语境'},
      ],
      'sections': [
        {'title': '短文目标', 'body': '把目标词放回语境中，训练从上下文判断词义。'},
      ],
    };
  }

  Map<String, dynamic> _confusePayload(String prompt) {
    return {
      'response': '易混词可以先按词性、语义方向和典型搭配拆开，再回到例句中验证。',
      'sections': [
        {'title': '词性', 'body': '确认两个词是否承担相同语法角色。'},
        {'title': '语义边界', 'body': '比较动作发出者、受影响对象和使用场景。'},
        {'title': '复习动作', 'body': '把混淆词放入同一组选择题和拼写题中重复巩固。'},
      ],
    };
  }

  String _systemPrompt(String feature) {
    return '''
You are LinguaQuest AIService. Return a compact JSON object only.
Feature: $feature.
Required keys: response, sections.
Use Chinese explanations for Chinese-speaking English learners.
Do not change user study records or claim that records were updated.
Keep generated content safe, concise, and suitable for exam vocabulary learning.
''';
  }

  Map<String, dynamic> _safeJsonObject(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      // Fall through to plain text wrapping.
    }
    return {'response': content};
  }
}

class AiCompletion {
  const AiCompletion({
    required this.feature,
    required this.title,
    required this.response,
    required this.payload,
  });

  final String feature;
  final String title;
  final String response;
  final Map<String, dynamic> payload;
}

class AiSafetyResult {
  const AiSafetyResult({required this.allowed, this.reason, this.category});

  final bool allowed;
  final String? reason;
  final String? category;

  Map<String, dynamic> toJson() {
    return {
      'allowed': allowed,
      if (reason != null) 'reason': reason,
      if (category != null) 'category': category,
    };
  }
}

class AiServiceException implements Exception {
  const AiServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

String _env(String key, String fallback) {
  return Platform.environment[key] ?? fallback;
}
