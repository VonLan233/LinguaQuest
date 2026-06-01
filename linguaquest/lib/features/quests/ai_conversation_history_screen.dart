import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/fallback_back_button.dart';
import '../../core/widgets/learning_badges.dart';
import '../../core/widgets/section_header.dart';
import '../../data/models/ai_conversation.dart';

class AiConversationHistoryScreen extends ConsumerWidget {
  const AiConversationHistoryScreen({this.conversationId, super.key});

  final String? conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = conversationId;
    if (id != null && id.isNotEmpty) {
      return _AiConversationDetailView(conversationId: id);
    }
    final conversations = ref.watch(aiConversationsProvider);
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/ai-learning'),
        title: const Text('AI 对话记录'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(aiConversationsProvider),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SectionHeader(
                title: '历史对话',
                subtitle: '对话保存在后端，可查看详情或删除不需要的记录。',
              ),
              const SizedBox(height: 14),
              conversations.when(
                data: (items) => _ConversationList(conversations: items),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) =>
                    _ErrorLine(text: '暂时无法同步 AI 对话记录，请稍后重试。'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AiConversationDetailView extends ConsumerWidget {
  const _AiConversationDetailView({required this.conversationId});

  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(aiConversationDetailProvider(conversationId));
    return Scaffold(
      appBar: AppBar(
        leading: const FallbackBackButton(fallbackLocation: '/ai-history'),
        title: const Text('对话详情'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: QuestIconButton(
              tooltip: '删除对话',
              onPressed: () => _delete(context, ref),
              icon: Icons.delete_outline,
              color: AppTheme.coral,
              size: 40,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(aiConversationDetailProvider(conversationId)),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              detail.when(
                data: (item) => _ConversationDetailBody(detail: item),
                loading: () => const LinearProgressIndicator(),
                error: (error, stackTrace) =>
                    const _ErrorLine(text: '暂时无法打开这段对话。'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除对话？'),
        content: const Text('这会从服务器删除该 AI 对话和消息记录。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.delete_outline),
            label: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref
        .read(appServicesRepositoryProvider)
        .deleteAiConversation(conversationId);
    ref.invalidate(aiConversationsProvider);
    ref.invalidate(aiConversationDetailProvider(conversationId));
    if (context.mounted) context.go('/ai-history');
  }
}

class _ConversationList extends StatelessWidget {
  const _ConversationList({required this.conversations});

  final List<AiConversation> conversations;

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return const _EmptyLine(text: '还没有 AI 对话。完成一次问答、长难句或作文批改后会显示在这里。');
    }
    return Column(
      children: [
        for (var index = 0; index < conversations.length; index++) ...[
          _ConversationRow(conversation: conversations[index]),
          if (index != conversations.length - 1)
            Divider(
              height: 14,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
        ],
      ],
    );
  }
}

class _ConversationRow extends StatelessWidget {
  const _ConversationRow({required this.conversation});

  final AiConversation conversation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/ai-history/${conversation.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconCueBadge(
                icon: _featureIcon(conversation.feature),
                color: AppTheme.cyan,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversation.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '更新于 ${_compactDate(conversation.updatedAt)}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              PillLabel(label: _featureLabel(conversation.feature)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationDetailBody extends StatelessWidget {
  const _ConversationDetailBody({required this.detail});

  final AiConversationDetail detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: detail.conversation.title,
          subtitle:
              '${_featureLabel(detail.conversation.feature)} · ${_compactDate(detail.conversation.updatedAt)}',
          trailing: TextButton.icon(
            onPressed: () => context.push(
              '/ai-tutor?feature=${detail.conversation.feature}&conversationId=${detail.conversation.id}',
            ),
            icon: const Icon(Icons.chat_outlined),
            label: const Text('继续'),
          ),
        ),
        const SizedBox(height: 14),
        if (detail.messages.isEmpty)
          const _EmptyLine(text: '这段对话还没有消息。')
        else
          for (final message in detail.messages) _MessageRow(message: message),
      ],
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({required this.message});

  final AiMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = message.isUser ? AppTheme.mango : AppTheme.cyan;
    final sections = (message.payload['sections'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconCueBadge(
            icon: message.isUser
                ? Icons.person_outline
                : Icons.psychology_alt_outlined,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.isUser ? '我' : 'AI 助教',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(message.content),
                if (sections.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  for (final section in sections.take(3))
                    Text(
                      '${section['title'] ?? '分析'}：${section['body'] ?? ''}',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

IconData _featureIcon(String feature) {
  return switch (feature) {
    'sentence' => Icons.account_tree_outlined,
    'essay' => Icons.rate_review_outlined,
    'cloze' => Icons.auto_stories_outlined,
    'confuse' => Icons.compare_arrows_outlined,
    _ => Icons.question_answer_outlined,
  };
}

String _featureLabel(String feature) {
  return switch (feature) {
    'sentence' => '长难句',
    'essay' => '作文',
    'cloze' => '填空',
    'confuse' => '易混词',
    _ => '问答',
  };
}

String _compactDate(DateTime date) {
  final local = date.toLocal();
  return '${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
}
