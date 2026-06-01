import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/repositories/app_services_repository.dart';

class AiTutorScreen extends ConsumerStatefulWidget {
  const AiTutorScreen({
    super.key,
    this.initialFeature = 'qa',
    this.initialConversationId,
  });

  final String initialFeature;
  final String? initialConversationId;

  @override
  ConsumerState<AiTutorScreen> createState() => _AiTutorScreenState();
}

class _AiTutorScreenState extends ConsumerState<AiTutorScreen> {
  late final TextEditingController _promptController;
  late String _feature;
  String? _conversationId;
  AiCompletionResult? _result;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _feature = _normalizedFeature(widget.initialFeature);
    _conversationId = widget.initialConversationId;
    _promptController = TextEditingController(text: _defaultPrompt(_feature));
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/ai-learning'),
        title: const Text('AI 助教'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: QuestIconButton(
              tooltip: '对话记录',
              onPressed: () => context.push('/ai-history'),
              icon: Icons.history_outlined,
              size: 40,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: '即时反馈',
              subtitle: '输入单词、语法或错题，获得结构化解释和可练习的例句。',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _promptController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '询问单词、语法或错题',
                prefixIcon: Icon(Icons.smart_toy_outlined),
              ),
            ),
            const SizedBox(height: 16),
            _FeatureSelector(
              selected: _feature,
              onSelected: (value) => setState(() {
                _feature = value;
                _promptController.text = _defaultPrompt(_feature);
                _result = null;
                _errorMessage = null;
              }),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _submit,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome_outlined),
              label: Text(_isLoading ? '生成中' : '发送到后端 AI 服务'),
            ),
            const SizedBox(height: 18),
            _AiAnswerBlock(
              result: _result,
              fallback: _errorMessage ?? '输入单词、语法或错题后，后端会返回结构化解释；客户端不持有 AI 密钥。',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final result = await ref
          .read(appServicesRepositoryProvider)
          .completeAi(
            feature: _feature,
            prompt: prompt,
            conversationId: _conversationId,
          );
      if (!mounted) return;
      setState(() {
        _result = result;
        _conversationId = result.conversationId;
        _errorMessage = null;
        _isLoading = false;
      });
      ref.invalidate(aiConversationsProvider);
      ref.invalidate(aiConversationDetailProvider(result.conversationId));
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _result = null;
        _errorMessage = 'AI 服务暂时不可用：$error';
        _isLoading = false;
      });
    }
  }
}

class _FeatureSelector extends StatelessWidget {
  const _FeatureSelector({required this.selected, required this.onSelected});

  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const items = [
      ('qa', '问答'),
      ('sentence', '长难句'),
      ('essay', '作文'),
      ('cloze', '填空'),
      ('confuse', '易混词'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final item in items)
          FilterPillButton(
            label: item.$2,
            selected: selected == item.$1,
            onSelected: () => onSelected(item.$1),
          ),
      ],
    );
  }
}

class _AiAnswerBlock extends StatelessWidget {
  const _AiAnswerBlock({required this.result, required this.fallback});

  final AiCompletionResult? result;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final result = this.result;
    final payload = result?.payload ?? const <String, dynamic>{};
    final sections = (payload['sections'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final issues = (payload['issues'] as List<dynamic>? ?? const [])
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final blanks = (payload['blanks'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final score = payload['score'];
    final passage = payload['passage']?.toString();
    final revision = payload['revision']?.toString();
    final providerNote = payload['providerNote']?.toString();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.psychology_alt_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result?.response ?? fallback,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (score != null) ...[
                const SizedBox(height: 10),
                PillLabel(label: '评分 $score', icon: Icons.grade_outlined),
              ],
              if (sections.isNotEmpty) ...[
                const SizedBox(height: 14),
                for (final section in sections) ...[
                  Text(
                    section['title']?.toString() ?? '分析',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(section['body']?.toString() ?? ''),
                  const SizedBox(height: 10),
                ],
              ],
              if (passage != null && passage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('短文', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(passage),
              ],
              if (blanks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final blank in blanks)
                      PillLabel(
                        label:
                            '${blank['answer'] ?? ''} · ${blank['hint'] ?? ''}',
                        icon: Icons.edit_outlined,
                      ),
                  ],
                ),
              ],
              if (issues.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('需要改进', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                for (final issue in issues) Text('• $issue'),
              ],
              if (revision != null && revision.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text('修改建议', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(revision),
              ],
              if (providerNote != null && providerNote.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  providerNote,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

String _normalizedFeature(String value) {
  return switch (value) {
    'sentence' || 'essay' || 'cloze' || 'confuse' => value,
    _ => 'qa',
  };
}

String _defaultPrompt(String feature) {
  return switch (feature) {
    'sentence' =>
      'Although the method seems simple, it works because each review appears before memory fades.',
    'essay' =>
      'Some people think students should learn vocabulary through apps. Discuss both views and give your opinion.',
    'cloze' => '用今天学过的词生成一段 80 词以内的情景填空练习。',
    'confuse' => '解释 affect 和 effect 在使用场景上的区别。',
    _ => '解释 affect 和 effect 的区别',
  };
}
