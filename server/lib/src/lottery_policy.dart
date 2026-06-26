import 'dart:math';

const lotteryDrawCost = 30;

const lotteryPrizeSeed = [
  {
    'id': 'avatar-frame-starry',
    'name': '星轨头像框',
    'category': 'avatarFrame',
    'rarity': 'rare',
    'description': '围绕头像的星轨装饰，不提供学习分数加成。',
    'probability': 4,
    'fragmentValue': 18,
  },
  {
    'id': 'avatar-frame-ember',
    'name': '烬焰头像框',
    'category': 'avatarFrame',
    'rarity': 'rare',
    'description': '燃烧余烬风格头像框，不影响学习公平性。',
    'probability': 3,
    'fragmentValue': 18,
  },
  {
    'id': 'profile-bg-aurora',
    'name': '极光主页背景',
    'category': 'profileBackground',
    'rarity': 'rare',
    'description': '个人空间可展示的极光背景，不影响学习公平性。',
    'probability': 4,
    'fragmentValue': 16,
  },
  {
    'id': 'profile-bg-dawn-harbor',
    'name': '黎明港湾背景',
    'category': 'profileBackground',
    'rarity': 'rare',
    'description': '黎明港口风景背景，仅作装饰展示。',
    'probability': 3,
    'fragmentValue': 16,
  },
  {
    'id': 'badge-focus-sprinter',
    'name': '专注冲刺徽章',
    'category': 'badge',
    'rarity': 'uncommon',
    'description': '学习资料页展示徽章，仅作荣誉装饰。',
    'probability': 9,
    'fragmentValue': 8,
  },
  {
    'id': 'badge-night-owl',
    'name': '夜枭徽章',
    'category': 'badge',
    'rarity': 'uncommon',
    'description': '深夜学习者专属徽章，不提高答题分数。',
    'probability': 7,
    'fragmentValue': 8,
  },
  {
    'id': 'badge-anniversary-lantern',
    'name': '周年灯笼徽章',
    'category': 'badge',
    'rarity': 'rare',
    'description': '特别活动限定徽章，仅作荣誉纪念。',
    'probability': 2,
    'fragmentValue': 20,
  },
  {
    'id': 'title-arena-scout',
    'name': '训练场侦察员称号',
    'category': 'title',
    'rarity': 'uncommon',
    'description': '训练场称号展示，不提高答题分数。',
    'probability': 8,
    'fragmentValue': 8,
  },
  {
    'id': 'title-lexicon-keeper',
    'name': '词汇守护者称号',
    'category': 'title',
    'rarity': 'uncommon',
    'description': '词汇学习者称号，不影响学习公平性。',
    'probability': 7,
    'fragmentValue': 8,
  },
  {
    'id': 'title-dawn-voyager',
    'name': '黎明航行者称号',
    'category': 'title',
    'rarity': 'rare',
    'description': '稀有探索者称号，仅作装饰。',
    'probability': 3,
    'fragmentValue': 16,
  },
  {
    'id': 'card-skin-mint',
    'name': '薄荷卡片皮肤',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': '单词卡片视觉皮肤，不改变记忆算法。',
    'probability': 12,
    'fragmentValue': 5,
  },
  {
    'id': 'card-skin-sakura',
    'name': '樱花卡片皮肤',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': '樱花风格卡片皮肤，不改变记忆算法。',
    'probability': 11,
    'fragmentValue': 5,
  },
  {
    'id': 'card-skin-midnight',
    'name': '午夜卡片皮肤',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': '深色午夜风格卡片皮肤，不影响学习成绩。',
    'probability': 10,
    'fragmentValue': 5,
  },
  {
    'id': 'card-skin-citrus',
    'name': '柑橘卡片皮肤',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': '清新柑橘色调卡片皮肤，仅作视觉装饰。',
    'probability': 7,
    'fragmentValue': 4,
  },
  {
    'id': 'comfort-star-fragments',
    'name': '星尘碎片',
    'category': 'fragment',
    'rarity': 'comfort',
    'description': '安慰奖励，可累计兑换装饰资产。',
    'probability': 10,
    'fragmentValue': 3,
  },
];

Map<String, dynamic> chooseLotteryPrize(
  List<Map<String, dynamic>> prizes, {
  Random? random,
}) {
  final active = prizes
      .where((prize) => (prize['is_active'] ?? prize['isActive']) != false)
      .toList();
  final pool = active.isEmpty ? lotteryPrizeSeed : active;
  final totalWeight = pool.fold<double>(0, (total, prize) {
    return total + _probability(prize['probability']);
  });
  final roll = (random ?? Random()).nextDouble() * totalWeight;
  var cursor = 0.0;
  for (final prize in pool) {
    cursor += _probability(prize['probability']);
    if (roll <= cursor) return prize;
  }
  return pool.last;
}

double _probability(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
