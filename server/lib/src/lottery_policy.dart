import 'dart:math';

const lotteryDrawCost = 30;

const lotteryPrizeSeed = [
  {
    'id': 'avatar-frame-starry',
    'name': '星轨头像框',
    'category': 'avatarFrame',
    'rarity': 'rare',
    'description': '围绕头像的星轨装饰，不提供学习分数加成。',
    'probability': 6,
    'fragmentValue': 18,
  },
  {
    'id': 'profile-bg-aurora',
    'name': '极光主页背景',
    'category': 'profileBackground',
    'rarity': 'rare',
    'description': '个人空间可展示的极光背景，不影响学习公平性。',
    'probability': 7,
    'fragmentValue': 16,
  },
  {
    'id': 'badge-focus-sprinter',
    'name': '专注冲刺徽章',
    'category': 'badge',
    'rarity': 'uncommon',
    'description': '学习资料页展示徽章，仅作荣誉装饰。',
    'probability': 16,
    'fragmentValue': 8,
  },
  {
    'id': 'title-arena-scout',
    'name': '训练场侦察员称号',
    'category': 'title',
    'rarity': 'uncommon',
    'description': '训练场称号展示，不提高答题分数。',
    'probability': 14,
    'fragmentValue': 8,
  },
  {
    'id': 'card-skin-mint',
    'name': '薄荷卡片皮肤',
    'category': 'cardSkin',
    'rarity': 'common',
    'description': '单词卡片视觉皮肤，不改变记忆算法。',
    'probability': 22,
    'fragmentValue': 5,
  },
  {
    'id': 'comfort-star-fragments',
    'name': '星尘碎片',
    'category': 'fragment',
    'rarity': 'comfort',
    'description': '安慰奖励，可累计兑换装饰资产。',
    'probability': 35,
    'fragmentValue': 3,
  },
];

Map<String, dynamic> chooseLotteryPrize(
  List<Map<String, dynamic>> prizes, {
  Random? random,
}) {
  final active = prizes.where((prize) => prize['is_active'] != false).toList();
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
