import 'package:flutter/material.dart';

import 'package:linguaquest/core/theme/app_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_pill.dart';
import '../../core/widgets/learning_badges.dart';
import '../../data/models/custom_word.dart';
import '../../data/models/lesson.dart';

class WordKnowledgeSections extends StatefulWidget {
  WordKnowledgeSections({required Word word, super.key})
    : wordText = word.word,
      meaning = word.meaning,
      exampleSentence = word.exampleSentence,
      collocations = word.collocations,
      synonyms = word.synonyms,
      antonyms = word.antonyms,
      derivatives = word.derivatives,
      rootAffix = word.rootAffix;

  WordKnowledgeSections.custom({required CustomWord word, super.key})
    : wordText = word.word,
      meaning = word.meaning,
      exampleSentence = word.exampleSentence,
      collocations = const [],
      synonyms = const [],
      antonyms = const [],
      derivatives = const [],
      rootAffix = '';

  final String wordText;
  final String meaning;
  final String exampleSentence;
  final List<WordPhrase> collocations;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> derivatives;
  final String rootAffix;

  @override
  State<WordKnowledgeSections> createState() => _WordKnowledgeSectionsState();
}

class _WordKnowledgeSectionsState extends State<WordKnowledgeSections> {
  final Set<int> _expandedIndexes = {0};

  @override
  Widget build(BuildContext context) {
    final knowledge = _knowledgeFor(
      widget.wordText,
      widget.meaning,
      widget.exampleSentence,
      collocations: widget.collocations,
      synonyms: widget.synonyms,
      antonyms: widget.antonyms,
      derivatives: widget.derivatives,
      rootAffix: widget.rootAffix,
    );
    final items = [
      _KnowledgePanelData(
        icon: AppIcons.hub,
        color: AppTheme.cyan,
        title: '词组搭配',
        body: knowledge.collocations.join(' · '),
      ),
      _KnowledgePanelData(
        icon: AppIcons.compareArrows,
        color: AppTheme.teal,
        title: '近义 / 反义',
        body:
            '近义：${knowledge.synonyms.join('、')}；反义：${knowledge.antonyms.join('、')}',
        synonyms: knowledge.synonyms,
        antonyms: knowledge.antonyms,
      ),
      _KnowledgePanelData(
        icon: AppIcons.accountTree,
        color: AppTheme.mango,
        title: '派生词族',
        body: knowledge.family.join(' · '),
      ),
      _KnowledgePanelData(
        icon: AppIcons.psychology,
        color: AppTheme.coral,
        title: '词根拆词',
        body: knowledge.rootNote,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '词汇全解',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: AppTokens.s12),
        for (var index = 0; index < items.length; index++) ...[
          _KnowledgeDisclosure(
            data: items[index],
            expanded: _expandedIndexes.contains(index),
            onTap: () => _toggle(index),
          ),
          if (index != items.length - 1) const _KnowledgeDivider(),
        ],
      ],
    );
  }

  void _toggle(int index) {
    setState(() {
      if (!_expandedIndexes.add(index)) {
        _expandedIndexes.remove(index);
      }
    });
  }
}

class _KnowledgeDisclosure extends StatelessWidget {
  const _KnowledgeDisclosure({
    required this.data,
    required this.expanded,
    required this.onTap,
  });

  final _KnowledgePanelData data;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      expanded: expanded,
      label: data.title,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTokens.radiusSmall),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTokens.s2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconCueBadge(icon: data.icon, color: data.color, size: 38),
                const SizedBox(width: AppTokens.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              data.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Icon(
                            expanded
                                ? AppIcons.keyboardArrowUp
                                : AppIcons.keyboardArrowDown,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      AnimatedSize(
                        duration: AppTokens.fast,
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: expanded
                            ? Padding(
                                padding: const EdgeInsets.only(
                                  top: AppTokens.s4,
                                  right: AppTokens.s4,
                                ),
                                child: _DisclosureBody(data: data),
                              )
                            : const SizedBox(width: double.infinity, height: 0),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclosureBody extends StatelessWidget {
  const _DisclosureBody({required this.data});

  final _KnowledgePanelData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final synonyms = data.synonyms;
    final antonyms = data.antonyms;
    final hasBadges =
        (synonyms != null && synonyms.isNotEmpty) ||
        (antonyms != null && antonyms.isNotEmpty);
    if (!hasBadges) {
      return Text(
        data.body,
        style: TextStyle(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.42,
        ),
      );
    }
    return Wrap(
      spacing: AppTokens.s8,
      runSpacing: AppTokens.s8,
      children: [
        if (synonyms != null)
          for (final value in synonyms)
            AppPill(label: value, variant: PillVariant.success),
        if (antonyms != null)
          for (final value in antonyms)
            AppPill(label: value, variant: PillVariant.streak),
      ],
    );
  }
}

class _KnowledgePanelData {
  const _KnowledgePanelData({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    this.synonyms,
    this.antonyms,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final List<String>? synonyms;
  final List<String>? antonyms;
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

_KnowledgeData _knowledgeFor(
  String wordText,
  String meaning,
  String exampleSentence, {
  required List<WordPhrase> collocations,
  required List<String> synonyms,
  required List<String> antonyms,
  required List<String> derivatives,
  required String rootAffix,
}) {
  if (collocations.isNotEmpty ||
      synonyms.isNotEmpty ||
      antonyms.isNotEmpty ||
      derivatives.isNotEmpty ||
      rootAffix.trim().isNotEmpty) {
    final fallback = _fallbackKnowledge(wordText, meaning, exampleSentence);
    return _KnowledgeData(
      collocations: collocations.isEmpty
          ? fallback.collocations
          : [
              for (final item in collocations)
                item.cn.trim().isEmpty
                    ? item.phrase
                    : '${item.phrase}（${item.cn}）',
            ],
      synonyms: synonyms.isEmpty ? fallback.synonyms : synonyms,
      antonyms: antonyms.isEmpty ? fallback.antonyms : antonyms,
      family: derivatives.isEmpty ? fallback.family : derivatives,
      rootNote: rootAffix.trim().isEmpty ? fallback.rootNote : rootAffix,
    );
  }
  switch (wordText.toLowerCase()) {
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
      return _fallbackKnowledge(wordText, meaning, exampleSentence);
  }
}

_KnowledgeData _fallbackKnowledge(
  String wordText,
  String meaning,
  String exampleSentence,
) {
  final cleanExample = exampleSentence.trim();
  final rootNote = cleanExample.isEmpty
      ? '结合释义“$meaning”记忆核心用法。'
      : '结合例句“$cleanExample”记忆核心含义：$meaning。';
  return _KnowledgeData(
    collocations: ['use $wordText', '$wordText in context'],
    synonyms: ['related word'],
    antonyms: ['opposite meaning'],
    family: ['$wordText form', '$wordText phrase'],
    rootNote: rootNote,
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
