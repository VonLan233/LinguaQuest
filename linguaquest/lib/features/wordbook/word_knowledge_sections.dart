import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/lesson.dart';

class WordKnowledgeSections extends StatelessWidget {
  const WordKnowledgeSections({required this.word, super.key});

  final Word word;

  @override
  Widget build(BuildContext context) {
    final knowledge = _knowledgeFor(word);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('词汇全解', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _KnowledgeLine(
          icon: Icons.hub_outlined,
          color: AppTheme.cyan,
          title: '词组搭配',
          body: knowledge.collocations.join(' · '),
        ),
        const _KnowledgeDivider(),
        _KnowledgeLine(
          icon: Icons.compare_arrows_rounded,
          color: AppTheme.teal,
          title: '近义 / 反义',
          body:
              '近义：${knowledge.synonyms.join('、')}；反义：${knowledge.antonyms.join('、')}',
        ),
        const _KnowledgeDivider(),
        _KnowledgeLine(
          icon: Icons.account_tree_outlined,
          color: AppTheme.mango,
          title: '派生词族',
          body: knowledge.family.join(' · '),
        ),
        const _KnowledgeDivider(),
        _KnowledgeLine(
          icon: Icons.psychology_outlined,
          color: AppTheme.coral,
          title: '词根拆词',
          body: knowledge.rootNote,
        ),
      ],
    );
  }
}

class _KnowledgeLine extends StatelessWidget {
  const _KnowledgeLine({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconCueBadge(icon: icon, color: color, size: 38),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.42,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KnowledgeDivider extends StatelessWidget {
  const _KnowledgeDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 22,
      color: Theme.of(
        context,
      ).colorScheme.outlineVariant.withValues(alpha: 0.7),
    );
  }
}

_KnowledgeData _knowledgeFor(Word word) {
  switch (word.word.toLowerCase()) {
    case 'allocate':
      return const _KnowledgeData(
        collocations: ['allocate time', 'allocate resources', 'allocate funds'],
        synonyms: ['assign', 'distribute'],
        antonyms: ['withhold', 'keep'],
        family: ['allocation', 'allocated', 'allocator'],
        rootNote: '可拆为 al- + locate，记作“把资源放到指定位置”。',
      );
    case 'evaluate':
      return const _KnowledgeData(
        collocations: ['evaluate evidence', 'evaluate performance'],
        synonyms: ['assess', 'judge'],
        antonyms: ['ignore', 'guess'],
        family: ['evaluation', 'evaluative', 'evaluator'],
        rootNote: '来自 value，核心是“判断价值或质量”。',
      );
    case 'contrast':
      return const _KnowledgeData(
        collocations: ['contrast A with B', 'sharp contrast'],
        synonyms: ['compare', 'differentiate'],
        antonyms: ['match', 'resemble'],
        family: ['contrastive', 'contrasting', 'contrastable'],
        rootNote: 'con- 表示共同，-trast 有拉开之意，可记作“放在一起看差异”。',
      );
    case 'brief':
      return const _KnowledgeData(
        collocations: ['brief update', 'brief summary'],
        synonyms: ['short', 'concise'],
        antonyms: ['lengthy', 'detailed'],
        family: ['briefly', 'briefing', 'brevity'],
        rootNote: '和 brevity 同源，记作“短而只保留重点”。',
      );
    case 'negotiate':
      return const _KnowledgeData(
        collocations: ['negotiate a deal', 'negotiate terms'],
        synonyms: ['discuss', 'bargain'],
        antonyms: ['reject', 'dictate'],
        family: ['negotiation', 'negotiator', 'negotiable'],
        rootNote: 'neg- 有处理事务的来源，记作“来回处理条件以达成一致”。',
      );
    case 'priority':
      return const _KnowledgeData(
        collocations: ['top priority', 'set priorities'],
        synonyms: ['preference', 'importance'],
        antonyms: ['afterthought', 'minor issue'],
        family: ['prioritize', 'prior', 'prioritization'],
        rootNote: 'prior 表示“在前”，priority 就是排在前面的事项。',
      );
    case 'itinerary':
      return const _KnowledgeData(
        collocations: ['travel itinerary', 'detailed itinerary'],
        synonyms: ['route', 'schedule'],
        antonyms: ['detour', 'improvisation'],
        family: ['itinerant', 'itinerate', 'itinerary plan'],
        rootNote: '和 journey/route 相关，记作“旅途中逐站安排”。',
      );
    case 'departure':
      return const _KnowledgeData(
        collocations: ['departure gate', 'departure time'],
        synonyms: ['leaving', 'exit'],
        antonyms: ['arrival', 'return'],
        family: ['depart', 'departed', 'departing'],
        rootNote: 'de- 表示离开，part 表示分开，可记作“从当前位置分离”。',
      );
    case 'luggage':
      return const _KnowledgeData(
        collocations: ['carry luggage', 'checked luggage'],
        synonyms: ['baggage', 'bags'],
        antonyms: ['hand-free travel', 'unpacked items'],
        family: ['luggage tag', 'luggage cart', 'luggage claim'],
        rootNote: '和 lug “拖、拉”有关，可记作“旅行中拖着的包”。',
      );
    case 'appetite':
      return const _KnowledgeData(
        collocations: ['good appetite', 'lose appetite'],
        synonyms: ['hunger', 'craving'],
        antonyms: ['fullness', 'disinterest'],
        family: ['appetizing', 'appetizer', 'appetitive'],
        rootNote: 'appet- 有追求、渴望之意，可记作“想吃的欲望”。',
      );
    case 'ingredient':
      return const _KnowledgeData(
        collocations: ['key ingredient', 'fresh ingredient'],
        synonyms: ['component', 'element'],
        antonyms: ['whole', 'product'],
        family: ['ingredients list', 'ingredient-based', 'main ingredient'],
        rootNote: 'in- + grad/gress 有进入之意，可记作“放进配方里的部分”。',
      );
    case 'flavor':
      return const _KnowledgeData(
        collocations: ['rich flavor', 'add flavor'],
        synonyms: ['taste', 'savor'],
        antonyms: ['blandness', 'plainness'],
        family: ['flavorful', 'flavored', 'flavoring'],
        rootNote: '和 taste 相关，记作“食物给人的味觉特征”。',
      );
    case 'recover':
      return const _KnowledgeData(
        collocations: ['recover from illness', 'recover quickly'],
        synonyms: ['heal', 'regain'],
        antonyms: ['decline', 'worsen'],
        family: ['recovery', 'recoverable', 'recovered'],
        rootNote: 're- 表示再一次，cover 有覆盖/找回感，记作“重新恢复状态”。',
      );
    case 'symptom':
      return const _KnowledgeData(
        collocations: ['common symptom', 'show symptoms'],
        synonyms: ['sign', 'indication'],
        antonyms: ['cause', 'health'],
        family: ['symptomatic', 'asymptomatic', 'symptom-free'],
        rootNote: 'sym- 表示共同出现，记作“和疾病一起出现的信号”。',
      );
    case 'prevent':
      return const _KnowledgeData(
        collocations: ['prevent damage', 'prevent illness'],
        synonyms: ['stop', 'avoid'],
        antonyms: ['allow', 'cause'],
        family: ['prevention', 'preventive', 'preventable'],
        rootNote: 'pre- 表示在前，vent 表示来，记作“提前挡住事情发生”。',
      );
    case 'commute':
      return const _KnowledgeData(
        collocations: ['commute to campus', 'daily commute'],
        synonyms: ['travel', 'journey'],
        antonyms: ['stay', 'remain'],
        family: ['commuter', 'commuting', 'commutable'],
        rootNote: 'com- 表示共同，mut- 表示改变位置，记作“固定来回移动”。',
      );
    case 'lecture':
      return const _KnowledgeData(
        collocations: ['attend a lecture', 'biology lecture'],
        synonyms: ['talk', 'class'],
        antonyms: ['discussion', 'silence'],
        family: ['lecturer', 'lecture hall', 'lecturing'],
        rootNote: 'lect- 与阅读/讲授相关，记作“围绕材料讲解”。',
      );
    case 'deadline':
      return const _KnowledgeData(
        collocations: ['meet a deadline', 'essay deadline'],
        synonyms: ['due date', 'time limit'],
        antonyms: ['extension', 'open date'],
        family: ['deadline-driven', 'deadline pressure', 'deadline day'],
        rootNote: 'dead + line，可记作“不能再越过的最后一条线”。',
      );
    default:
      return _fallbackKnowledge(word);
  }
}

_KnowledgeData _fallbackKnowledge(Word word) {
  return _KnowledgeData(
    collocations: ['use ${word.word}', '${word.word} in context'],
    synonyms: ['related word'],
    antonyms: ['opposite meaning'],
    family: ['${word.word} form', '${word.word} phrase'],
    rootNote: '结合例句“${word.exampleSentence}”记忆核心含义：${word.meaning}。',
  );
}

class _KnowledgeData {
  const _KnowledgeData({
    required this.collocations,
    required this.synonyms,
    required this.antonyms,
    required this.family,
    required this.rootNote,
  });

  final List<String> collocations;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> family;
  final String rootNote;
}
